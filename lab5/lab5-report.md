# LAB5——用户程序
## 练习0：填写已有实验
>本实验依赖实验2/3/4。请把你做的实验2/3/4的代码填入本实验中代码中有“LAB2”/“LAB3”/“LAB4”的注释相应部分。注意：为了能够正确执行lab5的测试应用程序，可能需对已完成的实验2/3/4的代码进行进一步改进。
## 练习一：加载应用程序并执行（需要编码）
>**`do_execve`**函数调用`load_icode`（位于kern/process/proc.c中）来加载并解析一个处于内存中的ELF执行文件格式的应用程序。你需要补充`load_icode`的第6步，设置好`proc_struct`结构中的成员变量`trapframe`的内容，确保在执行此进程后，能够从应用程序设定的起始执行地址开始执行。需设置正确的trapframe内容。
>
>请在实验报告中简要说明你的设计实现过程。
>
> - 请简要描述这个用户态进程被ucore选择占用CPU执行（RUNNING态）到具体执行应用程序第一条指令的整个经过。

在第6步中设置了trapframe的关键字段如下：
```c
    struct trapframe *tf = current->tf;
    memset(tf, 0, sizeof(struct trapframe));
    tf->gpr.sp = USTACKTOP;           // 用户栈指针
    tf->epc = elf->e_entry;           // 程序入口地址

    // 设置sstatus寄存器
    uintptr_t sstatus = read_csr(sstatus);
    // 清除SPP位（设置为用户态），开启中断
    sstatus &= ~SSTATUS_SPP;    // 清除SPP，表示从用户态进入
    sstatus |= SSTATUS_SPIE;   // 设置SPIE，允许中断
    sstatus &= ~SSTATUS_SIE;    // 清除SIE，在内核中禁用中断
    tf->status = sstatus;
```
首先获取当前进程的trapframe指针tf，清空trapframe。将用户栈指针设置为用户栈顶地址（USTACKTOP），并设置程序计数器（epc）为ELF文件的入口地址（elf->e_entry）。最后从CSR读取当前的sstatus寄存器值，配置处理器状态寄存器：清除SPP位（表示返回到用户态）、设置SPIE位（在用户态允许中断）、清除SIE位（当前在内核态禁用中断），确保执行sret指令后能够正确切换到用户态并开始执行应用程序。

- 用户态进程执行过程（通过exec加载新程序后的执行流程）

`load_icode()`在`do_execve()`中被调用，用于加载新程序。当进程调用exec系统调用加载新程序后，从系统调用返回用户态并执行新程序的流程如下：
1. 进程调用exec系统调用，在内核态执行`do_execve()`和`load_icode()`
2. `load_icode()`设置新的trapframe（包括`tf->epc = elf->e_entry`和`tf->gpr.sp = USTACKTOP`）
3. `sys_exec()`返回0，系统调用处理完成
4. 返回到`exception_handler()`，然后返回到`trap()`，最后返回到`__trapret`
5. `__trapret`调用`RESTORE_ALL`宏，从trapframe恢复所有寄存器（包括sstatus和sepc）
6. 执行`sret`指令：
   - CPU从sstatus恢复特权级别（用户态，因为SPP=0）
   - 从sepc恢复PC（sepc = elf->e_entry）
   - 切换到用户态
7. 程序计数器指向`elf->e_entry`指定的入口地址，应用程序的第一条指令开始执行

注意：exec后的进程不经过forkret，而是直接通过系统调用的正常返回路径（__trapret）返回到用户态。


