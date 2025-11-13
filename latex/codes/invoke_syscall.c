static long invoke_syscall(long sysno, long arg0, long arg1, long arg2,
                           long arg3, long arg4)
{                           
    long res;
    asm volatile(
        "add a7, zero, a0\n\t"
        "add a0, zero, a1\n\t"
        "add a1, zero, a2\n\t"
        "add a2, zero, a3\n\t"
        "add a3, zero, a4\n\t"
        "add a4, zero, a5\n\t"
        "ecall\n\t"
        "mv %0, a0"
        :"=r"(res)
    );
}