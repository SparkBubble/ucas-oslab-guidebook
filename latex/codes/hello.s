	.file	"hello.c"
	.text
	.section	.rodata
.LC0:
	.string	"Hello World!"
	.text
	.globl	hello_world
	.type	hello_world, @function
hello_world:
.LFB0:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	leaq	.LC0(%rip), %rdi
	call	puts@PLT
	nop
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE0:
	.size	hello_world, .-hello_world
	.ident	"GCC: (Gentoo 9.1.0-r1 p1.1) 9.1.0"
	.section	.note.GNU-stack,"",@progbits
