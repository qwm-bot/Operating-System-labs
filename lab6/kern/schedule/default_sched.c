#include <defs.h>
#include <list.h>
#include <proc.h>
#include <assert.h>
#include <default_sched.h>

/*
 * RR_init initializes the run-queue rq with correct assignment for
 * member variables, including:
 *
 *   - run_list: should be an empty list after initialization.
 *   - proc_num: set to 0
 *   - max_time_slice: no need here, the variable would be assigned by the caller.
 *
 * hint: see libs/list.h for routines of the list structures.
 */
static void
RR_init(struct run_queue *rq)
{
    // LAB6: YOUR CODE
    //学号：2311050
    // 初始化运行队列链表 run_list
    list_init(&(rq->run_list));
    // 初始化进程数为 0
    rq->proc_num = 0;
}

/*
 * RR_enqueue inserts the process ``proc'' into the tail of run-queue
 * ``rq''. The procedure should verify/initialize the relevant members
 * of ``proc'', and then put the ``run_link'' node into the queue.
 * The procedure should also update the meta data in ``rq'' structure.
 *
 * proc->time_slice denotes the time slices allocation for the
 * process, which should set to rq->max_time_slice.
 *
 * hint: see libs/list.h for routines of the list structures.
 */
static void
RR_enqueue(struct run_queue *rq, struct proc_struct *proc)
{
    // LAB6: YOUR CODE
    //学号：2311050
    // 确保进程不在其他队列中
    assert(list_empty(&(proc->run_link)));
    
    // 将进程加入到运行队列的队尾
    // list_add_before(head, elem) 相当于在 head 之前插入，即链表的最后一个位置
    list_add_before(&(rq->run_list), &(proc->run_link));
    
    // 如果进程的时间片用完或为0，将其重置为最大时间片
    // 注意：rq->max_time_slice 是在 sched_init 中设置的默认时间片
    if (proc->time_slice == 0 || proc->time_slice > rq->max_time_slice) {
        proc->time_slice = rq->max_time_slice;
    }
    
    // 更新进程所属的运行队列
    proc->rq = rq;
    // 运行队列进程数加 1
    rq->proc_num++;
}

/*
 * RR_dequeue removes the process ``proc'' from the front of run-queue
 * ``rq'', the operation would be finished by the list_del_init operation.
 * Remember to update the ``rq'' structure.
 *
 * hint: see libs/list.h for routines of the list structures.
 */
static void
RR_dequeue(struct run_queue *rq, struct proc_struct *proc)
{
    // LAB6: YOUR CODE
    //学号：2311050
    // 验证进程确实在该队列中
    assert(!list_empty(&(proc->run_link)) && proc->rq == rq);
    
    // 从链表中移除
    list_del_init(&(proc->run_link));
    
    // 运行队列进程数减 1
    rq->proc_num--;
}

/*
 * RR_pick_next picks the element from the front of ``run-queue'',
 * and returns the corresponding process pointer. The process pointer
 * would be calculated by macro le2proc, see kern/process/proc.h
 * for definition. Return NULL if there is no process in the queue.
 *
 * hint: see libs/list.h for routines of the list structures.
 */
static struct proc_struct *
RR_pick_next(struct run_queue *rq)
{
    // LAB6: YOUR CODE
    //学号：2311050
    // 获取链表头部的第一个节点
    list_entry_t *le = list_next(&(rq->run_list));
    
    // 如果队列不为空（下一个节点不是头节点本身）
    if (le != &(rq->run_list)) {
        // 使用宏 le2proc 将链表节点转换为进程结构体指针
        return le2proc(le, run_link);
    }
    
    // 队列为空
    return NULL;
}

/*
 * RR_proc_tick works with the tick event of current process. You
 * should check whether the time slices for current process is
 * exhausted and update the proc struct ``proc''. proc->time_slice
 * denotes the time slices left for current process. proc->need_resched
 * is the flag variable for process switching.
 */
static void
RR_proc_tick(struct run_queue *rq, struct proc_struct *proc)
{
    // LAB6: YOUR CODE
    //学号：2311050
    // 如果时间片大于 0，则递减
    if (proc->time_slice > 0) {
        proc->time_slice--;
    }
    
    // 如果时间片耗尽，设置 need_resched 标志，通知操作系统进行调度
    if (proc->time_slice == 0) {
        proc->need_resched = 1;
    }
}

struct sched_class default_sched_class = {
    .name = "RR_scheduler",
    .init = RR_init,
    .enqueue = RR_enqueue,
    .dequeue = RR_dequeue,
    .pick_next = RR_pick_next,
    .proc_tick = RR_proc_tick,
};
