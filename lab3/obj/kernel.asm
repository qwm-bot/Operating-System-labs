
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00007297          	auipc	t0,0x7
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0207000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00007297          	auipc	t0,0x7
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0207008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02062b7          	lui	t0,0xc0206
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c0206137          	lui	sp,0xc0206

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 1. 使用临时寄存器 t1 计算栈顶的精确地址
    lui t1, %hi(bootstacktop)
ffffffffc0200040:	c0206337          	lui	t1,0xc0206
    addi t1, t1, %lo(bootstacktop)
ffffffffc0200044:	00030313          	mv	t1,t1
    # 2. 将精确地址一次性地、安全地传给 sp
    mv sp, t1
ffffffffc0200048:	811a                	mv	sp,t1
    # 现在栈指针已经完美设置，可以安全地调用任何C函数了
    # 然后跳转到 kern_init (不再返回)
    lui t0, %hi(kern_init)
ffffffffc020004a:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc020004e:	05428293          	addi	t0,t0,84 # ffffffffc0200054 <kern_init>
    jr t0
ffffffffc0200052:	8282                	jr	t0

ffffffffc0200054 <kern_init>:
int kern_init(void) __attribute__((noreturn));
void grade_backtrace(void);

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc0200054:	00007517          	auipc	a0,0x7
ffffffffc0200058:	fd450513          	addi	a0,a0,-44 # ffffffffc0207028 <free_area>
ffffffffc020005c:	00007617          	auipc	a2,0x7
ffffffffc0200060:	44460613          	addi	a2,a2,1092 # ffffffffc02074a0 <end>
int kern_init(void) {
ffffffffc0200064:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200066:	8e09                	sub	a2,a2,a0
ffffffffc0200068:	4581                	li	a1,0
int kern_init(void) {
ffffffffc020006a:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020006c:	773010ef          	jal	ra,ffffffffc0201fde <memset>
    dtb_init();
ffffffffc0200070:	434000ef          	jal	ra,ffffffffc02004a4 <dtb_init>
    cons_init();
ffffffffc0200074:	422000ef          	jal	ra,ffffffffc0200496 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    cputs(message);
ffffffffc0200078:	00002517          	auipc	a0,0x2
ffffffffc020007c:	00850513          	addi	a0,a0,8 # ffffffffc0202080 <etext+0x90>
ffffffffc0200080:	0b6000ef          	jal	ra,ffffffffc0200136 <cputs>

    print_kerninfo();
ffffffffc0200084:	102000ef          	jal	ra,ffffffffc0200186 <print_kerninfo>

    idt_init();
ffffffffc0200088:	7d8000ef          	jal	ra,ffffffffc0200860 <idt_init>

    pmm_init();
ffffffffc020008c:	7d6010ef          	jal	ra,ffffffffc0201862 <pmm_init>

    // LAB3 CHALLENGE3: 测试异常处理
    cprintf("\n==== Testing Illegal Instruction Exception ====\n");
ffffffffc0200090:	00002517          	auipc	a0,0x2
ffffffffc0200094:	f6050513          	addi	a0,a0,-160 # ffffffffc0201ff0 <etext>
ffffffffc0200098:	066000ef          	jal	ra,ffffffffc02000fe <cprintf>
    // 触发非法指令异常: 在S模式下执行mret指令(mret只能在M模式执行)
    __asm__ __volatile__("mret");
ffffffffc020009c:	30200073          	mret
    
    cprintf("\n==== Testing Breakpoint Exception ====\n");
ffffffffc02000a0:	00002517          	auipc	a0,0x2
ffffffffc02000a4:	f8850513          	addi	a0,a0,-120 # ffffffffc0202028 <etext+0x38>
ffffffffc02000a8:	056000ef          	jal	ra,ffffffffc02000fe <cprintf>
    // 触发断点异常
    __asm__ __volatile__("ebreak");
ffffffffc02000ac:	9002                	ebreak
    
    cprintf("\nAll exceptions handled successfully!\n\n");
ffffffffc02000ae:	00002517          	auipc	a0,0x2
ffffffffc02000b2:	faa50513          	addi	a0,a0,-86 # ffffffffc0202058 <etext+0x68>
ffffffffc02000b6:	048000ef          	jal	ra,ffffffffc02000fe <cprintf>

    clock_init();
ffffffffc02000ba:	39a000ef          	jal	ra,ffffffffc0200454 <clock_init>
    intr_enable();
ffffffffc02000be:	796000ef          	jal	ra,ffffffffc0200854 <intr_enable>

    while (1)
ffffffffc02000c2:	a001                	j	ffffffffc02000c2 <kern_init+0x6e>

ffffffffc02000c4 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc02000c4:	1141                	addi	sp,sp,-16
ffffffffc02000c6:	e022                	sd	s0,0(sp)
ffffffffc02000c8:	e406                	sd	ra,8(sp)
ffffffffc02000ca:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc02000cc:	3cc000ef          	jal	ra,ffffffffc0200498 <cons_putc>
    (*cnt) ++;
ffffffffc02000d0:	401c                	lw	a5,0(s0)
}
ffffffffc02000d2:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc02000d4:	2785                	addiw	a5,a5,1
ffffffffc02000d6:	c01c                	sw	a5,0(s0)
}
ffffffffc02000d8:	6402                	ld	s0,0(sp)
ffffffffc02000da:	0141                	addi	sp,sp,16
ffffffffc02000dc:	8082                	ret

ffffffffc02000de <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000de:	1101                	addi	sp,sp,-32
ffffffffc02000e0:	862a                	mv	a2,a0
ffffffffc02000e2:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000e4:	00000517          	auipc	a0,0x0
ffffffffc02000e8:	fe050513          	addi	a0,a0,-32 # ffffffffc02000c4 <cputch>
ffffffffc02000ec:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000ee:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000f0:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000f2:	1bd010ef          	jal	ra,ffffffffc0201aae <vprintfmt>
    return cnt;
}
ffffffffc02000f6:	60e2                	ld	ra,24(sp)
ffffffffc02000f8:	4532                	lw	a0,12(sp)
ffffffffc02000fa:	6105                	addi	sp,sp,32
ffffffffc02000fc:	8082                	ret

ffffffffc02000fe <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000fe:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200100:	02810313          	addi	t1,sp,40 # ffffffffc0206028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc0200104:	8e2a                	mv	t3,a0
ffffffffc0200106:	f42e                	sd	a1,40(sp)
ffffffffc0200108:	f832                	sd	a2,48(sp)
ffffffffc020010a:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020010c:	00000517          	auipc	a0,0x0
ffffffffc0200110:	fb850513          	addi	a0,a0,-72 # ffffffffc02000c4 <cputch>
ffffffffc0200114:	004c                	addi	a1,sp,4
ffffffffc0200116:	869a                	mv	a3,t1
ffffffffc0200118:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc020011a:	ec06                	sd	ra,24(sp)
ffffffffc020011c:	e0ba                	sd	a4,64(sp)
ffffffffc020011e:	e4be                	sd	a5,72(sp)
ffffffffc0200120:	e8c2                	sd	a6,80(sp)
ffffffffc0200122:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc0200124:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200126:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200128:	187010ef          	jal	ra,ffffffffc0201aae <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc020012c:	60e2                	ld	ra,24(sp)
ffffffffc020012e:	4512                	lw	a0,4(sp)
ffffffffc0200130:	6125                	addi	sp,sp,96
ffffffffc0200132:	8082                	ret

ffffffffc0200134 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc0200134:	a695                	j	ffffffffc0200498 <cons_putc>

ffffffffc0200136 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200136:	1101                	addi	sp,sp,-32
ffffffffc0200138:	e822                	sd	s0,16(sp)
ffffffffc020013a:	ec06                	sd	ra,24(sp)
ffffffffc020013c:	e426                	sd	s1,8(sp)
ffffffffc020013e:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc0200140:	00054503          	lbu	a0,0(a0)
ffffffffc0200144:	c51d                	beqz	a0,ffffffffc0200172 <cputs+0x3c>
ffffffffc0200146:	0405                	addi	s0,s0,1
ffffffffc0200148:	4485                	li	s1,1
ffffffffc020014a:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc020014c:	34c000ef          	jal	ra,ffffffffc0200498 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc0200150:	00044503          	lbu	a0,0(s0)
ffffffffc0200154:	008487bb          	addw	a5,s1,s0
ffffffffc0200158:	0405                	addi	s0,s0,1
ffffffffc020015a:	f96d                	bnez	a0,ffffffffc020014c <cputs+0x16>
    (*cnt) ++;
ffffffffc020015c:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc0200160:	4529                	li	a0,10
ffffffffc0200162:	336000ef          	jal	ra,ffffffffc0200498 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc0200166:	60e2                	ld	ra,24(sp)
ffffffffc0200168:	8522                	mv	a0,s0
ffffffffc020016a:	6442                	ld	s0,16(sp)
ffffffffc020016c:	64a2                	ld	s1,8(sp)
ffffffffc020016e:	6105                	addi	sp,sp,32
ffffffffc0200170:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc0200172:	4405                	li	s0,1
ffffffffc0200174:	b7f5                	j	ffffffffc0200160 <cputs+0x2a>

ffffffffc0200176 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc0200176:	1141                	addi	sp,sp,-16
ffffffffc0200178:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc020017a:	326000ef          	jal	ra,ffffffffc02004a0 <cons_getc>
ffffffffc020017e:	dd75                	beqz	a0,ffffffffc020017a <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200180:	60a2                	ld	ra,8(sp)
ffffffffc0200182:	0141                	addi	sp,sp,16
ffffffffc0200184:	8082                	ret

ffffffffc0200186 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc0200186:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200188:	00002517          	auipc	a0,0x2
ffffffffc020018c:	f1850513          	addi	a0,a0,-232 # ffffffffc02020a0 <etext+0xb0>
void print_kerninfo(void) {
ffffffffc0200190:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200192:	f6dff0ef          	jal	ra,ffffffffc02000fe <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc0200196:	00000597          	auipc	a1,0x0
ffffffffc020019a:	ebe58593          	addi	a1,a1,-322 # ffffffffc0200054 <kern_init>
ffffffffc020019e:	00002517          	auipc	a0,0x2
ffffffffc02001a2:	f2250513          	addi	a0,a0,-222 # ffffffffc02020c0 <etext+0xd0>
ffffffffc02001a6:	f59ff0ef          	jal	ra,ffffffffc02000fe <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc02001aa:	00002597          	auipc	a1,0x2
ffffffffc02001ae:	e4658593          	addi	a1,a1,-442 # ffffffffc0201ff0 <etext>
ffffffffc02001b2:	00002517          	auipc	a0,0x2
ffffffffc02001b6:	f2e50513          	addi	a0,a0,-210 # ffffffffc02020e0 <etext+0xf0>
ffffffffc02001ba:	f45ff0ef          	jal	ra,ffffffffc02000fe <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc02001be:	00007597          	auipc	a1,0x7
ffffffffc02001c2:	e6a58593          	addi	a1,a1,-406 # ffffffffc0207028 <free_area>
ffffffffc02001c6:	00002517          	auipc	a0,0x2
ffffffffc02001ca:	f3a50513          	addi	a0,a0,-198 # ffffffffc0202100 <etext+0x110>
ffffffffc02001ce:	f31ff0ef          	jal	ra,ffffffffc02000fe <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc02001d2:	00007597          	auipc	a1,0x7
ffffffffc02001d6:	2ce58593          	addi	a1,a1,718 # ffffffffc02074a0 <end>
ffffffffc02001da:	00002517          	auipc	a0,0x2
ffffffffc02001de:	f4650513          	addi	a0,a0,-186 # ffffffffc0202120 <etext+0x130>
ffffffffc02001e2:	f1dff0ef          	jal	ra,ffffffffc02000fe <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc02001e6:	00007597          	auipc	a1,0x7
ffffffffc02001ea:	6b958593          	addi	a1,a1,1721 # ffffffffc020789f <end+0x3ff>
ffffffffc02001ee:	00000797          	auipc	a5,0x0
ffffffffc02001f2:	e6678793          	addi	a5,a5,-410 # ffffffffc0200054 <kern_init>
ffffffffc02001f6:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001fa:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02001fe:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200200:	3ff5f593          	andi	a1,a1,1023
ffffffffc0200204:	95be                	add	a1,a1,a5
ffffffffc0200206:	85a9                	srai	a1,a1,0xa
ffffffffc0200208:	00002517          	auipc	a0,0x2
ffffffffc020020c:	f3850513          	addi	a0,a0,-200 # ffffffffc0202140 <etext+0x150>
}
ffffffffc0200210:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200212:	b5f5                	j	ffffffffc02000fe <cprintf>

ffffffffc0200214 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc0200214:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc0200216:	00002617          	auipc	a2,0x2
ffffffffc020021a:	f5a60613          	addi	a2,a2,-166 # ffffffffc0202170 <etext+0x180>
ffffffffc020021e:	04d00593          	li	a1,77
ffffffffc0200222:	00002517          	auipc	a0,0x2
ffffffffc0200226:	f6650513          	addi	a0,a0,-154 # ffffffffc0202188 <etext+0x198>
void print_stackframe(void) {
ffffffffc020022a:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc020022c:	1cc000ef          	jal	ra,ffffffffc02003f8 <__panic>

ffffffffc0200230 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200230:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200232:	00002617          	auipc	a2,0x2
ffffffffc0200236:	f6e60613          	addi	a2,a2,-146 # ffffffffc02021a0 <etext+0x1b0>
ffffffffc020023a:	00002597          	auipc	a1,0x2
ffffffffc020023e:	f8658593          	addi	a1,a1,-122 # ffffffffc02021c0 <etext+0x1d0>
ffffffffc0200242:	00002517          	auipc	a0,0x2
ffffffffc0200246:	f8650513          	addi	a0,a0,-122 # ffffffffc02021c8 <etext+0x1d8>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc020024a:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020024c:	eb3ff0ef          	jal	ra,ffffffffc02000fe <cprintf>
ffffffffc0200250:	00002617          	auipc	a2,0x2
ffffffffc0200254:	f8860613          	addi	a2,a2,-120 # ffffffffc02021d8 <etext+0x1e8>
ffffffffc0200258:	00002597          	auipc	a1,0x2
ffffffffc020025c:	fa858593          	addi	a1,a1,-88 # ffffffffc0202200 <etext+0x210>
ffffffffc0200260:	00002517          	auipc	a0,0x2
ffffffffc0200264:	f6850513          	addi	a0,a0,-152 # ffffffffc02021c8 <etext+0x1d8>
ffffffffc0200268:	e97ff0ef          	jal	ra,ffffffffc02000fe <cprintf>
ffffffffc020026c:	00002617          	auipc	a2,0x2
ffffffffc0200270:	fa460613          	addi	a2,a2,-92 # ffffffffc0202210 <etext+0x220>
ffffffffc0200274:	00002597          	auipc	a1,0x2
ffffffffc0200278:	fbc58593          	addi	a1,a1,-68 # ffffffffc0202230 <etext+0x240>
ffffffffc020027c:	00002517          	auipc	a0,0x2
ffffffffc0200280:	f4c50513          	addi	a0,a0,-180 # ffffffffc02021c8 <etext+0x1d8>
ffffffffc0200284:	e7bff0ef          	jal	ra,ffffffffc02000fe <cprintf>
    }
    return 0;
}
ffffffffc0200288:	60a2                	ld	ra,8(sp)
ffffffffc020028a:	4501                	li	a0,0
ffffffffc020028c:	0141                	addi	sp,sp,16
ffffffffc020028e:	8082                	ret

ffffffffc0200290 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200290:	1141                	addi	sp,sp,-16
ffffffffc0200292:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc0200294:	ef3ff0ef          	jal	ra,ffffffffc0200186 <print_kerninfo>
    return 0;
}
ffffffffc0200298:	60a2                	ld	ra,8(sp)
ffffffffc020029a:	4501                	li	a0,0
ffffffffc020029c:	0141                	addi	sp,sp,16
ffffffffc020029e:	8082                	ret

ffffffffc02002a0 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002a0:	1141                	addi	sp,sp,-16
ffffffffc02002a2:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc02002a4:	f71ff0ef          	jal	ra,ffffffffc0200214 <print_stackframe>
    return 0;
}
ffffffffc02002a8:	60a2                	ld	ra,8(sp)
ffffffffc02002aa:	4501                	li	a0,0
ffffffffc02002ac:	0141                	addi	sp,sp,16
ffffffffc02002ae:	8082                	ret

