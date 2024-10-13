.data
msg_fileName: .asciiz "Enter a wave file name:\n"
msg_fileSize: .asciiz "Enter the file size (in bytes):\n"
out_Max: .asciiz "Maximum amplitude: "
out_Min: .asciiz "Minimum amplitude: "
heading: .asciiz "Information about the wave file: \n================================\n"
new_line: .asciiz "\n"
filename: .space 100
file_descriptor: .word 0
buffer: .space 4096

.text
.globl main

main:
    # Ask for file name
    li $v0, 4
    la $a0, msg_fileName
    syscall
    
    # Read file name
    li $v0, 8
    la $a0, filename
    li $a1, 100
    syscall
    
    # Remove newline character from filename
    la $t0, filename
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

    # Ask for file size
    li $v0, 4
    la $a0, msg_fileSize
    syscall
    
    # Read file size
    li $v0, 5
    syscall
    move $s0, $v0  # $s0 now holds the file size
    
    # Open file
    li $v0, 13
    la $a0, filename
    li $a1, 0      # Opens file in read mode
    li $a2, 0
    syscall
    move $s1, $v0  # $s1 now holds the file descriptor
    
    # Skip the first 44 bytes (header)
    li $v0, 14
    move $a0, $s1
    la $a1, buffer
    li $a2, 44
    syscall
    
    # Initialize max and min values
    li $s2, -32768  # $s2 holds max value
    li $s3, 32767   # $s3 holds min value
    li $s4, 0       # $s4 is a flag to indicate if we've processed any samples
    
    # Read and process audio data
    subu $s0, $s0, 44  # Adjust file size to account for the header
    li $t0, 0          # Bytes read so far

read_loop:
    bge $t0, $s0, print_results  # If all bytes read, print results
    
    # Read a chunk of data
    li $v0, 14
    move $a0, $s1
    la $a1, buffer
    li $a2, 4096
    syscall
    
    move $t1, $v0  # $t1 holds number of bytes read
    add $t0, $t0, $t1  # Update total bytes read
    
    # Process the chunk
    la $t2, buffer  # $t2 points to current position in buffer
    li $t3, 0       # $t3 is the loop counter for processing

process_chunk:
    bge $t3, $t1, read_loop  # If processed all bytes in, read next
    
    # Load 2 bytes and combine into a single  signed integer
    lbu $t4, 0($t2)
    lbu $t5, 1($t2)
    sll $t5, $t5, 8
    or $t4, $t4, $t5
    
    
    sll $t4, $t4, 16
    sra $t4, $t4, 16
    
    # Update max and min
    beqz $s4, first_sample
    bgt $t4, $s2, update_max
    blt $t4, $s3, update_min
    j continue_process

first_sample:
    li $s4, 1       # Set flag to indicate we've processed a sample
    move $s2, $t4   # Set first sample as both max and min
    move $s3, $t4
    j continue_process

update_max:
    move $s2, $t4
    j continue_process

update_min:
    move $s3, $t4

continue_process:
    addi $t2, $t2, 2  # Move to next sample
    addi $t3, $t3, 2  # Increment loop counter
    j process_chunk

print_results:
    # Display heading 
    li $v0, 4
    la $a0, heading
    syscall

    # Print max value
    li $v0, 4
    la $a0, out_Max
    syscall
    move $a0, $s2
    li $v0, 1
    syscall
    li $v0, 4
    la $a0, new_line
    syscall
    
    # Print min value
    li $v0, 4
    la $a0, out_Min
    syscall
    move $a0, $s3
    li $v0, 1
    syscall
    li $v0, 4
    la $a0, new_line
    syscall
    
    # Close the file
    li $v0, 16
    move $a0, $s1
    syscall
    
    # Exit the program
    li $v0, 10
    syscall
