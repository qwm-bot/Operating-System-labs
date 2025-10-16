#include <pmm.h>
#include <buddy_pmm.h>
#include <memlayout.h>
#include <string.h>
#include <stdio.h>

/*
 * 实验用简易伙伴分配器实现
 * - 单位：页（PGSIZE）
 * - 管理大小为2^k页的块，k ∈ [0, MAX_ORDER)
 * - 使用free_area[k]数组存储大小为(1<<k)页的空闲块
 * - 页面描述符使用flags标记空闲块头(PG_property)，property记录块大小
 */

#define MAX_ORDER 15 /* 支持最大2^15页（大内存）；会被npage限制 */

typedef struct buddy_area {
    list_entry_t free_list; /* 链表头 */
    size_t nr_free;        /* 该阶数下的空闲页数 */
} buddy_area_t;

static buddy_area_t buddy_areas[MAX_ORDER];
static size_t buddy_max_order = 0; /* 实际使用的最大阶数 */

/* 辅助函数：计算满足2^k ≥ n的最小k值 */
static int order_of(size_t n) {
    int k = 0;
    size_t sz = 1;
    while (sz < n) {
        sz <<= 1;
        k++;
    }
    return k;
}

/* 辅助函数：计算块起始页的索引（相对于pages数组） */
static size_t page_index(struct Page *p) {
    return (size_t)(p - pages);
}

/* 辅助函数：查找阶数为k的块的伙伴页 */
static struct Page *buddy_of(struct Page *base, int k) {
    size_t idx = page_index(base);
    size_t block_size = 1UL << k; /* 页数 */
    size_t buddy_idx = idx ^ block_size;
    if (buddy_idx >= npage) return NULL;
    return &pages[buddy_idx];
}

static void buddy_init(void) {
    for (size_t i = 0; i < MAX_ORDER; i++) {
        list_init(&buddy_areas[i].free_list);
        buddy_areas[i].nr_free = 0;
    }
}

/* 初始化内存映射：将[base, base+n)页区域作为最大对齐块插入伙伴列表 */
static void buddy_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    /* 初始标记页面为非保留，引用计数清零 */
    for (size_t i = 0; i < n; i++) {
        struct Page *p = base + i;
        assert(PageReserved(p));
        p->flags = 0;
        set_page_ref(p, 0);
        p->property = 0;
    }

    /* 作为最大伙伴对齐块插入 */
    size_t i = 0;
    while (i < n) {
        /* 全局页索引 */
        struct Page *p = base + i;
        size_t global_idx = page_index(p);
        /* 找到最大的阶数使块适合区域且对齐 */
        int k = 0;
        size_t max_fit = 1;
        while ((global_idx % (max_fit << 1)) == 0 && i + (max_fit << 1) <= n) {
            max_fit <<= 1;
            k++;
            if ((size_t)k + 1 >= MAX_ORDER) break;
        }
        /* 现在max_fit = 2^k页 */
        p->property = max_fit;
        SetPageProperty(p);
        list_add(&buddy_areas[k].free_list, &p->page_link);
        buddy_areas[k].nr_free += max_fit;
        i += max_fit;
    }

    /* 基于总页数计算buddy_max_order */
    size_t total_pages = npage - nbase;
    buddy_max_order = 0;
    size_t s = 1;
    while (s < total_pages && buddy_max_order + 1 < MAX_ORDER) { s <<= 1; buddy_max_order++; }
}

/* 分配>=n页：找到最小阶数的块>=n，必要时分裂 */
static struct Page *buddy_alloc_pages(size_t n) {
    assert(n > 0);
    /* 找到阶数k使块大小>=n */
    int k = order_of(n);
    int j = k;
    while (j < MAX_ORDER) {
        if (!list_empty(&buddy_areas[j].free_list)) break;
        j++;
    }
    if (j >= MAX_ORDER) return NULL; /* 无可用块 */
    /* 从阶数j取一个块 */
    list_entry_t *le = list_next(&buddy_areas[j].free_list);
    struct Page *p = le2page(le, page_link);
    list_del(&p->page_link);
    size_t block_size = 1UL << j;
    buddy_areas[j].nr_free -= block_size;
    ClearPageProperty(p);
    /* 分裂到阶数k */
    while (j > k) {
        j--;
        /* 后半部分成为阶数j的空闲块 */
        struct Page *half = p + (1UL << j);
        half->property = 1UL << j;
        SetPageProperty(half);
        list_add(&buddy_areas[j].free_list, &half->page_link);
        buddy_areas[j].nr_free += (1UL << j);
    }
    /* 标记返回块为已分配：已清除PG_property；设置ref=0 */
    set_page_ref(p, 0);
    return p;
}

