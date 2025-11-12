# LAB4——进程管理
## 练习0：填写已有实验
> 本实验依赖实验2/3。请把你做的实验2/3的代码填入本实验中代码中有“LAB2”,“LAB3”的注释相应部分。
## 练习1：分配并初始化一个进程控制块（需要编码）
>`alloc_proc`函数（位于`kern/process/proc.c`中）负责分配并返回一个新的`struct proc_struct`结构，用于存储新建立的内核线程的管理信息。ucore需要对这个结构进行最基本的初始化，你需要完成这个初始化过程。
>
>请在实验报告中简要说明你的设计实现过程。请回答如下问题：
>
> - 请说明`proc_struct`中`struct context context`和`struct trapframe *tf`成员变量含义和在本实验中的作用是啥？（提示通过看代码和编程调试可以判断出来）

### 完善`alloc_proc`函数
alloc_proc 函数的主要任务是为新创建的内核线程分配并初始化进程控制块PCB。根据proc_struct结构体中各字段的语义，采用不同的初始化策略，比如状态字段初始化为最安全的"未初始化"状态；PID设为无效值，表示尚未分配等。

最终将所有字段初始化为安全状态。
```c
proc->state = PROC_UNINIT;          // 进程状态：未初始化
        proc->pid = -1;                      // 进程ID：未分配
        proc->runs = 0;                      // 运行次数：0
        proc->kstack = 0;                     // 内核栈地址：未分配
        proc->need_resched = 0;              // 不需要重新调度
        proc->parent = NULL;                  // 父进程指针：无
        proc->mm = NULL;                      // 内存管理结构：内核线程不需要
        memset(&(proc->context), 0, sizeof(struct context)); // 上下文清零
        proc->tf = NULL;                      // 陷阱帧指针：未设置
        proc->pgdir = NULL;                   // 页目录基址：未分配
        proc->flags = 0;                      // 进程标志：0
        memset(proc->name, 0, PROC_NAME_LEN + 1); // 进程名清零
```
### 变量含义及作用
#### `struct context context`
- struct context结构体保存了进程切换时需要保存的寄存器状态，主要是被调用者保存的寄存器，包括返回地址ra、栈指针sp以及s0-s11寄存器。当需要从一个进程切换到另一个进程时，保存当前进程的寄存器状态到 context 中；当进程再次被调度执行时，从 context 中恢复寄存器状态继续执行。

- 在本实验中 proc_run 函数通过 switch_to(&(prev->context), &(next->context)) 实现进程切换；在 copy_thread 函数中设置新进程的 context.ra 指向 forkret，context.sp 指向 trapframe。

#### `struct trapframe *tf`
```c
struct trapframe {
    struct pushregs gpr;
    uintptr_t status;
    uintptr_t epc;
    uintptr_t tval;
    uintptr_t cause;
};
```
- struct trapframe *tf 是proc_struct中的一个指针成员，指向一个 trapframe 结构体。这个结构体用于保存进程在发生中断或异常时的处理器状态快照。
- 在本实验中，在创建新进程时，需要为新进程构造一个临时的中断帧来定义新进程诞生时的初始状态。
```c
int kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags)
{
    struct trapframe tf;
    ...
}
```
- copy_thread 函数将传入的 trapframe 复制到新进程内核栈的顶部。由于在真正的硬件中断发生时，CPU会自动将寄存器状态保存到当前栈顶。通过将trapframe放在相同位置，我们可以"欺骗"CPU，让它以为这个新进程是从某个中断处理中恢复的。
- forkret 函数作为新进程第一次执行的入口点，它调用forkrets，准备进行中断返回。forkrets将栈指针设置为新进程的trapframe，然后跳转到__trapret。__trapret会从trapframe中恢复所有寄存器的值，包括程序计数器epc。由于在初始化时将epc设置为了kernel_thread_entry，所以恢复后会跳转到那里执行。kernel_thread_entry是一个统一的入口函数，跳转到s0寄存器执行新进程要执行的函数。至此，完成了一个进程的初始化。


