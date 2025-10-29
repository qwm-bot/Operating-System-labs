
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00006297          	auipc	t0,0x6
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0206000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00006297          	auipc	t0,0x6
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0206008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02052b7          	lui	t0,0xc0205
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	01e31313          	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200024:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200028:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002c:	fff0031b          	addiw	t1,zero,-1
ffffffffc0200030:	03f31313          	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200034:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200038:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc020003c:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc0200040:	c0205137          	lui	sp,0xc0205

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 1. 使用临时寄存器 t1 计算栈顶的精确地址
    lui t1, %hi(bootstacktop)
ffffffffc0200044:	c0205337          	lui	t1,0xc0205
    addi t1, t1, %lo(bootstacktop)
ffffffffc0200048:	00030313          	mv	t1,t1
    # 2. 将精确地址一次性地、安全地传给 sp
    mv sp, t1
ffffffffc020004c:	811a                	mv	sp,t1
    # 现在栈指针已经完美设置，可以安全地调用任何C函数了
    # 然后跳转到 kern_init (不再返回)
    lui t0, %hi(kern_init)
ffffffffc020004e:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200052:	05828293          	addi	t0,t0,88 # ffffffffc0200058 <kern_init>
    jr t0
ffffffffc0200056:	8282                	jr	t0

ffffffffc0200058 <kern_init>:
void grade_backtrace(void);

int kern_init(void) {
    extern char edata[], end[];
    // 先清零 BSS，再读取并保存 DTB 的内存信息，避免被清零覆盖（为了解释变化 正式上传时我觉得应该删去这句话）
    memset(edata, 0, end - edata);
ffffffffc0200058:	00006517          	auipc	a0,0x6
ffffffffc020005c:	fc850513          	addi	a0,a0,-56 # ffffffffc0206020 <edata>
ffffffffc0200060:	00006617          	auipc	a2,0x6
ffffffffc0200064:	43060613          	addi	a2,a2,1072 # ffffffffc0206490 <end>
int kern_init(void) {
ffffffffc0200068:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc020006a:	8e09                	sub	a2,a2,a0
ffffffffc020006c:	4581                	li	a1,0
int kern_init(void) {
ffffffffc020006e:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200070:	6df010ef          	jal	ra,ffffffffc0201f4e <memset>
    dtb_init();
ffffffffc0200074:	460000ef          	jal	ra,ffffffffc02004d4 <dtb_init>
    cons_init();  // init the console
ffffffffc0200078:	3e8000ef          	jal	ra,ffffffffc0200460 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc020007c:	00002517          	auipc	a0,0x2
ffffffffc0200080:	ee450513          	addi	a0,a0,-284 # ffffffffc0201f60 <etext>
ffffffffc0200084:	08e000ef          	jal	ra,ffffffffc0200112 <cputs>

    print_kerninfo();
ffffffffc0200088:	0da000ef          	jal	ra,ffffffffc0200162 <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc020008c:	752000ef          	jal	ra,ffffffffc02007de <idt_init>

    pmm_init();  // init physical memory management
ffffffffc0200090:	702010ef          	jal	ra,ffffffffc0201792 <pmm_init>

    idt_init();  // init interrupt descriptor table
ffffffffc0200094:	74a000ef          	jal	ra,ffffffffc02007de <idt_init>

    clock_init();   // init clock interrupt
ffffffffc0200098:	396000ef          	jal	ra,ffffffffc020042e <clock_init>
    intr_enable();  // enable irq interrupt
ffffffffc020009c:	736000ef          	jal	ra,ffffffffc02007d2 <intr_enable>

    /* do nothing */
    while (1)
        ;
ffffffffc02000a0:	a001                	j	ffffffffc02000a0 <kern_init+0x48>

ffffffffc02000a2 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc02000a2:	1141                	addi	sp,sp,-16
ffffffffc02000a4:	e022                	sd	s0,0(sp)
ffffffffc02000a6:	e406                	sd	ra,8(sp)
ffffffffc02000a8:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc02000aa:	3b8000ef          	jal	ra,ffffffffc0200462 <cons_putc>
    (*cnt) ++;
ffffffffc02000ae:	401c                	lw	a5,0(s0)
}
ffffffffc02000b0:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc02000b2:	2785                	addiw	a5,a5,1
ffffffffc02000b4:	c01c                	sw	a5,0(s0)
}
ffffffffc02000b6:	6402                	ld	s0,0(sp)
ffffffffc02000b8:	0141                	addi	sp,sp,16
ffffffffc02000ba:	8082                	ret

ffffffffc02000bc <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000bc:	1101                	addi	sp,sp,-32
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000be:	86ae                	mv	a3,a1
ffffffffc02000c0:	862a                	mv	a2,a0
ffffffffc02000c2:	006c                	addi	a1,sp,12
ffffffffc02000c4:	00000517          	auipc	a0,0x0
ffffffffc02000c8:	fde50513          	addi	a0,a0,-34 # ffffffffc02000a2 <cputch>
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000cc:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000ce:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000d0:	123010ef          	jal	ra,ffffffffc02019f2 <vprintfmt>
    return cnt;
}
ffffffffc02000d4:	60e2                	ld	ra,24(sp)
ffffffffc02000d6:	4532                	lw	a0,12(sp)
ffffffffc02000d8:	6105                	addi	sp,sp,32
ffffffffc02000da:	8082                	ret

ffffffffc02000dc <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000dc:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000de:	02810313          	addi	t1,sp,40 # ffffffffc0205028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc02000e2:	f42e                	sd	a1,40(sp)
ffffffffc02000e4:	f832                	sd	a2,48(sp)
ffffffffc02000e6:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000e8:	862a                	mv	a2,a0
ffffffffc02000ea:	004c                	addi	a1,sp,4
ffffffffc02000ec:	00000517          	auipc	a0,0x0
ffffffffc02000f0:	fb650513          	addi	a0,a0,-74 # ffffffffc02000a2 <cputch>
ffffffffc02000f4:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc02000f6:	ec06                	sd	ra,24(sp)
ffffffffc02000f8:	e0ba                	sd	a4,64(sp)
ffffffffc02000fa:	e4be                	sd	a5,72(sp)
ffffffffc02000fc:	e8c2                	sd	a6,80(sp)
ffffffffc02000fe:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc0200100:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200102:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200104:	0ef010ef          	jal	ra,ffffffffc02019f2 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc0200108:	60e2                	ld	ra,24(sp)
ffffffffc020010a:	4512                	lw	a0,4(sp)
ffffffffc020010c:	6125                	addi	sp,sp,96
ffffffffc020010e:	8082                	ret

ffffffffc0200110 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc0200110:	ae89                	j	ffffffffc0200462 <cons_putc>

ffffffffc0200112 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200112:	1101                	addi	sp,sp,-32
ffffffffc0200114:	e822                	sd	s0,16(sp)
ffffffffc0200116:	ec06                	sd	ra,24(sp)
ffffffffc0200118:	e426                	sd	s1,8(sp)
ffffffffc020011a:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc020011c:	00054503          	lbu	a0,0(a0)
ffffffffc0200120:	c51d                	beqz	a0,ffffffffc020014e <cputs+0x3c>
ffffffffc0200122:	0405                	addi	s0,s0,1
ffffffffc0200124:	4485                	li	s1,1
ffffffffc0200126:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200128:	33a000ef          	jal	ra,ffffffffc0200462 <cons_putc>
    (*cnt) ++;
ffffffffc020012c:	008487bb          	addw	a5,s1,s0
    while ((c = *str ++) != '\0') {
ffffffffc0200130:	0405                	addi	s0,s0,1
ffffffffc0200132:	fff44503          	lbu	a0,-1(s0)
ffffffffc0200136:	f96d                	bnez	a0,ffffffffc0200128 <cputs+0x16>
ffffffffc0200138:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc020013c:	4529                	li	a0,10
ffffffffc020013e:	324000ef          	jal	ra,ffffffffc0200462 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc0200142:	8522                	mv	a0,s0
ffffffffc0200144:	60e2                	ld	ra,24(sp)
ffffffffc0200146:	6442                	ld	s0,16(sp)
ffffffffc0200148:	64a2                	ld	s1,8(sp)
ffffffffc020014a:	6105                	addi	sp,sp,32
ffffffffc020014c:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc020014e:	4405                	li	s0,1
ffffffffc0200150:	b7f5                	j	ffffffffc020013c <cputs+0x2a>

ffffffffc0200152 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc0200152:	1141                	addi	sp,sp,-16
ffffffffc0200154:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200156:	314000ef          	jal	ra,ffffffffc020046a <cons_getc>
ffffffffc020015a:	dd75                	beqz	a0,ffffffffc0200156 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc020015c:	60a2                	ld	ra,8(sp)
ffffffffc020015e:	0141                	addi	sp,sp,16
ffffffffc0200160:	8082                	ret

ffffffffc0200162 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc0200162:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200164:	00002517          	auipc	a0,0x2
ffffffffc0200168:	e4c50513          	addi	a0,a0,-436 # ffffffffc0201fb0 <etext+0x50>
void print_kerninfo(void) {
ffffffffc020016c:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc020016e:	f6fff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc0200172:	00000597          	auipc	a1,0x0
ffffffffc0200176:	ee658593          	addi	a1,a1,-282 # ffffffffc0200058 <kern_init>
ffffffffc020017a:	00002517          	auipc	a0,0x2
ffffffffc020017e:	e5650513          	addi	a0,a0,-426 # ffffffffc0201fd0 <etext+0x70>
ffffffffc0200182:	f5bff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc0200186:	00002597          	auipc	a1,0x2
ffffffffc020018a:	dda58593          	addi	a1,a1,-550 # ffffffffc0201f60 <etext>
ffffffffc020018e:	00002517          	auipc	a0,0x2
ffffffffc0200192:	e6250513          	addi	a0,a0,-414 # ffffffffc0201ff0 <etext+0x90>
ffffffffc0200196:	f47ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc020019a:	00006597          	auipc	a1,0x6
ffffffffc020019e:	e8658593          	addi	a1,a1,-378 # ffffffffc0206020 <edata>
ffffffffc02001a2:	00002517          	auipc	a0,0x2
ffffffffc02001a6:	e6e50513          	addi	a0,a0,-402 # ffffffffc0202010 <etext+0xb0>
ffffffffc02001aa:	f33ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc02001ae:	00006597          	auipc	a1,0x6
ffffffffc02001b2:	2e258593          	addi	a1,a1,738 # ffffffffc0206490 <end>
ffffffffc02001b6:	00002517          	auipc	a0,0x2
ffffffffc02001ba:	e7a50513          	addi	a0,a0,-390 # ffffffffc0202030 <etext+0xd0>
ffffffffc02001be:	f1fff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc02001c2:	00006597          	auipc	a1,0x6
ffffffffc02001c6:	6cd58593          	addi	a1,a1,1741 # ffffffffc020688f <end+0x3ff>
ffffffffc02001ca:	00000797          	auipc	a5,0x0
ffffffffc02001ce:	e8e78793          	addi	a5,a5,-370 # ffffffffc0200058 <kern_init>
ffffffffc02001d2:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001d6:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02001da:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001dc:	3ff5f593          	andi	a1,a1,1023
ffffffffc02001e0:	95be                	add	a1,a1,a5
ffffffffc02001e2:	85a9                	srai	a1,a1,0xa
ffffffffc02001e4:	00002517          	auipc	a0,0x2
ffffffffc02001e8:	e6c50513          	addi	a0,a0,-404 # ffffffffc0202050 <etext+0xf0>
}
ffffffffc02001ec:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001ee:	b5fd                	j	ffffffffc02000dc <cprintf>

ffffffffc02001f0 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02001f0:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02001f2:	00002617          	auipc	a2,0x2
ffffffffc02001f6:	d8e60613          	addi	a2,a2,-626 # ffffffffc0201f80 <etext+0x20>
ffffffffc02001fa:	04d00593          	li	a1,77
ffffffffc02001fe:	00002517          	auipc	a0,0x2
ffffffffc0200202:	d9a50513          	addi	a0,a0,-614 # ffffffffc0201f98 <etext+0x38>
void print_stackframe(void) {
ffffffffc0200206:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc0200208:	1c6000ef          	jal	ra,ffffffffc02003ce <__panic>

ffffffffc020020c <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc020020c:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020020e:	00002617          	auipc	a2,0x2
ffffffffc0200212:	f5260613          	addi	a2,a2,-174 # ffffffffc0202160 <commands+0xe0>
ffffffffc0200216:	00002597          	auipc	a1,0x2
ffffffffc020021a:	f6a58593          	addi	a1,a1,-150 # ffffffffc0202180 <commands+0x100>
ffffffffc020021e:	00002517          	auipc	a0,0x2
ffffffffc0200222:	f6a50513          	addi	a0,a0,-150 # ffffffffc0202188 <commands+0x108>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200226:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200228:	eb5ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
ffffffffc020022c:	00002617          	auipc	a2,0x2
ffffffffc0200230:	f6c60613          	addi	a2,a2,-148 # ffffffffc0202198 <commands+0x118>
ffffffffc0200234:	00002597          	auipc	a1,0x2
ffffffffc0200238:	f8c58593          	addi	a1,a1,-116 # ffffffffc02021c0 <commands+0x140>
ffffffffc020023c:	00002517          	auipc	a0,0x2
ffffffffc0200240:	f4c50513          	addi	a0,a0,-180 # ffffffffc0202188 <commands+0x108>
ffffffffc0200244:	e99ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
ffffffffc0200248:	00002617          	auipc	a2,0x2
ffffffffc020024c:	f8860613          	addi	a2,a2,-120 # ffffffffc02021d0 <commands+0x150>
ffffffffc0200250:	00002597          	auipc	a1,0x2
ffffffffc0200254:	fa058593          	addi	a1,a1,-96 # ffffffffc02021f0 <commands+0x170>
ffffffffc0200258:	00002517          	auipc	a0,0x2
ffffffffc020025c:	f3050513          	addi	a0,a0,-208 # ffffffffc0202188 <commands+0x108>
ffffffffc0200260:	e7dff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    }
    return 0;
}
ffffffffc0200264:	60a2                	ld	ra,8(sp)
ffffffffc0200266:	4501                	li	a0,0
ffffffffc0200268:	0141                	addi	sp,sp,16
ffffffffc020026a:	8082                	ret

ffffffffc020026c <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc020026c:	1141                	addi	sp,sp,-16
ffffffffc020026e:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc0200270:	ef3ff0ef          	jal	ra,ffffffffc0200162 <print_kerninfo>
    return 0;
}
ffffffffc0200274:	60a2                	ld	ra,8(sp)
ffffffffc0200276:	4501                	li	a0,0
ffffffffc0200278:	0141                	addi	sp,sp,16
ffffffffc020027a:	8082                	ret

ffffffffc020027c <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc020027c:	1141                	addi	sp,sp,-16
ffffffffc020027e:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc0200280:	f71ff0ef          	jal	ra,ffffffffc02001f0 <print_stackframe>
    return 0;
}
ffffffffc0200284:	60a2                	ld	ra,8(sp)
ffffffffc0200286:	4501                	li	a0,0
ffffffffc0200288:	0141                	addi	sp,sp,16
ffffffffc020028a:	8082                	ret

