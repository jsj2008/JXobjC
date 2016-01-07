/* Copyright (c) 2016 D. Mackay. All rights reserved. */

#ifndef OBJC_VECTOR_H
#define OBJC_VECTOR_H

#include "objc-defs.h"

extern id (*JX_alloc) (id, unsigned int);    /*allocate a new object */
extern id (*JX_dealloc) (id);                /* deallocate an object */
extern id (*JX_copy) (id, unsigned int);     /* shallow copy an object */
extern id (*JX_error) (id, STR, OC_VA_LIST); /* error handler */

extern id (*JX_cvtToId) (STR);   /* convert string name to class id */
extern SEL (*JX_cvtToSel) (STR); /* convert string to selector */

extern id (*JX_fileIn) (FILE *);
extern BOOL (*JX_fileOut) (FILE *, id);
extern BOOL (*JX_storeOn) (STR, id);
extern id (*JX_readFrom) (STR);
void EXPORT setfilein (id (*f) (FILE *));
void EXPORT setfileout (BOOL (*f) (FILE *, id));

extern id (*JX_showOn) (id, unsigned);

#endif