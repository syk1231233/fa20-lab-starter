#include "transpose.h"

/* The naive transpose function as a reference. */
void transpose_naive(int n, int blocksize, int *dst, int *src) {
    for (int x = 0; x < n; x++) {
        for (int y = 0; y < n; y++) {
            dst[y + x * n] = src[x + y * n];
        }
    }
}

/* Implement cache blocking below. You should NOT assume that n is a
 * multiple of the block size. */
void transpose_blocking(int n, int blocksize, int *dst, int *src) {
    /* n不是blocksize的倍数
        
    */
    int times = (n + blocksize -1) / blocksize;
    for(int x_t = 0; x_t < times; x_t++){
        for(int y_t = 0; y_t < times; y_t++){
            for(int x = 0; x < blocksize; x++){
                for(int y = 0; y < blocksize; y++){
                    if(((x + x_t * blocksize) < n) && ((y + y_t * blocksize) < n)) dst[y + (x + x_t * blocksize) * n + y_t * blocksize] = src[x + x_t * blocksize + (y + y_t * blocksize) * n];
                    else break; 
                }
            }
        }
    }
}
