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
> 创建一个内核线程需要分配和设置好很多资源。`kernel_thread`函数通过调用`do_fork`函数完成具体内核线程的创建工作。`do_kernel`函数会调用`alloc_proc`函数来分配并初始化一个进程控制块，但`alloc_proc`只是找到了一小块内存用以记录进程的必要信息，并没有实际分配这些资源。ucore一般通过`do_fork`实际创建新的内核线程。`do_fork`的作用是，创建当前内核线程的一个副本，它们的执行上下文、代码、数据都一样，但是存储位置不同。因此，我们实际需要"fork"的东西就是stack和trapframe。在这个过程中，需要给新内核线程分配资源，并且复制原进程的状态。你需要完成在`kern/process/proc.c`中的do_fork函数中的处理过程。它的大致执行步骤包括：
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
1. **设计实现过程**

    1. **资源不足检查** 
    ```c
    int ret = -E_NO_FREE_PROC;
    struct proc_struct *proc;
    if (nr_process >= MAX_PROCESS) {
        goto fork_out;
    }
    ret = -E_NO_MEM;
    ```
    进入` do_fork` 时首先做全局可创建进程数的检查：如果当前进程数`nr_process` 已经达到系统允许的上限`MAX_PROCESS`，函数直接返回错误`-E_NO_FREE_PROC`。随后把默认返回值设为`-E_NO_MEM`，用于后续的内存分配失败统一返回。

    2. **分配进程控制块**
    ```c
    proc = alloc_proc();
    if (proc == NULL) {
        goto fork_out;
    }
    ```
    调用`alloc_proc()`分配并初始化一个`proc_struct`结构体，如果内存不足分配失败，直接返回错误`ret`。

    3. **分配并设置内核栈**
    ```c
    if (setup_kstack(proc) != 0) {
        goto bad_fork_cleanup_proc;
    }
    ```
    为新进程分配内核栈页面，如果分配失败，跳到`bad_fork_cleanup_proc`，释放已分配的`proc_struct`内存，返回内存不足错误`ret`。

    4. **复制或共享内存管理信息**
    ```c
    if (copy_mm(clone_flags, proc) != 0) {
        goto bad_fork_cleanup_kstack;
    }
    ```
    根据`clone_flags`决定复制还是共享内存管理系统。如果失败，跳转到`bad_fork_cleanup_kstack`回收刚才申请的内核栈并释放`proc_struct`。

    5. **设置父指针，获取PID并复制线程上下文**
    ```c
    proc->parent = current;
    proc->pid = get_pid();
    copy_thread(proc, stack, tf);
    ```
    首先把当前进程设置为子进程的父进程，建立父子关系；然后调用`get_pid()`函数分配一个唯一`pid`给子进程；最后调用`copy_thread()`函数复制父进程的中断帧和上下文信息。

    6. **将新进程添加进进程列表**
    ```c
    list_add(&proc_list, &(proc->list_link));
    hash_proc(proc);
    nr_process++;
    ```
    把 proc 的链表节点`list_link`插入到全局进程链表，同时调用`hash_proc(proc)` 将其插入按 PID 的哈希链表，以便后续按 PID 快速查找。然后把全局计数 `nr_process`增 1。

    7. **唤醒子进程并返回PID**
    ```c
    wakeup_proc(proc);
    ret = proc->pid;
    ```
    调用`wakeup_proc()`将`proc->state`置为`PROC_RUNNABLE`;最后把分配到的子进程 PID 作为函数返回值。
2. **唯一ID的实现**

给每个新fork的线程一个唯一的id是通过`get_pid()`函数实现的。
```c
static int
get_pid(void)
{
    static_assert(MAX_PID > MAX_PROCESS);
    struct proc_struct *proc;
    list_entry_t *list = &proc_list, *le;
    static int next_safe = MAX_PID, last_pid = MAX_PID;
```

首先进行一系列初始化工作，通过 `static_assert(MAX_PID > MAX_PROCESS)` 在保证了 PID 数量大于系统允许的最大进程数，从而保证在CPU运行时始终存在未占用的 PID。`list` 和 `le` 分别指向全局进程链表头与链表迭代指针；变量 `last_pid` 用作顺序分配的上一次分配值，`next_safe` 用来作为下一轮检查的上界，以减少不必要的遍历。

---

```c
    if (++last_pid >= MAX_PID)
    {
        last_pid = 1;
        goto inside;
    }
```

这一段实现了对 `last_pid` 的循环自增逻辑：每次调用 `get_pid()` 时先将 `last_pid` 增一以产生一个新的候选 PID；若增至或超过最大的 PID 值则回绕到 `1` 重新开始循环。

---

```c
    if (last_pid >= next_safe)
    {
    inside:
        next_safe = MAX_PID;
    repeat:
        le = list;
        while ((le = list_next(le)) != list)
        {
            proc = le2proc(le, list_link);
```

当候选 PID 达到或超过 `next_safe` 时，首先将 `next_safe` 恢复为最大值以准备重新计算新的安全上界，然后从进程链表头开始遍历每个当前存在的进程。

---

