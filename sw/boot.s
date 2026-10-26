.section .text.init
.global _start

_start:
    # Set stack pointer (x2 / sp) near the top of Data Memory 
    # (1024 words * 4 bytes = 4096 bytes = 0x00001000)
    la sp, 0x00001000

    # Jump to the main function in C
    call main

    # Safety net: Infinite loop if main ever returns
trap_loop:
    j trap_loop