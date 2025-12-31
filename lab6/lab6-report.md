
# lab6——进程调度
## 练习0：填写已有实验
>本实验依赖实验2/3/4/5。请把你做的实验2/3/4/5的代码填入本实验中代码中有“LAB2”/“LAB3”/“LAB4”“LAB5”的注释相应部分。并确保编译通过。 注意：为了能够正确执行lab6的测试应用程序，可能需对已完成的实验2/3/4/5的代码进行进一步改进。 由于我们在进程控制块中记录了一些和调度有关的信息，例如Stride、优先级、时间片等等，因此我们需要对进程控制块的初始化进行更新，将调度有关的信息初始化。同时，由于时间片轮转的调度算法依赖于时钟中断，你可能也要对时钟中断的处理进行一定的更新。
## 练习1: 理解调度器框架的实现（不需要编码）
>请仔细阅读和分析调度器框架的相关代码，特别是以下两个关键部分的实现：

在完成练习0后，请仔细阅读并分析以下调度器框架的实现：

调度类结构体 sched_class 的分析：请详细解释 sched_class 结构体中每个函数指针的作用和调用时机，分析为什么需要将这些函数定义为函数指针，而不是直接实现函数。
运行队列结构体 run_queue 的分析：比较lab5和lab6中 run_queue 结构体的差异，解释为什么lab6的 run_queue 需要支持两种数据结构（链表和斜堆）。
调度器框架函数分析：分析 sched_init()、wakeup_proc() 和 schedule() 函数在lab6中的实现变化，理解这些函数如何与具体的调度算法解耦。
对于调度器框架的使用流程，请在实验报告中完成以下分析：

调度类的初始化流程：描述从内核启动到调度器初始化完成的完整流程，分析 default_sched_class 如何与调度器框架关联。
进程调度流程：绘制一个完整的进程调度流程图，包括：时钟中断触发、proc_tick 被调用、schedule() 函数执行、调度类各个函数的调用顺序。并解释 need_resched 标志位在调度过程中的作用
调度算法的切换机制：分析如果要添加一个新的调度算法（如stride），需要修改哪些代码？并解释为什么当前的设计使得切换调度算法变得容易。

## 练习2: 实现 Round Robin 调度算法（需要编码）
>完成练习0后，建议大家比较一下（可用kdiff3等文件比较软件）个人完成的lab5和练习0完成后的刚修改的lab6之间的区别，分析了解lab6采用RR调度算法后的执行过程。理解调度器框架的工作原理后，请在此框架下实现时间片轮转（Round Robin）调度算法。

注意有“LAB6”的注释，你需要完成 kern/schedule/default_sched.c 文件中的 RR_init、RR_enqueue、RR_dequeue、RR_pick_next 和 RR_proc_tick 函数的实现，使系统能够正确地进行进程调度。代码中所有需要完成的地方都有“LAB6”和“YOUR CODE”的注释，请在提交时特别注意保持注释，将“YOUR CODE”替换为自己的学号，并且将所有标有对应注释的部分填上正确的代码。

提示，请在实现时注意以下细节：

链表操作：list_add_before、list_add_after等。
宏的使用：le2proc(le, member) 宏等。
边界条件处理：空队列的处理、进程时间片耗尽后的处理、空闲进程的处理等。
请在实验报告中完成：

比较一个在lab5和lab6都有, 但是实现不同的函数, 说说为什么要做这个改动, 不做这个改动会出什么问题
提示: 如kern/schedule/sched.c里的函数。你也可以找个其他地方做了改动的函数。
描述你实现每个函数的具体思路和方法，解释为什么选择特定的链表操作方法。对每个实现函数的关键代码进行解释说明，并解释如何处理边界情况。
展示 make grade 的输出结果，并描述在 QEMU 中观察到的调度现象。
分析 Round Robin 调度算法的优缺点，讨论如何调整时间片大小来优化系统性能，并解释为什么需要在 RR_proc_tick 中设置 need_resched 标志。
拓展思考：如果要实现优先级 RR 调度，你的代码需要如何修改？当前的实现是否支持多核调度？如果不支持，需要如何改进？

