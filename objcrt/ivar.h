/* Copyright (c) 2016 D. Mackay. All rights reserved. */

#ifndef IVAR_H_
#define IVAR_H_

#include "objcrt.h"
#include "access.h"

/*
  The objC_iVar and objC_iVarList types are emitted in trlunit.m.
  Here is a reference:
      typedef struct objC_iVar_s
      {
        const char * name;
        const char * type;
        int offset, final_offset;
      } objC_iVar;

      typedef struct objC_iVarList_s
      {
        int count;
        objC_iVar (*list)[];
      } objC_iVarList;
 */

#define IVarInList(aList, index) (&(*((objC_iVarList *)aList)->list)[index])

INLINE ptrdiff_t ClassIVarsTotalOffset (id cls, BOOL set)
{
    Cls_t aCls      = getcls (cls);
    ptrdiff_t tally = 0, myIvars = 0;
    objC_iVarList * lst = clsivlist (aCls);

    for (int i = 0; i < lst->count; i++)
        myIvars += IVarInList (lst, i)->offset;

    if (aCls->clsSuper)
        tally += ClassIVarsTotalOffset (aCls->clsSuper, set);
    else
        tally +=
            ismeta (aCls) ? sizeof (struct _SHARED) : sizeof (struct _PRIVATE);

    if (set)
    {
        aCls->clsSizInstance = tally + myIvars;
        for (int i = 0; i < lst->count; i++)
            IVarInList (lst, i)->final_offset =
                IVarInList (lst, i)->offset + tally;
        aCls->clsIVarsOffset = tally;
    }

    return tally + myIvars;
}

void objC_compute_ivar_offsets (Cls_t * cls);
uintptr_t objC_compute_and_set_class_instance_size (Cls_t * cls);

#endif