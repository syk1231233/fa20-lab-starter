.globl classify

.text
classify:
    # =====================================
    # COMMAND LINE ARGUMENTS
    # =====================================
    # Args:
    #   a0 (int)    argc
    #   a1 (char**) argv
    #   a2 (int)    print_classification, if this is zero, 
    #               you should print the classification. Otherwise,
    #               this function should not print ANYTHING.
    # Returns:
    #   a0 (int)    Classification
    # Exceptions:
    # - If there are an incorrect number of command line args,
    #   this function terminates the program with exit code 89.
    # - If malloc fails, this function terminats the program with exit code 88.
    #
    # Usage:
    #   main.s <M0_PATH> <M1_PATH> <INPUT_PATH> <OUTPUT_PATH>

    # if argc != 5, go to argc_error
    li t0, 5
    bne a0, t0, argc_error

    # prologue
    addi sp, sp, -36
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    sw s2, 12(sp)
    sw s3, 16(sp)
    sw s4, 20(sp)
    sw s5, 24(sp)
    sw s6, 28(sp)
    sw s7, 32(sp)
    mv s0, a1
    mv s1, a2

    # s0 argv <M0_PATH> <M1_PATH> <INPUT_PATH> <OUTPUT_PATH>
    # s1 is_print classficatioon?
    # s2 m0 address
    # s3 m1 address
    # s4 input address
    # s5 outout address
    # s6 new outout address
    # s7 result

	# =====================================
    # LOAD MATRICES
    # =====================================
    # 1. open sp 8 byte to stroge rows and cols
    # 2. call read_matrix(a0 - file path a1 - rows address a2 - cols address) return a0 memory address

    # Load pretrained m0
    addi sp, sp, -8
    lw a0, 4(s0)    
    addi a1, sp, 0
    addi a2, sp, 4
    jal read_matrix
    mv s2, a0
    # Load pretrained m1
    addi sp, sp, -8
    lw a0, 8(s0)    
    addi a1, sp, 0
    addi a2, sp, 4
    jal read_matrix
    mv s3, a0
    # Load input matrix
    addi sp, sp, -8
    lw a0, 12(s0)    
    addi a1, sp, 0
    addi a2, sp, 4
    jal read_matrix
    mv s4, a0
    # =====================================
    # RUN LAYERS
    # =====================================
    # 1. LINEAR LAYER:    m0 * input
    #       1. malloc output matrix storage space, call malloc(m0_r * input_c * 4)
    lw t0, 16(sp)
    lw t1, 4(sp)
    mul t0, t0, t1
    slli a0, t0, 2
    jal malloc
    beq a0, zero, malloc_error
    mv s5, a0  
    #       2. call matmul(a0 - m0 address a1 - m0_r a2 - m0_c a3 - input address a4 - input_r a5 - input_c a6 - output address)
    mv a0, s2
    lw a1, 16(sp)
    lw a2, 20(sp)
    mv a3, s4
    lw a4, 0(sp)
    lw a5, 4(sp)
    mv a6, s5
    jal matmul
    # 2. NONLINEAR LAYER: ReLU(m0 * input)
    #       1. call relu(a0 - output address a1 - m0_r * input_c)
    mv a0, s5
    lw t0, 16(sp)
    lw t1, 4(sp)
    mul a1, t0, t1
    jal relu
    # 3. LINEAR LAYER:    m1 * ReLU(m0 * input)
    #       1. malloc new_output matrix storage space, call malloc(m1_r * output_c * 4)
    lw t0, 8(sp)
    lw t1, 4(sp)
    mul t0, t0, t1
    slli a0, t0, 2
    jal malloc
    beq a0, zero, malloc_error
    mv s6, a0
    #       2. call matmul(a0 - m1 address a1 - m1_r a2 - m1_c a3 - output address a4 - output_r a5 - outpur_c a6 - new_outpur address)
    mv a0, s3
    lw a1, 8(sp)
    lw a2, 12(sp)
    mv a3, s5
    lw a4, 16(sp)
    lw a5, 4(sp)
    mv a6, s6
    jal matmul
    # =====================================
    # WRITE OUTPUT
    # =====================================
    # Write output matrix
    # 1. call write_matrix(a0 - file path a1 - new output address a2 - new output rows a3 - new output cols)
    lw a0, 16(s0)
    mv a1, s6
    lw a2, 8(sp)
    lw a3, 4(sp)
    jal write_matrix
    # =====================================
    # CALCULATE CLASSIFICATION/LABEL
    # =====================================
    # Call argmax
    # 1. call argmax(a0 - new output address a1 - output cols * output rows)
    mv a0, s6
    lw t0, 4(sp)
    lw t1, 16(sp)
    mul a1, t0, t1
    jal argmax
    mv s7, a0
    # 2. a0 is the indentify result
    # Print classification
    #-if a2 == 0: print a0, else go to end
    bne s1, zero, end
    # 1. call print_int(a1 - print num)
    mv a1, s7
    jal print_int
    # Print newline afterwards for clarity
    # 1. call print_char(a1 = '\n')
    li a1, '\n'
    jal print_char
end: 
    # free memory m0 m1 input output new_output
    mv a0, s2
    jal free

    mv a0, s3
    jal free

    mv a0, s4
    jal free

    mv a0, s5
    jal free

    mv a0, s6
    jal free

    # mv a0 , classify result
    mv a0, s7

    # epilogue
    addi sp, sp, 24
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    lw s3, 16(sp)
    lw s4, 20(sp)
    lw s5, 24(sp)
    lw s6, 28(sp)
    lw s7, 32(sp)
    addi sp, sp, 36

    ret

argc_error:
    # exit with code 89
    li a1, 89
    jal exit2
malloc_error:
    # exit with code 88
    li a1, 88
    jal exit2