## 练习二：父进程复制自己的内存空间给子进程（需要编码）
>创建子进程的函数`do_fork`在执行中将拷贝当前进程（即父进程）的用户内存地址空间中的合法内容到新进程中（子进程），完成内存资源的复制。具体是通过`copy_range`函数（位于kern/mm/pmm.c中）实现的，请补充`copy_range`的实现，确保能够正确执行。
>
>请在实验报告中简要说明你的设计实现过程。
>
> - 如何设计实现`Copy on Write`机制？给出概要设计，鼓励给出详细设计。
## 练习三：阅读分析源代码，理解进程执行 fork/exec/wait/exit 的实现，以及系统调用的实现（不需要编码）
> 请在实验报告中简要说明你对 fork/exec/wait/exit函数的分析。并回答如下问题：
>
> - 请分析fork/exec/wait/exit的执行流程。重点关注哪些操作是在用户态完成，哪些是在内核态完成？内核态与用户态程序是如何交错执行的？内核态执行结果是如何返回给用户程序的？
> - 请给出ucore中一个用户态进程的执行状态生命周期图（包执行状态，执行状态之间的变换关系，以及产生变换的事件或函数调用）。（字符方式画即可）
>
>执行：make grade。如果所显示的应用程序检测都输出ok，则基本正确。（使用的是qemu-1.0.1）
## fork/exec/wait/exit 执行流程分析

### 系统调用机制

**用户态 -> 内核态切换：**
1. 用户程序调用系统调用包装函数（如 `sys_fork()`），该函数位于 `user/libs/syscall.c`
2. 包装函数执行内联汇编，将系统调用号和参数放入寄存器 a0-a5，然后执行 `ecall` 指令
3. `ecall` 指令触发硬件异常（CAUSE_USER_ECALL），CPU自动切换到内核态并跳转到异常处理入口
4. 异常处理程序 `__alltraps` 保存所有寄存器到 trapframe，然后调用 `trap()` 函数
5. `trap_dispatch()` -> `exception_handler()` -> `syscall()` 函数根据系统调用号分发到具体处理函数

**内核态 -> 用户态返回：**
1. 内核函数将返回值放入 `tf->gpr.a0` 寄存器
2. `__trapret` 恢复所有寄存器（包括包含返回值的 a0）
3. 执行 `sret` 指令，CPU恢复用户态并跳转到 `ecall` 的下一条指令
4. 用户程序从 a0 寄存器读取返回值

### fork() 执行流程

**用户态操作：**
- 调用 `fork()` -> `sys_fork()` -> 执行 `ecall` 指令陷入内核态

**内核态操作：**
- `syscall()` -> `sys_fork()` -> `do_fork()`
- `do_fork()` 执行：
  - 分配子进程PCB（状态为 PROC_UNINIT）
  - 分配内核栈
  - 复制父进程内存空间（`copy_mm()`）
  - 设置子进程 trapframe（子进程的 a0 设为 0）
  - 设置子进程 context（首次运行入口为 `forkret`）
  - 将子进程加入进程链表并设为 PROC_RUNNABLE（`wakeup_proc()`）
- 父进程返回子进程 PID（通过 `tf->gpr.a0`）

**子进程首次运行：**
- 调度器选择子进程后，通过 `proc_run()` 切换到子进程
- 子进程从 `forkret` 开始执行，通过 `sret` 返回用户态
- 子进程从 `fork()` 调用处继续执行，返回值为 0

### exec() 执行流程

**用户态操作：**
- 调用 `exec()` -> `sys_exec()` -> 执行 `ecall` 指令陷入内核态

**内核态操作：**
- `syscall()` -> `sys_exec()` -> `do_execve()`
- `do_execve()` 执行：
  - 验证用户空间地址有效性
  - 释放旧的内存空间（`exit_mmap()`, `put_pgdir()`, `mm_destroy()`）
  - 调用 `load_icode()` 加载新程序：
    - 创建新的内存管理结构
    - 解析 ELF 文件，加载代码段和数据段
    - 设置用户栈
    - 设置新的 trapframe（`tf->epc = elf->e_entry`，`tf->gpr.sp = USTACKTOP`）
- 通过 `sret` 返回用户态时，跳转到新程序的入口地址（不再返回 `exec()` 调用处）

### wait() 执行流程

