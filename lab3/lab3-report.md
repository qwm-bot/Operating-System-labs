# LAB3-中断与中断处理流程
## 实验目的
- riscv 的中断相关知识
- 中断前后如何进行上下文环境的保存与恢复
- 处理最简单的断点中断和时钟中断
## 练习1:完善中断处理（需要编程）
> 请编程完善trap.c中的中断处理函数trap，在对时钟中断进行处理的部分填写kern/trap/trap.c函数中处理时钟中断的部分，使操作系统每遇到100次时钟中断后，调用print_ticks子程序，向屏幕上打印一行文字”100 ticks”，在打印完10行后调用sbi.h中的shut_down()函数关机。\
要求完成问题1提出的相关函数实现，提交改进后的源代码包（可以编译执行），并在实验报告中简要说明实现过程和定时器中断中断处理的流程。实现要求的部分代码后，运行整个系统，大约每1秒会输出一次”100 ticks”，输出10行。

- 中断处理主流程
1. 在 trapentry.S 的 __alltraps 中通过 SAVE_ALL 宏将所有寄存器保存到 trapframe
2.  调用 trap.c 中的 trap() 函数
3. trap() 调用 trap_dispatch()，根据中断类型分发给 interrupt_handler()
4. interrupt_handler() 识别出是 IRQ_S_TIMER 类型中断，执行时钟中断处理逻辑
5. 处理完毕后，通过 __trapret 恢复寄存器并返回原程序执行

- 具体实现
1. 完善处理时钟中断的部分。调用 clock_set_next_event() 设置下一次时钟中断，设置ticks 计数器自增。
2. 判断ticks是否达到100的倍数。如果是，调用 print_ticks() 打印信息，num 计数器增加，随后判断 num 是否达到10，如果是就调用 sbi_shutdown() 关机

- 运行结果
<img src="中断输出.png" width="60%">
  如图，运行整个系统，大约每1秒会输出一次”100 ticks”，输出10行。

## 扩展练习 Challenge1：描述与理解中断流程
>回答：描述ucore中处理中断异常的流程（从异常的产生开始），其中mov a0，sp的目的是什么？SAVE_ALL中寄存器保存在栈中的位置是什么确定的？对于任何中断，__alltraps 中都需要保存所有寄存器吗？请说明理由。
- ucore中处理中断异常的流程：

  1. 当发生中断/异常时，首先在`init.c`中调用`idt_init()`函数，修改`sstatus`,进入S模式；跳转到中断向量表`stvec`所指向的入口`__alltraps`;
  2. 进入到`trapentry.S`的`__alltraps`汇编入口后，首先执行`SAVE_ALL`宏，首先为`trapframe`腾出内存空间，然后保存所有的通用寄存器和关键CSR，构造出`trapframe`结构，存放到栈中；最后将构造好的`trapframe`地址`sp`传给`trap()`函数；
  3. 在`trap.c`函数中，首先根据`tf->cause`的小于零的情况，判断是中断还是异常；然后根据`tf->cause`的具体值判断具体属于中断/异常的哪种情况并做相应的处理；
  4. 执行完`trap()`函数之后，返回`trapentry.S`汇编层的`__trapret`，执行`RESTORE_ALL`宏，从内核栈恢复所有寄存器，恢复`sstatus`和`sepc`;执行`sret`指令，使用`sepc`恢复原PC值，返回到原特权级，继续执行被中断的程序。
- 在RISC-V的调用约定中，`a0`是第一个函数参数寄存器，这里的
    ```asm
    move a0, sp
    jal trap
    ```
    表示当前栈指针`sp`传给`trap`函数，即`trap(sp)`，把中断/异常的上下文传递给`trap()`,从而让中断/异常处理函数能访问被保存的寄存器上下文。在这里`sp`指向的是一个`trapframe`结构体。
    ```asm
    struct trapframe {
        struct pushregs gpr;
        uintptr_t status;
        uintptr_t epc;
        uintptr_t badvaddr;
        uintptr_t cause;
    };
    ```
    通过`SAVE_ALL`函数，`sp`指向的结构体中已经保存了发生中断/异常时，所有寄存器的状态。
