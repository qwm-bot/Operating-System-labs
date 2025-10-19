
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
ffffffffc020003c:	c0205137          	lui	sp,0xc0205

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	0d628293          	addi	t0,t0,214 # ffffffffc02000d6 <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020004a:	1141                	addi	sp,sp,-16 # ffffffffc0204ff0 <bootstack+0x1ff0>
    extern char etext[], edata[], end[];
    cprintf("Special kernel symbols:\n");
ffffffffc020004c:	00002517          	auipc	a0,0x2
ffffffffc0200050:	d0450513          	addi	a0,a0,-764 # ffffffffc0201d50 <etext+0x6>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0f6000ef          	jal	ffffffffc020014c <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07c58593          	addi	a1,a1,124 # ffffffffc02000d6 <kern_init>
ffffffffc0200062:	00002517          	auipc	a0,0x2
ffffffffc0200066:	d0e50513          	addi	a0,a0,-754 # ffffffffc0201d70 <etext+0x26>
ffffffffc020006a:	0e2000ef          	jal	ffffffffc020014c <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00002597          	auipc	a1,0x2
ffffffffc0200072:	cdc58593          	addi	a1,a1,-804 # ffffffffc0201d4a <etext>
ffffffffc0200076:	00002517          	auipc	a0,0x2
ffffffffc020007a:	d1a50513          	addi	a0,a0,-742 # ffffffffc0201d90 <etext+0x46>
ffffffffc020007e:	0ce000ef          	jal	ffffffffc020014c <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	00006597          	auipc	a1,0x6
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc0206018 <buddy_areas>
ffffffffc020008a:	00002517          	auipc	a0,0x2
ffffffffc020008e:	d2650513          	addi	a0,a0,-730 # ffffffffc0201db0 <etext+0x66>
ffffffffc0200092:	0ba000ef          	jal	ffffffffc020014c <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	00006597          	auipc	a1,0x6
ffffffffc020009a:	25a58593          	addi	a1,a1,602 # ffffffffc02062f0 <end>
ffffffffc020009e:	00002517          	auipc	a0,0x2
ffffffffc02000a2:	d3250513          	addi	a0,a0,-718 # ffffffffc0201dd0 <etext+0x86>
ffffffffc02000a6:	0a6000ef          	jal	ffffffffc020014c <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000aa:	00000717          	auipc	a4,0x0
ffffffffc02000ae:	02c70713          	addi	a4,a4,44 # ffffffffc02000d6 <kern_init>
ffffffffc02000b2:	00006797          	auipc	a5,0x6
ffffffffc02000b6:	63d78793          	addi	a5,a5,1597 # ffffffffc02066ef <end+0x3ff>
ffffffffc02000ba:	8f99                	sub	a5,a5,a4
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000bc:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02000c0:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000c2:	3ff5f593          	andi	a1,a1,1023
ffffffffc02000c6:	95be                	add	a1,a1,a5
ffffffffc02000c8:	85a9                	srai	a1,a1,0xa
ffffffffc02000ca:	00002517          	auipc	a0,0x2
ffffffffc02000ce:	d2650513          	addi	a0,a0,-730 # ffffffffc0201df0 <etext+0xa6>
}
ffffffffc02000d2:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d4:	a8a5                	j	ffffffffc020014c <cprintf>

ffffffffc02000d6 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d6:	00006517          	auipc	a0,0x6
ffffffffc02000da:	f4250513          	addi	a0,a0,-190 # ffffffffc0206018 <buddy_areas>
ffffffffc02000de:	00006617          	auipc	a2,0x6
ffffffffc02000e2:	21260613          	addi	a2,a2,530 # ffffffffc02062f0 <end>
int kern_init(void) {
ffffffffc02000e6:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000e8:	8e09                	sub	a2,a2,a0
ffffffffc02000ea:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ec:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000ee:	44b010ef          	jal	ffffffffc0201d38 <memset>
    dtb_init();
ffffffffc02000f2:	13a000ef          	jal	ffffffffc020022c <dtb_init>
    cons_init();  // init the console
ffffffffc02000f6:	12c000ef          	jal	ffffffffc0200222 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fa:	00003517          	auipc	a0,0x3
ffffffffc02000fe:	89650513          	addi	a0,a0,-1898 # ffffffffc0202990 <etext+0xc46>
ffffffffc0200102:	07e000ef          	jal	ffffffffc0200180 <cputs>

    print_kerninfo();
ffffffffc0200106:	f45ff0ef          	jal	ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init();  // init physical memory management
ffffffffc020010a:	62d000ef          	jal	ffffffffc0200f36 <pmm_init>
    slub_test();
ffffffffc020010e:	396010ef          	jal	ffffffffc02014a4 <slub_test>
    /* do nothing */
    while (1)
ffffffffc0200112:	a001                	j	ffffffffc0200112 <kern_init+0x3c>

ffffffffc0200114 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200114:	1101                	addi	sp,sp,-32
ffffffffc0200116:	ec06                	sd	ra,24(sp)
ffffffffc0200118:	e42e                	sd	a1,8(sp)
    cons_putc(c);
ffffffffc020011a:	10a000ef          	jal	ffffffffc0200224 <cons_putc>
    (*cnt) ++;
ffffffffc020011e:	65a2                	ld	a1,8(sp)
}
ffffffffc0200120:	60e2                	ld	ra,24(sp)
    (*cnt) ++;
ffffffffc0200122:	419c                	lw	a5,0(a1)
ffffffffc0200124:	2785                	addiw	a5,a5,1
ffffffffc0200126:	c19c                	sw	a5,0(a1)
}
ffffffffc0200128:	6105                	addi	sp,sp,32
ffffffffc020012a:	8082                	ret

ffffffffc020012c <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc020012c:	1101                	addi	sp,sp,-32
ffffffffc020012e:	862a                	mv	a2,a0
ffffffffc0200130:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200132:	00000517          	auipc	a0,0x0
ffffffffc0200136:	fe250513          	addi	a0,a0,-30 # ffffffffc0200114 <cputch>
ffffffffc020013a:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc020013c:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc020013e:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200140:	7e8010ef          	jal	ffffffffc0201928 <vprintfmt>
    return cnt;
}
ffffffffc0200144:	60e2                	ld	ra,24(sp)
ffffffffc0200146:	4532                	lw	a0,12(sp)
ffffffffc0200148:	6105                	addi	sp,sp,32
ffffffffc020014a:	8082                	ret