ffffffffc02002b0 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc02002b0:	7115                	addi	sp,sp,-224
ffffffffc02002b2:	ed5e                	sd	s7,152(sp)
ffffffffc02002b4:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002b6:	00002517          	auipc	a0,0x2
ffffffffc02002ba:	f8a50513          	addi	a0,a0,-118 # ffffffffc0202240 <etext+0x250>
kmonitor(struct trapframe *tf) {
ffffffffc02002be:	ed86                	sd	ra,216(sp)
ffffffffc02002c0:	e9a2                	sd	s0,208(sp)
ffffffffc02002c2:	e5a6                	sd	s1,200(sp)
ffffffffc02002c4:	e1ca                	sd	s2,192(sp)
ffffffffc02002c6:	fd4e                	sd	s3,184(sp)
ffffffffc02002c8:	f952                	sd	s4,176(sp)
ffffffffc02002ca:	f556                	sd	s5,168(sp)
ffffffffc02002cc:	f15a                	sd	s6,160(sp)
ffffffffc02002ce:	e962                	sd	s8,144(sp)
ffffffffc02002d0:	e566                	sd	s9,136(sp)
ffffffffc02002d2:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002d4:	e2bff0ef          	jal	ra,ffffffffc02000fe <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc02002d8:	00002517          	auipc	a0,0x2
ffffffffc02002dc:	f9050513          	addi	a0,a0,-112 # ffffffffc0202268 <etext+0x278>
ffffffffc02002e0:	e1fff0ef          	jal	ra,ffffffffc02000fe <cprintf>
    if (tf != NULL) {
ffffffffc02002e4:	000b8563          	beqz	s7,ffffffffc02002ee <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc02002e8:	855e                	mv	a0,s7
ffffffffc02002ea:	756000ef          	jal	ra,ffffffffc0200a40 <print_trapframe>
ffffffffc02002ee:	00002c17          	auipc	s8,0x2
ffffffffc02002f2:	feac0c13          	addi	s8,s8,-22 # ffffffffc02022d8 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002f6:	00002917          	auipc	s2,0x2
ffffffffc02002fa:	f9a90913          	addi	s2,s2,-102 # ffffffffc0202290 <etext+0x2a0>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002fe:	00002497          	auipc	s1,0x2
ffffffffc0200302:	f9a48493          	addi	s1,s1,-102 # ffffffffc0202298 <etext+0x2a8>
        if (argc == MAXARGS - 1) {
ffffffffc0200306:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200308:	00002b17          	auipc	s6,0x2
ffffffffc020030c:	f98b0b13          	addi	s6,s6,-104 # ffffffffc02022a0 <etext+0x2b0>
        argv[argc ++] = buf;
ffffffffc0200310:	00002a17          	auipc	s4,0x2
ffffffffc0200314:	eb0a0a13          	addi	s4,s4,-336 # ffffffffc02021c0 <etext+0x1d0>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200318:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc020031a:	854a                	mv	a0,s2
ffffffffc020031c:	315010ef          	jal	ra,ffffffffc0201e30 <readline>
ffffffffc0200320:	842a                	mv	s0,a0
ffffffffc0200322:	dd65                	beqz	a0,ffffffffc020031a <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200324:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc0200328:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020032a:	e1bd                	bnez	a1,ffffffffc0200390 <kmonitor+0xe0>
    if (argc == 0) {
ffffffffc020032c:	fe0c87e3          	beqz	s9,ffffffffc020031a <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200330:	6582                	ld	a1,0(sp)
ffffffffc0200332:	00002d17          	auipc	s10,0x2
ffffffffc0200336:	fa6d0d13          	addi	s10,s10,-90 # ffffffffc02022d8 <commands>
        argv[argc ++] = buf;
ffffffffc020033a:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020033c:	4401                	li	s0,0
ffffffffc020033e:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200340:	445010ef          	jal	ra,ffffffffc0201f84 <strcmp>
ffffffffc0200344:	c919                	beqz	a0,ffffffffc020035a <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200346:	2405                	addiw	s0,s0,1
ffffffffc0200348:	0b540063          	beq	s0,s5,ffffffffc02003e8 <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020034c:	000d3503          	ld	a0,0(s10)
ffffffffc0200350:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200352:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200354:	431010ef          	jal	ra,ffffffffc0201f84 <strcmp>
ffffffffc0200358:	f57d                	bnez	a0,ffffffffc0200346 <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc020035a:	00141793          	slli	a5,s0,0x1
ffffffffc020035e:	97a2                	add	a5,a5,s0
ffffffffc0200360:	078e                	slli	a5,a5,0x3
ffffffffc0200362:	97e2                	add	a5,a5,s8
ffffffffc0200364:	6b9c                	ld	a5,16(a5)
ffffffffc0200366:	865e                	mv	a2,s7
ffffffffc0200368:	002c                	addi	a1,sp,8
ffffffffc020036a:	fffc851b          	addiw	a0,s9,-1
ffffffffc020036e:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc0200370:	fa0555e3          	bgez	a0,ffffffffc020031a <kmonitor+0x6a>
}
ffffffffc0200374:	60ee                	ld	ra,216(sp)
ffffffffc0200376:	644e                	ld	s0,208(sp)
ffffffffc0200378:	64ae                	ld	s1,200(sp)
ffffffffc020037a:	690e                	ld	s2,192(sp)
ffffffffc020037c:	79ea                	ld	s3,184(sp)
ffffffffc020037e:	7a4a                	ld	s4,176(sp)
ffffffffc0200380:	7aaa                	ld	s5,168(sp)
ffffffffc0200382:	7b0a                	ld	s6,160(sp)
ffffffffc0200384:	6bea                	ld	s7,152(sp)
ffffffffc0200386:	6c4a                	ld	s8,144(sp)
ffffffffc0200388:	6caa                	ld	s9,136(sp)
ffffffffc020038a:	6d0a                	ld	s10,128(sp)
ffffffffc020038c:	612d                	addi	sp,sp,224
ffffffffc020038e:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200390:	8526                	mv	a0,s1
ffffffffc0200392:	437010ef          	jal	ra,ffffffffc0201fc8 <strchr>
ffffffffc0200396:	c901                	beqz	a0,ffffffffc02003a6 <kmonitor+0xf6>
ffffffffc0200398:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc020039c:	00040023          	sb	zero,0(s0)
ffffffffc02003a0:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003a2:	d5c9                	beqz	a1,ffffffffc020032c <kmonitor+0x7c>
ffffffffc02003a4:	b7f5                	j	ffffffffc0200390 <kmonitor+0xe0>
        if (*buf == '\0') {
ffffffffc02003a6:	00044783          	lbu	a5,0(s0)
ffffffffc02003aa:	d3c9                	beqz	a5,ffffffffc020032c <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc02003ac:	033c8963          	beq	s9,s3,ffffffffc02003de <kmonitor+0x12e>
        argv[argc ++] = buf;
ffffffffc02003b0:	003c9793          	slli	a5,s9,0x3
ffffffffc02003b4:	0118                	addi	a4,sp,128
ffffffffc02003b6:	97ba                	add	a5,a5,a4
ffffffffc02003b8:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003bc:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc02003c0:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003c2:	e591                	bnez	a1,ffffffffc02003ce <kmonitor+0x11e>
ffffffffc02003c4:	b7b5                	j	ffffffffc0200330 <kmonitor+0x80>
ffffffffc02003c6:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc02003ca:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003cc:	d1a5                	beqz	a1,ffffffffc020032c <kmonitor+0x7c>
ffffffffc02003ce:	8526                	mv	a0,s1
ffffffffc02003d0:	3f9010ef          	jal	ra,ffffffffc0201fc8 <strchr>
ffffffffc02003d4:	d96d                	beqz	a0,ffffffffc02003c6 <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003d6:	00044583          	lbu	a1,0(s0)
ffffffffc02003da:	d9a9                	beqz	a1,ffffffffc020032c <kmonitor+0x7c>
ffffffffc02003dc:	bf55                	j	ffffffffc0200390 <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02003de:	45c1                	li	a1,16
ffffffffc02003e0:	855a                	mv	a0,s6
ffffffffc02003e2:	d1dff0ef          	jal	ra,ffffffffc02000fe <cprintf>
ffffffffc02003e6:	b7e9                	j	ffffffffc02003b0 <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02003e8:	6582                	ld	a1,0(sp)
ffffffffc02003ea:	00002517          	auipc	a0,0x2
ffffffffc02003ee:	ed650513          	addi	a0,a0,-298 # ffffffffc02022c0 <etext+0x2d0>
ffffffffc02003f2:	d0dff0ef          	jal	ra,ffffffffc02000fe <cprintf>
    return 0;
ffffffffc02003f6:	b715                	j	ffffffffc020031a <kmonitor+0x6a>

ffffffffc02003f8 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02003f8:	00007317          	auipc	t1,0x7
ffffffffc02003fc:	04830313          	addi	t1,t1,72 # ffffffffc0207440 <is_panic>
ffffffffc0200400:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc0200404:	715d                	addi	sp,sp,-80
ffffffffc0200406:	ec06                	sd	ra,24(sp)
ffffffffc0200408:	e822                	sd	s0,16(sp)
ffffffffc020040a:	f436                	sd	a3,40(sp)
ffffffffc020040c:	f83a                	sd	a4,48(sp)
ffffffffc020040e:	fc3e                	sd	a5,56(sp)
ffffffffc0200410:	e0c2                	sd	a6,64(sp)
ffffffffc0200412:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc0200414:	020e1a63          	bnez	t3,ffffffffc0200448 <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc0200418:	4785                	li	a5,1
ffffffffc020041a:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc020041e:	8432                	mv	s0,a2
ffffffffc0200420:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200422:	862e                	mv	a2,a1
ffffffffc0200424:	85aa                	mv	a1,a0
ffffffffc0200426:	00002517          	auipc	a0,0x2
ffffffffc020042a:	efa50513          	addi	a0,a0,-262 # ffffffffc0202320 <commands+0x48>
    va_start(ap, fmt);
ffffffffc020042e:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200430:	ccfff0ef          	jal	ra,ffffffffc02000fe <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200434:	65a2                	ld	a1,8(sp)
ffffffffc0200436:	8522                	mv	a0,s0
ffffffffc0200438:	ca7ff0ef          	jal	ra,ffffffffc02000de <vcprintf>
    cprintf("\n");
ffffffffc020043c:	00002517          	auipc	a0,0x2
ffffffffc0200440:	be450513          	addi	a0,a0,-1052 # ffffffffc0202020 <etext+0x30>
ffffffffc0200444:	cbbff0ef          	jal	ra,ffffffffc02000fe <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc0200448:	412000ef          	jal	ra,ffffffffc020085a <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc020044c:	4501                	li	a0,0
ffffffffc020044e:	e63ff0ef          	jal	ra,ffffffffc02002b0 <kmonitor>
    while (1) {
ffffffffc0200452:	bfed                	j	ffffffffc020044c <__panic+0x54>

ffffffffc0200454 <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc0200454:	1141                	addi	sp,sp,-16
ffffffffc0200456:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
ffffffffc0200458:	02000793          	li	a5,32
ffffffffc020045c:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200460:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200464:	67e1                	lui	a5,0x18
ffffffffc0200466:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc020046a:	953e                	add	a0,a0,a5
ffffffffc020046c:	293010ef          	jal	ra,ffffffffc0201efe <sbi_set_timer>
}
ffffffffc0200470:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc0200472:	00007797          	auipc	a5,0x7
ffffffffc0200476:	fc07bb23          	sd	zero,-42(a5) # ffffffffc0207448 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020047a:	00002517          	auipc	a0,0x2
ffffffffc020047e:	ec650513          	addi	a0,a0,-314 # ffffffffc0202340 <commands+0x68>
}
ffffffffc0200482:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc0200484:	b9ad                	j	ffffffffc02000fe <cprintf>

ffffffffc0200486 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200486:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020048a:	67e1                	lui	a5,0x18
ffffffffc020048c:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc0200490:	953e                	add	a0,a0,a5
ffffffffc0200492:	26d0106f          	j	ffffffffc0201efe <sbi_set_timer>

ffffffffc0200496 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200496:	8082                	ret

ffffffffc0200498 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200498:	0ff57513          	zext.b	a0,a0
ffffffffc020049c:	2490106f          	j	ffffffffc0201ee4 <sbi_console_putchar>

ffffffffc02004a0 <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc02004a0:	2790106f          	j	ffffffffc0201f18 <sbi_console_getchar>

ffffffffc02004a4 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc02004a4:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc02004a6:	00002517          	auipc	a0,0x2
ffffffffc02004aa:	eba50513          	addi	a0,a0,-326 # ffffffffc0202360 <commands+0x88>
void dtb_init(void) {
ffffffffc02004ae:	fc86                	sd	ra,120(sp)
ffffffffc02004b0:	f8a2                	sd	s0,112(sp)
ffffffffc02004b2:	e8d2                	sd	s4,80(sp)
ffffffffc02004b4:	f4a6                	sd	s1,104(sp)
ffffffffc02004b6:	f0ca                	sd	s2,96(sp)
ffffffffc02004b8:	ecce                	sd	s3,88(sp)
ffffffffc02004ba:	e4d6                	sd	s5,72(sp)
ffffffffc02004bc:	e0da                	sd	s6,64(sp)
ffffffffc02004be:	fc5e                	sd	s7,56(sp)
ffffffffc02004c0:	f862                	sd	s8,48(sp)
ffffffffc02004c2:	f466                	sd	s9,40(sp)
ffffffffc02004c4:	f06a                	sd	s10,32(sp)
ffffffffc02004c6:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc02004c8:	c37ff0ef          	jal	ra,ffffffffc02000fe <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02004cc:	00007597          	auipc	a1,0x7
ffffffffc02004d0:	b345b583          	ld	a1,-1228(a1) # ffffffffc0207000 <boot_hartid>
ffffffffc02004d4:	00002517          	auipc	a0,0x2
ffffffffc02004d8:	e9c50513          	addi	a0,a0,-356 # ffffffffc0202370 <commands+0x98>
ffffffffc02004dc:	c23ff0ef          	jal	ra,ffffffffc02000fe <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02004e0:	00007417          	auipc	s0,0x7
ffffffffc02004e4:	b2840413          	addi	s0,s0,-1240 # ffffffffc0207008 <boot_dtb>
ffffffffc02004e8:	600c                	ld	a1,0(s0)
ffffffffc02004ea:	00002517          	auipc	a0,0x2
ffffffffc02004ee:	e9650513          	addi	a0,a0,-362 # ffffffffc0202380 <commands+0xa8>
ffffffffc02004f2:	c0dff0ef          	jal	ra,ffffffffc02000fe <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc02004f6:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc02004fa:	00002517          	auipc	a0,0x2
ffffffffc02004fe:	e9e50513          	addi	a0,a0,-354 # ffffffffc0202398 <commands+0xc0>
    if (boot_dtb == 0) {
ffffffffc0200502:	120a0463          	beqz	s4,ffffffffc020062a <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200506:	57f5                	li	a5,-3
ffffffffc0200508:	07fa                	slli	a5,a5,0x1e
ffffffffc020050a:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc020050e:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200510:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200514:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200516:	0087d59b          	srliw	a1,a5,0x8
ffffffffc020051a:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020051e:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200522:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200526:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020052a:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020052c:	8ec9                	or	a3,a3,a0
ffffffffc020052e:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200532:	1b7d                	addi	s6,s6,-1
ffffffffc0200534:	0167f7b3          	and	a5,a5,s6
ffffffffc0200538:	8dd5                	or	a1,a1,a3
ffffffffc020053a:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc020053c:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200540:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc0200542:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed8a4d>
ffffffffc0200546:	10f59163          	bne	a1,a5,ffffffffc0200648 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc020054a:	471c                	lw	a5,8(a4)
ffffffffc020054c:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc020054e:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200550:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200554:	0086d51b          	srliw	a0,a3,0x8
ffffffffc0200558:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020055c:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200560:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200564:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200568:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020056c:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200570:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200574:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200578:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020057a:	01146433          	or	s0,s0,a7
ffffffffc020057e:	0086969b          	slliw	a3,a3,0x8
ffffffffc0200582:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200586:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200588:	0087979b          	slliw	a5,a5,0x8
ffffffffc020058c:	8c49                	or	s0,s0,a0
ffffffffc020058e:	0166f6b3          	and	a3,a3,s6
ffffffffc0200592:	00ca6a33          	or	s4,s4,a2
ffffffffc0200596:	0167f7b3          	and	a5,a5,s6
ffffffffc020059a:	8c55                	or	s0,s0,a3
ffffffffc020059c:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02005a0:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02005a2:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02005a4:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02005a6:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02005aa:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02005ac:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005ae:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc02005b2:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02005b4:	00002917          	auipc	s2,0x2
ffffffffc02005b8:	e3490913          	addi	s2,s2,-460 # ffffffffc02023e8 <commands+0x110>
ffffffffc02005bc:	49bd                	li	s3,15
        switch (token) {
ffffffffc02005be:	4d91                	li	s11,4
ffffffffc02005c0:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02005c2:	00002497          	auipc	s1,0x2
ffffffffc02005c6:	e1e48493          	addi	s1,s1,-482 # ffffffffc02023e0 <commands+0x108>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc02005ca:	000a2703          	lw	a4,0(s4)
ffffffffc02005ce:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005d2:	0087569b          	srliw	a3,a4,0x8
ffffffffc02005d6:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005da:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005de:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005e2:	0107571b          	srliw	a4,a4,0x10
ffffffffc02005e6:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005e8:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005ec:	0087171b          	slliw	a4,a4,0x8
ffffffffc02005f0:	8fd5                	or	a5,a5,a3
ffffffffc02005f2:	00eb7733          	and	a4,s6,a4
ffffffffc02005f6:	8fd9                	or	a5,a5,a4
ffffffffc02005f8:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc02005fa:	09778c63          	beq	a5,s7,ffffffffc0200692 <dtb_init+0x1ee>
ffffffffc02005fe:	00fbea63          	bltu	s7,a5,ffffffffc0200612 <dtb_init+0x16e>
ffffffffc0200602:	07a78663          	beq	a5,s10,ffffffffc020066e <dtb_init+0x1ca>
ffffffffc0200606:	4709                	li	a4,2
ffffffffc0200608:	00e79763          	bne	a5,a4,ffffffffc0200616 <dtb_init+0x172>
ffffffffc020060c:	4c81                	li	s9,0
ffffffffc020060e:	8a56                	mv	s4,s5
ffffffffc0200610:	bf6d                	j	ffffffffc02005ca <dtb_init+0x126>
ffffffffc0200612:	ffb78ee3          	beq	a5,s11,ffffffffc020060e <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200616:	00002517          	auipc	a0,0x2
ffffffffc020061a:	e4a50513          	addi	a0,a0,-438 # ffffffffc0202460 <commands+0x188>
ffffffffc020061e:	ae1ff0ef          	jal	ra,ffffffffc02000fe <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200622:	00002517          	auipc	a0,0x2
ffffffffc0200626:	e7650513          	addi	a0,a0,-394 # ffffffffc0202498 <commands+0x1c0>
}
ffffffffc020062a:	7446                	ld	s0,112(sp)
ffffffffc020062c:	70e6                	ld	ra,120(sp)
ffffffffc020062e:	74a6                	ld	s1,104(sp)
ffffffffc0200630:	7906                	ld	s2,96(sp)
ffffffffc0200632:	69e6                	ld	s3,88(sp)
ffffffffc0200634:	6a46                	ld	s4,80(sp)
ffffffffc0200636:	6aa6                	ld	s5,72(sp)
ffffffffc0200638:	6b06                	ld	s6,64(sp)
ffffffffc020063a:	7be2                	ld	s7,56(sp)
ffffffffc020063c:	7c42                	ld	s8,48(sp)
ffffffffc020063e:	7ca2                	ld	s9,40(sp)
ffffffffc0200640:	7d02                	ld	s10,32(sp)
ffffffffc0200642:	6de2                	ld	s11,24(sp)
ffffffffc0200644:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc0200646:	bc65                	j	ffffffffc02000fe <cprintf>
}
ffffffffc0200648:	7446                	ld	s0,112(sp)
ffffffffc020064a:	70e6                	ld	ra,120(sp)
ffffffffc020064c:	74a6                	ld	s1,104(sp)
ffffffffc020064e:	7906                	ld	s2,96(sp)
ffffffffc0200650:	69e6                	ld	s3,88(sp)
ffffffffc0200652:	6a46                	ld	s4,80(sp)
ffffffffc0200654:	6aa6                	ld	s5,72(sp)
ffffffffc0200656:	6b06                	ld	s6,64(sp)
ffffffffc0200658:	7be2                	ld	s7,56(sp)
ffffffffc020065a:	7c42                	ld	s8,48(sp)
ffffffffc020065c:	7ca2                	ld	s9,40(sp)
ffffffffc020065e:	7d02                	ld	s10,32(sp)
ffffffffc0200660:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200662:	00002517          	auipc	a0,0x2
ffffffffc0200666:	d5650513          	addi	a0,a0,-682 # ffffffffc02023b8 <commands+0xe0>
}
ffffffffc020066a:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc020066c:	bc49                	j	ffffffffc02000fe <cprintf>
                int name_len = strlen(name);
ffffffffc020066e:	8556                	mv	a0,s5
ffffffffc0200670:	0df010ef          	jal	ra,ffffffffc0201f4e <strlen>
ffffffffc0200674:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200676:	4619                	li	a2,6
ffffffffc0200678:	85a6                	mv	a1,s1
ffffffffc020067a:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc020067c:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020067e:	125010ef          	jal	ra,ffffffffc0201fa2 <strncmp>
ffffffffc0200682:	e111                	bnez	a0,ffffffffc0200686 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc0200684:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200686:	0a91                	addi	s5,s5,4
ffffffffc0200688:	9ad2                	add	s5,s5,s4
ffffffffc020068a:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc020068e:	8a56                	mv	s4,s5
ffffffffc0200690:	bf2d                	j	ffffffffc02005ca <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200692:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200696:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020069a:	0087d71b          	srliw	a4,a5,0x8
ffffffffc020069e:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006a2:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006a6:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006aa:	0107d79b          	srliw	a5,a5,0x10
ffffffffc02006ae:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006b2:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b6:	0087979b          	slliw	a5,a5,0x8
ffffffffc02006ba:	00eaeab3          	or	s5,s5,a4
ffffffffc02006be:	00fb77b3          	and	a5,s6,a5
ffffffffc02006c2:	00faeab3          	or	s5,s5,a5
ffffffffc02006c6:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006c8:	000c9c63          	bnez	s9,ffffffffc02006e0 <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc02006cc:	1a82                	slli	s5,s5,0x20
ffffffffc02006ce:	00368793          	addi	a5,a3,3
ffffffffc02006d2:	020ada93          	srli	s5,s5,0x20
ffffffffc02006d6:	9abe                	add	s5,s5,a5
ffffffffc02006d8:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02006dc:	8a56                	mv	s4,s5
ffffffffc02006de:	b5f5                	j	ffffffffc02005ca <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006e0:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006e4:	85ca                	mv	a1,s2
ffffffffc02006e6:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006e8:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006ec:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006f0:	0187971b          	slliw	a4,a5,0x18
ffffffffc02006f4:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006f8:	0107d79b          	srliw	a5,a5,0x10
ffffffffc02006fc:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006fe:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200702:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200706:	8d59                	or	a0,a0,a4
ffffffffc0200708:	00fb77b3          	and	a5,s6,a5
ffffffffc020070c:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc020070e:	1502                	slli	a0,a0,0x20
ffffffffc0200710:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200712:	9522                	add	a0,a0,s0
ffffffffc0200714:	071010ef          	jal	ra,ffffffffc0201f84 <strcmp>
ffffffffc0200718:	66a2                	ld	a3,8(sp)
ffffffffc020071a:	f94d                	bnez	a0,ffffffffc02006cc <dtb_init+0x228>
ffffffffc020071c:	fb59f8e3          	bgeu	s3,s5,ffffffffc02006cc <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc0200720:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc0200724:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200728:	00002517          	auipc	a0,0x2
ffffffffc020072c:	cc850513          	addi	a0,a0,-824 # ffffffffc02023f0 <commands+0x118>
           fdt32_to_cpu(x >> 32);
ffffffffc0200730:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200734:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc0200738:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020073c:	0187de1b          	srliw	t3,a5,0x18
ffffffffc0200740:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200744:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200748:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020074c:	0187d693          	srli	a3,a5,0x18
ffffffffc0200750:	01861f1b          	slliw	t5,a2,0x18
ffffffffc0200754:	0087579b          	srliw	a5,a4,0x8
ffffffffc0200758:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020075c:	0106561b          	srliw	a2,a2,0x10
ffffffffc0200760:	010f6f33          	or	t5,t5,a6
ffffffffc0200764:	0187529b          	srliw	t0,a4,0x18
ffffffffc0200768:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020076c:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200770:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200774:	0186f6b3          	and	a3,a3,s8
ffffffffc0200778:	01859e1b          	slliw	t3,a1,0x18
ffffffffc020077c:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200780:	0107581b          	srliw	a6,a4,0x10
ffffffffc0200784:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200788:	8361                	srli	a4,a4,0x18
ffffffffc020078a:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020078e:	0105d59b          	srliw	a1,a1,0x10
ffffffffc0200792:	01e6e6b3          	or	a3,a3,t5
ffffffffc0200796:	00cb7633          	and	a2,s6,a2
ffffffffc020079a:	0088181b          	slliw	a6,a6,0x8
ffffffffc020079e:	0085959b          	slliw	a1,a1,0x8
ffffffffc02007a2:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007a6:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007aa:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007ae:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007b2:	0088989b          	slliw	a7,a7,0x8
ffffffffc02007b6:	011b78b3          	and	a7,s6,a7
ffffffffc02007ba:	005eeeb3          	or	t4,t4,t0
ffffffffc02007be:	00c6e733          	or	a4,a3,a2
ffffffffc02007c2:	006c6c33          	or	s8,s8,t1
ffffffffc02007c6:	010b76b3          	and	a3,s6,a6
ffffffffc02007ca:	00bb7b33          	and	s6,s6,a1
ffffffffc02007ce:	01d7e7b3          	or	a5,a5,t4
ffffffffc02007d2:	016c6b33          	or	s6,s8,s6
ffffffffc02007d6:	01146433          	or	s0,s0,a7
ffffffffc02007da:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc02007dc:	1702                	slli	a4,a4,0x20
ffffffffc02007de:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007e0:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02007e2:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007e4:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02007e6:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007ea:	0167eb33          	or	s6,a5,s6
ffffffffc02007ee:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc02007f0:	90fff0ef          	jal	ra,ffffffffc02000fe <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc02007f4:	85a2                	mv	a1,s0
ffffffffc02007f6:	00002517          	auipc	a0,0x2
ffffffffc02007fa:	c1a50513          	addi	a0,a0,-998 # ffffffffc0202410 <commands+0x138>
ffffffffc02007fe:	901ff0ef          	jal	ra,ffffffffc02000fe <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200802:	014b5613          	srli	a2,s6,0x14
ffffffffc0200806:	85da                	mv	a1,s6
ffffffffc0200808:	00002517          	auipc	a0,0x2
ffffffffc020080c:	c2050513          	addi	a0,a0,-992 # ffffffffc0202428 <commands+0x150>
ffffffffc0200810:	8efff0ef          	jal	ra,ffffffffc02000fe <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200814:	008b05b3          	add	a1,s6,s0
ffffffffc0200818:	15fd                	addi	a1,a1,-1
ffffffffc020081a:	00002517          	auipc	a0,0x2
ffffffffc020081e:	c2e50513          	addi	a0,a0,-978 # ffffffffc0202448 <commands+0x170>
ffffffffc0200822:	8ddff0ef          	jal	ra,ffffffffc02000fe <cprintf>
    cprintf("DTB init completed\n");
ffffffffc0200826:	00002517          	auipc	a0,0x2
ffffffffc020082a:	c7250513          	addi	a0,a0,-910 # ffffffffc0202498 <commands+0x1c0>
        memory_base = mem_base;
ffffffffc020082e:	00007797          	auipc	a5,0x7
ffffffffc0200832:	c287b123          	sd	s0,-990(a5) # ffffffffc0207450 <memory_base>
        memory_size = mem_size;
ffffffffc0200836:	00007797          	auipc	a5,0x7
ffffffffc020083a:	c367b123          	sd	s6,-990(a5) # ffffffffc0207458 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc020083e:	b3f5                	j	ffffffffc020062a <dtb_init+0x186>

ffffffffc0200840 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc0200840:	00007517          	auipc	a0,0x7
ffffffffc0200844:	c1053503          	ld	a0,-1008(a0) # ffffffffc0207450 <memory_base>
ffffffffc0200848:	8082                	ret

ffffffffc020084a <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc020084a:	00007517          	auipc	a0,0x7
ffffffffc020084e:	c0e53503          	ld	a0,-1010(a0) # ffffffffc0207458 <memory_size>
ffffffffc0200852:	8082                	ret

ffffffffc0200854 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200854:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200858:	8082                	ret

ffffffffc020085a <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc020085a:	100177f3          	csrrci	a5,sstatus,2
ffffffffc020085e:	8082                	ret

ffffffffc0200860 <idt_init>:
#endif
}

void idt_init(void) {
    extern void __alltraps(void);
    write_csr(sscratch, 0);
ffffffffc0200860:	14005073          	csrwi	sscratch,0
    write_csr(stvec, &__alltraps);
ffffffffc0200864:	00000797          	auipc	a5,0x0
ffffffffc0200868:	3b878793          	addi	a5,a5,952 # ffffffffc0200c1c <__alltraps>
ffffffffc020086c:	10579073          	csrw	stvec,a5
}
ffffffffc0200870:	8082                	ret

ffffffffc0200872 <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200872:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc0200874:	1141                	addi	sp,sp,-16
ffffffffc0200876:	e022                	sd	s0,0(sp)
ffffffffc0200878:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020087a:	00002517          	auipc	a0,0x2
ffffffffc020087e:	c3650513          	addi	a0,a0,-970 # ffffffffc02024b0 <commands+0x1d8>
void print_regs(struct pushregs *gpr) {
ffffffffc0200882:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200884:	87bff0ef          	jal	ra,ffffffffc02000fe <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200888:	640c                	ld	a1,8(s0)
ffffffffc020088a:	00002517          	auipc	a0,0x2
ffffffffc020088e:	c3e50513          	addi	a0,a0,-962 # ffffffffc02024c8 <commands+0x1f0>
ffffffffc0200892:	86dff0ef          	jal	ra,ffffffffc02000fe <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200896:	680c                	ld	a1,16(s0)
ffffffffc0200898:	00002517          	auipc	a0,0x2
ffffffffc020089c:	c4850513          	addi	a0,a0,-952 # ffffffffc02024e0 <commands+0x208>
ffffffffc02008a0:	85fff0ef          	jal	ra,ffffffffc02000fe <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02008a4:	6c0c                	ld	a1,24(s0)
ffffffffc02008a6:	00002517          	auipc	a0,0x2
ffffffffc02008aa:	c5250513          	addi	a0,a0,-942 # ffffffffc02024f8 <commands+0x220>
ffffffffc02008ae:	851ff0ef          	jal	ra,ffffffffc02000fe <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02008b2:	700c                	ld	a1,32(s0)
ffffffffc02008b4:	00002517          	auipc	a0,0x2
ffffffffc02008b8:	c5c50513          	addi	a0,a0,-932 # ffffffffc0202510 <commands+0x238>
ffffffffc02008bc:	843ff0ef          	jal	ra,ffffffffc02000fe <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02008c0:	740c                	ld	a1,40(s0)
ffffffffc02008c2:	00002517          	auipc	a0,0x2
ffffffffc02008c6:	c6650513          	addi	a0,a0,-922 # ffffffffc0202528 <commands+0x250>
ffffffffc02008ca:	835ff0ef          	jal	ra,ffffffffc02000fe <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02008ce:	780c                	ld	a1,48(s0)
ffffffffc02008d0:	00002517          	auipc	a0,0x2
ffffffffc02008d4:	c7050513          	addi	a0,a0,-912 # ffffffffc0202540 <commands+0x268>
ffffffffc02008d8:	827ff0ef          	jal	ra,ffffffffc02000fe <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02008dc:	7c0c                	ld	a1,56(s0)
ffffffffc02008de:	00002517          	auipc	a0,0x2
ffffffffc02008e2:	c7a50513          	addi	a0,a0,-902 # ffffffffc0202558 <commands+0x280>
ffffffffc02008e6:	819ff0ef          	jal	ra,ffffffffc02000fe <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02008ea:	602c                	ld	a1,64(s0)
ffffffffc02008ec:	00002517          	auipc	a0,0x2
ffffffffc02008f0:	c8450513          	addi	a0,a0,-892 # ffffffffc0202570 <commands+0x298>
ffffffffc02008f4:	80bff0ef          	jal	ra,ffffffffc02000fe <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02008f8:	642c                	ld	a1,72(s0)
ffffffffc02008fa:	00002517          	auipc	a0,0x2
ffffffffc02008fe:	c8e50513          	addi	a0,a0,-882 # ffffffffc0202588 <commands+0x2b0>
ffffffffc0200902:	ffcff0ef          	jal	ra,ffffffffc02000fe <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200906:	682c                	ld	a1,80(s0)
ffffffffc0200908:	00002517          	auipc	a0,0x2
ffffffffc020090c:	c9850513          	addi	a0,a0,-872 # ffffffffc02025a0 <commands+0x2c8>
ffffffffc0200910:	feeff0ef          	jal	ra,ffffffffc02000fe <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200914:	6c2c                	ld	a1,88(s0)
ffffffffc0200916:	00002517          	auipc	a0,0x2
ffffffffc020091a:	ca250513          	addi	a0,a0,-862 # ffffffffc02025b8 <commands+0x2e0>
ffffffffc020091e:	fe0ff0ef          	jal	ra,ffffffffc02000fe <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200922:	702c                	ld	a1,96(s0)
ffffffffc0200924:	00002517          	auipc	a0,0x2
ffffffffc0200928:	cac50513          	addi	a0,a0,-852 # ffffffffc02025d0 <commands+0x2f8>
ffffffffc020092c:	fd2ff0ef          	jal	ra,ffffffffc02000fe <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200930:	742c                	ld	a1,104(s0)
ffffffffc0200932:	00002517          	auipc	a0,0x2
ffffffffc0200936:	cb650513          	addi	a0,a0,-842 # ffffffffc02025e8 <commands+0x310>
ffffffffc020093a:	fc4ff0ef          	jal	ra,ffffffffc02000fe <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc020093e:	782c                	ld	a1,112(s0)
ffffffffc0200940:	00002517          	auipc	a0,0x2
ffffffffc0200944:	cc050513          	addi	a0,a0,-832 # ffffffffc0202600 <commands+0x328>
ffffffffc0200948:	fb6ff0ef          	jal	ra,ffffffffc02000fe <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc020094c:	7c2c                	ld	a1,120(s0)
ffffffffc020094e:	00002517          	auipc	a0,0x2
ffffffffc0200952:	cca50513          	addi	a0,a0,-822 # ffffffffc0202618 <commands+0x340>
ffffffffc0200956:	fa8ff0ef          	jal	ra,ffffffffc02000fe <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc020095a:	604c                	ld	a1,128(s0)
ffffffffc020095c:	00002517          	auipc	a0,0x2
ffffffffc0200960:	cd450513          	addi	a0,a0,-812 # ffffffffc0202630 <commands+0x358>
ffffffffc0200964:	f9aff0ef          	jal	ra,ffffffffc02000fe <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200968:	644c                	ld	a1,136(s0)
ffffffffc020096a:	00002517          	auipc	a0,0x2
ffffffffc020096e:	cde50513          	addi	a0,a0,-802 # ffffffffc0202648 <commands+0x370>
ffffffffc0200972:	f8cff0ef          	jal	ra,ffffffffc02000fe <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200976:	684c                	ld	a1,144(s0)
ffffffffc0200978:	00002517          	auipc	a0,0x2
ffffffffc020097c:	ce850513          	addi	a0,a0,-792 # ffffffffc0202660 <commands+0x388>
ffffffffc0200980:	f7eff0ef          	jal	ra,ffffffffc02000fe <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200984:	6c4c                	ld	a1,152(s0)
ffffffffc0200986:	00002517          	auipc	a0,0x2
ffffffffc020098a:	cf250513          	addi	a0,a0,-782 # ffffffffc0202678 <commands+0x3a0>
ffffffffc020098e:	f70ff0ef          	jal	ra,ffffffffc02000fe <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200992:	704c                	ld	a1,160(s0)
ffffffffc0200994:	00002517          	auipc	a0,0x2
ffffffffc0200998:	cfc50513          	addi	a0,a0,-772 # ffffffffc0202690 <commands+0x3b8>
ffffffffc020099c:	f62ff0ef          	jal	ra,ffffffffc02000fe <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02009a0:	744c                	ld	a1,168(s0)
ffffffffc02009a2:	00002517          	auipc	a0,0x2
ffffffffc02009a6:	d0650513          	addi	a0,a0,-762 # ffffffffc02026a8 <commands+0x3d0>
ffffffffc02009aa:	f54ff0ef          	jal	ra,ffffffffc02000fe <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02009ae:	784c                	ld	a1,176(s0)
ffffffffc02009b0:	00002517          	auipc	a0,0x2
ffffffffc02009b4:	d1050513          	addi	a0,a0,-752 # ffffffffc02026c0 <commands+0x3e8>
ffffffffc02009b8:	f46ff0ef          	jal	ra,ffffffffc02000fe <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02009bc:	7c4c                	ld	a1,184(s0)
ffffffffc02009be:	00002517          	auipc	a0,0x2
ffffffffc02009c2:	d1a50513          	addi	a0,a0,-742 # ffffffffc02026d8 <commands+0x400>
ffffffffc02009c6:	f38ff0ef          	jal	ra,ffffffffc02000fe <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02009ca:	606c                	ld	a1,192(s0)
ffffffffc02009cc:	00002517          	auipc	a0,0x2
ffffffffc02009d0:	d2450513          	addi	a0,a0,-732 # ffffffffc02026f0 <commands+0x418>
ffffffffc02009d4:	f2aff0ef          	jal	ra,ffffffffc02000fe <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02009d8:	646c                	ld	a1,200(s0)
ffffffffc02009da:	00002517          	auipc	a0,0x2
ffffffffc02009de:	d2e50513          	addi	a0,a0,-722 # ffffffffc0202708 <commands+0x430>
ffffffffc02009e2:	f1cff0ef          	jal	ra,ffffffffc02000fe <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02009e6:	686c                	ld	a1,208(s0)
ffffffffc02009e8:	00002517          	auipc	a0,0x2
ffffffffc02009ec:	d3850513          	addi	a0,a0,-712 # ffffffffc0202720 <commands+0x448>
ffffffffc02009f0:	f0eff0ef          	jal	ra,ffffffffc02000fe <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02009f4:	6c6c                	ld	a1,216(s0)
ffffffffc02009f6:	00002517          	auipc	a0,0x2
ffffffffc02009fa:	d4250513          	addi	a0,a0,-702 # ffffffffc0202738 <commands+0x460>
ffffffffc02009fe:	f00ff0ef          	jal	ra,ffffffffc02000fe <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200a02:	706c                	ld	a1,224(s0)
ffffffffc0200a04:	00002517          	auipc	a0,0x2
ffffffffc0200a08:	d4c50513          	addi	a0,a0,-692 # ffffffffc0202750 <commands+0x478>
ffffffffc0200a0c:	ef2ff0ef          	jal	ra,ffffffffc02000fe <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200a10:	746c                	ld	a1,232(s0)
ffffffffc0200a12:	00002517          	auipc	a0,0x2
ffffffffc0200a16:	d5650513          	addi	a0,a0,-682 # ffffffffc0202768 <commands+0x490>
ffffffffc0200a1a:	ee4ff0ef          	jal	ra,ffffffffc02000fe <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200a1e:	786c                	ld	a1,240(s0)
ffffffffc0200a20:	00002517          	auipc	a0,0x2
ffffffffc0200a24:	d6050513          	addi	a0,a0,-672 # ffffffffc0202780 <commands+0x4a8>
ffffffffc0200a28:	ed6ff0ef          	jal	ra,ffffffffc02000fe <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a2c:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200a2e:	6402                	ld	s0,0(sp)
ffffffffc0200a30:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a32:	00002517          	auipc	a0,0x2
ffffffffc0200a36:	d6650513          	addi	a0,a0,-666 # ffffffffc0202798 <commands+0x4c0>
}
ffffffffc0200a3a:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a3c:	ec2ff06f          	j	ffffffffc02000fe <cprintf>

ffffffffc0200a40 <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a40:	1141                	addi	sp,sp,-16
ffffffffc0200a42:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a44:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a46:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a48:	00002517          	auipc	a0,0x2
ffffffffc0200a4c:	d6850513          	addi	a0,a0,-664 # ffffffffc02027b0 <commands+0x4d8>
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a50:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a52:	eacff0ef          	jal	ra,ffffffffc02000fe <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200a56:	8522                	mv	a0,s0
ffffffffc0200a58:	e1bff0ef          	jal	ra,ffffffffc0200872 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200a5c:	10043583          	ld	a1,256(s0)
ffffffffc0200a60:	00002517          	auipc	a0,0x2
ffffffffc0200a64:	d6850513          	addi	a0,a0,-664 # ffffffffc02027c8 <commands+0x4f0>
ffffffffc0200a68:	e96ff0ef          	jal	ra,ffffffffc02000fe <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200a6c:	10843583          	ld	a1,264(s0)
ffffffffc0200a70:	00002517          	auipc	a0,0x2
ffffffffc0200a74:	d7050513          	addi	a0,a0,-656 # ffffffffc02027e0 <commands+0x508>
ffffffffc0200a78:	e86ff0ef          	jal	ra,ffffffffc02000fe <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200a7c:	11043583          	ld	a1,272(s0)
ffffffffc0200a80:	00002517          	auipc	a0,0x2
ffffffffc0200a84:	d7850513          	addi	a0,a0,-648 # ffffffffc02027f8 <commands+0x520>
ffffffffc0200a88:	e76ff0ef          	jal	ra,ffffffffc02000fe <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a8c:	11843583          	ld	a1,280(s0)
}
ffffffffc0200a90:	6402                	ld	s0,0(sp)
ffffffffc0200a92:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a94:	00002517          	auipc	a0,0x2
ffffffffc0200a98:	d7c50513          	addi	a0,a0,-644 # ffffffffc0202810 <commands+0x538>
}
ffffffffc0200a9c:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a9e:	e60ff06f          	j	ffffffffc02000fe <cprintf>