- 在我们目前uCore的实现中，`SAVE_ALL`中寄存器的在栈中保存的位置是在`trapentry.S`中确定的。
    ```asm
    addi sp, sp, -36 * REGBYTES
    STORE x0,  0*REGBYTES(sp)
    STORE x1,  1*REGBYTES(sp)
    ...
    STORE x31, 31*REGBYTES(sp)

    STORE s1,  32*REGBYTES(sp)
    STORE s2,  33*REGBYTES(sp)
    STORE s3,  34*REGBYTES(sp)
    STORE s4,  35*REGBYTES(sp)
    ```
    可以看到，在`SAVE_ALL`的开始，首先开辟了`36*REGBYTES`大小的内存区域用来保存36个寄存器（包括特殊寄存器）；接着寄存器按照顺序，从栈顶开始，按照地址由低到高进行保存；所以，每个寄存器的保存位置是由**保存顺序+固定偏移规则**确定的，每个寄存器占`REGBYTES`个字节。
- 严格来说，`__alltraps`不一定必须保存所有寄存器，但在当前的uCore实现中，保存所有寄存器是最安全最简单的实现方式。
    - 保存全部寄存器的优点：
       - 中断可能发生在任何时刻，无论正在执行什么指令、使用哪些寄存器，中断随时可能触发。如果只保存部分寄存器，就可能破坏被中断的程序状态。
       - 保存所有寄存器可以方便统一处理逻辑。所有陷入中断/异常/系统调用都通过同一个入口` __alltraps`。这样可以用统一的`trapframe`结构，不需要区分不同来源。
       - 当系统 panic 或打印异常时，可以完整地打印寄存器内容。方便调试和异常恢复。
    - 在进入中断/异常时，保存所有的寄存器意味着所耗费的栈帧大，内存存取的开销大，导致每次中断的延迟也比较高，所以在高性能内核或者嵌入式系统中会进行优化，只保存必要的寄存器子集。

    如果操作系统与用户程序达成协议(如ABI)，在进行中断/异常处理的时候，操作系统只可能对一部分寄存器（如 Linux RISC-V中的Caller-saved和部分CSR）进行修改，而不会对剩余寄存器进行修改，那么在进行中断/异常处理前，仅保存寄存器自己即可。

    当然，从理论上讲，不同中断所要修改的寄存器不同且提前已知，我们可以先保存少量寄存器，然后用这些少量的寄存器判断中断的类型，从而有选择性的保存更多的寄存器，但这与我们目前代码的逻辑就不太相同了，实现起来也更为复杂。如果按照当前先保存寄存器后判断中断类型的逻辑来说，任何中断都必须保存全部的寄存器，因为提前根本无法判断哪些寄存器会被修改。
## 扩展练习 Challenge2：理解上下文切换机制
> 回答：在trapentry.S中汇编代码 csrw sscratch, sp；csrrw s0, sscratch, x0实现了什么操作，目的是什么？save all里面保存了stval scause这些csr，而在restore all里面却不还原它们？那这样store的意义何在呢？

### 问题分析

#### 1. `csrw sscratch, sp; csrrw s0, sscratch, x0` 的操作与目的

这两条指令并非连续执行，它们在 `SAVE_ALL` 宏中协同作用，其核心目的是在 `sp`（栈指针）寄存器被修改后，**正确地保存中断前的原始 `sp` 值**到 `trapframe` 中。

根据 `kern/trap/trapentry.S` 中 `SAVE_ALL` 宏的实现，实际的流程是：

1.  **`csrw sscratch, sp`**
    * **操作**：这是一条 CSR（Control and Status Register）写入指令。它将 `sp` 寄存器（x2）的**当前值**（即中断前的栈指针，例如用户栈指针 `usp`），写入（备份）到 `sscratch` 这个 CSR 寄存器中。
    * **目的**：**备份原始栈指针**。因为 `sp` 寄存器马上要被 `addi` 指令修改，所以必须先把它的原始值暂存到一个安全的地方。

2.  **`addi sp, sp, -36 * REGBYTES`**
    * **操作**：`addi`（立即数加法）指令。它将 `sp` 寄存器的值减去 `36 * REGBYTES`（在 64 位系统中为 `36 * 8 = 288` 字节）。
    * **目的**：**在当前栈上分配空间**。这 288 字节的空间就是用来存放 `trapframe` 结构体的（32 个通用寄存器 + 4 个 CSRs）。**注意：** 执行完这句，`sp` 寄存器的值**已经被改变了**，它现在指向新分配的 `trapframe` 的基地址。

