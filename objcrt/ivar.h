/* Copyright (c) 2016 D. Mackay. All rights reserved. */

#ifndef IVAR_H_
#define IVAR_H_

#include "objcrt.h"
#include "access.h"

#define _Paddingofi(_Siz, _Offs) (_Siz - (_Offs % _Siz)) % _Siz
#define _Paddingof(_Typ, _Offs)                                                \
    (_Alignof(_Typ) - (_Offs % _Alignof(_Typ))) % _Alignof(_Typ)

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

    if (aCls->clsSuper)
        tally += ClassIVarsTotalOffset (aCls->clsSuper, set);
    else
        tally += ismeta (aCls)
                     ? (sizeof (struct _SHARED) - sizeof (struct _PRIVATE))
                     : 0;
    if (set)
    {
        aCls->clsIVarsOffset = tally;
        // aCls->clsSizInstance = tally + myIvars;
        if (lst->count)
        {
            printf (KULN KBLD "***  IVar report for class %s  ***\n" KNRM KBLD
                              "%-16s%-18s%-8s\n" KNRM,
                    aCls->clsName, "Type", "Name", "Offset");
            for (int i = 0; i < lst->count; i++)
            {
                objC_iVar * iV = IVarInList (lst, i);
                size_t siz     = iV->size;

                if (siz > 1)
                    myIvars += _Paddingofi (siz, myIvars);

                iV->final_offset = myIvars + tally;

                printf (KRED "%-16s" KBLU KBLD "%-18s" KNRM "%-8d\n", iV->type,
                        iV->name, iV->final_offset);

                myIvars += siz;
            }
            printf (KULN KBLD "***  End of IVar report  ***\n" KNRM);
        }

        myIvars += _Paddingof (void *, myIvars);

        printf (
            "Tally: %d\tivars: %d\tTtl %d\tcompiler generated %d\tClass: %s\n",
            tally, myIvars, tally + myIvars, aCls->clsSizInstance,
            aCls->clsName);
    }

    return tally + myIvars;
}

void objC_compute_ivar_offsets (Cls_t * cls);
uintptr_t objC_compute_and_set_class_instance_size (Cls_t * cls);

#endif