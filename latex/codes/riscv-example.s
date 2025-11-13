	.file	"riscv-example.c"
	.option nopic
	.text
	.comm	buf,400,8
	.align	1
	.globl	do_sort
	.type	do_sort, @function
# void do_sort(int a[], int n)
do_sort:
	addi	sp,sp,-48
	sd	s0,40(sp)
	addi	s0,sp,48
	sd	a0,-40(s0)
	mv	a5,a1
	sw	a5,-44(s0)
	sw	zero,-20(s0)
	j	.L2
	# ...
	# 未经优化的代码太长了，不再赘述
	# 下面做了个a[i]^=a[j]
	lw	a5,-20(s0) # -20(s0)是i
	slli	a5,a5,2  # a5=i*4
	ld	a2,-40(s0) # 取出a[]的首地址
	add	a5,a2,a5 # a5现在是a[i]的地址了
	xor	a4,a3,a4 # a[i]^a[j]，a[i]和a[j]在前面已经load进a3和a4了
	sext.w	a4,a4
	sw	a4,0(a5) # 把结果写回a[i]的地址上
	# ...
	# 恢复保留寄存器的值，返回
	ld	s0,40(sp)
	addi	sp,sp,48
	jr	ra
	.size	do_sort, .-do_sort
	.section	.rodata
	.align	3
.LC0:
	.string	"%d"
	.align	3
.LC1:
	.string	"%d "
	.text
	.align	1
	.globl	main
	.type	main, @function
# int main()
main:
	# 分配栈空间,sp为栈顶，栈向下增长
	addi	sp,sp,-32
	# 保存保留寄存器
	sd	ra,24(sp)
	sd	s0,16(sp)
	# s0用作帧指针，指向栈底
	addi	s0,sp,32
	# scanf("%d", &n);
	addi	a5,s0,-28 # -28(s0) 是n的位置
	mv	a1,a5     # 把n作为scanf的第二个参数
	lui	a5,%hi(.LC0)
	addi	a0,a5,%lo(.LC0) # 把"%d"作为第一个参数
	call	__isoc99_scanf # 调用scanf
	# int t = n;
	lw	a5,-28(s0) # -28(s0)是n
	sw	a5,-20(s0) # -20(s0)是t
	j	.L8 # goto .L8
	# do {
.L9:
	# scanf("%d",&buf[t]);
	lw	a5,-20(s0)
	slli	a4,a5,2 # a4=t*4,int为4字节
	lui	a5,%hi(buf) 
	addi	a5,a5,%lo(buf) # a5=buf
	add	a5,a4,a5 # a5=buf+t*4,即&buf[t]
	mv	a1,a5  # a5作为scanf第二个参数
	lui	a5,%hi(.LC0) 
	addi	a0,a5,%lo(.LC0) # "%d"作为scanf第一个参数
	call	__isoc99_scanf  # 调用scanf
.L8:    # } while ((t--) != 0);
	lw	a5,-20(s0)
	addiw	a4,a5,-1
	sw	a4,-20(s0)
	# 上面三句实现的是t--，
	# 先把值取到a5,再把a5-1存回t的位置
	bne	a5,zero,.L9 # t!=0时跳回.L9,实现while的语义

	# sort(buf, n);
	lw	a5,-28(s0)
	mv	a1,a5 # n作为第二个参数
	lui	a5,%hi(buf) # buf作为第一个参数
	addi	a0,a5,%lo(buf)
	call	do_sort # 调用do_sort
	
	# int i = 0; goto .L10
	sw	zero,-24(s0) # -24(s0)是i 
	j	.L10
	# do {
.L11:
        # printf("%d ",buf[i])
	lui	a5,%hi(buf)
	addi	a4,a5,%lo(buf) # a4=buf
	lw	a5,-24(s0)
	slli	a5,a5,2 # a5= t*4
	add	a5,a4,a5 # a5=buf+t*4
	lw	a5,0(a5) # a5 = buf[t]
	mv	a1,a5 # buf[t]作为第二个参数
	lui	a5,%hi(.LC1)
	addi	a0,a5,%lo(.LC1) # "%d "作为第一个参数
	call	printf # 调用printf
	# ++i;
	lw	a5,-24(s0)
	addiw	a5,a5,1
	sw	a5,-24(s0)
.L10:   # } while (i < n);
	lw	a4,-28(s0)
	lw	a5,-24(s0)
	sext.w	a5,a5
	blt	a5,a4,.L11
	# printf("\n"); 用putchar('\n')实现的
	li	a0,10
	call	putchar
	li	a5,0
	# return 0;
	mv	a0,a5 # a0放返回值
	# 恢复ra、s0、sp原来的值
	ld	ra,24(sp)
	ld	s0,16(sp)
	addi	sp,sp,32
	jr	ra # 返回
	.size	main, .-main
	.ident	"GCC: (GNU) 8.3.0"
	.section	.note.GNU-stack,"",@progbits
