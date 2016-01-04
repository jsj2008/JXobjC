/* Copyright (c) 2016 D. Mackay. All rights reserved. */

#ifndef OBJC_MEMORY_H
#define OBJC_MEMORY_H

extern id outOfMem;

extern id (*JX_alloc) (id, unsigned int);
extern id (*JX_copy) (id, unsigned int);
extern id (*JX_dealloc) (id);

#endif