## 扩展练习 Challenge 1: 实现 Stride Scheduling 调度算法（需要编码）
>首先需要换掉RR调度器的实现，在sched_init中切换调度方法。然后根据此文件和后续文档对Stride度器的相关描述，完成Stride调度算法的实现。 注意有“LAB6”的注释，主要是修改default_sched_stride_c中的内容。代码中所有需要完成的地方都有“LAB6”和“YOUR CODE”的注释，请在提交时特别注意保持注释，将“YOUR CODE”替换为自己的学号，并且将所有标有对应注释的部分填上正确的代码。

后面的实验文档部分给出了Stride调度算法的大体描述。这里给出Stride调度算法的一些相关的资料（目前网上中文的资料比较欠缺）。

strid-shed paper location
也可GOOGLE “Stride Scheduling” 来查找相关资料
请在实验报告中完成：

简要说明如何设计实现”多级反馈队列调度算法“，给出概要设计，鼓励给出详细设计
简要证明/说明（不必特别严谨，但应当能够”说服你自己“），为什么Stride算法中，经过足够多的时间片之后，每个进程分配到的时间片数目和优先级成正比。
请在实验报告中简要说明你的设计实现过程。
### 1.数据结构定义

**BIG_STRIDE 常量：**
``` c
#define BIG_STRIDE 0x7FFFFFFF  /* 32位有符号整数的最大值 */
```

选择 `0x7FFFFFFF`是为了确保 stride 差值不会溢出。

### 2.`stride_init()` 函数实现

**实现代码：**
```c
stride_init(struct run_queue *rq)
{
     /* LAB6 CHALLENGE 1: 2311089
      * (1) init the ready process list: rq->run_list
      * (2) init the run pool: rq->lab6_run_pool
      * (3) set number of process: rq->proc_num to 0
      */
     list_init(&(rq->run_list));
     rq->lab6_run_pool = NULL;
     rq->proc_num = 0;
}
```

**实现思路：**
- 初始化 `run_list`：使用 `list_init()` 创建空的双向链表
- 初始化 `lab6_run_pool`：设置为 `NULL`，表示优先队列为空
- 初始化 `proc_num`：进程数量设为 0

### 3.`stride_enqueue()` 函数实现

**实现代码：**
```c
static void
stride_enqueue(struct run_queue *rq, struct proc_struct *proc)
{
     /* LAB6 CHALLENGE 1: 2311089
      * (1) insert the proc into rq correctly
      * NOTICE: you can use skew_heap or list. Important functions
      *         skew_heap_insert: insert a entry into skew_heap
      *         list_add_before: insert  a entry into the last of list
      * (2) recalculate proc->time_slice
      * (3) set proc->rq pointer to rq
      * (4) increase rq->proc_num
      */
#if USE_SKEW_HEAP
     // 如果进程已经在队列中，先移除（避免重复插入）
     if (proc->rq == rq) {
          rq->lab6_run_pool = skew_heap_remove(rq->lab6_run_pool, &(proc->lab6_run_pool), proc_stride_comp_f);
          rq->proc_num--;
     }
     // skew_heap_insert 内部会调用 skew_heap_init，所以不需要手动初始化
     rq->lab6_run_pool = skew_heap_insert(rq->lab6_run_pool, &(proc->lab6_run_pool), proc_stride_comp_f);
#else
     assert(list_empty(&(proc->run_link)));
     list_add_before(&(rq->run_list), &(proc->run_link));
#endif
     if (proc->time_slice == 0 || proc->time_slice > rq->max_time_slice) {
          proc->time_slice = rq->max_time_slice;
     }
     proc->rq = rq;
     rq->proc_num++;
}
```

**实现思路：**
1. **检查重复插入**：
   - 如果进程已经在队列中（`proc->rq == rq`），先移除它，避免重复插入导致的数据结构损坏

2. **插入进程到优先队列**：
   - 使用 `skew_heap_insert()` 将进程插入到斜堆。由于使用者可以快速的插入和删除队列中的元素，并且在预先指定的顺序下快速取得当前在队列中的最小（或者最大）值及其对应元素。因此相比普通链表扫描，优先队列在进程数量多时效率更高
   `skew_heap_insert()` 内部会调用 `skew_heap_init()` 初始化节点，所以不需要手动初始化
   - 使用 `proc_stride_comp_f` 比较函数，保证堆按 stride 值排序（最小值在堆顶）

3. **设置时间片**：
   - 如果 `time_slice` 为 0 或大于 `max_time_slice`，则设置为 `max_time_slice`，确保了每个进程都有合理的时间片

