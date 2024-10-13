.data
buffer: .space 4096  # Buffer for reading/writing data
header: .space 44    # Buffer for the header
error_msg: .asciiz "Error: File operation failed\n"

.text
.globl main

main:
    # Read input file name
    li $v0, 8
    la $a0, ($sp)
    li $a1, 100
    syscall
    jal remove_newline


    # Read output file name
    addi $sp, $sp, -100
    li $v0, 8
    move $a0, $sp
    li $a1, 100
    syscall
    jal remove_newline


    # Read file size
    li $v0, 5
    syscall
    move $s2, $v0  # $s2 is file size

    # Open input file
    li $v0, 13
    la $a0, 100($sp)
    li $a1, 0  # read-only mode
    li $a2, 0
    syscall
    bltz $v0, file_error
    move $s0, $v0  # $s0 is input file descriptor

    # Open output file
    li $v0, 13
    move $a0, $sp
    li $a1, 0x41  # Create and write-only mode
    li $a2, 0x1FF  # File permissions
    syscall
    bltz $v0, file_error
    move $s1, $v0  # $s1 = output file descriptor

    # Read and write header
    li $v0, 14
    move $a0, $s0
    la $a1, header
    li $a2, 44
    syscall
    bne $v0, 44, file_error

    # Write header to output
    li $v0, 15
    move $a0, $s1
    la $a1, header
    li $a2, 44
    syscall
    bne $v0, 44, file_error

    # Calculate data size
    addi $s3, $s2, -44  # $s3 is data size
    move $s4, $s3       # $s4 is remaining bytes to process

    # Allocate memory for entire audio data
    move $a0, $s3
    li $v0, 9  # sbrk
    syscall
    move $s5, $v0  # $s5 holds the address of allocated memory

    # Read entire audio data
    li $v0, 14
    move $a0, $s0
    move $a1, $s5
    move $a2, $s3
    syscall
    bne $v0, $s3, file_error

    # Reverse audio data (16-bit samples)
    move $t0, $s5               # Start of data
    add $t1, $s5, $s3
    addi $t1, $t1, -2           # End of data
reverse_data:
    bge $t0, $t1, write_data
    lhu $t2, ($t0)
    lhu $t3, ($t1)
    sh $t3, ($t0)
    sh $t2, ($t1)
    addi $t0, $t0, 2
    addi $t1, $t1, -2
    j reverse_data

write_data:
    # Write reversed audio data
    li $v0, 15
    move $a0, $s1
    move $a1, $s5
    move $a2, $s3
    syscall
    bne $v0, $s3, file_error

close_files:
    li $v0, 16
    move $a0, $s0
    syscall
    li $v0, 16
    move $a0, $s1
    syscall
    j exit_program

file_error:
    li $v0, 4
    la $a0, error_msg
    syscall
    j exit_program

exit_program:
    li $v0, 10
    syscall

remove_newline:
    li $t0, 0
remove_loop:
    lb $t1, ($a0)
    beqz $t1, end_remove
    bne $t1, 10, next_char
    sb $zero, ($a0)
    jr $ra
next_char:
    addi $a0, $a0, 1
    j remove_loop
end_remove:
    jr $ra
