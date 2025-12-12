#include <ulib.h>
#include <stdio.h>
#include <string.h>

static char shared_page[4096] = "ucore-cow";

int main(void)
{
    cprintf("[cow] parent before fork: %s\n", shared_page);
    int pid = fork();
    if (pid == 0)
    {
        // child tries to modify the shared buffer; should trigger COW
        shared_page[0] = 'C';
        shared_page[1] = 'H';
        shared_page[2] = 'I';
        cprintf("[cow] child modified buffer: %s\n", shared_page);
        exit(0);
    }
    else if (pid > 0)
    {
        wait();
        cprintf("[cow] parent after child exit: %s\n", shared_page);
        if (shared_page[0] == 'C')
        {
            cprintf("[cow] FAILED: parent saw child's write\n");
            return -1;
        }
        cprintf("[cow] PASSED: parent buffer intact\n");
        return 0;
    }
    cprintf("[cow] fork failed\n");
    return -1;
}