```c
            if (proc->pid == last_pid)
            {
                if (++last_pid >= next_safe)
                {
                    if (last_pid >= MAX_PID)
                    {
                        last_pid = 1;
                    }
                    next_safe = MAX_PID;
                    goto repeat;
                }
            }
```

在遍历过程中如果某个进程的 PID 恰好等于当前候选 `last_pid`，候选值自增来跳过被占用的编号；当自增后到达或超过当前的 `next_safe`时，`last_pid` 赋值为1，再从头找PID，并重置 `next_safe`为`MAX_PID`，然后再从链表头重新开始检查。**这里就保证了为新fork的进程分配的PID是不会与档现有的进行的PID值相等的，也就是说，做到了给每个新fork的线程一个唯一的id**。

---

```c
            else if (proc->pid > last_pid && next_safe > proc->pid)
            {
                next_safe = proc->pid;
            }
        }
    }
    return last_pid;
}
```

如果当前遍历到的进程 PID 大于`last_pid`,小于当前 `next_safe`，更新 `next_safe` 为这个PID值作为更小的上界；遍历完整个进程链表后，函数返回当前的 `last_pid` 作为最终分配结果。

（PS：此处 `next_safe` 的维护是为了加快分配PID的速度，它提供了下一次必须进行全面检查的阈值，在一定程度上可以减少重复扫描。）

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

    开关中断实现的核心思想是：**进入临界区前记录当前 CPU 的中断使能状态，并在离开临界区时恢复该状态，而不是强制开启或关闭中断。**
    1. 进入临界区：`local_intr_save(intr_flag)` ，宏 `local_intr_save(x)` 会调用内部函数 `__intr_save()`，主要逻辑如下：
        1. 读取sstatus寄存器，根据寄存器中的 `SSTATUS_SIE` 位表示当前 CPU 是否允许处理中断。
        2. 判断中断是否处于开启状态， 若当前中断已开启，则调用 `intr_disable()` 关闭中断，并返回标记值 `1`;若当前中断本就关闭，则什么也不做，返回 `0`。
        3. 返回值通过 x 保存原中断状态: `intr_flag = 1`：进入临界区前中断处于开启状态;`intr_flag = 0`：进入临界区前中断本来就关闭
    因此，`local_intr_save(intr_flag)`完成了“关闭中断”，并**记录了原中断状态**。
    2. 离开临界区：`local_intr_restore(intr_flag)` ；宏 `local_intr_restore(intr_flag)` 调用 `__intr_restore(flag)`，根据 flag 的值决定是否恢复中断：
        1. 如果 `flag == 1`，说明进入临界区前中断是开启的，因此调用 `intr_enable()` 再次开启中断
        2. 如果 `flag == 0`， 说明进入临界区前中断本来就关闭，退出临界区时不做任何操作
    这样保证了 **中断状态被恢复到进入临界区前的样子**，而不是盲目开启或关闭。
    3. 该设计有以下的优点：
        -  保证临界区内代码不被中断打断，避免共享数据结构在访问过程中被并发修改，确保内核操作的原子性。
        - 保证中断状态的正确恢复，即使调用者进入临界区前已经主动关闭了中断，该机制也不会在离开时错误地打开中断。
        - 提高可重入性与安全性，允许嵌套使用，不会破坏外层代码的中断状态。

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
1. **进程创建的过程**

    在操作系统中，进程的创建通常通过父进程派生子进程的方式完成。当创建一个新的进程时，内核首先为子进程分配独立的进程控制块并为其分配唯一的 PID，以便在整个系统中区分不同的执行实体。随后，内核会让子进程继承父进程的大部分执行环境，包括运行状态、权限信息、文件描述符表以及其他资源描述结构，使得一个新进程可以在父进程的基础上快速构建出自身的运行上下文。

    在内存管理层面，子进程会获得一份与父进程一致的虚拟地址空间布局，包括代码段、数据段、堆栈、内核用户边界等。内核需要为子进程建立对应的页表结构，使其能够独立进行内存访问。为了避免在创建阶段复制大量内存页造成开销，现代操作系统普遍采用**写时复制机制**：父子进程最初共享同一份物理页，且页面被标记为只读。当任一进程对共享页进行写入时，内核才会为该进程分配新的物理页并更新页表，从而在保证进程隔离性的同时显著降低了进程创建的成本。页表的复制通常只涉及页表结构本身，而非物理页的逐页复制，这进一步提升了创建效率。

    除了内存，子进程还会获得与父进程相同的寄存器现场，包括程序计数器、栈指针等。由于父子进程的寄存器完全一致，它们在用户态返回时看上去都“从同一位置继续执行”，但通过约定返回值不同（父进程返回子进程 PID，子进程返回 0），两者能够产生分歧。此外，子进程的内核栈和调度上下文会按需重新构造，使其能够在被调度器选中时从正确的位置进入执行。

    初始化完成后，子进程被加入调度队列，成为系统中一个新的可运行实体。从此刻起，父子进程拥有独立的执行流，它们既能共享某些资源，又能以不同方式继续执行，从而实现操作系统多任务环境下的并发与隔离。