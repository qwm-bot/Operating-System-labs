#include <clock.h>
#include <console.h>
#include <defs.h>
#include <intr.h>
#include <kdebug.h>
#include <kmonitor.h>
#include <pmm.h>
#include <stdio.h>
#include <string.h>
#include <trap.h>
#include <dtb.h>

int kern_init(void) __attribute__((noreturn));
void grade_backtrace(void);

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
    dtb_init();
    cons_init();
    const char *message = "(THU.CST) os is loading ...\0";
    cputs(message);

    print_kerninfo();

    idt_init();

    pmm_init();

    // LAB3 CHALLENGE3: 测试异常处理
    cprintf("\n==== Testing Illegal Instruction Exception ====\n");
    // 触发非法指令异常: 在S模式下执行mret指令(mret只能在M模式执行)
    __asm__ __volatile__("mret");
    
    cprintf("\n==== Testing Breakpoint Exception ====\n");
    // 触发断点异常
    __asm__ __volatile__("ebreak");
    
    cprintf("\nAll exceptions handled successfully!\n\n");

    clock_init();
    intr_enable();

    while (1)
        ;
}

void __attribute__((noinline))
grade_backtrace2(int arg0, int arg1, int arg2, int arg3) {
    mon_backtrace(0, NULL, NULL);
}

void __attribute__((noinline)) grade_backtrace1(int arg0, int arg1) {
    grade_backtrace2(arg0, (uintptr_t)&arg0, arg1, (uintptr_t)&arg1);
}

void __attribute__((noinline)) grade_backtrace0(int arg0, int arg1, int arg2) {
    grade_backtrace1(arg0, arg2);
}

void grade_backtrace(void) { grade_backtrace0(0, (uintptr_t)kern_init, 0xffff0000); }