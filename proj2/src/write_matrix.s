.globl write_matrix

.text
# ==============================================================================
# FUNCTION: Writes a matrix of integers into a binary file
# FILE FORMAT:
#   The first 8 bytes of the file will be two 4 byte ints representing the
#   numbers of rows and columns respectively. Every 4 bytes thereafter is an
#   element of the matrix in row-major order.
# Arguments:
#   a0 (char*) is the pointer to string representing the filename
#   a1 (int*)  is the pointer to the start of the matrix in memory
#   a2 (int)   is the number of rows in the matrix
#   a3 (int)   is the number of columns in the matrix
# Returns:
#   None
# Exceptions:
# - If you receive an fopen error or eof,
#   this function terminates the program with error code 93.
# - If you receive an fwrite error or eof,
#   this function terminates the program with error code 94.
# - If you receive an fclose error or eof,
#   this function terminates the program with error code 95.
# ==============================================================================
write_matrix:

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
    mv s3, a3
    # s0 - file path s1 - read matrix address s2 - rows s3 - cols s4 - file descriptor

    # 1. open file
    #   1. call fopen, fopen(a1 = a0 file path, a2 = 1 write) return a0 file discriptor
    mv a1, s0
    li a2, 1
    jal fopen
    #   2. open success? if a0 == -1, go to open_error
    li t0, -1
    beq a0, t0, open_error 
    mv s4, a0
    # 2. write 
    #   1. call fwrite, fwrite(a1 = file descriptor, a2 = Buffer to read from, a3 = Number of items to read from the buffer, a4 = Size of each item in the buffer) return a0 real write number
    addi sp, sp, -8
    sw s2, 0(sp)
    sw s3, 4(sp)
    mv a1, s4
    mv a2, sp
    li a3, 2
    li a4, 4
    jal fwrite
    li t0, 2
    bne a0, t0, write_error
    addi sp, sp, 8

    mv a1, s4
    mv a2, s1
    mul s0, s2, s3
    mv a3, s0
    li a4, 4
    jal fwrite
    bne a0, s0, write_error

    # 3. close file
    #   1. call fclose, fclose(a1 = file descriptor)  return a0 close state
    mv a1, s4
    jal fclose
    #   2. close success? if a0 == -1. go to close error
    li t0, -1
    beq a0, t0, close_error
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
    # exit with code 93
    li a1, 93
    jal exit2
write_error:
    # exit with code 94
    li a1, 94
    jal exit2
close_error:
    # exit with code 95
    li a1, 95
    jal exit2