ffffffffc020028c <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc020028c:	7115                	addi	sp,sp,-224
ffffffffc020028e:	e962                	sd	s8,144(sp)
ffffffffc0200290:	8c2a                	mv	s8,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200292:	00002517          	auipc	a0,0x2
ffffffffc0200296:	e3650513          	addi	a0,a0,-458 # ffffffffc02020c8 <commands+0x48>
kmonitor(struct trapframe *tf) {
ffffffffc020029a:	ed86                	sd	ra,216(sp)
ffffffffc020029c:	e9a2                	sd	s0,208(sp)
ffffffffc020029e:	e5a6                	sd	s1,200(sp)
ffffffffc02002a0:	e1ca                	sd	s2,192(sp)
ffffffffc02002a2:	fd4e                	sd	s3,184(sp)
ffffffffc02002a4:	f952                	sd	s4,176(sp)
ffffffffc02002a6:	f556                	sd	s5,168(sp)
ffffffffc02002a8:	f15a                	sd	s6,160(sp)
ffffffffc02002aa:	ed5e                	sd	s7,152(sp)
ffffffffc02002ac:	e566                	sd	s9,136(sp)
ffffffffc02002ae:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002b0:	e2dff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc02002b4:	00002517          	auipc	a0,0x2
ffffffffc02002b8:	e3c50513          	addi	a0,a0,-452 # ffffffffc02020f0 <commands+0x70>
ffffffffc02002bc:	e21ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    if (tf != NULL) {
ffffffffc02002c0:	000c0563          	beqz	s8,ffffffffc02002ca <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc02002c4:	8562                	mv	a0,s8
ffffffffc02002c6:	6f8000ef          	jal	ra,ffffffffc02009be <print_trapframe>
ffffffffc02002ca:	00002c97          	auipc	s9,0x2
ffffffffc02002ce:	db6c8c93          	addi	s9,s9,-586 # ffffffffc0202080 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002d2:	00002997          	auipc	s3,0x2
ffffffffc02002d6:	e4698993          	addi	s3,s3,-442 # ffffffffc0202118 <commands+0x98>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002da:	00002917          	auipc	s2,0x2
ffffffffc02002de:	e4690913          	addi	s2,s2,-442 # ffffffffc0202120 <commands+0xa0>
        if (argc == MAXARGS - 1) {
ffffffffc02002e2:	4a3d                	li	s4,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002e4:	00002b17          	auipc	s6,0x2
ffffffffc02002e8:	e44b0b13          	addi	s6,s6,-444 # ffffffffc0202128 <commands+0xa8>
    if (argc == 0) {
ffffffffc02002ec:	00002a97          	auipc	s5,0x2
ffffffffc02002f0:	e94a8a93          	addi	s5,s5,-364 # ffffffffc0202180 <commands+0x100>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002f4:	4b8d                	li	s7,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002f6:	854e                	mv	a0,s3
ffffffffc02002f8:	27b010ef          	jal	ra,ffffffffc0201d72 <readline>
ffffffffc02002fc:	842a                	mv	s0,a0
ffffffffc02002fe:	dd65                	beqz	a0,ffffffffc02002f6 <kmonitor+0x6a>
ffffffffc0200300:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc0200304:	4481                	li	s1,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200306:	c999                	beqz	a1,ffffffffc020031c <kmonitor+0x90>
ffffffffc0200308:	854a                	mv	a0,s2
ffffffffc020030a:	427010ef          	jal	ra,ffffffffc0201f30 <strchr>
ffffffffc020030e:	c925                	beqz	a0,ffffffffc020037e <kmonitor+0xf2>
            *buf ++ = '\0';
ffffffffc0200310:	00144583          	lbu	a1,1(s0)
ffffffffc0200314:	00040023          	sb	zero,0(s0)
ffffffffc0200318:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020031a:	f5fd                	bnez	a1,ffffffffc0200308 <kmonitor+0x7c>
    if (argc == 0) {
ffffffffc020031c:	dce9                	beqz	s1,ffffffffc02002f6 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020031e:	6582                	ld	a1,0(sp)
ffffffffc0200320:	00002d17          	auipc	s10,0x2
ffffffffc0200324:	d60d0d13          	addi	s10,s10,-672 # ffffffffc0202080 <commands>
    if (argc == 0) {
ffffffffc0200328:	8556                	mv	a0,s5
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020032a:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020032c:	0d61                	addi	s10,s10,24
ffffffffc020032e:	39d010ef          	jal	ra,ffffffffc0201eca <strcmp>
ffffffffc0200332:	c919                	beqz	a0,ffffffffc0200348 <kmonitor+0xbc>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200334:	2405                	addiw	s0,s0,1
ffffffffc0200336:	09740463          	beq	s0,s7,ffffffffc02003be <kmonitor+0x132>
ffffffffc020033a:	000d3503          	ld	a0,0(s10)
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020033e:	6582                	ld	a1,0(sp)
ffffffffc0200340:	0d61                	addi	s10,s10,24
ffffffffc0200342:	389010ef          	jal	ra,ffffffffc0201eca <strcmp>
ffffffffc0200346:	f57d                	bnez	a0,ffffffffc0200334 <kmonitor+0xa8>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc0200348:	00141793          	slli	a5,s0,0x1
ffffffffc020034c:	97a2                	add	a5,a5,s0
ffffffffc020034e:	078e                	slli	a5,a5,0x3
ffffffffc0200350:	97e6                	add	a5,a5,s9
ffffffffc0200352:	6b9c                	ld	a5,16(a5)
ffffffffc0200354:	8662                	mv	a2,s8
ffffffffc0200356:	002c                	addi	a1,sp,8
ffffffffc0200358:	fff4851b          	addiw	a0,s1,-1
ffffffffc020035c:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc020035e:	f8055ce3          	bgez	a0,ffffffffc02002f6 <kmonitor+0x6a>
}
ffffffffc0200362:	60ee                	ld	ra,216(sp)
ffffffffc0200364:	644e                	ld	s0,208(sp)
ffffffffc0200366:	64ae                	ld	s1,200(sp)
ffffffffc0200368:	690e                	ld	s2,192(sp)
ffffffffc020036a:	79ea                	ld	s3,184(sp)
ffffffffc020036c:	7a4a                	ld	s4,176(sp)
ffffffffc020036e:	7aaa                	ld	s5,168(sp)
ffffffffc0200370:	7b0a                	ld	s6,160(sp)
ffffffffc0200372:	6bea                	ld	s7,152(sp)
ffffffffc0200374:	6c4a                	ld	s8,144(sp)
ffffffffc0200376:	6caa                	ld	s9,136(sp)
ffffffffc0200378:	6d0a                	ld	s10,128(sp)
ffffffffc020037a:	612d                	addi	sp,sp,224
ffffffffc020037c:	8082                	ret
        if (*buf == '\0') {
ffffffffc020037e:	00044783          	lbu	a5,0(s0)
ffffffffc0200382:	dfc9                	beqz	a5,ffffffffc020031c <kmonitor+0x90>
        if (argc == MAXARGS - 1) {
ffffffffc0200384:	03448863          	beq	s1,s4,ffffffffc02003b4 <kmonitor+0x128>
        argv[argc ++] = buf;
ffffffffc0200388:	00349793          	slli	a5,s1,0x3
ffffffffc020038c:	0118                	addi	a4,sp,128
ffffffffc020038e:	97ba                	add	a5,a5,a4
ffffffffc0200390:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200394:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc0200398:	2485                	addiw	s1,s1,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020039a:	e591                	bnez	a1,ffffffffc02003a6 <kmonitor+0x11a>
ffffffffc020039c:	b749                	j	ffffffffc020031e <kmonitor+0x92>
            buf ++;
ffffffffc020039e:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003a0:	00044583          	lbu	a1,0(s0)
ffffffffc02003a4:	ddad                	beqz	a1,ffffffffc020031e <kmonitor+0x92>
ffffffffc02003a6:	854a                	mv	a0,s2
ffffffffc02003a8:	389010ef          	jal	ra,ffffffffc0201f30 <strchr>
ffffffffc02003ac:	d96d                	beqz	a0,ffffffffc020039e <kmonitor+0x112>
ffffffffc02003ae:	00044583          	lbu	a1,0(s0)
ffffffffc02003b2:	bf91                	j	ffffffffc0200306 <kmonitor+0x7a>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02003b4:	45c1                	li	a1,16
ffffffffc02003b6:	855a                	mv	a0,s6
ffffffffc02003b8:	d25ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
ffffffffc02003bc:	b7f1                	j	ffffffffc0200388 <kmonitor+0xfc>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02003be:	6582                	ld	a1,0(sp)
ffffffffc02003c0:	00002517          	auipc	a0,0x2
ffffffffc02003c4:	d8850513          	addi	a0,a0,-632 # ffffffffc0202148 <commands+0xc8>
ffffffffc02003c8:	d15ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    return 0;
ffffffffc02003cc:	b72d                	j	ffffffffc02002f6 <kmonitor+0x6a>

ffffffffc02003ce <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02003ce:	00006317          	auipc	t1,0x6
ffffffffc02003d2:	06a30313          	addi	t1,t1,106 # ffffffffc0206438 <is_panic>
ffffffffc02003d6:	00032303          	lw	t1,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02003da:	715d                	addi	sp,sp,-80
ffffffffc02003dc:	ec06                	sd	ra,24(sp)
ffffffffc02003de:	e822                	sd	s0,16(sp)
ffffffffc02003e0:	f436                	sd	a3,40(sp)
ffffffffc02003e2:	f83a                	sd	a4,48(sp)
ffffffffc02003e4:	fc3e                	sd	a5,56(sp)
ffffffffc02003e6:	e0c2                	sd	a6,64(sp)
ffffffffc02003e8:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02003ea:	02031c63          	bnez	t1,ffffffffc0200422 <__panic+0x54>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02003ee:	4785                	li	a5,1
ffffffffc02003f0:	8432                	mv	s0,a2
ffffffffc02003f2:	00006717          	auipc	a4,0x6
ffffffffc02003f6:	04f72323          	sw	a5,70(a4) # ffffffffc0206438 <is_panic>

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003fa:	862e                	mv	a2,a1
    va_start(ap, fmt);
ffffffffc02003fc:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003fe:	85aa                	mv	a1,a0
ffffffffc0200400:	00002517          	auipc	a0,0x2
ffffffffc0200404:	e0050513          	addi	a0,a0,-512 # ffffffffc0202200 <commands+0x180>
    va_start(ap, fmt);
ffffffffc0200408:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020040a:	cd3ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    vcprintf(fmt, ap);
ffffffffc020040e:	65a2                	ld	a1,8(sp)
ffffffffc0200410:	8522                	mv	a0,s0
ffffffffc0200412:	cabff0ef          	jal	ra,ffffffffc02000bc <vcprintf>
    cprintf("\n");
ffffffffc0200416:	00002517          	auipc	a0,0x2
ffffffffc020041a:	c6250513          	addi	a0,a0,-926 # ffffffffc0202078 <etext+0x118>
ffffffffc020041e:	cbfff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc0200422:	3b6000ef          	jal	ra,ffffffffc02007d8 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc0200426:	4501                	li	a0,0
ffffffffc0200428:	e65ff0ef          	jal	ra,ffffffffc020028c <kmonitor>
ffffffffc020042c:	bfed                	j	ffffffffc0200426 <__panic+0x58>

ffffffffc020042e <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc020042e:	1141                	addi	sp,sp,-16
ffffffffc0200430:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
ffffffffc0200432:	02000793          	li	a5,32
ffffffffc0200436:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020043a:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020043e:	67e1                	lui	a5,0x18
ffffffffc0200440:	6a078793          	addi	a5,a5,1696 # 186a0 <BASE_ADDRESS-0xffffffffc01e7960>
ffffffffc0200444:	953e                	add	a0,a0,a5
ffffffffc0200446:	207010ef          	jal	ra,ffffffffc0201e4c <sbi_set_timer>
}
ffffffffc020044a:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc020044c:	00006797          	auipc	a5,0x6
ffffffffc0200450:	0007be23          	sd	zero,28(a5) # ffffffffc0206468 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200454:	00002517          	auipc	a0,0x2
ffffffffc0200458:	dcc50513          	addi	a0,a0,-564 # ffffffffc0202220 <commands+0x1a0>
}
ffffffffc020045c:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc020045e:	b9bd                	j	ffffffffc02000dc <cprintf>

ffffffffc0200460 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200460:	8082                	ret

ffffffffc0200462 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200462:	0ff57513          	andi	a0,a0,255
ffffffffc0200466:	1cb0106f          	j	ffffffffc0201e30 <sbi_console_putchar>

ffffffffc020046a <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc020046a:	1ff0106f          	j	ffffffffc0201e68 <sbi_console_getchar>

ffffffffc020046e <fdt64_to_cpu>:
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
}

static uint64_t fdt64_to_cpu(uint64_t x) {
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020046e:	0005069b          	sext.w	a3,a0
           fdt32_to_cpu(x >> 32);
ffffffffc0200472:	9501                	srai	a0,a0,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200474:	0085579b          	srliw	a5,a0,0x8
ffffffffc0200478:	00ff08b7          	lui	a7,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020047c:	0185531b          	srliw	t1,a0,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200480:	0086d71b          	srliw	a4,a3,0x8
ffffffffc0200484:	0185159b          	slliw	a1,a0,0x18
ffffffffc0200488:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020048c:	0105551b          	srliw	a0,a0,0x10
ffffffffc0200490:	6641                	lui	a2,0x10
ffffffffc0200492:	0186de1b          	srliw	t3,a3,0x18
ffffffffc0200496:	167d                	addi	a2,a2,-1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200498:	0186981b          	slliw	a6,a3,0x18
ffffffffc020049c:	0117f7b3          	and	a5,a5,a7
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004a0:	0065e5b3          	or	a1,a1,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004a4:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004a8:	0106d69b          	srliw	a3,a3,0x10
ffffffffc02004ac:	0085151b          	slliw	a0,a0,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004b0:	01177733          	and	a4,a4,a7
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004b4:	01c86833          	or	a6,a6,t3
ffffffffc02004b8:	8fcd                	or	a5,a5,a1
ffffffffc02004ba:	8d71                	and	a0,a0,a2
ffffffffc02004bc:	0086969b          	slliw	a3,a3,0x8
ffffffffc02004c0:	01076733          	or	a4,a4,a6
ffffffffc02004c4:	8ef1                	and	a3,a3,a2
ffffffffc02004c6:	8d5d                	or	a0,a0,a5
ffffffffc02004c8:	8f55                	or	a4,a4,a3
           fdt32_to_cpu(x >> 32);
ffffffffc02004ca:	1502                	slli	a0,a0,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02004cc:	1702                	slli	a4,a4,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02004ce:	9101                	srli	a0,a0,0x20
}
ffffffffc02004d0:	8d59                	or	a0,a0,a4
ffffffffc02004d2:	8082                	ret

ffffffffc02004d4 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc02004d4:	7159                	addi	sp,sp,-112
    cprintf("DTB Init\n");
ffffffffc02004d6:	00002517          	auipc	a0,0x2
ffffffffc02004da:	d6a50513          	addi	a0,a0,-662 # ffffffffc0202240 <commands+0x1c0>
void dtb_init(void) {
ffffffffc02004de:	f486                	sd	ra,104(sp)
ffffffffc02004e0:	f0a2                	sd	s0,96(sp)
ffffffffc02004e2:	e4ce                	sd	s3,72(sp)
ffffffffc02004e4:	eca6                	sd	s1,88(sp)
ffffffffc02004e6:	e8ca                	sd	s2,80(sp)
ffffffffc02004e8:	e0d2                	sd	s4,64(sp)
ffffffffc02004ea:	fc56                	sd	s5,56(sp)
ffffffffc02004ec:	f85a                	sd	s6,48(sp)
ffffffffc02004ee:	f45e                	sd	s7,40(sp)
ffffffffc02004f0:	f062                	sd	s8,32(sp)
ffffffffc02004f2:	ec66                	sd	s9,24(sp)
ffffffffc02004f4:	e86a                	sd	s10,16(sp)
ffffffffc02004f6:	e46e                	sd	s11,8(sp)
    cprintf("DTB Init\n");
ffffffffc02004f8:	be5ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02004fc:	00006797          	auipc	a5,0x6
ffffffffc0200500:	b0478793          	addi	a5,a5,-1276 # ffffffffc0206000 <boot_hartid>
ffffffffc0200504:	638c                	ld	a1,0(a5)
ffffffffc0200506:	00002517          	auipc	a0,0x2
ffffffffc020050a:	d4a50513          	addi	a0,a0,-694 # ffffffffc0202250 <commands+0x1d0>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020050e:	00006417          	auipc	s0,0x6
ffffffffc0200512:	afa40413          	addi	s0,s0,-1286 # ffffffffc0206008 <boot_dtb>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200516:	bc7ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020051a:	600c                	ld	a1,0(s0)
ffffffffc020051c:	00002517          	auipc	a0,0x2
ffffffffc0200520:	d4450513          	addi	a0,a0,-700 # ffffffffc0202260 <commands+0x1e0>
ffffffffc0200524:	bb9ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200528:	00043983          	ld	s3,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc020052c:	00002517          	auipc	a0,0x2
ffffffffc0200530:	d4c50513          	addi	a0,a0,-692 # ffffffffc0202278 <commands+0x1f8>
    if (boot_dtb == 0) {
ffffffffc0200534:	10098d63          	beqz	s3,ffffffffc020064e <dtb_init+0x17a>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200538:	57f5                	li	a5,-3
ffffffffc020053a:	07fa                	slli	a5,a5,0x1e
ffffffffc020053c:	00f98733          	add	a4,s3,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200540:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200542:	00ff0537          	lui	a0,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200546:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020054a:	0087d69b          	srliw	a3,a5,0x8
ffffffffc020054e:	0187959b          	slliw	a1,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200552:	8dd1                	or	a1,a1,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200554:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200558:	0107d79b          	srliw	a5,a5,0x10
ffffffffc020055c:	6641                	lui	a2,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020055e:	8ee9                	and	a3,a3,a0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200560:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200564:	167d                	addi	a2,a2,-1
ffffffffc0200566:	8dd5                	or	a1,a1,a3
ffffffffc0200568:	8ff1                	and	a5,a5,a2
ffffffffc020056a:	8fcd                	or	a5,a5,a1
ffffffffc020056c:	0007859b          	sext.w	a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc0200570:	d00e07b7          	lui	a5,0xd00e0
ffffffffc0200574:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed9a5d>
ffffffffc0200578:	0ef59a63          	bne	a1,a5,ffffffffc020066c <dtb_init+0x198>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc020057c:	471c                	lw	a5,8(a4)
ffffffffc020057e:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc0200580:	4b81                	li	s7,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200582:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200586:	0086d81b          	srliw	a6,a3,0x8
ffffffffc020058a:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020058e:	0186d31b          	srliw	t1,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200592:	0187999b          	slliw	s3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200596:	0187d89b          	srliw	a7,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020059a:	0108181b          	slliw	a6,a6,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020059e:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005a2:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005a6:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005aa:	00a87833          	and	a6,a6,a0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005ae:	00646433          	or	s0,s0,t1
ffffffffc02005b2:	0086969b          	slliw	a3,a3,0x8
ffffffffc02005b6:	0119e9b3          	or	s3,s3,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005ba:	8d6d                	and	a0,a0,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005bc:	0087979b          	slliw	a5,a5,0x8
ffffffffc02005c0:	01046433          	or	s0,s0,a6
ffffffffc02005c4:	8ef1                	and	a3,a3,a2
ffffffffc02005c6:	00a9e9b3          	or	s3,s3,a0
ffffffffc02005ca:	8ff1                	and	a5,a5,a2
ffffffffc02005cc:	8c55                	or	s0,s0,a3
ffffffffc02005ce:	00f9e9b3          	or	s3,s3,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02005d2:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02005d4:	1982                	slli	s3,s3,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02005d6:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02005d8:	0209d993          	srli	s3,s3,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02005dc:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02005de:	99ba                	add	s3,s3,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005e0:	00ff0cb7          	lui	s9,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005e4:	8b32                	mv	s6,a2
        switch (token) {
ffffffffc02005e6:	4c09                	li	s8,2
ffffffffc02005e8:	490d                	li	s2,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02005ea:	00002497          	auipc	s1,0x2
ffffffffc02005ee:	cde48493          	addi	s1,s1,-802 # ffffffffc02022c8 <commands+0x248>
        switch (token) {
ffffffffc02005f2:	4d91                	li	s11,4
ffffffffc02005f4:	4d05                	li	s10,1
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc02005f6:	0009a703          	lw	a4,0(s3)
ffffffffc02005fa:	00498a13          	addi	s4,s3,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005fe:	0087579b          	srliw	a5,a4,0x8
ffffffffc0200602:	0187161b          	slliw	a2,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200606:	0187559b          	srliw	a1,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020060a:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020060e:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200612:	0197f7b3          	and	a5,a5,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200616:	8e4d                	or	a2,a2,a1
ffffffffc0200618:	0087171b          	slliw	a4,a4,0x8
ffffffffc020061c:	8fd1                	or	a5,a5,a2
ffffffffc020061e:	01677733          	and	a4,a4,s6
ffffffffc0200622:	8fd9                	or	a5,a5,a4
ffffffffc0200624:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc0200626:	09878d63          	beq	a5,s8,ffffffffc02006c0 <dtb_init+0x1ec>
ffffffffc020062a:	06fc7463          	bgeu	s8,a5,ffffffffc0200692 <dtb_init+0x1be>
ffffffffc020062e:	09278c63          	beq	a5,s2,ffffffffc02006c6 <dtb_init+0x1f2>
ffffffffc0200632:	01b79463          	bne	a5,s11,ffffffffc020063a <dtb_init+0x166>
                in_memory_node = 0;
ffffffffc0200636:	89d2                	mv	s3,s4
ffffffffc0200638:	bf7d                	j	ffffffffc02005f6 <dtb_init+0x122>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc020063a:	00002517          	auipc	a0,0x2
ffffffffc020063e:	d0650513          	addi	a0,a0,-762 # ffffffffc0202340 <commands+0x2c0>
ffffffffc0200642:	a9bff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200646:	00002517          	auipc	a0,0x2
ffffffffc020064a:	d3250513          	addi	a0,a0,-718 # ffffffffc0202378 <commands+0x2f8>
}
ffffffffc020064e:	7406                	ld	s0,96(sp)
ffffffffc0200650:	70a6                	ld	ra,104(sp)
ffffffffc0200652:	64e6                	ld	s1,88(sp)
ffffffffc0200654:	6946                	ld	s2,80(sp)
ffffffffc0200656:	69a6                	ld	s3,72(sp)
ffffffffc0200658:	6a06                	ld	s4,64(sp)
ffffffffc020065a:	7ae2                	ld	s5,56(sp)
ffffffffc020065c:	7b42                	ld	s6,48(sp)
ffffffffc020065e:	7ba2                	ld	s7,40(sp)
ffffffffc0200660:	7c02                	ld	s8,32(sp)
ffffffffc0200662:	6ce2                	ld	s9,24(sp)
ffffffffc0200664:	6d42                	ld	s10,16(sp)
ffffffffc0200666:	6da2                	ld	s11,8(sp)
ffffffffc0200668:	6165                	addi	sp,sp,112
    cprintf("DTB init completed\n");
ffffffffc020066a:	bc8d                	j	ffffffffc02000dc <cprintf>
}
ffffffffc020066c:	7406                	ld	s0,96(sp)
ffffffffc020066e:	70a6                	ld	ra,104(sp)
ffffffffc0200670:	64e6                	ld	s1,88(sp)
ffffffffc0200672:	6946                	ld	s2,80(sp)
ffffffffc0200674:	69a6                	ld	s3,72(sp)
ffffffffc0200676:	6a06                	ld	s4,64(sp)
ffffffffc0200678:	7ae2                	ld	s5,56(sp)
ffffffffc020067a:	7b42                	ld	s6,48(sp)
ffffffffc020067c:	7ba2                	ld	s7,40(sp)
ffffffffc020067e:	7c02                	ld	s8,32(sp)
ffffffffc0200680:	6ce2                	ld	s9,24(sp)
ffffffffc0200682:	6d42                	ld	s10,16(sp)
ffffffffc0200684:	6da2                	ld	s11,8(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200686:	00002517          	auipc	a0,0x2
ffffffffc020068a:	c1250513          	addi	a0,a0,-1006 # ffffffffc0202298 <commands+0x218>
}
ffffffffc020068e:	6165                	addi	sp,sp,112
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200690:	b4b1                	j	ffffffffc02000dc <cprintf>
        switch (token) {
ffffffffc0200692:	fba794e3          	bne	a5,s10,ffffffffc020063a <dtb_init+0x166>
                int name_len = strlen(name);
ffffffffc0200696:	8552                	mv	a0,s4
ffffffffc0200698:	7ee010ef          	jal	ra,ffffffffc0201e86 <strlen>
ffffffffc020069c:	0005099b          	sext.w	s3,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02006a0:	4619                	li	a2,6
ffffffffc02006a2:	00002597          	auipc	a1,0x2
ffffffffc02006a6:	c1e58593          	addi	a1,a1,-994 # ffffffffc02022c0 <commands+0x240>
ffffffffc02006aa:	8552                	mv	a0,s4
ffffffffc02006ac:	049010ef          	jal	ra,ffffffffc0201ef4 <strncmp>
ffffffffc02006b0:	e111                	bnez	a0,ffffffffc02006b4 <dtb_init+0x1e0>
                    in_memory_node = 1;
ffffffffc02006b2:	4b85                	li	s7,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02006b4:	0a11                	addi	s4,s4,4
ffffffffc02006b6:	9a4e                	add	s4,s4,s3
ffffffffc02006b8:	ffca7a13          	andi	s4,s4,-4
                in_memory_node = 0;
ffffffffc02006bc:	89d2                	mv	s3,s4
ffffffffc02006be:	bf25                	j	ffffffffc02005f6 <dtb_init+0x122>
ffffffffc02006c0:	4b81                	li	s7,0
ffffffffc02006c2:	89d2                	mv	s3,s4
ffffffffc02006c4:	bf0d                	j	ffffffffc02005f6 <dtb_init+0x122>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006c6:	0049a783          	lw	a5,4(s3)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006ca:	00c98a13          	addi	s4,s3,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ce:	0087da9b          	srliw	s5,a5,0x8
ffffffffc02006d2:	0187971b          	slliw	a4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006d6:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006da:	010a9a9b          	slliw	s5,s5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006de:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006e2:	019afab3          	and	s5,s5,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006e6:	8f51                	or	a4,a4,a2
ffffffffc02006e8:	0087979b          	slliw	a5,a5,0x8
ffffffffc02006ec:	00eaeab3          	or	s5,s5,a4
ffffffffc02006f0:	0167f7b3          	and	a5,a5,s6
ffffffffc02006f4:	00faeab3          	or	s5,s5,a5
ffffffffc02006f8:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006fa:	000b9b63          	bnez	s7,ffffffffc0200710 <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc02006fe:	1a82                	slli	s5,s5,0x20
ffffffffc0200700:	0a0d                	addi	s4,s4,3
ffffffffc0200702:	020ada93          	srli	s5,s5,0x20
ffffffffc0200706:	9a56                	add	s4,s4,s5
ffffffffc0200708:	ffca7a13          	andi	s4,s4,-4
                in_memory_node = 0;
ffffffffc020070c:	89d2                	mv	s3,s4
ffffffffc020070e:	b5e5                	j	ffffffffc02005f6 <dtb_init+0x122>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200710:	0089a783          	lw	a5,8(s3)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200714:	85a6                	mv	a1,s1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200716:	0087d51b          	srliw	a0,a5,0x8
ffffffffc020071a:	0187971b          	slliw	a4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020071e:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200722:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200726:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020072a:	01957533          	and	a0,a0,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020072e:	8f51                	or	a4,a4,a2
ffffffffc0200730:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200734:	8d59                	or	a0,a0,a4
ffffffffc0200736:	0167f7b3          	and	a5,a5,s6
ffffffffc020073a:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc020073c:	1502                	slli	a0,a0,0x20
ffffffffc020073e:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200740:	9522                	add	a0,a0,s0
ffffffffc0200742:	788010ef          	jal	ra,ffffffffc0201eca <strcmp>
ffffffffc0200746:	fd45                	bnez	a0,ffffffffc02006fe <dtb_init+0x22a>
ffffffffc0200748:	47bd                	li	a5,15
ffffffffc020074a:	fb57fae3          	bgeu	a5,s5,ffffffffc02006fe <dtb_init+0x22a>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020074e:	00c9b503          	ld	a0,12(s3)
ffffffffc0200752:	d1dff0ef          	jal	ra,ffffffffc020046e <fdt64_to_cpu>
ffffffffc0200756:	84aa                	mv	s1,a0
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc0200758:	0149b503          	ld	a0,20(s3)
ffffffffc020075c:	d13ff0ef          	jal	ra,ffffffffc020046e <fdt64_to_cpu>
ffffffffc0200760:	842a                	mv	s0,a0
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200762:	00002517          	auipc	a0,0x2
ffffffffc0200766:	b6e50513          	addi	a0,a0,-1170 # ffffffffc02022d0 <commands+0x250>
ffffffffc020076a:	973ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc020076e:	85a6                	mv	a1,s1
ffffffffc0200770:	00002517          	auipc	a0,0x2
ffffffffc0200774:	b8050513          	addi	a0,a0,-1152 # ffffffffc02022f0 <commands+0x270>
ffffffffc0200778:	965ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020077c:	01445613          	srli	a2,s0,0x14
ffffffffc0200780:	85a2                	mv	a1,s0
ffffffffc0200782:	00002517          	auipc	a0,0x2
ffffffffc0200786:	b8650513          	addi	a0,a0,-1146 # ffffffffc0202308 <commands+0x288>
ffffffffc020078a:	953ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc020078e:	008485b3          	add	a1,s1,s0
ffffffffc0200792:	15fd                	addi	a1,a1,-1
ffffffffc0200794:	00002517          	auipc	a0,0x2
ffffffffc0200798:	b9450513          	addi	a0,a0,-1132 # ffffffffc0202328 <commands+0x2a8>
ffffffffc020079c:	941ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("DTB init completed\n");
ffffffffc02007a0:	00002517          	auipc	a0,0x2
ffffffffc02007a4:	bd850513          	addi	a0,a0,-1064 # ffffffffc0202378 <commands+0x2f8>
        memory_base = mem_base;
ffffffffc02007a8:	00006797          	auipc	a5,0x6
ffffffffc02007ac:	c897bc23          	sd	s1,-872(a5) # ffffffffc0206440 <memory_base>
        memory_size = mem_size;
ffffffffc02007b0:	00006797          	auipc	a5,0x6
ffffffffc02007b4:	c887bc23          	sd	s0,-872(a5) # ffffffffc0206448 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc02007b8:	bd59                	j	ffffffffc020064e <dtb_init+0x17a>

ffffffffc02007ba <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
ffffffffc02007ba:	00006797          	auipc	a5,0x6
ffffffffc02007be:	c8678793          	addi	a5,a5,-890 # ffffffffc0206440 <memory_base>
}
ffffffffc02007c2:	6388                	ld	a0,0(a5)
ffffffffc02007c4:	8082                	ret

ffffffffc02007c6 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc02007c6:	00006797          	auipc	a5,0x6
ffffffffc02007ca:	c8278793          	addi	a5,a5,-894 # ffffffffc0206448 <memory_size>
}
ffffffffc02007ce:	6388                	ld	a0,0(a5)
ffffffffc02007d0:	8082                	ret

ffffffffc02007d2 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02007d2:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc02007d6:	8082                	ret

ffffffffc02007d8 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc02007d8:	100177f3          	csrrci	a5,sstatus,2
ffffffffc02007dc:	8082                	ret

ffffffffc02007de <idt_init>:
     */

    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc02007de:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc02007e2:	00000797          	auipc	a5,0x0
ffffffffc02007e6:	2be78793          	addi	a5,a5,702 # ffffffffc0200aa0 <__alltraps>
ffffffffc02007ea:	10579073          	csrw	stvec,a5
}
ffffffffc02007ee:	8082                	ret

ffffffffc02007f0 <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02007f0:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc02007f2:	1141                	addi	sp,sp,-16
ffffffffc02007f4:	e022                	sd	s0,0(sp)
ffffffffc02007f6:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02007f8:	00002517          	auipc	a0,0x2
ffffffffc02007fc:	c8050513          	addi	a0,a0,-896 # ffffffffc0202478 <commands+0x3f8>
void print_regs(struct pushregs *gpr) {
ffffffffc0200800:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200802:	8dbff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200806:	640c                	ld	a1,8(s0)
ffffffffc0200808:	00002517          	auipc	a0,0x2
ffffffffc020080c:	c8850513          	addi	a0,a0,-888 # ffffffffc0202490 <commands+0x410>
ffffffffc0200810:	8cdff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200814:	680c                	ld	a1,16(s0)
ffffffffc0200816:	00002517          	auipc	a0,0x2
ffffffffc020081a:	c9250513          	addi	a0,a0,-878 # ffffffffc02024a8 <commands+0x428>
ffffffffc020081e:	8bfff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200822:	6c0c                	ld	a1,24(s0)
ffffffffc0200824:	00002517          	auipc	a0,0x2
ffffffffc0200828:	c9c50513          	addi	a0,a0,-868 # ffffffffc02024c0 <commands+0x440>
ffffffffc020082c:	8b1ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200830:	700c                	ld	a1,32(s0)
ffffffffc0200832:	00002517          	auipc	a0,0x2
ffffffffc0200836:	ca650513          	addi	a0,a0,-858 # ffffffffc02024d8 <commands+0x458>
ffffffffc020083a:	8a3ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc020083e:	740c                	ld	a1,40(s0)
ffffffffc0200840:	00002517          	auipc	a0,0x2
ffffffffc0200844:	cb050513          	addi	a0,a0,-848 # ffffffffc02024f0 <commands+0x470>
ffffffffc0200848:	895ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc020084c:	780c                	ld	a1,48(s0)
ffffffffc020084e:	00002517          	auipc	a0,0x2
ffffffffc0200852:	cba50513          	addi	a0,a0,-838 # ffffffffc0202508 <commands+0x488>
ffffffffc0200856:	887ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc020085a:	7c0c                	ld	a1,56(s0)
ffffffffc020085c:	00002517          	auipc	a0,0x2
ffffffffc0200860:	cc450513          	addi	a0,a0,-828 # ffffffffc0202520 <commands+0x4a0>
ffffffffc0200864:	879ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200868:	602c                	ld	a1,64(s0)
ffffffffc020086a:	00002517          	auipc	a0,0x2
ffffffffc020086e:	cce50513          	addi	a0,a0,-818 # ffffffffc0202538 <commands+0x4b8>
ffffffffc0200872:	86bff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200876:	642c                	ld	a1,72(s0)
ffffffffc0200878:	00002517          	auipc	a0,0x2
ffffffffc020087c:	cd850513          	addi	a0,a0,-808 # ffffffffc0202550 <commands+0x4d0>
ffffffffc0200880:	85dff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200884:	682c                	ld	a1,80(s0)
ffffffffc0200886:	00002517          	auipc	a0,0x2
ffffffffc020088a:	ce250513          	addi	a0,a0,-798 # ffffffffc0202568 <commands+0x4e8>
ffffffffc020088e:	84fff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200892:	6c2c                	ld	a1,88(s0)
ffffffffc0200894:	00002517          	auipc	a0,0x2
ffffffffc0200898:	cec50513          	addi	a0,a0,-788 # ffffffffc0202580 <commands+0x500>
ffffffffc020089c:	841ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc02008a0:	702c                	ld	a1,96(s0)
ffffffffc02008a2:	00002517          	auipc	a0,0x2
ffffffffc02008a6:	cf650513          	addi	a0,a0,-778 # ffffffffc0202598 <commands+0x518>
ffffffffc02008aa:	833ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc02008ae:	742c                	ld	a1,104(s0)
ffffffffc02008b0:	00002517          	auipc	a0,0x2
ffffffffc02008b4:	d0050513          	addi	a0,a0,-768 # ffffffffc02025b0 <commands+0x530>
ffffffffc02008b8:	825ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc02008bc:	782c                	ld	a1,112(s0)
ffffffffc02008be:	00002517          	auipc	a0,0x2
ffffffffc02008c2:	d0a50513          	addi	a0,a0,-758 # ffffffffc02025c8 <commands+0x548>
ffffffffc02008c6:	817ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc02008ca:	7c2c                	ld	a1,120(s0)
ffffffffc02008cc:	00002517          	auipc	a0,0x2
ffffffffc02008d0:	d1450513          	addi	a0,a0,-748 # ffffffffc02025e0 <commands+0x560>
ffffffffc02008d4:	809ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc02008d8:	604c                	ld	a1,128(s0)
ffffffffc02008da:	00002517          	auipc	a0,0x2
ffffffffc02008de:	d1e50513          	addi	a0,a0,-738 # ffffffffc02025f8 <commands+0x578>
ffffffffc02008e2:	ffaff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc02008e6:	644c                	ld	a1,136(s0)
ffffffffc02008e8:	00002517          	auipc	a0,0x2
ffffffffc02008ec:	d2850513          	addi	a0,a0,-728 # ffffffffc0202610 <commands+0x590>
ffffffffc02008f0:	fecff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc02008f4:	684c                	ld	a1,144(s0)
ffffffffc02008f6:	00002517          	auipc	a0,0x2
ffffffffc02008fa:	d3250513          	addi	a0,a0,-718 # ffffffffc0202628 <commands+0x5a8>
ffffffffc02008fe:	fdeff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200902:	6c4c                	ld	a1,152(s0)
ffffffffc0200904:	00002517          	auipc	a0,0x2
ffffffffc0200908:	d3c50513          	addi	a0,a0,-708 # ffffffffc0202640 <commands+0x5c0>
ffffffffc020090c:	fd0ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200910:	704c                	ld	a1,160(s0)
ffffffffc0200912:	00002517          	auipc	a0,0x2
ffffffffc0200916:	d4650513          	addi	a0,a0,-698 # ffffffffc0202658 <commands+0x5d8>
ffffffffc020091a:	fc2ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc020091e:	744c                	ld	a1,168(s0)
ffffffffc0200920:	00002517          	auipc	a0,0x2
ffffffffc0200924:	d5050513          	addi	a0,a0,-688 # ffffffffc0202670 <commands+0x5f0>
ffffffffc0200928:	fb4ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc020092c:	784c                	ld	a1,176(s0)
ffffffffc020092e:	00002517          	auipc	a0,0x2
ffffffffc0200932:	d5a50513          	addi	a0,a0,-678 # ffffffffc0202688 <commands+0x608>
ffffffffc0200936:	fa6ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc020093a:	7c4c                	ld	a1,184(s0)
ffffffffc020093c:	00002517          	auipc	a0,0x2
ffffffffc0200940:	d6450513          	addi	a0,a0,-668 # ffffffffc02026a0 <commands+0x620>
ffffffffc0200944:	f98ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200948:	606c                	ld	a1,192(s0)
ffffffffc020094a:	00002517          	auipc	a0,0x2
ffffffffc020094e:	d6e50513          	addi	a0,a0,-658 # ffffffffc02026b8 <commands+0x638>
ffffffffc0200952:	f8aff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200956:	646c                	ld	a1,200(s0)
ffffffffc0200958:	00002517          	auipc	a0,0x2
ffffffffc020095c:	d7850513          	addi	a0,a0,-648 # ffffffffc02026d0 <commands+0x650>
ffffffffc0200960:	f7cff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200964:	686c                	ld	a1,208(s0)
ffffffffc0200966:	00002517          	auipc	a0,0x2
ffffffffc020096a:	d8250513          	addi	a0,a0,-638 # ffffffffc02026e8 <commands+0x668>
ffffffffc020096e:	f6eff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200972:	6c6c                	ld	a1,216(s0)
ffffffffc0200974:	00002517          	auipc	a0,0x2
ffffffffc0200978:	d8c50513          	addi	a0,a0,-628 # ffffffffc0202700 <commands+0x680>
ffffffffc020097c:	f60ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200980:	706c                	ld	a1,224(s0)
ffffffffc0200982:	00002517          	auipc	a0,0x2
ffffffffc0200986:	d9650513          	addi	a0,a0,-618 # ffffffffc0202718 <commands+0x698>
ffffffffc020098a:	f52ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc020098e:	746c                	ld	a1,232(s0)
ffffffffc0200990:	00002517          	auipc	a0,0x2
ffffffffc0200994:	da050513          	addi	a0,a0,-608 # ffffffffc0202730 <commands+0x6b0>
ffffffffc0200998:	f44ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc020099c:	786c                	ld	a1,240(s0)
ffffffffc020099e:	00002517          	auipc	a0,0x2
ffffffffc02009a2:	daa50513          	addi	a0,a0,-598 # ffffffffc0202748 <commands+0x6c8>
ffffffffc02009a6:	f36ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc02009aa:	7c6c                	ld	a1,248(s0)
}
ffffffffc02009ac:	6402                	ld	s0,0(sp)
ffffffffc02009ae:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc02009b0:	00002517          	auipc	a0,0x2
ffffffffc02009b4:	db050513          	addi	a0,a0,-592 # ffffffffc0202760 <commands+0x6e0>
}
ffffffffc02009b8:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc02009ba:	f22ff06f          	j	ffffffffc02000dc <cprintf>

ffffffffc02009be <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc02009be:	1141                	addi	sp,sp,-16
ffffffffc02009c0:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc02009c2:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc02009c4:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc02009c6:	00002517          	auipc	a0,0x2
ffffffffc02009ca:	db250513          	addi	a0,a0,-590 # ffffffffc0202778 <commands+0x6f8>
void print_trapframe(struct trapframe *tf) {
ffffffffc02009ce:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc02009d0:	f0cff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    print_regs(&tf->gpr);
ffffffffc02009d4:	8522                	mv	a0,s0
ffffffffc02009d6:	e1bff0ef          	jal	ra,ffffffffc02007f0 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc02009da:	10043583          	ld	a1,256(s0)
ffffffffc02009de:	00002517          	auipc	a0,0x2
ffffffffc02009e2:	db250513          	addi	a0,a0,-590 # ffffffffc0202790 <commands+0x710>
ffffffffc02009e6:	ef6ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc02009ea:	10843583          	ld	a1,264(s0)
ffffffffc02009ee:	00002517          	auipc	a0,0x2
ffffffffc02009f2:	dba50513          	addi	a0,a0,-582 # ffffffffc02027a8 <commands+0x728>
ffffffffc02009f6:	ee6ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc02009fa:	11043583          	ld	a1,272(s0)
ffffffffc02009fe:	00002517          	auipc	a0,0x2
ffffffffc0200a02:	dc250513          	addi	a0,a0,-574 # ffffffffc02027c0 <commands+0x740>
ffffffffc0200a06:	ed6ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a0a:	11843583          	ld	a1,280(s0)
}
ffffffffc0200a0e:	6402                	ld	s0,0(sp)
ffffffffc0200a10:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a12:	00002517          	auipc	a0,0x2
ffffffffc0200a16:	dc650513          	addi	a0,a0,-570 # ffffffffc02027d8 <commands+0x758>
}
ffffffffc0200a1a:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a1c:	ec0ff06f          	j	ffffffffc02000dc <cprintf>

ffffffffc0200a20 <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200a20:	11853783          	ld	a5,280(a0)
    switch (cause) {
ffffffffc0200a24:	472d                	li	a4,11
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200a26:	0786                	slli	a5,a5,0x1
ffffffffc0200a28:	8385                	srli	a5,a5,0x1
    switch (cause) {
ffffffffc0200a2a:	06f76063          	bltu	a4,a5,ffffffffc0200a8a <interrupt_handler+0x6a>
ffffffffc0200a2e:	00002717          	auipc	a4,0x2
ffffffffc0200a32:	95e70713          	addi	a4,a4,-1698 # ffffffffc020238c <commands+0x30c>
ffffffffc0200a36:	078a                	slli	a5,a5,0x2
ffffffffc0200a38:	97ba                	add	a5,a5,a4
ffffffffc0200a3a:	439c                	lw	a5,0(a5)
ffffffffc0200a3c:	97ba                	add	a5,a5,a4
ffffffffc0200a3e:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc0200a40:	00002517          	auipc	a0,0x2
ffffffffc0200a44:	9e050513          	addi	a0,a0,-1568 # ffffffffc0202420 <commands+0x3a0>
ffffffffc0200a48:	e94ff06f          	j	ffffffffc02000dc <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc0200a4c:	00002517          	auipc	a0,0x2
ffffffffc0200a50:	9b450513          	addi	a0,a0,-1612 # ffffffffc0202400 <commands+0x380>
ffffffffc0200a54:	e88ff06f          	j	ffffffffc02000dc <cprintf>
            cprintf("User software interrupt\n");
ffffffffc0200a58:	00002517          	auipc	a0,0x2
ffffffffc0200a5c:	96850513          	addi	a0,a0,-1688 # ffffffffc02023c0 <commands+0x340>
ffffffffc0200a60:	e7cff06f          	j	ffffffffc02000dc <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc0200a64:	00002517          	auipc	a0,0x2
ffffffffc0200a68:	9dc50513          	addi	a0,a0,-1572 # ffffffffc0202440 <commands+0x3c0>
ffffffffc0200a6c:	e70ff06f          	j	ffffffffc02000dc <cprintf>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200a70:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc0200a72:	00002517          	auipc	a0,0x2
ffffffffc0200a76:	9e650513          	addi	a0,a0,-1562 # ffffffffc0202458 <commands+0x3d8>
ffffffffc0200a7a:	e62ff06f          	j	ffffffffc02000dc <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200a7e:	00002517          	auipc	a0,0x2
ffffffffc0200a82:	96250513          	addi	a0,a0,-1694 # ffffffffc02023e0 <commands+0x360>
ffffffffc0200a86:	e56ff06f          	j	ffffffffc02000dc <cprintf>
            print_trapframe(tf);
ffffffffc0200a8a:	bf15                	j	ffffffffc02009be <print_trapframe>

ffffffffc0200a8c <trap>:
            break;
    }
}

static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200a8c:	11853783          	ld	a5,280(a0)
ffffffffc0200a90:	0007c763          	bltz	a5,ffffffffc0200a9e <trap+0x12>
    switch (tf->cause) {
ffffffffc0200a94:	472d                	li	a4,11
ffffffffc0200a96:	00f76363          	bltu	a4,a5,ffffffffc0200a9c <trap+0x10>
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf) {
    // dispatch based on what type of trap occurred
    trap_dispatch(tf);
}
ffffffffc0200a9a:	8082                	ret
            print_trapframe(tf);
ffffffffc0200a9c:	b70d                	j	ffffffffc02009be <print_trapframe>
        interrupt_handler(tf);
ffffffffc0200a9e:	b749                	j	ffffffffc0200a20 <interrupt_handler>

ffffffffc0200aa0 <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc0200aa0:	14011073          	csrw	sscratch,sp
ffffffffc0200aa4:	712d                	addi	sp,sp,-288
ffffffffc0200aa6:	e002                	sd	zero,0(sp)
ffffffffc0200aa8:	e406                	sd	ra,8(sp)
ffffffffc0200aaa:	ec0e                	sd	gp,24(sp)
ffffffffc0200aac:	f012                	sd	tp,32(sp)
ffffffffc0200aae:	f416                	sd	t0,40(sp)
ffffffffc0200ab0:	f81a                	sd	t1,48(sp)
ffffffffc0200ab2:	fc1e                	sd	t2,56(sp)
ffffffffc0200ab4:	e0a2                	sd	s0,64(sp)
ffffffffc0200ab6:	e4a6                	sd	s1,72(sp)
ffffffffc0200ab8:	e8aa                	sd	a0,80(sp)
ffffffffc0200aba:	ecae                	sd	a1,88(sp)
ffffffffc0200abc:	f0b2                	sd	a2,96(sp)
ffffffffc0200abe:	f4b6                	sd	a3,104(sp)
ffffffffc0200ac0:	f8ba                	sd	a4,112(sp)
ffffffffc0200ac2:	fcbe                	sd	a5,120(sp)
ffffffffc0200ac4:	e142                	sd	a6,128(sp)
ffffffffc0200ac6:	e546                	sd	a7,136(sp)
ffffffffc0200ac8:	e94a                	sd	s2,144(sp)
ffffffffc0200aca:	ed4e                	sd	s3,152(sp)
ffffffffc0200acc:	f152                	sd	s4,160(sp)
ffffffffc0200ace:	f556                	sd	s5,168(sp)
ffffffffc0200ad0:	f95a                	sd	s6,176(sp)
ffffffffc0200ad2:	fd5e                	sd	s7,184(sp)
ffffffffc0200ad4:	e1e2                	sd	s8,192(sp)
ffffffffc0200ad6:	e5e6                	sd	s9,200(sp)
ffffffffc0200ad8:	e9ea                	sd	s10,208(sp)
ffffffffc0200ada:	edee                	sd	s11,216(sp)
ffffffffc0200adc:	f1f2                	sd	t3,224(sp)
ffffffffc0200ade:	f5f6                	sd	t4,232(sp)
ffffffffc0200ae0:	f9fa                	sd	t5,240(sp)
ffffffffc0200ae2:	fdfe                	sd	t6,248(sp)
ffffffffc0200ae4:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200ae8:	100024f3          	csrr	s1,sstatus
ffffffffc0200aec:	14102973          	csrr	s2,sepc
ffffffffc0200af0:	143029f3          	csrr	s3,stval
ffffffffc0200af4:	14202a73          	csrr	s4,scause
ffffffffc0200af8:	e822                	sd	s0,16(sp)
ffffffffc0200afa:	e226                	sd	s1,256(sp)
ffffffffc0200afc:	e64a                	sd	s2,264(sp)
ffffffffc0200afe:	ea4e                	sd	s3,272(sp)
ffffffffc0200b00:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200b02:	850a                	mv	a0,sp
    jal trap
ffffffffc0200b04:	f89ff0ef          	jal	ra,ffffffffc0200a8c <trap>

ffffffffc0200b08 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200b08:	6492                	ld	s1,256(sp)
ffffffffc0200b0a:	6932                	ld	s2,264(sp)
ffffffffc0200b0c:	10049073          	csrw	sstatus,s1
ffffffffc0200b10:	14191073          	csrw	sepc,s2
ffffffffc0200b14:	60a2                	ld	ra,8(sp)
ffffffffc0200b16:	61e2                	ld	gp,24(sp)
ffffffffc0200b18:	7202                	ld	tp,32(sp)
ffffffffc0200b1a:	72a2                	ld	t0,40(sp)
ffffffffc0200b1c:	7342                	ld	t1,48(sp)
ffffffffc0200b1e:	73e2                	ld	t2,56(sp)
ffffffffc0200b20:	6406                	ld	s0,64(sp)
ffffffffc0200b22:	64a6                	ld	s1,72(sp)
ffffffffc0200b24:	6546                	ld	a0,80(sp)
ffffffffc0200b26:	65e6                	ld	a1,88(sp)
ffffffffc0200b28:	7606                	ld	a2,96(sp)
ffffffffc0200b2a:	76a6                	ld	a3,104(sp)
ffffffffc0200b2c:	7746                	ld	a4,112(sp)
ffffffffc0200b2e:	77e6                	ld	a5,120(sp)
ffffffffc0200b30:	680a                	ld	a6,128(sp)
ffffffffc0200b32:	68aa                	ld	a7,136(sp)
ffffffffc0200b34:	694a                	ld	s2,144(sp)
ffffffffc0200b36:	69ea                	ld	s3,152(sp)
ffffffffc0200b38:	7a0a                	ld	s4,160(sp)
ffffffffc0200b3a:	7aaa                	ld	s5,168(sp)
ffffffffc0200b3c:	7b4a                	ld	s6,176(sp)
ffffffffc0200b3e:	7bea                	ld	s7,184(sp)
ffffffffc0200b40:	6c0e                	ld	s8,192(sp)
ffffffffc0200b42:	6cae                	ld	s9,200(sp)
ffffffffc0200b44:	6d4e                	ld	s10,208(sp)
ffffffffc0200b46:	6dee                	ld	s11,216(sp)
ffffffffc0200b48:	7e0e                	ld	t3,224(sp)
ffffffffc0200b4a:	7eae                	ld	t4,232(sp)
ffffffffc0200b4c:	7f4e                	ld	t5,240(sp)
ffffffffc0200b4e:	7fee                	ld	t6,248(sp)
ffffffffc0200b50:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200b52:	10200073          	sret

ffffffffc0200b56 <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200b56:	00005797          	auipc	a5,0x5
ffffffffc0200b5a:	4ca78793          	addi	a5,a5,1226 # ffffffffc0206020 <edata>
ffffffffc0200b5e:	e79c                	sd	a5,8(a5)
ffffffffc0200b60:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200b62:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200b66:	8082                	ret

ffffffffc0200b68 <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200b68:	00005517          	auipc	a0,0x5
ffffffffc0200b6c:	4c856503          	lwu	a0,1224(a0) # ffffffffc0206030 <edata+0x10>
ffffffffc0200b70:	8082                	ret

ffffffffc0200b72 <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200b72:	715d                	addi	sp,sp,-80
ffffffffc0200b74:	f84a                	sd	s2,48(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200b76:	00005917          	auipc	s2,0x5
ffffffffc0200b7a:	4aa90913          	addi	s2,s2,1194 # ffffffffc0206020 <edata>
ffffffffc0200b7e:	00893783          	ld	a5,8(s2)
ffffffffc0200b82:	e486                	sd	ra,72(sp)
ffffffffc0200b84:	e0a2                	sd	s0,64(sp)
ffffffffc0200b86:	fc26                	sd	s1,56(sp)
ffffffffc0200b88:	f44e                	sd	s3,40(sp)
ffffffffc0200b8a:	f052                	sd	s4,32(sp)
ffffffffc0200b8c:	ec56                	sd	s5,24(sp)
ffffffffc0200b8e:	e85a                	sd	s6,16(sp)
ffffffffc0200b90:	e45e                	sd	s7,8(sp)
ffffffffc0200b92:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200b94:	31278f63          	beq	a5,s2,ffffffffc0200eb2 <default_check+0x340>
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200b98:	ff07b703          	ld	a4,-16(a5)
ffffffffc0200b9c:	8305                	srli	a4,a4,0x1
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200b9e:	8b05                	andi	a4,a4,1
ffffffffc0200ba0:	30070d63          	beqz	a4,ffffffffc0200eba <default_check+0x348>
    int count = 0, total = 0;
ffffffffc0200ba4:	4401                	li	s0,0
ffffffffc0200ba6:	4481                	li	s1,0
ffffffffc0200ba8:	a031                	j	ffffffffc0200bb4 <default_check+0x42>
ffffffffc0200baa:	ff07b703          	ld	a4,-16(a5)
        assert(PageProperty(p));
ffffffffc0200bae:	8b09                	andi	a4,a4,2
ffffffffc0200bb0:	30070563          	beqz	a4,ffffffffc0200eba <default_check+0x348>
        count ++, total += p->property;
ffffffffc0200bb4:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200bb8:	679c                	ld	a5,8(a5)
ffffffffc0200bba:	2485                	addiw	s1,s1,1
ffffffffc0200bbc:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200bbe:	ff2796e3          	bne	a5,s2,ffffffffc0200baa <default_check+0x38>
ffffffffc0200bc2:	89a2                	mv	s3,s0
    }
    assert(total == nr_free_pages());
ffffffffc0200bc4:	38f000ef          	jal	ra,ffffffffc0201752 <nr_free_pages>
ffffffffc0200bc8:	75351963          	bne	a0,s3,ffffffffc020131a <default_check+0x7a8>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200bcc:	4505                	li	a0,1
ffffffffc0200bce:	2fb000ef          	jal	ra,ffffffffc02016c8 <alloc_pages>
ffffffffc0200bd2:	8a2a                	mv	s4,a0
ffffffffc0200bd4:	48050363          	beqz	a0,ffffffffc020105a <default_check+0x4e8>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200bd8:	4505                	li	a0,1
ffffffffc0200bda:	2ef000ef          	jal	ra,ffffffffc02016c8 <alloc_pages>
ffffffffc0200bde:	89aa                	mv	s3,a0
ffffffffc0200be0:	74050d63          	beqz	a0,ffffffffc020133a <default_check+0x7c8>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200be4:	4505                	li	a0,1
ffffffffc0200be6:	2e3000ef          	jal	ra,ffffffffc02016c8 <alloc_pages>
ffffffffc0200bea:	8aaa                	mv	s5,a0
ffffffffc0200bec:	4e050763          	beqz	a0,ffffffffc02010da <default_check+0x568>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200bf0:	2f3a0563          	beq	s4,s3,ffffffffc0200eda <default_check+0x368>
ffffffffc0200bf4:	2eaa0363          	beq	s4,a0,ffffffffc0200eda <default_check+0x368>
ffffffffc0200bf8:	2ea98163          	beq	s3,a0,ffffffffc0200eda <default_check+0x368>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200bfc:	000a2783          	lw	a5,0(s4)
ffffffffc0200c00:	2e079d63          	bnez	a5,ffffffffc0200efa <default_check+0x388>
ffffffffc0200c04:	0009a783          	lw	a5,0(s3)
ffffffffc0200c08:	2e079963          	bnez	a5,ffffffffc0200efa <default_check+0x388>
ffffffffc0200c0c:	411c                	lw	a5,0(a0)
ffffffffc0200c0e:	2e079663          	bnez	a5,ffffffffc0200efa <default_check+0x388>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200c12:	00006797          	auipc	a5,0x6
ffffffffc0200c16:	87678793          	addi	a5,a5,-1930 # ffffffffc0206488 <pages>
ffffffffc0200c1a:	639c                	ld	a5,0(a5)
ffffffffc0200c1c:	00002717          	auipc	a4,0x2
ffffffffc0200c20:	bd470713          	addi	a4,a4,-1068 # ffffffffc02027f0 <commands+0x770>
ffffffffc0200c24:	630c                	ld	a1,0(a4)
ffffffffc0200c26:	40fa0733          	sub	a4,s4,a5
ffffffffc0200c2a:	870d                	srai	a4,a4,0x3
ffffffffc0200c2c:	02b70733          	mul	a4,a4,a1
ffffffffc0200c30:	00002697          	auipc	a3,0x2
ffffffffc0200c34:	35068693          	addi	a3,a3,848 # ffffffffc0202f80 <nbase>
ffffffffc0200c38:	6290                	ld	a2,0(a3)
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200c3a:	00006697          	auipc	a3,0x6
ffffffffc0200c3e:	81668693          	addi	a3,a3,-2026 # ffffffffc0206450 <npage>
ffffffffc0200c42:	6294                	ld	a3,0(a3)
ffffffffc0200c44:	06b2                	slli	a3,a3,0xc
ffffffffc0200c46:	9732                	add	a4,a4,a2

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200c48:	0732                	slli	a4,a4,0xc
ffffffffc0200c4a:	2cd77863          	bgeu	a4,a3,ffffffffc0200f1a <default_check+0x3a8>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200c4e:	40f98733          	sub	a4,s3,a5
ffffffffc0200c52:	870d                	srai	a4,a4,0x3
ffffffffc0200c54:	02b70733          	mul	a4,a4,a1
ffffffffc0200c58:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200c5a:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200c5c:	4ed77f63          	bgeu	a4,a3,ffffffffc020115a <default_check+0x5e8>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200c60:	40f507b3          	sub	a5,a0,a5
ffffffffc0200c64:	878d                	srai	a5,a5,0x3
ffffffffc0200c66:	02b787b3          	mul	a5,a5,a1
ffffffffc0200c6a:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200c6c:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200c6e:	34d7f663          	bgeu	a5,a3,ffffffffc0200fba <default_check+0x448>
    assert(alloc_page() == NULL);
ffffffffc0200c72:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200c74:	00093c03          	ld	s8,0(s2)
ffffffffc0200c78:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc0200c7c:	01092b03          	lw	s6,16(s2)
    elm->prev = elm->next = elm;
ffffffffc0200c80:	00005797          	auipc	a5,0x5
ffffffffc0200c84:	3b27b423          	sd	s2,936(a5) # ffffffffc0206028 <edata+0x8>
ffffffffc0200c88:	00005797          	auipc	a5,0x5
ffffffffc0200c8c:	3927bc23          	sd	s2,920(a5) # ffffffffc0206020 <edata>
    nr_free = 0;
ffffffffc0200c90:	00005797          	auipc	a5,0x5
ffffffffc0200c94:	3a07a023          	sw	zero,928(a5) # ffffffffc0206030 <edata+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200c98:	231000ef          	jal	ra,ffffffffc02016c8 <alloc_pages>
ffffffffc0200c9c:	2e051f63          	bnez	a0,ffffffffc0200f9a <default_check+0x428>
    free_page(p0);
ffffffffc0200ca0:	4585                	li	a1,1
ffffffffc0200ca2:	8552                	mv	a0,s4
ffffffffc0200ca4:	269000ef          	jal	ra,ffffffffc020170c <free_pages>
    free_page(p1);
ffffffffc0200ca8:	4585                	li	a1,1
ffffffffc0200caa:	854e                	mv	a0,s3
ffffffffc0200cac:	261000ef          	jal	ra,ffffffffc020170c <free_pages>
    free_page(p2);
ffffffffc0200cb0:	4585                	li	a1,1
ffffffffc0200cb2:	8556                	mv	a0,s5
ffffffffc0200cb4:	259000ef          	jal	ra,ffffffffc020170c <free_pages>
    assert(nr_free == 3);
ffffffffc0200cb8:	01092703          	lw	a4,16(s2)
ffffffffc0200cbc:	478d                	li	a5,3
ffffffffc0200cbe:	2af71e63          	bne	a4,a5,ffffffffc0200f7a <default_check+0x408>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200cc2:	4505                	li	a0,1
ffffffffc0200cc4:	205000ef          	jal	ra,ffffffffc02016c8 <alloc_pages>
ffffffffc0200cc8:	89aa                	mv	s3,a0
ffffffffc0200cca:	28050863          	beqz	a0,ffffffffc0200f5a <default_check+0x3e8>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200cce:	4505                	li	a0,1
ffffffffc0200cd0:	1f9000ef          	jal	ra,ffffffffc02016c8 <alloc_pages>
ffffffffc0200cd4:	8aaa                	mv	s5,a0
ffffffffc0200cd6:	3e050263          	beqz	a0,ffffffffc02010ba <default_check+0x548>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200cda:	4505                	li	a0,1
ffffffffc0200cdc:	1ed000ef          	jal	ra,ffffffffc02016c8 <alloc_pages>
ffffffffc0200ce0:	8a2a                	mv	s4,a0
ffffffffc0200ce2:	3a050c63          	beqz	a0,ffffffffc020109a <default_check+0x528>
    assert(alloc_page() == NULL);
ffffffffc0200ce6:	4505                	li	a0,1
ffffffffc0200ce8:	1e1000ef          	jal	ra,ffffffffc02016c8 <alloc_pages>
ffffffffc0200cec:	38051763          	bnez	a0,ffffffffc020107a <default_check+0x508>
    free_page(p0);
ffffffffc0200cf0:	4585                	li	a1,1
ffffffffc0200cf2:	854e                	mv	a0,s3
ffffffffc0200cf4:	219000ef          	jal	ra,ffffffffc020170c <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200cf8:	00893783          	ld	a5,8(s2)
ffffffffc0200cfc:	23278f63          	beq	a5,s2,ffffffffc0200f3a <default_check+0x3c8>
    assert((p = alloc_page()) == p0);
ffffffffc0200d00:	4505                	li	a0,1
ffffffffc0200d02:	1c7000ef          	jal	ra,ffffffffc02016c8 <alloc_pages>
ffffffffc0200d06:	32a99a63          	bne	s3,a0,ffffffffc020103a <default_check+0x4c8>
    assert(alloc_page() == NULL);
ffffffffc0200d0a:	4505                	li	a0,1
ffffffffc0200d0c:	1bd000ef          	jal	ra,ffffffffc02016c8 <alloc_pages>
ffffffffc0200d10:	30051563          	bnez	a0,ffffffffc020101a <default_check+0x4a8>
    assert(nr_free == 0);
ffffffffc0200d14:	01092783          	lw	a5,16(s2)
ffffffffc0200d18:	2e079163          	bnez	a5,ffffffffc0200ffa <default_check+0x488>
    free_page(p);
ffffffffc0200d1c:	854e                	mv	a0,s3
ffffffffc0200d1e:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200d20:	00005797          	auipc	a5,0x5
ffffffffc0200d24:	3187b023          	sd	s8,768(a5) # ffffffffc0206020 <edata>
ffffffffc0200d28:	00005797          	auipc	a5,0x5
ffffffffc0200d2c:	3177b023          	sd	s7,768(a5) # ffffffffc0206028 <edata+0x8>
    nr_free = nr_free_store;
ffffffffc0200d30:	00005797          	auipc	a5,0x5
ffffffffc0200d34:	3167a023          	sw	s6,768(a5) # ffffffffc0206030 <edata+0x10>
    free_page(p);
ffffffffc0200d38:	1d5000ef          	jal	ra,ffffffffc020170c <free_pages>
    free_page(p1);
ffffffffc0200d3c:	4585                	li	a1,1
ffffffffc0200d3e:	8556                	mv	a0,s5
ffffffffc0200d40:	1cd000ef          	jal	ra,ffffffffc020170c <free_pages>
    free_page(p2);
ffffffffc0200d44:	4585                	li	a1,1
ffffffffc0200d46:	8552                	mv	a0,s4
ffffffffc0200d48:	1c5000ef          	jal	ra,ffffffffc020170c <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200d4c:	4515                	li	a0,5
ffffffffc0200d4e:	17b000ef          	jal	ra,ffffffffc02016c8 <alloc_pages>
ffffffffc0200d52:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200d54:	28050363          	beqz	a0,ffffffffc0200fda <default_check+0x468>
ffffffffc0200d58:	651c                	ld	a5,8(a0)
ffffffffc0200d5a:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200d5c:	8b85                	andi	a5,a5,1
ffffffffc0200d5e:	54079e63          	bnez	a5,ffffffffc02012ba <default_check+0x748>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200d62:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200d64:	00093b03          	ld	s6,0(s2)
ffffffffc0200d68:	00893a83          	ld	s5,8(s2)
ffffffffc0200d6c:	00005797          	auipc	a5,0x5
ffffffffc0200d70:	2b27ba23          	sd	s2,692(a5) # ffffffffc0206020 <edata>
ffffffffc0200d74:	00005797          	auipc	a5,0x5
ffffffffc0200d78:	2b27ba23          	sd	s2,692(a5) # ffffffffc0206028 <edata+0x8>
    assert(alloc_page() == NULL);
ffffffffc0200d7c:	14d000ef          	jal	ra,ffffffffc02016c8 <alloc_pages>
ffffffffc0200d80:	50051d63          	bnez	a0,ffffffffc020129a <default_check+0x728>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0200d84:	05098a13          	addi	s4,s3,80
ffffffffc0200d88:	8552                	mv	a0,s4
ffffffffc0200d8a:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0200d8c:	01092b83          	lw	s7,16(s2)
    nr_free = 0;
ffffffffc0200d90:	00005797          	auipc	a5,0x5
ffffffffc0200d94:	2a07a023          	sw	zero,672(a5) # ffffffffc0206030 <edata+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0200d98:	175000ef          	jal	ra,ffffffffc020170c <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200d9c:	4511                	li	a0,4
ffffffffc0200d9e:	12b000ef          	jal	ra,ffffffffc02016c8 <alloc_pages>
ffffffffc0200da2:	4c051c63          	bnez	a0,ffffffffc020127a <default_check+0x708>
ffffffffc0200da6:	0589b783          	ld	a5,88(s3)
ffffffffc0200daa:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0200dac:	8b85                	andi	a5,a5,1
ffffffffc0200dae:	4a078663          	beqz	a5,ffffffffc020125a <default_check+0x6e8>
ffffffffc0200db2:	0609a703          	lw	a4,96(s3)
ffffffffc0200db6:	478d                	li	a5,3
ffffffffc0200db8:	4af71163          	bne	a4,a5,ffffffffc020125a <default_check+0x6e8>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0200dbc:	450d                	li	a0,3
ffffffffc0200dbe:	10b000ef          	jal	ra,ffffffffc02016c8 <alloc_pages>
ffffffffc0200dc2:	8c2a                	mv	s8,a0
ffffffffc0200dc4:	46050b63          	beqz	a0,ffffffffc020123a <default_check+0x6c8>
    assert(alloc_page() == NULL);
ffffffffc0200dc8:	4505                	li	a0,1
ffffffffc0200dca:	0ff000ef          	jal	ra,ffffffffc02016c8 <alloc_pages>
ffffffffc0200dce:	44051663          	bnez	a0,ffffffffc020121a <default_check+0x6a8>
    assert(p0 + 2 == p1);
ffffffffc0200dd2:	438a1463          	bne	s4,s8,ffffffffc02011fa <default_check+0x688>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0200dd6:	4585                	li	a1,1
ffffffffc0200dd8:	854e                	mv	a0,s3
ffffffffc0200dda:	133000ef          	jal	ra,ffffffffc020170c <free_pages>
    free_pages(p1, 3);
ffffffffc0200dde:	458d                	li	a1,3
ffffffffc0200de0:	8552                	mv	a0,s4
ffffffffc0200de2:	12b000ef          	jal	ra,ffffffffc020170c <free_pages>
ffffffffc0200de6:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0200dea:	02898c13          	addi	s8,s3,40
ffffffffc0200dee:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0200df0:	8b85                	andi	a5,a5,1
ffffffffc0200df2:	3e078463          	beqz	a5,ffffffffc02011da <default_check+0x668>
ffffffffc0200df6:	0109a703          	lw	a4,16(s3)
ffffffffc0200dfa:	4785                	li	a5,1
ffffffffc0200dfc:	3cf71f63          	bne	a4,a5,ffffffffc02011da <default_check+0x668>
ffffffffc0200e00:	008a3783          	ld	a5,8(s4)
ffffffffc0200e04:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0200e06:	8b85                	andi	a5,a5,1
ffffffffc0200e08:	3a078963          	beqz	a5,ffffffffc02011ba <default_check+0x648>
ffffffffc0200e0c:	010a2703          	lw	a4,16(s4)
ffffffffc0200e10:	478d                	li	a5,3
ffffffffc0200e12:	3af71463          	bne	a4,a5,ffffffffc02011ba <default_check+0x648>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0200e16:	4505                	li	a0,1
ffffffffc0200e18:	0b1000ef          	jal	ra,ffffffffc02016c8 <alloc_pages>
ffffffffc0200e1c:	36a99f63          	bne	s3,a0,ffffffffc020119a <default_check+0x628>
    free_page(p0);
ffffffffc0200e20:	4585                	li	a1,1
ffffffffc0200e22:	0eb000ef          	jal	ra,ffffffffc020170c <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0200e26:	4509                	li	a0,2
ffffffffc0200e28:	0a1000ef          	jal	ra,ffffffffc02016c8 <alloc_pages>
ffffffffc0200e2c:	34aa1763          	bne	s4,a0,ffffffffc020117a <default_check+0x608>

    free_pages(p0, 2);
ffffffffc0200e30:	4589                	li	a1,2
ffffffffc0200e32:	0db000ef          	jal	ra,ffffffffc020170c <free_pages>
    free_page(p2);
ffffffffc0200e36:	4585                	li	a1,1
ffffffffc0200e38:	8562                	mv	a0,s8
ffffffffc0200e3a:	0d3000ef          	jal	ra,ffffffffc020170c <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200e3e:	4515                	li	a0,5
ffffffffc0200e40:	089000ef          	jal	ra,ffffffffc02016c8 <alloc_pages>
ffffffffc0200e44:	89aa                	mv	s3,a0
ffffffffc0200e46:	48050a63          	beqz	a0,ffffffffc02012da <default_check+0x768>
    assert(alloc_page() == NULL);
ffffffffc0200e4a:	4505                	li	a0,1
ffffffffc0200e4c:	07d000ef          	jal	ra,ffffffffc02016c8 <alloc_pages>
ffffffffc0200e50:	2e051563          	bnez	a0,ffffffffc020113a <default_check+0x5c8>

    assert(nr_free == 0);
ffffffffc0200e54:	01092783          	lw	a5,16(s2)
ffffffffc0200e58:	2c079163          	bnez	a5,ffffffffc020111a <default_check+0x5a8>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200e5c:	4595                	li	a1,5
ffffffffc0200e5e:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200e60:	00005797          	auipc	a5,0x5
ffffffffc0200e64:	1d77a823          	sw	s7,464(a5) # ffffffffc0206030 <edata+0x10>
    free_list = free_list_store;
ffffffffc0200e68:	00005797          	auipc	a5,0x5
ffffffffc0200e6c:	1b67bc23          	sd	s6,440(a5) # ffffffffc0206020 <edata>
ffffffffc0200e70:	00005797          	auipc	a5,0x5
ffffffffc0200e74:	1b57bc23          	sd	s5,440(a5) # ffffffffc0206028 <edata+0x8>
    free_pages(p0, 5);
ffffffffc0200e78:	095000ef          	jal	ra,ffffffffc020170c <free_pages>
    return listelm->next;
ffffffffc0200e7c:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200e80:	01278963          	beq	a5,s2,ffffffffc0200e92 <default_check+0x320>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200e84:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200e88:	679c                	ld	a5,8(a5)
ffffffffc0200e8a:	34fd                	addiw	s1,s1,-1
ffffffffc0200e8c:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200e8e:	ff279be3          	bne	a5,s2,ffffffffc0200e84 <default_check+0x312>
    }
    assert(count == 0);
ffffffffc0200e92:	26049463          	bnez	s1,ffffffffc02010fa <default_check+0x588>
    assert(total == 0);
ffffffffc0200e96:	46041263          	bnez	s0,ffffffffc02012fa <default_check+0x788>
}
ffffffffc0200e9a:	60a6                	ld	ra,72(sp)
ffffffffc0200e9c:	6406                	ld	s0,64(sp)
ffffffffc0200e9e:	74e2                	ld	s1,56(sp)
ffffffffc0200ea0:	7942                	ld	s2,48(sp)
ffffffffc0200ea2:	79a2                	ld	s3,40(sp)
ffffffffc0200ea4:	7a02                	ld	s4,32(sp)
ffffffffc0200ea6:	6ae2                	ld	s5,24(sp)
ffffffffc0200ea8:	6b42                	ld	s6,16(sp)
ffffffffc0200eaa:	6ba2                	ld	s7,8(sp)
ffffffffc0200eac:	6c02                	ld	s8,0(sp)
ffffffffc0200eae:	6161                	addi	sp,sp,80
ffffffffc0200eb0:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200eb2:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200eb4:	4401                	li	s0,0
ffffffffc0200eb6:	4481                	li	s1,0
ffffffffc0200eb8:	b331                	j	ffffffffc0200bc4 <default_check+0x52>
        assert(PageProperty(p));