ffffffffc0200aa2 <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200aa2:	11853783          	ld	a5,280(a0)
ffffffffc0200aa6:	472d                	li	a4,11
ffffffffc0200aa8:	0786                	slli	a5,a5,0x1
ffffffffc0200aaa:	8385                	srli	a5,a5,0x1
ffffffffc0200aac:	08f76363          	bltu	a4,a5,ffffffffc0200b32 <interrupt_handler+0x90>
ffffffffc0200ab0:	00002717          	auipc	a4,0x2
ffffffffc0200ab4:	e6870713          	addi	a4,a4,-408 # ffffffffc0202918 <commands+0x640>
ffffffffc0200ab8:	078a                	slli	a5,a5,0x2
ffffffffc0200aba:	97ba                	add	a5,a5,a4
ffffffffc0200abc:	439c                	lw	a5,0(a5)
ffffffffc0200abe:	97ba                	add	a5,a5,a4
ffffffffc0200ac0:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc0200ac2:	00002517          	auipc	a0,0x2
ffffffffc0200ac6:	dc650513          	addi	a0,a0,-570 # ffffffffc0202888 <commands+0x5b0>
ffffffffc0200aca:	e34ff06f          	j	ffffffffc02000fe <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc0200ace:	00002517          	auipc	a0,0x2
ffffffffc0200ad2:	d9a50513          	addi	a0,a0,-614 # ffffffffc0202868 <commands+0x590>
ffffffffc0200ad6:	e28ff06f          	j	ffffffffc02000fe <cprintf>
            cprintf("User software interrupt\n");
ffffffffc0200ada:	00002517          	auipc	a0,0x2
ffffffffc0200ade:	d4e50513          	addi	a0,a0,-690 # ffffffffc0202828 <commands+0x550>
ffffffffc0200ae2:	e1cff06f          	j	ffffffffc02000fe <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc0200ae6:	00002517          	auipc	a0,0x2
ffffffffc0200aea:	dc250513          	addi	a0,a0,-574 # ffffffffc02028a8 <commands+0x5d0>
ffffffffc0200aee:	e10ff06f          	j	ffffffffc02000fe <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc0200af2:	1141                	addi	sp,sp,-16
ffffffffc0200af4:	e406                	sd	ra,8(sp)
            break;
        case IRQ_S_TIMER:
            // 练习1: 时钟中断处理
            clock_set_next_event();
ffffffffc0200af6:	991ff0ef          	jal	ra,ffffffffc0200486 <clock_set_next_event>
            ticks++;
