# lab2：物理内存和页表
## 练习1：理解first-fit 连续物理内存分配算法（思考题）
>first-fit 连续物理内存分配算法作为物理内存分配一个很基础的方法，需要同学们理解它的实现过程。请大家仔细阅读实验手册的教程并结合kern/mm/default_pmm.c中的相关代码，认真分析default_init，default_init_memmap，default_alloc_pages， default_free_pages等相关函数，并描述程序在进行物理内存分配的过程以及各个函数的作用。 请在实验报告中简要说明你的设计实现过程。请回答如下问题：你的first fit算法是否有进一步的改进空间？

first-fit连续物理内存分配算法：分配时从空闲块链表中找到第一个足够大的空闲块进行分配；释放时将释放的块重新加入空闲链表，并合并相邻空闲块。
### 函数实现分析
#### (1)default_init()
```c
static void
default_init(void) {
    list_init(&free_list);// 初始化双向链表
    nr_free = 0;// 空闲页计数器清零
}
```
该函数首先调用list_init函数来初始化一个空的双向链表free_list，然后定义了nr_free空闲块的个数定义为0。用于初始化存放空闲块的链表。
#### (2) default_init_memmap()
```c
static void
default_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);//判定n大于0，如果为0不需要存放页面
    struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(PageReserved(p));// 确保页面是保留状态
        p->flags = p->property = 0;// 初始化标志位和属性，之后页面可以被分配
        set_page_ref(p, 0);// 引用计数清零
    }
    base->property = n;// 设置第一页的块大小
    SetPageProperty(base); // 标记为有效空闲块
    nr_free += n;// 更新空闲页总数
    // 将空闲块插入链表（按地址升序）
    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {//如果新页面起始地址小于当前遍历到的页面地址，说明找到正确插入位置
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
            }
        }
    }
}
```
该函数初始化一段连续物理内存页，将其标记为空闲块并插入链表。
base是指向这段连续物理内存的起始页结构体；n需要初始化的连续物理页面的总数。首先判定n是否大于0，如果=0不需要存放页面；再遍历所有页，初始化标志位和引用计数；设置第一页的 property为块大小n，并标记为有效后按地址升序插入空闲链表。如果链表为空直接链入链表；否则遍历链表直到新页面起始地址小于当前遍历到的页面地址，说明找到正确插入位置，在该页面之前插入新的链表节点(list_add_before函数)；如果遍历完链表也没有找到这样的页面，则将新的链表节点添加到链表末尾 (list_add函数)。
```c
//libs/list.h
static inline void
list_add_before(list_entry_t *listelm, list_entry_t *elm) {
    __list_add(elm, listelm->prev, listelm);
}
static inline void
list_add(list_entry_t *listelm, list_entry_t *elm) {
    list_add_after(listelm, elm);
}
```
#### (3)default_alloc_pages()
```c
static struct Page *
default_alloc_pages(size_t n) {
    assert(n > 0);
    if (n > nr_free) {
        return NULL;// 检查是否有足够空闲页
    }
    struct Page *page = NULL;
    list_entry_t *le = &free_list;
    // 遍历链表，找到第一个大小 >=n 的块
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        if (p->property >= n) {
            page = p;
            break;
        }
    }
    if (page != NULL) {//找到大小 >=n 的块
        list_entry_t* prev = list_prev(&(page->page_link));// 从链表中移除该块
        list_del(&(page->page_link));
        if (page->property > n) {
            // 分割剩余部分
            struct Page *p = page + n;
            p->property = page->property - n;
            SetPageProperty(p);
            list_add(prev, &(p->page_link));// 将剩余块重新插入链表
        }
        nr_free -= n;
        ClearPageProperty(page);// 清除分配页的有效标志
    }
    return page;
}
```
该函数用于分配n个连续的物理页。
首先检查是否有足够的空闲页（n <= nr_free）；然后遍历空闲链表，找到第一个大小 ≥ n的块；若找到的块大于需求，分割剩余部分并重新插入链表；最后更新空闲页计数，并返回分配的内存首地址。
#### (4)default_free_pages()
```c
static void
default_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(!PageReserved(p) && !PageProperty(p));//被释放的页不能是保留页，不能是已空闲页
        p->flags = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
    SetPageProperty(base);
    nr_free += n;
    // 按地址升序插入链表
    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
            }
        }
    }
    // 尝试合并低地址相邻块
    list_entry_t* le = list_prev(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (p + p->property == base) {
            p->property += base->property;
            ClearPageProperty(base);
            list_del(&(base->page_link));
            base = p;
        }
    }
    // 尝试合并高地址相邻块
    le = list_next(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (base + base->property == p) {
            base->property += p->property;
            ClearPageProperty(p);
            list_del(&(p->page_link));
        }
    }
}
```
该函数用于释放 n个连续的物理页，并尝试合并相邻空闲块。
首先初始化要释放的页并更新全局空闲页计数；再按地址升序插入空闲链表；检查前后相邻块是否连续，若连续则合并。
#### (5)其他函数
- **default_nr_free_pages()：** 返回当前系统中空闲物理页的总数，供测试函数验证内存管理的正确性。
- **basic_check()：** 基础测试函数，首先分配3个页面，验证分配成功且互不相同；临时清空空闲链表，验证此时无法分配新页面；释放之前分配的页面，验证空闲计数正确；重新分配页面，验证能获取到刚释放的页面。
- **default_check()：** 复杂测试函数，首先分配5个页面，然后释放其中3个页面，验证能否正确分配这3个页面；测试与相邻空闲块的合并功能；验证分配大块连续内存的能力；最终验证所有内存都被正确回收。
#### (6)结构体default_pmm_manager
default_pmm_manager是 First-Fit 内存管理器的接口实例，封装算法核心操作。这样内核其他模块只需调用 pmm_manager->alloc_pages()，而无需关心底层是 First-Fit 还是其他算法。
#### (7)工作流程总结（操作系统物理内存管理）
系统启动时首先通过 default_init 初始化内存管理器，通过 default_init_memmap 将可用内存加入管理；当需要内存时调用 default_alloc_pages 进行分配；当释放内存时调用 default_free_pages 回收内存并尝试合并；通过 default_check 等函数验证分配器的正确性。
### 改进空间
#### 使用更高效的数据结构
- 当前使用双向链表管理空闲块，查找时间复杂度为 O(n)。
- 可以使用平衡二叉搜索树或跳表，使查找时间复杂度降至 O(log n)。
#### 缓存最近分配的块
- 现在连续分配相似大小的块时，每次都要从头遍历链表。
- 可以记录上次分配的块地址，下次分配时优先检查其相邻空间。
#### 合并策略优化
- 现在仅在释放时合并相邻块，可能遗留小碎片。
- 可以定期全局合并，在内存碎片达到阈值时，主动扫描并合并所有空闲块。
#### 块分裂策略调整
- 当前直接按请求大小分割，可能产生无用的小块。
- 可以改为仅当剩余块大于某个阈值时才分裂，否则整块分配。
## 练习2
## 扩展练习Challenge：buddy system（伙伴系统）分配算法（需要编程）
>Buddy System算法把系统中的可用存储空间划分为存储块(Block)来进行管理, 每个存储块的大小必须是2的n次幂(Pow(2, n)), 即1, 2, 4, 8, 16, 32, 64, 128...参考伙伴分配器的一个极简实现， 在ucore中实现buddy system分配算法，要求有比较充分的测试用例说明实现的正确性，需要有设计文档。