ffffffffc0200eba:	00002697          	auipc	a3,0x2
ffffffffc0200ebe:	93e68693          	addi	a3,a3,-1730 # ffffffffc02027f8 <commands+0x778>
ffffffffc0200ec2:	00002617          	auipc	a2,0x2
ffffffffc0200ec6:	94660613          	addi	a2,a2,-1722 # ffffffffc0202808 <commands+0x788>
ffffffffc0200eca:	0f000593          	li	a1,240
ffffffffc0200ece:	00002517          	auipc	a0,0x2
ffffffffc0200ed2:	95250513          	addi	a0,a0,-1710 # ffffffffc0202820 <commands+0x7a0>
ffffffffc0200ed6:	cf8ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200eda:	00002697          	auipc	a3,0x2
ffffffffc0200ede:	9de68693          	addi	a3,a3,-1570 # ffffffffc02028b8 <commands+0x838>
ffffffffc0200ee2:	00002617          	auipc	a2,0x2
ffffffffc0200ee6:	92660613          	addi	a2,a2,-1754 # ffffffffc0202808 <commands+0x788>
ffffffffc0200eea:	0bd00593          	li	a1,189
ffffffffc0200eee:	00002517          	auipc	a0,0x2
ffffffffc0200ef2:	93250513          	addi	a0,a0,-1742 # ffffffffc0202820 <commands+0x7a0>
ffffffffc0200ef6:	cd8ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200efa:	00002697          	auipc	a3,0x2
ffffffffc0200efe:	9e668693          	addi	a3,a3,-1562 # ffffffffc02028e0 <commands+0x860>
ffffffffc0200f02:	00002617          	auipc	a2,0x2
ffffffffc0200f06:	90660613          	addi	a2,a2,-1786 # ffffffffc0202808 <commands+0x788>
ffffffffc0200f0a:	0be00593          	li	a1,190
ffffffffc0200f0e:	00002517          	auipc	a0,0x2
ffffffffc0200f12:	91250513          	addi	a0,a0,-1774 # ffffffffc0202820 <commands+0x7a0>
ffffffffc0200f16:	cb8ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200f1a:	00002697          	auipc	a3,0x2
ffffffffc0200f1e:	a0668693          	addi	a3,a3,-1530 # ffffffffc0202920 <commands+0x8a0>
ffffffffc0200f22:	00002617          	auipc	a2,0x2
ffffffffc0200f26:	8e660613          	addi	a2,a2,-1818 # ffffffffc0202808 <commands+0x788>
ffffffffc0200f2a:	0c000593          	li	a1,192
ffffffffc0200f2e:	00002517          	auipc	a0,0x2
ffffffffc0200f32:	8f250513          	addi	a0,a0,-1806 # ffffffffc0202820 <commands+0x7a0>
ffffffffc0200f36:	c98ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(!list_empty(&free_list));
ffffffffc0200f3a:	00002697          	auipc	a3,0x2
ffffffffc0200f3e:	a6e68693          	addi	a3,a3,-1426 # ffffffffc02029a8 <commands+0x928>
ffffffffc0200f42:	00002617          	auipc	a2,0x2
ffffffffc0200f46:	8c660613          	addi	a2,a2,-1850 # ffffffffc0202808 <commands+0x788>
ffffffffc0200f4a:	0d900593          	li	a1,217
ffffffffc0200f4e:	00002517          	auipc	a0,0x2
ffffffffc0200f52:	8d250513          	addi	a0,a0,-1838 # ffffffffc0202820 <commands+0x7a0>
ffffffffc0200f56:	c78ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200f5a:	00002697          	auipc	a3,0x2
ffffffffc0200f5e:	8fe68693          	addi	a3,a3,-1794 # ffffffffc0202858 <commands+0x7d8>
ffffffffc0200f62:	00002617          	auipc	a2,0x2
ffffffffc0200f66:	8a660613          	addi	a2,a2,-1882 # ffffffffc0202808 <commands+0x788>
ffffffffc0200f6a:	0d200593          	li	a1,210
ffffffffc0200f6e:	00002517          	auipc	a0,0x2
ffffffffc0200f72:	8b250513          	addi	a0,a0,-1870 # ffffffffc0202820 <commands+0x7a0>
ffffffffc0200f76:	c58ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(nr_free == 3);
ffffffffc0200f7a:	00002697          	auipc	a3,0x2
ffffffffc0200f7e:	a1e68693          	addi	a3,a3,-1506 # ffffffffc0202998 <commands+0x918>
ffffffffc0200f82:	00002617          	auipc	a2,0x2
ffffffffc0200f86:	88660613          	addi	a2,a2,-1914 # ffffffffc0202808 <commands+0x788>
ffffffffc0200f8a:	0d000593          	li	a1,208
ffffffffc0200f8e:	00002517          	auipc	a0,0x2
ffffffffc0200f92:	89250513          	addi	a0,a0,-1902 # ffffffffc0202820 <commands+0x7a0>
ffffffffc0200f96:	c38ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200f9a:	00002697          	auipc	a3,0x2
ffffffffc0200f9e:	9e668693          	addi	a3,a3,-1562 # ffffffffc0202980 <commands+0x900>
ffffffffc0200fa2:	00002617          	auipc	a2,0x2
ffffffffc0200fa6:	86660613          	addi	a2,a2,-1946 # ffffffffc0202808 <commands+0x788>
ffffffffc0200faa:	0cb00593          	li	a1,203
ffffffffc0200fae:	00002517          	auipc	a0,0x2
ffffffffc0200fb2:	87250513          	addi	a0,a0,-1934 # ffffffffc0202820 <commands+0x7a0>
ffffffffc0200fb6:	c18ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200fba:	00002697          	auipc	a3,0x2
ffffffffc0200fbe:	9a668693          	addi	a3,a3,-1626 # ffffffffc0202960 <commands+0x8e0>
ffffffffc0200fc2:	00002617          	auipc	a2,0x2
ffffffffc0200fc6:	84660613          	addi	a2,a2,-1978 # ffffffffc0202808 <commands+0x788>
ffffffffc0200fca:	0c200593          	li	a1,194
ffffffffc0200fce:	00002517          	auipc	a0,0x2
ffffffffc0200fd2:	85250513          	addi	a0,a0,-1966 # ffffffffc0202820 <commands+0x7a0>
ffffffffc0200fd6:	bf8ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(p0 != NULL);
ffffffffc0200fda:	00002697          	auipc	a3,0x2
ffffffffc0200fde:	a1668693          	addi	a3,a3,-1514 # ffffffffc02029f0 <commands+0x970>
ffffffffc0200fe2:	00002617          	auipc	a2,0x2
ffffffffc0200fe6:	82660613          	addi	a2,a2,-2010 # ffffffffc0202808 <commands+0x788>
ffffffffc0200fea:	0f800593          	li	a1,248
ffffffffc0200fee:	00002517          	auipc	a0,0x2
ffffffffc0200ff2:	83250513          	addi	a0,a0,-1998 # ffffffffc0202820 <commands+0x7a0>
ffffffffc0200ff6:	bd8ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(nr_free == 0);
ffffffffc0200ffa:	00002697          	auipc	a3,0x2
ffffffffc0200ffe:	9e668693          	addi	a3,a3,-1562 # ffffffffc02029e0 <commands+0x960>
ffffffffc0201002:	00002617          	auipc	a2,0x2
ffffffffc0201006:	80660613          	addi	a2,a2,-2042 # ffffffffc0202808 <commands+0x788>
ffffffffc020100a:	0df00593          	li	a1,223
ffffffffc020100e:	00002517          	auipc	a0,0x2
ffffffffc0201012:	81250513          	addi	a0,a0,-2030 # ffffffffc0202820 <commands+0x7a0>
ffffffffc0201016:	bb8ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(alloc_page() == NULL);
ffffffffc020101a:	00002697          	auipc	a3,0x2
ffffffffc020101e:	96668693          	addi	a3,a3,-1690 # ffffffffc0202980 <commands+0x900>
ffffffffc0201022:	00001617          	auipc	a2,0x1
ffffffffc0201026:	7e660613          	addi	a2,a2,2022 # ffffffffc0202808 <commands+0x788>
ffffffffc020102a:	0dd00593          	li	a1,221
ffffffffc020102e:	00001517          	auipc	a0,0x1
ffffffffc0201032:	7f250513          	addi	a0,a0,2034 # ffffffffc0202820 <commands+0x7a0>
ffffffffc0201036:	b98ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc020103a:	00002697          	auipc	a3,0x2
ffffffffc020103e:	98668693          	addi	a3,a3,-1658 # ffffffffc02029c0 <commands+0x940>
ffffffffc0201042:	00001617          	auipc	a2,0x1
ffffffffc0201046:	7c660613          	addi	a2,a2,1990 # ffffffffc0202808 <commands+0x788>
ffffffffc020104a:	0dc00593          	li	a1,220
ffffffffc020104e:	00001517          	auipc	a0,0x1
ffffffffc0201052:	7d250513          	addi	a0,a0,2002 # ffffffffc0202820 <commands+0x7a0>
ffffffffc0201056:	b78ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020105a:	00001697          	auipc	a3,0x1
ffffffffc020105e:	7fe68693          	addi	a3,a3,2046 # ffffffffc0202858 <commands+0x7d8>
ffffffffc0201062:	00001617          	auipc	a2,0x1
ffffffffc0201066:	7a660613          	addi	a2,a2,1958 # ffffffffc0202808 <commands+0x788>
ffffffffc020106a:	0b900593          	li	a1,185
ffffffffc020106e:	00001517          	auipc	a0,0x1
ffffffffc0201072:	7b250513          	addi	a0,a0,1970 # ffffffffc0202820 <commands+0x7a0>
ffffffffc0201076:	b58ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(alloc_page() == NULL);
ffffffffc020107a:	00002697          	auipc	a3,0x2
ffffffffc020107e:	90668693          	addi	a3,a3,-1786 # ffffffffc0202980 <commands+0x900>
ffffffffc0201082:	00001617          	auipc	a2,0x1
ffffffffc0201086:	78660613          	addi	a2,a2,1926 # ffffffffc0202808 <commands+0x788>
ffffffffc020108a:	0d600593          	li	a1,214
ffffffffc020108e:	00001517          	auipc	a0,0x1
ffffffffc0201092:	79250513          	addi	a0,a0,1938 # ffffffffc0202820 <commands+0x7a0>
ffffffffc0201096:	b38ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020109a:	00001697          	auipc	a3,0x1
ffffffffc020109e:	7fe68693          	addi	a3,a3,2046 # ffffffffc0202898 <commands+0x818>
ffffffffc02010a2:	00001617          	auipc	a2,0x1
ffffffffc02010a6:	76660613          	addi	a2,a2,1894 # ffffffffc0202808 <commands+0x788>
ffffffffc02010aa:	0d400593          	li	a1,212
ffffffffc02010ae:	00001517          	auipc	a0,0x1
ffffffffc02010b2:	77250513          	addi	a0,a0,1906 # ffffffffc0202820 <commands+0x7a0>
ffffffffc02010b6:	b18ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02010ba:	00001697          	auipc	a3,0x1
ffffffffc02010be:	7be68693          	addi	a3,a3,1982 # ffffffffc0202878 <commands+0x7f8>
ffffffffc02010c2:	00001617          	auipc	a2,0x1
ffffffffc02010c6:	74660613          	addi	a2,a2,1862 # ffffffffc0202808 <commands+0x788>
ffffffffc02010ca:	0d300593          	li	a1,211
ffffffffc02010ce:	00001517          	auipc	a0,0x1
ffffffffc02010d2:	75250513          	addi	a0,a0,1874 # ffffffffc0202820 <commands+0x7a0>
ffffffffc02010d6:	af8ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02010da:	00001697          	auipc	a3,0x1
ffffffffc02010de:	7be68693          	addi	a3,a3,1982 # ffffffffc0202898 <commands+0x818>
ffffffffc02010e2:	00001617          	auipc	a2,0x1
ffffffffc02010e6:	72660613          	addi	a2,a2,1830 # ffffffffc0202808 <commands+0x788>
ffffffffc02010ea:	0bb00593          	li	a1,187
ffffffffc02010ee:	00001517          	auipc	a0,0x1
ffffffffc02010f2:	73250513          	addi	a0,a0,1842 # ffffffffc0202820 <commands+0x7a0>
ffffffffc02010f6:	ad8ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(count == 0);
ffffffffc02010fa:	00002697          	auipc	a3,0x2
ffffffffc02010fe:	a4668693          	addi	a3,a3,-1466 # ffffffffc0202b40 <commands+0xac0>
ffffffffc0201102:	00001617          	auipc	a2,0x1
ffffffffc0201106:	70660613          	addi	a2,a2,1798 # ffffffffc0202808 <commands+0x788>
ffffffffc020110a:	12500593          	li	a1,293
ffffffffc020110e:	00001517          	auipc	a0,0x1
ffffffffc0201112:	71250513          	addi	a0,a0,1810 # ffffffffc0202820 <commands+0x7a0>
ffffffffc0201116:	ab8ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(nr_free == 0);
ffffffffc020111a:	00002697          	auipc	a3,0x2
ffffffffc020111e:	8c668693          	addi	a3,a3,-1850 # ffffffffc02029e0 <commands+0x960>
ffffffffc0201122:	00001617          	auipc	a2,0x1
ffffffffc0201126:	6e660613          	addi	a2,a2,1766 # ffffffffc0202808 <commands+0x788>
ffffffffc020112a:	11a00593          	li	a1,282
ffffffffc020112e:	00001517          	auipc	a0,0x1
ffffffffc0201132:	6f250513          	addi	a0,a0,1778 # ffffffffc0202820 <commands+0x7a0>
ffffffffc0201136:	a98ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(alloc_page() == NULL);
ffffffffc020113a:	00002697          	auipc	a3,0x2
ffffffffc020113e:	84668693          	addi	a3,a3,-1978 # ffffffffc0202980 <commands+0x900>
ffffffffc0201142:	00001617          	auipc	a2,0x1
ffffffffc0201146:	6c660613          	addi	a2,a2,1734 # ffffffffc0202808 <commands+0x788>
ffffffffc020114a:	11800593          	li	a1,280
ffffffffc020114e:	00001517          	auipc	a0,0x1
ffffffffc0201152:	6d250513          	addi	a0,a0,1746 # ffffffffc0202820 <commands+0x7a0>
ffffffffc0201156:	a78ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc020115a:	00001697          	auipc	a3,0x1
ffffffffc020115e:	7e668693          	addi	a3,a3,2022 # ffffffffc0202940 <commands+0x8c0>
ffffffffc0201162:	00001617          	auipc	a2,0x1
ffffffffc0201166:	6a660613          	addi	a2,a2,1702 # ffffffffc0202808 <commands+0x788>
ffffffffc020116a:	0c100593          	li	a1,193
ffffffffc020116e:	00001517          	auipc	a0,0x1
ffffffffc0201172:	6b250513          	addi	a0,a0,1714 # ffffffffc0202820 <commands+0x7a0>
ffffffffc0201176:	a58ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc020117a:	00002697          	auipc	a3,0x2
ffffffffc020117e:	98668693          	addi	a3,a3,-1658 # ffffffffc0202b00 <commands+0xa80>
ffffffffc0201182:	00001617          	auipc	a2,0x1
ffffffffc0201186:	68660613          	addi	a2,a2,1670 # ffffffffc0202808 <commands+0x788>
ffffffffc020118a:	11200593          	li	a1,274
ffffffffc020118e:	00001517          	auipc	a0,0x1
ffffffffc0201192:	69250513          	addi	a0,a0,1682 # ffffffffc0202820 <commands+0x7a0>
ffffffffc0201196:	a38ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc020119a:	00002697          	auipc	a3,0x2
ffffffffc020119e:	94668693          	addi	a3,a3,-1722 # ffffffffc0202ae0 <commands+0xa60>
ffffffffc02011a2:	00001617          	auipc	a2,0x1
ffffffffc02011a6:	66660613          	addi	a2,a2,1638 # ffffffffc0202808 <commands+0x788>
ffffffffc02011aa:	11000593          	li	a1,272
ffffffffc02011ae:	00001517          	auipc	a0,0x1
ffffffffc02011b2:	67250513          	addi	a0,a0,1650 # ffffffffc0202820 <commands+0x7a0>
ffffffffc02011b6:	a18ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02011ba:	00002697          	auipc	a3,0x2
ffffffffc02011be:	8fe68693          	addi	a3,a3,-1794 # ffffffffc0202ab8 <commands+0xa38>
ffffffffc02011c2:	00001617          	auipc	a2,0x1
ffffffffc02011c6:	64660613          	addi	a2,a2,1606 # ffffffffc0202808 <commands+0x788>
ffffffffc02011ca:	10e00593          	li	a1,270
ffffffffc02011ce:	00001517          	auipc	a0,0x1
ffffffffc02011d2:	65250513          	addi	a0,a0,1618 # ffffffffc0202820 <commands+0x7a0>
ffffffffc02011d6:	9f8ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02011da:	00002697          	auipc	a3,0x2
ffffffffc02011de:	8b668693          	addi	a3,a3,-1866 # ffffffffc0202a90 <commands+0xa10>
ffffffffc02011e2:	00001617          	auipc	a2,0x1
ffffffffc02011e6:	62660613          	addi	a2,a2,1574 # ffffffffc0202808 <commands+0x788>
ffffffffc02011ea:	10d00593          	li	a1,269
ffffffffc02011ee:	00001517          	auipc	a0,0x1
ffffffffc02011f2:	63250513          	addi	a0,a0,1586 # ffffffffc0202820 <commands+0x7a0>
ffffffffc02011f6:	9d8ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(p0 + 2 == p1);
ffffffffc02011fa:	00002697          	auipc	a3,0x2
ffffffffc02011fe:	88668693          	addi	a3,a3,-1914 # ffffffffc0202a80 <commands+0xa00>
ffffffffc0201202:	00001617          	auipc	a2,0x1
ffffffffc0201206:	60660613          	addi	a2,a2,1542 # ffffffffc0202808 <commands+0x788>
ffffffffc020120a:	10800593          	li	a1,264
ffffffffc020120e:	00001517          	auipc	a0,0x1
ffffffffc0201212:	61250513          	addi	a0,a0,1554 # ffffffffc0202820 <commands+0x7a0>
ffffffffc0201216:	9b8ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(alloc_page() == NULL);
ffffffffc020121a:	00001697          	auipc	a3,0x1
ffffffffc020121e:	76668693          	addi	a3,a3,1894 # ffffffffc0202980 <commands+0x900>
ffffffffc0201222:	00001617          	auipc	a2,0x1
ffffffffc0201226:	5e660613          	addi	a2,a2,1510 # ffffffffc0202808 <commands+0x788>
ffffffffc020122a:	10700593          	li	a1,263
ffffffffc020122e:	00001517          	auipc	a0,0x1
ffffffffc0201232:	5f250513          	addi	a0,a0,1522 # ffffffffc0202820 <commands+0x7a0>
ffffffffc0201236:	998ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc020123a:	00002697          	auipc	a3,0x2
ffffffffc020123e:	82668693          	addi	a3,a3,-2010 # ffffffffc0202a60 <commands+0x9e0>
ffffffffc0201242:	00001617          	auipc	a2,0x1
ffffffffc0201246:	5c660613          	addi	a2,a2,1478 # ffffffffc0202808 <commands+0x788>
ffffffffc020124a:	10600593          	li	a1,262
ffffffffc020124e:	00001517          	auipc	a0,0x1
ffffffffc0201252:	5d250513          	addi	a0,a0,1490 # ffffffffc0202820 <commands+0x7a0>
ffffffffc0201256:	978ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc020125a:	00001697          	auipc	a3,0x1
ffffffffc020125e:	7d668693          	addi	a3,a3,2006 # ffffffffc0202a30 <commands+0x9b0>
ffffffffc0201262:	00001617          	auipc	a2,0x1
ffffffffc0201266:	5a660613          	addi	a2,a2,1446 # ffffffffc0202808 <commands+0x788>
ffffffffc020126a:	10500593          	li	a1,261
ffffffffc020126e:	00001517          	auipc	a0,0x1
ffffffffc0201272:	5b250513          	addi	a0,a0,1458 # ffffffffc0202820 <commands+0x7a0>
ffffffffc0201276:	958ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc020127a:	00001697          	auipc	a3,0x1
ffffffffc020127e:	79e68693          	addi	a3,a3,1950 # ffffffffc0202a18 <commands+0x998>
ffffffffc0201282:	00001617          	auipc	a2,0x1
ffffffffc0201286:	58660613          	addi	a2,a2,1414 # ffffffffc0202808 <commands+0x788>
ffffffffc020128a:	10400593          	li	a1,260
ffffffffc020128e:	00001517          	auipc	a0,0x1
ffffffffc0201292:	59250513          	addi	a0,a0,1426 # ffffffffc0202820 <commands+0x7a0>
ffffffffc0201296:	938ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(alloc_page() == NULL);
ffffffffc020129a:	00001697          	auipc	a3,0x1
ffffffffc020129e:	6e668693          	addi	a3,a3,1766 # ffffffffc0202980 <commands+0x900>
ffffffffc02012a2:	00001617          	auipc	a2,0x1
ffffffffc02012a6:	56660613          	addi	a2,a2,1382 # ffffffffc0202808 <commands+0x788>
ffffffffc02012aa:	0fe00593          	li	a1,254
ffffffffc02012ae:	00001517          	auipc	a0,0x1
ffffffffc02012b2:	57250513          	addi	a0,a0,1394 # ffffffffc0202820 <commands+0x7a0>
ffffffffc02012b6:	918ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(!PageProperty(p0));
ffffffffc02012ba:	00001697          	auipc	a3,0x1
ffffffffc02012be:	74668693          	addi	a3,a3,1862 # ffffffffc0202a00 <commands+0x980>
ffffffffc02012c2:	00001617          	auipc	a2,0x1
ffffffffc02012c6:	54660613          	addi	a2,a2,1350 # ffffffffc0202808 <commands+0x788>
ffffffffc02012ca:	0f900593          	li	a1,249
ffffffffc02012ce:	00001517          	auipc	a0,0x1
ffffffffc02012d2:	55250513          	addi	a0,a0,1362 # ffffffffc0202820 <commands+0x7a0>
ffffffffc02012d6:	8f8ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02012da:	00002697          	auipc	a3,0x2
ffffffffc02012de:	84668693          	addi	a3,a3,-1978 # ffffffffc0202b20 <commands+0xaa0>
ffffffffc02012e2:	00001617          	auipc	a2,0x1
ffffffffc02012e6:	52660613          	addi	a2,a2,1318 # ffffffffc0202808 <commands+0x788>
ffffffffc02012ea:	11700593          	li	a1,279
ffffffffc02012ee:	00001517          	auipc	a0,0x1
ffffffffc02012f2:	53250513          	addi	a0,a0,1330 # ffffffffc0202820 <commands+0x7a0>
ffffffffc02012f6:	8d8ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(total == 0);
ffffffffc02012fa:	00002697          	auipc	a3,0x2
ffffffffc02012fe:	85668693          	addi	a3,a3,-1962 # ffffffffc0202b50 <commands+0xad0>
ffffffffc0201302:	00001617          	auipc	a2,0x1
ffffffffc0201306:	50660613          	addi	a2,a2,1286 # ffffffffc0202808 <commands+0x788>
ffffffffc020130a:	12600593          	li	a1,294
ffffffffc020130e:	00001517          	auipc	a0,0x1
ffffffffc0201312:	51250513          	addi	a0,a0,1298 # ffffffffc0202820 <commands+0x7a0>
ffffffffc0201316:	8b8ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(total == nr_free_pages());
ffffffffc020131a:	00001697          	auipc	a3,0x1
ffffffffc020131e:	51e68693          	addi	a3,a3,1310 # ffffffffc0202838 <commands+0x7b8>
ffffffffc0201322:	00001617          	auipc	a2,0x1
ffffffffc0201326:	4e660613          	addi	a2,a2,1254 # ffffffffc0202808 <commands+0x788>
ffffffffc020132a:	0f300593          	li	a1,243
ffffffffc020132e:	00001517          	auipc	a0,0x1
ffffffffc0201332:	4f250513          	addi	a0,a0,1266 # ffffffffc0202820 <commands+0x7a0>
ffffffffc0201336:	898ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020133a:	00001697          	auipc	a3,0x1
ffffffffc020133e:	53e68693          	addi	a3,a3,1342 # ffffffffc0202878 <commands+0x7f8>
ffffffffc0201342:	00001617          	auipc	a2,0x1
ffffffffc0201346:	4c660613          	addi	a2,a2,1222 # ffffffffc0202808 <commands+0x788>
ffffffffc020134a:	0ba00593          	li	a1,186
ffffffffc020134e:	00001517          	auipc	a0,0x1
ffffffffc0201352:	4d250513          	addi	a0,a0,1234 # ffffffffc0202820 <commands+0x7a0>
ffffffffc0201356:	878ff0ef          	jal	ra,ffffffffc02003ce <__panic>