**用户态操作：**
- 调用 `wait()` -> `sys_wait()` -> 执行 `ecall` 指令陷入内核态

**内核态操作：**
- `syscall()` -> `sys_wait()` -> `do_wait()`
- `do_wait()` 执行：
  - 查找是否有 ZOMBIE 状态的子进程
  - 如果有：回收子进程资源，返回子进程 PID 和退出码
  - 如果没有但存在子进程：
    - 设置当前进程状态为 PROC_SLEEPING
    - 调用 `schedule()` 让出 CPU（**进程在内核态睡眠**）
    - 被子进程退出唤醒后，在内核态继续执行，重新查找 ZOMBIE 子进程

### exit() 执行流程

**用户态操作：**
- 调用 `exit()` -> `sys_exit()` -> 执行 `ecall` 指令陷入内核态

**内核态操作：**
- `syscall()` -> `sys_exit()` -> `do_exit()`
- `do_exit()` 执行：
  - 释放内存资源（切换到内核页表后释放用户空间）
  - 设置进程状态为 PROC_ZOMBIE
  - 处理子进程关系（将子进程的父进程设为 initproc）
  - 唤醒等待中的父进程（如果父进程在 `do_wait()` 中睡眠）
  - 调用 `schedule()` 切换到其他进程（当前进程永远不会再被调度）

### 内核态与用户态的交错执行

1. **同步系统调用**（fork、exec、getpid等）：
   - 用户态 -> 内核态执行 -> 立即返回用户态
   - 整个调用过程在同一个进程上下文中完成

2. **可能阻塞的系统调用**（wait）：
   - 用户态 -> 内核态执行
   - 如果没有就绪的资源，进程在内核态进入 PROC_SLEEPING 状态，调用 `schedule()` 让出 CPU
   - **切换到其他进程执行**（可能是其他进程的用户态或内核态代码）
   - 事件发生时（如子进程退出），父进程被唤醒，在内核态继续执行 `do_wait()` 的剩余代码
   - 完成后返回用户态

3. **进程创建的特殊性**（fork）：
   - 父进程在内核态完成 fork 后返回用户态，继续执行 fork() 之后的代码
   - 子进程首次被调度时，从内核态的 `forkret` 开始，然后通过 `sret` 返回用户态，从 fork() 调用处继续执行
   - **两个进程几乎同时从 fork() 返回**，但返回值不同（父进程返回子进程PID，子进程返回0）

4. **进程替换的特殊性**（exec）：
   - exec 执行后，**永远不会返回到 exec() 调用处**
   - 新程序从入口地址开始执行，之前的用户态栈和代码都被替换

### 内核态执行结果返回给用户程序

1. **返回值传递**：
   - 内核函数将返回值赋给 `tf->gpr.a0`（RISC-V中 a0 是返回值寄存器）
   - 例如：`sys_fork()` 返回 `do_fork()` 的结果（子进程PID）

2. **寄存器恢复**：
   - `__trapret` 调用 `RESTORE_ALL` 宏，从 trapframe 恢复所有寄存器
   - 恢复的 a0 寄存器包含系统调用的返回值

3. **返回到用户态**：
   - 执行 `sret` 指令，CPU 从 `sstatus` 恢复特权级别（用户态），从 `sepc` 恢复 PC

4. **用户程序获取返回值**：
   - 用户态的内联汇编：`"sd a0, %0"` 将 a0 的值保存到 `ret` 变量
   - `syscall()` 函数返回这个值，用户程序从包装函数获取返回值