3.  **`(... STORE x0, x1, x3-x31 ...)`**
    * **操作**：将 `x0`, `x1`, `x3` 到 `x31` 寄存器依次存入 `trapframe` 中。
    * **目的**：保存通用寄存器上下文。`x2`（即 `sp`）在此处被**故意跳过**了，因为当前的 `sp` 值是 `trapframe` 的基地址，而不是想保存的**原始 `sp`**。

4.  **`csrrw s0, sscratch, x0`**
    * **操作**：`csrrw`（CSR 读并写）指令。这是一个原子操作：
        1.  **读**：读取 `sscratch` 寄存器的值（即步骤 1 中备份的**原始 `sp`**），并将其存入 `s0` 寄存器。
        2.  **写**：将 `x0` 寄存器（值恒为 0）的值写入 `sscratch` 寄存器。
    * **目的**：**“取回”** 原始的 `sp` 值，并将其暂存在 `s0` 中。同时，`sscratch` 被清零（这是一个安全实践）。

5.  **`STORE s0, 2*REGBYTES(sp)`**
    * **操作**：`STORE` 指令。将 `s0` 寄存器（现在存着**原始 `sp`**）的值，存入 `sp + 16` 字节（`2 * 8`）偏移量的位置。
    * **目的**：**这才是真正“保存 `sp`”**。根据 `trap.h` 中 `struct pushregs` 的定义，`sp` (x2) 字段是第 3 个字段（0-indexed 偏移量为 2）。这行代码将原始的栈指针存入了 `trapframe` 中正确的位置 `trapframe->gpr.sp`。

**总结：**
这个指令序列的目的是**在 `sp` 寄存器被用于分配 `trapframe` 空间而改变后，仍能将中断前的原始 `sp` 值正确地保存到 `trapframe` 结构体中**。`sscratch` 在这里充当了一个临时的“备份盘”。

#### 2. `SAVE_ALL` 保存 `stval/scause` 但 `RESTORE_ALL` 不还原的原因

`SAVE_ALL` 宏确实保存了 `scause` 和 `sbadaddr`（即 `stval`），而 `RESTORE_ALL` 宏则忽略了它们。

**`store`（保存）的意义：作为 C 语言处理函数 `trap()` 的“输入参数”。**

1.  **向 C 函数传递信息**：
    `SAVE_ALL` 的唯一目的就是构建一个 C 语言能理解的 `struct trapframe`。
    紧接着，汇编代码执行 `move a0, sp` 和 `jal trap`。
    * `move a0, sp`：将 `trapframe` 的地址作为第一个参数（`a0`）。
    * `jal trap`：调用 C 函数 `trap(struct trapframe *tf)`。
    * 在 `trap.c` 中，C 代码需要通过 `tf->cause` (`scause`) 才能知道**“发生了什么”**（例如 `case IRQ_S_TIMER:` 或 `case CAUSE_ILLEGAL_INSTRUCTION:`），通过 `tf->badvaddr` (`stval`) 才能知道错误相关的地址。
    * 如果**不保存**它们，C 语言的 `trap` 函数将无法判断异常或中断的类型，也就无法进行后续处理。

2.  **它们是“事件报告”，不是“程序状态”**：
    这是最核心的
    区别：
    * **需要恢复的（程序状态）**：`x0-x31`（通用寄存器）、`sepc`（返回地址）、`sstatus`（CPU 状态）。这些共同定义了程序“中断前在做什么”。恢复它们，程序才能无缝继续运行。
    * **不需恢复的（事件报告）**：`scause`（原因）和 `stval`（详情）。它们是硬件在异常发生时，**“填写的报告”**，用于**告诉**操作系统发生了什么。
    * 操作系统**读取**这份报告（`tf->cause`），处理完事件后，这份报告就没有用处了。**“恢复”它们是毫无意义的**。
    * 如果发生下一次异常，硬件会**自动覆盖** `scause` 和 `stval`，写入新的“报告内容”。

