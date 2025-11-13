<exhibit>:
	addi	sp,sp,-64
	sd	ra,56(sp)
	sd	s0,48(sp)
	addi	s0,sp,64
	mv	a5,a0
	sd	a1,-32(s0)
	sd	a2,-40(s0)
	sd	a3,-48(s0)
	sd	a4,-56(s0)
	sw	a5,-20(s0)
	lw	a0,-20(s0)
	li	a4,0
	li	a5,0
	ld	a3,-48(s0)
	ld	a2,-40(s0)
	ld	a1,-32(s0)
	jal	ra,<invoke_syscall>
	mv	a5,a0
	sext.w	a5,a5
	mv	a0,a5
	ld	ra,56(sp)
	ld	s0,48(sp)
	addi	sp,sp,64
	ret

<invoke_syscall>:
	addi	sp,sp,-80
	sd	s0,72(sp)
	addi	s0,sp,80
	sd	a0,-40(s0)
	sd	a1,-48(s0)
	sd	a2,-56(s0)
	sd	a3,-64(s0)
	sd	a4,-72(s0)
	sd	a5,-80(s0)
	mv	a7,a0
	mv	a0,a1
	mv	a1,a2
	mv	a2,a3
	mv	a3,a4
	mv	a4,a5
	ecall
	mv	a5,a0
	sd	a5,-24(s0)
	nop
	mv	a0,a5
	ld	s0,72(sp)
	addi	sp,sp,80
	ret