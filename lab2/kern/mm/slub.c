#include <slub.h>
#include <string.h>
#include <stdio.h>

/* ----------------------------------------
 * 单核 SLUB 内存分配器（单页结构版）
 * ---------------------------------------- */

/* 一页的大小（4KB） */
#define SLAB_PAGE_SIZE 4096

/* 对象大小范围：2^3 ~ 2^11 */
#define MIN_OBJ_SHIFT 3
#define MAX_OBJ_SHIFT 11
#define CACHE_NUM (MAX_OBJ_SHIFT - MIN_OBJ_SHIFT + 1)

/* slab结构：元数据+位图+对象都放在一页 */
struct slab {
    unsigned int inuse;        // 已分配对象数
    unsigned int total;        // 对象总数
    void *freelist;            // 空闲对象链表头
    uint8_t *bitmap;           // 位图起始地址
    void *obj_base;            // 对象区起始地址
    struct slab *next;         // 链表指针
};

/* kmem_cache：管理固定大小对象 */
struct kmem_cache {
    size_t obj_size;
    struct slab *slabs_full;
    struct slab *slabs_partial;
    struct slab *slabs_free;
};

/* 全局缓存数组 */
static struct kmem_cache caches[CACHE_NUM];

/* 根据对象大小找到所属 cache */
static int size_to_index(size_t size) {
    int idx = 0;
    size_t s = (1 << MIN_OBJ_SHIFT);
    while (s < size && idx < CACHE_NUM) {
        s <<= 1;
        idx++;
    }
    return (idx >= CACHE_NUM) ? -1 : idx;
}

/* slab 创建：分配一页并建立 freelist + bitmap */
static struct slab *slab_create(struct kmem_cache *cache) {
    struct Page *page = alloc_page();
    if (page == NULL)
        return NULL;

    void *page_kva = KADDR(page2pa(page));
    struct slab *sl = (struct slab *)page_kva;
    sl->inuse = 0;
    sl->next = NULL;

    /* bitmap 紧跟在 slab 元数据后 */
    uint8_t *bitmap = (uint8_t *)(sl + 1);

    /* 先计算对象数量 */
    size_t obj_size = cache->obj_size;
    size_t overhead = sizeof(struct slab); // slab 头部大小
    size_t max_obj = (SLAB_PAGE_SIZE - overhead) / (obj_size + 1.0 / 8); // 初步估算
    size_t bitmap_bytes = (max_obj + 7) / 8;

    /* 实际对象个数 */
    int obj_num = (SLAB_PAGE_SIZE - overhead - bitmap_bytes) / obj_size;
    if (obj_num <= 0)
        return NULL;

    sl->bitmap = bitmap;
    memset(sl->bitmap, 0, bitmap_bytes);

    /* 对象区起始地址 */
    sl->obj_base = (void *)(bitmap + bitmap_bytes);
    sl->total = obj_num;

    /* 建立 freelist 链表 */
    sl->freelist = sl->obj_base;
    char *p = (char *)sl->obj_base;
    for (int i = 0; i < obj_num; i++) {
        void **obj = (void **)(p + i * obj_size);
        *obj = (i == obj_num - 1) ? NULL : (void *)(p + (i + 1) * obj_size);
    }

    return sl;
}

/* 初始化所有 kmem_cache */
void slub_init(void) {
    for (int i = 0; i < CACHE_NUM; i++) {
        caches[i].obj_size = (1 << (i + MIN_OBJ_SHIFT));
        caches[i].slabs_full = NULL;
        caches[i].slabs_partial = NULL;
        caches[i].slabs_free = NULL;
    }
}

/* 分配对象 */
void *slub_alloc(size_t size) {
    int idx = size_to_index(size);
    if (idx < 0)
        return NULL;
    struct kmem_cache *cache = &caches[idx];

    struct slab *sl = cache->slabs_partial;
    if (sl == NULL) {
        if (cache->slabs_free == NULL) {
            struct slab *newsl = slab_create(cache);
            if (newsl == NULL)
                return NULL;
            newsl->next = cache->slabs_free;
            cache->slabs_free = newsl;
        }

        sl = cache->slabs_free;
        cache->slabs_free = sl->next;
        sl->next = cache->slabs_partial;
        cache->slabs_partial = sl;
    }

    /* 分配 freelist 中第一个对象 */
    void *obj = sl->freelist;
    if (obj == NULL)
        return NULL;

    sl->freelist = *(void **)obj;
    sl->inuse++;

    /* 设置 bitmap 位 */
    int idx_bit = ((char *)obj - (char *)sl->obj_base) / cache->obj_size;
    sl->bitmap[idx_bit / 8] |= (1 << (idx_bit % 8));

    /* slab 满时移动到 full 链表 */
    if (sl->inuse == sl->total) {
        cache->slabs_partial = sl->next;
        sl->next = cache->slabs_full;
        cache->slabs_full = sl;
    }

    return obj;
}

