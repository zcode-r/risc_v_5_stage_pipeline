OUTPUT_ARCH("riscv")
ENTRY(_start)

SECTIONS
{
  /* Instruction Memory starts at address 0x00000000 */
  . = 0x00000000;

  .text : {
    *(.text.init)   /* Put _start from boot.s first at 0x00000000 */
    *(.text*)       /* Then place all compiled C function code */
  }

  /* Data Memory alignment (4-byte aligned) */
  . = ALIGN(4);

  .data : {
    *(.data*)
    *(.rodata*)
  }

  .bss : {
    *(.bss*)
  }
}