## 扩展练习Challenge
## 扩展练习Challenge：硬件的可用物理内存范围的获取方法（思考题）
> 如果 OS 无法提前知道当前硬件的可用物理内存范围，请问你有何办法让 OS 获取可用物理内存范围？
- **手工探测物理内存** 我们可以借鉴一下在没有SPD时，CPU探测内存条的相关信息的办法。向一块连续的区域上写入0x55，然后读取这一片区域的数据判断是否与写入的数据一致，然后再向这一片区域内写入0xAA,然后同样读取这片区域的数据判断是否和写入的一致，如果两次数据都一致，说明这块区域中的0和1是可以被程序员操纵的，大概率是一块内存。操作系统经过大范围这样的扫描，可以得到可用物理内存范围（但不一定百分百准确）。
## 实验中重要知识点
1. > 操作系统是怎样知道当前硬件的可用内存物理范围的？

- 在RISC-V中，由**OpenSBI**来完成。OpenSBI完成对于包括物理内存在内的各外设的扫描，将扫描结果以**DTB**的格式保存在物理内存中的某个地方，随后OpenSBI会将其地址保存在`a1`寄存器中。在操作系统的内核代码中，会从`a1`寄存器中读取设备树数据的存储地址，并将设备树数据读取出来，保存到全局变量`boot_dtb`中，后续利用`dtb_init`函数来读取设备树结构中存储的相关信息。
## 实验未涉及知识点
