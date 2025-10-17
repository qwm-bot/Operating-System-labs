#ifndef __KERN_MM_SLUB_H__
#define __KERN_MM_SLUB_H__

#include <defs.h>
#include <pmm.h>

/* 初始化 SLUB 分配器 */
void slub_init(void);

/* 分配一个大小为 size 字节的对象 */
void *slub_alloc(size_t size);

/* 释放一个由 slub_alloc 分配的对象 */
void slub_free(void *objp, size_t size);

#endif /* !__KERN_MM_SLUB_H__ */

