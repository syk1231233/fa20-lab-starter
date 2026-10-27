#include "matrix.h"
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <omp.h>

// Include SSE intrinsics
#if defined(_MSC_VER)
#include <intrin.h>
#elif defined(__GNUC__) && (defined(__x86_64__) || defined(__i386__))
#include <immintrin.h>
#include <x86intrin.h>
#endif

/* Below are some intel intrinsics that might be useful
 * void _mm256_storeu_pd (double * mem_addr, __m256d a)
 * __m256d _mm256_set1_pd (double a)
 * __m256d _mm256_set_pd (double e3, double e2, double e1, double e0)
 * __m256d _mm256_loadu_pd (double const * mem_addr)
 * __m256d _mm256_add_pd (__m256d a, __m256d b)
 * __m256d _mm256_sub_pd (__m256d a, __m256d b)
 * __m256d _mm256_fmadd_pd (__m256d a, __m256d b, __m256d c)
 * __m256d _mm256_mul_pd (__m256d a, __m256d b)
 * __m256d _mm256_cmp_pd (__m256d a, __m256d b, const int imm8)
 * __m256d _mm256_and_pd (__m256d a, __m256d b)
 * __m256d _mm256_max_pd (__m256d a, __m256d b)
*/

/*
 * Generates a random double between `low` and `high`.
 */
double rand_double(double low, double high) {
    double range = (high - low);
    double div = RAND_MAX / range;
    return low + (rand() / div);
}

/*
 * Generates a random matrix with `seed`.
 */
void rand_matrix(matrix *result, unsigned int seed, double low, double high) {
    srand(seed);
    for (int i = 0; i < result->rows; i++) {
        for (int j = 0; j < result->cols; j++) {
            set(result, i, j, rand_double(low, high));
        }
    }
}

/* typedef struct matrix {
    int rows;      	// number of rows
    int cols;      	// number of columns
    double **data; 	// each element is a pointer to a row of data
    int is_1d;     	// Whether this matrix is a 1d matrix
    // For 1D matrix, shape is (rows * cols)
    int ref_cnt;
    struct matrix *parent;
} matrix;
*/
/*
 * Allocate space for a matrix struct pointed to by the double pointer mat with
 * `rows` rows and `cols` columns. You should also allocate memory for the data array
 * and initialize all entries to be zeros. Remember to set all fieds of the matrix struct.
 * `parent` should be set to NULL to indicate that this matrix is not a slice.
 * You should return -1 if either `rows` or `cols` or both have invalid values, or if any
 * call to allocate memory in this function fails. If you don't set python error messages here upon
 * failure, then remember to set it in numc.c.
 * Return 0 upon success and non-zero upon failure.
 */
int allocate_matrix(matrix **mat, int rows, int cols) {
   if((rows <= 0) || (cols <= 0)){
        PyErr_SetString(PyExc_ValueError, "Invalid matrix argument");
        return -1;
   }

   matrix* new_mat = (matrix*)malloc(sizeof(struct matrix));
   if(new_mat == NULL){
        PyErr_SetString(PyExc_RuntimeError, "Malloc fail");
        return -1;
   }

   if(rows == 1 || cols == 1) new_mat->is_1d = 1;
   else new_mat->is_1d = 0;
    
   new_mat->data = (double**)malloc(sizeof(double*) * rows);
   if(new_mat->data == NULL){
        free(new_mat);
        PyErr_SetString(PyExc_RuntimeError, "Malloc fail");
        return -1;
   }
   new_mat->data[0] = (double*)calloc(cols * rows, sizeof(double));
   if(new_mat->data[0] == NULL){
        free(new_mat->data);
        free(new_mat);
        PyErr_SetString(PyExc_RuntimeError, "Malloc fail");
        return -1; 
   }
   for(int i = 1; i < rows; i++){
        new_mat->data[i] = new_mat->data[0] + cols * i;
   }
   new_mat->cols = cols;
   new_mat->rows = rows;

   new_mat->parent = NULL;

   new_mat->ref_cnt = 1;

   *mat = new_mat;
   return 0;
}

/*
 * Allocate space for a matrix struct pointed to by `mat` with `rows` rows and `cols` columns.
 * This is equivalent to setting the new matrix to be
 * from[row_offset:row_offset + rows, col_offset:col_offset + cols]
 * If you don't set python error messages here upon failure, then remember to set it in numc.c.
 * Return 0 upon success and non-zero upon failure.
 */
int allocate_matrix_ref(matrix **mat, matrix *from, int row_offset, int col_offset,
                        int rows, int cols) {
    if((rows <= 0) || (cols <= 0)){
        PyErr_SetString(PyExc_ValueError, "Invalid matrix argument");
        return -1;
   }

   if(from == NULL){
        PyErr_SetString(PyExc_ValueError, "Passing matrix is NULL");
        return -1;
   }

   matrix* new_mat = (matrix*)malloc(sizeof(struct matrix));
   if(new_mat == NULL){
        PyErr_SetString(PyExc_RuntimeError, "Malloc fail");
        return -1;
   }

   if(rows == 1 || cols == 1) new_mat->is_1d = 1;
   else new_mat->is_1d = 0;
    
   new_mat->data = (double**)malloc(sizeof(double*) * rows);
   if(new_mat->data == NULL){
        free(new_mat);
        PyErr_SetString(PyExc_RuntimeError, "Malloc fail");
        return -1;
   }
   for(int i = 0; i < rows; i++){
        new_mat->data[i] = from->data[i + row_offset] + col_offset; 
   }
   new_mat->cols = cols;
   new_mat->rows = rows;

   new_mat->parent = from;
   while(new_mat->parent->parent != NULL){
        new_mat->parent = new_mat->parent->parent;
   }
   new_mat->parent->ref_cnt++;
   new_mat->ref_cnt = new_mat->parent->ref_cnt;

   *mat = new_mat;
   return 0;
}