ffffffffc020014c <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc020014c:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc020014e:	02810313          	addi	t1,sp,40
cprintf(const char *fmt, ...) {
ffffffffc0200152:	f42e                	sd	a1,40(sp)
ffffffffc0200154:	f832                	sd	a2,48(sp)
ffffffffc0200156:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200158:	862a                	mv	a2,a0
ffffffffc020015a:	004c                	addi	a1,sp,4
ffffffffc020015c:	00000517          	auipc	a0,0x0
ffffffffc0200160:	fb850513          	addi	a0,a0,-72 # ffffffffc0200114 <cputch>
ffffffffc0200164:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc0200166:	ec06                	sd	ra,24(sp)
ffffffffc0200168:	e0ba                	sd	a4,64(sp)
ffffffffc020016a:	e4be                	sd	a5,72(sp)
ffffffffc020016c:	e8c2                	sd	a6,80(sp)
ffffffffc020016e:	ecc6                	sd	a7,88(sp)
    int cnt = 0;
ffffffffc0200170:	c202                	sw	zero,4(sp)
    va_start(ap, fmt);
ffffffffc0200172:	e41a                	sd	t1,8(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200174:	7b4010ef          	jal	ffffffffc0201928 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc0200178:	60e2                	ld	ra,24(sp)
ffffffffc020017a:	4512                	lw	a0,4(sp)
ffffffffc020017c:	6125                	addi	sp,sp,96
ffffffffc020017e:	8082                	ret

ffffffffc0200180 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200180:	1101                	addi	sp,sp,-32
ffffffffc0200182:	e822                	sd	s0,16(sp)
ffffffffc0200184:	ec06                	sd	ra,24(sp)
ffffffffc0200186:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc0200188:	00054503          	lbu	a0,0(a0)
ffffffffc020018c:	c51d                	beqz	a0,ffffffffc02001ba <cputs+0x3a>
ffffffffc020018e:	e426                	sd	s1,8(sp)
ffffffffc0200190:	0405                	addi	s0,s0,1
    int cnt = 0;
ffffffffc0200192:	4481                	li	s1,0
    cons_putc(c);
ffffffffc0200194:	090000ef          	jal	ffffffffc0200224 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc0200198:	00044503          	lbu	a0,0(s0)
ffffffffc020019c:	0405                	addi	s0,s0,1
ffffffffc020019e:	87a6                	mv	a5,s1
    (*cnt) ++;
ffffffffc02001a0:	2485                	addiw	s1,s1,1
    while ((c = *str ++) != '\0') {
ffffffffc02001a2:	f96d                	bnez	a0,ffffffffc0200194 <cputs+0x14>
    cons_putc(c);
ffffffffc02001a4:	4529                	li	a0,10
    (*cnt) ++;
ffffffffc02001a6:	0027841b          	addiw	s0,a5,2
ffffffffc02001aa:	64a2                	ld	s1,8(sp)
    cons_putc(c);
ffffffffc02001ac:	078000ef          	jal	ffffffffc0200224 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001b0:	60e2                	ld	ra,24(sp)
ffffffffc02001b2:	8522                	mv	a0,s0
ffffffffc02001b4:	6442                	ld	s0,16(sp)
ffffffffc02001b6:	6105                	addi	sp,sp,32
ffffffffc02001b8:	8082                	ret
    cons_putc(c);
ffffffffc02001ba:	4529                	li	a0,10
ffffffffc02001bc:	068000ef          	jal	ffffffffc0200224 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc02001c0:	4405                	li	s0,1
}
ffffffffc02001c2:	60e2                	ld	ra,24(sp)
ffffffffc02001c4:	8522                	mv	a0,s0
ffffffffc02001c6:	6442                	ld	s0,16(sp)
ffffffffc02001c8:	6105                	addi	sp,sp,32
ffffffffc02001ca:	8082                	ret

ffffffffc02001cc <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001cc:	00006317          	auipc	t1,0x6
ffffffffc02001d0:	0d432303          	lw	t1,212(t1) # ffffffffc02062a0 <is_panic>
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001d4:	715d                	addi	sp,sp,-80
ffffffffc02001d6:	ec06                	sd	ra,24(sp)
ffffffffc02001d8:	f436                	sd	a3,40(sp)
ffffffffc02001da:	f83a                	sd	a4,48(sp)
ffffffffc02001dc:	fc3e                	sd	a5,56(sp)
ffffffffc02001de:	e0c2                	sd	a6,64(sp)
ffffffffc02001e0:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001e2:	00030363          	beqz	t1,ffffffffc02001e8 <__panic+0x1c>
    vcprintf(fmt, ap);
    cprintf("\n");
    va_end(ap);

panic_dead:
    while (1) {
ffffffffc02001e6:	a001                	j	ffffffffc02001e6 <__panic+0x1a>
    is_panic = 1;
ffffffffc02001e8:	4705                	li	a4,1
    va_start(ap, fmt);
ffffffffc02001ea:	103c                	addi	a5,sp,40
ffffffffc02001ec:	e822                	sd	s0,16(sp)
ffffffffc02001ee:	8432                	mv	s0,a2
ffffffffc02001f0:	862e                	mv	a2,a1
ffffffffc02001f2:	85aa                	mv	a1,a0
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001f4:	00002517          	auipc	a0,0x2
ffffffffc02001f8:	c2c50513          	addi	a0,a0,-980 # ffffffffc0201e20 <etext+0xd6>
    is_panic = 1;
ffffffffc02001fc:	00006697          	auipc	a3,0x6
ffffffffc0200200:	0ae6a223          	sw	a4,164(a3) # ffffffffc02062a0 <is_panic>
    va_start(ap, fmt);
ffffffffc0200204:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200206:	f47ff0ef          	jal	ffffffffc020014c <cprintf>
    vcprintf(fmt, ap);
ffffffffc020020a:	65a2                	ld	a1,8(sp)
ffffffffc020020c:	8522                	mv	a0,s0
ffffffffc020020e:	f1fff0ef          	jal	ffffffffc020012c <vcprintf>
    cprintf("\n");
ffffffffc0200212:	00002517          	auipc	a0,0x2
ffffffffc0200216:	c2e50513          	addi	a0,a0,-978 # ffffffffc0201e40 <etext+0xf6>
ffffffffc020021a:	f33ff0ef          	jal	ffffffffc020014c <cprintf>
ffffffffc020021e:	6442                	ld	s0,16(sp)
ffffffffc0200220:	b7d9                	j	ffffffffc02001e6 <__panic+0x1a>

ffffffffc0200222 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200222:	8082                	ret

ffffffffc0200224 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200224:	0ff57513          	zext.b	a0,a0
ffffffffc0200228:	2670106f          	j	ffffffffc0201c8e <sbi_console_putchar>

ffffffffc020022c <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc020022c:	7179                	addi	sp,sp,-48
    cprintf("DTB Init\n");
ffffffffc020022e:	00002517          	auipc	a0,0x2
ffffffffc0200232:	c1a50513          	addi	a0,a0,-998 # ffffffffc0201e48 <etext+0xfe>
void dtb_init(void) {
ffffffffc0200236:	f406                	sd	ra,40(sp)
ffffffffc0200238:	f022                	sd	s0,32(sp)
    cprintf("DTB Init\n");
ffffffffc020023a:	f13ff0ef          	jal	ffffffffc020014c <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc020023e:	00006597          	auipc	a1,0x6
ffffffffc0200242:	dc25b583          	ld	a1,-574(a1) # ffffffffc0206000 <boot_hartid>
ffffffffc0200246:	00002517          	auipc	a0,0x2
ffffffffc020024a:	c1250513          	addi	a0,a0,-1006 # ffffffffc0201e58 <etext+0x10e>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020024e:	00006417          	auipc	s0,0x6
ffffffffc0200252:	dba40413          	addi	s0,s0,-582 # ffffffffc0206008 <boot_dtb>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200256:	ef7ff0ef          	jal	ffffffffc020014c <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020025a:	600c                	ld	a1,0(s0)
ffffffffc020025c:	00002517          	auipc	a0,0x2
ffffffffc0200260:	c0c50513          	addi	a0,a0,-1012 # ffffffffc0201e68 <etext+0x11e>
ffffffffc0200264:	ee9ff0ef          	jal	ffffffffc020014c <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200268:	6018                	ld	a4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc020026a:	00002517          	auipc	a0,0x2
ffffffffc020026e:	c1650513          	addi	a0,a0,-1002 # ffffffffc0201e80 <etext+0x136>
    if (boot_dtb == 0) {
ffffffffc0200272:	10070163          	beqz	a4,ffffffffc0200374 <dtb_init+0x148>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200276:	57f5                	li	a5,-3
ffffffffc0200278:	07fa                	slli	a5,a5,0x1e
ffffffffc020027a:	973e                	add	a4,a4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc020027c:	431c                	lw	a5,0(a4)
    if (magic != 0xd00dfeed) {
ffffffffc020027e:	d00e06b7          	lui	a3,0xd00e0
ffffffffc0200282:	eed68693          	addi	a3,a3,-275 # ffffffffd00dfeed <end+0xfed9bfd>
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200286:	0087d59b          	srliw	a1,a5,0x8
ffffffffc020028a:	0187961b          	slliw	a2,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020028e:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200292:	0ff5f593          	zext.b	a1,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200296:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020029a:	05c2                	slli	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020029c:	8e49                	or	a2,a2,a0
ffffffffc020029e:	0ff7f793          	zext.b	a5,a5
ffffffffc02002a2:	8dd1                	or	a1,a1,a2
ffffffffc02002a4:	07a2                	slli	a5,a5,0x8
ffffffffc02002a6:	8ddd                	or	a1,a1,a5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002a8:	00ff0837          	lui	a6,0xff0
    if (magic != 0xd00dfeed) {
ffffffffc02002ac:	0cd59863          	bne	a1,a3,ffffffffc020037c <dtb_init+0x150>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02002b0:	4710                	lw	a2,8(a4)
ffffffffc02002b2:	4754                	lw	a3,12(a4)
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02002b4:	e84a                	sd	s2,16(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002b6:	0086541b          	srliw	s0,a2,0x8
ffffffffc02002ba:	0086d79b          	srliw	a5,a3,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002be:	01865e1b          	srliw	t3,a2,0x18
ffffffffc02002c2:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002c6:	0186151b          	slliw	a0,a2,0x18
ffffffffc02002ca:	0186959b          	slliw	a1,a3,0x18
ffffffffc02002ce:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002d2:	0106561b          	srliw	a2,a2,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002d6:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002da:	0106d69b          	srliw	a3,a3,0x10
ffffffffc02002de:	01c56533          	or	a0,a0,t3
ffffffffc02002e2:	0115e5b3          	or	a1,a1,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002e6:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002ea:	0ff67613          	zext.b	a2,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002ee:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f2:	0ff6f693          	zext.b	a3,a3
ffffffffc02002f6:	8c49                	or	s0,s0,a0
ffffffffc02002f8:	0622                	slli	a2,a2,0x8
ffffffffc02002fa:	8fcd                	or	a5,a5,a1
ffffffffc02002fc:	06a2                	slli	a3,a3,0x8
ffffffffc02002fe:	8c51                	or	s0,s0,a2
ffffffffc0200300:	8fd5                	or	a5,a5,a3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200302:	1402                	slli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200304:	1782                	slli	a5,a5,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200306:	9001                	srli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200308:	9381                	srli	a5,a5,0x20
ffffffffc020030a:	ec26                	sd	s1,24(sp)
    int in_memory_node = 0;
ffffffffc020030c:	4301                	li	t1,0
        switch (token) {
ffffffffc020030e:	488d                	li	a7,3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200310:	943a                	add	s0,s0,a4
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200312:	00e78933          	add	s2,a5,a4
        switch (token) {
ffffffffc0200316:	4e05                	li	t3,1
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200318:	4018                	lw	a4,0(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020031a:	0087579b          	srliw	a5,a4,0x8
ffffffffc020031e:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200322:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200326:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020032a:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020032e:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200332:	8ed1                	or	a3,a3,a2
ffffffffc0200334:	0ff77713          	zext.b	a4,a4
ffffffffc0200338:	8fd5                	or	a5,a5,a3
ffffffffc020033a:	0722                	slli	a4,a4,0x8
ffffffffc020033c:	8fd9                	or	a5,a5,a4
        switch (token) {
ffffffffc020033e:	05178763          	beq	a5,a7,ffffffffc020038c <dtb_init+0x160>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200342:	0411                	addi	s0,s0,4
        switch (token) {
ffffffffc0200344:	00f8e963          	bltu	a7,a5,ffffffffc0200356 <dtb_init+0x12a>
ffffffffc0200348:	07c78d63          	beq	a5,t3,ffffffffc02003c2 <dtb_init+0x196>
ffffffffc020034c:	4709                	li	a4,2
ffffffffc020034e:	00e79763          	bne	a5,a4,ffffffffc020035c <dtb_init+0x130>
ffffffffc0200352:	4301                	li	t1,0
ffffffffc0200354:	b7d1                	j	ffffffffc0200318 <dtb_init+0xec>
ffffffffc0200356:	4711                	li	a4,4
ffffffffc0200358:	fce780e3          	beq	a5,a4,ffffffffc0200318 <dtb_init+0xec>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc020035c:	00002517          	auipc	a0,0x2
ffffffffc0200360:	bec50513          	addi	a0,a0,-1044 # ffffffffc0201f48 <etext+0x1fe>
ffffffffc0200364:	de9ff0ef          	jal	ffffffffc020014c <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200368:	64e2                	ld	s1,24(sp)
ffffffffc020036a:	6942                	ld	s2,16(sp)
ffffffffc020036c:	00002517          	auipc	a0,0x2
ffffffffc0200370:	c1450513          	addi	a0,a0,-1004 # ffffffffc0201f80 <etext+0x236>
}
ffffffffc0200374:	7402                	ld	s0,32(sp)
ffffffffc0200376:	70a2                	ld	ra,40(sp)
ffffffffc0200378:	6145                	addi	sp,sp,48
    cprintf("DTB init completed\n");
ffffffffc020037a:	bbc9                	j	ffffffffc020014c <cprintf>
}
ffffffffc020037c:	7402                	ld	s0,32(sp)
ffffffffc020037e:	70a2                	ld	ra,40(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200380:	00002517          	auipc	a0,0x2
ffffffffc0200384:	b2050513          	addi	a0,a0,-1248 # ffffffffc0201ea0 <etext+0x156>
}
ffffffffc0200388:	6145                	addi	sp,sp,48
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc020038a:	b3c9                	j	ffffffffc020014c <cprintf>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc020038c:	4058                	lw	a4,4(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020038e:	0087579b          	srliw	a5,a4,0x8
ffffffffc0200392:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200396:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020039a:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020039e:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02003a2:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02003a6:	8ed1                	or	a3,a3,a2
ffffffffc02003a8:	0ff77713          	zext.b	a4,a4
ffffffffc02003ac:	8fd5                	or	a5,a5,a3
ffffffffc02003ae:	0722                	slli	a4,a4,0x8
ffffffffc02003b0:	8fd9                	or	a5,a5,a4
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02003b2:	04031463          	bnez	t1,ffffffffc02003fa <dtb_init+0x1ce>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc02003b6:	1782                	slli	a5,a5,0x20
ffffffffc02003b8:	9381                	srli	a5,a5,0x20
ffffffffc02003ba:	043d                	addi	s0,s0,15
ffffffffc02003bc:	943e                	add	s0,s0,a5
ffffffffc02003be:	9871                	andi	s0,s0,-4
                break;
ffffffffc02003c0:	bfa1                	j	ffffffffc0200318 <dtb_init+0xec>
                int name_len = strlen(name);
ffffffffc02003c2:	8522                	mv	a0,s0
ffffffffc02003c4:	e01a                	sd	t1,0(sp)
ffffffffc02003c6:	0e3010ef          	jal	ffffffffc0201ca8 <strlen>
ffffffffc02003ca:	84aa                	mv	s1,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003cc:	4619                	li	a2,6
ffffffffc02003ce:	8522                	mv	a0,s0
ffffffffc02003d0:	00002597          	auipc	a1,0x2
ffffffffc02003d4:	af858593          	addi	a1,a1,-1288 # ffffffffc0201ec8 <etext+0x17e>
ffffffffc02003d8:	139010ef          	jal	ffffffffc0201d10 <strncmp>
ffffffffc02003dc:	6302                	ld	t1,0(sp)
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02003de:	0411                	addi	s0,s0,4
ffffffffc02003e0:	0004879b          	sext.w	a5,s1
ffffffffc02003e4:	943e                	add	s0,s0,a5
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003e6:	00153513          	seqz	a0,a0
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02003ea:	9871                	andi	s0,s0,-4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003ec:	00a36333          	or	t1,t1,a0
                break;
ffffffffc02003f0:	00ff0837          	lui	a6,0xff0
ffffffffc02003f4:	488d                	li	a7,3
ffffffffc02003f6:	4e05                	li	t3,1
ffffffffc02003f8:	b705                	j	ffffffffc0200318 <dtb_init+0xec>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02003fa:	4418                	lw	a4,8(s0)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02003fc:	00002597          	auipc	a1,0x2
ffffffffc0200400:	ad458593          	addi	a1,a1,-1324 # ffffffffc0201ed0 <etext+0x186>
ffffffffc0200404:	e43e                	sd	a5,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200406:	0087551b          	srliw	a0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020040a:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020040e:	0187169b          	slliw	a3,a4,0x18
ffffffffc0200412:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200416:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020041a:	01057533          	and	a0,a0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020041e:	8ed1                	or	a3,a3,a2
ffffffffc0200420:	0ff77713          	zext.b	a4,a4
ffffffffc0200424:	0722                	slli	a4,a4,0x8
ffffffffc0200426:	8d55                	or	a0,a0,a3
ffffffffc0200428:	8d59                	or	a0,a0,a4
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc020042a:	1502                	slli	a0,a0,0x20
ffffffffc020042c:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020042e:	954a                	add	a0,a0,s2
ffffffffc0200430:	e01a                	sd	t1,0(sp)
ffffffffc0200432:	0ab010ef          	jal	ffffffffc0201cdc <strcmp>
ffffffffc0200436:	67a2                	ld	a5,8(sp)
ffffffffc0200438:	473d                	li	a4,15
ffffffffc020043a:	6302                	ld	t1,0(sp)
ffffffffc020043c:	00ff0837          	lui	a6,0xff0
ffffffffc0200440:	488d                	li	a7,3
ffffffffc0200442:	4e05                	li	t3,1
ffffffffc0200444:	f6f779e3          	bgeu	a4,a5,ffffffffc02003b6 <dtb_init+0x18a>
ffffffffc0200448:	f53d                	bnez	a0,ffffffffc02003b6 <dtb_init+0x18a>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020044a:	00c43683          	ld	a3,12(s0)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc020044e:	01443703          	ld	a4,20(s0)
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200452:	00002517          	auipc	a0,0x2
ffffffffc0200456:	a8650513          	addi	a0,a0,-1402 # ffffffffc0201ed8 <etext+0x18e>
           fdt32_to_cpu(x >> 32);
ffffffffc020045a:	4206d793          	srai	a5,a3,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020045e:	0087d31b          	srliw	t1,a5,0x8
ffffffffc0200462:	00871f93          	slli	t6,a4,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc0200466:	42075893          	srai	a7,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020046a:	0187df1b          	srliw	t5,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020046e:	0187959b          	slliw	a1,a5,0x18
ffffffffc0200472:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200476:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020047a:	420fd613          	srai	a2,t6,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020047e:	0188de9b          	srliw	t4,a7,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200482:	01037333          	and	t1,t1,a6
ffffffffc0200486:	01889e1b          	slliw	t3,a7,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020048a:	01e5e5b3          	or	a1,a1,t5
ffffffffc020048e:	0ff7f793          	zext.b	a5,a5
ffffffffc0200492:	01de6e33          	or	t3,t3,t4
ffffffffc0200496:	0065e5b3          	or	a1,a1,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020049a:	01067633          	and	a2,a2,a6
ffffffffc020049e:	0086d31b          	srliw	t1,a3,0x8
ffffffffc02004a2:	0087541b          	srliw	s0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004a6:	07a2                	slli	a5,a5,0x8
ffffffffc02004a8:	0108d89b          	srliw	a7,a7,0x10
ffffffffc02004ac:	0186df1b          	srliw	t5,a3,0x18
ffffffffc02004b0:	01875e9b          	srliw	t4,a4,0x18
ffffffffc02004b4:	8ddd                	or	a1,a1,a5
ffffffffc02004b6:	01c66633          	or	a2,a2,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004ba:	0186979b          	slliw	a5,a3,0x18
ffffffffc02004be:	01871e1b          	slliw	t3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004c2:	0ff8f893          	zext.b	a7,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c6:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ca:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004ce:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004d2:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004d6:	01037333          	and	t1,t1,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004da:	08a2                	slli	a7,a7,0x8
ffffffffc02004dc:	01e7e7b3          	or	a5,a5,t5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004e0:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004e4:	0ff6f693          	zext.b	a3,a3
ffffffffc02004e8:	01de6833          	or	a6,t3,t4
ffffffffc02004ec:	0ff77713          	zext.b	a4,a4
ffffffffc02004f0:	01166633          	or	a2,a2,a7
ffffffffc02004f4:	0067e7b3          	or	a5,a5,t1
ffffffffc02004f8:	06a2                	slli	a3,a3,0x8
ffffffffc02004fa:	01046433          	or	s0,s0,a6
ffffffffc02004fe:	0722                	slli	a4,a4,0x8
ffffffffc0200500:	8fd5                	or	a5,a5,a3
ffffffffc0200502:	8c59                	or	s0,s0,a4
           fdt32_to_cpu(x >> 32);
ffffffffc0200504:	1582                	slli	a1,a1,0x20
ffffffffc0200506:	1602                	slli	a2,a2,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200508:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020050a:	9201                	srli	a2,a2,0x20
ffffffffc020050c:	9181                	srli	a1,a1,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020050e:	1402                	slli	s0,s0,0x20
ffffffffc0200510:	00b7e4b3          	or	s1,a5,a1
ffffffffc0200514:	8c51                	or	s0,s0,a2
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200516:	c37ff0ef          	jal	ffffffffc020014c <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc020051a:	85a6                	mv	a1,s1
ffffffffc020051c:	00002517          	auipc	a0,0x2
ffffffffc0200520:	9dc50513          	addi	a0,a0,-1572 # ffffffffc0201ef8 <etext+0x1ae>
ffffffffc0200524:	c29ff0ef          	jal	ffffffffc020014c <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200528:	01445613          	srli	a2,s0,0x14
ffffffffc020052c:	85a2                	mv	a1,s0
ffffffffc020052e:	00002517          	auipc	a0,0x2
ffffffffc0200532:	9e250513          	addi	a0,a0,-1566 # ffffffffc0201f10 <etext+0x1c6>
ffffffffc0200536:	c17ff0ef          	jal	ffffffffc020014c <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc020053a:	009405b3          	add	a1,s0,s1
ffffffffc020053e:	15fd                	addi	a1,a1,-1
ffffffffc0200540:	00002517          	auipc	a0,0x2
ffffffffc0200544:	9f050513          	addi	a0,a0,-1552 # ffffffffc0201f30 <etext+0x1e6>
ffffffffc0200548:	c05ff0ef          	jal	ffffffffc020014c <cprintf>
        memory_base = mem_base;
ffffffffc020054c:	00006797          	auipc	a5,0x6
ffffffffc0200550:	d697b223          	sd	s1,-668(a5) # ffffffffc02062b0 <memory_base>
        memory_size = mem_size;
ffffffffc0200554:	00006797          	auipc	a5,0x6
ffffffffc0200558:	d487ba23          	sd	s0,-684(a5) # ffffffffc02062a8 <memory_size>
ffffffffc020055c:	b531                	j	ffffffffc0200368 <dtb_init+0x13c>

ffffffffc020055e <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc020055e:	00006517          	auipc	a0,0x6
ffffffffc0200562:	d5253503          	ld	a0,-686(a0) # ffffffffc02062b0 <memory_base>
ffffffffc0200566:	8082                	ret

ffffffffc0200568 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc0200568:	00006517          	auipc	a0,0x6
ffffffffc020056c:	d4053503          	ld	a0,-704(a0) # ffffffffc02062a8 <memory_size>
ffffffffc0200570:	8082                	ret

ffffffffc0200572 <buddy_init>:
    if (buddy_idx >= npage) return NULL;
    return &pages[buddy_idx];
}

static void buddy_init(void) {
    for (size_t i = 0; i < MAX_ORDER; i++) {
ffffffffc0200572:	00006797          	auipc	a5,0x6
ffffffffc0200576:	aa678793          	addi	a5,a5,-1370 # ffffffffc0206018 <buddy_areas>
ffffffffc020057a:	00006717          	auipc	a4,0x6
ffffffffc020057e:	c0670713          	addi	a4,a4,-1018 # ffffffffc0206180 <caches>
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200582:	e79c                	sd	a5,8(a5)
ffffffffc0200584:	e39c                	sd	a5,0(a5)
        list_init(&buddy_areas[i].free_list);
        buddy_areas[i].nr_free = 0;
ffffffffc0200586:	0007b823          	sd	zero,16(a5)
    for (size_t i = 0; i < MAX_ORDER; i++) {
ffffffffc020058a:	07e1                	addi	a5,a5,24
ffffffffc020058c:	fee79be3          	bne	a5,a4,ffffffffc0200582 <buddy_init+0x10>
    }
}
ffffffffc0200590:	8082                	ret

ffffffffc0200592 <buddy_nr_free_pages>:
    }
}

static size_t buddy_nr_free_pages(void) {
    size_t total = 0;
    for (size_t i = 0; i < MAX_ORDER; i++) total += buddy_areas[i].nr_free;
ffffffffc0200592:	00006797          	auipc	a5,0x6
ffffffffc0200596:	a9678793          	addi	a5,a5,-1386 # ffffffffc0206028 <buddy_areas+0x10>
ffffffffc020059a:	00006697          	auipc	a3,0x6
ffffffffc020059e:	bf668693          	addi	a3,a3,-1034 # ffffffffc0206190 <caches+0x10>
    size_t total = 0;
ffffffffc02005a2:	4501                	li	a0,0
    for (size_t i = 0; i < MAX_ORDER; i++) total += buddy_areas[i].nr_free;
ffffffffc02005a4:	6398                	ld	a4,0(a5)
ffffffffc02005a6:	07e1                	addi	a5,a5,24
ffffffffc02005a8:	953a                	add	a0,a0,a4
ffffffffc02005aa:	fed79de3          	bne	a5,a3,ffffffffc02005a4 <buddy_nr_free_pages+0x12>
    return total;
}
ffffffffc02005ae:	8082                	ret

ffffffffc02005b0 <buddy_check>:

static void buddy_check(void) {
ffffffffc02005b0:	7119                	addi	sp,sp,-128
ffffffffc02005b2:	fc86                	sd	ra,120(sp)
ffffffffc02005b4:	f8a2                	sd	s0,112(sp)
ffffffffc02005b6:	f0ca                	sd	s2,96(sp)
ffffffffc02005b8:	ecce                	sd	s3,88(sp)
ffffffffc02005ba:	e8d2                	sd	s4,80(sp)
ffffffffc02005bc:	e4d6                	sd	s5,72(sp)
ffffffffc02005be:	e0da                	sd	s6,64(sp)
ffffffffc02005c0:	fc5e                	sd	s7,56(sp)
ffffffffc02005c2:	f862                	sd	s8,48(sp)
ffffffffc02005c4:	f466                	sd	s9,40(sp)
ffffffffc02005c6:	f4a6                	sd	s1,104(sp)
ffffffffc02005c8:	f06a                	sd	s10,32(sp)
ffffffffc02005ca:	ec6e                	sd	s11,24(sp)
    size_t initial_free = nr_free_pages();
ffffffffc02005cc:	15f000ef          	jal	ffffffffc0200f2a <nr_free_pages>

    cprintf("[Buddy 测试] 初始可用页数: %lu\n", initial_free);
ffffffffc02005d0:	85aa                	mv	a1,a0
    size_t initial_free = nr_free_pages();
ffffffffc02005d2:	8caa                	mv	s9,a0
    cprintf("[Buddy 测试] 初始可用页数: %lu\n", initial_free);
ffffffffc02005d4:	00002517          	auipc	a0,0x2
ffffffffc02005d8:	9c450513          	addi	a0,a0,-1596 # ffffffffc0201f98 <etext+0x24e>
ffffffffc02005dc:	b71ff0ef          	jal	ffffffffc020014c <cprintf>
    return (size_t)(p - pages);
ffffffffc02005e0:	ccccd7b7          	lui	a5,0xccccd
ffffffffc02005e4:	ccd78793          	addi	a5,a5,-819 # ffffffffcccccccd <end+0xcac69dd>
ffffffffc02005e8:	02079913          	slli	s2,a5,0x20
ffffffffc02005ec:	00006a17          	auipc	s4,0x6
ffffffffc02005f0:	a2ca0a13          	addi	s4,s4,-1492 # ffffffffc0206018 <buddy_areas>
ffffffffc02005f4:	993e                	add	s2,s2,a5
    cprintf("[Buddy 测试] 初始可用页数: %lu\n", initial_free);
ffffffffc02005f6:	8452                	mv	s0,s4

    for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc02005f8:	4a81                	li	s5,0
        cprintf("[Buddy] 阶 %d (块大小 %lu 页) — nr_free(页数) = %lu\n", i, 1UL << i, buddy_areas[i].nr_free);
ffffffffc02005fa:	4b85                	li	s7,1
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02005fc:	00002c17          	auipc	s8,0x2
ffffffffc0200600:	5c4c0c13          	addi	s8,s8,1476 # ffffffffc0202bc0 <nbase>
ffffffffc0200604:	00006997          	auipc	s3,0x6
ffffffffc0200608:	ce498993          	addi	s3,s3,-796 # ffffffffc02062e8 <pages>
    for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc020060c:	4b3d                	li	s6,15
        cprintf("[Buddy] 阶 %d (块大小 %lu 页) — nr_free(页数) = %lu\n", i, 1UL << i, buddy_areas[i].nr_free);
ffffffffc020060e:	6814                	ld	a3,16(s0)
ffffffffc0200610:	015b9633          	sll	a2,s7,s5
ffffffffc0200614:	85d6                	mv	a1,s5
ffffffffc0200616:	00002517          	auipc	a0,0x2
ffffffffc020061a:	9aa50513          	addi	a0,a0,-1622 # ffffffffc0201fc0 <etext+0x276>
ffffffffc020061e:	b2fff0ef          	jal	ffffffffc020014c <cprintf>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200622:	00843d03          	ld	s10,8(s0)
        list_entry_t *le = &buddy_areas[i].free_list;
        int idx = 0;
        while ((le = list_next(le)) != &buddy_areas[i].free_list) {
ffffffffc0200626:	028d0e63          	beq	s10,s0,ffffffffc0200662 <buddy_check+0xb2>
ffffffffc020062a:	000c3483          	ld	s1,0(s8)
        int idx = 0;
ffffffffc020062e:	4d81                	li	s11,0
    return (size_t)(p - pages);
ffffffffc0200630:	0009b783          	ld	a5,0(s3)
            struct Page *p = le2page(le, page_link);
ffffffffc0200634:	fe8d0613          	addi	a2,s10,-24
            cprintf(" 块 %d: 页索引=%lu, 物理地址=0x%016lx, property=%u\n", idx++, page_index(p), page2pa(p), p->property);
ffffffffc0200638:	ff8d2703          	lw	a4,-8(s10)
    return (size_t)(p - pages);
ffffffffc020063c:	8e1d                	sub	a2,a2,a5
ffffffffc020063e:	860d                	srai	a2,a2,0x3
ffffffffc0200640:	03260633          	mul	a2,a2,s2
ffffffffc0200644:	85ee                	mv	a1,s11
            cprintf(" 块 %d: 页索引=%lu, 物理地址=0x%016lx, property=%u\n", idx++, page_index(p), page2pa(p), p->property);
ffffffffc0200646:	00002517          	auipc	a0,0x2
ffffffffc020064a:	9ba50513          	addi	a0,a0,-1606 # ffffffffc0202000 <etext+0x2b6>
ffffffffc020064e:	2d85                	addiw	s11,s11,1
ffffffffc0200650:	009606b3          	add	a3,a2,s1
ffffffffc0200654:	06b2                	slli	a3,a3,0xc
ffffffffc0200656:	af7ff0ef          	jal	ffffffffc020014c <cprintf>
ffffffffc020065a:	008d3d03          	ld	s10,8(s10)
        while ((le = list_next(le)) != &buddy_areas[i].free_list) {
ffffffffc020065e:	fc8d19e3          	bne	s10,s0,ffffffffc0200630 <buddy_check+0x80>
    for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc0200662:	2a85                	addiw	s5,s5,1
ffffffffc0200664:	0461                	addi	s0,s0,24
ffffffffc0200666:	fb6a94e3          	bne	s5,s6,ffffffffc020060e <buddy_check+0x5e>
        }
    }

    /* 单页分配/释放测试 */
    cprintf("[Buddy 测试] 单页分配/释放测试开始\n");
ffffffffc020066a:	00002517          	auipc	a0,0x2
ffffffffc020066e:	9d650513          	addi	a0,a0,-1578 # ffffffffc0202040 <etext+0x2f6>
ffffffffc0200672:	adbff0ef          	jal	ffffffffc020014c <cprintf>
    struct Page *p0 = alloc_page();
ffffffffc0200676:	4505                	li	a0,1
ffffffffc0200678:	09b000ef          	jal	ffffffffc0200f12 <alloc_pages>
ffffffffc020067c:	8aaa                	mv	s5,a0
    struct Page *p1 = alloc_page();
ffffffffc020067e:	4505                	li	a0,1
ffffffffc0200680:	093000ef          	jal	ffffffffc0200f12 <alloc_pages>
ffffffffc0200684:	892a                	mv	s2,a0
    struct Page *p2 = alloc_page();
ffffffffc0200686:	4505                	li	a0,1
ffffffffc0200688:	08b000ef          	jal	ffffffffc0200f12 <alloc_pages>
    assert(p0 && p1 && p2);
ffffffffc020068c:	001ab793          	seqz	a5,s5
ffffffffc0200690:	00193713          	seqz	a4,s2
ffffffffc0200694:	8fd9                	or	a5,a5,a4
    struct Page *p2 = alloc_page();
ffffffffc0200696:	89aa                	mv	s3,a0
    assert(p0 && p1 && p2);
ffffffffc0200698:	3e079963          	bnez	a5,ffffffffc0200a8a <buddy_check+0x4da>
ffffffffc020069c:	3e050763          	beqz	a0,ffffffffc0200a8a <buddy_check+0x4da>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02006a0:	412a87b3          	sub	a5,s5,s2
ffffffffc02006a4:	40aa8733          	sub	a4,s5,a0
ffffffffc02006a8:	0017b793          	seqz	a5,a5
ffffffffc02006ac:	00173713          	seqz	a4,a4
ffffffffc02006b0:	8fd9                	or	a5,a5,a4
ffffffffc02006b2:	3a079c63          	bnez	a5,ffffffffc0200a6a <buddy_check+0x4ba>
ffffffffc02006b6:	3aa90a63          	beq	s2,a0,ffffffffc0200a6a <buddy_check+0x4ba>
    return (size_t)(p - pages);
ffffffffc02006ba:	00006497          	auipc	s1,0x6
ffffffffc02006be:	c2e48493          	addi	s1,s1,-978 # ffffffffc02062e8 <pages>
ffffffffc02006c2:	609c                	ld	a5,0(s1)
ffffffffc02006c4:	ccccd737          	lui	a4,0xccccd
ffffffffc02006c8:	ccd70713          	addi	a4,a4,-819 # ffffffffcccccccd <end+0xcac69dd>
ffffffffc02006cc:	40f506b3          	sub	a3,a0,a5
ffffffffc02006d0:	02071413          	slli	s0,a4,0x20
ffffffffc02006d4:	40f90633          	sub	a2,s2,a5
ffffffffc02006d8:	40fa87b3          	sub	a5,s5,a5
ffffffffc02006dc:	943a                	add	s0,s0,a4
ffffffffc02006de:	4037d593          	srai	a1,a5,0x3
ffffffffc02006e2:	868d                	srai	a3,a3,0x3
ffffffffc02006e4:	860d                	srai	a2,a2,0x3
    cprintf("  分配到页索引: %lu, %lu, %lu\n", page_index(p0), page_index(p1), page_index(p2));
ffffffffc02006e6:	028686b3          	mul	a3,a3,s0
ffffffffc02006ea:	00002517          	auipc	a0,0x2
ffffffffc02006ee:	9ee50513          	addi	a0,a0,-1554 # ffffffffc02020d8 <etext+0x38e>
ffffffffc02006f2:	02860633          	mul	a2,a2,s0
ffffffffc02006f6:	028585b3          	mul	a1,a1,s0
ffffffffc02006fa:	a53ff0ef          	jal	ffffffffc020014c <cprintf>
    assert(nr_free_pages() == initial_free - 3);
ffffffffc02006fe:	02d000ef          	jal	ffffffffc0200f2a <nr_free_pages>
ffffffffc0200702:	ffdc8793          	addi	a5,s9,-3
ffffffffc0200706:	34f51263          	bne	a0,a5,ffffffffc0200a4a <buddy_check+0x49a>
    free_page(p0);
ffffffffc020070a:	8556                	mv	a0,s5
ffffffffc020070c:	4585                	li	a1,1
ffffffffc020070e:	011000ef          	jal	ffffffffc0200f1e <free_pages>
    free_page(p1);
ffffffffc0200712:	854a                	mv	a0,s2
ffffffffc0200714:	4585                	li	a1,1
ffffffffc0200716:	009000ef          	jal	ffffffffc0200f1e <free_pages>
    free_page(p2);
ffffffffc020071a:	854e                	mv	a0,s3
ffffffffc020071c:	4585                	li	a1,1
ffffffffc020071e:	001000ef          	jal	ffffffffc0200f1e <free_pages>
    assert(nr_free_pages() == initial_free);
ffffffffc0200722:	009000ef          	jal	ffffffffc0200f2a <nr_free_pages>
ffffffffc0200726:	31951263          	bne	a0,s9,ffffffffc0200a2a <buddy_check+0x47a>
    cprintf("[Buddy 测试] 单页测试通过\n");
ffffffffc020072a:	00002517          	auipc	a0,0x2
ffffffffc020072e:	a1e50513          	addi	a0,a0,-1506 # ffffffffc0202148 <etext+0x3fe>
ffffffffc0200732:	a1bff0ef          	jal	ffffffffc020014c <cprintf>

    /* 多页分配/释放测试 */
    cprintf("[Buddy 测试] 多页分配/释放测试开始\n");
ffffffffc0200736:	00002517          	auipc	a0,0x2
ffffffffc020073a:	a3a50513          	addi	a0,a0,-1478 # ffffffffc0202170 <etext+0x426>
ffffffffc020073e:	a0fff0ef          	jal	ffffffffc020014c <cprintf>
    struct Page *pa4 = alloc_pages(4);
ffffffffc0200742:	4511                	li	a0,4
ffffffffc0200744:	7ce000ef          	jal	ffffffffc0200f12 <alloc_pages>
ffffffffc0200748:	89aa                	mv	s3,a0
    struct Page *pb2 = alloc_pages(2);
ffffffffc020074a:	4509                	li	a0,2
ffffffffc020074c:	7c6000ef          	jal	ffffffffc0200f12 <alloc_pages>
ffffffffc0200750:	892a                	mv	s2,a0
    assert(pa4 && pb2);
ffffffffc0200752:	2a098c63          	beqz	s3,ffffffffc0200a0a <buddy_check+0x45a>
ffffffffc0200756:	2a050a63          	beqz	a0,ffffffffc0200a0a <buddy_check+0x45a>
    return (size_t)(p - pages);
ffffffffc020075a:	609c                	ld	a5,0(s1)
    cprintf("  分配 4 页起始页索引=%lu, 2 页起始页索引=%lu\n", page_index(pa4), page_index(pb2));
ffffffffc020075c:	00002517          	auipc	a0,0x2
ffffffffc0200760:	a5450513          	addi	a0,a0,-1452 # ffffffffc02021b0 <etext+0x466>
    return (size_t)(p - pages);
ffffffffc0200764:	40f90633          	sub	a2,s2,a5
ffffffffc0200768:	40f987b3          	sub	a5,s3,a5
ffffffffc020076c:	4037d593          	srai	a1,a5,0x3
ffffffffc0200770:	860d                	srai	a2,a2,0x3
    cprintf("  分配 4 页起始页索引=%lu, 2 页起始页索引=%lu\n", page_index(pa4), page_index(pb2));
ffffffffc0200772:	02860633          	mul	a2,a2,s0
ffffffffc0200776:	028585b3          	mul	a1,a1,s0
ffffffffc020077a:	9d3ff0ef          	jal	ffffffffc020014c <cprintf>
    assert(nr_free_pages() == initial_free - (4 + 2));
ffffffffc020077e:	7ac000ef          	jal	ffffffffc0200f2a <nr_free_pages>
ffffffffc0200782:	ffac8793          	addi	a5,s9,-6
ffffffffc0200786:	26f51263          	bne	a0,a5,ffffffffc02009ea <buddy_check+0x43a>
    free_pages(pa4, 4);
ffffffffc020078a:	854e                	mv	a0,s3
ffffffffc020078c:	4591                	li	a1,4
ffffffffc020078e:	790000ef          	jal	ffffffffc0200f1e <free_pages>
    free_pages(pb2, 2);
ffffffffc0200792:	854a                	mv	a0,s2
ffffffffc0200794:	4589                	li	a1,2
ffffffffc0200796:	788000ef          	jal	ffffffffc0200f1e <free_pages>
    assert(nr_free_pages() == initial_free);
ffffffffc020079a:	790000ef          	jal	ffffffffc0200f2a <nr_free_pages>
ffffffffc020079e:	23951663          	bne	a0,s9,ffffffffc02009ca <buddy_check+0x41a>
    cprintf("[Buddy 测试] 多页测试通过\n");
ffffffffc02007a2:	00002517          	auipc	a0,0x2
ffffffffc02007a6:	a7e50513          	addi	a0,a0,-1410 # ffffffffc0202220 <etext+0x4d6>
ffffffffc02007aa:	9a3ff0ef          	jal	ffffffffc020014c <cprintf>

    /* 分割与合并验证 */
    cprintf("[Buddy 测试] split/merge 测试开始\n");
ffffffffc02007ae:	00002517          	auipc	a0,0x2
ffffffffc02007b2:	a9a50513          	addi	a0,a0,-1382 # ffffffffc0202248 <etext+0x4fe>
ffffffffc02007b6:	997ff0ef          	jal	ffffffffc020014c <cprintf>
    if (initial_free >= 8) {
ffffffffc02007ba:	479d                	li	a5,7
ffffffffc02007bc:	1597f063          	bgeu	a5,s9,ffffffffc02008fc <buddy_check+0x34c>
        struct Page *p8 = alloc_pages(8);
ffffffffc02007c0:	4521                	li	a0,8
ffffffffc02007c2:	750000ef          	jal	ffffffffc0200f12 <alloc_pages>
ffffffffc02007c6:	842a                	mv	s0,a0
        assert(p8 != NULL);
ffffffffc02007c8:	18050163          	beqz	a0,ffffffffc020094a <buddy_check+0x39a>
    return (size_t)(p - pages);
ffffffffc02007cc:	608c                	ld	a1,0(s1)
ffffffffc02007ce:	ccccd7b7          	lui	a5,0xccccd
ffffffffc02007d2:	ccd78793          	addi	a5,a5,-819 # ffffffffcccccccd <end+0xcac69dd>
ffffffffc02007d6:	02079913          	slli	s2,a5,0x20
ffffffffc02007da:	40b505b3          	sub	a1,a0,a1
ffffffffc02007de:	993e                	add	s2,s2,a5
ffffffffc02007e0:	858d                	srai	a1,a1,0x3
        cprintf("  分配 8 页起始页索引=%lu\n", page_index(p8));
ffffffffc02007e2:	032585b3          	mul	a1,a1,s2
ffffffffc02007e6:	00002517          	auipc	a0,0x2
ffffffffc02007ea:	aa250513          	addi	a0,a0,-1374 # ffffffffc0202288 <etext+0x53e>
ffffffffc02007ee:	95fff0ef          	jal	ffffffffc020014c <cprintf>
        free_pages(p8, 8);
ffffffffc02007f2:	45a1                	li	a1,8
ffffffffc02007f4:	8522                	mv	a0,s0
ffffffffc02007f6:	728000ef          	jal	ffffffffc0200f1e <free_pages>

        struct Page *a = alloc_pages(4);
ffffffffc02007fa:	4511                	li	a0,4
ffffffffc02007fc:	716000ef          	jal	ffffffffc0200f12 <alloc_pages>
ffffffffc0200800:	8d2a                	mv	s10,a0
        struct Page *b = alloc_pages(4);
ffffffffc0200802:	4511                	li	a0,4
ffffffffc0200804:	70e000ef          	jal	ffffffffc0200f12 <alloc_pages>
        assert(a && b && a != b);
ffffffffc0200808:	001d3793          	seqz	a5,s10
ffffffffc020080c:	00153713          	seqz	a4,a0
        struct Page *b = alloc_pages(4);
ffffffffc0200810:	e42a                	sd	a0,8(sp)
        assert(a && b && a != b);
ffffffffc0200812:	8fd9                	or	a5,a5,a4
ffffffffc0200814:	14079b63          	bnez	a5,ffffffffc020096a <buddy_check+0x3ba>
ffffffffc0200818:	14ad0963          	beq	s10,a0,ffffffffc020096a <buddy_check+0x3ba>
    return (size_t)(p - pages);
ffffffffc020081c:	609c                	ld	a5,0(s1)
ffffffffc020081e:	6722                	ld	a4,8(sp)
        cprintf("  分配到两个 4 页块: %lu, %lu\n", page_index(a), page_index(b));
ffffffffc0200820:	00002517          	auipc	a0,0x2
ffffffffc0200824:	aa850513          	addi	a0,a0,-1368 # ffffffffc02022c8 <etext+0x57e>
        for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc0200828:	4981                	li	s3,0
    return (size_t)(p - pages);
ffffffffc020082a:	40f70633          	sub	a2,a4,a5
ffffffffc020082e:	40fd07b3          	sub	a5,s10,a5
ffffffffc0200832:	4037d593          	srai	a1,a5,0x3
ffffffffc0200836:	860d                	srai	a2,a2,0x3
        cprintf("  分配到两个 4 页块: %lu, %lu\n", page_index(a), page_index(b));
ffffffffc0200838:	03260633          	mul	a2,a2,s2
            cprintf("[Buddy] 阶 %d (块大小 %lu 页) — nr_free(页数) = %lu\n", i, 1UL << i, buddy_areas[i].nr_free);
ffffffffc020083c:	4b05                	li	s6,1
ffffffffc020083e:	00002b97          	auipc	s7,0x2
ffffffffc0200842:	382b8b93          	addi	s7,s7,898 # ffffffffc0202bc0 <nbase>
        for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc0200846:	4abd                	li	s5,15
        cprintf("  分配到两个 4 页块: %lu, %lu\n", page_index(a), page_index(b));
ffffffffc0200848:	032585b3          	mul	a1,a1,s2
ffffffffc020084c:	901ff0ef          	jal	ffffffffc020014c <cprintf>
            cprintf("[Buddy] 阶 %d (块大小 %lu 页) — nr_free(页数) = %lu\n", i, 1UL << i, buddy_areas[i].nr_free);
ffffffffc0200850:	010a3683          	ld	a3,16(s4)
ffffffffc0200854:	013b1633          	sll	a2,s6,s3
ffffffffc0200858:	85ce                	mv	a1,s3
ffffffffc020085a:	00001517          	auipc	a0,0x1
ffffffffc020085e:	76650513          	addi	a0,a0,1894 # ffffffffc0201fc0 <etext+0x276>
ffffffffc0200862:	8ebff0ef          	jal	ffffffffc020014c <cprintf>
ffffffffc0200866:	008a3d83          	ld	s11,8(s4)
            list_entry_t *le = &buddy_areas[i].free_list;
            int idx = 0;
            while ((le = list_next(le)) != &buddy_areas[i].free_list) {
ffffffffc020086a:	034d8d63          	beq	s11,s4,ffffffffc02008a4 <buddy_check+0x2f4>
ffffffffc020086e:	000bb403          	ld	s0,0(s7)
            int idx = 0;
ffffffffc0200872:	4c01                	li	s8,0
    return (size_t)(p - pages);
ffffffffc0200874:	6094                	ld	a3,0(s1)
                struct Page *p = le2page(le, page_link);
ffffffffc0200876:	fe8d8613          	addi	a2,s11,-24
                cprintf(" 块 %d: 页索引=%lu, 物理地址=0x%016lx, property=%u\n", idx++, page_index(p), page2pa(p), p->property);
ffffffffc020087a:	ff8da703          	lw	a4,-8(s11)
    return (size_t)(p - pages);
ffffffffc020087e:	8e15                	sub	a2,a2,a3
ffffffffc0200880:	860d                	srai	a2,a2,0x3
ffffffffc0200882:	03260633          	mul	a2,a2,s2
ffffffffc0200886:	85e2                	mv	a1,s8
                cprintf(" 块 %d: 页索引=%lu, 物理地址=0x%016lx, property=%u\n", idx++, page_index(p), page2pa(p), p->property);
ffffffffc0200888:	00001517          	auipc	a0,0x1
ffffffffc020088c:	77850513          	addi	a0,a0,1912 # ffffffffc0202000 <etext+0x2b6>
ffffffffc0200890:	2c05                	addiw	s8,s8,1
ffffffffc0200892:	008606b3          	add	a3,a2,s0
ffffffffc0200896:	06b2                	slli	a3,a3,0xc
ffffffffc0200898:	8b5ff0ef          	jal	ffffffffc020014c <cprintf>
ffffffffc020089c:	008dbd83          	ld	s11,8(s11)
            while ((le = list_next(le)) != &buddy_areas[i].free_list) {
ffffffffc02008a0:	fd4d9ae3          	bne	s11,s4,ffffffffc0200874 <buddy_check+0x2c4>
        for (int i = 0; i < MAX_ORDER; i++) {
ffffffffc02008a4:	2985                	addiw	s3,s3,1
ffffffffc02008a6:	0a61                	addi	s4,s4,24
ffffffffc02008a8:	fb5994e3          	bne	s3,s5,ffffffffc0200850 <buddy_check+0x2a0>
            }
        }
        free_pages(a, 4);
ffffffffc02008ac:	856a                	mv	a0,s10
ffffffffc02008ae:	4591                	li	a1,4
ffffffffc02008b0:	66e000ef          	jal	ffffffffc0200f1e <free_pages>
        free_pages(b, 4);
ffffffffc02008b4:	6522                	ld	a0,8(sp)
ffffffffc02008b6:	4591                	li	a1,4
ffffffffc02008b8:	666000ef          	jal	ffffffffc0200f1e <free_pages>
        struct Page *p8b = alloc_pages(8);
ffffffffc02008bc:	4521                	li	a0,8
ffffffffc02008be:	654000ef          	jal	ffffffffc0200f12 <alloc_pages>
ffffffffc02008c2:	842a                	mv	s0,a0
        assert(p8b != NULL);
ffffffffc02008c4:	c179                	beqz	a0,ffffffffc020098a <buddy_check+0x3da>
    return (size_t)(p - pages);
ffffffffc02008c6:	609c                	ld	a5,0(s1)
ffffffffc02008c8:	ccccd737          	lui	a4,0xccccd
ffffffffc02008cc:	ccd70713          	addi	a4,a4,-819 # ffffffffcccccccd <end+0xcac69dd>
ffffffffc02008d0:	02071593          	slli	a1,a4,0x20
ffffffffc02008d4:	40f507b3          	sub	a5,a0,a5
ffffffffc02008d8:	878d                	srai	a5,a5,0x3
ffffffffc02008da:	95ba                	add	a1,a1,a4
        cprintf("  合并后再次分配 8 页起始页索引=%lu\n", page_index(p8b));
ffffffffc02008dc:	02b785b3          	mul	a1,a5,a1
ffffffffc02008e0:	00002517          	auipc	a0,0x2
ffffffffc02008e4:	a2050513          	addi	a0,a0,-1504 # ffffffffc0202300 <etext+0x5b6>
ffffffffc02008e8:	865ff0ef          	jal	ffffffffc020014c <cprintf>
        free_pages(p8b, 8);
ffffffffc02008ec:	8522                	mv	a0,s0
ffffffffc02008ee:	45a1                	li	a1,8
ffffffffc02008f0:	62e000ef          	jal	ffffffffc0200f1e <free_pages>
        assert(nr_free_pages() == initial_free);
ffffffffc02008f4:	636000ef          	jal	ffffffffc0200f2a <nr_free_pages>
ffffffffc02008f8:	0b951963          	bne	a0,s9,ffffffffc02009aa <buddy_check+0x3fa>
    }
    cprintf("[Buddy 测试] split/merge 测试通过\n");
ffffffffc02008fc:	00002517          	auipc	a0,0x2
ffffffffc0200900:	a3c50513          	addi	a0,a0,-1476 # ffffffffc0202338 <etext+0x5ee>
ffffffffc0200904:	849ff0ef          	jal	ffffffffc020014c <cprintf>

    cprintf("[Buddy 测试] 结束，可用页数: %lu\n", nr_free_pages());
ffffffffc0200908:	622000ef          	jal	ffffffffc0200f2a <nr_free_pages>
ffffffffc020090c:	85aa                	mv	a1,a0
ffffffffc020090e:	00002517          	auipc	a0,0x2
ffffffffc0200912:	a5a50513          	addi	a0,a0,-1446 # ffffffffc0202368 <etext+0x61e>
ffffffffc0200916:	837ff0ef          	jal	ffffffffc020014c <cprintf>

    /* 边界：请求超过总页数应该返回 NULL */
    assert(alloc_pages(npage + 1) == NULL);
ffffffffc020091a:	00006517          	auipc	a0,0x6
ffffffffc020091e:	9c653503          	ld	a0,-1594(a0) # ffffffffc02062e0 <npage>
ffffffffc0200922:	0505                	addi	a0,a0,1
ffffffffc0200924:	5ee000ef          	jal	ffffffffc0200f12 <alloc_pages>
ffffffffc0200928:	18051163          	bnez	a0,ffffffffc0200aaa <buddy_check+0x4fa>
}
ffffffffc020092c:	70e6                	ld	ra,120(sp)
ffffffffc020092e:	7446                	ld	s0,112(sp)
ffffffffc0200930:	74a6                	ld	s1,104(sp)
ffffffffc0200932:	7906                	ld	s2,96(sp)
ffffffffc0200934:	69e6                	ld	s3,88(sp)
ffffffffc0200936:	6a46                	ld	s4,80(sp)
ffffffffc0200938:	6aa6                	ld	s5,72(sp)
ffffffffc020093a:	6b06                	ld	s6,64(sp)
ffffffffc020093c:	7be2                	ld	s7,56(sp)
ffffffffc020093e:	7c42                	ld	s8,48(sp)
ffffffffc0200940:	7ca2                	ld	s9,40(sp)
ffffffffc0200942:	7d02                	ld	s10,32(sp)
ffffffffc0200944:	6de2                	ld	s11,24(sp)
ffffffffc0200946:	6109                	addi	sp,sp,128
ffffffffc0200948:	8082                	ret
        assert(p8 != NULL);
ffffffffc020094a:	00002697          	auipc	a3,0x2
ffffffffc020094e:	92e68693          	addi	a3,a3,-1746 # ffffffffc0202278 <etext+0x52e>
ffffffffc0200952:	00001617          	auipc	a2,0x1
ffffffffc0200956:	72e60613          	addi	a2,a2,1838 # ffffffffc0202080 <etext+0x336>
ffffffffc020095a:	0e600593          	li	a1,230
ffffffffc020095e:	00001517          	auipc	a0,0x1
ffffffffc0200962:	73a50513          	addi	a0,a0,1850 # ffffffffc0202098 <etext+0x34e>
ffffffffc0200966:	867ff0ef          	jal	ffffffffc02001cc <__panic>
        assert(a && b && a != b);
ffffffffc020096a:	00002697          	auipc	a3,0x2
ffffffffc020096e:	94668693          	addi	a3,a3,-1722 # ffffffffc02022b0 <etext+0x566>
ffffffffc0200972:	00001617          	auipc	a2,0x1
ffffffffc0200976:	70e60613          	addi	a2,a2,1806 # ffffffffc0202080 <etext+0x336>
ffffffffc020097a:	0ec00593          	li	a1,236
ffffffffc020097e:	00001517          	auipc	a0,0x1
ffffffffc0200982:	71a50513          	addi	a0,a0,1818 # ffffffffc0202098 <etext+0x34e>
ffffffffc0200986:	847ff0ef          	jal	ffffffffc02001cc <__panic>
        assert(p8b != NULL);
ffffffffc020098a:	00002697          	auipc	a3,0x2
ffffffffc020098e:	96668693          	addi	a3,a3,-1690 # ffffffffc02022f0 <etext+0x5a6>
ffffffffc0200992:	00001617          	auipc	a2,0x1
ffffffffc0200996:	6ee60613          	addi	a2,a2,1774 # ffffffffc0202080 <etext+0x336>
ffffffffc020099a:	0fa00593          	li	a1,250
ffffffffc020099e:	00001517          	auipc	a0,0x1
ffffffffc02009a2:	6fa50513          	addi	a0,a0,1786 # ffffffffc0202098 <etext+0x34e>
ffffffffc02009a6:	827ff0ef          	jal	ffffffffc02001cc <__panic>
        assert(nr_free_pages() == initial_free);
ffffffffc02009aa:	00001697          	auipc	a3,0x1
ffffffffc02009ae:	77e68693          	addi	a3,a3,1918 # ffffffffc0202128 <etext+0x3de>
ffffffffc02009b2:	00001617          	auipc	a2,0x1
ffffffffc02009b6:	6ce60613          	addi	a2,a2,1742 # ffffffffc0202080 <etext+0x336>
ffffffffc02009ba:	0fd00593          	li	a1,253
ffffffffc02009be:	00001517          	auipc	a0,0x1
ffffffffc02009c2:	6da50513          	addi	a0,a0,1754 # ffffffffc0202098 <etext+0x34e>
ffffffffc02009c6:	807ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(nr_free_pages() == initial_free);
ffffffffc02009ca:	00001697          	auipc	a3,0x1
ffffffffc02009ce:	75e68693          	addi	a3,a3,1886 # ffffffffc0202128 <etext+0x3de>
ffffffffc02009d2:	00001617          	auipc	a2,0x1
ffffffffc02009d6:	6ae60613          	addi	a2,a2,1710 # ffffffffc0202080 <etext+0x336>
ffffffffc02009da:	0df00593          	li	a1,223
ffffffffc02009de:	00001517          	auipc	a0,0x1
ffffffffc02009e2:	6ba50513          	addi	a0,a0,1722 # ffffffffc0202098 <etext+0x34e>
ffffffffc02009e6:	fe6ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(nr_free_pages() == initial_free - (4 + 2));
ffffffffc02009ea:	00002697          	auipc	a3,0x2
ffffffffc02009ee:	80668693          	addi	a3,a3,-2042 # ffffffffc02021f0 <etext+0x4a6>
ffffffffc02009f2:	00001617          	auipc	a2,0x1
ffffffffc02009f6:	68e60613          	addi	a2,a2,1678 # ffffffffc0202080 <etext+0x336>
ffffffffc02009fa:	0dc00593          	li	a1,220
ffffffffc02009fe:	00001517          	auipc	a0,0x1
ffffffffc0200a02:	69a50513          	addi	a0,a0,1690 # ffffffffc0202098 <etext+0x34e>
ffffffffc0200a06:	fc6ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(pa4 && pb2);
ffffffffc0200a0a:	00001697          	auipc	a3,0x1
ffffffffc0200a0e:	79668693          	addi	a3,a3,1942 # ffffffffc02021a0 <etext+0x456>
ffffffffc0200a12:	00001617          	auipc	a2,0x1
ffffffffc0200a16:	66e60613          	addi	a2,a2,1646 # ffffffffc0202080 <etext+0x336>
ffffffffc0200a1a:	0da00593          	li	a1,218
ffffffffc0200a1e:	00001517          	auipc	a0,0x1
ffffffffc0200a22:	67a50513          	addi	a0,a0,1658 # ffffffffc0202098 <etext+0x34e>
ffffffffc0200a26:	fa6ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(nr_free_pages() == initial_free);
ffffffffc0200a2a:	00001697          	auipc	a3,0x1
ffffffffc0200a2e:	6fe68693          	addi	a3,a3,1790 # ffffffffc0202128 <etext+0x3de>
ffffffffc0200a32:	00001617          	auipc	a2,0x1
ffffffffc0200a36:	64e60613          	addi	a2,a2,1614 # ffffffffc0202080 <etext+0x336>
ffffffffc0200a3a:	0d300593          	li	a1,211
ffffffffc0200a3e:	00001517          	auipc	a0,0x1
ffffffffc0200a42:	65a50513          	addi	a0,a0,1626 # ffffffffc0202098 <etext+0x34e>
ffffffffc0200a46:	f86ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(nr_free_pages() == initial_free - 3);
ffffffffc0200a4a:	00001697          	auipc	a3,0x1
ffffffffc0200a4e:	6b668693          	addi	a3,a3,1718 # ffffffffc0202100 <etext+0x3b6>
ffffffffc0200a52:	00001617          	auipc	a2,0x1
ffffffffc0200a56:	62e60613          	addi	a2,a2,1582 # ffffffffc0202080 <etext+0x336>
ffffffffc0200a5a:	0cf00593          	li	a1,207
ffffffffc0200a5e:	00001517          	auipc	a0,0x1
ffffffffc0200a62:	63a50513          	addi	a0,a0,1594 # ffffffffc0202098 <etext+0x34e>
ffffffffc0200a66:	f66ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200a6a:	00001697          	auipc	a3,0x1
ffffffffc0200a6e:	64668693          	addi	a3,a3,1606 # ffffffffc02020b0 <etext+0x366>
ffffffffc0200a72:	00001617          	auipc	a2,0x1
ffffffffc0200a76:	60e60613          	addi	a2,a2,1550 # ffffffffc0202080 <etext+0x336>
ffffffffc0200a7a:	0cd00593          	li	a1,205
ffffffffc0200a7e:	00001517          	auipc	a0,0x1
ffffffffc0200a82:	61a50513          	addi	a0,a0,1562 # ffffffffc0202098 <etext+0x34e>
ffffffffc0200a86:	f46ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(p0 && p1 && p2);
ffffffffc0200a8a:	00001697          	auipc	a3,0x1
ffffffffc0200a8e:	5e668693          	addi	a3,a3,1510 # ffffffffc0202070 <etext+0x326>
ffffffffc0200a92:	00001617          	auipc	a2,0x1
ffffffffc0200a96:	5ee60613          	addi	a2,a2,1518 # ffffffffc0202080 <etext+0x336>
ffffffffc0200a9a:	0cc00593          	li	a1,204
ffffffffc0200a9e:	00001517          	auipc	a0,0x1
ffffffffc0200aa2:	5fa50513          	addi	a0,a0,1530 # ffffffffc0202098 <etext+0x34e>
ffffffffc0200aa6:	f26ff0ef          	jal	ffffffffc02001cc <__panic>
    assert(alloc_pages(npage + 1) == NULL);
ffffffffc0200aaa:	00002697          	auipc	a3,0x2
ffffffffc0200aae:	8ee68693          	addi	a3,a3,-1810 # ffffffffc0202398 <etext+0x64e>
ffffffffc0200ab2:	00001617          	auipc	a2,0x1
ffffffffc0200ab6:	5ce60613          	addi	a2,a2,1486 # ffffffffc0202080 <etext+0x336>
ffffffffc0200aba:	10400593          	li	a1,260
ffffffffc0200abe:	00001517          	auipc	a0,0x1
ffffffffc0200ac2:	5da50513          	addi	a0,a0,1498 # ffffffffc0202098 <etext+0x34e>
ffffffffc0200ac6:	f06ff0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc0200aca <buddy_free_pages>:
static void buddy_free_pages(struct Page *base, size_t n) {
ffffffffc0200aca:	7139                	addi	sp,sp,-64
ffffffffc0200acc:	fc06                	sd	ra,56(sp)
ffffffffc0200ace:	f822                	sd	s0,48(sp)
ffffffffc0200ad0:	f426                	sd	s1,40(sp)
ffffffffc0200ad2:	f04a                	sd	s2,32(sp)
ffffffffc0200ad4:	ec4e                	sd	s3,24(sp)
ffffffffc0200ad6:	e852                	sd	s4,16(sp)
ffffffffc0200ad8:	e456                	sd	s5,8(sp)
    assert(n > 0);
ffffffffc0200ada:	18058563          	beqz	a1,ffffffffc0200c64 <buddy_free_pages+0x19a>
    return (size_t)(p - pages);
ffffffffc0200ade:	ccccd7b7          	lui	a5,0xccccd
ffffffffc0200ae2:	ccd78793          	addi	a5,a5,-819 # ffffffffcccccccd <end+0xcac69dd>
ffffffffc0200ae6:	00006e17          	auipc	t3,0x6
ffffffffc0200aea:	802e3e03          	ld	t3,-2046(t3) # ffffffffc02062e8 <pages>
    if (buddy_idx >= npage) return NULL;
ffffffffc0200aee:	00005297          	auipc	t0,0x5
ffffffffc0200af2:	7f22b283          	ld	t0,2034(t0) # ffffffffc02062e0 <npage>
    return (size_t)(p - pages);
ffffffffc0200af6:	02079f93          	slli	t6,a5,0x20
ffffffffc0200afa:	842a                	mv	s0,a0
ffffffffc0200afc:	9fbe                	add	t6,t6,a5
    size_t off = 0;
ffffffffc0200afe:	4e81                	li	t4,0
ffffffffc0200b00:	00005517          	auipc	a0,0x5
ffffffffc0200b04:	51850513          	addi	a0,a0,1304 # ffffffffc0206018 <buddy_areas>
    while (sz < n) {
ffffffffc0200b08:	4f05                	li	t5,1
        while ((gidx & ((1UL << cur_k) - 1)) != 0) {
ffffffffc0200b0a:	537d                	li	t1,-1
        while (pk + 1 < MAX_ORDER) {
ffffffffc0200b0c:	44b5                	li	s1,13
ffffffffc0200b0e:	43b9                	li	t2,14
        struct Page *cur = base + off;
ffffffffc0200b10:	002e9613          	slli	a2,t4,0x2
ffffffffc0200b14:	9676                	add	a2,a2,t4
ffffffffc0200b16:	060e                	slli	a2,a2,0x3
        size_t remaining = n - off;
ffffffffc0200b18:	41d58933          	sub	s2,a1,t4
        struct Page *cur = base + off;
ffffffffc0200b1c:	9622                	add	a2,a2,s0
    int k = 0;
ffffffffc0200b1e:	4781                	li	a5,0
    size_t sz = 1;
ffffffffc0200b20:	4705                	li	a4,1
    while (sz < n) {
ffffffffc0200b22:	13e90063          	beq	s2,t5,ffffffffc0200c42 <buddy_free_pages+0x178>
        sz <<= 1;
ffffffffc0200b26:	0706                	slli	a4,a4,0x1
        k++;
ffffffffc0200b28:	2785                	addiw	a5,a5,1
    while (sz < n) {
ffffffffc0200b2a:	ff276ee3          	bltu	a4,s2,ffffffffc0200b26 <buddy_free_pages+0x5c>
    return (size_t)(p - pages);
ffffffffc0200b2e:	41c606b3          	sub	a3,a2,t3
ffffffffc0200b32:	4036d813          	srai	a6,a3,0x3
ffffffffc0200b36:	03f80833          	mul	a6,a6,t6
        while ((gidx & ((1UL << cur_k) - 1)) != 0) {
ffffffffc0200b3a:	00f31733          	sll	a4,t1,a5
ffffffffc0200b3e:	fff74713          	not	a4,a4
ffffffffc0200b42:	01077733          	and	a4,a4,a6
ffffffffc0200b46:	12070f63          	beqz	a4,ffffffffc0200c84 <buddy_free_pages+0x1ba>
            cur_k--;
ffffffffc0200b4a:	37fd                	addiw	a5,a5,-1
        while ((gidx & ((1UL << cur_k) - 1)) != 0) {
ffffffffc0200b4c:	00f31733          	sll	a4,t1,a5
ffffffffc0200b50:	fff74713          	not	a4,a4
ffffffffc0200b54:	01077733          	and	a4,a4,a6
ffffffffc0200b58:	fb6d                	bnez	a4,ffffffffc0200b4a <buddy_free_pages+0x80>
ffffffffc0200b5a:	00ff1933          	sll	s2,t5,a5
        blk->property = cur_size;
ffffffffc0200b5e:	0009071b          	sext.w	a4,s2
        SetPageProperty(blk);
ffffffffc0200b62:	00863803          	ld	a6,8(a2)
        blk->property = cur_size;
ffffffffc0200b66:	ca18                	sw	a4,16(a2)
        SetPageProperty(blk);
ffffffffc0200b68:	00286813          	ori	a6,a6,2
ffffffffc0200b6c:	01063423          	sd	a6,8(a2)
        while (pk + 1 < MAX_ORDER) {
ffffffffc0200b70:	0ef4c863          	blt	s1,a5,ffffffffc0200c60 <buddy_free_pages+0x196>
    return (size_t)(p - pages);
ffffffffc0200b74:	868d                	srai	a3,a3,0x3
ffffffffc0200b76:	03f686b3          	mul	a3,a3,t6
ffffffffc0200b7a:	00179813          	slli	a6,a5,0x1
ffffffffc0200b7e:	983e                	add	a6,a6,a5
    size_t block_size = 1UL << k; /* 页数 */
ffffffffc0200b80:	00ff18b3          	sll	a7,t5,a5
ffffffffc0200b84:	080e                	slli	a6,a6,0x3
ffffffffc0200b86:	982a                	add	a6,a6,a0
    size_t buddy_idx = idx ^ block_size;
ffffffffc0200b88:	0116c6b3          	xor	a3,a3,a7
    if (buddy_idx >= npage) return NULL;
ffffffffc0200b8c:	0656f663          	bgeu	a3,t0,ffffffffc0200bf8 <buddy_free_pages+0x12e>
    return &pages[buddy_idx];
ffffffffc0200b90:	00269713          	slli	a4,a3,0x2
ffffffffc0200b94:	9736                	add	a4,a4,a3
ffffffffc0200b96:	070e                	slli	a4,a4,0x3
ffffffffc0200b98:	9772                	add	a4,a4,t3
            if (buddy == NULL) break;
ffffffffc0200b9a:	cf39                	beqz	a4,ffffffffc0200bf8 <buddy_free_pages+0x12e>
            if (!PageProperty(buddy) || buddy->property != (1UL << pk)) break;
ffffffffc0200b9c:	6714                	ld	a3,8(a4)
ffffffffc0200b9e:	0026f993          	andi	s3,a3,2
ffffffffc0200ba2:	04098b63          	beqz	s3,ffffffffc0200bf8 <buddy_free_pages+0x12e>
ffffffffc0200ba6:	01076983          	lwu	s3,16(a4)
ffffffffc0200baa:	05389763          	bne	a7,s3,ffffffffc0200bf8 <buddy_free_pages+0x12e>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200bae:	01873a83          	ld	s5,24(a4)
ffffffffc0200bb2:	02073a03          	ld	s4,32(a4)
            buddy_areas[pk].nr_free -= (1UL << pk);
ffffffffc0200bb6:	01083983          	ld	s3,16(a6) # ff0010 <kern_entry-0xffffffffbf20fff0>
            ClearPageProperty(buddy);
ffffffffc0200bba:	9af5                	andi	a3,a3,-3
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200bbc:	014ab423          	sd	s4,8(s5)
    next->prev = prev;
ffffffffc0200bc0:	015a3023          	sd	s5,0(s4)
            buddy_areas[pk].nr_free -= (1UL << pk);
ffffffffc0200bc4:	411988b3          	sub	a7,s3,a7
ffffffffc0200bc8:	01183823          	sd	a7,16(a6)
            ClearPageProperty(buddy);
ffffffffc0200bcc:	e714                	sd	a3,8(a4)
            ClearPageProperty(blk);
ffffffffc0200bce:	6614                	ld	a3,8(a2)
ffffffffc0200bd0:	9af5                	andi	a3,a3,-3
ffffffffc0200bd2:	e614                	sd	a3,8(a2)
            if (buddy < blk) blk = buddy;
ffffffffc0200bd4:	00c77363          	bgeu	a4,a2,ffffffffc0200bda <buddy_free_pages+0x110>
ffffffffc0200bd8:	863a                	mv	a2,a4
            pk++;
ffffffffc0200bda:	2785                	addiw	a5,a5,1
        while (pk + 1 < MAX_ORDER) {
ffffffffc0200bdc:	0861                	addi	a6,a6,24
ffffffffc0200bde:	06778b63          	beq	a5,t2,ffffffffc0200c54 <buddy_free_pages+0x18a>
ffffffffc0200be2:	41c606b3          	sub	a3,a2,t3
    return (size_t)(p - pages);
ffffffffc0200be6:	868d                	srai	a3,a3,0x3
ffffffffc0200be8:	03f686b3          	mul	a3,a3,t6
    size_t block_size = 1UL << k; /* 页数 */
ffffffffc0200bec:	00ff18b3          	sll	a7,t5,a5
    size_t buddy_idx = idx ^ block_size;
ffffffffc0200bf0:	0116c6b3          	xor	a3,a3,a7
    if (buddy_idx >= npage) return NULL;
ffffffffc0200bf4:	f856eee3          	bltu	a3,t0,ffffffffc0200b90 <buddy_free_pages+0xc6>
        SetPageProperty(blk);
ffffffffc0200bf8:	00863803          	ld	a6,8(a2)
ffffffffc0200bfc:	00286813          	ori	a6,a6,2
    __list_add(elm, listelm, listelm->next);
ffffffffc0200c00:	00179713          	slli	a4,a5,0x1
ffffffffc0200c04:	97ba                	add	a5,a5,a4
ffffffffc0200c06:	078e                	slli	a5,a5,0x3
ffffffffc0200c08:	97aa                	add	a5,a5,a0
ffffffffc0200c0a:	6794                	ld	a3,8(a5)
        buddy_areas[pk].nr_free += (1UL << pk);
ffffffffc0200c0c:	6b98                	ld	a4,16(a5)
        SetPageProperty(blk);
ffffffffc0200c0e:	01063423          	sd	a6,8(a2)
        blk->property = 1UL << pk;
ffffffffc0200c12:	01162823          	sw	a7,16(a2)
        list_add(&buddy_areas[pk].free_list, &blk->page_link);
ffffffffc0200c16:	01860813          	addi	a6,a2,24
    prev->next = next->prev = elm;
ffffffffc0200c1a:	0106b023          	sd	a6,0(a3)
ffffffffc0200c1e:	0107b423          	sd	a6,8(a5)
    elm->next = next;
ffffffffc0200c22:	f214                	sd	a3,32(a2)
    elm->prev = prev;
ffffffffc0200c24:	ee1c                	sd	a5,24(a2)
        buddy_areas[pk].nr_free += (1UL << pk);
ffffffffc0200c26:	9746                	add	a4,a4,a7
        off += cur_size;
ffffffffc0200c28:	9eca                	add	t4,t4,s2
        buddy_areas[pk].nr_free += (1UL << pk);
ffffffffc0200c2a:	eb98                	sd	a4,16(a5)
    while (off < n) {
ffffffffc0200c2c:	eebee2e3          	bltu	t4,a1,ffffffffc0200b10 <buddy_free_pages+0x46>
}
ffffffffc0200c30:	70e2                	ld	ra,56(sp)
ffffffffc0200c32:	7442                	ld	s0,48(sp)
ffffffffc0200c34:	74a2                	ld	s1,40(sp)
ffffffffc0200c36:	7902                	ld	s2,32(sp)
ffffffffc0200c38:	69e2                	ld	s3,24(sp)
ffffffffc0200c3a:	6a42                	ld	s4,16(sp)
ffffffffc0200c3c:	6aa2                	ld	s5,8(sp)
ffffffffc0200c3e:	6121                	addi	sp,sp,64
ffffffffc0200c40:	8082                	ret
        SetPageProperty(blk);
ffffffffc0200c42:	6618                	ld	a4,8(a2)
        blk->property = cur_size;
ffffffffc0200c44:	01e62823          	sw	t5,16(a2)
        SetPageProperty(blk);
ffffffffc0200c48:	41c606b3          	sub	a3,a2,t3
ffffffffc0200c4c:	00276713          	ori	a4,a4,2
ffffffffc0200c50:	e618                	sd	a4,8(a2)
        while (pk + 1 < MAX_ORDER) {
ffffffffc0200c52:	b70d                	j	ffffffffc0200b74 <buddy_free_pages+0xaa>
        SetPageProperty(blk);
ffffffffc0200c54:	00863803          	ld	a6,8(a2)
ffffffffc0200c58:	6891                	lui	a7,0x4
ffffffffc0200c5a:	00286813          	ori	a6,a6,2
ffffffffc0200c5e:	b74d                	j	ffffffffc0200c00 <buddy_free_pages+0x136>
        while (pk + 1 < MAX_ORDER) {
ffffffffc0200c60:	88ca                	mv	a7,s2
ffffffffc0200c62:	bf79                	j	ffffffffc0200c00 <buddy_free_pages+0x136>
    assert(n > 0);
ffffffffc0200c64:	00001697          	auipc	a3,0x1
ffffffffc0200c68:	75468693          	addi	a3,a3,1876 # ffffffffc02023b8 <etext+0x66e>
ffffffffc0200c6c:	00001617          	auipc	a2,0x1
ffffffffc0200c70:	41460613          	addi	a2,a2,1044 # ffffffffc0202080 <etext+0x336>
ffffffffc0200c74:	08500593          	li	a1,133
ffffffffc0200c78:	00001517          	auipc	a0,0x1
ffffffffc0200c7c:	42050513          	addi	a0,a0,1056 # ffffffffc0202098 <etext+0x34e>
ffffffffc0200c80:	d4cff0ef          	jal	ffffffffc02001cc <__panic>
        while ((gidx & ((1UL << cur_k) - 1)) != 0) {
ffffffffc0200c84:	4905                	li	s2,1
ffffffffc0200c86:	00f91933          	sll	s2,s2,a5
        blk->property = cur_size;
ffffffffc0200c8a:	0009071b          	sext.w	a4,s2
ffffffffc0200c8e:	bdd1                	j	ffffffffc0200b62 <buddy_free_pages+0x98>

ffffffffc0200c90 <buddy_alloc_pages>:
    assert(n > 0);
ffffffffc0200c90:	10050163          	beqz	a0,ffffffffc0200d92 <buddy_alloc_pages+0x102>
    while (sz < n) {
ffffffffc0200c94:	4785                	li	a5,1
    int k = 0;
ffffffffc0200c96:	4581                	li	a1,0
    while (sz < n) {
ffffffffc0200c98:	00f50963          	beq	a0,a5,ffffffffc0200caa <buddy_alloc_pages+0x1a>
        sz <<= 1;
ffffffffc0200c9c:	0786                	slli	a5,a5,0x1
        k++;
ffffffffc0200c9e:	2585                	addiw	a1,a1,1
    while (sz < n) {
ffffffffc0200ca0:	fea7eee3          	bltu	a5,a0,ffffffffc0200c9c <buddy_alloc_pages+0xc>
    while (j < MAX_ORDER) {
ffffffffc0200ca4:	47b9                	li	a5,14
ffffffffc0200ca6:	0eb7c463          	blt	a5,a1,ffffffffc0200d8e <buddy_alloc_pages+0xfe>
ffffffffc0200caa:	00159793          	slli	a5,a1,0x1
ffffffffc0200cae:	97ae                	add	a5,a5,a1
ffffffffc0200cb0:	078e                	slli	a5,a5,0x3
ffffffffc0200cb2:	00005517          	auipc	a0,0x5
ffffffffc0200cb6:	36650513          	addi	a0,a0,870 # ffffffffc0206018 <buddy_areas>
ffffffffc0200cba:	97aa                	add	a5,a5,a0
    int j = k;
ffffffffc0200cbc:	86ae                	mv	a3,a1
    while (j < MAX_ORDER) {
ffffffffc0200cbe:	463d                	li	a2,15
ffffffffc0200cc0:	a029                	j	ffffffffc0200cca <buddy_alloc_pages+0x3a>
        j++;
ffffffffc0200cc2:	2685                	addiw	a3,a3,1
    while (j < MAX_ORDER) {
ffffffffc0200cc4:	07e1                	addi	a5,a5,24
ffffffffc0200cc6:	0cc68463          	beq	a3,a2,ffffffffc0200d8e <buddy_alloc_pages+0xfe>
        if (!list_empty(&buddy_areas[j].free_list)) break;
ffffffffc0200cca:	6798                	ld	a4,8(a5)
ffffffffc0200ccc:	fef70be3          	beq	a4,a5,ffffffffc0200cc2 <buddy_alloc_pages+0x32>
    return listelm->next;
ffffffffc0200cd0:	00169793          	slli	a5,a3,0x1
ffffffffc0200cd4:	97b6                	add	a5,a5,a3
ffffffffc0200cd6:	078e                	slli	a5,a5,0x3
ffffffffc0200cd8:	97aa                	add	a5,a5,a0
ffffffffc0200cda:	0087bf83          	ld	t6,8(a5)
    buddy_areas[j].nr_free -= block_size;
ffffffffc0200cde:	6b90                	ld	a2,16(a5)
    size_t block_size = 1UL << j;
ffffffffc0200ce0:	4e85                	li	t4,1
    __list_del(listelm->prev, listelm->next);
ffffffffc0200ce2:	008fb503          	ld	a0,8(t6)
ffffffffc0200ce6:	000fb803          	ld	a6,0(t6)
    ClearPageProperty(p);
ffffffffc0200cea:	ff0fb703          	ld	a4,-16(t6)
    size_t block_size = 1UL << j;
ffffffffc0200cee:	00de98b3          	sll	a7,t4,a3
    prev->next = next;
ffffffffc0200cf2:	00a83423          	sd	a0,8(a6)
    next->prev = prev;
ffffffffc0200cf6:	01053023          	sd	a6,0(a0)
    buddy_areas[j].nr_free -= block_size;
ffffffffc0200cfa:	41160633          	sub	a2,a2,a7
ffffffffc0200cfe:	eb90                	sd	a2,16(a5)
    ClearPageProperty(p);
ffffffffc0200d00:	ffd77793          	andi	a5,a4,-3
ffffffffc0200d04:	feffb823          	sd	a5,-16(t6)
    struct Page *p = le2page(le, page_link);
ffffffffc0200d08:	fe8f8513          	addi	a0,t6,-24
    while (j > k) {
ffffffffc0200d0c:	06d5de63          	bge	a1,a3,ffffffffc0200d88 <buddy_alloc_pages+0xf8>
ffffffffc0200d10:	fff6861b          	addiw	a2,a3,-1
ffffffffc0200d14:	02061813          	slli	a6,a2,0x20
ffffffffc0200d18:	02085813          	srli	a6,a6,0x20
ffffffffc0200d1c:	410686b3          	sub	a3,a3,a6
ffffffffc0200d20:	00181793          	slli	a5,a6,0x1
ffffffffc0200d24:	00169e13          	slli	t3,a3,0x1
ffffffffc0200d28:	97c2                	add	a5,a5,a6
ffffffffc0200d2a:	9e36                	add	t3,t3,a3
ffffffffc0200d2c:	00005717          	auipc	a4,0x5
ffffffffc0200d30:	2f470713          	addi	a4,a4,756 # ffffffffc0206020 <buddy_areas+0x8>
ffffffffc0200d34:	078e                	slli	a5,a5,0x3
ffffffffc0200d36:	0e0e                	slli	t3,t3,0x3
        struct Page *half = p + (1UL << j);
ffffffffc0200d38:	02800f13          	li	t5,40
ffffffffc0200d3c:	1e01                	addi	t3,t3,-32
ffffffffc0200d3e:	973e                	add	a4,a4,a5
ffffffffc0200d40:	a011                	j	ffffffffc0200d44 <buddy_alloc_pages+0xb4>
ffffffffc0200d42:	367d                	addiw	a2,a2,-1
ffffffffc0200d44:	00cf17b3          	sll	a5,t5,a2
ffffffffc0200d48:	97aa                	add	a5,a5,a0
        SetPageProperty(half);
ffffffffc0200d4a:	0087b803          	ld	a6,8(a5)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200d4e:	00073883          	ld	a7,0(a4)
        half->property = 1UL << j;
ffffffffc0200d52:	00ce96b3          	sll	a3,t4,a2
        SetPageProperty(half);
ffffffffc0200d56:	00286813          	ori	a6,a6,2
ffffffffc0200d5a:	0107b423          	sd	a6,8(a5)
        buddy_areas[j].nr_free += (1UL << j);
ffffffffc0200d5e:	00873803          	ld	a6,8(a4)
        half->property = 1UL << j;
ffffffffc0200d62:	cb94                	sw	a3,16(a5)
        list_add(&buddy_areas[j].free_list, &half->page_link);
ffffffffc0200d64:	01878313          	addi	t1,a5,24
    prev->next = next->prev = elm;
ffffffffc0200d68:	0068b023          	sd	t1,0(a7) # 4000 <kern_entry-0xffffffffc01fc000>
ffffffffc0200d6c:	00673023          	sd	t1,0(a4)
ffffffffc0200d70:	00ee0333          	add	t1,t3,a4
    elm->next = next;
ffffffffc0200d74:	0317b023          	sd	a7,32(a5)
    elm->prev = prev;
ffffffffc0200d78:	0067bc23          	sd	t1,24(a5)
        buddy_areas[j].nr_free += (1UL << j);
ffffffffc0200d7c:	00d807b3          	add	a5,a6,a3
ffffffffc0200d80:	e71c                	sd	a5,8(a4)
    while (j > k) {
ffffffffc0200d82:	1721                	addi	a4,a4,-24
ffffffffc0200d84:	fac59fe3          	bne	a1,a2,ffffffffc0200d42 <buddy_alloc_pages+0xb2>



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200d88:	fe0fa423          	sw	zero,-24(t6)
    return p;
ffffffffc0200d8c:	8082                	ret
    if (j >= MAX_ORDER) return NULL; /* 无可用块 */
ffffffffc0200d8e:	4501                	li	a0,0
}
ffffffffc0200d90:	8082                	ret
static struct Page *buddy_alloc_pages(size_t n) {
ffffffffc0200d92:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0200d94:	00001697          	auipc	a3,0x1
ffffffffc0200d98:	62468693          	addi	a3,a3,1572 # ffffffffc02023b8 <etext+0x66e>
ffffffffc0200d9c:	00001617          	auipc	a2,0x1
ffffffffc0200da0:	2e460613          	addi	a2,a2,740 # ffffffffc0202080 <etext+0x336>
ffffffffc0200da4:	06400593          	li	a1,100
ffffffffc0200da8:	00001517          	auipc	a0,0x1
ffffffffc0200dac:	2f050513          	addi	a0,a0,752 # ffffffffc0202098 <etext+0x34e>
static struct Page *buddy_alloc_pages(size_t n) {
ffffffffc0200db0:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200db2:	c1aff0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc0200db6 <buddy_init_memmap>:
static void buddy_init_memmap(struct Page *base, size_t n) {
ffffffffc0200db6:	1141                	addi	sp,sp,-16
ffffffffc0200db8:	e406                	sd	ra,8(sp)
ffffffffc0200dba:	e022                	sd	s0,0(sp)
ffffffffc0200dbc:	87aa                	mv	a5,a0
ffffffffc0200dbe:	4601                	li	a2,0
    assert(n > 0);
ffffffffc0200dc0:	12058963          	beqz	a1,ffffffffc0200ef2 <buddy_init_memmap+0x13c>
        assert(PageReserved(p));
ffffffffc0200dc4:	0087b303          	ld	t1,8(a5)
ffffffffc0200dc8:	00137313          	andi	t1,t1,1
ffffffffc0200dcc:	10030363          	beqz	t1,ffffffffc0200ed2 <buddy_init_memmap+0x11c>
        p->flags = 0;
ffffffffc0200dd0:	0007b423          	sd	zero,8(a5)
ffffffffc0200dd4:	0007a023          	sw	zero,0(a5)
        p->property = 0;
ffffffffc0200dd8:	0007a823          	sw	zero,16(a5)
    for (size_t i = 0; i < n; i++) {
ffffffffc0200ddc:	0605                	addi	a2,a2,1
ffffffffc0200dde:	02878793          	addi	a5,a5,40
ffffffffc0200de2:	fec591e3          	bne	a1,a2,ffffffffc0200dc4 <buddy_init_memmap+0xe>
    return (size_t)(p - pages);
ffffffffc0200de6:	ccccd7b7          	lui	a5,0xccccd
ffffffffc0200dea:	ccd78793          	addi	a5,a5,-819 # ffffffffcccccccd <end+0xcac69dd>
ffffffffc0200dee:	00005297          	auipc	t0,0x5
ffffffffc0200df2:	4fa2b283          	ld	t0,1274(t0) # ffffffffc02062e8 <pages>
ffffffffc0200df6:	02079f93          	slli	t6,a5,0x20
ffffffffc0200dfa:	9fbe                	add	t6,t6,a5
    size_t i = 0;
ffffffffc0200dfc:	4e01                	li	t3,0
ffffffffc0200dfe:	00005f17          	auipc	t5,0x5
ffffffffc0200e02:	21af0f13          	addi	t5,t5,538 # ffffffffc0206018 <buddy_areas>
            if ((size_t)k + 1 >= MAX_ORDER) break;
ffffffffc0200e06:	4eb9                	li	t4,14
        struct Page *p = base + i;
ffffffffc0200e08:	002e1593          	slli	a1,t3,0x2
ffffffffc0200e0c:	95f2                	add	a1,a1,t3
ffffffffc0200e0e:	058e                	slli	a1,a1,0x3
ffffffffc0200e10:	95aa                	add	a1,a1,a0
    return (size_t)(p - pages);
ffffffffc0200e12:	40558833          	sub	a6,a1,t0
ffffffffc0200e16:	40385813          	srai	a6,a6,0x3
ffffffffc0200e1a:	03f80833          	mul	a6,a6,t6
        size_t max_fit = 1;
ffffffffc0200e1e:	879a                	mv	a5,t1
        int k = 0;
ffffffffc0200e20:	4701                	li	a4,0
        while ((global_idx % (max_fit << 1)) == 0 && i + (max_fit << 1) <= n) {
ffffffffc0200e22:	88be                	mv	a7,a5
ffffffffc0200e24:	0786                	slli	a5,a5,0x1
ffffffffc0200e26:	02f876b3          	remu	a3,a6,a5
ffffffffc0200e2a:	eec1                	bnez	a3,ffffffffc0200ec2 <buddy_init_memmap+0x10c>
ffffffffc0200e2c:	01c786b3          	add	a3,a5,t3
ffffffffc0200e30:	08d66963          	bltu	a2,a3,ffffffffc0200ec2 <buddy_init_memmap+0x10c>
            k++;
ffffffffc0200e34:	2705                	addiw	a4,a4,1
            if ((size_t)k + 1 >= MAX_ORDER) break;
ffffffffc0200e36:	ffd716e3          	bne	a4,t4,ffffffffc0200e22 <buddy_init_memmap+0x6c>
ffffffffc0200e3a:	8e36                	mv	t3,a3
ffffffffc0200e3c:	15000813          	li	a6,336
ffffffffc0200e40:	00171693          	slli	a3,a4,0x1
    __list_add(elm, listelm, listelm->next);
ffffffffc0200e44:	9736                	add	a4,a4,a3
ffffffffc0200e46:	070e                	slli	a4,a4,0x3
        SetPageProperty(p);
ffffffffc0200e48:	6594                	ld	a3,8(a1)
ffffffffc0200e4a:	977a                	add	a4,a4,t5
ffffffffc0200e4c:	00873383          	ld	t2,8(a4)
ffffffffc0200e50:	0026e693          	ori	a3,a3,2
        buddy_areas[k].nr_free += max_fit;
ffffffffc0200e54:	01073883          	ld	a7,16(a4)
        p->property = max_fit;
ffffffffc0200e58:	c99c                	sw	a5,16(a1)
        SetPageProperty(p);
ffffffffc0200e5a:	e594                	sd	a3,8(a1)
        list_add(&buddy_areas[k].free_list, &p->page_link);
ffffffffc0200e5c:	01858413          	addi	s0,a1,24
    prev->next = next->prev = elm;
ffffffffc0200e60:	0083b023          	sd	s0,0(t2)
ffffffffc0200e64:	e700                	sd	s0,8(a4)
ffffffffc0200e66:	010f06b3          	add	a3,t5,a6
    elm->prev = prev;
ffffffffc0200e6a:	ed94                	sd	a3,24(a1)
    elm->next = next;
ffffffffc0200e6c:	0275b023          	sd	t2,32(a1)
        buddy_areas[k].nr_free += max_fit;
ffffffffc0200e70:	97c6                	add	a5,a5,a7
ffffffffc0200e72:	eb1c                	sd	a5,16(a4)
    while (i < n) {
ffffffffc0200e74:	f8ce6ae3          	bltu	t3,a2,ffffffffc0200e08 <buddy_init_memmap+0x52>
    size_t total_pages = npage - nbase;
ffffffffc0200e78:	00002797          	auipc	a5,0x2
ffffffffc0200e7c:	d487b783          	ld	a5,-696(a5) # ffffffffc0202bc0 <nbase>
ffffffffc0200e80:	00005717          	auipc	a4,0x5
ffffffffc0200e84:	46073703          	ld	a4,1120(a4) # ffffffffc02062e0 <npage>
    buddy_max_order = 0;
ffffffffc0200e88:	00005697          	auipc	a3,0x5
ffffffffc0200e8c:	4206b823          	sd	zero,1072(a3) # ffffffffc02062b8 <buddy_max_order>
    while (s < total_pages && buddy_max_order + 1 < MAX_ORDER) { s <<= 1; buddy_max_order++; }
ffffffffc0200e90:	4585                	li	a1,1
    size_t total_pages = npage - nbase;
ffffffffc0200e92:	8f1d                	sub	a4,a4,a5
    while (s < total_pages && buddy_max_order + 1 < MAX_ORDER) { s <<= 1; buddy_max_order++; }
ffffffffc0200e94:	4681                	li	a3,0
ffffffffc0200e96:	4781                	li	a5,0
ffffffffc0200e98:	463d                	li	a2,15
ffffffffc0200e9a:	00e5e763          	bltu	a1,a4,ffffffffc0200ea8 <buddy_init_memmap+0xf2>
ffffffffc0200e9e:	a831                	j	ffffffffc0200eba <buddy_init_memmap+0x104>
ffffffffc0200ea0:	0306                	slli	t1,t1,0x1
ffffffffc0200ea2:	4685                	li	a3,1
ffffffffc0200ea4:	00e37763          	bgeu	t1,a4,ffffffffc0200eb2 <buddy_init_memmap+0xfc>
ffffffffc0200ea8:	0785                	addi	a5,a5,1
ffffffffc0200eaa:	fec79be3          	bne	a5,a2,ffffffffc0200ea0 <buddy_init_memmap+0xea>
ffffffffc0200eae:	c691                	beqz	a3,ffffffffc0200eba <buddy_init_memmap+0x104>
ffffffffc0200eb0:	47b9                	li	a5,14
ffffffffc0200eb2:	00005717          	auipc	a4,0x5
ffffffffc0200eb6:	40f73323          	sd	a5,1030(a4) # ffffffffc02062b8 <buddy_max_order>
}
ffffffffc0200eba:	60a2                	ld	ra,8(sp)
ffffffffc0200ebc:	6402                	ld	s0,0(sp)
ffffffffc0200ebe:	0141                	addi	sp,sp,16
ffffffffc0200ec0:	8082                	ret
ffffffffc0200ec2:	00171693          	slli	a3,a4,0x1
ffffffffc0200ec6:	00e68833          	add	a6,a3,a4
        i += max_fit;
ffffffffc0200eca:	9e46                	add	t3,t3,a7
ffffffffc0200ecc:	87c6                	mv	a5,a7
ffffffffc0200ece:	080e                	slli	a6,a6,0x3
ffffffffc0200ed0:	bf95                	j	ffffffffc0200e44 <buddy_init_memmap+0x8e>
        assert(PageReserved(p));
ffffffffc0200ed2:	00001697          	auipc	a3,0x1
ffffffffc0200ed6:	4ee68693          	addi	a3,a3,1262 # ffffffffc02023c0 <etext+0x676>
ffffffffc0200eda:	00001617          	auipc	a2,0x1
ffffffffc0200ede:	1a660613          	addi	a2,a2,422 # ffffffffc0202080 <etext+0x336>
ffffffffc0200ee2:	03f00593          	li	a1,63
ffffffffc0200ee6:	00001517          	auipc	a0,0x1
ffffffffc0200eea:	1b250513          	addi	a0,a0,434 # ffffffffc0202098 <etext+0x34e>
ffffffffc0200eee:	adeff0ef          	jal	ffffffffc02001cc <__panic>
    assert(n > 0);
ffffffffc0200ef2:	00001697          	auipc	a3,0x1
ffffffffc0200ef6:	4c668693          	addi	a3,a3,1222 # ffffffffc02023b8 <etext+0x66e>
ffffffffc0200efa:	00001617          	auipc	a2,0x1
ffffffffc0200efe:	18660613          	addi	a2,a2,390 # ffffffffc0202080 <etext+0x336>
ffffffffc0200f02:	03b00593          	li	a1,59
ffffffffc0200f06:	00001517          	auipc	a0,0x1
ffffffffc0200f0a:	19250513          	addi	a0,a0,402 # ffffffffc0202098 <etext+0x34e>
ffffffffc0200f0e:	abeff0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc0200f12 <alloc_pages>:
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    return pmm_manager->alloc_pages(n);
ffffffffc0200f12:	00005797          	auipc	a5,0x5
ffffffffc0200f16:	3ae7b783          	ld	a5,942(a5) # ffffffffc02062c0 <pmm_manager>
ffffffffc0200f1a:	6f9c                	ld	a5,24(a5)
ffffffffc0200f1c:	8782                	jr	a5

ffffffffc0200f1e <free_pages>:
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);
ffffffffc0200f1e:	00005797          	auipc	a5,0x5
ffffffffc0200f22:	3a27b783          	ld	a5,930(a5) # ffffffffc02062c0 <pmm_manager>
ffffffffc0200f26:	739c                	ld	a5,32(a5)
ffffffffc0200f28:	8782                	jr	a5

ffffffffc0200f2a <nr_free_pages>:
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void) {
    return pmm_manager->nr_free_pages();
ffffffffc0200f2a:	00005797          	auipc	a5,0x5
ffffffffc0200f2e:	3967b783          	ld	a5,918(a5) # ffffffffc02062c0 <pmm_manager>
ffffffffc0200f32:	779c                	ld	a5,40(a5)
ffffffffc0200f34:	8782                	jr	a5

ffffffffc0200f36 <pmm_init>:
    pmm_manager = &buddy_pmm_manager;  // 修改这一行
ffffffffc0200f36:	00002797          	auipc	a5,0x2
ffffffffc0200f3a:	a7a78793          	addi	a5,a5,-1414 # ffffffffc02029b0 <buddy_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200f3e:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0200f40:	7139                	addi	sp,sp,-64
ffffffffc0200f42:	fc06                	sd	ra,56(sp)
ffffffffc0200f44:	f822                	sd	s0,48(sp)
ffffffffc0200f46:	f426                	sd	s1,40(sp)
ffffffffc0200f48:	ec4e                	sd	s3,24(sp)
ffffffffc0200f4a:	f04a                	sd	s2,32(sp)
    pmm_manager = &buddy_pmm_manager;  // 修改这一行
ffffffffc0200f4c:	00005417          	auipc	s0,0x5
ffffffffc0200f50:	37440413          	addi	s0,s0,884 # ffffffffc02062c0 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200f54:	00001517          	auipc	a0,0x1
ffffffffc0200f58:	49450513          	addi	a0,a0,1172 # ffffffffc02023e8 <etext+0x69e>
    pmm_manager = &buddy_pmm_manager;  // 修改这一行
ffffffffc0200f5c:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200f5e:	9eeff0ef          	jal	ffffffffc020014c <cprintf>
    pmm_manager->init();
ffffffffc0200f62:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200f64:	00005497          	auipc	s1,0x5
ffffffffc0200f68:	37448493          	addi	s1,s1,884 # ffffffffc02062d8 <va_pa_offset>
    pmm_manager->init();
ffffffffc0200f6c:	679c                	ld	a5,8(a5)
ffffffffc0200f6e:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200f70:	57f5                	li	a5,-3
ffffffffc0200f72:	07fa                	slli	a5,a5,0x1e
ffffffffc0200f74:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc0200f76:	de8ff0ef          	jal	ffffffffc020055e <get_memory_base>
ffffffffc0200f7a:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc0200f7c:	decff0ef          	jal	ffffffffc0200568 <get_memory_size>
    if (mem_size == 0) {
ffffffffc0200f80:	14050c63          	beqz	a0,ffffffffc02010d8 <pmm_init+0x1a2>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0200f84:	00a98933          	add	s2,s3,a0
ffffffffc0200f88:	e42a                	sd	a0,8(sp)
    cprintf("physcial memory map:\n");
ffffffffc0200f8a:	00001517          	auipc	a0,0x1
ffffffffc0200f8e:	4a650513          	addi	a0,a0,1190 # ffffffffc0202430 <etext+0x6e6>
ffffffffc0200f92:	9baff0ef          	jal	ffffffffc020014c <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0200f96:	65a2                	ld	a1,8(sp)
ffffffffc0200f98:	864e                	mv	a2,s3
ffffffffc0200f9a:	fff90693          	addi	a3,s2,-1
ffffffffc0200f9e:	00001517          	auipc	a0,0x1
ffffffffc0200fa2:	4aa50513          	addi	a0,a0,1194 # ffffffffc0202448 <etext+0x6fe>
ffffffffc0200fa6:	9a6ff0ef          	jal	ffffffffc020014c <cprintf>
    if (maxpa > KERNTOP) {
ffffffffc0200faa:	c80007b7          	lui	a5,0xc8000
ffffffffc0200fae:	85ca                	mv	a1,s2
ffffffffc0200fb0:	0d27e263          	bltu	a5,s2,ffffffffc0201074 <pmm_init+0x13e>
ffffffffc0200fb4:	77fd                	lui	a5,0xfffff
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200fb6:	00006697          	auipc	a3,0x6
ffffffffc0200fba:	33968693          	addi	a3,a3,825 # ffffffffc02072ef <end+0xfff>
ffffffffc0200fbe:	8efd                	and	a3,a3,a5
    npage = maxpa / PGSIZE;
ffffffffc0200fc0:	81b1                	srli	a1,a1,0xc
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200fc2:	fff80837          	lui	a6,0xfff80
    npage = maxpa / PGSIZE;
ffffffffc0200fc6:	00005797          	auipc	a5,0x5
ffffffffc0200fca:	30b7bd23          	sd	a1,794(a5) # ffffffffc02062e0 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200fce:	00005797          	auipc	a5,0x5
ffffffffc0200fd2:	30d7bd23          	sd	a3,794(a5) # ffffffffc02062e8 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200fd6:	982e                	add	a6,a6,a1
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200fd8:	88b6                	mv	a7,a3
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200fda:	02080963          	beqz	a6,ffffffffc020100c <pmm_init+0xd6>
ffffffffc0200fde:	00259613          	slli	a2,a1,0x2
ffffffffc0200fe2:	962e                	add	a2,a2,a1
ffffffffc0200fe4:	fec007b7          	lui	a5,0xfec00
ffffffffc0200fe8:	97b6                	add	a5,a5,a3
ffffffffc0200fea:	060e                	slli	a2,a2,0x3
ffffffffc0200fec:	963e                	add	a2,a2,a5
ffffffffc0200fee:	87b6                	mv	a5,a3
        SetPageReserved(pages + i);
ffffffffc0200ff0:	6798                	ld	a4,8(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200ff2:	02878793          	addi	a5,a5,40 # fffffffffec00028 <end+0x3e9f9d38>
        SetPageReserved(pages + i);
ffffffffc0200ff6:	00176713          	ori	a4,a4,1
ffffffffc0200ffa:	fee7b023          	sd	a4,-32(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200ffe:	fec799e3          	bne	a5,a2,ffffffffc0200ff0 <pmm_init+0xba>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201002:	00281793          	slli	a5,a6,0x2
ffffffffc0201006:	97c2                	add	a5,a5,a6
ffffffffc0201008:	078e                	slli	a5,a5,0x3
ffffffffc020100a:	96be                	add	a3,a3,a5
ffffffffc020100c:	c02007b7          	lui	a5,0xc0200
ffffffffc0201010:	0af6e863          	bltu	a3,a5,ffffffffc02010c0 <pmm_init+0x18a>
ffffffffc0201014:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0201016:	77fd                	lui	a5,0xfffff
ffffffffc0201018:	00f97933          	and	s2,s2,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020101c:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc020101e:	0526ed63          	bltu	a3,s2,ffffffffc0201078 <pmm_init+0x142>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0201022:	601c                	ld	a5,0(s0)
ffffffffc0201024:	7b9c                	ld	a5,48(a5)
ffffffffc0201026:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0201028:	00001517          	auipc	a0,0x1
ffffffffc020102c:	4a850513          	addi	a0,a0,1192 # ffffffffc02024d0 <etext+0x786>
ffffffffc0201030:	91cff0ef          	jal	ffffffffc020014c <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0201034:	00004597          	auipc	a1,0x4
ffffffffc0201038:	fcc58593          	addi	a1,a1,-52 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc020103c:	00005797          	auipc	a5,0x5
ffffffffc0201040:	28b7ba23          	sd	a1,660(a5) # ffffffffc02062d0 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201044:	c02007b7          	lui	a5,0xc0200
ffffffffc0201048:	0af5e463          	bltu	a1,a5,ffffffffc02010f0 <pmm_init+0x1ba>
ffffffffc020104c:	609c                	ld	a5,0(s1)
}
ffffffffc020104e:	7442                	ld	s0,48(sp)
ffffffffc0201050:	70e2                	ld	ra,56(sp)
ffffffffc0201052:	74a2                	ld	s1,40(sp)
ffffffffc0201054:	7902                	ld	s2,32(sp)
ffffffffc0201056:	69e2                	ld	s3,24(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0201058:	40f586b3          	sub	a3,a1,a5
ffffffffc020105c:	00005797          	auipc	a5,0x5
ffffffffc0201060:	26d7b623          	sd	a3,620(a5) # ffffffffc02062c8 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201064:	00001517          	auipc	a0,0x1
ffffffffc0201068:	48c50513          	addi	a0,a0,1164 # ffffffffc02024f0 <etext+0x7a6>
ffffffffc020106c:	8636                	mv	a2,a3
}
ffffffffc020106e:	6121                	addi	sp,sp,64
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201070:	8dcff06f          	j	ffffffffc020014c <cprintf>
    if (maxpa > KERNTOP) {
ffffffffc0201074:	85be                	mv	a1,a5
ffffffffc0201076:	bf3d                	j	ffffffffc0200fb4 <pmm_init+0x7e>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0201078:	6705                	lui	a4,0x1
ffffffffc020107a:	177d                	addi	a4,a4,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc020107c:	96ba                	add	a3,a3,a4
ffffffffc020107e:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0201080:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201084:	02b7f263          	bgeu	a5,a1,ffffffffc02010a8 <pmm_init+0x172>
    pmm_manager->init_memmap(base, n);
ffffffffc0201088:	6018                	ld	a4,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc020108a:	fff80637          	lui	a2,0xfff80
ffffffffc020108e:	97b2                	add	a5,a5,a2
ffffffffc0201090:	00279513          	slli	a0,a5,0x2
ffffffffc0201094:	953e                	add	a0,a0,a5
ffffffffc0201096:	6b1c                	ld	a5,16(a4)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0201098:	40d90933          	sub	s2,s2,a3
ffffffffc020109c:	050e                	slli	a0,a0,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc020109e:	00c95593          	srli	a1,s2,0xc
ffffffffc02010a2:	9546                	add	a0,a0,a7
ffffffffc02010a4:	9782                	jalr	a5
}
ffffffffc02010a6:	bfb5                	j	ffffffffc0201022 <pmm_init+0xec>
        panic("pa2page called with invalid pa");
ffffffffc02010a8:	00001617          	auipc	a2,0x1
ffffffffc02010ac:	3f860613          	addi	a2,a2,1016 # ffffffffc02024a0 <etext+0x756>
ffffffffc02010b0:	06a00593          	li	a1,106
ffffffffc02010b4:	00001517          	auipc	a0,0x1
ffffffffc02010b8:	40c50513          	addi	a0,a0,1036 # ffffffffc02024c0 <etext+0x776>
ffffffffc02010bc:	910ff0ef          	jal	ffffffffc02001cc <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02010c0:	00001617          	auipc	a2,0x1
ffffffffc02010c4:	3b860613          	addi	a2,a2,952 # ffffffffc0202478 <etext+0x72e>
ffffffffc02010c8:	05e00593          	li	a1,94
ffffffffc02010cc:	00001517          	auipc	a0,0x1
ffffffffc02010d0:	35450513          	addi	a0,a0,852 # ffffffffc0202420 <etext+0x6d6>
ffffffffc02010d4:	8f8ff0ef          	jal	ffffffffc02001cc <__panic>
        panic("DTB memory info not available");
ffffffffc02010d8:	00001617          	auipc	a2,0x1
ffffffffc02010dc:	32860613          	addi	a2,a2,808 # ffffffffc0202400 <etext+0x6b6>
ffffffffc02010e0:	04600593          	li	a1,70
ffffffffc02010e4:	00001517          	auipc	a0,0x1
ffffffffc02010e8:	33c50513          	addi	a0,a0,828 # ffffffffc0202420 <etext+0x6d6>
ffffffffc02010ec:	8e0ff0ef          	jal	ffffffffc02001cc <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc02010f0:	86ae                	mv	a3,a1
ffffffffc02010f2:	00001617          	auipc	a2,0x1
ffffffffc02010f6:	38660613          	addi	a2,a2,902 # ffffffffc0202478 <etext+0x72e>
ffffffffc02010fa:	07900593          	li	a1,121
ffffffffc02010fe:	00001517          	auipc	a0,0x1
ffffffffc0201102:	32250513          	addi	a0,a0,802 # ffffffffc0202420 <etext+0x6d6>
ffffffffc0201106:	8c6ff0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc020110a <slub_alloc>:

/* 根据对象大小找到所属 cache */
static int size_to_index(size_t size) {
    int idx = 0;
    size_t s = (1 << MIN_OBJ_SHIFT);
    while (s < size && idx < CACHE_NUM) {
ffffffffc020110a:	47a1                	li	a5,8
    int idx = 0;
ffffffffc020110c:	4701                	li	a4,0
    while (s < size && idx < CACHE_NUM) {
ffffffffc020110e:	00a7fc63          	bgeu	a5,a0,ffffffffc0201126 <slub_alloc+0x1c>
        s <<= 1;
ffffffffc0201112:	0786                	slli	a5,a5,0x1
        idx++;
ffffffffc0201114:	2705                	addiw	a4,a4,1
    while (s < size && idx < CACHE_NUM) {
ffffffffc0201116:	00a7f563          	bgeu	a5,a0,ffffffffc0201120 <slub_alloc+0x16>
ffffffffc020111a:	ff770693          	addi	a3,a4,-9
ffffffffc020111e:	faf5                	bnez	a3,ffffffffc0201112 <slub_alloc+0x8>
    }
    return (idx >= CACHE_NUM) ? -1 : idx;
ffffffffc0201120:	47a5                	li	a5,9
ffffffffc0201122:	18f70d63          	beq	a4,a5,ffffffffc02012bc <slub_alloc+0x1b2>
    int idx = size_to_index(size);
    if (idx < 0)
        return NULL;
    struct kmem_cache *cache = &caches[idx];

    struct slab *sl = cache->slabs_partial;
ffffffffc0201126:	0716                	slli	a4,a4,0x5
ffffffffc0201128:	00005817          	auipc	a6,0x5
ffffffffc020112c:	05880813          	addi	a6,a6,88 # ffffffffc0206180 <caches>
ffffffffc0201130:	00e80633          	add	a2,a6,a4
ffffffffc0201134:	6a1c                	ld	a5,16(a2)
void *slub_alloc(size_t size) {
ffffffffc0201136:	7139                	addi	sp,sp,-64
ffffffffc0201138:	fc06                	sd	ra,56(sp)
    if (sl == NULL) {
ffffffffc020113a:	c3b5                	beqz	a5,ffffffffc020119e <slub_alloc+0x94>
        sl->next = cache->slabs_partial;
        cache->slabs_partial = sl;
    }

    /* 分配 freelist 中第一个对象 */
    void *obj = sl->freelist;
ffffffffc020113c:	6788                	ld	a0,8(a5)
    if (obj == NULL)
ffffffffc020113e:	c141                	beqz	a0,ffffffffc02011be <slub_alloc+0xb4>

    sl->freelist = *(void **)obj;
    sl->inuse++;

    /* 设置 bitmap 位 */
    int idx_bit = ((char *)obj - (char *)sl->obj_base) / cache->obj_size;
ffffffffc0201140:	983a                	add	a6,a6,a4
ffffffffc0201142:	6f98                	ld	a4,24(a5)
ffffffffc0201144:	00083603          	ld	a2,0(a6)
    sl->inuse++;
ffffffffc0201148:	4394                	lw	a3,0(a5)
    int idx_bit = ((char *)obj - (char *)sl->obj_base) / cache->obj_size;
ffffffffc020114a:	40e50733          	sub	a4,a0,a4
ffffffffc020114e:	02c75733          	divu	a4,a4,a2
    sl->inuse++;
ffffffffc0201152:	2685                	addiw	a3,a3,1
    sl->freelist = *(void **)obj;
ffffffffc0201154:	6110                	ld	a2,0(a0)
    sl->inuse++;
ffffffffc0201156:	c394                	sw	a3,0(a5)
    sl->bitmap[idx_bit / 8] |= (1 << (idx_bit % 8));
ffffffffc0201158:	6b8c                	ld	a1,16(a5)
    sl->freelist = *(void **)obj;
ffffffffc020115a:	e790                	sd	a2,8(a5)
    sl->bitmap[idx_bit / 8] |= (1 << (idx_bit % 8));
ffffffffc020115c:	4605                	li	a2,1
    int idx_bit = ((char *)obj - (char *)sl->obj_base) / cache->obj_size;
ffffffffc020115e:	2701                	sext.w	a4,a4
    sl->bitmap[idx_bit / 8] |= (1 << (idx_bit % 8));
ffffffffc0201160:	41f7569b          	sraiw	a3,a4,0x1f
ffffffffc0201164:	01d6d69b          	srliw	a3,a3,0x1d
ffffffffc0201168:	9eb9                	addw	a3,a3,a4
ffffffffc020116a:	4036d69b          	sraiw	a3,a3,0x3
ffffffffc020116e:	96ae                	add	a3,a3,a1
ffffffffc0201170:	0006c583          	lbu	a1,0(a3)
ffffffffc0201174:	8b1d                	andi	a4,a4,7
ffffffffc0201176:	00e6173b          	sllw	a4,a2,a4
ffffffffc020117a:	8f4d                	or	a4,a4,a1
ffffffffc020117c:	00e68023          	sb	a4,0(a3)

    /* slab 满时移动到 full 链表 */
    if (sl->inuse == sl->total) {
ffffffffc0201180:	4394                	lw	a3,0(a5)
ffffffffc0201182:	43d8                	lw	a4,4(a5)
ffffffffc0201184:	00e69a63          	bne	a3,a4,ffffffffc0201198 <slub_alloc+0x8e>
        cache->slabs_partial = sl->next;
ffffffffc0201188:	7394                	ld	a3,32(a5)
        sl->next = cache->slabs_full;
ffffffffc020118a:	00883703          	ld	a4,8(a6)
        cache->slabs_partial = sl->next;
ffffffffc020118e:	00d83823          	sd	a3,16(a6)
        sl->next = cache->slabs_full;
ffffffffc0201192:	f398                	sd	a4,32(a5)
        cache->slabs_full = sl;
ffffffffc0201194:	00f83423          	sd	a5,8(a6)
    }

    return obj;
}
ffffffffc0201198:	70e2                	ld	ra,56(sp)
ffffffffc020119a:	6121                	addi	sp,sp,64
ffffffffc020119c:	8082                	ret
        if (cache->slabs_free == NULL) {
ffffffffc020119e:	6e1c                	ld	a5,24(a2)
ffffffffc02011a0:	cb89                	beqz	a5,ffffffffc02011b2 <slub_alloc+0xa8>
        cache->slabs_free = sl->next;
ffffffffc02011a2:	7390                	ld	a2,32(a5)
ffffffffc02011a4:	4581                	li	a1,0
ffffffffc02011a6:	00e806b3          	add	a3,a6,a4
ffffffffc02011aa:	ee90                	sd	a2,24(a3)
        sl->next = cache->slabs_partial;
ffffffffc02011ac:	f38c                	sd	a1,32(a5)
        cache->slabs_partial = sl;
ffffffffc02011ae:	ea9c                	sd	a5,16(a3)
ffffffffc02011b0:	b771                	j	ffffffffc020113c <slub_alloc+0x32>
    struct Page *page = alloc_page();
ffffffffc02011b2:	4505                	li	a0,1
ffffffffc02011b4:	e43a                	sd	a4,8(sp)
ffffffffc02011b6:	e032                	sd	a2,0(sp)
ffffffffc02011b8:	d5bff0ef          	jal	ffffffffc0200f12 <alloc_pages>
    if (page == NULL)
ffffffffc02011bc:	e509                	bnez	a0,ffffffffc02011c6 <slub_alloc+0xbc>
}
ffffffffc02011be:	70e2                	ld	ra,56(sp)
        return NULL;
ffffffffc02011c0:	4501                	li	a0,0
}
ffffffffc02011c2:	6121                	addi	sp,sp,64
ffffffffc02011c4:	8082                	ret
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02011c6:	00005797          	auipc	a5,0x5
ffffffffc02011ca:	1227b783          	ld	a5,290(a5) # ffffffffc02062e8 <pages>
ffffffffc02011ce:	ccccd6b7          	lui	a3,0xccccd
ffffffffc02011d2:	ccd68693          	addi	a3,a3,-819 # ffffffffcccccccd <end+0xcac69dd>
ffffffffc02011d6:	02069593          	slli	a1,a3,0x20
ffffffffc02011da:	40f507b3          	sub	a5,a0,a5
ffffffffc02011de:	95b6                	add	a1,a1,a3
ffffffffc02011e0:	878d                	srai	a5,a5,0x3
ffffffffc02011e2:	02b787b3          	mul	a5,a5,a1
ffffffffc02011e6:	00002697          	auipc	a3,0x2
ffffffffc02011ea:	9da6b683          	ld	a3,-1574(a3) # ffffffffc0202bc0 <nbase>
    void *page_kva = KADDR(page2pa(page));
ffffffffc02011ee:	00005597          	auipc	a1,0x5
ffffffffc02011f2:	0f25b583          	ld	a1,242(a1) # ffffffffc02062e0 <npage>
ffffffffc02011f6:	6602                	ld	a2,0(sp)
ffffffffc02011f8:	6722                	ld	a4,8(sp)
ffffffffc02011fa:	97b6                	add	a5,a5,a3
ffffffffc02011fc:	00c79693          	slli	a3,a5,0xc
ffffffffc0201200:	82b1                	srli	a3,a3,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201202:	07b2                	slli	a5,a5,0xc
ffffffffc0201204:	0ab6fe63          	bgeu	a3,a1,ffffffffc02012c0 <slub_alloc+0x1b6>
    size_t obj_size = cache->obj_size;
ffffffffc0201208:	00063303          	ld	t1,0(a2)
    size_t max_obj = (SLAB_PAGE_SIZE - overhead) / (obj_size + 1.0 / 8); // 初步估算
ffffffffc020120c:	00002697          	auipc	a3,0x2
ffffffffc0201210:	9bc6b687          	fld	fa3,-1604(a3) # ffffffffc0202bc8 <nbase+0x8>
ffffffffc0201214:	00002697          	auipc	a3,0x2
ffffffffc0201218:	9bc6b787          	fld	fa5,-1604(a3) # ffffffffc0202bd0 <nbase+0x10>
ffffffffc020121c:	d2337753          	fcvt.d.lu	fa4,t1
    int obj_num = (SLAB_PAGE_SIZE - overhead - bitmap_bytes) / obj_size;
ffffffffc0201220:	6585                	lui	a1,0x1
ffffffffc0201222:	fd858593          	addi	a1,a1,-40 # fd8 <kern_entry-0xffffffffc01ff028>
    size_t max_obj = (SLAB_PAGE_SIZE - overhead) / (obj_size + 1.0 / 8); // 初步估算
ffffffffc0201226:	02d77753          	fadd.d	fa4,fa4,fa3
    void *page_kva = KADDR(page2pa(page));
ffffffffc020122a:	00005697          	auipc	a3,0x5
ffffffffc020122e:	0ae6b683          	ld	a3,174(a3) # ffffffffc02062d8 <va_pa_offset>
ffffffffc0201232:	97b6                	add	a5,a5,a3
    sl->inuse = 0;
ffffffffc0201234:	0007a023          	sw	zero,0(a5)
    sl->next = NULL;
ffffffffc0201238:	0207b023          	sd	zero,32(a5)
    size_t max_obj = (SLAB_PAGE_SIZE - overhead) / (obj_size + 1.0 / 8); // 初步估算
ffffffffc020123c:	1ae7f7d3          	fdiv.d	fa5,fa5,fa4
ffffffffc0201240:	c2379653          	fcvt.lu.d	a2,fa5,rtz
    size_t bitmap_bytes = (max_obj + 7) / 8;
ffffffffc0201244:	061d                	addi	a2,a2,7
ffffffffc0201246:	820d                	srli	a2,a2,0x3
    int obj_num = (SLAB_PAGE_SIZE - overhead - bitmap_bytes) / obj_size;
ffffffffc0201248:	40c588b3          	sub	a7,a1,a2
ffffffffc020124c:	0268d8b3          	divu	a7,a7,t1
ffffffffc0201250:	2881                	sext.w	a7,a7
    if (obj_num <= 0)
ffffffffc0201252:	f71056e3          	blez	a7,ffffffffc02011be <slub_alloc+0xb4>
    uint8_t *bitmap = (uint8_t *)(sl + 1);
ffffffffc0201256:	02878693          	addi	a3,a5,40
    sl->bitmap = bitmap;
ffffffffc020125a:	eb94                	sd	a3,16(a5)
    memset(sl->bitmap, 0, bitmap_bytes);
ffffffffc020125c:	8536                	mv	a0,a3
ffffffffc020125e:	4581                	li	a1,0
    sl->bitmap = bitmap;
ffffffffc0201260:	e83e                	sd	a5,16(sp)
    memset(sl->bitmap, 0, bitmap_bytes);
ffffffffc0201262:	e436                	sd	a3,8(sp)
ffffffffc0201264:	e032                	sd	a2,0(sp)
ffffffffc0201266:	ec46                	sd	a7,24(sp)
ffffffffc0201268:	f01a                	sd	t1,32(sp)
ffffffffc020126a:	f43a                	sd	a4,40(sp)
ffffffffc020126c:	2cd000ef          	jal	ffffffffc0201d38 <memset>
    sl->obj_base = (void *)(bitmap + bitmap_bytes);
ffffffffc0201270:	66a2                	ld	a3,8(sp)
ffffffffc0201272:	6602                	ld	a2,0(sp)
ffffffffc0201274:	67c2                	ld	a5,16(sp)
    sl->total = obj_num;
ffffffffc0201276:	68e2                	ld	a7,24(sp)
        *obj = (i == obj_num - 1) ? NULL : (void *)(p + (i + 1) * obj_size);
ffffffffc0201278:	7722                	ld	a4,40(sp)
ffffffffc020127a:	7302                	ld	t1,32(sp)
    sl->obj_base = (void *)(bitmap + bitmap_bytes);
ffffffffc020127c:	9636                	add	a2,a2,a3
ffffffffc020127e:	ef90                	sd	a2,24(a5)
    sl->freelist = sl->obj_base;
ffffffffc0201280:	e790                	sd	a2,8(a5)
    sl->total = obj_num;
ffffffffc0201282:	0117a223          	sw	a7,4(a5)
        *obj = (i == obj_num - 1) ? NULL : (void *)(p + (i + 1) * obj_size);
ffffffffc0201286:	fff88e1b          	addiw	t3,a7,-1
ffffffffc020128a:	4681                	li	a3,0
ffffffffc020128c:	00005817          	auipc	a6,0x5
ffffffffc0201290:	ef480813          	addi	a6,a6,-268 # ffffffffc0206180 <caches>
ffffffffc0201294:	03c68063          	beq	a3,t3,ffffffffc02012b4 <slub_alloc+0x1aa>
ffffffffc0201298:	00c305b3          	add	a1,t1,a2
ffffffffc020129c:	852e                	mv	a0,a1
ffffffffc020129e:	e208                	sd	a0,0(a2)
    for (int i = 0; i < obj_num; i++) {
ffffffffc02012a0:	2685                	addiw	a3,a3,1
ffffffffc02012a2:	862e                	mv	a2,a1
ffffffffc02012a4:	fed898e3          	bne	a7,a3,ffffffffc0201294 <slub_alloc+0x18a>
            newsl->next = cache->slabs_free;
ffffffffc02012a8:	00e806b3          	add	a3,a6,a4
ffffffffc02012ac:	6e90                	ld	a2,24(a3)
        sl->next = cache->slabs_partial;
ffffffffc02012ae:	6a8c                	ld	a1,16(a3)
            newsl->next = cache->slabs_free;
ffffffffc02012b0:	f390                	sd	a2,32(a5)
            cache->slabs_free = newsl;
ffffffffc02012b2:	bdd5                	j	ffffffffc02011a6 <slub_alloc+0x9c>
        *obj = (i == obj_num - 1) ? NULL : (void *)(p + (i + 1) * obj_size);
ffffffffc02012b4:	4501                	li	a0,0
ffffffffc02012b6:	00c305b3          	add	a1,t1,a2
ffffffffc02012ba:	b7d5                	j	ffffffffc020129e <slub_alloc+0x194>
        return NULL;
ffffffffc02012bc:	4501                	li	a0,0
}
ffffffffc02012be:	8082                	ret
    void *page_kva = KADDR(page2pa(page));
ffffffffc02012c0:	86be                	mv	a3,a5
ffffffffc02012c2:	00001617          	auipc	a2,0x1
ffffffffc02012c6:	26e60613          	addi	a2,a2,622 # ffffffffc0202530 <etext+0x7e6>
ffffffffc02012ca:	03700593          	li	a1,55
ffffffffc02012ce:	00001517          	auipc	a0,0x1
ffffffffc02012d2:	28a50513          	addi	a0,a0,650 # ffffffffc0202558 <etext+0x80e>
ffffffffc02012d6:	ef7fe0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc02012da <slub_free>:

/* 释放对象 */
void slub_free(void *objp, size_t size) {
    if (objp == NULL)
ffffffffc02012da:	12050a63          	beqz	a0,ffffffffc020140e <slub_free+0x134>
void slub_free(void *objp, size_t size) {
ffffffffc02012de:	1141                	addi	sp,sp,-16
ffffffffc02012e0:	e406                	sd	ra,8(sp)
        return;

    // 如果对象大于 SLAB_PAGE_SIZE，直接按页释放
    if (size > SLAB_PAGE_SIZE) {
ffffffffc02012e2:	6705                	lui	a4,0x1
ffffffffc02012e4:	0eb76063          	bltu	a4,a1,ffffffffc02013c4 <slub_free+0xea>
    while (s < size && idx < CACHE_NUM) {
ffffffffc02012e8:	47a1                	li	a5,8
ffffffffc02012ea:	12b7f363          	bgeu	a5,a1,ffffffffc0201410 <slub_free+0x136>
    int idx = 0;
ffffffffc02012ee:	4701                	li	a4,0
        s <<= 1;
ffffffffc02012f0:	0786                	slli	a5,a5,0x1
        idx++;
ffffffffc02012f2:	2705                	addiw	a4,a4,1 # 1001 <kern_entry-0xffffffffc01fefff>
    while (s < size && idx < CACHE_NUM) {
ffffffffc02012f4:	00b7f563          	bgeu	a5,a1,ffffffffc02012fe <slub_free+0x24>
ffffffffc02012f8:	ff770613          	addi	a2,a4,-9
ffffffffc02012fc:	fa75                	bnez	a2,ffffffffc02012f0 <slub_free+0x16>
    return (idx >= CACHE_NUM) ? -1 : idx;
ffffffffc02012fe:	47a5                	li	a5,9
ffffffffc0201300:	0af70f63          	beq	a4,a5,ffffffffc02013be <slub_free+0xe4>
ffffffffc0201304:	00571313          	slli	t1,a4,0x5
ffffffffc0201308:	00830793          	addi	a5,t1,8
        return;

    struct kmem_cache *cache = &caches[idx];

    uintptr_t obj_addr = (uintptr_t)objp;
    uintptr_t page_addr = obj_addr & ~(SLAB_PAGE_SIZE - 1);
ffffffffc020130c:	75fd                	lui	a1,0xfffff
ffffffffc020130e:	8de9                	and	a1,a1,a0
    struct slab *sl = (struct slab *)page_addr;

    // 重新插入 freelist
    *(void **)objp = sl->freelist;
ffffffffc0201310:	6594                	ld	a3,8(a1)
    sl->freelist = objp;
    sl->inuse--;

    // 清除 bitmap 位
    int idx_bit = ((char *)objp - (char *)sl->obj_base) / cache->obj_size;
ffffffffc0201312:	0716                	slli	a4,a4,0x5
ffffffffc0201314:	00005817          	auipc	a6,0x5
ffffffffc0201318:	e6c80813          	addi	a6,a6,-404 # ffffffffc0206180 <caches>
    *(void **)objp = sl->freelist;
ffffffffc020131c:	e114                	sd	a3,0(a0)
    int idx_bit = ((char *)objp - (char *)sl->obj_base) / cache->obj_size;
ffffffffc020131e:	6d94                	ld	a3,24(a1)
ffffffffc0201320:	00e80e33          	add	t3,a6,a4
ffffffffc0201324:	000e3883          	ld	a7,0(t3)
ffffffffc0201328:	40d506b3          	sub	a3,a0,a3
    sl->freelist = objp;
ffffffffc020132c:	e588                	sd	a0,8(a1)
    int idx_bit = ((char *)objp - (char *)sl->obj_base) / cache->obj_size;
ffffffffc020132e:	0316d6b3          	divu	a3,a3,a7
    sl->inuse--;
ffffffffc0201332:	4190                	lw	a2,0(a1)
    sl->bitmap[idx_bit / 8] &= ~(1 << (idx_bit % 8));
ffffffffc0201334:	0105b883          	ld	a7,16(a1) # fffffffffffff010 <end+0x3fdf8d20>
    sl->inuse--;
ffffffffc0201338:	367d                	addiw	a2,a2,-1
ffffffffc020133a:	c190                	sw	a2,0(a1)
    sl->bitmap[idx_bit / 8] &= ~(1 << (idx_bit % 8));
ffffffffc020133c:	4605                	li	a2,1
    int idx_bit = ((char *)objp - (char *)sl->obj_base) / cache->obj_size;
ffffffffc020133e:	2681                	sext.w	a3,a3
    sl->bitmap[idx_bit / 8] &= ~(1 << (idx_bit % 8));
ffffffffc0201340:	41f6d51b          	sraiw	a0,a3,0x1f
ffffffffc0201344:	01d5551b          	srliw	a0,a0,0x1d
ffffffffc0201348:	9d35                	addw	a0,a0,a3
ffffffffc020134a:	4035551b          	sraiw	a0,a0,0x3
ffffffffc020134e:	9546                	add	a0,a0,a7
ffffffffc0201350:	00054883          	lbu	a7,0(a0)
ffffffffc0201354:	8a9d                	andi	a3,a3,7
ffffffffc0201356:	00d616bb          	sllw	a3,a2,a3
ffffffffc020135a:	fff6c693          	not	a3,a3
ffffffffc020135e:	0116f6b3          	and	a3,a3,a7
ffffffffc0201362:	00d50023          	sb	a3,0(a0)

    // 若 slab 从 full 变为 partial
    struct slab **p = &cache->slabs_full;
ffffffffc0201366:	008e3683          	ld	a3,8(t3)
    while (*p && *p != sl)
ffffffffc020136a:	c695                	beqz	a3,ffffffffc0201396 <slub_free+0xbc>
    struct slab **p = &cache->slabs_full;
ffffffffc020136c:	01078633          	add	a2,a5,a6
    while (*p && *p != sl)
ffffffffc0201370:	621c                	ld	a5,0(a2)
ffffffffc0201372:	00b78963          	beq	a5,a1,ffffffffc0201384 <slub_free+0xaa>
        p = &(*p)->next;
ffffffffc0201376:	7394                	ld	a3,32(a5)
ffffffffc0201378:	02078613          	addi	a2,a5,32
    while (*p && *p != sl)
ffffffffc020137c:	ce89                	beqz	a3,ffffffffc0201396 <slub_free+0xbc>
ffffffffc020137e:	87b6                	mv	a5,a3
ffffffffc0201380:	feb79be3          	bne	a5,a1,ffffffffc0201376 <slub_free+0x9c>
    if (*p == sl) {
ffffffffc0201384:	00b69963          	bne	a3,a1,ffffffffc0201396 <slub_free+0xbc>
        *p = sl->next;
ffffffffc0201388:	7194                	ld	a3,32(a1)
        sl->next = cache->slabs_partial;
ffffffffc020138a:	00e807b3          	add	a5,a6,a4
        *p = sl->next;
ffffffffc020138e:	e214                	sd	a3,0(a2)
        sl->next = cache->slabs_partial;
ffffffffc0201390:	6b94                	ld	a3,16(a5)
ffffffffc0201392:	f194                	sd	a3,32(a1)
        cache->slabs_partial = sl;
ffffffffc0201394:	eb8c                	sd	a1,16(a5)
    }

    // 若 slab 全空，释放页
    if (sl->inuse == 0) {
ffffffffc0201396:	419c                	lw	a5,0(a1)
ffffffffc0201398:	e39d                	bnez	a5,ffffffffc02013be <slub_free+0xe4>
        struct slab **q = &cache->slabs_partial;
ffffffffc020139a:	9742                	add	a4,a4,a6
ffffffffc020139c:	6b14                	ld	a3,16(a4)
        while (*q && *q != sl)
ffffffffc020139e:	c285                	beqz	a3,ffffffffc02013be <slub_free+0xe4>
        struct slab **q = &cache->slabs_partial;
ffffffffc02013a0:	0341                	addi	t1,t1,16
ffffffffc02013a2:	00680733          	add	a4,a6,t1
        while (*q && *q != sl)
ffffffffc02013a6:	631c                	ld	a5,0(a4)
ffffffffc02013a8:	00b78963          	beq	a5,a1,ffffffffc02013ba <slub_free+0xe0>
            q = &(*q)->next;
ffffffffc02013ac:	7394                	ld	a3,32(a5)
ffffffffc02013ae:	02078713          	addi	a4,a5,32
        while (*q && *q != sl)
ffffffffc02013b2:	c691                	beqz	a3,ffffffffc02013be <slub_free+0xe4>
ffffffffc02013b4:	87b6                	mv	a5,a3
ffffffffc02013b6:	feb79be3          	bne	a5,a1,ffffffffc02013ac <slub_free+0xd2>
        if (*q == sl) {
ffffffffc02013ba:	04f68e63          	beq	a3,a5,ffffffffc0201416 <slub_free+0x13c>
            *q = sl->next;
            struct Page *page = kva2page(page_addr);
            free_page(page);
        }
    }
}
ffffffffc02013be:	60a2                	ld	ra,8(sp)
ffffffffc02013c0:	0141                	addi	sp,sp,16
ffffffffc02013c2:	8082                	ret
}
static inline void flush_tlb() { asm volatile("sfence.vm"); }
extern char bootstack[], bootstacktop[]; // defined in entry.S
static inline struct Page *kva2page(uintptr_t kva)
{
    return pa2page(PADDR(kva));
ffffffffc02013c4:	c02007b7          	lui	a5,0xc0200
ffffffffc02013c8:	0af56563          	bltu	a0,a5,ffffffffc0201472 <slub_free+0x198>
ffffffffc02013cc:	00005797          	auipc	a5,0x5
ffffffffc02013d0:	f0c7b783          	ld	a5,-244(a5) # ffffffffc02062d8 <va_pa_offset>
    if (PPN(pa) >= npage) {
ffffffffc02013d4:	00005697          	auipc	a3,0x5
ffffffffc02013d8:	f0c6b683          	ld	a3,-244(a3) # ffffffffc02062e0 <npage>
    return pa2page(PADDR(kva));
ffffffffc02013dc:	40f507b3          	sub	a5,a0,a5
    if (PPN(pa) >= npage) {
ffffffffc02013e0:	83b1                	srli	a5,a5,0xc
ffffffffc02013e2:	06d7fc63          	bgeu	a5,a3,ffffffffc020145a <slub_free+0x180>
    return &pages[PPN(pa) - nbase];
ffffffffc02013e6:	00001697          	auipc	a3,0x1
ffffffffc02013ea:	7da6b683          	ld	a3,2010(a3) # ffffffffc0202bc0 <nbase>
        size_t npages = (size + PGSIZE - 1) / PGSIZE;  // 向上取整
ffffffffc02013ee:	177d                	addi	a4,a4,-1
ffffffffc02013f0:	00005517          	auipc	a0,0x5
ffffffffc02013f4:	ef853503          	ld	a0,-264(a0) # ffffffffc02062e8 <pages>
ffffffffc02013f8:	8f95                	sub	a5,a5,a3
ffffffffc02013fa:	00279693          	slli	a3,a5,0x2
ffffffffc02013fe:	97b6                	add	a5,a5,a3
ffffffffc0201400:	95ba                	add	a1,a1,a4
ffffffffc0201402:	078e                	slli	a5,a5,0x3
        free_pages(page, npages);
ffffffffc0201404:	81b1                	srli	a1,a1,0xc
}
ffffffffc0201406:	60a2                	ld	ra,8(sp)
        free_pages(page, npages);
ffffffffc0201408:	953e                	add	a0,a0,a5
}
ffffffffc020140a:	0141                	addi	sp,sp,16
        free_pages(page, npages);
ffffffffc020140c:	be09                	j	ffffffffc0200f1e <free_pages>
ffffffffc020140e:	8082                	ret
    while (s < size && idx < CACHE_NUM) {
ffffffffc0201410:	4301                	li	t1,0
    int idx = 0;
ffffffffc0201412:	4701                	li	a4,0
ffffffffc0201414:	bde5                	j	ffffffffc020130c <slub_free+0x32>
            *q = sl->next;
ffffffffc0201416:	7290                	ld	a2,32(a3)
    return pa2page(PADDR(kva));
ffffffffc0201418:	c02007b7          	lui	a5,0xc0200
ffffffffc020141c:	e310                	sd	a2,0(a4)
ffffffffc020141e:	06f6e763          	bltu	a3,a5,ffffffffc020148c <slub_free+0x1b2>
ffffffffc0201422:	00005797          	auipc	a5,0x5
ffffffffc0201426:	eb67b783          	ld	a5,-330(a5) # ffffffffc02062d8 <va_pa_offset>
    if (PPN(pa) >= npage) {
ffffffffc020142a:	00005717          	auipc	a4,0x5
ffffffffc020142e:	eb673703          	ld	a4,-330(a4) # ffffffffc02062e0 <npage>
    return pa2page(PADDR(kva));
ffffffffc0201432:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage) {
ffffffffc0201436:	83b1                	srli	a5,a5,0xc
ffffffffc0201438:	02e7f163          	bgeu	a5,a4,ffffffffc020145a <slub_free+0x180>
    return &pages[PPN(pa) - nbase];
ffffffffc020143c:	00001717          	auipc	a4,0x1
ffffffffc0201440:	78473703          	ld	a4,1924(a4) # ffffffffc0202bc0 <nbase>
ffffffffc0201444:	00005517          	auipc	a0,0x5
ffffffffc0201448:	ea453503          	ld	a0,-348(a0) # ffffffffc02062e8 <pages>
            free_page(page);
ffffffffc020144c:	4585                	li	a1,1
ffffffffc020144e:	8f99                	sub	a5,a5,a4
ffffffffc0201450:	00279713          	slli	a4,a5,0x2
ffffffffc0201454:	97ba                	add	a5,a5,a4
ffffffffc0201456:	078e                	slli	a5,a5,0x3
ffffffffc0201458:	b77d                	j	ffffffffc0201406 <slub_free+0x12c>
        panic("pa2page called with invalid pa");
ffffffffc020145a:	00001617          	auipc	a2,0x1
ffffffffc020145e:	04660613          	addi	a2,a2,70 # ffffffffc02024a0 <etext+0x756>
ffffffffc0201462:	06a00593          	li	a1,106
ffffffffc0201466:	00001517          	auipc	a0,0x1
ffffffffc020146a:	05a50513          	addi	a0,a0,90 # ffffffffc02024c0 <etext+0x776>
ffffffffc020146e:	d5ffe0ef          	jal	ffffffffc02001cc <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201472:	86aa                	mv	a3,a0
ffffffffc0201474:	00001617          	auipc	a2,0x1
ffffffffc0201478:	00460613          	addi	a2,a2,4 # ffffffffc0202478 <etext+0x72e>
ffffffffc020147c:	07200593          	li	a1,114
ffffffffc0201480:	00001517          	auipc	a0,0x1
ffffffffc0201484:	04050513          	addi	a0,a0,64 # ffffffffc02024c0 <etext+0x776>
ffffffffc0201488:	d45fe0ef          	jal	ffffffffc02001cc <__panic>
ffffffffc020148c:	00001617          	auipc	a2,0x1
ffffffffc0201490:	fec60613          	addi	a2,a2,-20 # ffffffffc0202478 <etext+0x72e>
ffffffffc0201494:	07200593          	li	a1,114
ffffffffc0201498:	00001517          	auipc	a0,0x1
ffffffffc020149c:	02850513          	addi	a0,a0,40 # ffffffffc02024c0 <etext+0x776>
ffffffffc02014a0:	d2dfe0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc02014a4 <slub_test>:
#include <assert.h> 

#define TEST_OBJ_NUM 1000

void slub_test(void) {
ffffffffc02014a4:	7131                	addi	sp,sp,-192
ffffffffc02014a6:	f922                	sd	s0,176(sp)
ffffffffc02014a8:	e15a                	sd	s6,128(sp)
ffffffffc02014aa:	fd06                	sd	ra,184(sp)
ffffffffc02014ac:	f526                	sd	s1,168(sp)
ffffffffc02014ae:	f14a                	sd	s2,160(sp)
ffffffffc02014b0:	ed4e                	sd	s3,152(sp)
ffffffffc02014b2:	e952                	sd	s4,144(sp)
ffffffffc02014b4:	e556                	sd	s5,136(sp)
ffffffffc02014b6:	fcde                	sd	s7,120(sp)
ffffffffc02014b8:	f8e2                	sd	s8,112(sp)
ffffffffc02014ba:	f4e6                	sd	s9,104(sp)
ffffffffc02014bc:	f0ea                	sd	s10,96(sp)
ffffffffc02014be:	ecee                	sd	s11,88(sp)
ffffffffc02014c0:	0180                	addi	s0,sp,192
    cprintf("========== SLUB 测试开始 ==========\n");
ffffffffc02014c2:	00001517          	auipc	a0,0x1
ffffffffc02014c6:	0a650513          	addi	a0,a0,166 # ffffffffc0202568 <etext+0x81e>
ffffffffc02014ca:	00005b17          	auipc	s6,0x5
ffffffffc02014ce:	cb6b0b13          	addi	s6,s6,-842 # ffffffffc0206180 <caches>
ffffffffc02014d2:	c7bfe0ef          	jal	ffffffffc020014c <cprintf>
    for (int i = 0; i < CACHE_NUM; i++) {
ffffffffc02014d6:	87da                	mv	a5,s6
    cprintf("========== SLUB 测试开始 ==========\n");
ffffffffc02014d8:	470d                	li	a4,3
        caches[i].obj_size = (1 << (i + MIN_OBJ_SHIFT));
ffffffffc02014da:	4585                	li	a1,1
    for (int i = 0; i < CACHE_NUM; i++) {
ffffffffc02014dc:	4631                	li	a2,12
        caches[i].obj_size = (1 << (i + MIN_OBJ_SHIFT));
ffffffffc02014de:	00e596bb          	sllw	a3,a1,a4
        caches[i].slabs_full = NULL;
ffffffffc02014e2:	0007b423          	sd	zero,8(a5)
        caches[i].slabs_partial = NULL;
ffffffffc02014e6:	0007b823          	sd	zero,16(a5)
        caches[i].slabs_free = NULL;
ffffffffc02014ea:	0007bc23          	sd	zero,24(a5)
        caches[i].obj_size = (1 << (i + MIN_OBJ_SHIFT));
ffffffffc02014ee:	e394                	sd	a3,0(a5)
    for (int i = 0; i < CACHE_NUM; i++) {
ffffffffc02014f0:	2705                	addiw	a4,a4,1
ffffffffc02014f2:	02078793          	addi	a5,a5,32
ffffffffc02014f6:	fec714e3          	bne	a4,a2,ffffffffc02014de <slub_test+0x3a>

    /* 初始化 SLUB */
    slub_init();

    /* 不同大小的对象 */
    size_t sizes[] = {8, 16, 32, 64, 128, 256, 512, 1024, 2048};
ffffffffc02014fa:	00001797          	auipc	a5,0x1
ffffffffc02014fe:	4ee78793          	addi	a5,a5,1262 # ffffffffc02029e8 <buddy_pmm_manager+0x38>
ffffffffc0201502:	6790                	ld	a2,8(a5)
ffffffffc0201504:	6b94                	ld	a3,16(a5)
ffffffffc0201506:	638c                	ld	a1,0(a5)
ffffffffc0201508:	f4c43823          	sd	a2,-176(s0)
ffffffffc020150c:	f4d43c23          	sd	a3,-168(s0)
ffffffffc0201510:	7390                	ld	a2,32(a5)
ffffffffc0201512:	7794                	ld	a3,40(a5)
ffffffffc0201514:	f4b43423          	sd	a1,-184(s0)
ffffffffc0201518:	f6c43423          	sd	a2,-152(s0)
ffffffffc020151c:	6f8c                	ld	a1,24(a5)
ffffffffc020151e:	7b90                	ld	a2,48(a5)
ffffffffc0201520:	f6d43823          	sd	a3,-144(s0)
ffffffffc0201524:	7f94                	ld	a3,56(a5)
ffffffffc0201526:	63bc                	ld	a5,64(a5)
ffffffffc0201528:	6c89                	lui	s9,0x2
    int num_sizes = sizeof(sizes) / sizeof(sizes[0]);
    void *objs[num_sizes][TEST_OBJ_NUM / num_sizes];

    /* 阶段 1：顺序分配所有对象 */
    cprintf("【阶段1】分配不同大小的对象...\n");
ffffffffc020152a:	00001517          	auipc	a0,0x1
ffffffffc020152e:	06e50513          	addi	a0,a0,110 # ffffffffc0202598 <etext+0x84e>
    size_t sizes[] = {8, 16, 32, 64, 128, 256, 512, 1024, 2048};
ffffffffc0201532:	f8f43423          	sd	a5,-120(s0)
    void *objs[num_sizes][TEST_OBJ_NUM / num_sizes];
ffffffffc0201536:	77f9                	lui	a5,0xffffe
ffffffffc0201538:	0c078793          	addi	a5,a5,192 # ffffffffffffe0c0 <end+0x3fdf7dd0>
ffffffffc020153c:	913e                	add	sp,sp,a5
ffffffffc020153e:	f4840b93          	addi	s7,s0,-184
ffffffffc0201542:	f38c8c93          	addi	s9,s9,-200 # 1f38 <kern_entry-0xffffffffc01fe0c8>
    size_t sizes[] = {8, 16, 32, 64, 128, 256, 512, 1024, 2048};
ffffffffc0201546:	f6b43023          	sd	a1,-160(s0)
ffffffffc020154a:	f6c43c23          	sd	a2,-136(s0)
ffffffffc020154e:	f8d43023          	sd	a3,-128(s0)
    void *objs[num_sizes][TEST_OBJ_NUM / num_sizes];
ffffffffc0201552:	8d0a                	mv	s10,sp
    cprintf("【阶段1】分配不同大小的对象...\n");
ffffffffc0201554:	bf9fe0ef          	jal	ffffffffc020014c <cprintf>
ffffffffc0201558:	8c5e                	mv	s8,s7
ffffffffc020155a:	9c8a                	add	s9,s9,sp
ffffffffc020155c:	8a8a                	mv	s5,sp
    for (int s = 0; s < num_sizes; s++) {
        size_t sz = sizes[s];
        for (int i = 0; i < TEST_OBJ_NUM / num_sizes; i++) {
ffffffffc020155e:	06f00a13          	li	s4,111
        size_t sz = sizes[s];
ffffffffc0201562:	000c3983          	ld	s3,0(s8)
ffffffffc0201566:	8956                	mv	s2,s5
        for (int i = 0; i < TEST_OBJ_NUM / num_sizes; i++) {
ffffffffc0201568:	4481                	li	s1,0
            objs[s][i] = slub_alloc(sz);
ffffffffc020156a:	854e                	mv	a0,s3
ffffffffc020156c:	b9fff0ef          	jal	ffffffffc020110a <slub_alloc>
ffffffffc0201570:	00a93023          	sd	a0,0(s2)
            assert(objs[s][i] != NULL);
ffffffffc0201574:	28050163          	beqz	a0,ffffffffc02017f6 <slub_test+0x352>
            memset(objs[s][i], 0xA0 + (i & 0xF), sz);
ffffffffc0201578:	00f4f593          	andi	a1,s1,15
ffffffffc020157c:	fa05859b          	addiw	a1,a1,-96
ffffffffc0201580:	0ff5f593          	zext.b	a1,a1
ffffffffc0201584:	864e                	mv	a2,s3
        for (int i = 0; i < TEST_OBJ_NUM / num_sizes; i++) {
ffffffffc0201586:	2485                	addiw	s1,s1,1
            memset(objs[s][i], 0xA0 + (i & 0xF), sz);
ffffffffc0201588:	7b0000ef          	jal	ffffffffc0201d38 <memset>
        for (int i = 0; i < TEST_OBJ_NUM / num_sizes; i++) {
ffffffffc020158c:	0921                	addi	s2,s2,8
ffffffffc020158e:	fd449ee3          	bne	s1,s4,ffffffffc020156a <slub_test+0xc6>
    for (int s = 0; s < num_sizes; s++) {
ffffffffc0201592:	378a8a93          	addi	s5,s5,888
ffffffffc0201596:	0c21                	addi	s8,s8,8
ffffffffc0201598:	fd9a95e3          	bne	s5,s9,ffffffffc0201562 <slub_test+0xbe>
        }
    }
    cprintf("【阶段1】分配完成。\n\n");
ffffffffc020159c:	00001517          	auipc	a0,0x1
ffffffffc02015a0:	04450513          	addi	a0,a0,68 # ffffffffc02025e0 <etext+0x896>
ffffffffc02015a4:	ba9fe0ef          	jal	ffffffffc020014c <cprintf>

    /* 阶段 2：释放每种大小一半对象，并检查 slab 状态 */
    cprintf("【阶段2】释放部分对象...\n");
ffffffffc02015a8:	6c09                	lui	s8,0x2
ffffffffc02015aa:	00001517          	auipc	a0,0x1
ffffffffc02015ae:	05650513          	addi	a0,a0,86 # ffffffffc0202600 <etext+0x8b6>
ffffffffc02015b2:	0f0c0c13          	addi	s8,s8,240 # 20f0 <kern_entry-0xffffffffc01fdf10>
ffffffffc02015b6:	b97fe0ef          	jal	ffffffffc020014c <cprintf>
    for (int s = 0; s < num_sizes; s++) {
ffffffffc02015ba:	1b8d0913          	addi	s2,s10,440
ffffffffc02015be:	9c6a                	add	s8,s8,s10
    cprintf("【阶段2】释放部分对象...\n");
ffffffffc02015c0:	8ade                	mv	s5,s7
    while (s < size && idx < CACHE_NUM) {
ffffffffc02015c2:	4ca1                	li	s9,8
    return (idx >= CACHE_NUM) ? -1 : idx;
ffffffffc02015c4:	4da5                	li	s11,9
        size_t sz = sizes[s];
ffffffffc02015c6:	000ab983          	ld	s3,0(s5)
    int idx = 0;
ffffffffc02015ca:	4a01                	li	s4,0
    while (s < size && idx < CACHE_NUM) {
ffffffffc02015cc:	013cfd63          	bgeu	s9,s3,ffffffffc02015e6 <slub_test+0x142>
    size_t s = (1 << MIN_OBJ_SHIFT);
ffffffffc02015d0:	47a1                	li	a5,8
ffffffffc02015d2:	a021                	j	ffffffffc02015da <slub_test+0x136>
    while (s < size && idx < CACHE_NUM) {
ffffffffc02015d4:	ff7a0713          	addi	a4,s4,-9
ffffffffc02015d8:	c709                	beqz	a4,ffffffffc02015e2 <slub_test+0x13e>
        s <<= 1;
ffffffffc02015da:	0786                	slli	a5,a5,0x1
        idx++;
ffffffffc02015dc:	2a05                	addiw	s4,s4,1
    while (s < size && idx < CACHE_NUM) {
ffffffffc02015de:	ff37ebe3          	bltu	a5,s3,ffffffffc02015d4 <slub_test+0x130>
    return (idx >= CACHE_NUM) ? -1 : idx;
ffffffffc02015e2:	23ba0a63          	beq	s4,s11,ffffffffc0201816 <slub_test+0x372>
        struct kmem_cache *cache = &caches[size_to_index(sz)];
        for (int i = 0; i < (TEST_OBJ_NUM / num_sizes) / 2; i++) {
ffffffffc02015e6:	e4890493          	addi	s1,s2,-440
            if (objs[s][i]) {
ffffffffc02015ea:	6088                	ld	a0,0(s1)
ffffffffc02015ec:	c511                	beqz	a0,ffffffffc02015f8 <slub_test+0x154>
                slub_free(objs[s][i], sz);
ffffffffc02015ee:	85ce                	mv	a1,s3
ffffffffc02015f0:	cebff0ef          	jal	ffffffffc02012da <slub_free>
                objs[s][i] = NULL;
ffffffffc02015f4:	0004b023          	sd	zero,0(s1)
        for (int i = 0; i < (TEST_OBJ_NUM / num_sizes) / 2; i++) {
ffffffffc02015f8:	04a1                	addi	s1,s1,8
ffffffffc02015fa:	ff2498e3          	bne	s1,s2,ffffffffc02015ea <slub_test+0x146>
            }
        }
        /* 检查 partial slab 状态 */
        struct slab *sl = cache->slabs_partial;
ffffffffc02015fe:	005a1793          	slli	a5,s4,0x5
ffffffffc0201602:	97da                	add	a5,a5,s6
ffffffffc0201604:	6b9c                	ld	a5,16(a5)
        while (sl) {
ffffffffc0201606:	cb89                	beqz	a5,ffffffffc0201618 <slub_test+0x174>
            assert(sl->inuse > 0 && sl->inuse < sl->total);
ffffffffc0201608:	4398                	lw	a4,0(a5)
ffffffffc020160a:	20070863          	beqz	a4,ffffffffc020181a <slub_test+0x376>
ffffffffc020160e:	43d4                	lw	a3,4(a5)
ffffffffc0201610:	20d77563          	bgeu	a4,a3,ffffffffc020181a <slub_test+0x376>
            sl = sl->next;
ffffffffc0201614:	739c                	ld	a5,32(a5)
        while (sl) {
ffffffffc0201616:	fbed                	bnez	a5,ffffffffc0201608 <slub_test+0x164>
        }
        cprintf("  -> 释放 %lu 字节对象的一半完成。\n", (unsigned long)sz);
ffffffffc0201618:	85ce                	mv	a1,s3
ffffffffc020161a:	00001517          	auipc	a0,0x1
ffffffffc020161e:	03650513          	addi	a0,a0,54 # ffffffffc0202650 <etext+0x906>
    for (int s = 0; s < num_sizes; s++) {
ffffffffc0201622:	37890913          	addi	s2,s2,888
        cprintf("  -> 释放 %lu 字节对象的一半完成。\n", (unsigned long)sz);
ffffffffc0201626:	b27fe0ef          	jal	ffffffffc020014c <cprintf>
    for (int s = 0; s < num_sizes; s++) {
ffffffffc020162a:	0aa1                	addi	s5,s5,8
ffffffffc020162c:	f9891de3          	bne	s2,s8,ffffffffc02015c6 <slub_test+0x122>
    }
    cprintf("【阶段2】部分释放完成。\n\n");
ffffffffc0201630:	00001517          	auipc	a0,0x1
ffffffffc0201634:	05050513          	addi	a0,a0,80 # ffffffffc0202680 <etext+0x936>
ffffffffc0201638:	b15fe0ef          	jal	ffffffffc020014c <cprintf>

    /* 阶段 3：再次分配，测试复用空闲 slab */
    cprintf("【阶段3】复用测试...\n");
ffffffffc020163c:	00001517          	auipc	a0,0x1
ffffffffc0201640:	06c50513          	addi	a0,a0,108 # ffffffffc02026a8 <etext+0x95e>
ffffffffc0201644:	b09fe0ef          	jal	ffffffffc020014c <cprintf>
    for (int s = 0; s < num_sizes; s++) {
ffffffffc0201648:	048b8c13          	addi	s8,s7,72
    cprintf("【阶段3】复用测试...\n");
ffffffffc020164c:	89de                	mv	s3,s7
        size_t sz = sizes[s];
ffffffffc020164e:	0009b903          	ld	s2,0(s3)
ffffffffc0201652:	44ed                	li	s1,27
        for (int i = 0; i < (TEST_OBJ_NUM / num_sizes) / 4; i++) {
            void *ptr = slub_alloc(sz);
ffffffffc0201654:	854a                	mv	a0,s2
ffffffffc0201656:	ab5ff0ef          	jal	ffffffffc020110a <slub_alloc>
            assert(ptr != NULL);
ffffffffc020165a:	1e050063          	beqz	a0,ffffffffc020183a <slub_test+0x396>
            memset(ptr, 0x5A, sz);
ffffffffc020165e:	864a                	mv	a2,s2
ffffffffc0201660:	05a00593          	li	a1,90
        for (int i = 0; i < (TEST_OBJ_NUM / num_sizes) / 4; i++) {
ffffffffc0201664:	34fd                	addiw	s1,s1,-1
            memset(ptr, 0x5A, sz);
ffffffffc0201666:	6d2000ef          	jal	ffffffffc0201d38 <memset>
        for (int i = 0; i < (TEST_OBJ_NUM / num_sizes) / 4; i++) {
ffffffffc020166a:	f4ed                	bnez	s1,ffffffffc0201654 <slub_test+0x1b0>
    for (int s = 0; s < num_sizes; s++) {
ffffffffc020166c:	09a1                	addi	s3,s3,8
ffffffffc020166e:	ff8990e3          	bne	s3,s8,ffffffffc020164e <slub_test+0x1aa>
        }
    }
    cprintf("【阶段3】复用测试完成。\n\n");
ffffffffc0201672:	00001517          	auipc	a0,0x1
ffffffffc0201676:	06650513          	addi	a0,a0,102 # ffffffffc02026d8 <etext+0x98e>
ffffffffc020167a:	ad3fe0ef          	jal	ffffffffc020014c <cprintf>

    /* 阶段 4：随机释放所有对象，测试 slab 回收页 */
    cprintf("【阶段4】释放所有对象...\n");
ffffffffc020167e:	6c89                	lui	s9,0x2
ffffffffc0201680:	00001517          	auipc	a0,0x1
ffffffffc0201684:	08050513          	addi	a0,a0,128 # ffffffffc0202700 <etext+0x9b6>
ffffffffc0201688:	f30c8c93          	addi	s9,s9,-208 # 1f30 <kern_entry-0xffffffffc01fe0d0>
ffffffffc020168c:	ff8d0493          	addi	s1,s10,-8
ffffffffc0201690:	9cea                	add	s9,s9,s10
ffffffffc0201692:	abbfe0ef          	jal	ffffffffc020014c <cprintf>
ffffffffc0201696:	8ade                	mv	s5,s7
    while (s < size && idx < CACHE_NUM) {
ffffffffc0201698:	4d21                	li	s10,8
    for (int s = 0; s < num_sizes; s++) {
        size_t sz = sizes[s];
ffffffffc020169a:	000ab903          	ld	s2,0(s5)
    int idx = 0;
ffffffffc020169e:	4981                	li	s3,0
    while (s < size && idx < CACHE_NUM) {
ffffffffc02016a0:	012d7d63          	bgeu	s10,s2,ffffffffc02016ba <slub_test+0x216>
    size_t s = (1 << MIN_OBJ_SHIFT);
ffffffffc02016a4:	47a1                	li	a5,8
        s <<= 1;
ffffffffc02016a6:	0786                	slli	a5,a5,0x1
        idx++;
ffffffffc02016a8:	2985                	addiw	s3,s3,1
    while (s < size && idx < CACHE_NUM) {
ffffffffc02016aa:	0127f563          	bgeu	a5,s2,ffffffffc02016b4 <slub_test+0x210>
ffffffffc02016ae:	ff798713          	addi	a4,s3,-9
ffffffffc02016b2:	fb75                	bnez	a4,ffffffffc02016a6 <slub_test+0x202>
    return (idx >= CACHE_NUM) ? -1 : idx;
ffffffffc02016b4:	47a5                	li	a5,9
ffffffffc02016b6:	1af98463          	beq	s3,a5,ffffffffc020185e <slub_test+0x3ba>
        struct kmem_cache *cache = &caches[size_to_index(sz)];
        for (int i = TEST_OBJ_NUM / num_sizes - 1; i >= 0; i--) {
ffffffffc02016ba:	37848a13          	addi	s4,s1,888
    return (idx >= CACHE_NUM) ? -1 : idx;
ffffffffc02016be:	8dd2                	mv	s11,s4
            if (objs[s][i]) {
ffffffffc02016c0:	000db503          	ld	a0,0(s11)
ffffffffc02016c4:	c511                	beqz	a0,ffffffffc02016d0 <slub_test+0x22c>
                slub_free(objs[s][i], sz);
ffffffffc02016c6:	85ca                	mv	a1,s2
ffffffffc02016c8:	c13ff0ef          	jal	ffffffffc02012da <slub_free>
                objs[s][i] = NULL;
ffffffffc02016cc:	000db023          	sd	zero,0(s11)
        for (int i = TEST_OBJ_NUM / num_sizes - 1; i >= 0; i--) {
ffffffffc02016d0:	1de1                	addi	s11,s11,-8
ffffffffc02016d2:	fe9d97e3          	bne	s11,s1,ffffffffc02016c0 <slub_test+0x21c>
            }
        }
        /* 检查 full slab 和 partial slab 都为空或已回收 */
        struct slab *sl = cache->slabs_partial;
ffffffffc02016d6:	0996                	slli	s3,s3,0x5
ffffffffc02016d8:	013b07b3          	add	a5,s6,s3
ffffffffc02016dc:	6b9c                	ld	a5,16(a5)
        while (sl) {
ffffffffc02016de:	cb81                	beqz	a5,ffffffffc02016ee <slub_test+0x24a>
            assert(sl->inuse > 0 || sl->total == 0);
ffffffffc02016e0:	4398                	lw	a4,0(a5)
ffffffffc02016e2:	e701                	bnez	a4,ffffffffc02016ea <slub_test+0x246>
ffffffffc02016e4:	43d8                	lw	a4,4(a5)
ffffffffc02016e6:	18071e63          	bnez	a4,ffffffffc0201882 <slub_test+0x3de>
            sl = sl->next;
ffffffffc02016ea:	739c                	ld	a5,32(a5)
        while (sl) {
ffffffffc02016ec:	fbf5                	bnez	a5,ffffffffc02016e0 <slub_test+0x23c>
        }
        sl = cache->slabs_full;
ffffffffc02016ee:	99da                	add	s3,s3,s6
ffffffffc02016f0:	0089b783          	ld	a5,8(s3)
        while (sl) {
ffffffffc02016f4:	c791                	beqz	a5,ffffffffc0201700 <slub_test+0x25c>
            assert(sl->inuse > 0);
ffffffffc02016f6:	4398                	lw	a4,0(a5)
ffffffffc02016f8:	16070563          	beqz	a4,ffffffffc0201862 <slub_test+0x3be>
            sl = sl->next;
ffffffffc02016fc:	739c                	ld	a5,32(a5)
        while (sl) {
ffffffffc02016fe:	ffe5                	bnez	a5,ffffffffc02016f6 <slub_test+0x252>
        }
        cprintf("  -> %lu 字节对象释放完毕。\n", (unsigned long)sz);
ffffffffc0201700:	85ca                	mv	a1,s2
ffffffffc0201702:	00001517          	auipc	a0,0x1
ffffffffc0201706:	05650513          	addi	a0,a0,86 # ffffffffc0202758 <etext+0xa0e>
ffffffffc020170a:	a43fe0ef          	jal	ffffffffc020014c <cprintf>
    for (int s = 0; s < num_sizes; s++) {
ffffffffc020170e:	0aa1                	addi	s5,s5,8
ffffffffc0201710:	014c8463          	beq	s9,s4,ffffffffc0201718 <slub_test+0x274>
ffffffffc0201714:	84d2                	mv	s1,s4
ffffffffc0201716:	b751                	j	ffffffffc020169a <slub_test+0x1f6>
    }
    cprintf("【阶段4】全部释放完成。\n\n");
ffffffffc0201718:	00001517          	auipc	a0,0x1
ffffffffc020171c:	06850513          	addi	a0,a0,104 # ffffffffc0202780 <etext+0xa36>
ffffffffc0201720:	a2dfe0ef          	jal	ffffffffc020014c <cprintf>

    /* 阶段 5：分配超过最大对象 */
    cprintf("【阶段5】测试超大对象...\n");
ffffffffc0201724:	00001517          	auipc	a0,0x1
ffffffffc0201728:	08450513          	addi	a0,a0,132 # ffffffffc02027a8 <etext+0xa5e>
ffffffffc020172c:	a21fe0ef          	jal	ffffffffc020014c <cprintf>
    void *bigobj = slub_alloc(4096);
ffffffffc0201730:	6505                	lui	a0,0x1
ffffffffc0201732:	9d9ff0ef          	jal	ffffffffc020110a <slub_alloc>
    assert(bigobj == NULL);
ffffffffc0201736:	16051663          	bnez	a0,ffffffffc02018a2 <slub_test+0x3fe>
    cprintf("  超大对象分配失败（正确行为）\n");
ffffffffc020173a:	00001517          	auipc	a0,0x1
ffffffffc020173e:	0a650513          	addi	a0,a0,166 # ffffffffc02027e0 <etext+0xa96>
ffffffffc0201742:	a0bfe0ef          	jal	ffffffffc020014c <cprintf>

    /* 阶段 6：释放 NULL 指针安全性测试 */
    cprintf("【阶段6】释放 NULL 测试...\n");
ffffffffc0201746:	00001517          	auipc	a0,0x1
ffffffffc020174a:	0ca50513          	addi	a0,a0,202 # ffffffffc0202810 <etext+0xac6>
ffffffffc020174e:	9fffe0ef          	jal	ffffffffc020014c <cprintf>
    slub_free(NULL, 16);
    cprintf("  释放 NULL 安全。\n");
ffffffffc0201752:	00001517          	auipc	a0,0x1
ffffffffc0201756:	0e650513          	addi	a0,a0,230 # ffffffffc0202838 <etext+0xaee>
ffffffffc020175a:	9f3fe0ef          	jal	ffffffffc020014c <cprintf>

    /* 阶段 7：检查总页数与 inuse 一致 */
    cprintf("【阶段7】总页数检查...\n");
ffffffffc020175e:	00001517          	auipc	a0,0x1
ffffffffc0201762:	0fa50513          	addi	a0,a0,250 # ffffffffc0202858 <etext+0xb0e>
ffffffffc0201766:	9e7fe0ef          	jal	ffffffffc020014c <cprintf>
    size_t total_objs = 0;
ffffffffc020176a:	4581                	li	a1,0
    while (s < size && idx < CACHE_NUM) {
ffffffffc020176c:	4521                	li	a0,8
    return (idx >= CACHE_NUM) ? -1 : idx;
ffffffffc020176e:	4825                	li	a6,9
    for (int s = 0; s < num_sizes; s++) {
        struct kmem_cache *cache = &caches[size_to_index(sizes[s])];
ffffffffc0201770:	000bb603          	ld	a2,0(s7)
    int idx = 0;
ffffffffc0201774:	4781                	li	a5,0
    while (s < size && idx < CACHE_NUM) {
ffffffffc0201776:	00c57c63          	bgeu	a0,a2,ffffffffc020178e <slub_test+0x2ea>
    size_t s = (1 << MIN_OBJ_SHIFT);
ffffffffc020177a:	4721                	li	a4,8
        s <<= 1;
ffffffffc020177c:	0706                	slli	a4,a4,0x1
        idx++;
ffffffffc020177e:	2785                	addiw	a5,a5,1
    while (s < size && idx < CACHE_NUM) {
ffffffffc0201780:	00c77563          	bgeu	a4,a2,ffffffffc020178a <slub_test+0x2e6>
ffffffffc0201784:	ff778693          	addi	a3,a5,-9
ffffffffc0201788:	faf5                	bnez	a3,ffffffffc020177c <slub_test+0x2d8>
    return (idx >= CACHE_NUM) ? -1 : idx;
ffffffffc020178a:	0d078863          	beq	a5,a6,ffffffffc020185a <slub_test+0x3b6>
        struct slab *sl = cache->slabs_partial;
ffffffffc020178e:	00579713          	slli	a4,a5,0x5
ffffffffc0201792:	00eb07b3          	add	a5,s6,a4
ffffffffc0201796:	6b9c                	ld	a5,16(a5)
        while (sl) {
ffffffffc0201798:	c791                	beqz	a5,ffffffffc02017a4 <slub_test+0x300>
            total_objs += sl->inuse;
ffffffffc020179a:	0007e683          	lwu	a3,0(a5)
            sl = sl->next;
ffffffffc020179e:	739c                	ld	a5,32(a5)
            total_objs += sl->inuse;
ffffffffc02017a0:	95b6                	add	a1,a1,a3
        while (sl) {
ffffffffc02017a2:	ffe5                	bnez	a5,ffffffffc020179a <slub_test+0x2f6>
        }
        sl = cache->slabs_full;
ffffffffc02017a4:	00eb07b3          	add	a5,s6,a4
ffffffffc02017a8:	679c                	ld	a5,8(a5)
        while (sl) {
ffffffffc02017aa:	c791                	beqz	a5,ffffffffc02017b6 <slub_test+0x312>
            total_objs += sl->inuse;
ffffffffc02017ac:	0007e703          	lwu	a4,0(a5)
            sl = sl->next;
ffffffffc02017b0:	739c                	ld	a5,32(a5)
            total_objs += sl->inuse;
ffffffffc02017b2:	95ba                	add	a1,a1,a4
        while (sl) {
ffffffffc02017b4:	ffe5                	bnez	a5,ffffffffc02017ac <slub_test+0x308>
    for (int s = 0; s < num_sizes; s++) {
ffffffffc02017b6:	0ba1                	addi	s7,s7,8
ffffffffc02017b8:	fb8b9ce3          	bne	s7,s8,ffffffffc0201770 <slub_test+0x2cc>
        }
    }
    cprintf("  总对象使用数统计完成: %lu\n", total_objs);
ffffffffc02017bc:	00001517          	auipc	a0,0x1
ffffffffc02017c0:	0c450513          	addi	a0,a0,196 # ffffffffc0202880 <etext+0xb36>
ffffffffc02017c4:	989fe0ef          	jal	ffffffffc020014c <cprintf>

    cprintf("========== SLUB 测试结束 ==========\n");
ffffffffc02017c8:	00001517          	auipc	a0,0x1
ffffffffc02017cc:	0e050513          	addi	a0,a0,224 # ffffffffc02028a8 <etext+0xb5e>
ffffffffc02017d0:	97dfe0ef          	jal	ffffffffc020014c <cprintf>
}
ffffffffc02017d4:	f4040113          	addi	sp,s0,-192
ffffffffc02017d8:	70ea                	ld	ra,184(sp)
ffffffffc02017da:	744a                	ld	s0,176(sp)
ffffffffc02017dc:	74aa                	ld	s1,168(sp)
ffffffffc02017de:	790a                	ld	s2,160(sp)
ffffffffc02017e0:	69ea                	ld	s3,152(sp)
ffffffffc02017e2:	6a4a                	ld	s4,144(sp)
ffffffffc02017e4:	6aaa                	ld	s5,136(sp)
ffffffffc02017e6:	6b0a                	ld	s6,128(sp)
ffffffffc02017e8:	7be6                	ld	s7,120(sp)
ffffffffc02017ea:	7c46                	ld	s8,112(sp)
ffffffffc02017ec:	7ca6                	ld	s9,104(sp)
ffffffffc02017ee:	7d06                	ld	s10,96(sp)
ffffffffc02017f0:	6de6                	ld	s11,88(sp)
ffffffffc02017f2:	6129                	addi	sp,sp,192
ffffffffc02017f4:	8082                	ret
            assert(objs[s][i] != NULL);
ffffffffc02017f6:	00001697          	auipc	a3,0x1
ffffffffc02017fa:	dd268693          	addi	a3,a3,-558 # ffffffffc02025c8 <etext+0x87e>
ffffffffc02017fe:	00001617          	auipc	a2,0x1
ffffffffc0201802:	88260613          	addi	a2,a2,-1918 # ffffffffc0202080 <etext+0x336>
ffffffffc0201806:	0df00593          	li	a1,223
ffffffffc020180a:	00001517          	auipc	a0,0x1
ffffffffc020180e:	d4e50513          	addi	a0,a0,-690 # ffffffffc0202558 <etext+0x80e>
ffffffffc0201812:	9bbfe0ef          	jal	ffffffffc02001cc <__panic>
    return (idx >= CACHE_NUM) ? -1 : idx;
ffffffffc0201816:	5a7d                	li	s4,-1
ffffffffc0201818:	b3f9                	j	ffffffffc02015e6 <slub_test+0x142>
            assert(sl->inuse > 0 && sl->inuse < sl->total);
ffffffffc020181a:	00001697          	auipc	a3,0x1
ffffffffc020181e:	e0e68693          	addi	a3,a3,-498 # ffffffffc0202628 <etext+0x8de>
ffffffffc0201822:	00001617          	auipc	a2,0x1
ffffffffc0201826:	85e60613          	addi	a2,a2,-1954 # ffffffffc0202080 <etext+0x336>
ffffffffc020182a:	0f300593          	li	a1,243
ffffffffc020182e:	00001517          	auipc	a0,0x1
ffffffffc0201832:	d2a50513          	addi	a0,a0,-726 # ffffffffc0202558 <etext+0x80e>
ffffffffc0201836:	997fe0ef          	jal	ffffffffc02001cc <__panic>
            assert(ptr != NULL);
ffffffffc020183a:	00001697          	auipc	a3,0x1
ffffffffc020183e:	e8e68693          	addi	a3,a3,-370 # ffffffffc02026c8 <etext+0x97e>
ffffffffc0201842:	00001617          	auipc	a2,0x1
ffffffffc0201846:	83e60613          	addi	a2,a2,-1986 # ffffffffc0202080 <etext+0x336>
ffffffffc020184a:	10000593          	li	a1,256
ffffffffc020184e:	00001517          	auipc	a0,0x1
ffffffffc0201852:	d0a50513          	addi	a0,a0,-758 # ffffffffc0202558 <etext+0x80e>
ffffffffc0201856:	977fe0ef          	jal	ffffffffc02001cc <__panic>
    return (idx >= CACHE_NUM) ? -1 : idx;
ffffffffc020185a:	57fd                	li	a5,-1
ffffffffc020185c:	bf0d                	j	ffffffffc020178e <slub_test+0x2ea>
ffffffffc020185e:	59fd                	li	s3,-1
ffffffffc0201860:	bda9                	j	ffffffffc02016ba <slub_test+0x216>
            assert(sl->inuse > 0);
ffffffffc0201862:	00001697          	auipc	a3,0x1
ffffffffc0201866:	ee668693          	addi	a3,a3,-282 # ffffffffc0202748 <etext+0x9fe>
ffffffffc020186a:	00001617          	auipc	a2,0x1
ffffffffc020186e:	81660613          	addi	a2,a2,-2026 # ffffffffc0202080 <etext+0x336>
ffffffffc0201872:	11900593          	li	a1,281
ffffffffc0201876:	00001517          	auipc	a0,0x1
ffffffffc020187a:	ce250513          	addi	a0,a0,-798 # ffffffffc0202558 <etext+0x80e>
ffffffffc020187e:	94ffe0ef          	jal	ffffffffc02001cc <__panic>
            assert(sl->inuse > 0 || sl->total == 0);
ffffffffc0201882:	00001697          	auipc	a3,0x1
ffffffffc0201886:	ea668693          	addi	a3,a3,-346 # ffffffffc0202728 <etext+0x9de>
ffffffffc020188a:	00000617          	auipc	a2,0x0
ffffffffc020188e:	7f660613          	addi	a2,a2,2038 # ffffffffc0202080 <etext+0x336>
ffffffffc0201892:	11400593          	li	a1,276
ffffffffc0201896:	00001517          	auipc	a0,0x1
ffffffffc020189a:	cc250513          	addi	a0,a0,-830 # ffffffffc0202558 <etext+0x80e>
ffffffffc020189e:	92ffe0ef          	jal	ffffffffc02001cc <__panic>
    assert(bigobj == NULL);
ffffffffc02018a2:	00001697          	auipc	a3,0x1
ffffffffc02018a6:	f2e68693          	addi	a3,a3,-210 # ffffffffc02027d0 <etext+0xa86>
ffffffffc02018aa:	00000617          	auipc	a2,0x0
ffffffffc02018ae:	7d660613          	addi	a2,a2,2006 # ffffffffc0202080 <etext+0x336>
ffffffffc02018b2:	12300593          	li	a1,291
ffffffffc02018b6:	00001517          	auipc	a0,0x1
ffffffffc02018ba:	ca250513          	addi	a0,a0,-862 # ffffffffc0202558 <etext+0x80e>
ffffffffc02018be:	90ffe0ef          	jal	ffffffffc02001cc <__panic>

ffffffffc02018c2 <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02018c2:	7179                	addi	sp,sp,-48
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02018c4:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02018c8:	f022                	sd	s0,32(sp)
ffffffffc02018ca:	ec26                	sd	s1,24(sp)
ffffffffc02018cc:	e84a                	sd	s2,16(sp)
ffffffffc02018ce:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02018d0:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02018d4:	f406                	sd	ra,40(sp)
    unsigned mod = do_div(result, base);
ffffffffc02018d6:	03067a33          	remu	s4,a2,a6
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02018da:	fff7041b          	addiw	s0,a4,-1
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02018de:	84aa                	mv	s1,a0
ffffffffc02018e0:	892e                	mv	s2,a1
    if (num >= base) {
ffffffffc02018e2:	03067d63          	bgeu	a2,a6,ffffffffc020191c <printnum+0x5a>
ffffffffc02018e6:	e44e                	sd	s3,8(sp)
ffffffffc02018e8:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02018ea:	4785                	li	a5,1
ffffffffc02018ec:	00e7d763          	bge	a5,a4,ffffffffc02018fa <printnum+0x38>
            putch(padc, putdat);
ffffffffc02018f0:	85ca                	mv	a1,s2
ffffffffc02018f2:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc02018f4:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02018f6:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02018f8:	fc65                	bnez	s0,ffffffffc02018f0 <printnum+0x2e>
ffffffffc02018fa:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02018fc:	00001797          	auipc	a5,0x1
ffffffffc0201900:	fdc78793          	addi	a5,a5,-36 # ffffffffc02028d8 <etext+0xb8e>
ffffffffc0201904:	97d2                	add	a5,a5,s4
}
ffffffffc0201906:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201908:	0007c503          	lbu	a0,0(a5)
}
ffffffffc020190c:	70a2                	ld	ra,40(sp)
ffffffffc020190e:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201910:	85ca                	mv	a1,s2
ffffffffc0201912:	87a6                	mv	a5,s1
}
ffffffffc0201914:	6942                	ld	s2,16(sp)
ffffffffc0201916:	64e2                	ld	s1,24(sp)
ffffffffc0201918:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020191a:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc020191c:	03065633          	divu	a2,a2,a6
ffffffffc0201920:	8722                	mv	a4,s0
ffffffffc0201922:	fa1ff0ef          	jal	ffffffffc02018c2 <printnum>
ffffffffc0201926:	bfd9                	j	ffffffffc02018fc <printnum+0x3a>

ffffffffc0201928 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201928:	7119                	addi	sp,sp,-128
ffffffffc020192a:	f4a6                	sd	s1,104(sp)
ffffffffc020192c:	f0ca                	sd	s2,96(sp)
ffffffffc020192e:	ecce                	sd	s3,88(sp)
ffffffffc0201930:	e8d2                	sd	s4,80(sp)
ffffffffc0201932:	e4d6                	sd	s5,72(sp)
ffffffffc0201934:	e0da                	sd	s6,64(sp)
ffffffffc0201936:	f862                	sd	s8,48(sp)
ffffffffc0201938:	fc86                	sd	ra,120(sp)
ffffffffc020193a:	f8a2                	sd	s0,112(sp)
ffffffffc020193c:	fc5e                	sd	s7,56(sp)
ffffffffc020193e:	f466                	sd	s9,40(sp)
ffffffffc0201940:	f06a                	sd	s10,32(sp)
ffffffffc0201942:	ec6e                	sd	s11,24(sp)
ffffffffc0201944:	84aa                	mv	s1,a0
ffffffffc0201946:	8c32                	mv	s8,a2
ffffffffc0201948:	8a36                	mv	s4,a3
ffffffffc020194a:	892e                	mv	s2,a1
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020194c:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201950:	05500b13          	li	s6,85
ffffffffc0201954:	00001a97          	auipc	s5,0x1
ffffffffc0201958:	0dca8a93          	addi	s5,s5,220 # ffffffffc0202a30 <buddy_pmm_manager+0x80>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020195c:	000c4503          	lbu	a0,0(s8)
ffffffffc0201960:	001c0413          	addi	s0,s8,1
ffffffffc0201964:	01350a63          	beq	a0,s3,ffffffffc0201978 <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc0201968:	cd0d                	beqz	a0,ffffffffc02019a2 <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc020196a:	85ca                	mv	a1,s2
ffffffffc020196c:	9482                	jalr	s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020196e:	00044503          	lbu	a0,0(s0)
ffffffffc0201972:	0405                	addi	s0,s0,1
ffffffffc0201974:	ff351ae3          	bne	a0,s3,ffffffffc0201968 <vprintfmt+0x40>
        width = precision = -1;
ffffffffc0201978:	5cfd                	li	s9,-1
ffffffffc020197a:	8d66                	mv	s10,s9
        char padc = ' ';
ffffffffc020197c:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc0201980:	4b81                	li	s7,0
ffffffffc0201982:	4781                	li	a5,0
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201984:	00044683          	lbu	a3,0(s0)
ffffffffc0201988:	00140c13          	addi	s8,s0,1
ffffffffc020198c:	fdd6859b          	addiw	a1,a3,-35
ffffffffc0201990:	0ff5f593          	zext.b	a1,a1
ffffffffc0201994:	02bb6663          	bltu	s6,a1,ffffffffc02019c0 <vprintfmt+0x98>
ffffffffc0201998:	058a                	slli	a1,a1,0x2
ffffffffc020199a:	95d6                	add	a1,a1,s5
ffffffffc020199c:	4198                	lw	a4,0(a1)
ffffffffc020199e:	9756                	add	a4,a4,s5
ffffffffc02019a0:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02019a2:	70e6                	ld	ra,120(sp)
ffffffffc02019a4:	7446                	ld	s0,112(sp)
ffffffffc02019a6:	74a6                	ld	s1,104(sp)
ffffffffc02019a8:	7906                	ld	s2,96(sp)
ffffffffc02019aa:	69e6                	ld	s3,88(sp)
ffffffffc02019ac:	6a46                	ld	s4,80(sp)
ffffffffc02019ae:	6aa6                	ld	s5,72(sp)
ffffffffc02019b0:	6b06                	ld	s6,64(sp)
ffffffffc02019b2:	7be2                	ld	s7,56(sp)
ffffffffc02019b4:	7c42                	ld	s8,48(sp)
ffffffffc02019b6:	7ca2                	ld	s9,40(sp)
ffffffffc02019b8:	7d02                	ld	s10,32(sp)
ffffffffc02019ba:	6de2                	ld	s11,24(sp)
ffffffffc02019bc:	6109                	addi	sp,sp,128
ffffffffc02019be:	8082                	ret
            putch('%', putdat);
ffffffffc02019c0:	85ca                	mv	a1,s2
ffffffffc02019c2:	02500513          	li	a0,37
ffffffffc02019c6:	9482                	jalr	s1
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc02019c8:	fff44783          	lbu	a5,-1(s0)
ffffffffc02019cc:	02500713          	li	a4,37
ffffffffc02019d0:	8c22                	mv	s8,s0
ffffffffc02019d2:	f8e785e3          	beq	a5,a4,ffffffffc020195c <vprintfmt+0x34>
ffffffffc02019d6:	ffec4783          	lbu	a5,-2(s8)
ffffffffc02019da:	1c7d                	addi	s8,s8,-1
ffffffffc02019dc:	fee79de3          	bne	a5,a4,ffffffffc02019d6 <vprintfmt+0xae>
ffffffffc02019e0:	bfb5                	j	ffffffffc020195c <vprintfmt+0x34>
                ch = *fmt;
ffffffffc02019e2:	00144603          	lbu	a2,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc02019e6:	4525                	li	a0,9
                precision = precision * 10 + ch - '0';
ffffffffc02019e8:	fd068c9b          	addiw	s9,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc02019ec:	fd06071b          	addiw	a4,a2,-48
ffffffffc02019f0:	24e56a63          	bltu	a0,a4,ffffffffc0201c44 <vprintfmt+0x31c>
                ch = *fmt;
ffffffffc02019f4:	2601                	sext.w	a2,a2
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02019f6:	8462                	mv	s0,s8
                precision = precision * 10 + ch - '0';
ffffffffc02019f8:	002c971b          	slliw	a4,s9,0x2
                ch = *fmt;
ffffffffc02019fc:	00144683          	lbu	a3,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201a00:	0197073b          	addw	a4,a4,s9
ffffffffc0201a04:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201a08:	9f31                	addw	a4,a4,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201a0a:	fd06859b          	addiw	a1,a3,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201a0e:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201a10:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc0201a14:	0006861b          	sext.w	a2,a3
                if (ch < '0' || ch > '9') {
ffffffffc0201a18:	feb570e3          	bgeu	a0,a1,ffffffffc02019f8 <vprintfmt+0xd0>
            if (width < 0)
ffffffffc0201a1c:	f60d54e3          	bgez	s10,ffffffffc0201984 <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc0201a20:	8d66                	mv	s10,s9
ffffffffc0201a22:	5cfd                	li	s9,-1
ffffffffc0201a24:	b785                	j	ffffffffc0201984 <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a26:	8db6                	mv	s11,a3
ffffffffc0201a28:	8462                	mv	s0,s8
ffffffffc0201a2a:	bfa9                	j	ffffffffc0201984 <vprintfmt+0x5c>
ffffffffc0201a2c:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc0201a2e:	4b85                	li	s7,1
            goto reswitch;
ffffffffc0201a30:	bf91                	j	ffffffffc0201984 <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc0201a32:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201a34:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201a38:	00f74463          	blt	a4,a5,ffffffffc0201a40 <vprintfmt+0x118>
    else if (lflag) {
ffffffffc0201a3c:	1a078763          	beqz	a5,ffffffffc0201bea <vprintfmt+0x2c2>
        return va_arg(*ap, unsigned long);
ffffffffc0201a40:	000a3603          	ld	a2,0(s4)
ffffffffc0201a44:	46c1                	li	a3,16
ffffffffc0201a46:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201a48:	000d879b          	sext.w	a5,s11
ffffffffc0201a4c:	876a                	mv	a4,s10
ffffffffc0201a4e:	85ca                	mv	a1,s2
ffffffffc0201a50:	8526                	mv	a0,s1
ffffffffc0201a52:	e71ff0ef          	jal	ffffffffc02018c2 <printnum>
            break;
ffffffffc0201a56:	b719                	j	ffffffffc020195c <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc0201a58:	000a2503          	lw	a0,0(s4)
ffffffffc0201a5c:	85ca                	mv	a1,s2
ffffffffc0201a5e:	0a21                	addi	s4,s4,8
ffffffffc0201a60:	9482                	jalr	s1
            break;
ffffffffc0201a62:	bded                	j	ffffffffc020195c <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0201a64:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201a66:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201a6a:	00f74463          	blt	a4,a5,ffffffffc0201a72 <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc0201a6e:	16078963          	beqz	a5,ffffffffc0201be0 <vprintfmt+0x2b8>
        return va_arg(*ap, unsigned long);
ffffffffc0201a72:	000a3603          	ld	a2,0(s4)
ffffffffc0201a76:	46a9                	li	a3,10
ffffffffc0201a78:	8a2e                	mv	s4,a1
ffffffffc0201a7a:	b7f9                	j	ffffffffc0201a48 <vprintfmt+0x120>
            putch('0', putdat);
ffffffffc0201a7c:	85ca                	mv	a1,s2
ffffffffc0201a7e:	03000513          	li	a0,48
ffffffffc0201a82:	9482                	jalr	s1
            putch('x', putdat);
ffffffffc0201a84:	85ca                	mv	a1,s2
ffffffffc0201a86:	07800513          	li	a0,120
ffffffffc0201a8a:	9482                	jalr	s1
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201a8c:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc0201a90:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201a92:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201a94:	bf55                	j	ffffffffc0201a48 <vprintfmt+0x120>
            putch(ch, putdat);
ffffffffc0201a96:	85ca                	mv	a1,s2
ffffffffc0201a98:	02500513          	li	a0,37
ffffffffc0201a9c:	9482                	jalr	s1
            break;
ffffffffc0201a9e:	bd7d                	j	ffffffffc020195c <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc0201aa0:	000a2c83          	lw	s9,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201aa4:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc0201aa6:	0a21                	addi	s4,s4,8
            goto process_precision;
ffffffffc0201aa8:	bf95                	j	ffffffffc0201a1c <vprintfmt+0xf4>
    if (lflag >= 2) {
ffffffffc0201aaa:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201aac:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201ab0:	00f74463          	blt	a4,a5,ffffffffc0201ab8 <vprintfmt+0x190>
    else if (lflag) {
ffffffffc0201ab4:	12078163          	beqz	a5,ffffffffc0201bd6 <vprintfmt+0x2ae>
        return va_arg(*ap, unsigned long);
ffffffffc0201ab8:	000a3603          	ld	a2,0(s4)
ffffffffc0201abc:	46a1                	li	a3,8
ffffffffc0201abe:	8a2e                	mv	s4,a1
ffffffffc0201ac0:	b761                	j	ffffffffc0201a48 <vprintfmt+0x120>
            if (width < 0)
ffffffffc0201ac2:	876a                	mv	a4,s10
ffffffffc0201ac4:	000d5363          	bgez	s10,ffffffffc0201aca <vprintfmt+0x1a2>
ffffffffc0201ac8:	4701                	li	a4,0
ffffffffc0201aca:	00070d1b          	sext.w	s10,a4
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201ace:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0201ad0:	bd55                	j	ffffffffc0201984 <vprintfmt+0x5c>
            if (width > 0 && padc != '-') {
ffffffffc0201ad2:	000d841b          	sext.w	s0,s11
ffffffffc0201ad6:	fd340793          	addi	a5,s0,-45
ffffffffc0201ada:	00f037b3          	snez	a5,a5
ffffffffc0201ade:	01a02733          	sgtz	a4,s10
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201ae2:	000a3d83          	ld	s11,0(s4)
            if (width > 0 && padc != '-') {
ffffffffc0201ae6:	8f7d                	and	a4,a4,a5
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201ae8:	008a0793          	addi	a5,s4,8
ffffffffc0201aec:	e43e                	sd	a5,8(sp)
ffffffffc0201aee:	100d8c63          	beqz	s11,ffffffffc0201c06 <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
ffffffffc0201af2:	12071363          	bnez	a4,ffffffffc0201c18 <vprintfmt+0x2f0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201af6:	000dc783          	lbu	a5,0(s11)
ffffffffc0201afa:	0007851b          	sext.w	a0,a5
ffffffffc0201afe:	c78d                	beqz	a5,ffffffffc0201b28 <vprintfmt+0x200>
ffffffffc0201b00:	0d85                	addi	s11,s11,1
ffffffffc0201b02:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201b04:	05e00a13          	li	s4,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201b08:	000cc563          	bltz	s9,ffffffffc0201b12 <vprintfmt+0x1ea>
ffffffffc0201b0c:	3cfd                	addiw	s9,s9,-1
ffffffffc0201b0e:	008c8d63          	beq	s9,s0,ffffffffc0201b28 <vprintfmt+0x200>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201b12:	020b9663          	bnez	s7,ffffffffc0201b3e <vprintfmt+0x216>
                    putch(ch, putdat);
ffffffffc0201b16:	85ca                	mv	a1,s2
ffffffffc0201b18:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201b1a:	000dc783          	lbu	a5,0(s11)
ffffffffc0201b1e:	0d85                	addi	s11,s11,1
ffffffffc0201b20:	3d7d                	addiw	s10,s10,-1
ffffffffc0201b22:	0007851b          	sext.w	a0,a5
ffffffffc0201b26:	f3ed                	bnez	a5,ffffffffc0201b08 <vprintfmt+0x1e0>
            for (; width > 0; width --) {
ffffffffc0201b28:	01a05963          	blez	s10,ffffffffc0201b3a <vprintfmt+0x212>
                putch(' ', putdat);
ffffffffc0201b2c:	85ca                	mv	a1,s2
ffffffffc0201b2e:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc0201b32:	3d7d                	addiw	s10,s10,-1
                putch(' ', putdat);
ffffffffc0201b34:	9482                	jalr	s1
            for (; width > 0; width --) {
ffffffffc0201b36:	fe0d1be3          	bnez	s10,ffffffffc0201b2c <vprintfmt+0x204>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201b3a:	6a22                	ld	s4,8(sp)
ffffffffc0201b3c:	b505                	j	ffffffffc020195c <vprintfmt+0x34>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201b3e:	3781                	addiw	a5,a5,-32
ffffffffc0201b40:	fcfa7be3          	bgeu	s4,a5,ffffffffc0201b16 <vprintfmt+0x1ee>
                    putch('?', putdat);
ffffffffc0201b44:	03f00513          	li	a0,63
ffffffffc0201b48:	85ca                	mv	a1,s2
ffffffffc0201b4a:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201b4c:	000dc783          	lbu	a5,0(s11)
ffffffffc0201b50:	0d85                	addi	s11,s11,1
ffffffffc0201b52:	3d7d                	addiw	s10,s10,-1
ffffffffc0201b54:	0007851b          	sext.w	a0,a5
ffffffffc0201b58:	dbe1                	beqz	a5,ffffffffc0201b28 <vprintfmt+0x200>
ffffffffc0201b5a:	fa0cd9e3          	bgez	s9,ffffffffc0201b0c <vprintfmt+0x1e4>
ffffffffc0201b5e:	b7c5                	j	ffffffffc0201b3e <vprintfmt+0x216>
            if (err < 0) {
ffffffffc0201b60:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201b64:	4619                	li	a2,6
            err = va_arg(ap, int);
ffffffffc0201b66:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201b68:	41f7d71b          	sraiw	a4,a5,0x1f
ffffffffc0201b6c:	8fb9                	xor	a5,a5,a4
ffffffffc0201b6e:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201b72:	02d64563          	blt	a2,a3,ffffffffc0201b9c <vprintfmt+0x274>
ffffffffc0201b76:	00001797          	auipc	a5,0x1
ffffffffc0201b7a:	01278793          	addi	a5,a5,18 # ffffffffc0202b88 <error_string>
ffffffffc0201b7e:	00369713          	slli	a4,a3,0x3
ffffffffc0201b82:	97ba                	add	a5,a5,a4
ffffffffc0201b84:	639c                	ld	a5,0(a5)
ffffffffc0201b86:	cb99                	beqz	a5,ffffffffc0201b9c <vprintfmt+0x274>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201b88:	86be                	mv	a3,a5
ffffffffc0201b8a:	00001617          	auipc	a2,0x1
ffffffffc0201b8e:	d7e60613          	addi	a2,a2,-642 # ffffffffc0202908 <etext+0xbbe>
ffffffffc0201b92:	85ca                	mv	a1,s2
ffffffffc0201b94:	8526                	mv	a0,s1
ffffffffc0201b96:	0d8000ef          	jal	ffffffffc0201c6e <printfmt>
ffffffffc0201b9a:	b3c9                	j	ffffffffc020195c <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201b9c:	00001617          	auipc	a2,0x1
ffffffffc0201ba0:	d5c60613          	addi	a2,a2,-676 # ffffffffc02028f8 <etext+0xbae>
ffffffffc0201ba4:	85ca                	mv	a1,s2
ffffffffc0201ba6:	8526                	mv	a0,s1
ffffffffc0201ba8:	0c6000ef          	jal	ffffffffc0201c6e <printfmt>
ffffffffc0201bac:	bb45                	j	ffffffffc020195c <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0201bae:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201bb0:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
ffffffffc0201bb4:	00f74363          	blt	a4,a5,ffffffffc0201bba <vprintfmt+0x292>
    else if (lflag) {
ffffffffc0201bb8:	cf81                	beqz	a5,ffffffffc0201bd0 <vprintfmt+0x2a8>
        return va_arg(*ap, long);
ffffffffc0201bba:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201bbe:	02044b63          	bltz	s0,ffffffffc0201bf4 <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
ffffffffc0201bc2:	8622                	mv	a2,s0
ffffffffc0201bc4:	8a5e                	mv	s4,s7
ffffffffc0201bc6:	46a9                	li	a3,10
ffffffffc0201bc8:	b541                	j	ffffffffc0201a48 <vprintfmt+0x120>
            lflag ++;
ffffffffc0201bca:	2785                	addiw	a5,a5,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201bcc:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0201bce:	bb5d                	j	ffffffffc0201984 <vprintfmt+0x5c>
        return va_arg(*ap, int);
ffffffffc0201bd0:	000a2403          	lw	s0,0(s4)
ffffffffc0201bd4:	b7ed                	j	ffffffffc0201bbe <vprintfmt+0x296>
        return va_arg(*ap, unsigned int);
ffffffffc0201bd6:	000a6603          	lwu	a2,0(s4)
ffffffffc0201bda:	46a1                	li	a3,8
ffffffffc0201bdc:	8a2e                	mv	s4,a1
ffffffffc0201bde:	b5ad                	j	ffffffffc0201a48 <vprintfmt+0x120>
ffffffffc0201be0:	000a6603          	lwu	a2,0(s4)
ffffffffc0201be4:	46a9                	li	a3,10
ffffffffc0201be6:	8a2e                	mv	s4,a1
ffffffffc0201be8:	b585                	j	ffffffffc0201a48 <vprintfmt+0x120>
ffffffffc0201bea:	000a6603          	lwu	a2,0(s4)
ffffffffc0201bee:	46c1                	li	a3,16
ffffffffc0201bf0:	8a2e                	mv	s4,a1
ffffffffc0201bf2:	bd99                	j	ffffffffc0201a48 <vprintfmt+0x120>
                putch('-', putdat);
ffffffffc0201bf4:	85ca                	mv	a1,s2
ffffffffc0201bf6:	02d00513          	li	a0,45
ffffffffc0201bfa:	9482                	jalr	s1
                num = -(long long)num;
ffffffffc0201bfc:	40800633          	neg	a2,s0
ffffffffc0201c00:	8a5e                	mv	s4,s7
ffffffffc0201c02:	46a9                	li	a3,10
ffffffffc0201c04:	b591                	j	ffffffffc0201a48 <vprintfmt+0x120>
            if (width > 0 && padc != '-') {
ffffffffc0201c06:	e329                	bnez	a4,ffffffffc0201c48 <vprintfmt+0x320>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c08:	02800793          	li	a5,40
ffffffffc0201c0c:	853e                	mv	a0,a5
ffffffffc0201c0e:	00001d97          	auipc	s11,0x1
ffffffffc0201c12:	ce3d8d93          	addi	s11,s11,-797 # ffffffffc02028f1 <etext+0xba7>
ffffffffc0201c16:	b5f5                	j	ffffffffc0201b02 <vprintfmt+0x1da>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201c18:	85e6                	mv	a1,s9
ffffffffc0201c1a:	856e                	mv	a0,s11
ffffffffc0201c1c:	0a4000ef          	jal	ffffffffc0201cc0 <strnlen>
ffffffffc0201c20:	40ad0d3b          	subw	s10,s10,a0
ffffffffc0201c24:	01a05863          	blez	s10,ffffffffc0201c34 <vprintfmt+0x30c>
                    putch(padc, putdat);
ffffffffc0201c28:	85ca                	mv	a1,s2
ffffffffc0201c2a:	8522                	mv	a0,s0
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201c2c:	3d7d                	addiw	s10,s10,-1
                    putch(padc, putdat);
ffffffffc0201c2e:	9482                	jalr	s1
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201c30:	fe0d1ce3          	bnez	s10,ffffffffc0201c28 <vprintfmt+0x300>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c34:	000dc783          	lbu	a5,0(s11)
ffffffffc0201c38:	0007851b          	sext.w	a0,a5
ffffffffc0201c3c:	ec0792e3          	bnez	a5,ffffffffc0201b00 <vprintfmt+0x1d8>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201c40:	6a22                	ld	s4,8(sp)
ffffffffc0201c42:	bb29                	j	ffffffffc020195c <vprintfmt+0x34>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c44:	8462                	mv	s0,s8
ffffffffc0201c46:	bbd9                	j	ffffffffc0201a1c <vprintfmt+0xf4>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201c48:	85e6                	mv	a1,s9
ffffffffc0201c4a:	00001517          	auipc	a0,0x1
ffffffffc0201c4e:	ca650513          	addi	a0,a0,-858 # ffffffffc02028f0 <etext+0xba6>
ffffffffc0201c52:	06e000ef          	jal	ffffffffc0201cc0 <strnlen>
ffffffffc0201c56:	40ad0d3b          	subw	s10,s10,a0
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c5a:	02800793          	li	a5,40
                p = "(null)";
ffffffffc0201c5e:	00001d97          	auipc	s11,0x1
ffffffffc0201c62:	c92d8d93          	addi	s11,s11,-878 # ffffffffc02028f0 <etext+0xba6>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c66:	853e                	mv	a0,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201c68:	fda040e3          	bgtz	s10,ffffffffc0201c28 <vprintfmt+0x300>
ffffffffc0201c6c:	bd51                	j	ffffffffc0201b00 <vprintfmt+0x1d8>

ffffffffc0201c6e <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201c6e:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201c70:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201c74:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201c76:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201c78:	ec06                	sd	ra,24(sp)
ffffffffc0201c7a:	f83a                	sd	a4,48(sp)
ffffffffc0201c7c:	fc3e                	sd	a5,56(sp)
ffffffffc0201c7e:	e0c2                	sd	a6,64(sp)
ffffffffc0201c80:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201c82:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201c84:	ca5ff0ef          	jal	ffffffffc0201928 <vprintfmt>
}
ffffffffc0201c88:	60e2                	ld	ra,24(sp)
ffffffffc0201c8a:	6161                	addi	sp,sp,80
ffffffffc0201c8c:	8082                	ret

ffffffffc0201c8e <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201c8e:	00004717          	auipc	a4,0x4
ffffffffc0201c92:	38273703          	ld	a4,898(a4) # ffffffffc0206010 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201c96:	4781                	li	a5,0
ffffffffc0201c98:	88ba                	mv	a7,a4
ffffffffc0201c9a:	852a                	mv	a0,a0
ffffffffc0201c9c:	85be                	mv	a1,a5
ffffffffc0201c9e:	863e                	mv	a2,a5
ffffffffc0201ca0:	00000073          	ecall
ffffffffc0201ca4:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201ca6:	8082                	ret

ffffffffc0201ca8 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201ca8:	00054783          	lbu	a5,0(a0)
ffffffffc0201cac:	cb81                	beqz	a5,ffffffffc0201cbc <strlen+0x14>
    size_t cnt = 0;
ffffffffc0201cae:	4781                	li	a5,0
        cnt ++;
ffffffffc0201cb0:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc0201cb2:	00f50733          	add	a4,a0,a5
ffffffffc0201cb6:	00074703          	lbu	a4,0(a4)
ffffffffc0201cba:	fb7d                	bnez	a4,ffffffffc0201cb0 <strlen+0x8>
    }
    return cnt;
}
ffffffffc0201cbc:	853e                	mv	a0,a5
ffffffffc0201cbe:	8082                	ret

ffffffffc0201cc0 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201cc0:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201cc2:	e589                	bnez	a1,ffffffffc0201ccc <strnlen+0xc>
ffffffffc0201cc4:	a811                	j	ffffffffc0201cd8 <strnlen+0x18>
        cnt ++;
ffffffffc0201cc6:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201cc8:	00f58863          	beq	a1,a5,ffffffffc0201cd8 <strnlen+0x18>
ffffffffc0201ccc:	00f50733          	add	a4,a0,a5
ffffffffc0201cd0:	00074703          	lbu	a4,0(a4)
ffffffffc0201cd4:	fb6d                	bnez	a4,ffffffffc0201cc6 <strnlen+0x6>
ffffffffc0201cd6:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201cd8:	852e                	mv	a0,a1
ffffffffc0201cda:	8082                	ret

ffffffffc0201cdc <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201cdc:	00054783          	lbu	a5,0(a0)
ffffffffc0201ce0:	e791                	bnez	a5,ffffffffc0201cec <strcmp+0x10>
ffffffffc0201ce2:	a01d                	j	ffffffffc0201d08 <strcmp+0x2c>
ffffffffc0201ce4:	00054783          	lbu	a5,0(a0)
ffffffffc0201ce8:	cb99                	beqz	a5,ffffffffc0201cfe <strcmp+0x22>
ffffffffc0201cea:	0585                	addi	a1,a1,1
ffffffffc0201cec:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc0201cf0:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201cf2:	fef709e3          	beq	a4,a5,ffffffffc0201ce4 <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201cf6:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201cfa:	9d19                	subw	a0,a0,a4
ffffffffc0201cfc:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201cfe:	0015c703          	lbu	a4,1(a1)
ffffffffc0201d02:	4501                	li	a0,0
}
ffffffffc0201d04:	9d19                	subw	a0,a0,a4
ffffffffc0201d06:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201d08:	0005c703          	lbu	a4,0(a1)
ffffffffc0201d0c:	4501                	li	a0,0
ffffffffc0201d0e:	b7f5                	j	ffffffffc0201cfa <strcmp+0x1e>

ffffffffc0201d10 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201d10:	ce01                	beqz	a2,ffffffffc0201d28 <strncmp+0x18>
ffffffffc0201d12:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0201d16:	167d                	addi	a2,a2,-1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201d18:	cb91                	beqz	a5,ffffffffc0201d2c <strncmp+0x1c>
ffffffffc0201d1a:	0005c703          	lbu	a4,0(a1)
ffffffffc0201d1e:	00f71763          	bne	a4,a5,ffffffffc0201d2c <strncmp+0x1c>
        n --, s1 ++, s2 ++;
ffffffffc0201d22:	0505                	addi	a0,a0,1
ffffffffc0201d24:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201d26:	f675                	bnez	a2,ffffffffc0201d12 <strncmp+0x2>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201d28:	4501                	li	a0,0
ffffffffc0201d2a:	8082                	ret
ffffffffc0201d2c:	00054503          	lbu	a0,0(a0)
ffffffffc0201d30:	0005c783          	lbu	a5,0(a1)
ffffffffc0201d34:	9d1d                	subw	a0,a0,a5
}
ffffffffc0201d36:	8082                	ret

ffffffffc0201d38 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201d38:	ca01                	beqz	a2,ffffffffc0201d48 <memset+0x10>
ffffffffc0201d3a:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201d3c:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201d3e:	0785                	addi	a5,a5,1
ffffffffc0201d40:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201d44:	fef61de3          	bne	a2,a5,ffffffffc0201d3e <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201d48:	8082                	ret