**总结：**
`store` `scause` 和 `stval` 的意义在于**将硬件的“异常报告”作为参数传递给 C 语言内核**。它们是**只读的输入信息**，而非需要恢复的程序状态，因此 `RESTORE_ALL` 会（也必须）忽略它们。

## 扩展练习Challenge3：完善异常中断(需要编程)
>编程完善在触发一条非法指令异常 mret和，在 kern/trap/trap.c的异常处理函数中捕获，并对其进行处理，简单输出异常类型和异常指令触发地址，即“Illegal instruction caught at 0x(地址)”，“ebreak caught at 0x（地址）”与“Exception type:Illegal instruction"，“Exception type: breakpoint”。

### 实现思路

需要在`kern/trap/trap.c`中添加对非法指令异常和断点异常的处理:

1. **非法指令异常**: CAUSE_ILLEGAL_INSTRUCTION (2)
2. **断点异常**: CAUSE_BREAKPOINT (3)

### 代码实现

#### 1. 修改 trap.c 添加异常处理

在`trap_dispatch()`函数中添加异常处理分支:

```c
void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
        // 中断处理
        interrupt_handler(tf);
    } else {
        // 异常处理
        exception_handler(tf);
    }
}

static void exception_handler(struct trapframe *tf) {
    switch (tf->cause) {
        case CAUSE_ILLEGAL_INSTRUCTION:
            cprintf("Exception type: Illegal instruction\n");
            cprintf("Illegal instruction caught at 0x%016llx\n", tf->epc);
            // 跳过非法指令,继续执行(epc += 4)
            tf->epc += 4;
            break;
            
        case CAUSE_BREAKPOINT:
            cprintf("Exception type: breakpoint\n");
            cprintf("ebreak caught at 0x%016llx\n", tf->epc);
            // 跳过ebreak指令
            tf->epc += 2;  // ebreak是2字节的压缩指令
            break;
            
        default:
            print_trapframe(tf);
            break;
    }
}
```

#### 2. 添加测试代码触发异常

在`kern/init/init.c`的`kern_init()`函数中添加测试:

```c
int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
    
    cons_init();
    const char *message = "(THU.CST) os is loading ...\n";
    cprintf("%s\n\n", message);
    
    print_kerninfo();
    
    idt_init();
    
    // 测试非法指令异常
    cprintf("\n==== Testing Illegal Instruction ====\n");
    __asm__ __volatile__("mret");  // mret在S模式下是非法指令
    
    // 测试断点异常
    cprintf("\n==== Testing Breakpoint ====\n");
    __asm__ __volatile__("ebreak");
    
    cprintf("\nAll exceptions handled successfully!\n\n");
    
    clock_init();
    intr_enable();
    
    while (1)
        ;
}
```

### 运行结果
![alt text](image.png)

### 关键技术点说明

#### 1. 异常类型判断
```c
// cause的最高位表示是中断(1)还是异常(0)
if ((intptr_t)tf->cause < 0) {
    // 中断
} else {
    // 异常
}
```

#### 2. 异常码定义
根据RISC-V规范:
- `CAUSE_ILLEGAL_INSTRUCTION = 2`: 非法指令
- `CAUSE_BREAKPOINT = 3`: 断点异常

#### 3. EPC调整

**为什么需要调整EPC?**
- 异常处理完后,如果不调整epc,会重复执行导致异常的指令
- 对于非法指令,通常跳过该指令(+4字节)
- 对于ebreak,如果是调试用途可能需要停止,这里选择跳过(+2字节)

**指令长度:**
- 标准RISC-V指令: 4字节
- 压缩指令(如ebreak): 2字节

---


## 实验涉及的知识点

1. **异常与中断的基本概念**  
   异常（Exception）是 CPU 执行指令时出现的错误或特殊情况，如页错误、非法指令或系统调用，它是同步触发的事件，通常不可屏蔽。而中断（Interrupt）由外部硬件设备触发，如时钟溢出或外设完成，属于异步事件，可以通过中断使能位进行屏蔽。两者的主要区别在于触发方式和可屏蔽性：异常同步、不可屏蔽；中断异步、可屏蔽。