/*
 * This function will be called automatically by Python when a numc matrix loses all of its
 * reference pointers.
 * You need to make sure that you only free `mat->data` if no other existing matrices are also
 * referring this data array.
 * See the spec for more information.
 */
void deallocate_matrix(matrix *mat) {
    // 1. check mat's validity
    if(mat == NULL){
        return ;
    }

    // 2. find its root and check its ref_cnt
    matrix* cur_mat = mat;
    while(cur_mat->parent != NULL){
        cur_mat = cur_mat->parent;
    }

    // 3. free slice anywhere
    if(cur_mat != mat){
        free(mat->data);
        free(mat);
    }

    if(cur_mat->ref_cnt == 1){
        // 3.1 free root
        free(cur_mat->data[0]);
        free(cur_mat->data);
        free(cur_mat);
    }else{
        // 3.2  root's ref_cnt minus 1;
        cur_mat->ref_cnt--;
    }
}

/*
 * Return the double value of the matrix at the given row and column.
 * You may assume `row` and `col` are valid.
 */
double get(matrix *mat, int row, int col) {
    return mat->data[row][col];
}

/*
 * Set the value at the given row and column to val. You may assume `row` and
 * `col` are valid
 */
void set(matrix *mat, int row, int col, double val) {
    mat->data[row][col] = val;
}

/*
 * Set all entries in mat to val
 */
void fill_matrix(matrix *mat, double val) {
    for(int i = 0; i < mat->rows; i++){
        for(int j = 0; j < mat->cols; j++){
            mat->data[i][j] = val;
        }
    }
}

/*
 * Store the result of adding mat1 and mat2 to `result`.
 * Return 0 upon success and a nonzero value upon failure.
 */
int add_matrix(matrix *result, matrix *mat1, matrix *mat2) {
    int rows = mat1->rows;
    int cols = mat2->cols;
    for(int i = 0; i < rows; i++){
        for(int j = 0; j < cols; j++){
            result->data[i][j] = mat1->data[i][j] + mat2->data[i][j];
        }
    }
    return 0;
}

/*
 * Store the result of subtracting mat2 from mat1 to `result`.
 * Return 0 upon success and a nonzero value upon failure.
 */
int sub_matrix(matrix *result, matrix *mat1, matrix *mat2) {
    int rows = mat1->rows;
    int cols = mat2->cols;
    for(int i = 0; i < rows; i++){
        for(int j = 0; j < cols; j++){
            result->data[i][j] = mat1->data[i][j] - mat2->data[i][j];
        }
    }
    return 0;
}

/*
 * Store the result of multiplying mat1 and mat2 to `result`.
 * Return 0 upon success and a nonzero value upon failure.
 * Remember that matrix multiplication is not the same as multiplying individual elements.
 */
int mul_matrix(matrix *result, matrix *mat1, matrix *mat2) {
    int rows = mat1->rows;
    int cols = mat2->cols;
    int times = mat1->cols;
    for(int i = 0; i < rows; i++){
        for(int j = 0; j < cols; j++){
            double sum = 0;
            for(int k = 0; k < times; k++){
                sum += mat1->data[i][k] * mat2->data[k][j];
            }
            result->data[i][j] = sum;
        }
    }
    return 0;
}

/*
 * Store the result of raising mat to the (pow)th power to `result`.
 * Return 0 upon success and a nonzero value upon failure.
 * Remember that pow is defined with matrix multiplication, not element-wise multiplication.
 */
int pow_matrix(matrix *result, matrix *mat, int pow) {

    matrix* tmp;
    if(allocate_matrix(&tmp, result->rows, result->cols) == -1){
        return -1;
    }

    for(int i = 0; i < mat->rows; i++){
        for(int j = 0; j < mat->cols; j++){
            if(i != j) result->data[i][j] = 0;
            else result->data[i][i] = 1;
        }
    }

    while(1){
        if(pow == 0){
            deallocate_matrix(tmp);
            return 0;
        }
        mul_matrix(tmp,result,mat);
        for(int i = 0; i < mat->rows; i++){
            for(int j = 0; j < mat->rows; j++){
                result->data[i][j] = tmp->data[i][j];
            }
        }
        pow--;
    }
}

/*
 * Store the result of element-wise negating mat's entries to `result`.
 * Return 0 upon success and a nonzero value upon failure.
 */
int neg_matrix(matrix *result, matrix *mat) {
    int rows = mat->rows;
    int cols = mat->cols;
    for(int i = 0; i < rows; i++){
        for(int j = 0; j < cols; j++){
            result->data[i][j] = -mat->data[i][j];
        }
    }
    return 0;
}

/*
 * Store the result of taking the absolute value element-wise to `result`.
 * Return 0 upon success and a nonzero value upon failure.
 */
int abs_matrix(matrix *result, matrix *mat) {
    int rows = mat->rows;
    int cols = mat->cols;
    for(int i = 0; i < rows; i++){
        for(int j = 0; j < cols; j++){
            double data = mat->data[i][j];
            if(data < 0) data = -data;
            result->data[i][j] = data;
        }
    }
    return 0;
}

