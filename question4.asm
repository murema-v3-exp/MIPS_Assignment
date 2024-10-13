.data
    fileName:         .space 256
    fileDescriptor:   .word 0
    buffer:           .space 2       # Buffer for writing samples

    HEADER_SIZE:      .word 44
    HIGH_AMPLITUDE:   .half 32767    # 0x7fff
    LOW_AMPLITUDE:    .half -32768   # 0x8000

.text
.globl main

main:
    # Get file name
    li $v0, 8
    la $a0, fileName
    li $a1, 256
    syscall
    
    # Remove newline from fileName
    la $t0, fileName
remove_newline:
    lb $t1, ($t0)
    beqz $t1, end_remove_newline
    bne $t1, 10, not_newline
    sb $zero, ($t0)
    j end_remove_newline
not_newline:
    addi $t0, $t0, 1
    j remove_newline
end_remove_newline:

    # Get tone frequency
    li $v0, 5
    syscall
    move $s0, $v0  # $s0 = tone frequency

    # Get sample frequency
    li $v0, 5
    syscall
    move $s1, $v0  # $s1 = sample frequency

    # Get length of tone
    li $v0, 5
    syscall
    move $s2, $v0  # $s2 = length of tone

    # Open file for writing
    li $v0, 13
    la $a0, fileName
    li $a1, 0x41                    # Create and write mode
    li $a2, 0x1FF                   # File permissions
    syscall
    move $s3, $v0                   # $s3 is a file descriptor
    bltz $s3, exit_program          # If file open failed, exit

    # Write zeroed-out header
    li $t0, 44  # Header size
zero_header_loop:
    beqz $t0, end_zero_header
    li $v0, 15
    move $a0, $s3
    la $a1, buffer
    sw $zero, buffer
    li $a2, 1
    syscall
    addi $t0, $t0, -1
    j zero_header_loop
end_zero_header:

    # Calculate total samples
    mul $t0, $s1, $s2                       # total_samples = sample_freq * length
    
    # Calculate samples per half period
    div $t1, $s1, $s0                       # samples_per_period = sample_freq / tone_freq
    srl $t1, $t1, 1                         # samples_per_half_period = samples_per_period / 2
    
    # Generate and write square wave
    li $t2, 0                               # sample counter
    li $t3, 0                               # half period counter
    li $t4, 1                               # state (1 for high, 0 for low)
generate_wave:
    bge $t2, $t0, end_generate_wave
    
    bnez $t4, write_high
write_low:
    lh $t5, LOW_AMPLITUDE
    j write_sample
write_high:
    lh $t5, HIGH_AMPLITUDE
write_sample:
    sh $t5, buffer
    li $v0, 15
    move $a0, $s3
    la $a1, buffer
    li $a2, 2
    syscall
    
    addi $t2, $t2, 1
    addi $t3, $t3, 1
    
    bne $t3, $t1, generate_wave
    li $t3, 0
    xori $t4, $t4, 1                        # Toggle state
    j generate_wave
end_generate_wave:

    # Close file
    li $v0, 16
    move $a0, $s3
    syscall

exit_program:
    # Exit program
    li $v0, 10
    syscall
    