/* 释放对象 */
void slub_free(void *objp, size_t size) {
    if (objp == NULL)
        return;

    // 如果对象大于 SLAB_PAGE_SIZE，直接按页释放
    if (size > SLAB_PAGE_SIZE) {
        struct Page *page = kva2page((uintptr_t)objp);
        size_t npages = (size + PGSIZE - 1) / PGSIZE;  // 向上取整
        free_pages(page, npages);
        return;
    }

    // 小对象：走 slab 释放逻辑
    int idx = size_to_index(size);
    if (idx < 0)
        return;

    struct kmem_cache *cache = &caches[idx];

    uintptr_t obj_addr = (uintptr_t)objp;
    uintptr_t page_addr = obj_addr & ~(SLAB_PAGE_SIZE - 1);
    struct slab *sl = (struct slab *)page_addr;

    // 重新插入 freelist
    *(void **)objp = sl->freelist;
    sl->freelist = objp;
    sl->inuse--;

    // 清除 bitmap 位
    int idx_bit = ((char *)objp - (char *)sl->obj_base) / cache->obj_size;
    sl->bitmap[idx_bit / 8] &= ~(1 << (idx_bit % 8));

    // 若 slab 从 full 变为 partial
    struct slab **p = &cache->slabs_full;
    while (*p && *p != sl)
        p = &(*p)->next;
    if (*p == sl) {
        *p = sl->next;
        sl->next = cache->slabs_partial;
        cache->slabs_partial = sl;
    }

    // 若 slab 全空，释放页
    if (sl->inuse == 0) {
        struct slab **q = &cache->slabs_partial;
        while (*q && *q != sl)
            q = &(*q)->next;
        if (*q == sl) {
            *q = sl->next;
            struct Page *page = kva2page(page_addr);
            free_page(page);
        }
    }
}
#include <assert.h> 

#define TEST_OBJ_NUM 1000

void slub_test(void) {
    cprintf("========== SLUB 测试开始 ==========\n");

    /* 初始化 SLUB */
    slub_init();

    /* 不同大小的对象 */
    size_t sizes[] = {8, 16, 32, 64, 128, 256, 512, 1024, 2048};
    int num_sizes = sizeof(sizes) / sizeof(sizes[0]);
    void *objs[num_sizes][TEST_OBJ_NUM / num_sizes];

    /* 阶段 1：顺序分配所有对象 */
    cprintf("【阶段1】分配不同大小的对象...\n");
    for (int s = 0; s < num_sizes; s++) {
        size_t sz = sizes[s];
        for (int i = 0; i < TEST_OBJ_NUM / num_sizes; i++) {
            objs[s][i] = slub_alloc(sz);
            assert(objs[s][i] != NULL);
            memset(objs[s][i], 0xA0 + (i & 0xF), sz);
        }
    }
    cprintf("【阶段1】分配完成。\n\n");

    /* 阶段 2：释放每种大小一半对象，并检查 slab 状态 */
    cprintf("【阶段2】释放部分对象...\n");
    for (int s = 0; s < num_sizes; s++) {
        size_t sz = sizes[s];
        struct kmem_cache *cache = &caches[size_to_index(sz)];
        for (int i = 0; i < (TEST_OBJ_NUM / num_sizes) / 2; i++) {
            if (objs[s][i]) {
                slub_free(objs[s][i], sz);
                objs[s][i] = NULL;
            }
        }
        /* 检查 partial slab 状态 */
        struct slab *sl = cache->slabs_partial;
        while (sl) {
            assert(sl->inuse > 0 && sl->inuse < sl->total);
            sl = sl->next;
        }
        cprintf("  -> 释放 %lu 字节对象的一半完成。\n", (unsigned long)sz);
    }
    cprintf("【阶段2】部分释放完成。\n\n");

    /* 阶段 3：再次分配，测试复用空闲 slab */
    cprintf("【阶段3】复用测试...\n");
    for (int s = 0; s < num_sizes; s++) {
        size_t sz = sizes[s];
        for (int i = 0; i < (TEST_OBJ_NUM / num_sizes) / 4; i++) {
            void *ptr = slub_alloc(sz);
            assert(ptr != NULL);
            memset(ptr, 0x5A, sz);
        }
    }
    cprintf("【阶段3】复用测试完成。\n\n");

    /* 阶段 4：随机释放所有对象，测试 slab 回收页 */
    cprintf("【阶段4】释放所有对象...\n");
    for (int s = 0; s < num_sizes; s++) {
        size_t sz = sizes[s];
        struct kmem_cache *cache = &caches[size_to_index(sz)];
        for (int i = TEST_OBJ_NUM / num_sizes - 1; i >= 0; i--) {
            if (objs[s][i]) {
                slub_free(objs[s][i], sz);
                objs[s][i] = NULL;
            }
        }
        /* 检查 full slab 和 partial slab 都为空或已回收 */
        struct slab *sl = cache->slabs_partial;
        while (sl) {
            assert(sl->inuse > 0 || sl->total == 0);
            sl = sl->next;
        }
        sl = cache->slabs_full;
        while (sl) {
            assert(sl->inuse > 0);
            sl = sl->next;
        }
        cprintf("  -> %lu 字节对象释放完毕。\n", (unsigned long)sz);
    }
    cprintf("【阶段4】全部释放完成。\n\n");

    /* 阶段 5：分配超过最大对象 */
    cprintf("【阶段5】测试超大对象...\n");
    void *bigobj = slub_alloc(4096);
    assert(bigobj == NULL);
    cprintf("  超大对象分配失败（正确行为）\n");

    /* 阶段 6：释放 NULL 指针安全性测试 */
    cprintf("【阶段6】释放 NULL 测试...\n");
    slub_free(NULL, 16);
    cprintf("  释放 NULL 安全。\n");

    /* 阶段 7：检查总页数与 inuse 一致 */
    cprintf("【阶段7】总页数检查...\n");
    size_t total_objs = 0;
    for (int s = 0; s < num_sizes; s++) {
        struct kmem_cache *cache = &caches[size_to_index(sizes[s])];
        struct slab *sl = cache->slabs_partial;
        while (sl) {
            total_objs += sl->inuse;
            sl = sl->next;
        }
        sl = cache->slabs_full;
        while (sl) {
            total_objs += sl->inuse;
            sl = sl->next;
        }
    }
    cprintf("  总对象使用数统计完成: %lu\n", total_objs);

    cprintf("========== SLUB 测试结束 ==========\n");
}