4. **更新元数据**：
   - 设置 `proc->rq` 指针，建立进程与运行队列的关联
   - 增加 `rq->proc_num`，更新队列中的进程数量

### 4.`stride_dequeue()` 函数实现

**实现代码：**
```c
static void
stride_dequeue(struct run_queue *rq, struct proc_struct *proc)
{
     /* LAB6 CHALLENGE 1: 2311089
      * (1) remove the proc from rq correctly
      * NOTICE: you can use skew_heap or list. Important functions
      *         skew_heap_remove: remove a entry from skew_heap
      *         list_del_init: remove a entry from the  list
      */
#if USE_SKEW_HEAP
     if (proc->rq == rq) {
          rq->lab6_run_pool = skew_heap_remove(rq->lab6_run_pool, &(proc->lab6_run_pool), proc_stride_comp_f);
          rq->proc_num--;
          proc->rq = NULL;
     }
#else
     list_del_init(&(proc->run_link));
     rq->proc_num--;
#endif
}
```

**实现思路：**
- 只有当 `proc->rq == rq` 时才执行移除操作，避免移除不在队列中的进程。使用 `skew_heap_remove()` 从优先队列中移除指定进程
- 减少 `proc_num`，更新队列中的进程数量。清除 `proc->rq` 指针，表示进程不在任何队列中

### 5.`stride_pick_next()` 函数实现

**实现代码：**
```c
static struct proc_struct *
stride_pick_next(struct run_queue *rq)
{
     /* LAB6 CHALLENGE 1: 2311089
      * (1) get a  proc_struct pointer p  with the minimum value of stride
             (1.1) If using skew_heap, we can use le2proc get the p from rq->lab6_run_pol
             (1.2) If using list, we have to search list to find the p with minimum stride value
      * (2) update p;s stride value: p->lab6_stride
      * (3) return p
      */
#if USE_SKEW_HEAP
     skew_heap_entry_t *le = rq->lab6_run_pool;
     if (le == NULL) {
          return NULL;
     }
     struct proc_struct *p = le2proc(le, lab6_run_pool);
#else
     list_entry_t *le = list_next(&(rq->run_list));
     if (le == &(rq->run_list)) {
          return NULL;
     }
     struct proc_struct *p = le2proc(le, run_link);
     le = list_next(le);
     while (le != &(rq->run_list)) {
          struct proc_struct *q = le2proc(le, run_link);
          if ((int32_t)(p->lab6_stride - q->lab6_stride) > 0) {
               p = q;
          }
          le = list_next(le);
     }
#endif
     if (p->lab6_priority == 0) {
          p->lab6_stride += BIG_STRIDE;
     } else {
          p->lab6_stride += BIG_STRIDE / p->lab6_priority;
     }
     return p;
}
```

**实现思路：**
1. **获取 stride 最小的进程**：
   - 使用斜堆时，堆顶（`rq->lab6_run_pool`）就是 stride 最小的进程
   - 使用 `le2proc` 宏将 `skew_heap_entry_t` 转换为 `proc_struct` 指针
   - 如果队列为空（`le == NULL`），返回 `NULL`

2. **更新 stride 值**：
   - 如果 `priority == 0`，则 `stride += BIG_STRIDE`避免除零错误。否则`stride += BIG_STRIDE / priority`。优先级越高每次增加的 stride 越小，这确保了优先级高的进程 stride 增长慢，更容易被选中


**边界条件处理：**
- 空队列：返回 `NULL`，调用者会切换到 `idleproc`
- 更新 stride 后，堆的性质可能被破坏，但是 `pick_next` 之后会立即 `dequeue`，然后进程会以新的 stride 值重新 `enqueue`

### 6.`stride_proc_tick()` 函数实现

**实现代码：**
```c
static void
stride_proc_tick(struct run_queue *rq, struct proc_struct *proc)
{
     /* LAB6 CHALLENGE 1: 2311089 */
     if (proc->time_slice > 0) {
          proc->time_slice--;
     }
     if (proc->time_slice == 0) {
          proc->need_resched = 1;
     }
}
```

**实现思路：**
- 每次时钟中断，减少当前进程的时间片，当时间片耗尽时，设置 `need_resched = 1`，触发进程切换
- 在 `schedule()` 函数中会检查这个标志，决定是否进行进程切换
- 由于时钟中断发生在中断上下文中，不能直接调用 `schedule()`，需要通过标志位延迟到合适时机

