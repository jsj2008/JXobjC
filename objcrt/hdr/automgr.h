/*
 * Automgr Tracing GC for JX Objective-C
 * Copyright (c) 2015 D. Mackay. All rights reserved.
 * Use is subject to licence terms.
 */

#ifndef AUTOMGR__H_
#define AUTOMGR__H_

#import "objcrt.h"

void AMGR_init_thrd (void * stkBegin);
void AMGR_main_init (void * stkBegin);
void AMGR_add_zone (void * start, size_t length, BOOL isRoot, BOOL isCopy,
                    BOOL isObject);
void AMGR_remove_zone (void * location);


#endif