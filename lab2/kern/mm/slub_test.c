#include <slub.h>
#include <string.h>
#include <stdio.h>

#define TEST_OBJ_NUM 1000

void slub_test(void) {
    cprintf("========== SLUB 测试开始 ==========\n");

    /* 初始化 SLUB */
    slub_init();

    /* 不同大小的对象 */
    size_t sizes[] = {8, 16, 32, 64, 128, 256, 512, 1024, 2048};
    int num_sizes = sizeof(sizes) / sizeof(sizes[0]);

    /* 每种大小都有自己的一组对象 */
    void *objs[num_sizes][TEST_OBJ_NUM / num_sizes];

    /* 测试分配不同大小的对象 */
    cprintf("【阶段1】分配不同大小的对象...\n");
    for (int s = 0; s < num_sizes; s++) {
        size_t sz = sizes[s];
        cprintf("  -> 分配 %lu 字节对象...\n", (unsigned long)sz);
        for (int i = 0; i < TEST_OBJ_NUM / num_sizes; i++) {
            objs[s][i] = slub_alloc(sz);
            if (objs[s][i] == NULL) {
                cprintf("    [失败] idx=%d, size=%lu\n", i, (unsigned long)sz);
            } else {
                memset(objs[s][i], 0xA0 + (i & 0xF), sz);
            }
        }
    }

    cprintf("【阶段1】分配完成。\n\n");

    /* 释放部分对象，测试 slab 回到部分使用 */
    cprintf("【阶段2】释放部分对象...\n");
    for (int s = 0; s < num_sizes; s++) {
        size_t sz = sizes[s];
        for (int i = 0; i < (TEST_OBJ_NUM / num_sizes) / 2; i++) {
            if (objs[s][i]) {
                slub_free(objs[s][i], sz);
                objs[s][i] = NULL;
            }
        }
        cprintf("  -> 释放 %lu 字节对象的一半完成。\n", (unsigned long)sz);
    }
    cprintf("【阶段2】部分释放完成。\n\n");

    /* 再次分配对象，测试复用空闲 slab */
    cprintf("【阶段3】再次分配对象，测试复用...\n");
    for (int s = 0; s < num_sizes; s++) {
        size_t sz = sizes[s];
        for (int i = 0; i < (TEST_OBJ_NUM / num_sizes) / 4; i++) {
            void *ptr = slub_alloc(sz);
            if (ptr == NULL) {
                cprintf("    [复用失败] size=%lu idx=%d\n", (unsigned long)sz, i);
            } else {
                memset(ptr, 0x5A, sz);
            }
        }
    }
    cprintf("【阶段3】复用测试完成。\n\n");

    /* 全部释放，测试 slab 是否回收页 */
    cprintf("【阶段4】释放所有对象...\n");
    for (int s = 0; s < num_sizes; s++) {
        size_t sz = sizes[s];
        for (int i = 0; i < TEST_OBJ_NUM / num_sizes; i++) {
            if (objs[s][i]) {
                slub_free(objs[s][i], sz);
                objs[s][i] = NULL;
            }
        }
        cprintf("  -> %lu 字节对象释放完毕。\n", (unsigned long)sz);
    }
    cprintf("【阶段4】全部释放完成。\n\n");

    /* 测试超过最大对象 */
    cprintf("【阶段5】测试超过最大对象...\n");
    void *bigobj = slub_alloc(4096);
    if (bigobj == NULL) {
        cprintf(" 分配大对象失败（正确行为）\n");
    } else {
        cprintf(" 分配大对象成功（错误！）\n");
    }

    /* 测试释放 NULL 指针 */
    cprintf("【阶段6】测试释放 NULL 指针...\n");
    slub_free(NULL, 16);
    cprintf("  释放 NULL 安全。\n");

    cprintf("========== SLUB 测试结束 ==========\n");
}

/* 用于 init.c 调用 */
int slub(void) {
    slub_test();
    return 0;
}