### 7.总结
Stride 调度算法的核心思想是：每个进程有一个 stride 值，初始为 0；每次被选中运行后，stride 增加 `BIG_STRIDE / priority`；总是选择 stride 值最小的进程运行

**为什么经过足够多的时间片后，每个进程分配到的时间片数目和优先级成正比？**

假设有两个进程 A 和 B，优先级分别为 `p_a` 和 `p_b`。

1. **stride 增长速率**：
   进程 A 、B 每次运行后 stride 分别增加`BIG_STRIDE / p_a`、`BIG_STRIDE / p_b`

2. **长期运行后的平衡**：
   - 经过足够长的时间，因为总是选择 stride 最小的，两个进程的 stride 值会趋于接近
   - 设进程 A 运行了 `n_a` 次，进程 B 运行了 `n_b` 次。平衡时：`n_a * (BIG_STRIDE / p_a) ≈ n_b * (BIG_STRIDE / p_b)`。因此：`n_a / n_b ≈ p_a / p_b`

3. **结论**：
   进程运行次数与优先级成正比。由于每次运行的时间片相同，总 CPU 时间也与优先级成正比

**举例说明：**
- 进程 A：priority = 6，每次 stride 增加 `BIG_STRIDE / 6`
- 进程 B：priority = 3，每次 stride 增加 `BIG_STRIDE / 3`
- 经过足够长时间后，进程 A 的运行次数应该是进程 B 的 2 倍（6/3 = 2）。因此，进程 A 获得的总 CPU 时间是进程 B 的 2 倍



## 多级反馈队列调度算法设计

### 1.概要

多级反馈队列（MLFQ）是一种结合了优先级调度和时间片轮转的调度算法。

**核心思想：**
- 维护多个优先级队列，每个队列有不同的时间片大小。高优先级队列的时间片较小，低优先级队列的时间片较大
- 新进程进入最高优先级队列
- 如果进程在时间片内完成，保持当前优先级。如果进程时间片用完但未完成，降级到下一优先级队列


### 2.详细设计

**数据结构：**
```c
#define MAX_PRIORITY_LEVEL 5

struct mlfq_run_queue {
    struct run_queue queues[MAX_PRIORITY_LEVEL];  // 多个优先级队列
    int time_slices[MAX_PRIORITY_LEVEL];          // 每个队列的时间片大小
    unsigned int total_proc_num;                   // 总进程数
};
```

**关键函数设计：**

1. **`mlfq_init()`**：
   初始化所有优先级队列，设置每个队列的时间片大小（高优先级队列时间片小，低优先级队列时间片大）

2. **`mlfq_enqueue()`**：
   新进程进入最高优先级队列，设置进程的当前优先级级别

3. **`mlfq_pick_next()`**：
   从最高优先级队列开始查找，找到第一个非空队列，选择该队列的队首进程

4. **`mlfq_proc_tick()`**：
   减少当前进程的时间片。如果时间片用完未完成，降级到下一优先级队列

5. **`mlfq_dequeue()`**：
   从对应优先级队列中移除进程

## 测试结果

![alt text](image-1.png)

从实验输出可以看到，不同优先级的进程获得了不同数量的 CPU 时间。优先级较高的进程获得了更多的执行机会，完成了更多的工作量。优先级最高的进程（priority = 6，pid = 7）累计完成的工作量为 acc = 872000；优先级最低的进程（priority = 1，pid = 3）累计完成的工作量为 acc = 312000；可以观察到，随着进程优先级的降低，其获得的 CPU 时间和完成的工作量也逐渐减少。

从整体趋势来看，进程的累计运行量 acc 与其优先级呈正相关关系。虽然各进程的运行时间time基本相同，但高优先级进程在相同时间内获得了更多的 CPU 资源，这与 Stride 调度算法“按权重比例分配 CPU 时间”的设计目标一致。尽管由于时间片离散和调度切换等因素，实际数值与理论比例并不完全一致，但总体分配结果符合预期。


## 实验知识点

1. 在 stride 调度实验中，通过给进程设置不同的 priority，并据此计算 stride，使高优先级进程在调度中被更频繁地选中，从而获得更多的 CPU 时间。这对应了 OS 原理中的调度策略与加权公平调度思想。
2. 通过维护进程的 stride 和累计值，在每次调度时选择 stride 最小的进程运行。这对应了 OS 原理中调度器维护就绪队列并根据策略进行调度决策。