/* 释放页面：将块重新插入并尝试与伙伴合并 */
static void buddy_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    /* 规范化：我们将释放大小为向上取整到2的幂的一个块 */
    int k = order_of(n);
    size_t block_size = 1UL << k;
    /* 如果n不是2的幂，我们将从base向上释放为2的幂的块 */
    size_t off = 0;
    while (off < n) {
        /* 剩余大小 */
        size_t remaining = n - off;
        int cur_k = order_of(remaining);
        struct Page *cur = base + off;
        size_t gidx = page_index(cur);
        while ((gidx & ((1UL << cur_k) - 1)) != 0) {
            cur_k--;
        }
        size_t cur_size = 1UL << cur_k;
        /* 在阶数cur_k插入大小为cur_size的块并尝试合并 */
        struct Page *blk = cur;
        blk->property = cur_size;
        SetPageProperty(blk);
        /* 尝试向上合并 */
        int pk = cur_k;
        while (pk + 1 < MAX_ORDER) {
            struct Page *buddy = buddy_of(blk, pk);
            if (buddy == NULL) break;
            if (!PageProperty(buddy) || buddy->property != (1UL << pk)) break;
            /* 伙伴空闲且大小相同：从空闲列表移除伙伴并合并 */
            list_del(&buddy->page_link);
            buddy_areas[pk].nr_free -= (1UL << pk);
            /* 清理旧的头部标志，确保只有合并后的新头保留PG_property */
            ClearPageProperty(buddy);
            ClearPageProperty(blk);
            /* 选择新的基址为min(blk, buddy) */
            if (buddy < blk) blk = buddy;
            pk++;
        }
        /* 最终设置新头并将blk插入阶数pk的空闲列表 */
        blk->property = 1UL << pk;
        SetPageProperty(blk);
        list_add(&buddy_areas[pk].free_list, &blk->page_link);
        buddy_areas[pk].nr_free += (1UL << pk);
        off += cur_size;
    }
}

static size_t buddy_nr_free_pages(void) {
    size_t total = 0;
    for (size_t i = 0; i < MAX_ORDER; i++) total += buddy_areas[i].nr_free;
    return total;
}

static void buddy_check(void) {
    size_t initial_free = nr_free_pages();

    cprintf("[Buddy 测试] 初始可用页数: %lu\n", initial_free);

for (int i = 0; i < MAX_ORDER; i++) {
            cprintf("[Buddy] 阶 %d (块大小 %lu 页) — nr_free(页数) = %lu\n", i, 1UL << i, buddy_areas[i].nr_free);
            list_entry_t *le = &buddy_areas[i].free_list;
            int idx = 0;
            while ((le = list_next(le)) != &buddy_areas[i].free_list) {
                struct Page *p = le2page(le, page_link);
                cprintf(" 块 %d: 页索引=%lu, 物理地址=0x%016lx, property=%u\n", idx++, page_index(p), page2pa(p), p->property);
            }
}

    /* 单页分配/释放测试 */
    cprintf("[Buddy 测试] 单页分配/释放测试开始\n");
    struct Page *p0 = alloc_page();
    struct Page *p1 = alloc_page();
    struct Page *p2 = alloc_page();
    assert(p0 && p1 && p2);
    assert(p0 != p1 && p0 != p2 && p1 != p2);
    cprintf("  分配到页索引: %lu, %lu, %lu\n", page_index(p0), page_index(p1), page_index(p2));
    assert(nr_free_pages() == initial_free - 3);
    free_page(p0);
    free_page(p1);
    free_page(p2);
    assert(nr_free_pages() == initial_free);
    cprintf("[Buddy 测试] 单页测试通过\n");

    /* 多页分配/释放测试 */
    cprintf("[Buddy 测试] 多页分配/释放测试开始\n");
    struct Page *pa4 = alloc_pages(4);
    struct Page *pb2 = alloc_pages(2);
    assert(pa4 && pb2);
    cprintf("  分配 4 页起始页索引=%lu, 2 页起始页索引=%lu\n", page_index(pa4), page_index(pb2));
    assert(nr_free_pages() == initial_free - (4 + 2));
    free_pages(pa4, 4);
    free_pages(pb2, 2);
    assert(nr_free_pages() == initial_free);
    cprintf("[Buddy 测试] 多页测试通过\n");

    /* 分割与合并验证 */
    cprintf("[Buddy 测试] split/merge 测试开始\n");
    if (initial_free >= 8) {
        struct Page *p8 = alloc_pages(8);
        assert(p8 != NULL);
        cprintf("  分配 8 页起始页索引=%lu\n", page_index(p8));
        free_pages(p8, 8);

        struct Page *a = alloc_pages(4);
        struct Page *b = alloc_pages(4);
        assert(a && b && a != b);
        cprintf("  分配到两个 4 页块: %lu, %lu\n", page_index(a), page_index(b));
        for (int i = 0; i < MAX_ORDER; i++) {
            cprintf("[Buddy] 阶 %d (块大小 %lu 页) — nr_free(页数) = %lu\n", i, 1UL << i, buddy_areas[i].nr_free);
            list_entry_t *le = &buddy_areas[i].free_list;
            int idx = 0;
            while ((le = list_next(le)) != &buddy_areas[i].free_list) {
                struct Page *p = le2page(le, page_link);
                cprintf(" 块 %d: 页索引=%lu, 物理地址=0x%016lx, property=%u\n", idx++, page_index(p), page2pa(p), p->property);
            }
}
        free_pages(a, 4);
        free_pages(b, 4);
        struct Page *p8b = alloc_pages(8);
        assert(p8b != NULL);
        cprintf("  合并后再次分配 8 页起始页索引=%lu\n", page_index(p8b));
        free_pages(p8b, 8);
        assert(nr_free_pages() == initial_free);
    }
    cprintf("[Buddy 测试] split/merge 测试通过\n");

    cprintf("[Buddy 测试] 结束，可用页数: %lu\n", nr_free_pages());

    /* 边界：请求超过总页数应该返回 NULL */
    assert(alloc_pages(npage + 1) == NULL);
}

const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check,
};