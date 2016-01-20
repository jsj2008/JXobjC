/* Copyright (c) 2016 D. Mackay. All rights reserved. */

#ifndef IVAR_H_
#define IVAR_H_

typedef struct objC_iVar_s
{
    const char * name;
    const char * type;
    /* This is set by the compiler to the offset from the start of the object's
     * iVars. It is refined by the runtime: it becomes the offset from the start
     * of the object in memory. */
    int offset;
} objC_iVar;

typedef struct objC_iVarList_s
{
    int count;
    objC_iVar list[];
} objC_iVarList;

#endif