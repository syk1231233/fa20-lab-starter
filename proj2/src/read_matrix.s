.globl read_matrix

.text
# ==============================================================================
# FUNCTION: Allocates memory and reads in a binary file as a matrix of integers
#
# FILE FORMAT:
#   The first 8 bytes are two 4 byte ints representing the # of rows and columns
#   in the matrix. Every 4 bytes afterwards is an element of the matrix in
#   row-major order.
# Arguments:
#   a0 (char*) is the pointer to string representing the filename
#   a1 (int*)  is a pointer to an integer, we will set it to the number of rows
#   a2 (int*)  is a pointer to an integer, we will set it to the number of columns
# Returns:
#   a0 (int*)  is the pointer to the matrix in memory
# Exceptions:
# - If malloc returns an error,
#   this function terminates the program with error code 88.
# - If you receive an fopen error or eof, 
#   this function terminates the program with error code 90.
# - If you receive an fread error or eof,
#   this function terminates the program with error code 91.
# - If you receive an fclose error or eof,
#   this function terminates the program with error code 92.
# ==============================================================================

read_matrix:

    # a0 - file_path a1 - storage rows a2 - storage cols
    # Prologue
    addi sp, sp, -24
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    sw s2, 12(sp)
    sw s3, 16(sp)
    sw s4, 20(sp)
    mv s0, a0
    mv s1, a1
    mv s2, a2

	# 1. open file   
    #       1. open file, fopen(a1 = file_path, a2 = 0 -> read) return a0 - file discriptor
    mv a1, s0
    li a2, 0
    jal fopen
    mv s3, a0

    # s0 - file path s1 - rows address s2 - cols address s3 - file discriptor s4 - buf addres

    #       2. really open? if a0 == -1, go to open_error
    li t0, -1
    beq a0, t0, open_error
    # 2. get its size   
    #       1. read 4byte， fread(a1 = file discriptor, a2 = s1 rows address, a3 = read number) return a0 - real read number
    mv a1, s3
    mv a2, s1
    li a3, 4
    jal fread
    #       2. read success? if a0 != 8, go to read_error
    li t0, 4
    bne a0, t0, read_error   
    #       3. read 4byte， fread(a1 = file discriptor, a2 = s2 cols address, a3 = read number) return a0 - real read number
    mv a1, s3
    mv a2, s2
    li a3, 4
    jal fread
    #       4. read success? if a0 != 8, go to read_error
    li t0, 4
    bne a0, t0, read_error  
    # 3. malloc memory according to its size 
    #       1. malloc rows * cols * 4 byte space to storage size
    lw t0, 0(s1)
    lw t1, 0(s2)
    mul t0, t0, t1
    slli a0, t0, 2
    mv s0, a0   # s0 - malloc bytes
    jal malloc
    #       2. is a nullptr? if a0 == 0, go to malloc_error
    beq a0, zero, malloc_error
    mv s1, a0  # s1 - malloc address
    # 4. read the ramainder of the file
    #       1. read its remainder
    mv a1, s3
    mv a2, s1
    mv a3, s0
    jal fread
    #       2. read success? if a0 != cols * rows * 4, go to read_error 
    bne a0, s0, read_error
    # 5. close file
    #       1.  close file, fclose(a1 = file_discriptor) return a0 indicate its close state
    mv a1, s3
    jal fclose
    #       2.  close success? if a0 != 0, go to close_error
    bne a0, zero, close_error
    mv a0, s1
    # Epilogue
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    lw s3, 16(sp)
    lw s4, 20(sp)
    addi sp, sp, 24

    ret

open_error:
    # exit with code 90 
    li a1, 90
    jal exit2
malloc_error:
    # exit with code 88 
    li a1, 88
    jal exit2
read_error:
    # exit with code 91
    li a1, 91
    jal exit2
close_error:
    # exit with code 92
    li a1, 92
    jal exit2