## 练习2：为新创建的内核线程分配资源（需要编码）
> 创建一个内核线程需要分配和设置好很多资源。`kernel_thread`函数通过调用do_fork函数完成具体内核线程的创建工作。`do_kernel`函数会调用alloc_proc函数来分配并初始化一个进程控制块，但`alloc_proc`只是找到了一小块内存用以记录进程的必要信息，并没有实际分配这些资源。ucore一般通过do_fork实际创建新的内核线程。`do_fork`的作用是，创建当前内核线程的一个副本，它们的执行上下文、代码、数据都一样，但是存储位置不同。因此，我们实际需要"fork"的东西就是stack和trapframe。在这个过程中，需要给新内核线程分配资源，并且复制原进程的状态。你需要完成在`kern/process/proc.c`中的do_fork函数中的处理过程。它的大致执行步骤包括：
>
>- 调用alloc_proc，首先获得一块用户信息块。
>- 为进程分配一个内核栈。
>- 复制原进程的内存管理信息到新进程（但内核线程不必做此事）
>- 复制原进程上下文到新进程
>- 将新进程添加到进程列表
>- 唤醒新进程
>- 返回新进程号
> 
>请在实验报告中简要说明你的设计实现过程。请回答如下问题：
>
>- 请说明ucore是否做到给每个新fork的线程一个唯一的id？请说明你的分析和理由。
## 练习3：编写proc_run 函数（需要编码）
> proc_run用于将指定的进程切换到CPU上运行。它的大致执行步骤包括：
>
>- 检查要切换的进程是否与当前正在运行的进程相同，如果相同则不需要切换。
>- 禁用中断。你可以使用`/kern/sync/sync.h`中定义好的宏`local_intr_save(x)`和`local_intr_restore(x)`来实现关、开中断。
>- 切换当前进程为要运行的进程。
>- 切换页表，以便使用新进程的地址空间。`/libs/riscv.h`中提供了`lsatp(unsigned int pgdir)`函数，可实现修改SATP寄存器值的功能。
>- 实现上下文切换。`/kern/process`中已经预先编写好了`switch.S`，其中定义了`switch_to()`函数。可实现两个进程的context切换。
>- 允许中断。
>
>请回答如下问题：
>
>- 在本实验的执行过程中，创建且运行了几个内核线程？
>
>完成代码编写后，编译并运行代码：make qemu
## 扩展练习 Challenge：
1. > 说明语句`local_intr_save(intr_flag);....local_intr_restore(intr_flag)`;是如何实现开关中断的？
2. > 深入理解不同分页模式的工作原理（思考题）
    >
    >get_pte()函数（位于kern/mm/pmm.c）用于在页表中查找或创建页表项，从而实现对指定线性地址对应的物理页的访问和映射操作。这在操作系统中的分页机制下，是实现虚拟内存与物理内存之间映射关系非常重要的内容。
    >
    >- get_pte()函数中有两段形式类似的代码， 结合sv32，sv39，sv48的异同，解释这两段代码为什么如此相像。
    >- 目前get_pte()函数将页表项的查找和页表项的分配合并在一个函数里，你认为这种写法好吗？有没有必要把两个功能拆开？

### 为什么两段代码相像
```c
pde_t *pdep1 = &pgdir[PDX1(la)];
    if (!(*pdep1 & PTE_V))
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
    }
```
```c
pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
    if (!(*pdep0 & PTE_V))
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
    }
```
- RISC-V Sv39 内存管理机制采用的多级页表结构。第一段代码处理一级页目录项，它使用虚拟地址的 [38:30] 位作为索引。第二段代码处理二级页目录项，使用虚拟地址的 [29:21] 位作为索引。虽然索引的位段不同，但核心逻辑完全一致：都是检查当前级别的页表项是否存在PTE_V 标志位，如果不存在且允许创建，就分配新的页表页面并进行初始化。

- Sv32, Sv39, Sv48核心页表遍历机制是完全相同的，都遵循 RISC-V 标准的分页原理。只是虚拟地址宽度分别是32位，39位，48位，页表级数分别是2，3，4。而页表的级数 N 直接决定了在 get_pte中需要执行 N-1 次“查找或创建下一级页表”的重复代码段，才能最终到达存放最终映射的末级页表。

比如如果目标是 Sv32（2 级页表）：那么只需要 1 段​ 这样的相似代码。流程是：处理根目录（Level 1）-> 直接返回最终 PTE。

如果目标是 Sv48（4 级页表）：则需要 3 段​ 相似的代码。流程是：处理根目录（Level 3）-> 处理 Level 2 -> 处理 Level 1 -> 返回最终 PTE。

### 页表项的查找和页表项的分配合并在一个函数好吗
我认为这种合并是合理的。

在操作系统中，获取页表项的典型场景就是"如果存在就获取，如果不存在就创建"。将这两个操作合并到一个函数中，为调用方提供了极大的便利。调用方不需要先调用查找函数，再根据返回值决定是否调用分配函数，而是通过一个简单的布尔参数 create就能控制行为。如果拆分成两个函数，在查找返回后、分配调用前，其他进程可能会修改页表状态，导致不一致。

## 实验涉及的知识点
