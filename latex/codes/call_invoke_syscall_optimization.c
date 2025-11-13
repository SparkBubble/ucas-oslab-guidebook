int exhibit(int mbox_idx, void *msg, int msg_length)
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