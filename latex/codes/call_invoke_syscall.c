int exhibit(int mbox_idx, void *msg, int msg_length)
{
    return invoke_syscall(SYS_EXHIBIT,\
                          (long)mbox_idx, \
                          (long)msg, \
                          msg_length, IGNORE, IGNORE);
}