ffffffffc0200afa:	00007797          	auipc	a5,0x7
ffffffffc0200afe:	94e78793          	addi	a5,a5,-1714 # ffffffffc0207448 <ticks>
ffffffffc0200b02:	6398                	ld	a4,0(a5)
ffffffffc0200b04:	0705                	addi	a4,a4,1
ffffffffc0200b06:	e398                	sd	a4,0(a5)
            
            if (ticks % TICK_NUM == 0) {
ffffffffc0200b08:	639c                	ld	a5,0(a5)
ffffffffc0200b0a:	06400713          	li	a4,100
ffffffffc0200b0e:	02e7f7b3          	remu	a5,a5,a4
ffffffffc0200b12:	c38d                	beqz	a5,ffffffffc0200b34 <interrupt_handler+0x92>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200b14:	60a2                	ld	ra,8(sp)
ffffffffc0200b16:	0141                	addi	sp,sp,16
ffffffffc0200b18:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc0200b1a:	00002517          	auipc	a0,0x2
ffffffffc0200b1e:	dde50513          	addi	a0,a0,-546 # ffffffffc02028f8 <commands+0x620>
ffffffffc0200b22:	ddcff06f          	j	ffffffffc02000fe <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200b26:	00002517          	auipc	a0,0x2
ffffffffc0200b2a:	d2250513          	addi	a0,a0,-734 # ffffffffc0202848 <commands+0x570>
ffffffffc0200b2e:	dd0ff06f          	j	ffffffffc02000fe <cprintf>
            print_trapframe(tf);
ffffffffc0200b32:	b739                	j	ffffffffc0200a40 <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200b34:	06400593          	li	a1,100
ffffffffc0200b38:	00002517          	auipc	a0,0x2
ffffffffc0200b3c:	d8850513          	addi	a0,a0,-632 # ffffffffc02028c0 <commands+0x5e8>
ffffffffc0200b40:	dbeff0ef          	jal	ra,ffffffffc02000fe <cprintf>
                num++;
ffffffffc0200b44:	00007717          	auipc	a4,0x7
ffffffffc0200b48:	91c70713          	addi	a4,a4,-1764 # ffffffffc0207460 <num>
ffffffffc0200b4c:	431c                	lw	a5,0(a4)
                if (num == 10) {
ffffffffc0200b4e:	46a9                	li	a3,10
                num++;
ffffffffc0200b50:	0017861b          	addiw	a2,a5,1
ffffffffc0200b54:	c310                	sw	a2,0(a4)
                if (num == 10) {
ffffffffc0200b56:	fad61fe3          	bne	a2,a3,ffffffffc0200b14 <interrupt_handler+0x72>
                    cprintf("Reached 10 times, shutting down...\n");
ffffffffc0200b5a:	00002517          	auipc	a0,0x2
ffffffffc0200b5e:	d7650513          	addi	a0,a0,-650 # ffffffffc02028d0 <commands+0x5f8>
ffffffffc0200b62:	d9cff0ef          	jal	ra,ffffffffc02000fe <cprintf>
}
ffffffffc0200b66:	60a2                	ld	ra,8(sp)
ffffffffc0200b68:	0141                	addi	sp,sp,16
                    sbi_shutdown();
ffffffffc0200b6a:	3ca0106f          	j	ffffffffc0201f34 <sbi_shutdown>

ffffffffc0200b6e <exception_handler>:

void exception_handler(struct trapframe *tf) {
ffffffffc0200b6e:	1101                	addi	sp,sp,-32
ffffffffc0200b70:	e822                	sd	s0,16(sp)
    switch (tf->cause) {
ffffffffc0200b72:	11853403          	ld	s0,280(a0)
void exception_handler(struct trapframe *tf) {
ffffffffc0200b76:	e426                	sd	s1,8(sp)
ffffffffc0200b78:	ec06                	sd	ra,24(sp)
    switch (tf->cause) {
ffffffffc0200b7a:	478d                	li	a5,3
void exception_handler(struct trapframe *tf) {
ffffffffc0200b7c:	84aa                	mv	s1,a0
    switch (tf->cause) {
ffffffffc0200b7e:	04f40863          	beq	s0,a5,ffffffffc0200bce <exception_handler+0x60>
ffffffffc0200b82:	0287ed63          	bltu	a5,s0,ffffffffc0200bbc <exception_handler+0x4e>
ffffffffc0200b86:	4789                	li	a5,2
ffffffffc0200b88:	02f41563          	bne	s0,a5,ffffffffc0200bb2 <exception_handler+0x44>
            break;
        case CAUSE_FAULT_FETCH:
            break;
        case CAUSE_ILLEGAL_INSTRUCTION:
            // LAB3 CHALLENGE3: 非法指令异常处理
            cprintf("Exception type: Illegal instruction\n");
ffffffffc0200b8c:	00002517          	auipc	a0,0x2
ffffffffc0200b90:	dbc50513          	addi	a0,a0,-580 # ffffffffc0202948 <commands+0x670>
ffffffffc0200b94:	d6aff0ef          	jal	ra,ffffffffc02000fe <cprintf>
            cprintf("Illegal instruction caught at 0x%016lx\n", tf->epc);
ffffffffc0200b98:	1084b583          	ld	a1,264(s1)
ffffffffc0200b9c:	00002517          	auipc	a0,0x2
ffffffffc0200ba0:	dd450513          	addi	a0,a0,-556 # ffffffffc0202970 <commands+0x698>
ffffffffc0200ba4:	d5aff0ef          	jal	ra,ffffffffc02000fe <cprintf>
            // 更新epc,跳过非法指令(假设是4字节标准指令)
            tf->epc += 4;
ffffffffc0200ba8:	1084b783          	ld	a5,264(s1)
ffffffffc0200bac:	0791                	addi	a5,a5,4
ffffffffc0200bae:	10f4b423          	sd	a5,264(s1)
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200bb2:	60e2                	ld	ra,24(sp)
ffffffffc0200bb4:	6442                	ld	s0,16(sp)
ffffffffc0200bb6:	64a2                	ld	s1,8(sp)
ffffffffc0200bb8:	6105                	addi	sp,sp,32
ffffffffc0200bba:	8082                	ret
    switch (tf->cause) {
ffffffffc0200bbc:	1471                	addi	s0,s0,-4
ffffffffc0200bbe:	479d                	li	a5,7
ffffffffc0200bc0:	fe87f9e3          	bgeu	a5,s0,ffffffffc0200bb2 <exception_handler+0x44>
}
ffffffffc0200bc4:	6442                	ld	s0,16(sp)
ffffffffc0200bc6:	60e2                	ld	ra,24(sp)
ffffffffc0200bc8:	64a2                	ld	s1,8(sp)
ffffffffc0200bca:	6105                	addi	sp,sp,32
            print_trapframe(tf);
ffffffffc0200bcc:	bd95                	j	ffffffffc0200a40 <print_trapframe>
        cprintf("Exception type: breakpoint\n");
ffffffffc0200bce:	00002517          	auipc	a0,0x2
ffffffffc0200bd2:	dca50513          	addi	a0,a0,-566 # ffffffffc0202998 <commands+0x6c0>
ffffffffc0200bd6:	d28ff0ef          	jal	ra,ffffffffc02000fe <cprintf>
        cprintf("ebreak caught at 0x%016lx\n", tf->epc);
ffffffffc0200bda:	1084b583          	ld	a1,264(s1)
ffffffffc0200bde:	00002517          	auipc	a0,0x2
ffffffffc0200be2:	dda50513          	addi	a0,a0,-550 # ffffffffc02029b8 <commands+0x6e0>
ffffffffc0200be6:	d18ff0ef          	jal	ra,ffffffffc02000fe <cprintf>
        uint16_t instr = *(uint16_t *)(tf->epc);
ffffffffc0200bea:	1084b783          	ld	a5,264(s1)
        tf->epc += ((instr & 0x3) != 0x3) ? 2 : 4;
ffffffffc0200bee:	4689                	li	a3,2
ffffffffc0200bf0:	0007d703          	lhu	a4,0(a5)
ffffffffc0200bf4:	8b0d                	andi	a4,a4,3
ffffffffc0200bf6:	00870a63          	beq	a4,s0,ffffffffc0200c0a <exception_handler+0x9c>
}
ffffffffc0200bfa:	60e2                	ld	ra,24(sp)
ffffffffc0200bfc:	6442                	ld	s0,16(sp)
        tf->epc += ((instr & 0x3) != 0x3) ? 2 : 4;
ffffffffc0200bfe:	97b6                	add	a5,a5,a3
ffffffffc0200c00:	10f4b423          	sd	a5,264(s1)
}
ffffffffc0200c04:	64a2                	ld	s1,8(sp)
ffffffffc0200c06:	6105                	addi	sp,sp,32
ffffffffc0200c08:	8082                	ret
        tf->epc += ((instr & 0x3) != 0x3) ? 2 : 4;
ffffffffc0200c0a:	4691                	li	a3,4
ffffffffc0200c0c:	b7fd                	j	ffffffffc0200bfa <exception_handler+0x8c>

ffffffffc0200c0e <trap>:

static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200c0e:	11853783          	ld	a5,280(a0)
ffffffffc0200c12:	0007c363          	bltz	a5,ffffffffc0200c18 <trap+0xa>
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
ffffffffc0200c16:	bfa1                	j	ffffffffc0200b6e <exception_handler>
        interrupt_handler(tf);
ffffffffc0200c18:	b569                	j	ffffffffc0200aa2 <interrupt_handler>
	...

ffffffffc0200c1c <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc0200c1c:	14011073          	csrw	sscratch,sp
ffffffffc0200c20:	712d                	addi	sp,sp,-288
ffffffffc0200c22:	e002                	sd	zero,0(sp)
ffffffffc0200c24:	e406                	sd	ra,8(sp)
ffffffffc0200c26:	ec0e                	sd	gp,24(sp)
ffffffffc0200c28:	f012                	sd	tp,32(sp)
ffffffffc0200c2a:	f416                	sd	t0,40(sp)
ffffffffc0200c2c:	f81a                	sd	t1,48(sp)
ffffffffc0200c2e:	fc1e                	sd	t2,56(sp)
ffffffffc0200c30:	e0a2                	sd	s0,64(sp)
ffffffffc0200c32:	e4a6                	sd	s1,72(sp)
ffffffffc0200c34:	e8aa                	sd	a0,80(sp)
ffffffffc0200c36:	ecae                	sd	a1,88(sp)
ffffffffc0200c38:	f0b2                	sd	a2,96(sp)
ffffffffc0200c3a:	f4b6                	sd	a3,104(sp)
ffffffffc0200c3c:	f8ba                	sd	a4,112(sp)
ffffffffc0200c3e:	fcbe                	sd	a5,120(sp)
ffffffffc0200c40:	e142                	sd	a6,128(sp)
ffffffffc0200c42:	e546                	sd	a7,136(sp)
ffffffffc0200c44:	e94a                	sd	s2,144(sp)
ffffffffc0200c46:	ed4e                	sd	s3,152(sp)
ffffffffc0200c48:	f152                	sd	s4,160(sp)
ffffffffc0200c4a:	f556                	sd	s5,168(sp)
ffffffffc0200c4c:	f95a                	sd	s6,176(sp)
ffffffffc0200c4e:	fd5e                	sd	s7,184(sp)
ffffffffc0200c50:	e1e2                	sd	s8,192(sp)
ffffffffc0200c52:	e5e6                	sd	s9,200(sp)
ffffffffc0200c54:	e9ea                	sd	s10,208(sp)
ffffffffc0200c56:	edee                	sd	s11,216(sp)
ffffffffc0200c58:	f1f2                	sd	t3,224(sp)
ffffffffc0200c5a:	f5f6                	sd	t4,232(sp)
ffffffffc0200c5c:	f9fa                	sd	t5,240(sp)
ffffffffc0200c5e:	fdfe                	sd	t6,248(sp)
ffffffffc0200c60:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200c64:	100024f3          	csrr	s1,sstatus
ffffffffc0200c68:	14102973          	csrr	s2,sepc
ffffffffc0200c6c:	143029f3          	csrr	s3,stval
ffffffffc0200c70:	14202a73          	csrr	s4,scause
ffffffffc0200c74:	e822                	sd	s0,16(sp)
ffffffffc0200c76:	e226                	sd	s1,256(sp)
ffffffffc0200c78:	e64a                	sd	s2,264(sp)
ffffffffc0200c7a:	ea4e                	sd	s3,272(sp)
ffffffffc0200c7c:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200c7e:	850a                	mv	a0,sp
    jal trap
ffffffffc0200c80:	f8fff0ef          	jal	ra,ffffffffc0200c0e <trap>

ffffffffc0200c84 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200c84:	6492                	ld	s1,256(sp)
ffffffffc0200c86:	6932                	ld	s2,264(sp)
ffffffffc0200c88:	10049073          	csrw	sstatus,s1
ffffffffc0200c8c:	14191073          	csrw	sepc,s2
ffffffffc0200c90:	60a2                	ld	ra,8(sp)
ffffffffc0200c92:	61e2                	ld	gp,24(sp)
ffffffffc0200c94:	7202                	ld	tp,32(sp)
ffffffffc0200c96:	72a2                	ld	t0,40(sp)
ffffffffc0200c98:	7342                	ld	t1,48(sp)
ffffffffc0200c9a:	73e2                	ld	t2,56(sp)
ffffffffc0200c9c:	6406                	ld	s0,64(sp)
ffffffffc0200c9e:	64a6                	ld	s1,72(sp)
ffffffffc0200ca0:	6546                	ld	a0,80(sp)
ffffffffc0200ca2:	65e6                	ld	a1,88(sp)
ffffffffc0200ca4:	7606                	ld	a2,96(sp)
ffffffffc0200ca6:	76a6                	ld	a3,104(sp)
ffffffffc0200ca8:	7746                	ld	a4,112(sp)
ffffffffc0200caa:	77e6                	ld	a5,120(sp)
ffffffffc0200cac:	680a                	ld	a6,128(sp)
ffffffffc0200cae:	68aa                	ld	a7,136(sp)
ffffffffc0200cb0:	694a                	ld	s2,144(sp)
ffffffffc0200cb2:	69ea                	ld	s3,152(sp)
ffffffffc0200cb4:	7a0a                	ld	s4,160(sp)
ffffffffc0200cb6:	7aaa                	ld	s5,168(sp)
ffffffffc0200cb8:	7b4a                	ld	s6,176(sp)
ffffffffc0200cba:	7bea                	ld	s7,184(sp)
ffffffffc0200cbc:	6c0e                	ld	s8,192(sp)
ffffffffc0200cbe:	6cae                	ld	s9,200(sp)
ffffffffc0200cc0:	6d4e                	ld	s10,208(sp)
ffffffffc0200cc2:	6dee                	ld	s11,216(sp)
ffffffffc0200cc4:	7e0e                	ld	t3,224(sp)
ffffffffc0200cc6:	7eae                	ld	t4,232(sp)
ffffffffc0200cc8:	7f4e                	ld	t5,240(sp)
ffffffffc0200cca:	7fee                	ld	t6,248(sp)
ffffffffc0200ccc:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200cce:	10200073          	sret

ffffffffc0200cd2 <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200cd2:	00006797          	auipc	a5,0x6
ffffffffc0200cd6:	35678793          	addi	a5,a5,854 # ffffffffc0207028 <free_area>
ffffffffc0200cda:	e79c                	sd	a5,8(a5)
ffffffffc0200cdc:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200cde:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200ce2:	8082                	ret

ffffffffc0200ce4 <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200ce4:	00006517          	auipc	a0,0x6
ffffffffc0200ce8:	35456503          	lwu	a0,852(a0) # ffffffffc0207038 <free_area+0x10>
ffffffffc0200cec:	8082                	ret

ffffffffc0200cee <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200cee:	715d                	addi	sp,sp,-80
ffffffffc0200cf0:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200cf2:	00006417          	auipc	s0,0x6
ffffffffc0200cf6:	33640413          	addi	s0,s0,822 # ffffffffc0207028 <free_area>
ffffffffc0200cfa:	641c                	ld	a5,8(s0)
ffffffffc0200cfc:	e486                	sd	ra,72(sp)
ffffffffc0200cfe:	fc26                	sd	s1,56(sp)
ffffffffc0200d00:	f84a                	sd	s2,48(sp)
ffffffffc0200d02:	f44e                	sd	s3,40(sp)
ffffffffc0200d04:	f052                	sd	s4,32(sp)
ffffffffc0200d06:	ec56                	sd	s5,24(sp)
ffffffffc0200d08:	e85a                	sd	s6,16(sp)
ffffffffc0200d0a:	e45e                	sd	s7,8(sp)
ffffffffc0200d0c:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200d0e:	2c878763          	beq	a5,s0,ffffffffc0200fdc <default_check+0x2ee>
    int count = 0, total = 0;
ffffffffc0200d12:	4481                	li	s1,0
ffffffffc0200d14:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200d16:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200d1a:	8b09                	andi	a4,a4,2
ffffffffc0200d1c:	2c070463          	beqz	a4,ffffffffc0200fe4 <default_check+0x2f6>
        count ++, total += p->property;
ffffffffc0200d20:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200d24:	679c                	ld	a5,8(a5)
ffffffffc0200d26:	2905                	addiw	s2,s2,1
ffffffffc0200d28:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200d2a:	fe8796e3          	bne	a5,s0,ffffffffc0200d16 <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200d2e:	89a6                	mv	s3,s1
ffffffffc0200d30:	2f9000ef          	jal	ra,ffffffffc0201828 <nr_free_pages>
ffffffffc0200d34:	71351863          	bne	a0,s3,ffffffffc0201444 <default_check+0x756>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200d38:	4505                	li	a0,1
ffffffffc0200d3a:	271000ef          	jal	ra,ffffffffc02017aa <alloc_pages>
ffffffffc0200d3e:	8a2a                	mv	s4,a0
ffffffffc0200d40:	44050263          	beqz	a0,ffffffffc0201184 <default_check+0x496>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200d44:	4505                	li	a0,1
ffffffffc0200d46:	265000ef          	jal	ra,ffffffffc02017aa <alloc_pages>
ffffffffc0200d4a:	89aa                	mv	s3,a0
ffffffffc0200d4c:	70050c63          	beqz	a0,ffffffffc0201464 <default_check+0x776>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200d50:	4505                	li	a0,1
ffffffffc0200d52:	259000ef          	jal	ra,ffffffffc02017aa <alloc_pages>
ffffffffc0200d56:	8aaa                	mv	s5,a0
ffffffffc0200d58:	4a050663          	beqz	a0,ffffffffc0201204 <default_check+0x516>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200d5c:	2b3a0463          	beq	s4,s3,ffffffffc0201004 <default_check+0x316>
ffffffffc0200d60:	2aaa0263          	beq	s4,a0,ffffffffc0201004 <default_check+0x316>
ffffffffc0200d64:	2aa98063          	beq	s3,a0,ffffffffc0201004 <default_check+0x316>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200d68:	000a2783          	lw	a5,0(s4)
ffffffffc0200d6c:	2a079c63          	bnez	a5,ffffffffc0201024 <default_check+0x336>
ffffffffc0200d70:	0009a783          	lw	a5,0(s3)
ffffffffc0200d74:	2a079863          	bnez	a5,ffffffffc0201024 <default_check+0x336>
ffffffffc0200d78:	411c                	lw	a5,0(a0)
ffffffffc0200d7a:	2a079563          	bnez	a5,ffffffffc0201024 <default_check+0x336>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200d7e:	00006797          	auipc	a5,0x6
ffffffffc0200d82:	6f27b783          	ld	a5,1778(a5) # ffffffffc0207470 <pages>
ffffffffc0200d86:	40fa0733          	sub	a4,s4,a5
ffffffffc0200d8a:	870d                	srai	a4,a4,0x3
ffffffffc0200d8c:	00002597          	auipc	a1,0x2
ffffffffc0200d90:	3d45b583          	ld	a1,980(a1) # ffffffffc0203160 <error_string+0x38>
ffffffffc0200d94:	02b70733          	mul	a4,a4,a1
ffffffffc0200d98:	00002617          	auipc	a2,0x2
ffffffffc0200d9c:	3d063603          	ld	a2,976(a2) # ffffffffc0203168 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200da0:	00006697          	auipc	a3,0x6
ffffffffc0200da4:	6c86b683          	ld	a3,1736(a3) # ffffffffc0207468 <npage>
ffffffffc0200da8:	06b2                	slli	a3,a3,0xc
ffffffffc0200daa:	9732                	add	a4,a4,a2

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200dac:	0732                	slli	a4,a4,0xc
ffffffffc0200dae:	28d77b63          	bgeu	a4,a3,ffffffffc0201044 <default_check+0x356>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200db2:	40f98733          	sub	a4,s3,a5
ffffffffc0200db6:	870d                	srai	a4,a4,0x3
ffffffffc0200db8:	02b70733          	mul	a4,a4,a1
ffffffffc0200dbc:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200dbe:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200dc0:	4cd77263          	bgeu	a4,a3,ffffffffc0201284 <default_check+0x596>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200dc4:	40f507b3          	sub	a5,a0,a5
ffffffffc0200dc8:	878d                	srai	a5,a5,0x3
ffffffffc0200dca:	02b787b3          	mul	a5,a5,a1
ffffffffc0200dce:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200dd0:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200dd2:	30d7f963          	bgeu	a5,a3,ffffffffc02010e4 <default_check+0x3f6>
    assert(alloc_page() == NULL);
ffffffffc0200dd6:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200dd8:	00043c03          	ld	s8,0(s0)
ffffffffc0200ddc:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200de0:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200de4:	e400                	sd	s0,8(s0)
ffffffffc0200de6:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200de8:	00006797          	auipc	a5,0x6
ffffffffc0200dec:	2407a823          	sw	zero,592(a5) # ffffffffc0207038 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200df0:	1bb000ef          	jal	ra,ffffffffc02017aa <alloc_pages>
ffffffffc0200df4:	2c051863          	bnez	a0,ffffffffc02010c4 <default_check+0x3d6>
    free_page(p0);
ffffffffc0200df8:	4585                	li	a1,1
ffffffffc0200dfa:	8552                	mv	a0,s4
ffffffffc0200dfc:	1ed000ef          	jal	ra,ffffffffc02017e8 <free_pages>
    free_page(p1);
ffffffffc0200e00:	4585                	li	a1,1
ffffffffc0200e02:	854e                	mv	a0,s3
ffffffffc0200e04:	1e5000ef          	jal	ra,ffffffffc02017e8 <free_pages>
    free_page(p2);
ffffffffc0200e08:	4585                	li	a1,1
ffffffffc0200e0a:	8556                	mv	a0,s5
ffffffffc0200e0c:	1dd000ef          	jal	ra,ffffffffc02017e8 <free_pages>
    assert(nr_free == 3);
ffffffffc0200e10:	4818                	lw	a4,16(s0)
ffffffffc0200e12:	478d                	li	a5,3
ffffffffc0200e14:	28f71863          	bne	a4,a5,ffffffffc02010a4 <default_check+0x3b6>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200e18:	4505                	li	a0,1
ffffffffc0200e1a:	191000ef          	jal	ra,ffffffffc02017aa <alloc_pages>
ffffffffc0200e1e:	89aa                	mv	s3,a0
ffffffffc0200e20:	26050263          	beqz	a0,ffffffffc0201084 <default_check+0x396>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200e24:	4505                	li	a0,1
ffffffffc0200e26:	185000ef          	jal	ra,ffffffffc02017aa <alloc_pages>
ffffffffc0200e2a:	8aaa                	mv	s5,a0
ffffffffc0200e2c:	3a050c63          	beqz	a0,ffffffffc02011e4 <default_check+0x4f6>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200e30:	4505                	li	a0,1
ffffffffc0200e32:	179000ef          	jal	ra,ffffffffc02017aa <alloc_pages>
ffffffffc0200e36:	8a2a                	mv	s4,a0
ffffffffc0200e38:	38050663          	beqz	a0,ffffffffc02011c4 <default_check+0x4d6>
    assert(alloc_page() == NULL);
ffffffffc0200e3c:	4505                	li	a0,1
ffffffffc0200e3e:	16d000ef          	jal	ra,ffffffffc02017aa <alloc_pages>
ffffffffc0200e42:	36051163          	bnez	a0,ffffffffc02011a4 <default_check+0x4b6>
    free_page(p0);
ffffffffc0200e46:	4585                	li	a1,1
ffffffffc0200e48:	854e                	mv	a0,s3
ffffffffc0200e4a:	19f000ef          	jal	ra,ffffffffc02017e8 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200e4e:	641c                	ld	a5,8(s0)
ffffffffc0200e50:	20878a63          	beq	a5,s0,ffffffffc0201064 <default_check+0x376>
    assert((p = alloc_page()) == p0);
ffffffffc0200e54:	4505                	li	a0,1
ffffffffc0200e56:	155000ef          	jal	ra,ffffffffc02017aa <alloc_pages>
ffffffffc0200e5a:	30a99563          	bne	s3,a0,ffffffffc0201164 <default_check+0x476>
    assert(alloc_page() == NULL);
ffffffffc0200e5e:	4505                	li	a0,1
ffffffffc0200e60:	14b000ef          	jal	ra,ffffffffc02017aa <alloc_pages>
ffffffffc0200e64:	2e051063          	bnez	a0,ffffffffc0201144 <default_check+0x456>
    assert(nr_free == 0);
ffffffffc0200e68:	481c                	lw	a5,16(s0)
ffffffffc0200e6a:	2a079d63          	bnez	a5,ffffffffc0201124 <default_check+0x436>
    free_page(p);
ffffffffc0200e6e:	854e                	mv	a0,s3
ffffffffc0200e70:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200e72:	01843023          	sd	s8,0(s0)
ffffffffc0200e76:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200e7a:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200e7e:	16b000ef          	jal	ra,ffffffffc02017e8 <free_pages>
    free_page(p1);
ffffffffc0200e82:	4585                	li	a1,1
ffffffffc0200e84:	8556                	mv	a0,s5
ffffffffc0200e86:	163000ef          	jal	ra,ffffffffc02017e8 <free_pages>
    free_page(p2);
ffffffffc0200e8a:	4585                	li	a1,1
ffffffffc0200e8c:	8552                	mv	a0,s4
ffffffffc0200e8e:	15b000ef          	jal	ra,ffffffffc02017e8 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200e92:	4515                	li	a0,5
ffffffffc0200e94:	117000ef          	jal	ra,ffffffffc02017aa <alloc_pages>
ffffffffc0200e98:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200e9a:	26050563          	beqz	a0,ffffffffc0201104 <default_check+0x416>
ffffffffc0200e9e:	651c                	ld	a5,8(a0)
ffffffffc0200ea0:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200ea2:	8b85                	andi	a5,a5,1
ffffffffc0200ea4:	54079063          	bnez	a5,ffffffffc02013e4 <default_check+0x6f6>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200ea8:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200eaa:	00043b03          	ld	s6,0(s0)
ffffffffc0200eae:	00843a83          	ld	s5,8(s0)
ffffffffc0200eb2:	e000                	sd	s0,0(s0)
ffffffffc0200eb4:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200eb6:	0f5000ef          	jal	ra,ffffffffc02017aa <alloc_pages>
ffffffffc0200eba:	50051563          	bnez	a0,ffffffffc02013c4 <default_check+0x6d6>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0200ebe:	05098a13          	addi	s4,s3,80
ffffffffc0200ec2:	8552                	mv	a0,s4
ffffffffc0200ec4:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0200ec6:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc0200eca:	00006797          	auipc	a5,0x6
ffffffffc0200ece:	1607a723          	sw	zero,366(a5) # ffffffffc0207038 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0200ed2:	117000ef          	jal	ra,ffffffffc02017e8 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200ed6:	4511                	li	a0,4
ffffffffc0200ed8:	0d3000ef          	jal	ra,ffffffffc02017aa <alloc_pages>
ffffffffc0200edc:	4c051463          	bnez	a0,ffffffffc02013a4 <default_check+0x6b6>
ffffffffc0200ee0:	0589b783          	ld	a5,88(s3)
ffffffffc0200ee4:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0200ee6:	8b85                	andi	a5,a5,1
ffffffffc0200ee8:	48078e63          	beqz	a5,ffffffffc0201384 <default_check+0x696>
ffffffffc0200eec:	0609a703          	lw	a4,96(s3)
ffffffffc0200ef0:	478d                	li	a5,3
ffffffffc0200ef2:	48f71963          	bne	a4,a5,ffffffffc0201384 <default_check+0x696>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0200ef6:	450d                	li	a0,3
ffffffffc0200ef8:	0b3000ef          	jal	ra,ffffffffc02017aa <alloc_pages>
ffffffffc0200efc:	8c2a                	mv	s8,a0
ffffffffc0200efe:	46050363          	beqz	a0,ffffffffc0201364 <default_check+0x676>
    assert(alloc_page() == NULL);
ffffffffc0200f02:	4505                	li	a0,1
ffffffffc0200f04:	0a7000ef          	jal	ra,ffffffffc02017aa <alloc_pages>
ffffffffc0200f08:	42051e63          	bnez	a0,ffffffffc0201344 <default_check+0x656>
    assert(p0 + 2 == p1);
ffffffffc0200f0c:	418a1c63          	bne	s4,s8,ffffffffc0201324 <default_check+0x636>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0200f10:	4585                	li	a1,1
ffffffffc0200f12:	854e                	mv	a0,s3
ffffffffc0200f14:	0d5000ef          	jal	ra,ffffffffc02017e8 <free_pages>
    free_pages(p1, 3);
ffffffffc0200f18:	458d                	li	a1,3
ffffffffc0200f1a:	8552                	mv	a0,s4
ffffffffc0200f1c:	0cd000ef          	jal	ra,ffffffffc02017e8 <free_pages>
ffffffffc0200f20:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0200f24:	02898c13          	addi	s8,s3,40
ffffffffc0200f28:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0200f2a:	8b85                	andi	a5,a5,1
ffffffffc0200f2c:	3c078c63          	beqz	a5,ffffffffc0201304 <default_check+0x616>
ffffffffc0200f30:	0109a703          	lw	a4,16(s3)
ffffffffc0200f34:	4785                	li	a5,1
ffffffffc0200f36:	3cf71763          	bne	a4,a5,ffffffffc0201304 <default_check+0x616>
ffffffffc0200f3a:	008a3783          	ld	a5,8(s4)
ffffffffc0200f3e:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0200f40:	8b85                	andi	a5,a5,1
ffffffffc0200f42:	3a078163          	beqz	a5,ffffffffc02012e4 <default_check+0x5f6>
ffffffffc0200f46:	010a2703          	lw	a4,16(s4)
ffffffffc0200f4a:	478d                	li	a5,3
ffffffffc0200f4c:	38f71c63          	bne	a4,a5,ffffffffc02012e4 <default_check+0x5f6>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0200f50:	4505                	li	a0,1
ffffffffc0200f52:	059000ef          	jal	ra,ffffffffc02017aa <alloc_pages>
ffffffffc0200f56:	36a99763          	bne	s3,a0,ffffffffc02012c4 <default_check+0x5d6>
    free_page(p0);
ffffffffc0200f5a:	4585                	li	a1,1
ffffffffc0200f5c:	08d000ef          	jal	ra,ffffffffc02017e8 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0200f60:	4509                	li	a0,2
ffffffffc0200f62:	049000ef          	jal	ra,ffffffffc02017aa <alloc_pages>
ffffffffc0200f66:	32aa1f63          	bne	s4,a0,ffffffffc02012a4 <default_check+0x5b6>

    free_pages(p0, 2);
ffffffffc0200f6a:	4589                	li	a1,2
ffffffffc0200f6c:	07d000ef          	jal	ra,ffffffffc02017e8 <free_pages>
    free_page(p2);
ffffffffc0200f70:	4585                	li	a1,1
ffffffffc0200f72:	8562                	mv	a0,s8
ffffffffc0200f74:	075000ef          	jal	ra,ffffffffc02017e8 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200f78:	4515                	li	a0,5
ffffffffc0200f7a:	031000ef          	jal	ra,ffffffffc02017aa <alloc_pages>
ffffffffc0200f7e:	89aa                	mv	s3,a0
ffffffffc0200f80:	48050263          	beqz	a0,ffffffffc0201404 <default_check+0x716>
    assert(alloc_page() == NULL);
ffffffffc0200f84:	4505                	li	a0,1
ffffffffc0200f86:	025000ef          	jal	ra,ffffffffc02017aa <alloc_pages>
ffffffffc0200f8a:	2c051d63          	bnez	a0,ffffffffc0201264 <default_check+0x576>

    assert(nr_free == 0);
ffffffffc0200f8e:	481c                	lw	a5,16(s0)
ffffffffc0200f90:	2a079a63          	bnez	a5,ffffffffc0201244 <default_check+0x556>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200f94:	4595                	li	a1,5
ffffffffc0200f96:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200f98:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0200f9c:	01643023          	sd	s6,0(s0)
ffffffffc0200fa0:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0200fa4:	045000ef          	jal	ra,ffffffffc02017e8 <free_pages>
    return listelm->next;
ffffffffc0200fa8:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200faa:	00878963          	beq	a5,s0,ffffffffc0200fbc <default_check+0x2ce>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200fae:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200fb2:	679c                	ld	a5,8(a5)
ffffffffc0200fb4:	397d                	addiw	s2,s2,-1
ffffffffc0200fb6:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200fb8:	fe879be3          	bne	a5,s0,ffffffffc0200fae <default_check+0x2c0>
    }
    assert(count == 0);
ffffffffc0200fbc:	26091463          	bnez	s2,ffffffffc0201224 <default_check+0x536>
    assert(total == 0);
ffffffffc0200fc0:	46049263          	bnez	s1,ffffffffc0201424 <default_check+0x736>
}
ffffffffc0200fc4:	60a6                	ld	ra,72(sp)
ffffffffc0200fc6:	6406                	ld	s0,64(sp)
ffffffffc0200fc8:	74e2                	ld	s1,56(sp)
ffffffffc0200fca:	7942                	ld	s2,48(sp)
ffffffffc0200fcc:	79a2                	ld	s3,40(sp)
ffffffffc0200fce:	7a02                	ld	s4,32(sp)
ffffffffc0200fd0:	6ae2                	ld	s5,24(sp)
ffffffffc0200fd2:	6b42                	ld	s6,16(sp)
ffffffffc0200fd4:	6ba2                	ld	s7,8(sp)
ffffffffc0200fd6:	6c02                	ld	s8,0(sp)
ffffffffc0200fd8:	6161                	addi	sp,sp,80
ffffffffc0200fda:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200fdc:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200fde:	4481                	li	s1,0
ffffffffc0200fe0:	4901                	li	s2,0
ffffffffc0200fe2:	b3b9                	j	ffffffffc0200d30 <default_check+0x42>
        assert(PageProperty(p));
ffffffffc0200fe4:	00002697          	auipc	a3,0x2
ffffffffc0200fe8:	9f468693          	addi	a3,a3,-1548 # ffffffffc02029d8 <commands+0x700>
ffffffffc0200fec:	00002617          	auipc	a2,0x2
ffffffffc0200ff0:	9fc60613          	addi	a2,a2,-1540 # ffffffffc02029e8 <commands+0x710>
ffffffffc0200ff4:	0f000593          	li	a1,240
ffffffffc0200ff8:	00002517          	auipc	a0,0x2
ffffffffc0200ffc:	a0850513          	addi	a0,a0,-1528 # ffffffffc0202a00 <commands+0x728>
ffffffffc0201000:	bf8ff0ef          	jal	ra,ffffffffc02003f8 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201004:	00002697          	auipc	a3,0x2
ffffffffc0201008:	a9468693          	addi	a3,a3,-1388 # ffffffffc0202a98 <commands+0x7c0>
ffffffffc020100c:	00002617          	auipc	a2,0x2
ffffffffc0201010:	9dc60613          	addi	a2,a2,-1572 # ffffffffc02029e8 <commands+0x710>
ffffffffc0201014:	0bd00593          	li	a1,189
ffffffffc0201018:	00002517          	auipc	a0,0x2
ffffffffc020101c:	9e850513          	addi	a0,a0,-1560 # ffffffffc0202a00 <commands+0x728>
ffffffffc0201020:	bd8ff0ef          	jal	ra,ffffffffc02003f8 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201024:	00002697          	auipc	a3,0x2
ffffffffc0201028:	a9c68693          	addi	a3,a3,-1380 # ffffffffc0202ac0 <commands+0x7e8>
ffffffffc020102c:	00002617          	auipc	a2,0x2
ffffffffc0201030:	9bc60613          	addi	a2,a2,-1604 # ffffffffc02029e8 <commands+0x710>
ffffffffc0201034:	0be00593          	li	a1,190
ffffffffc0201038:	00002517          	auipc	a0,0x2
ffffffffc020103c:	9c850513          	addi	a0,a0,-1592 # ffffffffc0202a00 <commands+0x728>
ffffffffc0201040:	bb8ff0ef          	jal	ra,ffffffffc02003f8 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201044:	00002697          	auipc	a3,0x2
ffffffffc0201048:	abc68693          	addi	a3,a3,-1348 # ffffffffc0202b00 <commands+0x828>
ffffffffc020104c:	00002617          	auipc	a2,0x2
ffffffffc0201050:	99c60613          	addi	a2,a2,-1636 # ffffffffc02029e8 <commands+0x710>
ffffffffc0201054:	0c000593          	li	a1,192
ffffffffc0201058:	00002517          	auipc	a0,0x2
ffffffffc020105c:	9a850513          	addi	a0,a0,-1624 # ffffffffc0202a00 <commands+0x728>
ffffffffc0201060:	b98ff0ef          	jal	ra,ffffffffc02003f8 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0201064:	00002697          	auipc	a3,0x2
ffffffffc0201068:	b2468693          	addi	a3,a3,-1244 # ffffffffc0202b88 <commands+0x8b0>
ffffffffc020106c:	00002617          	auipc	a2,0x2
ffffffffc0201070:	97c60613          	addi	a2,a2,-1668 # ffffffffc02029e8 <commands+0x710>
ffffffffc0201074:	0d900593          	li	a1,217
ffffffffc0201078:	00002517          	auipc	a0,0x2
ffffffffc020107c:	98850513          	addi	a0,a0,-1656 # ffffffffc0202a00 <commands+0x728>
ffffffffc0201080:	b78ff0ef          	jal	ra,ffffffffc02003f8 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201084:	00002697          	auipc	a3,0x2
ffffffffc0201088:	9b468693          	addi	a3,a3,-1612 # ffffffffc0202a38 <commands+0x760>
ffffffffc020108c:	00002617          	auipc	a2,0x2
ffffffffc0201090:	95c60613          	addi	a2,a2,-1700 # ffffffffc02029e8 <commands+0x710>
ffffffffc0201094:	0d200593          	li	a1,210
ffffffffc0201098:	00002517          	auipc	a0,0x2
ffffffffc020109c:	96850513          	addi	a0,a0,-1688 # ffffffffc0202a00 <commands+0x728>
ffffffffc02010a0:	b58ff0ef          	jal	ra,ffffffffc02003f8 <__panic>
    assert(nr_free == 3);
ffffffffc02010a4:	00002697          	auipc	a3,0x2
ffffffffc02010a8:	ad468693          	addi	a3,a3,-1324 # ffffffffc0202b78 <commands+0x8a0>
ffffffffc02010ac:	00002617          	auipc	a2,0x2
ffffffffc02010b0:	93c60613          	addi	a2,a2,-1732 # ffffffffc02029e8 <commands+0x710>
ffffffffc02010b4:	0d000593          	li	a1,208
ffffffffc02010b8:	00002517          	auipc	a0,0x2
ffffffffc02010bc:	94850513          	addi	a0,a0,-1720 # ffffffffc0202a00 <commands+0x728>
ffffffffc02010c0:	b38ff0ef          	jal	ra,ffffffffc02003f8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02010c4:	00002697          	auipc	a3,0x2
ffffffffc02010c8:	a9c68693          	addi	a3,a3,-1380 # ffffffffc0202b60 <commands+0x888>
ffffffffc02010cc:	00002617          	auipc	a2,0x2
ffffffffc02010d0:	91c60613          	addi	a2,a2,-1764 # ffffffffc02029e8 <commands+0x710>
ffffffffc02010d4:	0cb00593          	li	a1,203
ffffffffc02010d8:	00002517          	auipc	a0,0x2
ffffffffc02010dc:	92850513          	addi	a0,a0,-1752 # ffffffffc0202a00 <commands+0x728>
ffffffffc02010e0:	b18ff0ef          	jal	ra,ffffffffc02003f8 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02010e4:	00002697          	auipc	a3,0x2
ffffffffc02010e8:	a5c68693          	addi	a3,a3,-1444 # ffffffffc0202b40 <commands+0x868>
ffffffffc02010ec:	00002617          	auipc	a2,0x2
ffffffffc02010f0:	8fc60613          	addi	a2,a2,-1796 # ffffffffc02029e8 <commands+0x710>
ffffffffc02010f4:	0c200593          	li	a1,194
ffffffffc02010f8:	00002517          	auipc	a0,0x2
ffffffffc02010fc:	90850513          	addi	a0,a0,-1784 # ffffffffc0202a00 <commands+0x728>
ffffffffc0201100:	af8ff0ef          	jal	ra,ffffffffc02003f8 <__panic>
    assert(p0 != NULL);
ffffffffc0201104:	00002697          	auipc	a3,0x2
ffffffffc0201108:	acc68693          	addi	a3,a3,-1332 # ffffffffc0202bd0 <commands+0x8f8>
ffffffffc020110c:	00002617          	auipc	a2,0x2
ffffffffc0201110:	8dc60613          	addi	a2,a2,-1828 # ffffffffc02029e8 <commands+0x710>
ffffffffc0201114:	0f800593          	li	a1,248
ffffffffc0201118:	00002517          	auipc	a0,0x2
ffffffffc020111c:	8e850513          	addi	a0,a0,-1816 # ffffffffc0202a00 <commands+0x728>
ffffffffc0201120:	ad8ff0ef          	jal	ra,ffffffffc02003f8 <__panic>
    assert(nr_free == 0);
ffffffffc0201124:	00002697          	auipc	a3,0x2
ffffffffc0201128:	a9c68693          	addi	a3,a3,-1380 # ffffffffc0202bc0 <commands+0x8e8>
ffffffffc020112c:	00002617          	auipc	a2,0x2
ffffffffc0201130:	8bc60613          	addi	a2,a2,-1860 # ffffffffc02029e8 <commands+0x710>
ffffffffc0201134:	0df00593          	li	a1,223
ffffffffc0201138:	00002517          	auipc	a0,0x2
ffffffffc020113c:	8c850513          	addi	a0,a0,-1848 # ffffffffc0202a00 <commands+0x728>
ffffffffc0201140:	ab8ff0ef          	jal	ra,ffffffffc02003f8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201144:	00002697          	auipc	a3,0x2
ffffffffc0201148:	a1c68693          	addi	a3,a3,-1508 # ffffffffc0202b60 <commands+0x888>
ffffffffc020114c:	00002617          	auipc	a2,0x2
ffffffffc0201150:	89c60613          	addi	a2,a2,-1892 # ffffffffc02029e8 <commands+0x710>
ffffffffc0201154:	0dd00593          	li	a1,221
ffffffffc0201158:	00002517          	auipc	a0,0x2
ffffffffc020115c:	8a850513          	addi	a0,a0,-1880 # ffffffffc0202a00 <commands+0x728>
ffffffffc0201160:	a98ff0ef          	jal	ra,ffffffffc02003f8 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201164:	00002697          	auipc	a3,0x2
ffffffffc0201168:	a3c68693          	addi	a3,a3,-1476 # ffffffffc0202ba0 <commands+0x8c8>
ffffffffc020116c:	00002617          	auipc	a2,0x2
ffffffffc0201170:	87c60613          	addi	a2,a2,-1924 # ffffffffc02029e8 <commands+0x710>
ffffffffc0201174:	0dc00593          	li	a1,220
ffffffffc0201178:	00002517          	auipc	a0,0x2
ffffffffc020117c:	88850513          	addi	a0,a0,-1912 # ffffffffc0202a00 <commands+0x728>
ffffffffc0201180:	a78ff0ef          	jal	ra,ffffffffc02003f8 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201184:	00002697          	auipc	a3,0x2
ffffffffc0201188:	8b468693          	addi	a3,a3,-1868 # ffffffffc0202a38 <commands+0x760>
ffffffffc020118c:	00002617          	auipc	a2,0x2
ffffffffc0201190:	85c60613          	addi	a2,a2,-1956 # ffffffffc02029e8 <commands+0x710>
ffffffffc0201194:	0b900593          	li	a1,185
ffffffffc0201198:	00002517          	auipc	a0,0x2
ffffffffc020119c:	86850513          	addi	a0,a0,-1944 # ffffffffc0202a00 <commands+0x728>
ffffffffc02011a0:	a58ff0ef          	jal	ra,ffffffffc02003f8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02011a4:	00002697          	auipc	a3,0x2
ffffffffc02011a8:	9bc68693          	addi	a3,a3,-1604 # ffffffffc0202b60 <commands+0x888>
ffffffffc02011ac:	00002617          	auipc	a2,0x2
ffffffffc02011b0:	83c60613          	addi	a2,a2,-1988 # ffffffffc02029e8 <commands+0x710>
ffffffffc02011b4:	0d600593          	li	a1,214
ffffffffc02011b8:	00002517          	auipc	a0,0x2
ffffffffc02011bc:	84850513          	addi	a0,a0,-1976 # ffffffffc0202a00 <commands+0x728>
ffffffffc02011c0:	a38ff0ef          	jal	ra,ffffffffc02003f8 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02011c4:	00002697          	auipc	a3,0x2
ffffffffc02011c8:	8b468693          	addi	a3,a3,-1868 # ffffffffc0202a78 <commands+0x7a0>
ffffffffc02011cc:	00002617          	auipc	a2,0x2
ffffffffc02011d0:	81c60613          	addi	a2,a2,-2020 # ffffffffc02029e8 <commands+0x710>
ffffffffc02011d4:	0d400593          	li	a1,212
ffffffffc02011d8:	00002517          	auipc	a0,0x2
ffffffffc02011dc:	82850513          	addi	a0,a0,-2008 # ffffffffc0202a00 <commands+0x728>
ffffffffc02011e0:	a18ff0ef          	jal	ra,ffffffffc02003f8 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02011e4:	00002697          	auipc	a3,0x2
ffffffffc02011e8:	87468693          	addi	a3,a3,-1932 # ffffffffc0202a58 <commands+0x780>
ffffffffc02011ec:	00001617          	auipc	a2,0x1
ffffffffc02011f0:	7fc60613          	addi	a2,a2,2044 # ffffffffc02029e8 <commands+0x710>
ffffffffc02011f4:	0d300593          	li	a1,211
ffffffffc02011f8:	00002517          	auipc	a0,0x2
ffffffffc02011fc:	80850513          	addi	a0,a0,-2040 # ffffffffc0202a00 <commands+0x728>
ffffffffc0201200:	9f8ff0ef          	jal	ra,ffffffffc02003f8 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201204:	00002697          	auipc	a3,0x2
ffffffffc0201208:	87468693          	addi	a3,a3,-1932 # ffffffffc0202a78 <commands+0x7a0>
ffffffffc020120c:	00001617          	auipc	a2,0x1
ffffffffc0201210:	7dc60613          	addi	a2,a2,2012 # ffffffffc02029e8 <commands+0x710>
ffffffffc0201214:	0bb00593          	li	a1,187
ffffffffc0201218:	00001517          	auipc	a0,0x1
ffffffffc020121c:	7e850513          	addi	a0,a0,2024 # ffffffffc0202a00 <commands+0x728>
ffffffffc0201220:	9d8ff0ef          	jal	ra,ffffffffc02003f8 <__panic>
    assert(count == 0);
ffffffffc0201224:	00002697          	auipc	a3,0x2
ffffffffc0201228:	afc68693          	addi	a3,a3,-1284 # ffffffffc0202d20 <commands+0xa48>
ffffffffc020122c:	00001617          	auipc	a2,0x1
ffffffffc0201230:	7bc60613          	addi	a2,a2,1980 # ffffffffc02029e8 <commands+0x710>
ffffffffc0201234:	12500593          	li	a1,293
ffffffffc0201238:	00001517          	auipc	a0,0x1
ffffffffc020123c:	7c850513          	addi	a0,a0,1992 # ffffffffc0202a00 <commands+0x728>
ffffffffc0201240:	9b8ff0ef          	jal	ra,ffffffffc02003f8 <__panic>
    assert(nr_free == 0);
ffffffffc0201244:	00002697          	auipc	a3,0x2
ffffffffc0201248:	97c68693          	addi	a3,a3,-1668 # ffffffffc0202bc0 <commands+0x8e8>
ffffffffc020124c:	00001617          	auipc	a2,0x1
ffffffffc0201250:	79c60613          	addi	a2,a2,1948 # ffffffffc02029e8 <commands+0x710>
ffffffffc0201254:	11a00593          	li	a1,282
ffffffffc0201258:	00001517          	auipc	a0,0x1
ffffffffc020125c:	7a850513          	addi	a0,a0,1960 # ffffffffc0202a00 <commands+0x728>
ffffffffc0201260:	998ff0ef          	jal	ra,ffffffffc02003f8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201264:	00002697          	auipc	a3,0x2
ffffffffc0201268:	8fc68693          	addi	a3,a3,-1796 # ffffffffc0202b60 <commands+0x888>
ffffffffc020126c:	00001617          	auipc	a2,0x1
ffffffffc0201270:	77c60613          	addi	a2,a2,1916 # ffffffffc02029e8 <commands+0x710>
ffffffffc0201274:	11800593          	li	a1,280
ffffffffc0201278:	00001517          	auipc	a0,0x1
ffffffffc020127c:	78850513          	addi	a0,a0,1928 # ffffffffc0202a00 <commands+0x728>
ffffffffc0201280:	978ff0ef          	jal	ra,ffffffffc02003f8 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201284:	00002697          	auipc	a3,0x2
ffffffffc0201288:	89c68693          	addi	a3,a3,-1892 # ffffffffc0202b20 <commands+0x848>
ffffffffc020128c:	00001617          	auipc	a2,0x1
ffffffffc0201290:	75c60613          	addi	a2,a2,1884 # ffffffffc02029e8 <commands+0x710>
ffffffffc0201294:	0c100593          	li	a1,193
ffffffffc0201298:	00001517          	auipc	a0,0x1
ffffffffc020129c:	76850513          	addi	a0,a0,1896 # ffffffffc0202a00 <commands+0x728>
ffffffffc02012a0:	958ff0ef          	jal	ra,ffffffffc02003f8 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02012a4:	00002697          	auipc	a3,0x2
ffffffffc02012a8:	a3c68693          	addi	a3,a3,-1476 # ffffffffc0202ce0 <commands+0xa08>
ffffffffc02012ac:	00001617          	auipc	a2,0x1
ffffffffc02012b0:	73c60613          	addi	a2,a2,1852 # ffffffffc02029e8 <commands+0x710>
ffffffffc02012b4:	11200593          	li	a1,274
ffffffffc02012b8:	00001517          	auipc	a0,0x1
ffffffffc02012bc:	74850513          	addi	a0,a0,1864 # ffffffffc0202a00 <commands+0x728>
ffffffffc02012c0:	938ff0ef          	jal	ra,ffffffffc02003f8 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02012c4:	00002697          	auipc	a3,0x2
ffffffffc02012c8:	9fc68693          	addi	a3,a3,-1540 # ffffffffc0202cc0 <commands+0x9e8>
ffffffffc02012cc:	00001617          	auipc	a2,0x1
ffffffffc02012d0:	71c60613          	addi	a2,a2,1820 # ffffffffc02029e8 <commands+0x710>
ffffffffc02012d4:	11000593          	li	a1,272
ffffffffc02012d8:	00001517          	auipc	a0,0x1
ffffffffc02012dc:	72850513          	addi	a0,a0,1832 # ffffffffc0202a00 <commands+0x728>
ffffffffc02012e0:	918ff0ef          	jal	ra,ffffffffc02003f8 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02012e4:	00002697          	auipc	a3,0x2
ffffffffc02012e8:	9b468693          	addi	a3,a3,-1612 # ffffffffc0202c98 <commands+0x9c0>
ffffffffc02012ec:	00001617          	auipc	a2,0x1
ffffffffc02012f0:	6fc60613          	addi	a2,a2,1788 # ffffffffc02029e8 <commands+0x710>
ffffffffc02012f4:	10e00593          	li	a1,270
ffffffffc02012f8:	00001517          	auipc	a0,0x1
ffffffffc02012fc:	70850513          	addi	a0,a0,1800 # ffffffffc0202a00 <commands+0x728>
ffffffffc0201300:	8f8ff0ef          	jal	ra,ffffffffc02003f8 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201304:	00002697          	auipc	a3,0x2
ffffffffc0201308:	96c68693          	addi	a3,a3,-1684 # ffffffffc0202c70 <commands+0x998>
ffffffffc020130c:	00001617          	auipc	a2,0x1
ffffffffc0201310:	6dc60613          	addi	a2,a2,1756 # ffffffffc02029e8 <commands+0x710>
ffffffffc0201314:	10d00593          	li	a1,269
ffffffffc0201318:	00001517          	auipc	a0,0x1
ffffffffc020131c:	6e850513          	addi	a0,a0,1768 # ffffffffc0202a00 <commands+0x728>
ffffffffc0201320:	8d8ff0ef          	jal	ra,ffffffffc02003f8 <__panic>
    assert(p0 + 2 == p1);
ffffffffc0201324:	00002697          	auipc	a3,0x2
ffffffffc0201328:	93c68693          	addi	a3,a3,-1732 # ffffffffc0202c60 <commands+0x988>
ffffffffc020132c:	00001617          	auipc	a2,0x1
ffffffffc0201330:	6bc60613          	addi	a2,a2,1724 # ffffffffc02029e8 <commands+0x710>
ffffffffc0201334:	10800593          	li	a1,264
ffffffffc0201338:	00001517          	auipc	a0,0x1
ffffffffc020133c:	6c850513          	addi	a0,a0,1736 # ffffffffc0202a00 <commands+0x728>
ffffffffc0201340:	8b8ff0ef          	jal	ra,ffffffffc02003f8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201344:	00002697          	auipc	a3,0x2
ffffffffc0201348:	81c68693          	addi	a3,a3,-2020 # ffffffffc0202b60 <commands+0x888>
ffffffffc020134c:	00001617          	auipc	a2,0x1
ffffffffc0201350:	69c60613          	addi	a2,a2,1692 # ffffffffc02029e8 <commands+0x710>
ffffffffc0201354:	10700593          	li	a1,263
ffffffffc0201358:	00001517          	auipc	a0,0x1
ffffffffc020135c:	6a850513          	addi	a0,a0,1704 # ffffffffc0202a00 <commands+0x728>
ffffffffc0201360:	898ff0ef          	jal	ra,ffffffffc02003f8 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201364:	00002697          	auipc	a3,0x2
ffffffffc0201368:	8dc68693          	addi	a3,a3,-1828 # ffffffffc0202c40 <commands+0x968>
ffffffffc020136c:	00001617          	auipc	a2,0x1
ffffffffc0201370:	67c60613          	addi	a2,a2,1660 # ffffffffc02029e8 <commands+0x710>
ffffffffc0201374:	10600593          	li	a1,262
ffffffffc0201378:	00001517          	auipc	a0,0x1
ffffffffc020137c:	68850513          	addi	a0,a0,1672 # ffffffffc0202a00 <commands+0x728>
ffffffffc0201380:	878ff0ef          	jal	ra,ffffffffc02003f8 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201384:	00002697          	auipc	a3,0x2
ffffffffc0201388:	88c68693          	addi	a3,a3,-1908 # ffffffffc0202c10 <commands+0x938>
ffffffffc020138c:	00001617          	auipc	a2,0x1
ffffffffc0201390:	65c60613          	addi	a2,a2,1628 # ffffffffc02029e8 <commands+0x710>
ffffffffc0201394:	10500593          	li	a1,261
ffffffffc0201398:	00001517          	auipc	a0,0x1
ffffffffc020139c:	66850513          	addi	a0,a0,1640 # ffffffffc0202a00 <commands+0x728>
ffffffffc02013a0:	858ff0ef          	jal	ra,ffffffffc02003f8 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc02013a4:	00002697          	auipc	a3,0x2
ffffffffc02013a8:	85468693          	addi	a3,a3,-1964 # ffffffffc0202bf8 <commands+0x920>
ffffffffc02013ac:	00001617          	auipc	a2,0x1
ffffffffc02013b0:	63c60613          	addi	a2,a2,1596 # ffffffffc02029e8 <commands+0x710>
ffffffffc02013b4:	10400593          	li	a1,260
ffffffffc02013b8:	00001517          	auipc	a0,0x1
ffffffffc02013bc:	64850513          	addi	a0,a0,1608 # ffffffffc0202a00 <commands+0x728>
ffffffffc02013c0:	838ff0ef          	jal	ra,ffffffffc02003f8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02013c4:	00001697          	auipc	a3,0x1
ffffffffc02013c8:	79c68693          	addi	a3,a3,1948 # ffffffffc0202b60 <commands+0x888>
ffffffffc02013cc:	00001617          	auipc	a2,0x1
ffffffffc02013d0:	61c60613          	addi	a2,a2,1564 # ffffffffc02029e8 <commands+0x710>
ffffffffc02013d4:	0fe00593          	li	a1,254
ffffffffc02013d8:	00001517          	auipc	a0,0x1
ffffffffc02013dc:	62850513          	addi	a0,a0,1576 # ffffffffc0202a00 <commands+0x728>
ffffffffc02013e0:	818ff0ef          	jal	ra,ffffffffc02003f8 <__panic>
    assert(!PageProperty(p0));
ffffffffc02013e4:	00001697          	auipc	a3,0x1
ffffffffc02013e8:	7fc68693          	addi	a3,a3,2044 # ffffffffc0202be0 <commands+0x908>
ffffffffc02013ec:	00001617          	auipc	a2,0x1
ffffffffc02013f0:	5fc60613          	addi	a2,a2,1532 # ffffffffc02029e8 <commands+0x710>
ffffffffc02013f4:	0f900593          	li	a1,249
ffffffffc02013f8:	00001517          	auipc	a0,0x1
ffffffffc02013fc:	60850513          	addi	a0,a0,1544 # ffffffffc0202a00 <commands+0x728>
ffffffffc0201400:	ff9fe0ef          	jal	ra,ffffffffc02003f8 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201404:	00002697          	auipc	a3,0x2
ffffffffc0201408:	8fc68693          	addi	a3,a3,-1796 # ffffffffc0202d00 <commands+0xa28>
ffffffffc020140c:	00001617          	auipc	a2,0x1
ffffffffc0201410:	5dc60613          	addi	a2,a2,1500 # ffffffffc02029e8 <commands+0x710>
ffffffffc0201414:	11700593          	li	a1,279
ffffffffc0201418:	00001517          	auipc	a0,0x1
ffffffffc020141c:	5e850513          	addi	a0,a0,1512 # ffffffffc0202a00 <commands+0x728>
ffffffffc0201420:	fd9fe0ef          	jal	ra,ffffffffc02003f8 <__panic>
    assert(total == 0);
ffffffffc0201424:	00002697          	auipc	a3,0x2
ffffffffc0201428:	90c68693          	addi	a3,a3,-1780 # ffffffffc0202d30 <commands+0xa58>
ffffffffc020142c:	00001617          	auipc	a2,0x1
ffffffffc0201430:	5bc60613          	addi	a2,a2,1468 # ffffffffc02029e8 <commands+0x710>
ffffffffc0201434:	12600593          	li	a1,294
ffffffffc0201438:	00001517          	auipc	a0,0x1
ffffffffc020143c:	5c850513          	addi	a0,a0,1480 # ffffffffc0202a00 <commands+0x728>
ffffffffc0201440:	fb9fe0ef          	jal	ra,ffffffffc02003f8 <__panic>
    assert(total == nr_free_pages());
ffffffffc0201444:	00001697          	auipc	a3,0x1
ffffffffc0201448:	5d468693          	addi	a3,a3,1492 # ffffffffc0202a18 <commands+0x740>
ffffffffc020144c:	00001617          	auipc	a2,0x1
ffffffffc0201450:	59c60613          	addi	a2,a2,1436 # ffffffffc02029e8 <commands+0x710>
ffffffffc0201454:	0f300593          	li	a1,243
ffffffffc0201458:	00001517          	auipc	a0,0x1
ffffffffc020145c:	5a850513          	addi	a0,a0,1448 # ffffffffc0202a00 <commands+0x728>
ffffffffc0201460:	f99fe0ef          	jal	ra,ffffffffc02003f8 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201464:	00001697          	auipc	a3,0x1
ffffffffc0201468:	5f468693          	addi	a3,a3,1524 # ffffffffc0202a58 <commands+0x780>
ffffffffc020146c:	00001617          	auipc	a2,0x1
ffffffffc0201470:	57c60613          	addi	a2,a2,1404 # ffffffffc02029e8 <commands+0x710>
ffffffffc0201474:	0ba00593          	li	a1,186
ffffffffc0201478:	00001517          	auipc	a0,0x1
ffffffffc020147c:	58850513          	addi	a0,a0,1416 # ffffffffc0202a00 <commands+0x728>
ffffffffc0201480:	f79fe0ef          	jal	ra,ffffffffc02003f8 <__panic>

ffffffffc0201484 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc0201484:	1141                	addi	sp,sp,-16
ffffffffc0201486:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201488:	14058a63          	beqz	a1,ffffffffc02015dc <default_free_pages+0x158>
    for (; p != base + n; p ++) {
ffffffffc020148c:	00259693          	slli	a3,a1,0x2
ffffffffc0201490:	96ae                	add	a3,a3,a1
ffffffffc0201492:	068e                	slli	a3,a3,0x3
ffffffffc0201494:	96aa                	add	a3,a3,a0
ffffffffc0201496:	87aa                	mv	a5,a0
ffffffffc0201498:	02d50263          	beq	a0,a3,ffffffffc02014bc <default_free_pages+0x38>
ffffffffc020149c:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020149e:	8b05                	andi	a4,a4,1
ffffffffc02014a0:	10071e63          	bnez	a4,ffffffffc02015bc <default_free_pages+0x138>
ffffffffc02014a4:	6798                	ld	a4,8(a5)
ffffffffc02014a6:	8b09                	andi	a4,a4,2
ffffffffc02014a8:	10071a63          	bnez	a4,ffffffffc02015bc <default_free_pages+0x138>
        p->flags = 0;
ffffffffc02014ac:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc02014b0:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02014b4:	02878793          	addi	a5,a5,40
ffffffffc02014b8:	fed792e3          	bne	a5,a3,ffffffffc020149c <default_free_pages+0x18>
    base->property = n;
ffffffffc02014bc:	2581                	sext.w	a1,a1
ffffffffc02014be:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc02014c0:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02014c4:	4789                	li	a5,2
ffffffffc02014c6:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc02014ca:	00006697          	auipc	a3,0x6
ffffffffc02014ce:	b5e68693          	addi	a3,a3,-1186 # ffffffffc0207028 <free_area>
ffffffffc02014d2:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02014d4:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02014d6:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02014da:	9db9                	addw	a1,a1,a4
ffffffffc02014dc:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc02014de:	0ad78863          	beq	a5,a3,ffffffffc020158e <default_free_pages+0x10a>
            struct Page* page = le2page(le, page_link);
ffffffffc02014e2:	fe878713          	addi	a4,a5,-24
ffffffffc02014e6:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc02014ea:	4581                	li	a1,0
            if (base < page) {
ffffffffc02014ec:	00e56a63          	bltu	a0,a4,ffffffffc0201500 <default_free_pages+0x7c>
    return listelm->next;
ffffffffc02014f0:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02014f2:	06d70263          	beq	a4,a3,ffffffffc0201556 <default_free_pages+0xd2>
    for (; p != base + n; p ++) {
ffffffffc02014f6:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02014f8:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc02014fc:	fee57ae3          	bgeu	a0,a4,ffffffffc02014f0 <default_free_pages+0x6c>
ffffffffc0201500:	c199                	beqz	a1,ffffffffc0201506 <default_free_pages+0x82>
ffffffffc0201502:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201506:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0201508:	e390                	sd	a2,0(a5)
ffffffffc020150a:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc020150c:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020150e:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc0201510:	02d70063          	beq	a4,a3,ffffffffc0201530 <default_free_pages+0xac>
        if (p + p->property == base) {
ffffffffc0201514:	ff872803          	lw	a6,-8(a4)
        p = le2page(le, page_link);
ffffffffc0201518:	fe870593          	addi	a1,a4,-24
        if (p + p->property == base) {
ffffffffc020151c:	02081613          	slli	a2,a6,0x20
ffffffffc0201520:	9201                	srli	a2,a2,0x20
ffffffffc0201522:	00261793          	slli	a5,a2,0x2
ffffffffc0201526:	97b2                	add	a5,a5,a2
ffffffffc0201528:	078e                	slli	a5,a5,0x3
ffffffffc020152a:	97ae                	add	a5,a5,a1
ffffffffc020152c:	02f50f63          	beq	a0,a5,ffffffffc020156a <default_free_pages+0xe6>
    return listelm->next;
ffffffffc0201530:	7118                	ld	a4,32(a0)
    if (le != &free_list) {
ffffffffc0201532:	00d70f63          	beq	a4,a3,ffffffffc0201550 <default_free_pages+0xcc>
        if (base + base->property == p) {
ffffffffc0201536:	490c                	lw	a1,16(a0)
        p = le2page(le, page_link);
ffffffffc0201538:	fe870693          	addi	a3,a4,-24
        if (base + base->property == p) {
ffffffffc020153c:	02059613          	slli	a2,a1,0x20
ffffffffc0201540:	9201                	srli	a2,a2,0x20
ffffffffc0201542:	00261793          	slli	a5,a2,0x2
ffffffffc0201546:	97b2                	add	a5,a5,a2
ffffffffc0201548:	078e                	slli	a5,a5,0x3
ffffffffc020154a:	97aa                	add	a5,a5,a0
ffffffffc020154c:	04f68863          	beq	a3,a5,ffffffffc020159c <default_free_pages+0x118>
}
ffffffffc0201550:	60a2                	ld	ra,8(sp)
ffffffffc0201552:	0141                	addi	sp,sp,16
ffffffffc0201554:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201556:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201558:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc020155a:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020155c:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc020155e:	02d70563          	beq	a4,a3,ffffffffc0201588 <default_free_pages+0x104>
    prev->next = next->prev = elm;
ffffffffc0201562:	8832                	mv	a6,a2
ffffffffc0201564:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc0201566:	87ba                	mv	a5,a4
ffffffffc0201568:	bf41                	j	ffffffffc02014f8 <default_free_pages+0x74>
            p->property += base->property;
ffffffffc020156a:	491c                	lw	a5,16(a0)
ffffffffc020156c:	0107883b          	addw	a6,a5,a6
ffffffffc0201570:	ff072c23          	sw	a6,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201574:	57f5                	li	a5,-3
ffffffffc0201576:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc020157a:	6d10                	ld	a2,24(a0)
ffffffffc020157c:	711c                	ld	a5,32(a0)
            base = p;
ffffffffc020157e:	852e                	mv	a0,a1
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0201580:	e61c                	sd	a5,8(a2)
    return listelm->next;
ffffffffc0201582:	6718                	ld	a4,8(a4)
    next->prev = prev;
ffffffffc0201584:	e390                	sd	a2,0(a5)
ffffffffc0201586:	b775                	j	ffffffffc0201532 <default_free_pages+0xae>
ffffffffc0201588:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list) {
ffffffffc020158a:	873e                	mv	a4,a5
ffffffffc020158c:	b761                	j	ffffffffc0201514 <default_free_pages+0x90>
}
ffffffffc020158e:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201590:	e390                	sd	a2,0(a5)
ffffffffc0201592:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201594:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201596:	ed1c                	sd	a5,24(a0)
ffffffffc0201598:	0141                	addi	sp,sp,16
ffffffffc020159a:	8082                	ret
            base->property += p->property;
ffffffffc020159c:	ff872783          	lw	a5,-8(a4)
ffffffffc02015a0:	ff070693          	addi	a3,a4,-16
ffffffffc02015a4:	9dbd                	addw	a1,a1,a5
ffffffffc02015a6:	c90c                	sw	a1,16(a0)
ffffffffc02015a8:	57f5                	li	a5,-3
ffffffffc02015aa:	60f6b02f          	amoand.d	zero,a5,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02015ae:	6314                	ld	a3,0(a4)
ffffffffc02015b0:	671c                	ld	a5,8(a4)
}
ffffffffc02015b2:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc02015b4:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc02015b6:	e394                	sd	a3,0(a5)
ffffffffc02015b8:	0141                	addi	sp,sp,16
ffffffffc02015ba:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02015bc:	00001697          	auipc	a3,0x1
ffffffffc02015c0:	78c68693          	addi	a3,a3,1932 # ffffffffc0202d48 <commands+0xa70>
ffffffffc02015c4:	00001617          	auipc	a2,0x1
ffffffffc02015c8:	42460613          	addi	a2,a2,1060 # ffffffffc02029e8 <commands+0x710>
ffffffffc02015cc:	08300593          	li	a1,131
ffffffffc02015d0:	00001517          	auipc	a0,0x1
ffffffffc02015d4:	43050513          	addi	a0,a0,1072 # ffffffffc0202a00 <commands+0x728>
ffffffffc02015d8:	e21fe0ef          	jal	ra,ffffffffc02003f8 <__panic>
    assert(n > 0);
ffffffffc02015dc:	00001697          	auipc	a3,0x1
ffffffffc02015e0:	76468693          	addi	a3,a3,1892 # ffffffffc0202d40 <commands+0xa68>
ffffffffc02015e4:	00001617          	auipc	a2,0x1
ffffffffc02015e8:	40460613          	addi	a2,a2,1028 # ffffffffc02029e8 <commands+0x710>
ffffffffc02015ec:	08000593          	li	a1,128
ffffffffc02015f0:	00001517          	auipc	a0,0x1
ffffffffc02015f4:	41050513          	addi	a0,a0,1040 # ffffffffc0202a00 <commands+0x728>
ffffffffc02015f8:	e01fe0ef          	jal	ra,ffffffffc02003f8 <__panic>

ffffffffc02015fc <default_alloc_pages>:
    assert(n > 0);
ffffffffc02015fc:	c959                	beqz	a0,ffffffffc0201692 <default_alloc_pages+0x96>
    if (n > nr_free) {
ffffffffc02015fe:	00006597          	auipc	a1,0x6
ffffffffc0201602:	a2a58593          	addi	a1,a1,-1494 # ffffffffc0207028 <free_area>
ffffffffc0201606:	0105a803          	lw	a6,16(a1)
ffffffffc020160a:	862a                	mv	a2,a0
ffffffffc020160c:	02081793          	slli	a5,a6,0x20
ffffffffc0201610:	9381                	srli	a5,a5,0x20
ffffffffc0201612:	00a7ee63          	bltu	a5,a0,ffffffffc020162e <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc0201616:	87ae                	mv	a5,a1
ffffffffc0201618:	a801                	j	ffffffffc0201628 <default_alloc_pages+0x2c>
        if (p->property >= n) {
ffffffffc020161a:	ff87a703          	lw	a4,-8(a5)
ffffffffc020161e:	02071693          	slli	a3,a4,0x20
ffffffffc0201622:	9281                	srli	a3,a3,0x20
ffffffffc0201624:	00c6f763          	bgeu	a3,a2,ffffffffc0201632 <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc0201628:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc020162a:	feb798e3          	bne	a5,a1,ffffffffc020161a <default_alloc_pages+0x1e>
        return NULL;
ffffffffc020162e:	4501                	li	a0,0
}
ffffffffc0201630:	8082                	ret
    return listelm->prev;
ffffffffc0201632:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201636:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc020163a:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc020163e:	00060e1b          	sext.w	t3,a2
    prev->next = next;
ffffffffc0201642:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc0201646:	01133023          	sd	a7,0(t1)
        if (page->property > n) {
ffffffffc020164a:	02d67b63          	bgeu	a2,a3,ffffffffc0201680 <default_alloc_pages+0x84>
            struct Page *p = page + n;
ffffffffc020164e:	00261693          	slli	a3,a2,0x2
ffffffffc0201652:	96b2                	add	a3,a3,a2
ffffffffc0201654:	068e                	slli	a3,a3,0x3
ffffffffc0201656:	96aa                	add	a3,a3,a0
            p->property = page->property - n;
ffffffffc0201658:	41c7073b          	subw	a4,a4,t3
ffffffffc020165c:	ca98                	sw	a4,16(a3)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020165e:	00868613          	addi	a2,a3,8
ffffffffc0201662:	4709                	li	a4,2
ffffffffc0201664:	40e6302f          	amoor.d	zero,a4,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc0201668:	0088b703          	ld	a4,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc020166c:	01868613          	addi	a2,a3,24
        nr_free -= n;
ffffffffc0201670:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc0201674:	e310                	sd	a2,0(a4)
ffffffffc0201676:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc020167a:	f298                	sd	a4,32(a3)
    elm->prev = prev;
ffffffffc020167c:	0116bc23          	sd	a7,24(a3)
ffffffffc0201680:	41c8083b          	subw	a6,a6,t3
ffffffffc0201684:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201688:	5775                	li	a4,-3
ffffffffc020168a:	17c1                	addi	a5,a5,-16
ffffffffc020168c:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0201690:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc0201692:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0201694:	00001697          	auipc	a3,0x1
ffffffffc0201698:	6ac68693          	addi	a3,a3,1708 # ffffffffc0202d40 <commands+0xa68>
ffffffffc020169c:	00001617          	auipc	a2,0x1
ffffffffc02016a0:	34c60613          	addi	a2,a2,844 # ffffffffc02029e8 <commands+0x710>
ffffffffc02016a4:	06200593          	li	a1,98
ffffffffc02016a8:	00001517          	auipc	a0,0x1
ffffffffc02016ac:	35850513          	addi	a0,a0,856 # ffffffffc0202a00 <commands+0x728>
default_alloc_pages(size_t n) {
ffffffffc02016b0:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02016b2:	d47fe0ef          	jal	ra,ffffffffc02003f8 <__panic>

ffffffffc02016b6 <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc02016b6:	1141                	addi	sp,sp,-16
ffffffffc02016b8:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02016ba:	c9e1                	beqz	a1,ffffffffc020178a <default_init_memmap+0xd4>
    for (; p != base + n; p ++) {
ffffffffc02016bc:	00259693          	slli	a3,a1,0x2
ffffffffc02016c0:	96ae                	add	a3,a3,a1
ffffffffc02016c2:	068e                	slli	a3,a3,0x3
ffffffffc02016c4:	96aa                	add	a3,a3,a0
ffffffffc02016c6:	87aa                	mv	a5,a0
ffffffffc02016c8:	00d50f63          	beq	a0,a3,ffffffffc02016e6 <default_init_memmap+0x30>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02016cc:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc02016ce:	8b05                	andi	a4,a4,1
ffffffffc02016d0:	cf49                	beqz	a4,ffffffffc020176a <default_init_memmap+0xb4>
        p->flags = p->property = 0;
ffffffffc02016d2:	0007a823          	sw	zero,16(a5)
ffffffffc02016d6:	0007b423          	sd	zero,8(a5)
ffffffffc02016da:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02016de:	02878793          	addi	a5,a5,40
ffffffffc02016e2:	fed795e3          	bne	a5,a3,ffffffffc02016cc <default_init_memmap+0x16>
    base->property = n;
ffffffffc02016e6:	2581                	sext.w	a1,a1
ffffffffc02016e8:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02016ea:	4789                	li	a5,2
ffffffffc02016ec:	00850713          	addi	a4,a0,8
ffffffffc02016f0:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc02016f4:	00006697          	auipc	a3,0x6
ffffffffc02016f8:	93468693          	addi	a3,a3,-1740 # ffffffffc0207028 <free_area>
ffffffffc02016fc:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02016fe:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201700:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0201704:	9db9                	addw	a1,a1,a4
ffffffffc0201706:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0201708:	04d78a63          	beq	a5,a3,ffffffffc020175c <default_init_memmap+0xa6>
            struct Page* page = le2page(le, page_link);
ffffffffc020170c:	fe878713          	addi	a4,a5,-24
ffffffffc0201710:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0201714:	4581                	li	a1,0
            if (base < page) {
ffffffffc0201716:	00e56a63          	bltu	a0,a4,ffffffffc020172a <default_init_memmap+0x74>
    return listelm->next;
ffffffffc020171a:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc020171c:	02d70263          	beq	a4,a3,ffffffffc0201740 <default_init_memmap+0x8a>
    for (; p != base + n; p ++) {
ffffffffc0201720:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201722:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0201726:	fee57ae3          	bgeu	a0,a4,ffffffffc020171a <default_init_memmap+0x64>
ffffffffc020172a:	c199                	beqz	a1,ffffffffc0201730 <default_init_memmap+0x7a>
ffffffffc020172c:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201730:	6398                	ld	a4,0(a5)
}
ffffffffc0201732:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201734:	e390                	sd	a2,0(a5)
ffffffffc0201736:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201738:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020173a:	ed18                	sd	a4,24(a0)
ffffffffc020173c:	0141                	addi	sp,sp,16
ffffffffc020173e:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201740:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201742:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201744:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201746:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201748:	00d70663          	beq	a4,a3,ffffffffc0201754 <default_init_memmap+0x9e>
    prev->next = next->prev = elm;
ffffffffc020174c:	8832                	mv	a6,a2
ffffffffc020174e:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc0201750:	87ba                	mv	a5,a4
ffffffffc0201752:	bfc1                	j	ffffffffc0201722 <default_init_memmap+0x6c>
}
ffffffffc0201754:	60a2                	ld	ra,8(sp)
ffffffffc0201756:	e290                	sd	a2,0(a3)
ffffffffc0201758:	0141                	addi	sp,sp,16
ffffffffc020175a:	8082                	ret
ffffffffc020175c:	60a2                	ld	ra,8(sp)
ffffffffc020175e:	e390                	sd	a2,0(a5)
ffffffffc0201760:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201762:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201764:	ed1c                	sd	a5,24(a0)
ffffffffc0201766:	0141                	addi	sp,sp,16
ffffffffc0201768:	8082                	ret
        assert(PageReserved(p));
ffffffffc020176a:	00001697          	auipc	a3,0x1
ffffffffc020176e:	60668693          	addi	a3,a3,1542 # ffffffffc0202d70 <commands+0xa98>
ffffffffc0201772:	00001617          	auipc	a2,0x1
ffffffffc0201776:	27660613          	addi	a2,a2,630 # ffffffffc02029e8 <commands+0x710>
ffffffffc020177a:	04900593          	li	a1,73
ffffffffc020177e:	00001517          	auipc	a0,0x1
ffffffffc0201782:	28250513          	addi	a0,a0,642 # ffffffffc0202a00 <commands+0x728>
ffffffffc0201786:	c73fe0ef          	jal	ra,ffffffffc02003f8 <__panic>
    assert(n > 0);
ffffffffc020178a:	00001697          	auipc	a3,0x1
ffffffffc020178e:	5b668693          	addi	a3,a3,1462 # ffffffffc0202d40 <commands+0xa68>
ffffffffc0201792:	00001617          	auipc	a2,0x1
ffffffffc0201796:	25660613          	addi	a2,a2,598 # ffffffffc02029e8 <commands+0x710>
ffffffffc020179a:	04600593          	li	a1,70
ffffffffc020179e:	00001517          	auipc	a0,0x1
ffffffffc02017a2:	26250513          	addi	a0,a0,610 # ffffffffc0202a00 <commands+0x728>
ffffffffc02017a6:	c53fe0ef          	jal	ra,ffffffffc02003f8 <__panic>

ffffffffc02017aa <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02017aa:	100027f3          	csrr	a5,sstatus
ffffffffc02017ae:	8b89                	andi	a5,a5,2
ffffffffc02017b0:	e799                	bnez	a5,ffffffffc02017be <alloc_pages+0x14>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc02017b2:	00006797          	auipc	a5,0x6
ffffffffc02017b6:	cc67b783          	ld	a5,-826(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc02017ba:	6f9c                	ld	a5,24(a5)
ffffffffc02017bc:	8782                	jr	a5
struct Page *alloc_pages(size_t n) {
ffffffffc02017be:	1141                	addi	sp,sp,-16
ffffffffc02017c0:	e406                	sd	ra,8(sp)
ffffffffc02017c2:	e022                	sd	s0,0(sp)
ffffffffc02017c4:	842a                	mv	s0,a0
        intr_disable();
ffffffffc02017c6:	894ff0ef          	jal	ra,ffffffffc020085a <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02017ca:	00006797          	auipc	a5,0x6
ffffffffc02017ce:	cae7b783          	ld	a5,-850(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc02017d2:	6f9c                	ld	a5,24(a5)
ffffffffc02017d4:	8522                	mv	a0,s0
ffffffffc02017d6:	9782                	jalr	a5
ffffffffc02017d8:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc02017da:	87aff0ef          	jal	ra,ffffffffc0200854 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc02017de:	60a2                	ld	ra,8(sp)
ffffffffc02017e0:	8522                	mv	a0,s0
ffffffffc02017e2:	6402                	ld	s0,0(sp)
ffffffffc02017e4:	0141                	addi	sp,sp,16
ffffffffc02017e6:	8082                	ret

ffffffffc02017e8 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02017e8:	100027f3          	csrr	a5,sstatus
ffffffffc02017ec:	8b89                	andi	a5,a5,2
ffffffffc02017ee:	e799                	bnez	a5,ffffffffc02017fc <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc02017f0:	00006797          	auipc	a5,0x6
ffffffffc02017f4:	c887b783          	ld	a5,-888(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc02017f8:	739c                	ld	a5,32(a5)
ffffffffc02017fa:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc02017fc:	1101                	addi	sp,sp,-32
ffffffffc02017fe:	ec06                	sd	ra,24(sp)
ffffffffc0201800:	e822                	sd	s0,16(sp)
ffffffffc0201802:	e426                	sd	s1,8(sp)
ffffffffc0201804:	842a                	mv	s0,a0
ffffffffc0201806:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201808:	852ff0ef          	jal	ra,ffffffffc020085a <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020180c:	00006797          	auipc	a5,0x6
ffffffffc0201810:	c6c7b783          	ld	a5,-916(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc0201814:	739c                	ld	a5,32(a5)
ffffffffc0201816:	85a6                	mv	a1,s1
ffffffffc0201818:	8522                	mv	a0,s0
ffffffffc020181a:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc020181c:	6442                	ld	s0,16(sp)
ffffffffc020181e:	60e2                	ld	ra,24(sp)
ffffffffc0201820:	64a2                	ld	s1,8(sp)
ffffffffc0201822:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201824:	830ff06f          	j	ffffffffc0200854 <intr_enable>

ffffffffc0201828 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201828:	100027f3          	csrr	a5,sstatus
ffffffffc020182c:	8b89                	andi	a5,a5,2
ffffffffc020182e:	e799                	bnez	a5,ffffffffc020183c <nr_free_pages+0x14>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201830:	00006797          	auipc	a5,0x6
ffffffffc0201834:	c487b783          	ld	a5,-952(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc0201838:	779c                	ld	a5,40(a5)
ffffffffc020183a:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc020183c:	1141                	addi	sp,sp,-16
ffffffffc020183e:	e406                	sd	ra,8(sp)
ffffffffc0201840:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201842:	818ff0ef          	jal	ra,ffffffffc020085a <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201846:	00006797          	auipc	a5,0x6
ffffffffc020184a:	c327b783          	ld	a5,-974(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc020184e:	779c                	ld	a5,40(a5)
ffffffffc0201850:	9782                	jalr	a5
ffffffffc0201852:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201854:	800ff0ef          	jal	ra,ffffffffc0200854 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201858:	60a2                	ld	ra,8(sp)
ffffffffc020185a:	8522                	mv	a0,s0
ffffffffc020185c:	6402                	ld	s0,0(sp)
ffffffffc020185e:	0141                	addi	sp,sp,16
ffffffffc0201860:	8082                	ret

ffffffffc0201862 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0201862:	00001797          	auipc	a5,0x1
ffffffffc0201866:	53678793          	addi	a5,a5,1334 # ffffffffc0202d98 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020186a:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc020186c:	7179                	addi	sp,sp,-48
ffffffffc020186e:	f022                	sd	s0,32(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201870:	00001517          	auipc	a0,0x1
ffffffffc0201874:	56050513          	addi	a0,a0,1376 # ffffffffc0202dd0 <default_pmm_manager+0x38>
    pmm_manager = &default_pmm_manager;
ffffffffc0201878:	00006417          	auipc	s0,0x6
ffffffffc020187c:	c0040413          	addi	s0,s0,-1024 # ffffffffc0207478 <pmm_manager>
void pmm_init(void) {
ffffffffc0201880:	f406                	sd	ra,40(sp)
ffffffffc0201882:	ec26                	sd	s1,24(sp)
ffffffffc0201884:	e44e                	sd	s3,8(sp)
ffffffffc0201886:	e84a                	sd	s2,16(sp)
ffffffffc0201888:	e052                	sd	s4,0(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc020188a:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020188c:	873fe0ef          	jal	ra,ffffffffc02000fe <cprintf>
    pmm_manager->init();
ffffffffc0201890:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201892:	00006497          	auipc	s1,0x6
ffffffffc0201896:	bfe48493          	addi	s1,s1,-1026 # ffffffffc0207490 <va_pa_offset>
    pmm_manager->init();
ffffffffc020189a:	679c                	ld	a5,8(a5)
ffffffffc020189c:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020189e:	57f5                	li	a5,-3
ffffffffc02018a0:	07fa                	slli	a5,a5,0x1e
ffffffffc02018a2:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc02018a4:	f9dfe0ef          	jal	ra,ffffffffc0200840 <get_memory_base>
ffffffffc02018a8:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc02018aa:	fa1fe0ef          	jal	ra,ffffffffc020084a <get_memory_size>
    if (mem_size == 0) {
ffffffffc02018ae:	16050163          	beqz	a0,ffffffffc0201a10 <pmm_init+0x1ae>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02018b2:	892a                	mv	s2,a0
    cprintf("physcial memory map:\n");
ffffffffc02018b4:	00001517          	auipc	a0,0x1
ffffffffc02018b8:	56450513          	addi	a0,a0,1380 # ffffffffc0202e18 <default_pmm_manager+0x80>
ffffffffc02018bc:	843fe0ef          	jal	ra,ffffffffc02000fe <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02018c0:	01298a33          	add	s4,s3,s2
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc02018c4:	864e                	mv	a2,s3
ffffffffc02018c6:	fffa0693          	addi	a3,s4,-1
ffffffffc02018ca:	85ca                	mv	a1,s2
ffffffffc02018cc:	00001517          	auipc	a0,0x1
ffffffffc02018d0:	56450513          	addi	a0,a0,1380 # ffffffffc0202e30 <default_pmm_manager+0x98>
ffffffffc02018d4:	82bfe0ef          	jal	ra,ffffffffc02000fe <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc02018d8:	c80007b7          	lui	a5,0xc8000
ffffffffc02018dc:	8652                	mv	a2,s4
ffffffffc02018de:	0d47e863          	bltu	a5,s4,ffffffffc02019ae <pmm_init+0x14c>
ffffffffc02018e2:	00007797          	auipc	a5,0x7
ffffffffc02018e6:	bbd78793          	addi	a5,a5,-1091 # ffffffffc020849f <end+0xfff>
ffffffffc02018ea:	757d                	lui	a0,0xfffff
ffffffffc02018ec:	8d7d                	and	a0,a0,a5
ffffffffc02018ee:	8231                	srli	a2,a2,0xc
ffffffffc02018f0:	00006597          	auipc	a1,0x6
ffffffffc02018f4:	b7858593          	addi	a1,a1,-1160 # ffffffffc0207468 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02018f8:	00006817          	auipc	a6,0x6
ffffffffc02018fc:	b7880813          	addi	a6,a6,-1160 # ffffffffc0207470 <pages>
    npage = maxpa / PGSIZE;
ffffffffc0201900:	e190                	sd	a2,0(a1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201902:	00a83023          	sd	a0,0(a6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201906:	000807b7          	lui	a5,0x80
ffffffffc020190a:	02f60663          	beq	a2,a5,ffffffffc0201936 <pmm_init+0xd4>
ffffffffc020190e:	4701                	li	a4,0
ffffffffc0201910:	4781                	li	a5,0
ffffffffc0201912:	4305                	li	t1,1
ffffffffc0201914:	fff808b7          	lui	a7,0xfff80
        SetPageReserved(pages + i);
ffffffffc0201918:	953a                	add	a0,a0,a4
ffffffffc020191a:	00850693          	addi	a3,a0,8 # fffffffffffff008 <end+0x3fdf7b68>
ffffffffc020191e:	4066b02f          	amoor.d	zero,t1,(a3)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201922:	6190                	ld	a2,0(a1)
ffffffffc0201924:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc0201926:	00083503          	ld	a0,0(a6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020192a:	011606b3          	add	a3,a2,a7
ffffffffc020192e:	02870713          	addi	a4,a4,40
ffffffffc0201932:	fed7e3e3          	bltu	a5,a3,ffffffffc0201918 <pmm_init+0xb6>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201936:	00261693          	slli	a3,a2,0x2
ffffffffc020193a:	96b2                	add	a3,a3,a2
ffffffffc020193c:	fec007b7          	lui	a5,0xfec00
ffffffffc0201940:	97aa                	add	a5,a5,a0
ffffffffc0201942:	068e                	slli	a3,a3,0x3
ffffffffc0201944:	96be                	add	a3,a3,a5
ffffffffc0201946:	c02007b7          	lui	a5,0xc0200
ffffffffc020194a:	0af6e763          	bltu	a3,a5,ffffffffc02019f8 <pmm_init+0x196>
ffffffffc020194e:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0201950:	77fd                	lui	a5,0xfffff
ffffffffc0201952:	00fa75b3          	and	a1,s4,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201956:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc0201958:	04b6ee63          	bltu	a3,a1,ffffffffc02019b4 <pmm_init+0x152>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc020195c:	601c                	ld	a5,0(s0)
ffffffffc020195e:	7b9c                	ld	a5,48(a5)
ffffffffc0201960:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0201962:	00001517          	auipc	a0,0x1
ffffffffc0201966:	55650513          	addi	a0,a0,1366 # ffffffffc0202eb8 <default_pmm_manager+0x120>
ffffffffc020196a:	f94fe0ef          	jal	ra,ffffffffc02000fe <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc020196e:	00004597          	auipc	a1,0x4
ffffffffc0201972:	69258593          	addi	a1,a1,1682 # ffffffffc0206000 <boot_page_table_sv39>
ffffffffc0201976:	00006797          	auipc	a5,0x6
ffffffffc020197a:	b0b7b923          	sd	a1,-1262(a5) # ffffffffc0207488 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc020197e:	c02007b7          	lui	a5,0xc0200
ffffffffc0201982:	0af5e363          	bltu	a1,a5,ffffffffc0201a28 <pmm_init+0x1c6>
ffffffffc0201986:	6090                	ld	a2,0(s1)
}
ffffffffc0201988:	7402                	ld	s0,32(sp)
ffffffffc020198a:	70a2                	ld	ra,40(sp)
ffffffffc020198c:	64e2                	ld	s1,24(sp)
ffffffffc020198e:	6942                	ld	s2,16(sp)
ffffffffc0201990:	69a2                	ld	s3,8(sp)
ffffffffc0201992:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0201994:	40c58633          	sub	a2,a1,a2
ffffffffc0201998:	00006797          	auipc	a5,0x6
ffffffffc020199c:	aec7b423          	sd	a2,-1304(a5) # ffffffffc0207480 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02019a0:	00001517          	auipc	a0,0x1
ffffffffc02019a4:	53850513          	addi	a0,a0,1336 # ffffffffc0202ed8 <default_pmm_manager+0x140>
}
ffffffffc02019a8:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02019aa:	f54fe06f          	j	ffffffffc02000fe <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc02019ae:	c8000637          	lui	a2,0xc8000
ffffffffc02019b2:	bf05                	j	ffffffffc02018e2 <pmm_init+0x80>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc02019b4:	6705                	lui	a4,0x1
ffffffffc02019b6:	177d                	addi	a4,a4,-1
ffffffffc02019b8:	96ba                	add	a3,a3,a4
ffffffffc02019ba:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc02019bc:	00c6d793          	srli	a5,a3,0xc
ffffffffc02019c0:	02c7f063          	bgeu	a5,a2,ffffffffc02019e0 <pmm_init+0x17e>
    pmm_manager->init_memmap(base, n);
ffffffffc02019c4:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc02019c6:	fff80737          	lui	a4,0xfff80
ffffffffc02019ca:	973e                	add	a4,a4,a5
ffffffffc02019cc:	00271793          	slli	a5,a4,0x2
ffffffffc02019d0:	97ba                	add	a5,a5,a4
ffffffffc02019d2:	6a18                	ld	a4,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc02019d4:	8d95                	sub	a1,a1,a3
ffffffffc02019d6:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc02019d8:	81b1                	srli	a1,a1,0xc
ffffffffc02019da:	953e                	add	a0,a0,a5
ffffffffc02019dc:	9702                	jalr	a4
}
ffffffffc02019de:	bfbd                	j	ffffffffc020195c <pmm_init+0xfa>
        panic("pa2page called with invalid pa");
ffffffffc02019e0:	00001617          	auipc	a2,0x1
ffffffffc02019e4:	4a860613          	addi	a2,a2,1192 # ffffffffc0202e88 <default_pmm_manager+0xf0>
ffffffffc02019e8:	06b00593          	li	a1,107
ffffffffc02019ec:	00001517          	auipc	a0,0x1
ffffffffc02019f0:	4bc50513          	addi	a0,a0,1212 # ffffffffc0202ea8 <default_pmm_manager+0x110>
ffffffffc02019f4:	a05fe0ef          	jal	ra,ffffffffc02003f8 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02019f8:	00001617          	auipc	a2,0x1
ffffffffc02019fc:	46860613          	addi	a2,a2,1128 # ffffffffc0202e60 <default_pmm_manager+0xc8>
ffffffffc0201a00:	07100593          	li	a1,113
ffffffffc0201a04:	00001517          	auipc	a0,0x1
ffffffffc0201a08:	40450513          	addi	a0,a0,1028 # ffffffffc0202e08 <default_pmm_manager+0x70>
ffffffffc0201a0c:	9edfe0ef          	jal	ra,ffffffffc02003f8 <__panic>
        panic("DTB memory info not available");
ffffffffc0201a10:	00001617          	auipc	a2,0x1
ffffffffc0201a14:	3d860613          	addi	a2,a2,984 # ffffffffc0202de8 <default_pmm_manager+0x50>
ffffffffc0201a18:	05a00593          	li	a1,90
ffffffffc0201a1c:	00001517          	auipc	a0,0x1
ffffffffc0201a20:	3ec50513          	addi	a0,a0,1004 # ffffffffc0202e08 <default_pmm_manager+0x70>
ffffffffc0201a24:	9d5fe0ef          	jal	ra,ffffffffc02003f8 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201a28:	86ae                	mv	a3,a1
ffffffffc0201a2a:	00001617          	auipc	a2,0x1
ffffffffc0201a2e:	43660613          	addi	a2,a2,1078 # ffffffffc0202e60 <default_pmm_manager+0xc8>
ffffffffc0201a32:	08c00593          	li	a1,140
ffffffffc0201a36:	00001517          	auipc	a0,0x1
ffffffffc0201a3a:	3d250513          	addi	a0,a0,978 # ffffffffc0202e08 <default_pmm_manager+0x70>
ffffffffc0201a3e:	9bbfe0ef          	jal	ra,ffffffffc02003f8 <__panic>

ffffffffc0201a42 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201a42:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201a46:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0201a48:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201a4c:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0201a4e:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201a52:	f022                	sd	s0,32(sp)
ffffffffc0201a54:	ec26                	sd	s1,24(sp)
ffffffffc0201a56:	e84a                	sd	s2,16(sp)
ffffffffc0201a58:	f406                	sd	ra,40(sp)
ffffffffc0201a5a:	e44e                	sd	s3,8(sp)
ffffffffc0201a5c:	84aa                	mv	s1,a0
ffffffffc0201a5e:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0201a60:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0201a64:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0201a66:	03067e63          	bgeu	a2,a6,ffffffffc0201aa2 <printnum+0x60>
ffffffffc0201a6a:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0201a6c:	00805763          	blez	s0,ffffffffc0201a7a <printnum+0x38>
ffffffffc0201a70:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201a72:	85ca                	mv	a1,s2
ffffffffc0201a74:	854e                	mv	a0,s3
ffffffffc0201a76:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201a78:	fc65                	bnez	s0,ffffffffc0201a70 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a7a:	1a02                	slli	s4,s4,0x20
ffffffffc0201a7c:	00001797          	auipc	a5,0x1
ffffffffc0201a80:	49c78793          	addi	a5,a5,1180 # ffffffffc0202f18 <default_pmm_manager+0x180>
ffffffffc0201a84:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201a88:	9a3e                	add	s4,s4,a5
}
ffffffffc0201a8a:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a8c:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0201a90:	70a2                	ld	ra,40(sp)
ffffffffc0201a92:	69a2                	ld	s3,8(sp)
ffffffffc0201a94:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a96:	85ca                	mv	a1,s2
ffffffffc0201a98:	87a6                	mv	a5,s1
}
ffffffffc0201a9a:	6942                	ld	s2,16(sp)
ffffffffc0201a9c:	64e2                	ld	s1,24(sp)
ffffffffc0201a9e:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201aa0:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201aa2:	03065633          	divu	a2,a2,a6
ffffffffc0201aa6:	8722                	mv	a4,s0
ffffffffc0201aa8:	f9bff0ef          	jal	ra,ffffffffc0201a42 <printnum>
ffffffffc0201aac:	b7f9                	j	ffffffffc0201a7a <printnum+0x38>

ffffffffc0201aae <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201aae:	7119                	addi	sp,sp,-128
ffffffffc0201ab0:	f4a6                	sd	s1,104(sp)
ffffffffc0201ab2:	f0ca                	sd	s2,96(sp)
ffffffffc0201ab4:	ecce                	sd	s3,88(sp)
ffffffffc0201ab6:	e8d2                	sd	s4,80(sp)
ffffffffc0201ab8:	e4d6                	sd	s5,72(sp)
ffffffffc0201aba:	e0da                	sd	s6,64(sp)
ffffffffc0201abc:	fc5e                	sd	s7,56(sp)
ffffffffc0201abe:	f06a                	sd	s10,32(sp)
ffffffffc0201ac0:	fc86                	sd	ra,120(sp)
ffffffffc0201ac2:	f8a2                	sd	s0,112(sp)
ffffffffc0201ac4:	f862                	sd	s8,48(sp)
ffffffffc0201ac6:	f466                	sd	s9,40(sp)
ffffffffc0201ac8:	ec6e                	sd	s11,24(sp)
ffffffffc0201aca:	892a                	mv	s2,a0
ffffffffc0201acc:	84ae                	mv	s1,a1
ffffffffc0201ace:	8d32                	mv	s10,a2
ffffffffc0201ad0:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201ad2:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0201ad6:	5b7d                	li	s6,-1
ffffffffc0201ad8:	00001a97          	auipc	s5,0x1
ffffffffc0201adc:	474a8a93          	addi	s5,s5,1140 # ffffffffc0202f4c <default_pmm_manager+0x1b4>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201ae0:	00001b97          	auipc	s7,0x1
ffffffffc0201ae4:	648b8b93          	addi	s7,s7,1608 # ffffffffc0203128 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201ae8:	000d4503          	lbu	a0,0(s10)
ffffffffc0201aec:	001d0413          	addi	s0,s10,1
ffffffffc0201af0:	01350a63          	beq	a0,s3,ffffffffc0201b04 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0201af4:	c121                	beqz	a0,ffffffffc0201b34 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0201af6:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201af8:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201afa:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201afc:	fff44503          	lbu	a0,-1(s0)
ffffffffc0201b00:	ff351ae3          	bne	a0,s3,ffffffffc0201af4 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b04:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201b08:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201b0c:	4c81                	li	s9,0
ffffffffc0201b0e:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0201b10:	5c7d                	li	s8,-1
ffffffffc0201b12:	5dfd                	li	s11,-1
ffffffffc0201b14:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0201b18:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b1a:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201b1e:	0ff5f593          	zext.b	a1,a1
ffffffffc0201b22:	00140d13          	addi	s10,s0,1
ffffffffc0201b26:	04b56263          	bltu	a0,a1,ffffffffc0201b6a <vprintfmt+0xbc>
ffffffffc0201b2a:	058a                	slli	a1,a1,0x2
ffffffffc0201b2c:	95d6                	add	a1,a1,s5
ffffffffc0201b2e:	4194                	lw	a3,0(a1)
ffffffffc0201b30:	96d6                	add	a3,a3,s5
ffffffffc0201b32:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201b34:	70e6                	ld	ra,120(sp)
ffffffffc0201b36:	7446                	ld	s0,112(sp)
ffffffffc0201b38:	74a6                	ld	s1,104(sp)
ffffffffc0201b3a:	7906                	ld	s2,96(sp)
ffffffffc0201b3c:	69e6                	ld	s3,88(sp)
ffffffffc0201b3e:	6a46                	ld	s4,80(sp)
ffffffffc0201b40:	6aa6                	ld	s5,72(sp)
ffffffffc0201b42:	6b06                	ld	s6,64(sp)
ffffffffc0201b44:	7be2                	ld	s7,56(sp)
ffffffffc0201b46:	7c42                	ld	s8,48(sp)
ffffffffc0201b48:	7ca2                	ld	s9,40(sp)
ffffffffc0201b4a:	7d02                	ld	s10,32(sp)
ffffffffc0201b4c:	6de2                	ld	s11,24(sp)
ffffffffc0201b4e:	6109                	addi	sp,sp,128
ffffffffc0201b50:	8082                	ret
            padc = '0';
ffffffffc0201b52:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0201b54:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b58:	846a                	mv	s0,s10
ffffffffc0201b5a:	00140d13          	addi	s10,s0,1
ffffffffc0201b5e:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201b62:	0ff5f593          	zext.b	a1,a1
ffffffffc0201b66:	fcb572e3          	bgeu	a0,a1,ffffffffc0201b2a <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0201b6a:	85a6                	mv	a1,s1
ffffffffc0201b6c:	02500513          	li	a0,37
ffffffffc0201b70:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201b72:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201b76:	8d22                	mv	s10,s0
ffffffffc0201b78:	f73788e3          	beq	a5,s3,ffffffffc0201ae8 <vprintfmt+0x3a>
ffffffffc0201b7c:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0201b80:	1d7d                	addi	s10,s10,-1
ffffffffc0201b82:	ff379de3          	bne	a5,s3,ffffffffc0201b7c <vprintfmt+0xce>
ffffffffc0201b86:	b78d                	j	ffffffffc0201ae8 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0201b88:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0201b8c:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b90:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201b92:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0201b96:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201b9a:	02d86463          	bltu	a6,a3,ffffffffc0201bc2 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0201b9e:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201ba2:	002c169b          	slliw	a3,s8,0x2
ffffffffc0201ba6:	0186873b          	addw	a4,a3,s8
ffffffffc0201baa:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201bae:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0201bb0:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201bb4:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201bb6:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0201bba:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201bbe:	fed870e3          	bgeu	a6,a3,ffffffffc0201b9e <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0201bc2:	f40ddce3          	bgez	s11,ffffffffc0201b1a <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0201bc6:	8de2                	mv	s11,s8
ffffffffc0201bc8:	5c7d                	li	s8,-1
ffffffffc0201bca:	bf81                	j	ffffffffc0201b1a <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0201bcc:	fffdc693          	not	a3,s11
ffffffffc0201bd0:	96fd                	srai	a3,a3,0x3f
ffffffffc0201bd2:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201bd6:	00144603          	lbu	a2,1(s0)
ffffffffc0201bda:	2d81                	sext.w	s11,s11
ffffffffc0201bdc:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201bde:	bf35                	j	ffffffffc0201b1a <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0201be0:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201be4:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0201be8:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201bea:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0201bec:	bfd9                	j	ffffffffc0201bc2 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0201bee:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201bf0:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201bf4:	01174463          	blt	a4,a7,ffffffffc0201bfc <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0201bf8:	1a088e63          	beqz	a7,ffffffffc0201db4 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0201bfc:	000a3603          	ld	a2,0(s4)
ffffffffc0201c00:	46c1                	li	a3,16
ffffffffc0201c02:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201c04:	2781                	sext.w	a5,a5
ffffffffc0201c06:	876e                	mv	a4,s11
ffffffffc0201c08:	85a6                	mv	a1,s1
ffffffffc0201c0a:	854a                	mv	a0,s2
ffffffffc0201c0c:	e37ff0ef          	jal	ra,ffffffffc0201a42 <printnum>
            break;
ffffffffc0201c10:	bde1                	j	ffffffffc0201ae8 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0201c12:	000a2503          	lw	a0,0(s4)
ffffffffc0201c16:	85a6                	mv	a1,s1
ffffffffc0201c18:	0a21                	addi	s4,s4,8
ffffffffc0201c1a:	9902                	jalr	s2
            break;
ffffffffc0201c1c:	b5f1                	j	ffffffffc0201ae8 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201c1e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201c20:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201c24:	01174463          	blt	a4,a7,ffffffffc0201c2c <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0201c28:	18088163          	beqz	a7,ffffffffc0201daa <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0201c2c:	000a3603          	ld	a2,0(s4)
ffffffffc0201c30:	46a9                	li	a3,10
ffffffffc0201c32:	8a2e                	mv	s4,a1
ffffffffc0201c34:	bfc1                	j	ffffffffc0201c04 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c36:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201c3a:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c3c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201c3e:	bdf1                	j	ffffffffc0201b1a <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0201c40:	85a6                	mv	a1,s1
ffffffffc0201c42:	02500513          	li	a0,37
ffffffffc0201c46:	9902                	jalr	s2
            break;
ffffffffc0201c48:	b545                	j	ffffffffc0201ae8 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c4a:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0201c4e:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c50:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201c52:	b5e1                	j	ffffffffc0201b1a <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0201c54:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201c56:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201c5a:	01174463          	blt	a4,a7,ffffffffc0201c62 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0201c5e:	14088163          	beqz	a7,ffffffffc0201da0 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0201c62:	000a3603          	ld	a2,0(s4)
ffffffffc0201c66:	46a1                	li	a3,8
ffffffffc0201c68:	8a2e                	mv	s4,a1
ffffffffc0201c6a:	bf69                	j	ffffffffc0201c04 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0201c6c:	03000513          	li	a0,48
ffffffffc0201c70:	85a6                	mv	a1,s1
ffffffffc0201c72:	e03e                	sd	a5,0(sp)
ffffffffc0201c74:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201c76:	85a6                	mv	a1,s1
ffffffffc0201c78:	07800513          	li	a0,120
ffffffffc0201c7c:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201c7e:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201c80:	6782                	ld	a5,0(sp)
ffffffffc0201c82:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201c84:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0201c88:	bfb5                	j	ffffffffc0201c04 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201c8a:	000a3403          	ld	s0,0(s4)
ffffffffc0201c8e:	008a0713          	addi	a4,s4,8
ffffffffc0201c92:	e03a                	sd	a4,0(sp)
ffffffffc0201c94:	14040263          	beqz	s0,ffffffffc0201dd8 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0201c98:	0fb05763          	blez	s11,ffffffffc0201d86 <vprintfmt+0x2d8>
ffffffffc0201c9c:	02d00693          	li	a3,45
ffffffffc0201ca0:	0cd79163          	bne	a5,a3,ffffffffc0201d62 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201ca4:	00044783          	lbu	a5,0(s0)
ffffffffc0201ca8:	0007851b          	sext.w	a0,a5
ffffffffc0201cac:	cf85                	beqz	a5,ffffffffc0201ce4 <vprintfmt+0x236>
ffffffffc0201cae:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201cb2:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201cb6:	000c4563          	bltz	s8,ffffffffc0201cc0 <vprintfmt+0x212>
ffffffffc0201cba:	3c7d                	addiw	s8,s8,-1
ffffffffc0201cbc:	036c0263          	beq	s8,s6,ffffffffc0201ce0 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0201cc0:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201cc2:	0e0c8e63          	beqz	s9,ffffffffc0201dbe <vprintfmt+0x310>
ffffffffc0201cc6:	3781                	addiw	a5,a5,-32
ffffffffc0201cc8:	0ef47b63          	bgeu	s0,a5,ffffffffc0201dbe <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0201ccc:	03f00513          	li	a0,63
ffffffffc0201cd0:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201cd2:	000a4783          	lbu	a5,0(s4)
ffffffffc0201cd6:	3dfd                	addiw	s11,s11,-1
ffffffffc0201cd8:	0a05                	addi	s4,s4,1
ffffffffc0201cda:	0007851b          	sext.w	a0,a5
ffffffffc0201cde:	ffe1                	bnez	a5,ffffffffc0201cb6 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0201ce0:	01b05963          	blez	s11,ffffffffc0201cf2 <vprintfmt+0x244>
ffffffffc0201ce4:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201ce6:	85a6                	mv	a1,s1
ffffffffc0201ce8:	02000513          	li	a0,32
ffffffffc0201cec:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201cee:	fe0d9be3          	bnez	s11,ffffffffc0201ce4 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201cf2:	6a02                	ld	s4,0(sp)
ffffffffc0201cf4:	bbd5                	j	ffffffffc0201ae8 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201cf6:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201cf8:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0201cfc:	01174463          	blt	a4,a7,ffffffffc0201d04 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0201d00:	08088d63          	beqz	a7,ffffffffc0201d9a <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0201d04:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201d08:	0a044d63          	bltz	s0,ffffffffc0201dc2 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0201d0c:	8622                	mv	a2,s0
ffffffffc0201d0e:	8a66                	mv	s4,s9
ffffffffc0201d10:	46a9                	li	a3,10
ffffffffc0201d12:	bdcd                	j	ffffffffc0201c04 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0201d14:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201d18:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201d1a:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201d1c:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201d20:	8fb5                	xor	a5,a5,a3
ffffffffc0201d22:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201d26:	02d74163          	blt	a4,a3,ffffffffc0201d48 <vprintfmt+0x29a>
ffffffffc0201d2a:	00369793          	slli	a5,a3,0x3
ffffffffc0201d2e:	97de                	add	a5,a5,s7
ffffffffc0201d30:	639c                	ld	a5,0(a5)
ffffffffc0201d32:	cb99                	beqz	a5,ffffffffc0201d48 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201d34:	86be                	mv	a3,a5
ffffffffc0201d36:	00001617          	auipc	a2,0x1
ffffffffc0201d3a:	21260613          	addi	a2,a2,530 # ffffffffc0202f48 <default_pmm_manager+0x1b0>
ffffffffc0201d3e:	85a6                	mv	a1,s1
ffffffffc0201d40:	854a                	mv	a0,s2
ffffffffc0201d42:	0ce000ef          	jal	ra,ffffffffc0201e10 <printfmt>
ffffffffc0201d46:	b34d                	j	ffffffffc0201ae8 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201d48:	00001617          	auipc	a2,0x1
ffffffffc0201d4c:	1f060613          	addi	a2,a2,496 # ffffffffc0202f38 <default_pmm_manager+0x1a0>
ffffffffc0201d50:	85a6                	mv	a1,s1
ffffffffc0201d52:	854a                	mv	a0,s2
ffffffffc0201d54:	0bc000ef          	jal	ra,ffffffffc0201e10 <printfmt>
ffffffffc0201d58:	bb41                	j	ffffffffc0201ae8 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201d5a:	00001417          	auipc	s0,0x1
ffffffffc0201d5e:	1d640413          	addi	s0,s0,470 # ffffffffc0202f30 <default_pmm_manager+0x198>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201d62:	85e2                	mv	a1,s8
ffffffffc0201d64:	8522                	mv	a0,s0
ffffffffc0201d66:	e43e                	sd	a5,8(sp)
ffffffffc0201d68:	200000ef          	jal	ra,ffffffffc0201f68 <strnlen>
ffffffffc0201d6c:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201d70:	01b05b63          	blez	s11,ffffffffc0201d86 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0201d74:	67a2                	ld	a5,8(sp)
ffffffffc0201d76:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201d7a:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201d7c:	85a6                	mv	a1,s1
ffffffffc0201d7e:	8552                	mv	a0,s4
ffffffffc0201d80:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201d82:	fe0d9ce3          	bnez	s11,ffffffffc0201d7a <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201d86:	00044783          	lbu	a5,0(s0)
ffffffffc0201d8a:	00140a13          	addi	s4,s0,1
ffffffffc0201d8e:	0007851b          	sext.w	a0,a5
ffffffffc0201d92:	d3a5                	beqz	a5,ffffffffc0201cf2 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201d94:	05e00413          	li	s0,94
ffffffffc0201d98:	bf39                	j	ffffffffc0201cb6 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0201d9a:	000a2403          	lw	s0,0(s4)
ffffffffc0201d9e:	b7ad                	j	ffffffffc0201d08 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0201da0:	000a6603          	lwu	a2,0(s4)
ffffffffc0201da4:	46a1                	li	a3,8
ffffffffc0201da6:	8a2e                	mv	s4,a1
ffffffffc0201da8:	bdb1                	j	ffffffffc0201c04 <vprintfmt+0x156>
ffffffffc0201daa:	000a6603          	lwu	a2,0(s4)
ffffffffc0201dae:	46a9                	li	a3,10
ffffffffc0201db0:	8a2e                	mv	s4,a1
ffffffffc0201db2:	bd89                	j	ffffffffc0201c04 <vprintfmt+0x156>
ffffffffc0201db4:	000a6603          	lwu	a2,0(s4)
ffffffffc0201db8:	46c1                	li	a3,16
ffffffffc0201dba:	8a2e                	mv	s4,a1
ffffffffc0201dbc:	b5a1                	j	ffffffffc0201c04 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0201dbe:	9902                	jalr	s2
ffffffffc0201dc0:	bf09                	j	ffffffffc0201cd2 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0201dc2:	85a6                	mv	a1,s1
ffffffffc0201dc4:	02d00513          	li	a0,45
ffffffffc0201dc8:	e03e                	sd	a5,0(sp)
ffffffffc0201dca:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201dcc:	6782                	ld	a5,0(sp)
ffffffffc0201dce:	8a66                	mv	s4,s9
ffffffffc0201dd0:	40800633          	neg	a2,s0
ffffffffc0201dd4:	46a9                	li	a3,10
ffffffffc0201dd6:	b53d                	j	ffffffffc0201c04 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0201dd8:	03b05163          	blez	s11,ffffffffc0201dfa <vprintfmt+0x34c>
ffffffffc0201ddc:	02d00693          	li	a3,45
ffffffffc0201de0:	f6d79de3          	bne	a5,a3,ffffffffc0201d5a <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0201de4:	00001417          	auipc	s0,0x1
ffffffffc0201de8:	14c40413          	addi	s0,s0,332 # ffffffffc0202f30 <default_pmm_manager+0x198>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201dec:	02800793          	li	a5,40
ffffffffc0201df0:	02800513          	li	a0,40
ffffffffc0201df4:	00140a13          	addi	s4,s0,1
ffffffffc0201df8:	bd6d                	j	ffffffffc0201cb2 <vprintfmt+0x204>
ffffffffc0201dfa:	00001a17          	auipc	s4,0x1
ffffffffc0201dfe:	137a0a13          	addi	s4,s4,311 # ffffffffc0202f31 <default_pmm_manager+0x199>
ffffffffc0201e02:	02800513          	li	a0,40
ffffffffc0201e06:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201e0a:	05e00413          	li	s0,94
ffffffffc0201e0e:	b565                	j	ffffffffc0201cb6 <vprintfmt+0x208>

ffffffffc0201e10 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201e10:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201e12:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201e16:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201e18:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201e1a:	ec06                	sd	ra,24(sp)
ffffffffc0201e1c:	f83a                	sd	a4,48(sp)
ffffffffc0201e1e:	fc3e                	sd	a5,56(sp)
ffffffffc0201e20:	e0c2                	sd	a6,64(sp)
ffffffffc0201e22:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201e24:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201e26:	c89ff0ef          	jal	ra,ffffffffc0201aae <vprintfmt>
}
ffffffffc0201e2a:	60e2                	ld	ra,24(sp)
ffffffffc0201e2c:	6161                	addi	sp,sp,80
ffffffffc0201e2e:	8082                	ret

ffffffffc0201e30 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0201e30:	715d                	addi	sp,sp,-80
ffffffffc0201e32:	e486                	sd	ra,72(sp)
ffffffffc0201e34:	e0a6                	sd	s1,64(sp)
ffffffffc0201e36:	fc4a                	sd	s2,56(sp)
ffffffffc0201e38:	f84e                	sd	s3,48(sp)
ffffffffc0201e3a:	f452                	sd	s4,40(sp)
ffffffffc0201e3c:	f056                	sd	s5,32(sp)
ffffffffc0201e3e:	ec5a                	sd	s6,24(sp)
ffffffffc0201e40:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc0201e42:	c901                	beqz	a0,ffffffffc0201e52 <readline+0x22>
ffffffffc0201e44:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc0201e46:	00001517          	auipc	a0,0x1
ffffffffc0201e4a:	10250513          	addi	a0,a0,258 # ffffffffc0202f48 <default_pmm_manager+0x1b0>
ffffffffc0201e4e:	ab0fe0ef          	jal	ra,ffffffffc02000fe <cprintf>
readline(const char *prompt) {
ffffffffc0201e52:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201e54:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0201e56:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0201e58:	4aa9                	li	s5,10
ffffffffc0201e5a:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0201e5c:	00005b97          	auipc	s7,0x5
ffffffffc0201e60:	1e4b8b93          	addi	s7,s7,484 # ffffffffc0207040 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201e64:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc0201e68:	b0efe0ef          	jal	ra,ffffffffc0200176 <getchar>
        if (c < 0) {
ffffffffc0201e6c:	00054a63          	bltz	a0,ffffffffc0201e80 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201e70:	00a95a63          	bge	s2,a0,ffffffffc0201e84 <readline+0x54>
ffffffffc0201e74:	029a5263          	bge	s4,s1,ffffffffc0201e98 <readline+0x68>
        c = getchar();
ffffffffc0201e78:	afefe0ef          	jal	ra,ffffffffc0200176 <getchar>
        if (c < 0) {
ffffffffc0201e7c:	fe055ae3          	bgez	a0,ffffffffc0201e70 <readline+0x40>
            return NULL;
ffffffffc0201e80:	4501                	li	a0,0
ffffffffc0201e82:	a091                	j	ffffffffc0201ec6 <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc0201e84:	03351463          	bne	a0,s3,ffffffffc0201eac <readline+0x7c>
ffffffffc0201e88:	e8a9                	bnez	s1,ffffffffc0201eda <readline+0xaa>
        c = getchar();
ffffffffc0201e8a:	aecfe0ef          	jal	ra,ffffffffc0200176 <getchar>
        if (c < 0) {
ffffffffc0201e8e:	fe0549e3          	bltz	a0,ffffffffc0201e80 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201e92:	fea959e3          	bge	s2,a0,ffffffffc0201e84 <readline+0x54>
ffffffffc0201e96:	4481                	li	s1,0
            cputchar(c);
ffffffffc0201e98:	e42a                	sd	a0,8(sp)
ffffffffc0201e9a:	a9afe0ef          	jal	ra,ffffffffc0200134 <cputchar>
            buf[i ++] = c;
ffffffffc0201e9e:	6522                	ld	a0,8(sp)
ffffffffc0201ea0:	009b87b3          	add	a5,s7,s1
ffffffffc0201ea4:	2485                	addiw	s1,s1,1
ffffffffc0201ea6:	00a78023          	sb	a0,0(a5)
ffffffffc0201eaa:	bf7d                	j	ffffffffc0201e68 <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0201eac:	01550463          	beq	a0,s5,ffffffffc0201eb4 <readline+0x84>
ffffffffc0201eb0:	fb651ce3          	bne	a0,s6,ffffffffc0201e68 <readline+0x38>
            cputchar(c);
ffffffffc0201eb4:	a80fe0ef          	jal	ra,ffffffffc0200134 <cputchar>
            buf[i] = '\0';
ffffffffc0201eb8:	00005517          	auipc	a0,0x5
ffffffffc0201ebc:	18850513          	addi	a0,a0,392 # ffffffffc0207040 <buf>
ffffffffc0201ec0:	94aa                	add	s1,s1,a0
ffffffffc0201ec2:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0201ec6:	60a6                	ld	ra,72(sp)
ffffffffc0201ec8:	6486                	ld	s1,64(sp)
ffffffffc0201eca:	7962                	ld	s2,56(sp)
ffffffffc0201ecc:	79c2                	ld	s3,48(sp)
ffffffffc0201ece:	7a22                	ld	s4,40(sp)
ffffffffc0201ed0:	7a82                	ld	s5,32(sp)
ffffffffc0201ed2:	6b62                	ld	s6,24(sp)
ffffffffc0201ed4:	6bc2                	ld	s7,16(sp)
ffffffffc0201ed6:	6161                	addi	sp,sp,80
ffffffffc0201ed8:	8082                	ret
            cputchar(c);
ffffffffc0201eda:	4521                	li	a0,8
ffffffffc0201edc:	a58fe0ef          	jal	ra,ffffffffc0200134 <cputchar>
            i --;
ffffffffc0201ee0:	34fd                	addiw	s1,s1,-1
ffffffffc0201ee2:	b759                	j	ffffffffc0201e68 <readline+0x38>

ffffffffc0201ee4 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201ee4:	4781                	li	a5,0
ffffffffc0201ee6:	00005717          	auipc	a4,0x5
ffffffffc0201eea:	13273703          	ld	a4,306(a4) # ffffffffc0207018 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201eee:	88ba                	mv	a7,a4
ffffffffc0201ef0:	852a                	mv	a0,a0
ffffffffc0201ef2:	85be                	mv	a1,a5
ffffffffc0201ef4:	863e                	mv	a2,a5
ffffffffc0201ef6:	00000073          	ecall
ffffffffc0201efa:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201efc:	8082                	ret

ffffffffc0201efe <sbi_set_timer>:
    __asm__ volatile (
ffffffffc0201efe:	4781                	li	a5,0
ffffffffc0201f00:	00005717          	auipc	a4,0x5
ffffffffc0201f04:	59873703          	ld	a4,1432(a4) # ffffffffc0207498 <SBI_SET_TIMER>
ffffffffc0201f08:	88ba                	mv	a7,a4
ffffffffc0201f0a:	852a                	mv	a0,a0
ffffffffc0201f0c:	85be                	mv	a1,a5
ffffffffc0201f0e:	863e                	mv	a2,a5
ffffffffc0201f10:	00000073          	ecall
ffffffffc0201f14:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
ffffffffc0201f16:	8082                	ret

ffffffffc0201f18 <sbi_console_getchar>:
    __asm__ volatile (
ffffffffc0201f18:	4501                	li	a0,0
ffffffffc0201f1a:	00005797          	auipc	a5,0x5
ffffffffc0201f1e:	0f67b783          	ld	a5,246(a5) # ffffffffc0207010 <SBI_CONSOLE_GETCHAR>
ffffffffc0201f22:	88be                	mv	a7,a5
ffffffffc0201f24:	852a                	mv	a0,a0
ffffffffc0201f26:	85aa                	mv	a1,a0
ffffffffc0201f28:	862a                	mv	a2,a0
ffffffffc0201f2a:	00000073          	ecall
ffffffffc0201f2e:	852a                	mv	a0,a0

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
}
ffffffffc0201f30:	2501                	sext.w	a0,a0
ffffffffc0201f32:	8082                	ret

ffffffffc0201f34 <sbi_shutdown>:
    __asm__ volatile (
ffffffffc0201f34:	4781                	li	a5,0
ffffffffc0201f36:	00005717          	auipc	a4,0x5
ffffffffc0201f3a:	0ea73703          	ld	a4,234(a4) # ffffffffc0207020 <SBI_SHUTDOWN>
ffffffffc0201f3e:	88ba                	mv	a7,a4
ffffffffc0201f40:	853e                	mv	a0,a5
ffffffffc0201f42:	85be                	mv	a1,a5
ffffffffc0201f44:	863e                	mv	a2,a5
ffffffffc0201f46:	00000073          	ecall
ffffffffc0201f4a:	87aa                	mv	a5,a0

void sbi_shutdown(void)
{
	sbi_call(SBI_SHUTDOWN, 0, 0, 0);
ffffffffc0201f4c:	8082                	ret

ffffffffc0201f4e <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201f4e:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0201f52:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0201f54:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0201f56:	cb81                	beqz	a5,ffffffffc0201f66 <strlen+0x18>
        cnt ++;
ffffffffc0201f58:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0201f5a:	00a707b3          	add	a5,a4,a0
ffffffffc0201f5e:	0007c783          	lbu	a5,0(a5)
ffffffffc0201f62:	fbfd                	bnez	a5,ffffffffc0201f58 <strlen+0xa>
ffffffffc0201f64:	8082                	ret
    }
    return cnt;
}
ffffffffc0201f66:	8082                	ret

ffffffffc0201f68 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201f68:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201f6a:	e589                	bnez	a1,ffffffffc0201f74 <strnlen+0xc>
ffffffffc0201f6c:	a811                	j	ffffffffc0201f80 <strnlen+0x18>
        cnt ++;
ffffffffc0201f6e:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201f70:	00f58863          	beq	a1,a5,ffffffffc0201f80 <strnlen+0x18>
ffffffffc0201f74:	00f50733          	add	a4,a0,a5
ffffffffc0201f78:	00074703          	lbu	a4,0(a4)
ffffffffc0201f7c:	fb6d                	bnez	a4,ffffffffc0201f6e <strnlen+0x6>
ffffffffc0201f7e:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201f80:	852e                	mv	a0,a1
ffffffffc0201f82:	8082                	ret

ffffffffc0201f84 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201f84:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201f88:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201f8c:	cb89                	beqz	a5,ffffffffc0201f9e <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0201f8e:	0505                	addi	a0,a0,1
ffffffffc0201f90:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201f92:	fee789e3          	beq	a5,a4,ffffffffc0201f84 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201f96:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201f9a:	9d19                	subw	a0,a0,a4
ffffffffc0201f9c:	8082                	ret
ffffffffc0201f9e:	4501                	li	a0,0
ffffffffc0201fa0:	bfed                	j	ffffffffc0201f9a <strcmp+0x16>

ffffffffc0201fa2 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201fa2:	c20d                	beqz	a2,ffffffffc0201fc4 <strncmp+0x22>
ffffffffc0201fa4:	962e                	add	a2,a2,a1
ffffffffc0201fa6:	a031                	j	ffffffffc0201fb2 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0201fa8:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201faa:	00e79a63          	bne	a5,a4,ffffffffc0201fbe <strncmp+0x1c>
ffffffffc0201fae:	00b60b63          	beq	a2,a1,ffffffffc0201fc4 <strncmp+0x22>
ffffffffc0201fb2:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0201fb6:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201fb8:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0201fbc:	f7f5                	bnez	a5,ffffffffc0201fa8 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201fbe:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0201fc2:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201fc4:	4501                	li	a0,0
ffffffffc0201fc6:	8082                	ret

ffffffffc0201fc8 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0201fc8:	00054783          	lbu	a5,0(a0)
ffffffffc0201fcc:	c799                	beqz	a5,ffffffffc0201fda <strchr+0x12>
        if (*s == c) {
ffffffffc0201fce:	00f58763          	beq	a1,a5,ffffffffc0201fdc <strchr+0x14>
    while (*s != '\0') {
ffffffffc0201fd2:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0201fd6:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0201fd8:	fbfd                	bnez	a5,ffffffffc0201fce <strchr+0x6>
    }
    return NULL;
ffffffffc0201fda:	4501                	li	a0,0
}
ffffffffc0201fdc:	8082                	ret

ffffffffc0201fde <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201fde:	ca01                	beqz	a2,ffffffffc0201fee <memset+0x10>
ffffffffc0201fe0:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201fe2:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201fe4:	0785                	addi	a5,a5,1
ffffffffc0201fe6:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201fea:	fec79de3          	bne	a5,a2,ffffffffc0201fe4 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201fee:	8082                	ret