ffffffffc020135a <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc020135a:	1141                	addi	sp,sp,-16
ffffffffc020135c:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020135e:	18058063          	beqz	a1,ffffffffc02014de <default_free_pages+0x184>
    for (; p != base + n; p ++) {
ffffffffc0201362:	00259693          	slli	a3,a1,0x2
ffffffffc0201366:	96ae                	add	a3,a3,a1
ffffffffc0201368:	068e                	slli	a3,a3,0x3
ffffffffc020136a:	96aa                	add	a3,a3,a0
ffffffffc020136c:	02d50d63          	beq	a0,a3,ffffffffc02013a6 <default_free_pages+0x4c>
ffffffffc0201370:	651c                	ld	a5,8(a0)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201372:	8b85                	andi	a5,a5,1
ffffffffc0201374:	14079563          	bnez	a5,ffffffffc02014be <default_free_pages+0x164>
ffffffffc0201378:	651c                	ld	a5,8(a0)
ffffffffc020137a:	8385                	srli	a5,a5,0x1
ffffffffc020137c:	8b85                	andi	a5,a5,1
ffffffffc020137e:	14079063          	bnez	a5,ffffffffc02014be <default_free_pages+0x164>
ffffffffc0201382:	87aa                	mv	a5,a0
ffffffffc0201384:	a809                	j	ffffffffc0201396 <default_free_pages+0x3c>
ffffffffc0201386:	6798                	ld	a4,8(a5)
ffffffffc0201388:	8b05                	andi	a4,a4,1
ffffffffc020138a:	12071a63          	bnez	a4,ffffffffc02014be <default_free_pages+0x164>
ffffffffc020138e:	6798                	ld	a4,8(a5)
ffffffffc0201390:	8b09                	andi	a4,a4,2
ffffffffc0201392:	12071663          	bnez	a4,ffffffffc02014be <default_free_pages+0x164>
        p->flags = 0;
ffffffffc0201396:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc020139a:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc020139e:	02878793          	addi	a5,a5,40
ffffffffc02013a2:	fed792e3          	bne	a5,a3,ffffffffc0201386 <default_free_pages+0x2c>
    base->property = n;
ffffffffc02013a6:	2581                	sext.w	a1,a1
ffffffffc02013a8:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc02013aa:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02013ae:	4789                	li	a5,2
ffffffffc02013b0:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc02013b4:	00005697          	auipc	a3,0x5
ffffffffc02013b8:	c6c68693          	addi	a3,a3,-916 # ffffffffc0206020 <edata>
ffffffffc02013bc:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02013be:	669c                	ld	a5,8(a3)
ffffffffc02013c0:	9db9                	addw	a1,a1,a4
ffffffffc02013c2:	00005717          	auipc	a4,0x5
ffffffffc02013c6:	c6b72723          	sw	a1,-914(a4) # ffffffffc0206030 <edata+0x10>
    if (list_empty(&free_list)) {
ffffffffc02013ca:	08d78f63          	beq	a5,a3,ffffffffc0201468 <default_free_pages+0x10e>
            struct Page* page = le2page(le, page_link);
ffffffffc02013ce:	fe878713          	addi	a4,a5,-24
ffffffffc02013d2:	628c                	ld	a1,0(a3)
    if (list_empty(&free_list)) {
ffffffffc02013d4:	4801                	li	a6,0
ffffffffc02013d6:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc02013da:	00e56a63          	bltu	a0,a4,ffffffffc02013ee <default_free_pages+0x94>
    return listelm->next;
ffffffffc02013de:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02013e0:	02d70563          	beq	a4,a3,ffffffffc020140a <default_free_pages+0xb0>
        while ((le = list_next(le)) != &free_list) {
ffffffffc02013e4:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02013e6:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc02013ea:	fee57ae3          	bgeu	a0,a4,ffffffffc02013de <default_free_pages+0x84>
ffffffffc02013ee:	00080663          	beqz	a6,ffffffffc02013fa <default_free_pages+0xa0>
ffffffffc02013f2:	00005817          	auipc	a6,0x5
ffffffffc02013f6:	c2b83723          	sd	a1,-978(a6) # ffffffffc0206020 <edata>
    __list_add(elm, listelm->prev, listelm);
ffffffffc02013fa:	638c                	ld	a1,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc02013fc:	e390                	sd	a2,0(a5)
ffffffffc02013fe:	e590                	sd	a2,8(a1)
    elm->next = next;
ffffffffc0201400:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201402:	ed0c                	sd	a1,24(a0)
    if (le != &free_list) {
ffffffffc0201404:	02d59163          	bne	a1,a3,ffffffffc0201426 <default_free_pages+0xcc>
ffffffffc0201408:	a091                	j	ffffffffc020144c <default_free_pages+0xf2>
    prev->next = next->prev = elm;
ffffffffc020140a:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020140c:	f114                	sd	a3,32(a0)
ffffffffc020140e:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201410:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc0201412:	85b2                	mv	a1,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201414:	00d70563          	beq	a4,a3,ffffffffc020141e <default_free_pages+0xc4>
ffffffffc0201418:	4805                	li	a6,1
ffffffffc020141a:	87ba                	mv	a5,a4
ffffffffc020141c:	b7e9                	j	ffffffffc02013e6 <default_free_pages+0x8c>
ffffffffc020141e:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc0201420:	85be                	mv	a1,a5
    if (le != &free_list) {
ffffffffc0201422:	02d78163          	beq	a5,a3,ffffffffc0201444 <default_free_pages+0xea>
        if (p + p->property == base) {
ffffffffc0201426:	ff85a803          	lw	a6,-8(a1)
        p = le2page(le, page_link);
ffffffffc020142a:	fe858613          	addi	a2,a1,-24
        if (p + p->property == base) {
ffffffffc020142e:	02081713          	slli	a4,a6,0x20
ffffffffc0201432:	9301                	srli	a4,a4,0x20
ffffffffc0201434:	00271793          	slli	a5,a4,0x2
ffffffffc0201438:	97ba                	add	a5,a5,a4
ffffffffc020143a:	078e                	slli	a5,a5,0x3
ffffffffc020143c:	97b2                	add	a5,a5,a2
ffffffffc020143e:	02f50e63          	beq	a0,a5,ffffffffc020147a <default_free_pages+0x120>
ffffffffc0201442:	711c                	ld	a5,32(a0)
    if (le != &free_list) {
ffffffffc0201444:	fe878713          	addi	a4,a5,-24
ffffffffc0201448:	00d78d63          	beq	a5,a3,ffffffffc0201462 <default_free_pages+0x108>
        if (base + base->property == p) {
ffffffffc020144c:	490c                	lw	a1,16(a0)
ffffffffc020144e:	02059613          	slli	a2,a1,0x20
ffffffffc0201452:	9201                	srli	a2,a2,0x20
ffffffffc0201454:	00261693          	slli	a3,a2,0x2
ffffffffc0201458:	96b2                	add	a3,a3,a2
ffffffffc020145a:	068e                	slli	a3,a3,0x3
ffffffffc020145c:	96aa                	add	a3,a3,a0
ffffffffc020145e:	04d70063          	beq	a4,a3,ffffffffc020149e <default_free_pages+0x144>
}
ffffffffc0201462:	60a2                	ld	ra,8(sp)
ffffffffc0201464:	0141                	addi	sp,sp,16
ffffffffc0201466:	8082                	ret
ffffffffc0201468:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc020146a:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc020146e:	e398                	sd	a4,0(a5)
ffffffffc0201470:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc0201472:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201474:	ed1c                	sd	a5,24(a0)
}
ffffffffc0201476:	0141                	addi	sp,sp,16
ffffffffc0201478:	8082                	ret
            p->property += base->property;
ffffffffc020147a:	491c                	lw	a5,16(a0)
ffffffffc020147c:	0107883b          	addw	a6,a5,a6
ffffffffc0201480:	ff05ac23          	sw	a6,-8(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201484:	57f5                	li	a5,-3
ffffffffc0201486:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc020148a:	01853803          	ld	a6,24(a0)
ffffffffc020148e:	7118                	ld	a4,32(a0)
            base = p;
ffffffffc0201490:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0201492:	00e83423          	sd	a4,8(a6)
    next->prev = prev;
ffffffffc0201496:	659c                	ld	a5,8(a1)
ffffffffc0201498:	01073023          	sd	a6,0(a4)
ffffffffc020149c:	b765                	j	ffffffffc0201444 <default_free_pages+0xea>
            base->property += p->property;
ffffffffc020149e:	ff87a703          	lw	a4,-8(a5)
ffffffffc02014a2:	ff078693          	addi	a3,a5,-16
ffffffffc02014a6:	9db9                	addw	a1,a1,a4
ffffffffc02014a8:	c90c                	sw	a1,16(a0)
ffffffffc02014aa:	5775                	li	a4,-3
ffffffffc02014ac:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02014b0:	6398                	ld	a4,0(a5)
ffffffffc02014b2:	679c                	ld	a5,8(a5)
}
ffffffffc02014b4:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc02014b6:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02014b8:	e398                	sd	a4,0(a5)
ffffffffc02014ba:	0141                	addi	sp,sp,16
ffffffffc02014bc:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02014be:	00001697          	auipc	a3,0x1
ffffffffc02014c2:	6a268693          	addi	a3,a3,1698 # ffffffffc0202b60 <commands+0xae0>
ffffffffc02014c6:	00001617          	auipc	a2,0x1
ffffffffc02014ca:	34260613          	addi	a2,a2,834 # ffffffffc0202808 <commands+0x788>
ffffffffc02014ce:	08300593          	li	a1,131
ffffffffc02014d2:	00001517          	auipc	a0,0x1
ffffffffc02014d6:	34e50513          	addi	a0,a0,846 # ffffffffc0202820 <commands+0x7a0>
ffffffffc02014da:	ef5fe0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(n > 0);
ffffffffc02014de:	00001697          	auipc	a3,0x1
ffffffffc02014e2:	6aa68693          	addi	a3,a3,1706 # ffffffffc0202b88 <commands+0xb08>
ffffffffc02014e6:	00001617          	auipc	a2,0x1
ffffffffc02014ea:	32260613          	addi	a2,a2,802 # ffffffffc0202808 <commands+0x788>
ffffffffc02014ee:	08000593          	li	a1,128
ffffffffc02014f2:	00001517          	auipc	a0,0x1
ffffffffc02014f6:	32e50513          	addi	a0,a0,814 # ffffffffc0202820 <commands+0x7a0>
ffffffffc02014fa:	ed5fe0ef          	jal	ra,ffffffffc02003ce <__panic>

ffffffffc02014fe <default_alloc_pages>:
    assert(n > 0);
ffffffffc02014fe:	cd51                	beqz	a0,ffffffffc020159a <default_alloc_pages+0x9c>
    if (n > nr_free) {
ffffffffc0201500:	00005597          	auipc	a1,0x5
ffffffffc0201504:	b2058593          	addi	a1,a1,-1248 # ffffffffc0206020 <edata>
ffffffffc0201508:	0105a803          	lw	a6,16(a1)
ffffffffc020150c:	862a                	mv	a2,a0
ffffffffc020150e:	02081793          	slli	a5,a6,0x20
ffffffffc0201512:	9381                	srli	a5,a5,0x20
ffffffffc0201514:	00a7ee63          	bltu	a5,a0,ffffffffc0201530 <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc0201518:	87ae                	mv	a5,a1
ffffffffc020151a:	a801                	j	ffffffffc020152a <default_alloc_pages+0x2c>
        if (p->property >= n) {
ffffffffc020151c:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201520:	02071693          	slli	a3,a4,0x20
ffffffffc0201524:	9281                	srli	a3,a3,0x20
ffffffffc0201526:	00c6f763          	bgeu	a3,a2,ffffffffc0201534 <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc020152a:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc020152c:	feb798e3          	bne	a5,a1,ffffffffc020151c <default_alloc_pages+0x1e>
        return NULL;
ffffffffc0201530:	4501                	li	a0,0
}
ffffffffc0201532:	8082                	ret
        struct Page *p = le2page(le, page_link);
ffffffffc0201534:	fe878513          	addi	a0,a5,-24
    if (page != NULL) {
ffffffffc0201538:	dd6d                	beqz	a0,ffffffffc0201532 <default_alloc_pages+0x34>
    return listelm->prev;
ffffffffc020153a:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc020153e:	0087b303          	ld	t1,8(a5)
    prev->next = next;
ffffffffc0201542:	00060e1b          	sext.w	t3,a2
ffffffffc0201546:	0068b423          	sd	t1,8(a7) # ff0008 <BASE_ADDRESS-0xffffffffbf20fff8>
    next->prev = prev;
ffffffffc020154a:	01133023          	sd	a7,0(t1)
        if (page->property > n) {
ffffffffc020154e:	02d67b63          	bgeu	a2,a3,ffffffffc0201584 <default_alloc_pages+0x86>
            struct Page *p = page + n;
ffffffffc0201552:	00261693          	slli	a3,a2,0x2
ffffffffc0201556:	96b2                	add	a3,a3,a2
ffffffffc0201558:	068e                	slli	a3,a3,0x3
ffffffffc020155a:	96aa                	add	a3,a3,a0
            p->property = page->property - n;
ffffffffc020155c:	41c7073b          	subw	a4,a4,t3
ffffffffc0201560:	ca98                	sw	a4,16(a3)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201562:	00868613          	addi	a2,a3,8
ffffffffc0201566:	4709                	li	a4,2
ffffffffc0201568:	40e6302f          	amoor.d	zero,a4,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc020156c:	0088b703          	ld	a4,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc0201570:	01868613          	addi	a2,a3,24
    prev->next = next->prev = elm;
ffffffffc0201574:	0105a803          	lw	a6,16(a1)
ffffffffc0201578:	e310                	sd	a2,0(a4)
ffffffffc020157a:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc020157e:	f298                	sd	a4,32(a3)
    elm->prev = prev;
ffffffffc0201580:	0116bc23          	sd	a7,24(a3)
        nr_free -= n;
ffffffffc0201584:	41c8083b          	subw	a6,a6,t3
ffffffffc0201588:	00005717          	auipc	a4,0x5
ffffffffc020158c:	ab072423          	sw	a6,-1368(a4) # ffffffffc0206030 <edata+0x10>
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201590:	5775                	li	a4,-3
ffffffffc0201592:	17c1                	addi	a5,a5,-16
ffffffffc0201594:	60e7b02f          	amoand.d	zero,a4,(a5)
ffffffffc0201598:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc020159a:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc020159c:	00001697          	auipc	a3,0x1
ffffffffc02015a0:	5ec68693          	addi	a3,a3,1516 # ffffffffc0202b88 <commands+0xb08>
ffffffffc02015a4:	00001617          	auipc	a2,0x1
ffffffffc02015a8:	26460613          	addi	a2,a2,612 # ffffffffc0202808 <commands+0x788>
ffffffffc02015ac:	06200593          	li	a1,98
ffffffffc02015b0:	00001517          	auipc	a0,0x1
ffffffffc02015b4:	27050513          	addi	a0,a0,624 # ffffffffc0202820 <commands+0x7a0>
default_alloc_pages(size_t n) {
ffffffffc02015b8:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02015ba:	e15fe0ef          	jal	ra,ffffffffc02003ce <__panic>

ffffffffc02015be <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc02015be:	1141                	addi	sp,sp,-16
ffffffffc02015c0:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02015c2:	c1fd                	beqz	a1,ffffffffc02016a8 <default_init_memmap+0xea>
    for (; p != base + n; p ++) {
ffffffffc02015c4:	00259693          	slli	a3,a1,0x2
ffffffffc02015c8:	96ae                	add	a3,a3,a1
ffffffffc02015ca:	068e                	slli	a3,a3,0x3
ffffffffc02015cc:	96aa                	add	a3,a3,a0
ffffffffc02015ce:	02d50463          	beq	a0,a3,ffffffffc02015f6 <default_init_memmap+0x38>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02015d2:	6518                	ld	a4,8(a0)
        assert(PageReserved(p));
ffffffffc02015d4:	87aa                	mv	a5,a0
ffffffffc02015d6:	8b05                	andi	a4,a4,1
ffffffffc02015d8:	e709                	bnez	a4,ffffffffc02015e2 <default_init_memmap+0x24>
ffffffffc02015da:	a07d                	j	ffffffffc0201688 <default_init_memmap+0xca>
ffffffffc02015dc:	6798                	ld	a4,8(a5)
ffffffffc02015de:	8b05                	andi	a4,a4,1
ffffffffc02015e0:	c745                	beqz	a4,ffffffffc0201688 <default_init_memmap+0xca>
        p->flags = p->property = 0;
ffffffffc02015e2:	0007a823          	sw	zero,16(a5)
ffffffffc02015e6:	0007b423          	sd	zero,8(a5)
ffffffffc02015ea:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02015ee:	02878793          	addi	a5,a5,40
ffffffffc02015f2:	fed795e3          	bne	a5,a3,ffffffffc02015dc <default_init_memmap+0x1e>
    base->property = n;
ffffffffc02015f6:	2581                	sext.w	a1,a1
ffffffffc02015f8:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02015fa:	4789                	li	a5,2
ffffffffc02015fc:	00850713          	addi	a4,a0,8
ffffffffc0201600:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201604:	00005697          	auipc	a3,0x5
ffffffffc0201608:	a1c68693          	addi	a3,a3,-1508 # ffffffffc0206020 <edata>
ffffffffc020160c:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc020160e:	669c                	ld	a5,8(a3)
ffffffffc0201610:	9db9                	addw	a1,a1,a4
ffffffffc0201612:	00005717          	auipc	a4,0x5
ffffffffc0201616:	a0b72f23          	sw	a1,-1506(a4) # ffffffffc0206030 <edata+0x10>
    if (list_empty(&free_list)) {
ffffffffc020161a:	04d78a63          	beq	a5,a3,ffffffffc020166e <default_init_memmap+0xb0>
            struct Page* page = le2page(le, page_link);
ffffffffc020161e:	fe878713          	addi	a4,a5,-24
ffffffffc0201622:	628c                	ld	a1,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0201624:	4801                	li	a6,0
ffffffffc0201626:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc020162a:	00e56a63          	bltu	a0,a4,ffffffffc020163e <default_init_memmap+0x80>
    return listelm->next;
ffffffffc020162e:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0201630:	02d70563          	beq	a4,a3,ffffffffc020165a <default_init_memmap+0x9c>
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201634:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201636:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc020163a:	fee57ae3          	bgeu	a0,a4,ffffffffc020162e <default_init_memmap+0x70>
ffffffffc020163e:	00080663          	beqz	a6,ffffffffc020164a <default_init_memmap+0x8c>
ffffffffc0201642:	00005717          	auipc	a4,0x5
ffffffffc0201646:	9cb73f23          	sd	a1,-1570(a4) # ffffffffc0206020 <edata>
    __list_add(elm, listelm->prev, listelm);
ffffffffc020164a:	6398                	ld	a4,0(a5)
}
ffffffffc020164c:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc020164e:	e390                	sd	a2,0(a5)
ffffffffc0201650:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201652:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201654:	ed18                	sd	a4,24(a0)
ffffffffc0201656:	0141                	addi	sp,sp,16
ffffffffc0201658:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc020165a:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020165c:	f114                	sd	a3,32(a0)
ffffffffc020165e:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201660:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc0201662:	85b2                	mv	a1,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201664:	00d70e63          	beq	a4,a3,ffffffffc0201680 <default_init_memmap+0xc2>
ffffffffc0201668:	4805                	li	a6,1
ffffffffc020166a:	87ba                	mv	a5,a4
ffffffffc020166c:	b7e9                	j	ffffffffc0201636 <default_init_memmap+0x78>
}
ffffffffc020166e:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0201670:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc0201674:	e398                	sd	a4,0(a5)
ffffffffc0201676:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc0201678:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020167a:	ed1c                	sd	a5,24(a0)
}
ffffffffc020167c:	0141                	addi	sp,sp,16
ffffffffc020167e:	8082                	ret
ffffffffc0201680:	60a2                	ld	ra,8(sp)
ffffffffc0201682:	e290                	sd	a2,0(a3)
ffffffffc0201684:	0141                	addi	sp,sp,16
ffffffffc0201686:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201688:	00001697          	auipc	a3,0x1
ffffffffc020168c:	50868693          	addi	a3,a3,1288 # ffffffffc0202b90 <commands+0xb10>
ffffffffc0201690:	00001617          	auipc	a2,0x1
ffffffffc0201694:	17860613          	addi	a2,a2,376 # ffffffffc0202808 <commands+0x788>
ffffffffc0201698:	04900593          	li	a1,73
ffffffffc020169c:	00001517          	auipc	a0,0x1
ffffffffc02016a0:	18450513          	addi	a0,a0,388 # ffffffffc0202820 <commands+0x7a0>
ffffffffc02016a4:	d2bfe0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(n > 0);
ffffffffc02016a8:	00001697          	auipc	a3,0x1
ffffffffc02016ac:	4e068693          	addi	a3,a3,1248 # ffffffffc0202b88 <commands+0xb08>
ffffffffc02016b0:	00001617          	auipc	a2,0x1
ffffffffc02016b4:	15860613          	addi	a2,a2,344 # ffffffffc0202808 <commands+0x788>
ffffffffc02016b8:	04600593          	li	a1,70
ffffffffc02016bc:	00001517          	auipc	a0,0x1
ffffffffc02016c0:	16450513          	addi	a0,a0,356 # ffffffffc0202820 <commands+0x7a0>
ffffffffc02016c4:	d0bfe0ef          	jal	ra,ffffffffc02003ce <__panic>

ffffffffc02016c8 <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02016c8:	100027f3          	csrr	a5,sstatus
ffffffffc02016cc:	8b89                	andi	a5,a5,2
ffffffffc02016ce:	eb89                	bnez	a5,ffffffffc02016e0 <alloc_pages+0x18>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc02016d0:	00005797          	auipc	a5,0x5
ffffffffc02016d4:	da878793          	addi	a5,a5,-600 # ffffffffc0206478 <pmm_manager>
ffffffffc02016d8:	639c                	ld	a5,0(a5)
ffffffffc02016da:	0187b303          	ld	t1,24(a5)
ffffffffc02016de:	8302                	jr	t1
struct Page *alloc_pages(size_t n) {
ffffffffc02016e0:	1141                	addi	sp,sp,-16
ffffffffc02016e2:	e406                	sd	ra,8(sp)
ffffffffc02016e4:	e022                	sd	s0,0(sp)
ffffffffc02016e6:	842a                	mv	s0,a0
        intr_disable();
ffffffffc02016e8:	8f0ff0ef          	jal	ra,ffffffffc02007d8 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02016ec:	00005797          	auipc	a5,0x5
ffffffffc02016f0:	d8c78793          	addi	a5,a5,-628 # ffffffffc0206478 <pmm_manager>
ffffffffc02016f4:	639c                	ld	a5,0(a5)
ffffffffc02016f6:	8522                	mv	a0,s0
ffffffffc02016f8:	6f9c                	ld	a5,24(a5)
ffffffffc02016fa:	9782                	jalr	a5
ffffffffc02016fc:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc02016fe:	8d4ff0ef          	jal	ra,ffffffffc02007d2 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201702:	8522                	mv	a0,s0
ffffffffc0201704:	60a2                	ld	ra,8(sp)
ffffffffc0201706:	6402                	ld	s0,0(sp)
ffffffffc0201708:	0141                	addi	sp,sp,16
ffffffffc020170a:	8082                	ret

ffffffffc020170c <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020170c:	100027f3          	csrr	a5,sstatus
ffffffffc0201710:	8b89                	andi	a5,a5,2
ffffffffc0201712:	eb89                	bnez	a5,ffffffffc0201724 <free_pages+0x18>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201714:	00005797          	auipc	a5,0x5
ffffffffc0201718:	d6478793          	addi	a5,a5,-668 # ffffffffc0206478 <pmm_manager>
ffffffffc020171c:	639c                	ld	a5,0(a5)
ffffffffc020171e:	0207b303          	ld	t1,32(a5)
ffffffffc0201722:	8302                	jr	t1
void free_pages(struct Page *base, size_t n) {
ffffffffc0201724:	1101                	addi	sp,sp,-32
ffffffffc0201726:	ec06                	sd	ra,24(sp)
ffffffffc0201728:	e822                	sd	s0,16(sp)
ffffffffc020172a:	e426                	sd	s1,8(sp)
ffffffffc020172c:	842a                	mv	s0,a0
ffffffffc020172e:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201730:	8a8ff0ef          	jal	ra,ffffffffc02007d8 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201734:	00005797          	auipc	a5,0x5
ffffffffc0201738:	d4478793          	addi	a5,a5,-700 # ffffffffc0206478 <pmm_manager>
ffffffffc020173c:	639c                	ld	a5,0(a5)
ffffffffc020173e:	85a6                	mv	a1,s1
ffffffffc0201740:	8522                	mv	a0,s0
ffffffffc0201742:	739c                	ld	a5,32(a5)
ffffffffc0201744:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201746:	6442                	ld	s0,16(sp)
ffffffffc0201748:	60e2                	ld	ra,24(sp)
ffffffffc020174a:	64a2                	ld	s1,8(sp)
ffffffffc020174c:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc020174e:	884ff06f          	j	ffffffffc02007d2 <intr_enable>

ffffffffc0201752 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201752:	100027f3          	csrr	a5,sstatus
ffffffffc0201756:	8b89                	andi	a5,a5,2
ffffffffc0201758:	eb89                	bnez	a5,ffffffffc020176a <nr_free_pages+0x18>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc020175a:	00005797          	auipc	a5,0x5
ffffffffc020175e:	d1e78793          	addi	a5,a5,-738 # ffffffffc0206478 <pmm_manager>
ffffffffc0201762:	639c                	ld	a5,0(a5)
ffffffffc0201764:	0287b303          	ld	t1,40(a5)
ffffffffc0201768:	8302                	jr	t1
size_t nr_free_pages(void) {
ffffffffc020176a:	1141                	addi	sp,sp,-16
ffffffffc020176c:	e406                	sd	ra,8(sp)
ffffffffc020176e:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201770:	868ff0ef          	jal	ra,ffffffffc02007d8 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201774:	00005797          	auipc	a5,0x5
ffffffffc0201778:	d0478793          	addi	a5,a5,-764 # ffffffffc0206478 <pmm_manager>
ffffffffc020177c:	639c                	ld	a5,0(a5)
ffffffffc020177e:	779c                	ld	a5,40(a5)
ffffffffc0201780:	9782                	jalr	a5
ffffffffc0201782:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201784:	84eff0ef          	jal	ra,ffffffffc02007d2 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201788:	8522                	mv	a0,s0
ffffffffc020178a:	60a2                	ld	ra,8(sp)
ffffffffc020178c:	6402                	ld	s0,0(sp)
ffffffffc020178e:	0141                	addi	sp,sp,16
ffffffffc0201790:	8082                	ret

ffffffffc0201792 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0201792:	00001797          	auipc	a5,0x1
ffffffffc0201796:	40e78793          	addi	a5,a5,1038 # ffffffffc0202ba0 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020179a:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc020179c:	7179                	addi	sp,sp,-48
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020179e:	00001517          	auipc	a0,0x1
ffffffffc02017a2:	45250513          	addi	a0,a0,1106 # ffffffffc0202bf0 <default_pmm_manager+0x50>
void pmm_init(void) {
ffffffffc02017a6:	f406                	sd	ra,40(sp)
ffffffffc02017a8:	f022                	sd	s0,32(sp)
ffffffffc02017aa:	e84a                	sd	s2,16(sp)
ffffffffc02017ac:	ec26                	sd	s1,24(sp)
ffffffffc02017ae:	e44e                	sd	s3,8(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc02017b0:	00005717          	auipc	a4,0x5
ffffffffc02017b4:	ccf73423          	sd	a5,-824(a4) # ffffffffc0206478 <pmm_manager>
ffffffffc02017b8:	00005417          	auipc	s0,0x5
ffffffffc02017bc:	cc040413          	addi	s0,s0,-832 # ffffffffc0206478 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02017c0:	91dfe0ef          	jal	ra,ffffffffc02000dc <cprintf>
    pmm_manager->init();
ffffffffc02017c4:	601c                	ld	a5,0(s0)
ffffffffc02017c6:	679c                	ld	a5,8(a5)
ffffffffc02017c8:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02017ca:	57f5                	li	a5,-3
ffffffffc02017cc:	07fa                	slli	a5,a5,0x1e
ffffffffc02017ce:	00005717          	auipc	a4,0x5
ffffffffc02017d2:	caf73923          	sd	a5,-846(a4) # ffffffffc0206480 <va_pa_offset>
    uint64_t mem_begin = get_memory_base();
ffffffffc02017d6:	fe5fe0ef          	jal	ra,ffffffffc02007ba <get_memory_base>
ffffffffc02017da:	892a                	mv	s2,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc02017dc:	febfe0ef          	jal	ra,ffffffffc02007c6 <get_memory_size>
    if (mem_size == 0) {
ffffffffc02017e0:	14050f63          	beqz	a0,ffffffffc020193e <pmm_init+0x1ac>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02017e4:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc02017e6:	00001517          	auipc	a0,0x1
ffffffffc02017ea:	45250513          	addi	a0,a0,1106 # ffffffffc0202c38 <default_pmm_manager+0x98>
ffffffffc02017ee:	8effe0ef          	jal	ra,ffffffffc02000dc <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02017f2:	009909b3          	add	s3,s2,s1
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc02017f6:	fff98693          	addi	a3,s3,-1
ffffffffc02017fa:	864a                	mv	a2,s2
ffffffffc02017fc:	85a6                	mv	a1,s1
ffffffffc02017fe:	00001517          	auipc	a0,0x1
ffffffffc0201802:	45250513          	addi	a0,a0,1106 # ffffffffc0202c50 <default_pmm_manager+0xb0>
ffffffffc0201806:	8d7fe0ef          	jal	ra,ffffffffc02000dc <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc020180a:	c80007b7          	lui	a5,0xc8000
ffffffffc020180e:	874e                	mv	a4,s3
ffffffffc0201810:	0f37e263          	bltu	a5,s3,ffffffffc02018f4 <pmm_init+0x162>
ffffffffc0201814:	00006797          	auipc	a5,0x6
ffffffffc0201818:	c7b78793          	addi	a5,a5,-901 # ffffffffc020748f <end+0xfff>
ffffffffc020181c:	757d                	lui	a0,0xfffff
ffffffffc020181e:	8331                	srli	a4,a4,0xc
ffffffffc0201820:	8fe9                	and	a5,a5,a0
ffffffffc0201822:	00005697          	auipc	a3,0x5
ffffffffc0201826:	c2e6b723          	sd	a4,-978(a3) # ffffffffc0206450 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020182a:	00005697          	auipc	a3,0x5
ffffffffc020182e:	c4f6bf23          	sd	a5,-930(a3) # ffffffffc0206488 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201832:	000806b7          	lui	a3,0x80
ffffffffc0201836:	02d70f63          	beq	a4,a3,ffffffffc0201874 <pmm_init+0xe2>
ffffffffc020183a:	4601                	li	a2,0
ffffffffc020183c:	4681                	li	a3,0
ffffffffc020183e:	00005897          	auipc	a7,0x5
ffffffffc0201842:	c1288893          	addi	a7,a7,-1006 # ffffffffc0206450 <npage>
ffffffffc0201846:	00005597          	auipc	a1,0x5
ffffffffc020184a:	c4258593          	addi	a1,a1,-958 # ffffffffc0206488 <pages>
ffffffffc020184e:	4805                	li	a6,1
ffffffffc0201850:	fff80537          	lui	a0,0xfff80
ffffffffc0201854:	a011                	j	ffffffffc0201858 <pmm_init+0xc6>
ffffffffc0201856:	619c                	ld	a5,0(a1)
        SetPageReserved(pages + i);
ffffffffc0201858:	97b2                	add	a5,a5,a2
ffffffffc020185a:	07a1                	addi	a5,a5,8
ffffffffc020185c:	4107b02f          	amoor.d	zero,a6,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201860:	0008b703          	ld	a4,0(a7)
ffffffffc0201864:	0685                	addi	a3,a3,1
ffffffffc0201866:	02860613          	addi	a2,a2,40
ffffffffc020186a:	00a707b3          	add	a5,a4,a0
ffffffffc020186e:	fef6e4e3          	bltu	a3,a5,ffffffffc0201856 <pmm_init+0xc4>
ffffffffc0201872:	619c                	ld	a5,0(a1)
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201874:	00271693          	slli	a3,a4,0x2
ffffffffc0201878:	96ba                	add	a3,a3,a4
ffffffffc020187a:	fec00637          	lui	a2,0xfec00
ffffffffc020187e:	963e                	add	a2,a2,a5
ffffffffc0201880:	068e                	slli	a3,a3,0x3
ffffffffc0201882:	96b2                	add	a3,a3,a2
ffffffffc0201884:	c0200637          	lui	a2,0xc0200
ffffffffc0201888:	08c6ef63          	bltu	a3,a2,ffffffffc0201926 <pmm_init+0x194>
ffffffffc020188c:	00005497          	auipc	s1,0x5
ffffffffc0201890:	bf448493          	addi	s1,s1,-1036 # ffffffffc0206480 <va_pa_offset>
ffffffffc0201894:	6088                	ld	a0,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0201896:	767d                	lui	a2,0xfffff
ffffffffc0201898:	00c9f5b3          	and	a1,s3,a2
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020189c:	8e89                	sub	a3,a3,a0
    if (freemem < mem_end) {
ffffffffc020189e:	04b6ee63          	bltu	a3,a1,ffffffffc02018fa <pmm_init+0x168>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc02018a2:	601c                	ld	a5,0(s0)
ffffffffc02018a4:	7b9c                	ld	a5,48(a5)
ffffffffc02018a6:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02018a8:	00001517          	auipc	a0,0x1
ffffffffc02018ac:	43050513          	addi	a0,a0,1072 # ffffffffc0202cd8 <default_pmm_manager+0x138>
ffffffffc02018b0:	82dfe0ef          	jal	ra,ffffffffc02000dc <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc02018b4:	00003697          	auipc	a3,0x3
ffffffffc02018b8:	74c68693          	addi	a3,a3,1868 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc02018bc:	00005797          	auipc	a5,0x5
ffffffffc02018c0:	b8d7be23          	sd	a3,-1124(a5) # ffffffffc0206458 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc02018c4:	c02007b7          	lui	a5,0xc0200
ffffffffc02018c8:	08f6e763          	bltu	a3,a5,ffffffffc0201956 <pmm_init+0x1c4>
ffffffffc02018cc:	609c                	ld	a5,0(s1)
}
ffffffffc02018ce:	7402                	ld	s0,32(sp)
ffffffffc02018d0:	70a2                	ld	ra,40(sp)
ffffffffc02018d2:	64e2                	ld	s1,24(sp)
ffffffffc02018d4:	6942                	ld	s2,16(sp)
ffffffffc02018d6:	69a2                	ld	s3,8(sp)
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02018d8:	85b6                	mv	a1,a3
    satp_physical = PADDR(satp_virtual);
ffffffffc02018da:	8e9d                	sub	a3,a3,a5
ffffffffc02018dc:	00005797          	auipc	a5,0x5
ffffffffc02018e0:	b8d7ba23          	sd	a3,-1132(a5) # ffffffffc0206470 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02018e4:	00001517          	auipc	a0,0x1
ffffffffc02018e8:	41450513          	addi	a0,a0,1044 # ffffffffc0202cf8 <default_pmm_manager+0x158>
ffffffffc02018ec:	8636                	mv	a2,a3
}
ffffffffc02018ee:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02018f0:	fecfe06f          	j	ffffffffc02000dc <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc02018f4:	c8000737          	lui	a4,0xc8000
ffffffffc02018f8:	bf31                	j	ffffffffc0201814 <pmm_init+0x82>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc02018fa:	6505                	lui	a0,0x1
ffffffffc02018fc:	157d                	addi	a0,a0,-1
ffffffffc02018fe:	96aa                	add	a3,a3,a0
ffffffffc0201900:	8ef1                	and	a3,a3,a2
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0201902:	00c6d513          	srli	a0,a3,0xc
ffffffffc0201906:	06e57463          	bgeu	a0,a4,ffffffffc020196e <pmm_init+0x1dc>
    pmm_manager->init_memmap(base, n);
ffffffffc020190a:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc020190c:	fff80737          	lui	a4,0xfff80
ffffffffc0201910:	972a                	add	a4,a4,a0
ffffffffc0201912:	00271513          	slli	a0,a4,0x2
ffffffffc0201916:	953a                	add	a0,a0,a4
ffffffffc0201918:	6a18                	ld	a4,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc020191a:	8d95                	sub	a1,a1,a3
ffffffffc020191c:	050e                	slli	a0,a0,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc020191e:	81b1                	srli	a1,a1,0xc
ffffffffc0201920:	953e                	add	a0,a0,a5
ffffffffc0201922:	9702                	jalr	a4
ffffffffc0201924:	bfbd                	j	ffffffffc02018a2 <pmm_init+0x110>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201926:	00001617          	auipc	a2,0x1
ffffffffc020192a:	35a60613          	addi	a2,a2,858 # ffffffffc0202c80 <default_pmm_manager+0xe0>
ffffffffc020192e:	07100593          	li	a1,113
ffffffffc0201932:	00001517          	auipc	a0,0x1
ffffffffc0201936:	2f650513          	addi	a0,a0,758 # ffffffffc0202c28 <default_pmm_manager+0x88>
ffffffffc020193a:	a95fe0ef          	jal	ra,ffffffffc02003ce <__panic>
        panic("DTB memory info not available");
ffffffffc020193e:	00001617          	auipc	a2,0x1
ffffffffc0201942:	2ca60613          	addi	a2,a2,714 # ffffffffc0202c08 <default_pmm_manager+0x68>
ffffffffc0201946:	05a00593          	li	a1,90
ffffffffc020194a:	00001517          	auipc	a0,0x1
ffffffffc020194e:	2de50513          	addi	a0,a0,734 # ffffffffc0202c28 <default_pmm_manager+0x88>
ffffffffc0201952:	a7dfe0ef          	jal	ra,ffffffffc02003ce <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201956:	00001617          	auipc	a2,0x1
ffffffffc020195a:	32a60613          	addi	a2,a2,810 # ffffffffc0202c80 <default_pmm_manager+0xe0>
ffffffffc020195e:	08c00593          	li	a1,140
ffffffffc0201962:	00001517          	auipc	a0,0x1
ffffffffc0201966:	2c650513          	addi	a0,a0,710 # ffffffffc0202c28 <default_pmm_manager+0x88>
ffffffffc020196a:	a65fe0ef          	jal	ra,ffffffffc02003ce <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020196e:	00001617          	auipc	a2,0x1
ffffffffc0201972:	33a60613          	addi	a2,a2,826 # ffffffffc0202ca8 <default_pmm_manager+0x108>
ffffffffc0201976:	06b00593          	li	a1,107
ffffffffc020197a:	00001517          	auipc	a0,0x1
ffffffffc020197e:	34e50513          	addi	a0,a0,846 # ffffffffc0202cc8 <default_pmm_manager+0x128>
ffffffffc0201982:	a4dfe0ef          	jal	ra,ffffffffc02003ce <__panic>

ffffffffc0201986 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201986:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020198a:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc020198c:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201990:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0201992:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201996:	f022                	sd	s0,32(sp)
ffffffffc0201998:	ec26                	sd	s1,24(sp)
ffffffffc020199a:	e84a                	sd	s2,16(sp)
ffffffffc020199c:	f406                	sd	ra,40(sp)
ffffffffc020199e:	e44e                	sd	s3,8(sp)
ffffffffc02019a0:	84aa                	mv	s1,a0
ffffffffc02019a2:	892e                	mv	s2,a1
ffffffffc02019a4:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc02019a8:	2a01                	sext.w	s4,s4

    // first recursively print all preceding (more significant) digits
    if (num >= base) {
ffffffffc02019aa:	03067e63          	bgeu	a2,a6,ffffffffc02019e6 <printnum+0x60>
ffffffffc02019ae:	89be                	mv	s3,a5
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02019b0:	00805763          	blez	s0,ffffffffc02019be <printnum+0x38>
ffffffffc02019b4:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02019b6:	85ca                	mv	a1,s2
ffffffffc02019b8:	854e                	mv	a0,s3
ffffffffc02019ba:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02019bc:	fc65                	bnez	s0,ffffffffc02019b4 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02019be:	1a02                	slli	s4,s4,0x20
ffffffffc02019c0:	020a5a13          	srli	s4,s4,0x20
ffffffffc02019c4:	00001797          	auipc	a5,0x1
ffffffffc02019c8:	50478793          	addi	a5,a5,1284 # ffffffffc0202ec8 <error_string+0x38>
ffffffffc02019cc:	9a3e                	add	s4,s4,a5
}
ffffffffc02019ce:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02019d0:	000a4503          	lbu	a0,0(s4)
}
ffffffffc02019d4:	70a2                	ld	ra,40(sp)
ffffffffc02019d6:	69a2                	ld	s3,8(sp)
ffffffffc02019d8:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02019da:	85ca                	mv	a1,s2
ffffffffc02019dc:	8326                	mv	t1,s1
}
ffffffffc02019de:	6942                	ld	s2,16(sp)
ffffffffc02019e0:	64e2                	ld	s1,24(sp)
ffffffffc02019e2:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02019e4:	8302                	jr	t1
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02019e6:	03065633          	divu	a2,a2,a6
ffffffffc02019ea:	8722                	mv	a4,s0
ffffffffc02019ec:	f9bff0ef          	jal	ra,ffffffffc0201986 <printnum>
ffffffffc02019f0:	b7f9                	j	ffffffffc02019be <printnum+0x38>

ffffffffc02019f2 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02019f2:	7119                	addi	sp,sp,-128
ffffffffc02019f4:	f4a6                	sd	s1,104(sp)
ffffffffc02019f6:	f0ca                	sd	s2,96(sp)
ffffffffc02019f8:	e8d2                	sd	s4,80(sp)
ffffffffc02019fa:	e4d6                	sd	s5,72(sp)
ffffffffc02019fc:	e0da                	sd	s6,64(sp)
ffffffffc02019fe:	fc5e                	sd	s7,56(sp)
ffffffffc0201a00:	f862                	sd	s8,48(sp)
ffffffffc0201a02:	f06a                	sd	s10,32(sp)
ffffffffc0201a04:	fc86                	sd	ra,120(sp)
ffffffffc0201a06:	f8a2                	sd	s0,112(sp)
ffffffffc0201a08:	ecce                	sd	s3,88(sp)
ffffffffc0201a0a:	f466                	sd	s9,40(sp)
ffffffffc0201a0c:	ec6e                	sd	s11,24(sp)
ffffffffc0201a0e:	892a                	mv	s2,a0
ffffffffc0201a10:	84ae                	mv	s1,a1
ffffffffc0201a12:	8d32                	mv	s10,a2
ffffffffc0201a14:	8ab6                	mv	s5,a3
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0201a16:	5b7d                	li	s6,-1
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a18:	00001a17          	auipc	s4,0x1
ffffffffc0201a1c:	320a0a13          	addi	s4,s4,800 # ffffffffc0202d38 <default_pmm_manager+0x198>
                for (width -= strnlen(p, precision); width > 0; width --) {
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201a20:	05e00b93          	li	s7,94
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201a24:	00001c17          	auipc	s8,0x1
ffffffffc0201a28:	46cc0c13          	addi	s8,s8,1132 # ffffffffc0202e90 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a2c:	000d4503          	lbu	a0,0(s10)
ffffffffc0201a30:	02500793          	li	a5,37
ffffffffc0201a34:	001d0413          	addi	s0,s10,1
ffffffffc0201a38:	00f50e63          	beq	a0,a5,ffffffffc0201a54 <vprintfmt+0x62>
            if (ch == '\0') {
ffffffffc0201a3c:	c521                	beqz	a0,ffffffffc0201a84 <vprintfmt+0x92>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a3e:	02500993          	li	s3,37
ffffffffc0201a42:	a011                	j	ffffffffc0201a46 <vprintfmt+0x54>
            if (ch == '\0') {
ffffffffc0201a44:	c121                	beqz	a0,ffffffffc0201a84 <vprintfmt+0x92>
            putch(ch, putdat);
ffffffffc0201a46:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a48:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201a4a:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a4c:	fff44503          	lbu	a0,-1(s0)
ffffffffc0201a50:	ff351ae3          	bne	a0,s3,ffffffffc0201a44 <vprintfmt+0x52>
ffffffffc0201a54:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201a58:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201a5c:	4981                	li	s3,0
ffffffffc0201a5e:	4801                	li	a6,0
        width = precision = -1;
ffffffffc0201a60:	5cfd                	li	s9,-1
ffffffffc0201a62:	5dfd                	li	s11,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a64:	05500593          	li	a1,85
                if (ch < '0' || ch > '9') {
ffffffffc0201a68:	4525                	li	a0,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a6a:	fdd6069b          	addiw	a3,a2,-35
ffffffffc0201a6e:	0ff6f693          	andi	a3,a3,255
ffffffffc0201a72:	00140d13          	addi	s10,s0,1
ffffffffc0201a76:	1ed5ef63          	bltu	a1,a3,ffffffffc0201c74 <vprintfmt+0x282>
ffffffffc0201a7a:	068a                	slli	a3,a3,0x2
ffffffffc0201a7c:	96d2                	add	a3,a3,s4
ffffffffc0201a7e:	4294                	lw	a3,0(a3)
ffffffffc0201a80:	96d2                	add	a3,a3,s4
ffffffffc0201a82:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201a84:	70e6                	ld	ra,120(sp)
ffffffffc0201a86:	7446                	ld	s0,112(sp)
ffffffffc0201a88:	74a6                	ld	s1,104(sp)
ffffffffc0201a8a:	7906                	ld	s2,96(sp)
ffffffffc0201a8c:	69e6                	ld	s3,88(sp)
ffffffffc0201a8e:	6a46                	ld	s4,80(sp)
ffffffffc0201a90:	6aa6                	ld	s5,72(sp)
ffffffffc0201a92:	6b06                	ld	s6,64(sp)
ffffffffc0201a94:	7be2                	ld	s7,56(sp)
ffffffffc0201a96:	7c42                	ld	s8,48(sp)
ffffffffc0201a98:	7ca2                	ld	s9,40(sp)
ffffffffc0201a9a:	7d02                	ld	s10,32(sp)
ffffffffc0201a9c:	6de2                	ld	s11,24(sp)
ffffffffc0201a9e:	6109                	addi	sp,sp,128
ffffffffc0201aa0:	8082                	ret
            padc = '-';
ffffffffc0201aa2:	87b2                	mv	a5,a2
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201aa4:	00144603          	lbu	a2,1(s0)
ffffffffc0201aa8:	846a                	mv	s0,s10
ffffffffc0201aaa:	b7c1                	j	ffffffffc0201a6a <vprintfmt+0x78>
            precision = va_arg(ap, int);
ffffffffc0201aac:	000aac83          	lw	s9,0(s5)
            goto process_precision;
ffffffffc0201ab0:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0201ab4:	0aa1                	addi	s5,s5,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201ab6:	846a                	mv	s0,s10
            if (width < 0)
ffffffffc0201ab8:	fa0dd9e3          	bgez	s11,ffffffffc0201a6a <vprintfmt+0x78>
                width = precision, precision = -1;
ffffffffc0201abc:	8de6                	mv	s11,s9
ffffffffc0201abe:	5cfd                	li	s9,-1
ffffffffc0201ac0:	b76d                	j	ffffffffc0201a6a <vprintfmt+0x78>
            if (width < 0)
ffffffffc0201ac2:	fffdc693          	not	a3,s11
ffffffffc0201ac6:	96fd                	srai	a3,a3,0x3f
ffffffffc0201ac8:	00ddfdb3          	and	s11,s11,a3
ffffffffc0201acc:	00144603          	lbu	a2,1(s0)
ffffffffc0201ad0:	2d81                	sext.w	s11,s11
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201ad2:	846a                	mv	s0,s10
ffffffffc0201ad4:	bf59                	j	ffffffffc0201a6a <vprintfmt+0x78>
    if (lflag >= 2) {
ffffffffc0201ad6:	4705                	li	a4,1
ffffffffc0201ad8:	008a8593          	addi	a1,s5,8
ffffffffc0201adc:	01074463          	blt	a4,a6,ffffffffc0201ae4 <vprintfmt+0xf2>
    else if (lflag) {
ffffffffc0201ae0:	22080863          	beqz	a6,ffffffffc0201d10 <vprintfmt+0x31e>
        return va_arg(*ap, unsigned long);
ffffffffc0201ae4:	000ab603          	ld	a2,0(s5)
ffffffffc0201ae8:	46c1                	li	a3,16
ffffffffc0201aea:	8aae                	mv	s5,a1
ffffffffc0201aec:	a291                	j	ffffffffc0201c30 <vprintfmt+0x23e>
                precision = precision * 10 + ch - '0';
ffffffffc0201aee:	fd060c9b          	addiw	s9,a2,-48
                ch = *fmt;
ffffffffc0201af2:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201af6:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201af8:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0201afc:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201b00:	fad56ce3          	bltu	a0,a3,ffffffffc0201ab8 <vprintfmt+0xc6>
            for (precision = 0; ; ++ fmt) {
ffffffffc0201b04:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201b06:	002c969b          	slliw	a3,s9,0x2
                ch = *fmt;
ffffffffc0201b0a:	00044603          	lbu	a2,0(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201b0e:	0196873b          	addw	a4,a3,s9
ffffffffc0201b12:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201b16:	0117073b          	addw	a4,a4,a7
                if (ch < '0' || ch > '9') {
ffffffffc0201b1a:	fd06069b          	addiw	a3,a2,-48
                precision = precision * 10 + ch - '0';
ffffffffc0201b1e:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc0201b22:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201b26:	fcd57fe3          	bgeu	a0,a3,ffffffffc0201b04 <vprintfmt+0x112>
ffffffffc0201b2a:	b779                	j	ffffffffc0201ab8 <vprintfmt+0xc6>
            putch(va_arg(ap, int), putdat);
ffffffffc0201b2c:	000aa503          	lw	a0,0(s5)
ffffffffc0201b30:	85a6                	mv	a1,s1
ffffffffc0201b32:	0aa1                	addi	s5,s5,8
ffffffffc0201b34:	9902                	jalr	s2
            break;
ffffffffc0201b36:	bddd                	j	ffffffffc0201a2c <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201b38:	4705                	li	a4,1
ffffffffc0201b3a:	008a8993          	addi	s3,s5,8
ffffffffc0201b3e:	01074463          	blt	a4,a6,ffffffffc0201b46 <vprintfmt+0x154>
    else if (lflag) {
ffffffffc0201b42:	1c080463          	beqz	a6,ffffffffc0201d0a <vprintfmt+0x318>
        return va_arg(*ap, long);
ffffffffc0201b46:	000ab403          	ld	s0,0(s5)
            if ((long long)num < 0) {
ffffffffc0201b4a:	1c044a63          	bltz	s0,ffffffffc0201d1e <vprintfmt+0x32c>
            num = getint(&ap, lflag);
ffffffffc0201b4e:	8622                	mv	a2,s0
ffffffffc0201b50:	8ace                	mv	s5,s3
ffffffffc0201b52:	46a9                	li	a3,10
ffffffffc0201b54:	a8f1                	j	ffffffffc0201c30 <vprintfmt+0x23e>
            err = va_arg(ap, int);
ffffffffc0201b56:	000aa783          	lw	a5,0(s5)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201b5a:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201b5c:	0aa1                	addi	s5,s5,8
            if (err < 0) {
ffffffffc0201b5e:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201b62:	8fb5                	xor	a5,a5,a3
ffffffffc0201b64:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201b68:	12d74963          	blt	a4,a3,ffffffffc0201c9a <vprintfmt+0x2a8>
ffffffffc0201b6c:	00369793          	slli	a5,a3,0x3
ffffffffc0201b70:	97e2                	add	a5,a5,s8
ffffffffc0201b72:	639c                	ld	a5,0(a5)
ffffffffc0201b74:	12078363          	beqz	a5,ffffffffc0201c9a <vprintfmt+0x2a8>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201b78:	86be                	mv	a3,a5
ffffffffc0201b7a:	00001617          	auipc	a2,0x1
ffffffffc0201b7e:	3fe60613          	addi	a2,a2,1022 # ffffffffc0202f78 <error_string+0xe8>
ffffffffc0201b82:	85a6                	mv	a1,s1
ffffffffc0201b84:	854a                	mv	a0,s2
ffffffffc0201b86:	1cc000ef          	jal	ra,ffffffffc0201d52 <printfmt>
ffffffffc0201b8a:	b54d                	j	ffffffffc0201a2c <vprintfmt+0x3a>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201b8c:	000ab603          	ld	a2,0(s5)
ffffffffc0201b90:	0aa1                	addi	s5,s5,8
ffffffffc0201b92:	1a060163          	beqz	a2,ffffffffc0201d34 <vprintfmt+0x342>
            if (width > 0 && padc != '-') {
ffffffffc0201b96:	00160413          	addi	s0,a2,1
ffffffffc0201b9a:	15b05763          	blez	s11,ffffffffc0201ce8 <vprintfmt+0x2f6>
ffffffffc0201b9e:	02d00593          	li	a1,45
ffffffffc0201ba2:	10b79d63          	bne	a5,a1,ffffffffc0201cbc <vprintfmt+0x2ca>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201ba6:	00064783          	lbu	a5,0(a2)
ffffffffc0201baa:	0007851b          	sext.w	a0,a5
ffffffffc0201bae:	c905                	beqz	a0,ffffffffc0201bde <vprintfmt+0x1ec>
ffffffffc0201bb0:	000cc563          	bltz	s9,ffffffffc0201bba <vprintfmt+0x1c8>
ffffffffc0201bb4:	3cfd                	addiw	s9,s9,-1
ffffffffc0201bb6:	036c8263          	beq	s9,s6,ffffffffc0201bda <vprintfmt+0x1e8>
                    putch('?', putdat);
ffffffffc0201bba:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201bbc:	14098f63          	beqz	s3,ffffffffc0201d1a <vprintfmt+0x328>
ffffffffc0201bc0:	3781                	addiw	a5,a5,-32
ffffffffc0201bc2:	14fbfc63          	bgeu	s7,a5,ffffffffc0201d1a <vprintfmt+0x328>
                    putch('?', putdat);
ffffffffc0201bc6:	03f00513          	li	a0,63
ffffffffc0201bca:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201bcc:	0405                	addi	s0,s0,1
ffffffffc0201bce:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201bd2:	3dfd                	addiw	s11,s11,-1
ffffffffc0201bd4:	0007851b          	sext.w	a0,a5
ffffffffc0201bd8:	fd61                	bnez	a0,ffffffffc0201bb0 <vprintfmt+0x1be>
            for (; width > 0; width --) {
ffffffffc0201bda:	e5b059e3          	blez	s11,ffffffffc0201a2c <vprintfmt+0x3a>
ffffffffc0201bde:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201be0:	85a6                	mv	a1,s1
ffffffffc0201be2:	02000513          	li	a0,32
ffffffffc0201be6:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201be8:	e40d82e3          	beqz	s11,ffffffffc0201a2c <vprintfmt+0x3a>
ffffffffc0201bec:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201bee:	85a6                	mv	a1,s1
ffffffffc0201bf0:	02000513          	li	a0,32
ffffffffc0201bf4:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201bf6:	fe0d94e3          	bnez	s11,ffffffffc0201bde <vprintfmt+0x1ec>
ffffffffc0201bfa:	bd0d                	j	ffffffffc0201a2c <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201bfc:	4705                	li	a4,1
ffffffffc0201bfe:	008a8593          	addi	a1,s5,8
ffffffffc0201c02:	01074463          	blt	a4,a6,ffffffffc0201c0a <vprintfmt+0x218>
    else if (lflag) {
ffffffffc0201c06:	0e080863          	beqz	a6,ffffffffc0201cf6 <vprintfmt+0x304>
        return va_arg(*ap, unsigned long);
ffffffffc0201c0a:	000ab603          	ld	a2,0(s5)
ffffffffc0201c0e:	46a1                	li	a3,8
ffffffffc0201c10:	8aae                	mv	s5,a1
ffffffffc0201c12:	a839                	j	ffffffffc0201c30 <vprintfmt+0x23e>
            putch('0', putdat);
ffffffffc0201c14:	03000513          	li	a0,48
ffffffffc0201c18:	85a6                	mv	a1,s1
ffffffffc0201c1a:	e03e                	sd	a5,0(sp)
ffffffffc0201c1c:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201c1e:	85a6                	mv	a1,s1
ffffffffc0201c20:	07800513          	li	a0,120
ffffffffc0201c24:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201c26:	0aa1                	addi	s5,s5,8
ffffffffc0201c28:	ff8ab603          	ld	a2,-8(s5)
            goto number;
ffffffffc0201c2c:	6782                	ld	a5,0(sp)
ffffffffc0201c2e:	46c1                	li	a3,16
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201c30:	2781                	sext.w	a5,a5
ffffffffc0201c32:	876e                	mv	a4,s11
ffffffffc0201c34:	85a6                	mv	a1,s1
ffffffffc0201c36:	854a                	mv	a0,s2
ffffffffc0201c38:	d4fff0ef          	jal	ra,ffffffffc0201986 <printnum>
            break;
ffffffffc0201c3c:	bbc5                	j	ffffffffc0201a2c <vprintfmt+0x3a>
            lflag ++;
ffffffffc0201c3e:	00144603          	lbu	a2,1(s0)
ffffffffc0201c42:	2805                	addiw	a6,a6,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c44:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201c46:	b515                	j	ffffffffc0201a6a <vprintfmt+0x78>
            goto reswitch;
ffffffffc0201c48:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201c4c:	4985                	li	s3,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c4e:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201c50:	bd29                	j	ffffffffc0201a6a <vprintfmt+0x78>
            putch(ch, putdat);
ffffffffc0201c52:	85a6                	mv	a1,s1
ffffffffc0201c54:	02500513          	li	a0,37
ffffffffc0201c58:	9902                	jalr	s2
            break;
ffffffffc0201c5a:	bbc9                	j	ffffffffc0201a2c <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201c5c:	4705                	li	a4,1
ffffffffc0201c5e:	008a8593          	addi	a1,s5,8
ffffffffc0201c62:	01074463          	blt	a4,a6,ffffffffc0201c6a <vprintfmt+0x278>
    else if (lflag) {
ffffffffc0201c66:	08080d63          	beqz	a6,ffffffffc0201d00 <vprintfmt+0x30e>
        return va_arg(*ap, unsigned long);
ffffffffc0201c6a:	000ab603          	ld	a2,0(s5)
ffffffffc0201c6e:	46a9                	li	a3,10
ffffffffc0201c70:	8aae                	mv	s5,a1
ffffffffc0201c72:	bf7d                	j	ffffffffc0201c30 <vprintfmt+0x23e>
            putch('%', putdat);
ffffffffc0201c74:	85a6                	mv	a1,s1
ffffffffc0201c76:	02500513          	li	a0,37
ffffffffc0201c7a:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201c7c:	fff44703          	lbu	a4,-1(s0)
ffffffffc0201c80:	02500793          	li	a5,37
ffffffffc0201c84:	8d22                	mv	s10,s0
ffffffffc0201c86:	daf703e3          	beq	a4,a5,ffffffffc0201a2c <vprintfmt+0x3a>
ffffffffc0201c8a:	02500713          	li	a4,37
ffffffffc0201c8e:	1d7d                	addi	s10,s10,-1
ffffffffc0201c90:	fffd4783          	lbu	a5,-1(s10)
ffffffffc0201c94:	fee79de3          	bne	a5,a4,ffffffffc0201c8e <vprintfmt+0x29c>
ffffffffc0201c98:	bb51                	j	ffffffffc0201a2c <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201c9a:	00001617          	auipc	a2,0x1
ffffffffc0201c9e:	2ce60613          	addi	a2,a2,718 # ffffffffc0202f68 <error_string+0xd8>
ffffffffc0201ca2:	85a6                	mv	a1,s1
ffffffffc0201ca4:	854a                	mv	a0,s2
ffffffffc0201ca6:	0ac000ef          	jal	ra,ffffffffc0201d52 <printfmt>
ffffffffc0201caa:	b349                	j	ffffffffc0201a2c <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201cac:	00001617          	auipc	a2,0x1
ffffffffc0201cb0:	2b460613          	addi	a2,a2,692 # ffffffffc0202f60 <error_string+0xd0>
            if (width > 0 && padc != '-') {
ffffffffc0201cb4:	00001417          	auipc	s0,0x1
ffffffffc0201cb8:	2ad40413          	addi	s0,s0,685 # ffffffffc0202f61 <error_string+0xd1>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201cbc:	8532                	mv	a0,a2
ffffffffc0201cbe:	85e6                	mv	a1,s9
ffffffffc0201cc0:	e032                	sd	a2,0(sp)
ffffffffc0201cc2:	e43e                	sd	a5,8(sp)
ffffffffc0201cc4:	1e0000ef          	jal	ra,ffffffffc0201ea4 <strnlen>
ffffffffc0201cc8:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201ccc:	6602                	ld	a2,0(sp)
ffffffffc0201cce:	01b05d63          	blez	s11,ffffffffc0201ce8 <vprintfmt+0x2f6>
ffffffffc0201cd2:	67a2                	ld	a5,8(sp)
ffffffffc0201cd4:	2781                	sext.w	a5,a5
ffffffffc0201cd6:	e43e                	sd	a5,8(sp)
                    putch(padc, putdat);
ffffffffc0201cd8:	6522                	ld	a0,8(sp)
ffffffffc0201cda:	85a6                	mv	a1,s1
ffffffffc0201cdc:	e032                	sd	a2,0(sp)
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201cde:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201ce0:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201ce2:	6602                	ld	a2,0(sp)
ffffffffc0201ce4:	fe0d9ae3          	bnez	s11,ffffffffc0201cd8 <vprintfmt+0x2e6>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201ce8:	00064783          	lbu	a5,0(a2)
ffffffffc0201cec:	0007851b          	sext.w	a0,a5
ffffffffc0201cf0:	ec0510e3          	bnez	a0,ffffffffc0201bb0 <vprintfmt+0x1be>
ffffffffc0201cf4:	bb25                	j	ffffffffc0201a2c <vprintfmt+0x3a>
        return va_arg(*ap, unsigned int);
ffffffffc0201cf6:	000ae603          	lwu	a2,0(s5)
ffffffffc0201cfa:	46a1                	li	a3,8
ffffffffc0201cfc:	8aae                	mv	s5,a1
ffffffffc0201cfe:	bf0d                	j	ffffffffc0201c30 <vprintfmt+0x23e>
ffffffffc0201d00:	000ae603          	lwu	a2,0(s5)
ffffffffc0201d04:	46a9                	li	a3,10
ffffffffc0201d06:	8aae                	mv	s5,a1
ffffffffc0201d08:	b725                	j	ffffffffc0201c30 <vprintfmt+0x23e>
        return va_arg(*ap, int);
ffffffffc0201d0a:	000aa403          	lw	s0,0(s5)
ffffffffc0201d0e:	bd35                	j	ffffffffc0201b4a <vprintfmt+0x158>
        return va_arg(*ap, unsigned int);
ffffffffc0201d10:	000ae603          	lwu	a2,0(s5)
ffffffffc0201d14:	46c1                	li	a3,16
ffffffffc0201d16:	8aae                	mv	s5,a1
ffffffffc0201d18:	bf21                	j	ffffffffc0201c30 <vprintfmt+0x23e>
                    putch(ch, putdat);
ffffffffc0201d1a:	9902                	jalr	s2
ffffffffc0201d1c:	bd45                	j	ffffffffc0201bcc <vprintfmt+0x1da>
                putch('-', putdat);
ffffffffc0201d1e:	85a6                	mv	a1,s1
ffffffffc0201d20:	02d00513          	li	a0,45
ffffffffc0201d24:	e03e                	sd	a5,0(sp)
ffffffffc0201d26:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201d28:	8ace                	mv	s5,s3
ffffffffc0201d2a:	40800633          	neg	a2,s0
ffffffffc0201d2e:	46a9                	li	a3,10
ffffffffc0201d30:	6782                	ld	a5,0(sp)
ffffffffc0201d32:	bdfd                	j	ffffffffc0201c30 <vprintfmt+0x23e>
            if (width > 0 && padc != '-') {
ffffffffc0201d34:	01b05663          	blez	s11,ffffffffc0201d40 <vprintfmt+0x34e>
ffffffffc0201d38:	02d00693          	li	a3,45
ffffffffc0201d3c:	f6d798e3          	bne	a5,a3,ffffffffc0201cac <vprintfmt+0x2ba>
ffffffffc0201d40:	00001417          	auipc	s0,0x1
ffffffffc0201d44:	22140413          	addi	s0,s0,545 # ffffffffc0202f61 <error_string+0xd1>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201d48:	02800513          	li	a0,40
ffffffffc0201d4c:	02800793          	li	a5,40
ffffffffc0201d50:	b585                	j	ffffffffc0201bb0 <vprintfmt+0x1be>

ffffffffc0201d52 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201d52:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201d54:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201d58:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201d5a:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201d5c:	ec06                	sd	ra,24(sp)
ffffffffc0201d5e:	f83a                	sd	a4,48(sp)
ffffffffc0201d60:	fc3e                	sd	a5,56(sp)
ffffffffc0201d62:	e0c2                	sd	a6,64(sp)
ffffffffc0201d64:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201d66:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201d68:	c8bff0ef          	jal	ra,ffffffffc02019f2 <vprintfmt>
}
ffffffffc0201d6c:	60e2                	ld	ra,24(sp)
ffffffffc0201d6e:	6161                	addi	sp,sp,80
ffffffffc0201d70:	8082                	ret

ffffffffc0201d72 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0201d72:	715d                	addi	sp,sp,-80
ffffffffc0201d74:	e486                	sd	ra,72(sp)
ffffffffc0201d76:	e0a2                	sd	s0,64(sp)
ffffffffc0201d78:	fc26                	sd	s1,56(sp)
ffffffffc0201d7a:	f84a                	sd	s2,48(sp)
ffffffffc0201d7c:	f44e                	sd	s3,40(sp)
ffffffffc0201d7e:	f052                	sd	s4,32(sp)
ffffffffc0201d80:	ec56                	sd	s5,24(sp)
ffffffffc0201d82:	e85a                	sd	s6,16(sp)
ffffffffc0201d84:	e45e                	sd	s7,8(sp)
    if (prompt != NULL) {
ffffffffc0201d86:	c901                	beqz	a0,ffffffffc0201d96 <readline+0x24>
        cprintf("%s", prompt);
ffffffffc0201d88:	85aa                	mv	a1,a0
ffffffffc0201d8a:	00001517          	auipc	a0,0x1
ffffffffc0201d8e:	1ee50513          	addi	a0,a0,494 # ffffffffc0202f78 <error_string+0xe8>
ffffffffc0201d92:	b4afe0ef          	jal	ra,ffffffffc02000dc <cprintf>
readline(const char *prompt) {
ffffffffc0201d96:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201d98:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0201d9a:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0201d9c:	4aa9                	li	s5,10
ffffffffc0201d9e:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0201da0:	00004b97          	auipc	s7,0x4
ffffffffc0201da4:	298b8b93          	addi	s7,s7,664 # ffffffffc0206038 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201da8:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc0201dac:	ba6fe0ef          	jal	ra,ffffffffc0200152 <getchar>
ffffffffc0201db0:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc0201db2:	00054b63          	bltz	a0,ffffffffc0201dc8 <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201db6:	00a95b63          	bge	s2,a0,ffffffffc0201dcc <readline+0x5a>
ffffffffc0201dba:	029a5463          	bge	s4,s1,ffffffffc0201de2 <readline+0x70>
        c = getchar();
ffffffffc0201dbe:	b94fe0ef          	jal	ra,ffffffffc0200152 <getchar>
ffffffffc0201dc2:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc0201dc4:	fe0559e3          	bgez	a0,ffffffffc0201db6 <readline+0x44>
            return NULL;
ffffffffc0201dc8:	4501                	li	a0,0
ffffffffc0201dca:	a099                	j	ffffffffc0201e10 <readline+0x9e>
        else if (c == '\b' && i > 0) {
ffffffffc0201dcc:	03341463          	bne	s0,s3,ffffffffc0201df4 <readline+0x82>
ffffffffc0201dd0:	e8b9                	bnez	s1,ffffffffc0201e26 <readline+0xb4>
        c = getchar();
ffffffffc0201dd2:	b80fe0ef          	jal	ra,ffffffffc0200152 <getchar>
ffffffffc0201dd6:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc0201dd8:	fe0548e3          	bltz	a0,ffffffffc0201dc8 <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201ddc:	fea958e3          	bge	s2,a0,ffffffffc0201dcc <readline+0x5a>
ffffffffc0201de0:	4481                	li	s1,0
            cputchar(c);
ffffffffc0201de2:	8522                	mv	a0,s0
ffffffffc0201de4:	b2cfe0ef          	jal	ra,ffffffffc0200110 <cputchar>
            buf[i ++] = c;
ffffffffc0201de8:	009b87b3          	add	a5,s7,s1
ffffffffc0201dec:	00878023          	sb	s0,0(a5)
ffffffffc0201df0:	2485                	addiw	s1,s1,1
ffffffffc0201df2:	bf6d                	j	ffffffffc0201dac <readline+0x3a>
        else if (c == '\n' || c == '\r') {
ffffffffc0201df4:	01540463          	beq	s0,s5,ffffffffc0201dfc <readline+0x8a>
ffffffffc0201df8:	fb641ae3          	bne	s0,s6,ffffffffc0201dac <readline+0x3a>
            cputchar(c);
ffffffffc0201dfc:	8522                	mv	a0,s0
ffffffffc0201dfe:	b12fe0ef          	jal	ra,ffffffffc0200110 <cputchar>
            buf[i] = '\0';
ffffffffc0201e02:	00004517          	auipc	a0,0x4
ffffffffc0201e06:	23650513          	addi	a0,a0,566 # ffffffffc0206038 <buf>
ffffffffc0201e0a:	94aa                	add	s1,s1,a0
ffffffffc0201e0c:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0201e10:	60a6                	ld	ra,72(sp)
ffffffffc0201e12:	6406                	ld	s0,64(sp)
ffffffffc0201e14:	74e2                	ld	s1,56(sp)
ffffffffc0201e16:	7942                	ld	s2,48(sp)
ffffffffc0201e18:	79a2                	ld	s3,40(sp)
ffffffffc0201e1a:	7a02                	ld	s4,32(sp)
ffffffffc0201e1c:	6ae2                	ld	s5,24(sp)
ffffffffc0201e1e:	6b42                	ld	s6,16(sp)
ffffffffc0201e20:	6ba2                	ld	s7,8(sp)
ffffffffc0201e22:	6161                	addi	sp,sp,80
ffffffffc0201e24:	8082                	ret
            cputchar(c);
ffffffffc0201e26:	4521                	li	a0,8
ffffffffc0201e28:	ae8fe0ef          	jal	ra,ffffffffc0200110 <cputchar>
            i --;
ffffffffc0201e2c:	34fd                	addiw	s1,s1,-1
ffffffffc0201e2e:	bfbd                	j	ffffffffc0201dac <readline+0x3a>

ffffffffc0201e30 <sbi_console_putchar>:
    );
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
ffffffffc0201e30:	00004797          	auipc	a5,0x4
ffffffffc0201e34:	1e878793          	addi	a5,a5,488 # ffffffffc0206018 <SBI_CONSOLE_PUTCHAR>
    __asm__ volatile (
ffffffffc0201e38:	6398                	ld	a4,0(a5)
ffffffffc0201e3a:	4781                	li	a5,0
ffffffffc0201e3c:	88ba                	mv	a7,a4
ffffffffc0201e3e:	852a                	mv	a0,a0
ffffffffc0201e40:	85be                	mv	a1,a5
ffffffffc0201e42:	863e                	mv	a2,a5
ffffffffc0201e44:	00000073          	ecall
ffffffffc0201e48:	87aa                	mv	a5,a0
}
ffffffffc0201e4a:	8082                	ret

ffffffffc0201e4c <sbi_set_timer>:

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
ffffffffc0201e4c:	00004797          	auipc	a5,0x4
ffffffffc0201e50:	61478793          	addi	a5,a5,1556 # ffffffffc0206460 <SBI_SET_TIMER>
    __asm__ volatile (
ffffffffc0201e54:	6398                	ld	a4,0(a5)
ffffffffc0201e56:	4781                	li	a5,0
ffffffffc0201e58:	88ba                	mv	a7,a4
ffffffffc0201e5a:	852a                	mv	a0,a0
ffffffffc0201e5c:	85be                	mv	a1,a5
ffffffffc0201e5e:	863e                	mv	a2,a5
ffffffffc0201e60:	00000073          	ecall
ffffffffc0201e64:	87aa                	mv	a5,a0
}
ffffffffc0201e66:	8082                	ret

ffffffffc0201e68 <sbi_console_getchar>:

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
ffffffffc0201e68:	00004797          	auipc	a5,0x4
ffffffffc0201e6c:	1a878793          	addi	a5,a5,424 # ffffffffc0206010 <SBI_CONSOLE_GETCHAR>
    __asm__ volatile (
ffffffffc0201e70:	639c                	ld	a5,0(a5)
ffffffffc0201e72:	4501                	li	a0,0
ffffffffc0201e74:	88be                	mv	a7,a5
ffffffffc0201e76:	852a                	mv	a0,a0
ffffffffc0201e78:	85aa                	mv	a1,a0
ffffffffc0201e7a:	862a                	mv	a2,a0
ffffffffc0201e7c:	00000073          	ecall
ffffffffc0201e80:	852a                	mv	a0,a0
}
ffffffffc0201e82:	2501                	sext.w	a0,a0
ffffffffc0201e84:	8082                	ret

ffffffffc0201e86 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201e86:	00054783          	lbu	a5,0(a0)
ffffffffc0201e8a:	cb91                	beqz	a5,ffffffffc0201e9e <strlen+0x18>
    size_t cnt = 0;
ffffffffc0201e8c:	4781                	li	a5,0
        cnt ++;
ffffffffc0201e8e:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc0201e90:	00f50733          	add	a4,a0,a5
ffffffffc0201e94:	00074703          	lbu	a4,0(a4) # fffffffffff80000 <end+0x3fd79b70>
ffffffffc0201e98:	fb7d                	bnez	a4,ffffffffc0201e8e <strlen+0x8>
    }
    return cnt;
}
ffffffffc0201e9a:	853e                	mv	a0,a5
ffffffffc0201e9c:	8082                	ret
    size_t cnt = 0;
ffffffffc0201e9e:	4781                	li	a5,0
}
ffffffffc0201ea0:	853e                	mv	a0,a5
ffffffffc0201ea2:	8082                	ret

ffffffffc0201ea4 <strnlen>:
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201ea4:	c185                	beqz	a1,ffffffffc0201ec4 <strnlen+0x20>
ffffffffc0201ea6:	00054783          	lbu	a5,0(a0)
ffffffffc0201eaa:	cf89                	beqz	a5,ffffffffc0201ec4 <strnlen+0x20>
    size_t cnt = 0;
ffffffffc0201eac:	4781                	li	a5,0
ffffffffc0201eae:	a021                	j	ffffffffc0201eb6 <strnlen+0x12>
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201eb0:	00074703          	lbu	a4,0(a4)
ffffffffc0201eb4:	c711                	beqz	a4,ffffffffc0201ec0 <strnlen+0x1c>
        cnt ++;
ffffffffc0201eb6:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201eb8:	00f50733          	add	a4,a0,a5
ffffffffc0201ebc:	fef59ae3          	bne	a1,a5,ffffffffc0201eb0 <strnlen+0xc>
    }
    return cnt;
}
ffffffffc0201ec0:	853e                	mv	a0,a5
ffffffffc0201ec2:	8082                	ret
    size_t cnt = 0;
ffffffffc0201ec4:	4781                	li	a5,0
}
ffffffffc0201ec6:	853e                	mv	a0,a5
ffffffffc0201ec8:	8082                	ret

ffffffffc0201eca <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201eca:	00054783          	lbu	a5,0(a0)
ffffffffc0201ece:	0005c703          	lbu	a4,0(a1)
ffffffffc0201ed2:	cb91                	beqz	a5,ffffffffc0201ee6 <strcmp+0x1c>
ffffffffc0201ed4:	00e79c63          	bne	a5,a4,ffffffffc0201eec <strcmp+0x22>
        s1 ++, s2 ++;
ffffffffc0201ed8:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201eda:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
ffffffffc0201ede:	0585                	addi	a1,a1,1
ffffffffc0201ee0:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201ee4:	fbe5                	bnez	a5,ffffffffc0201ed4 <strcmp+0xa>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201ee6:	4501                	li	a0,0
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201ee8:	9d19                	subw	a0,a0,a4
ffffffffc0201eea:	8082                	ret
ffffffffc0201eec:	0007851b          	sext.w	a0,a5
ffffffffc0201ef0:	9d19                	subw	a0,a0,a4
ffffffffc0201ef2:	8082                	ret

ffffffffc0201ef4 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201ef4:	c61d                	beqz	a2,ffffffffc0201f22 <strncmp+0x2e>
ffffffffc0201ef6:	00054703          	lbu	a4,0(a0)
ffffffffc0201efa:	0005c683          	lbu	a3,0(a1)
ffffffffc0201efe:	c715                	beqz	a4,ffffffffc0201f2a <strncmp+0x36>
ffffffffc0201f00:	02e69563          	bne	a3,a4,ffffffffc0201f2a <strncmp+0x36>
ffffffffc0201f04:	962e                	add	a2,a2,a1
ffffffffc0201f06:	a809                	j	ffffffffc0201f18 <strncmp+0x24>
ffffffffc0201f08:	00054703          	lbu	a4,0(a0)
ffffffffc0201f0c:	cf09                	beqz	a4,ffffffffc0201f26 <strncmp+0x32>
ffffffffc0201f0e:	0007c683          	lbu	a3,0(a5)
ffffffffc0201f12:	85be                	mv	a1,a5
ffffffffc0201f14:	00d71b63          	bne	a4,a3,ffffffffc0201f2a <strncmp+0x36>
        n --, s1 ++, s2 ++;
ffffffffc0201f18:	00158793          	addi	a5,a1,1
ffffffffc0201f1c:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201f1e:	fec795e3          	bne	a5,a2,ffffffffc0201f08 <strncmp+0x14>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201f22:	4501                	li	a0,0
ffffffffc0201f24:	8082                	ret
ffffffffc0201f26:	0015c683          	lbu	a3,1(a1)
ffffffffc0201f2a:	40d7053b          	subw	a0,a4,a3
}
ffffffffc0201f2e:	8082                	ret

ffffffffc0201f30 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0201f30:	00054783          	lbu	a5,0(a0)
ffffffffc0201f34:	cb91                	beqz	a5,ffffffffc0201f48 <strchr+0x18>
        if (*s == c) {
ffffffffc0201f36:	00b79563          	bne	a5,a1,ffffffffc0201f40 <strchr+0x10>
ffffffffc0201f3a:	a809                	j	ffffffffc0201f4c <strchr+0x1c>
ffffffffc0201f3c:	00b78763          	beq	a5,a1,ffffffffc0201f4a <strchr+0x1a>
            return (char *)s;
        }
        s ++;
ffffffffc0201f40:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0201f42:	00054783          	lbu	a5,0(a0)
ffffffffc0201f46:	fbfd                	bnez	a5,ffffffffc0201f3c <strchr+0xc>
    }
    return NULL;
ffffffffc0201f48:	4501                	li	a0,0
}
ffffffffc0201f4a:	8082                	ret
ffffffffc0201f4c:	8082                	ret

ffffffffc0201f4e <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201f4e:	ca01                	beqz	a2,ffffffffc0201f5e <memset+0x10>
ffffffffc0201f50:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201f52:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201f54:	0785                	addi	a5,a5,1
ffffffffc0201f56:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201f5a:	fec79de3          	bne	a5,a2,ffffffffc0201f54 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201f5e:	8082                	ret