2. **特权级与陷入机制**  
   现代 CPU（以 RISC-V 为例）具有多级特权级：M（Machine）模式为硬件最高权限，S（Supervisor）模式为内核，U（User）模式为用户程序。中断或异常发生时，CPU 自动将当前 PC 保存到 `sepc`，将事件原因写入 `scause`，异常相关地址保存到 `stval`（如缺页地址），并切换到高特权级执行内核 trap handler。这一机制保证了用户程序被安全隔离，同时允许内核接管处理事件。

3. **内核中断处理流程**  
   当中断或异常发生时，操作系统内核会接管 CPU 执行权以响应事件。整个处理流程包括以下几个阶段：  
   - **硬件触发与上下文保存**：CPU 检测到中断或异常，自动保存关键状态信息（如程序计数器、状态寄存器等），并切换到内核特权级。  
   - **事件分发**：内核根据中断向量表，判断中断或异常类型，并将事件分发到对应的处理程序。例如，时钟中断驱动调度和时间片管理，外设中断驱动设备数据处理，系统调用触发内核服务。  
   - **中断处理与内核服务执行**：处理程序完成必要的操作，包括更新系统状态、唤醒阻塞进程、执行调度或处理设备数据等。  
   - **上下文恢复与返回用户态**：处理完成后，内核恢复被中断程序的上下文，允许 CPU 返回到原来的特权级和程序执行点，继续执行被中断的任务。
     
4.  **异常上下文（CSRs） vs 通用上下文 (GPRs) (Challenge 2)**

      * **OS原理：** 区分“程序运行状态”和“异常事件报告”。
      * **含义：**
          * **通用上下文**（GPRs, `sepc`, `sstatus`）：是程序运行的**状态**，必须在 `RESTORE_ALL` 中恢复。
          * **异常上下文**（`scause`, `stval`）：是硬件给OS的“事件报告”，是只读输入，用于指导 `trap` 函数的行为，不需要（也不能）被恢复。

5.  **上下文保存的堆栈选择 (Challenge 2)**

      * **OS原理：** 内核必须在**安全**的内核栈上运行，以防止用户栈无效或恶意破坏内核。
      * **差异：** 健壮的 OS 会在 `__alltraps` 入口立即用 `csrrw sp, sscratch, sp` 切换到内核栈。本 `lab3` 为了简化，通过 `csrw sscratch, sp` 保存 `usp` 后，**直接在用户栈上**分配和保存了 `trapframe`。这依赖于一个假设：即用户栈是有效且空间足够的。

6.  **软件实现的中断分发 (Challenge 3)**

      * **OS原理：** 中断向量表 (Interrupt Vector Table, IDT)。OS 需要根据不同的中断/异常号（向量）跳转到不同的处理函数。
      * **差异：** 某些架构（如 x86）有**硬件 IDT**，CPU 自动查表跳转。本实验的 RISC-V 设置 `stvec` 为**单一入口**（`__alltraps`）。因此，内核必须在**软件层面**实现分发：`trap_dispatch` 函数读取 `tf->cause`，然后用 `switch` 语句 **手动模拟**中断向量表的功能。

7.  **异常返回与 `epc` 控制 (Challenge 3)**

      * **OS原理：** 异常处理与程序恢复。
      * **含义：** `sepc` 寄存器决定了 `sret` 指令**返回到哪里**。
      * **关系：** 对于 `ebreak` 或“非法指令”这类已处理的异常，`sepc` 指向的是**导致异常的指令本身**。如果 OS 不修改 `epc`，`sret` 将返回原处，再次执行非法指令，导致**无限异常循环**。因此，`exception_handler` 中 `tf->epc += N` 的操作是**强制要求**的，是 OS 履行“处理并跳过异常”的责任。

8.  **OS原理中重要但在本实验未对应的知识点**

      * **进程/线程上下文切换：** 本实验只涉及 U/S 态的特权级切换。真正的进程切换（`switch_to`）还需要保存和恢复更多的上下文，尤其是**切换页表**（即修改 `satp` 寄存器）。
      * **缺页故障 (Page Fault) 处理：** 这是最重要的异常之一，但 `exception_handler` 尚未处理它。它需要复杂的物理内存管理和页表操作。
      * **并发与锁：** 本实验的 `trap` 流程是单核、非抢占的。在多核或可抢占内核中，`trap` 入口和出口必须处理复杂的并发控制（如锁），以防止竞争条件。

