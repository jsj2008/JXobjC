/* Copyright (c) 2016 D. Mackay. All rights reserved. */

#include <string.h>

#include "objc-ivar.h"
#include "ivar.h"

void * JX_getIVarAddress (id obj, const char * iVarName)
{
    Cls_t aCls;
    objC_iVarList * lst;

    if (!obj)
        return 0;

    aCls = getcls (obj);
    lst  = clsivlist (aCls);

search:
    if (lst->count)
        for (int i = 0; i < lst->count; i++)
        {
            objC_iVar * iV = IVarInList (lst, i);
            if (!strcmp (iV->name, iVarName))
                return (((char *)obj) + iV->final_offset);
        }

    if (aCls->clsSuper && (Cls_t)aCls->clsSuper != aCls)
    {
        aCls = (Cls_t)aCls->clsSuper;
        goto search;
    }
    else
        return 0;
}