### ucore用户态进程生命周期图
```
                      +----------------------------+
                      |        alloc_proc()        |
                      |   创建 PCB，状态=UNINIT     |
                      +--------------+-------------+
                                     |
                                     | proc_init() / wakeup_proc()
                                     v
                            +------------------+
                            |  PROC_UNINIT     |
                            +--------+---------+
                                     |
                                     | wakeup_proc() / 在 do_fork() 中
                                     v
                         +-------------------------+
                         |     PROC_RUNNABLE      |
                         |   （就绪队列中的进程）  |
                         +-----------+-------------+
                                     |
                                     | schedule() 选择该进程
                                     | proc_run()
                                     v
                              +---------------+
                              |   RUNNING     |
                              +-------+-------+
          +---------------------------+---------------------------+
          |                           |                           |
          | 时间片用完/中断/yield      | do_sleep(), do_wait()     | do_exit()
          | schedule()                 | 主动睡眠/等待资源         | 退出执行
          |                           |                           |
          v                           v                           v
+----------------------+     +---------------------+     +---------------------+
|   PROC_RUNNABLE      |     |   PROC_SLEEPING     |     |    PROC_ZOMBIE      |
| (重新加入就绪队列)    |     | （不可调度，等待事件）|     |（等待父进程 wait）   |
+----------+-----------+     +----------+----------+     +----------+----------+
           ^                        |                           ^
           |                        |                           |
           | wakeup_proc()          |                           |do_kill() -> PF_EXITING(被kill唤醒后检查标志)-> do_exit()
           | 事件触发/条件满足        |                           |
           |                        |                           |
           |                        |                           |
           +------------------------+---------------------------+
                                                               |
                                                               | do_wait() 回收资源
                                                               v
                                                        +---------------------+
                                                        |   （被内核回收）    |
                                                        | do_wait() -> free   |
                                                        +---------------------+

状态说明：
- PROC_UNINIT:   未初始化状态，进程控制块已分配但未完全初始化
- PROC_RUNNABLE: 可运行状态，进程在就绪队列中等待调度
- RUNNING:       运行状态，进程正在CPU上执行（状态值仍为PROC_RUNNABLE）
- PROC_SLEEPING: 睡眠状态，进程因等待资源或事件而阻塞，不可调度
- PROC_ZOMBIE:   僵尸状态，进程已退出但资源未回收，等待父进程处理

关键转换函数和事件：
1. alloc_proc():           创建进程结构，状态设为PROC_UNINIT
2. proc_init()/wakeup_proc(): PROC_UNINIT -> PROC_RUNNABLE
3. schedule() -> proc_run(): PROC_RUNNABLE -> RUNNING
4. 时间片用完/中断/yield:    RUNNING -> PROC_RUNNABLE (通过schedule())
5. do_sleep()/do_wait():    RUNNING -> PROC_SLEEPING
6. wakeup_proc():           PROC_SLEEPING -> PROC_RUNNABLE
7. do_exit():               RUNNING -> PROC_ZOMBIE
8. do_kill() + do_exit():   PROC_SLEEPING -> PROC_ZOMBIE (进程在睡眠时被kill)
9. do_wait():               父进程回收子进程资源，PROC_ZOMBIE -> 进程被销毁
```

## 扩展练习一：实现 Copy on Write （COW）机制
>给出实现源码,测试用例和设计报告（包括在cow情况下的各种状态转换（类似有限状态自动机）的说明）。
>
>这个扩展练习涉及到本实验和上一个实验“虚拟内存管理”。在ucore操作系统中，当一个用户父进程创建自己的子进程时，父进程会把其申请的用户空间设置为只读，子进程可共享父进程占用的用户内存空间中的页面（这就是一个共享的资源）。当其中任何一个进程修改此用户内存空间中的某页面时，ucore会通过page fault异常获知该操作，并完成拷贝内存页面，使得两个进程都有各自的内存页面。这样一个进程所做的修改不会被另外一个进程可见了。请在ucore中实现这样的COW机制。
>
>由于COW实现比较复杂，容易引入bug，请参考 https://dirtycow.ninja/ 看看能否在ucore的COW实现中模拟这个错误和解决方案。需要有解释。
## 扩展练习二
>说明该用户程序是何时被预先加载到内存中的？与我们常用操作系统的加载有何区别，原因是什么？
