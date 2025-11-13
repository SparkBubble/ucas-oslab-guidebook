static long invoke_syscall(long sysno, long arg0, long arg1, long arg2,
                           long arg3, long arg4)
{                           
    long res;
    asm volatile(
        "mv a7, %[sysno]\n\t"
        ...
        :"=r"(res)
        :[sysno] "r" (sysno)
        :"r" (sysno) ...
    );
}