.data
prompt_filename: .asciiz "Enter a wave file name:\n"
prompt_filesize: .asciiz "Enter the file size (in bytes): "
info_header: .asciiz "Information about the wave file:\n================================\n"
channels_msg: .asciiz "Number of channels: "
sample_rate_msg: .asciiz "Sample rate: "
byte_rate_msg: .asciiz "Byte rate: "
bits_per_sample_msg: .asciiz "Bits per sample: "
newline: .asciiz "\n"
filename: .space 256            # space to store the filename
buffer: .space 44               # space to store the WAVE header


.text
.globl main                     # declares main as the global entry point 


main:
    # Prompt for filename
    li $v0, 4                   # syscall for printing a string
    la $a0, prompt_filename     # load the address of the prompt
    syscall

    # Read filename
    li $v0, 8                   # syscall for reading string
    la $a0, filename            # load address where the filename will be stored
    li $a1, 256                 # max number of characters to be printed
    syscall


# Remove newline from filename
    la $t0, filename            # load the filename into a register
remove_newline:
    lb $t1, ($t0)
    beqz $t1, end_remove_newline # if the byte is zero(null), ends the loop
    bne $t1, 10, next_char       # if the character is not a newline, we move to the next byte (skip)
    sb $zero, ($t0)              # if newline, replace with null (0) to show the new end of string
    j end_remove_newline         # exit loop

next_char:
    addi $t0, $t0, 1             # move to next address/byte        
    j remove_newline

end_remove_newline:

    # Prompt for file size     
    li $v0, 4                     
    la $a0, prompt_filesize
    syscall

    # Print newline after file size prompt
    li $v0, 4
    la $a0, newline
    syscall

    # Read file size 
    li $v0, 5                      # syscall for reading an integer
    syscall

    # Open file
    li $v0, 13                     # syscall for opening a file                     
    la $a0, filename               
    li $a1, 0                      # Read-only mode
    li $a2, 0                      # no special flags
    syscall
    move $s0, $v0                  # Save file descriptor

    # Check if file opened successfully
    bltz $s0, exit_program

    # Read header
    li $v0, 14                     # syscall for reading from a file
    move $a0, $s0                  # get file descriptor
    la $a1, buffer                 # set address of input buffer
    li $a2, 44                     # maximum number of characters to read
    syscall

    # Close file
    li $v0, 16                     # syscall for closing file
    move $a0, $s0                  # set file descriptor in ($s0) as argument
    syscall

    # Print info header
    li $v0, 4
    la $a0, info_header
    syscall

    # Print number of channels
    li $v0, 4
    la $a0, channels_msg
    syscall

    la $t0, buffer                # load the buffer's address into $t0
    lhu $a0, 22($t0)              # load halfword (16 bytes) from byte 22, into arguments
    li $v0, 1                     # syscall to print integer
    syscall

    li $v0, 4
    la $a0, newline               # print a newline
    syscall

    # Print sample rate
    li $v0, 4
    la $a0, sample_rate_msg
    syscall

    la $t0, buffer
    lw $a0, 24($t0)
    li $v0, 1
    syscall

    li $v0, 4
    la $a0, newline
    syscall

    # Print byte rate
    li $v0, 4
    la $a0, byte_rate_msg
    syscall

    la $t0, buffer
    lw $a0, 28($t0)
    li $v0, 1
    syscall

    li $v0, 4
    la $a0, newline
    syscall

    # Print bits per sample
    li $v0, 4
    la $a0, bits_per_sample_msg
    syscall

    la $t0, buffer
    lhu $a0, 34($t0)
    li $v0, 1
    syscall

    li $v0, 4
    la $a0, newline
    syscall

exit_program:
    # Exit program
    li $v0, 10
    syscall

