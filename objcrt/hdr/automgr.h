/*
 * Automgr Tracing GC for JX Objective-C
 * Copyright (c) 2015 D. Mackay. All rights reserved.
 * Use is subject to licence terms.
 */

#ifndef AUTOMGR__H_
#define AUTOMGR__H_

#import "objcrt.h"

void * AMGR_init_pre_thrd (void * stkBegin);
void AMGR_init_post_thrd (void * mgr);
void AMGR_main_init (void * stkBegin);
void AMGR_enable ();
void AMGR_disable ();

void AMGR_add_zone (void * start, size_t length, BOOL isRoot, BOOL isCopy,
                    BOOL isObject);
void AMGR_remove_zone (void * location);
void AMGR_remove_all_zones ();

void * AMGR_alloc (size_t bytes);
void * AMGR_oalloc (size_t bytes);
void * AMGR_calloc (size_t num, size_t bytes);
void * AMGR_realloc (void * location, size_t newBytes);
void AMGR_free (void * location);

void AMGR_cycle ();

#endif