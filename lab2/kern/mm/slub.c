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
    int idx = size_to_index(size);
    if (idx < 0)
        return;
    struct kmem_cache *cache = &caches[idx];

    uintptr_t obj_addr = (uintptr_t)objp;
    uintptr_t page_addr = obj_addr & ~(SLAB_PAGE_SIZE - 1);
    struct slab *sl = (struct slab *)page_addr;

    /* 重新插入 freelist */
    *(void **)objp = sl->freelist;
    sl->freelist = objp;
    sl->inuse--;

    /* 清除 bitmap 位 */
    int idx_bit = ((char *)objp - (char *)sl->obj_base) / cache->obj_size;
    sl->bitmap[idx_bit / 8] &= ~(1 << (idx_bit % 8));

    /* 若 slab 从 full 变为 partial */
    struct slab **p = &cache->slabs_full;
    while (*p && *p != sl)
        p = &(*p)->next;
    if (*p == sl) {
        *p = sl->next;
        sl->next = cache->slabs_partial;
        cache->slabs_partial = sl;
    }

    /* 若 slab 全空，释放页 */
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
