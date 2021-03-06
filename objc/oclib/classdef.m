/*
 * Copyright (c) 1998,2000 David Stes.
 *
 * This library is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Library General Public License as published
 * by the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */
/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#include <stdlib.h>
#include <assert.h>
#include <string.h>
#include "Object.h"
#include "Block.h"
#include "OCString.h"
#include "OrdCltn.h"
#include "Set.h"
#include "Dictionary.h"
#include "selector.h"
#include "classdef.h"
#include "trlunit.h"
#include "options.h"
#include "decl.h"
#include "pointer.h"
#include "def.h"
#include "methdef.h"
#include "type.h"
#include "util.h"
#include "expr.h"
#include "msgxpr.h"
#include "structsp.h"
#include "method.h"

id curclassdef;

@implementation ClassDef

- (int)compare:b
{
    int c;
    char *s1, *s2;
    s1 = [self classname];
    s2 = [b classname];
    c  = strcmp (s1, s2);
    return c;
}

- (char *)privtypename { return privtypename; }

- selftype
{
    if (!selftype)
    {
        privStruct = [StructSpec new];

        [privStruct keyw:[Symbol sprintf:"struct"]];
        [privStruct name:[Symbol sprintf:"%s", privtypename]];
        assert (privtypename);
        selftype = [Type new];
        [selftype addspec:privStruct];
        [selftype decl:[Pointer new]];
    }
    return selftype;
}

- (char *)shartypename { return shartypename; }

- (char *)otbtypename { return otbtypename; }

- shartypename:(char *)s
{
    /* the default is _SHARED but may change for cvars */
    shartypename = s;
    return self;
}

+ new { return [[super new] shartypename:"_SHARED"]; }

- warnpending
{
    warn ("definition of %s not properly ended.", [self classname]);
    return self;
}

- classname:(Symbol)sym
{
    char * s;

    assert (classname == nil);
    classname = sym;
    s         = [classname str];
    [trlunit def:sym asclass:self];

    if (o_oneperfile)
    {
        privtypename   = "_PRIVATE";
        clsdisptblname = "_clsDispatchTbl";
        nstdisptblname = "_nstDispatchTbl";
    }
    else
    {
        privtypename   = [[String sprintf:"%s_PRIVATE", s] strCopy];
        clsdisptblname = [[String sprintf:"_%s_clsDispatchTbl", s] strCopy];
        nstdisptblname = [[String sprintf:"_%s_nstDispatchTbl", s] strCopy];
    }
    globfunname     = [[String sprintf:"OBJCCLASS_%s", s] strCopy];
    c_classname     = [[String sprintf:"clsImpl_%s", s] strCopy];
    _classfunname   = [[String sprintf:"OBJCCFUNC_%s", s] strCopy];
    _superfunname   = [[String sprintf:"OBJCCSUPER_%s", s] strCopy];
    _m_classfunname = [[String sprintf:"OBJCMFUNC_%s", s] strCopy];
    _m_superfunname = [[String sprintf:"OBJCMSUPER_%s", s] strCopy];
    _classname      = [[String sprintf:"_%s", s] strCopy];
    _m_classname = [[String sprintf:"__%s", s] strCopy];
    if (o_otb)
    {
        otbtypename = [[String sprintf:"%s_OTB", s] strCopy];
    }
    if ([trlunit lookupstruct:[Symbol sprintf:"%s", privtypename]] == nil)
    {
        id r = [StructSpec new];

        [r keyw:[Symbol sprintf:"struct"]];
        [r name:[Symbol sprintf:"_PRIVATE", privtypename]];
        [trlunit defstruct:r];
        [trlunit def:[String str:s]
              astype:[[[[Type new] addspec:r] ampersand] setIsobject:YES]];
    }

    /* Only actually needed when this is an implementation, not interface. */
    [self declareOffsetTables];

    return self;
}

- checksupername:sym
{
    char * m = "conflicting superclasses %s and %s for %s.";
    char * n = "conflicting superclass declarations for %s.";

    if (sym == nil && supername == nil)
        return self;
    if (sym != nil && supername != nil && [supername isEqual:sym])
        return self;
    if (sym == nil || supername == nil)
    {
        fatal (n, [self classname]);
        return self;
    }
    fatalat (sym, m, [sym str], [supername str], [self classname]);
    return self;
}

- supername:sym
{
    supername = sym;
    if (sym != nil && ((superc = [trlunit lookupclass:sym]) == nil))
    {
        fatal ("cannot find %s superclass of %s", [sym str], [self classname]);
    }
    return self;
}

- (char *)classname { return [classname str]; }

- (char *)globfunname { return globfunname; }

- (char *)c_classname { return c_classname; }

- (char *)_classname { return _classname; }

- (char *)_m_classname { return _m_classname; }

- (char *)_classfunname { return _classfunname; }

- (char *)_m_classfunname { return _m_classfunname; }

- (char *)_superfunname { return _superfunname; }

- (char *)_m_superfunname { return _m_superfunname; }

- (char *)supername { return (supername) ? [supername str] : NULL; }

- superclassdef { return superc; }

- rootclassdef
{
    if (!rootc)
    {
        id p, q;

        p = self;
        while ((q = [p superclassdef]))
        {
            p = q;
        }
        rootc = p;
    }
    return rootc;
}

- (char *)rootname { return [[self rootclassdef] classname]; }

- (int)numidivars
{
    int i, n;
    int count = 0;

    if (ivars)
        for (i = 0, n = [ivars size]; i < n; i++)
        {
            if ([[ivartypes at:i] isid])
                count++;
        }
    return count;
}

- synthrefcntmethods
{
    /* during synth of these methods we temporarily turn refcnt off */
    assert (o_refcnt);
    o_refcnt = 0;

    if (isimpl)
    {
        if (!nstdisptbl || ![nstdispsels find:s_decrefs])
        {
            decrefsmethod = mkdecrefsmeth (curclassdef, ivarnames, ivartypes);
            [decrefsmethod synth];
        }
        if (!nstdisptbl || ![nstdispsels find:s_increfs])
        {
            increfsmethod = mkincrefsmeth (curclassdef, ivarnames, ivartypes);
            [increfsmethod synth];
        }
    }
    o_refcnt++;
    return self;
}

- synthfilermethods
{
    if (isimpl)
    {
        if (!nstdisptbl || ![nstdispsels find:s_fileInIdsFrom])
        {
            fileinmethod = mkfileinmeth (curclassdef, ivarnames, ivartypes);
            [fileinmethod synth];
        }
        if (!nstdisptbl || ![nstdispsels find:s_fileOutIdsFor])
        {
            fileoutmethod = mkfileoutmeth (curclassdef, ivarnames, ivartypes);
            [fileoutmethod synth];
        }
    }
    return self;
}

- synthpropmethods
{
    if (isimpl)
    {
        [propmeths do:
                   { : each |[each synth];
                   }];
    }
    return self;
}

- ivars { return ivars; }

- ivars:aList
{
    ivars = aList;
    return self;
}

- cvars { return cvars; }

- cvars:aList
{
    if (!o_cvars)
        fatal ("class variables not allowed");
    cvars = aList;
    return self;
}

- checkvars:(char *)what:names:types:aList
{
    if (!names)
    {
        char * me = [self classname];

        fatal ("'%s' was previously declared without %s variables", me, what);
    }
    else
    {
        int i, n;
        id outerstruct = curstruct;

        curstruct = self;
        assert (compnames == nil);
        [aList elementsPerform:@selector (synth)];
        assert (compnames != nil);
        curstruct = outerstruct;
        for (i = 0, n = [compnames size]; i < n; i++)
        {
            if (i < [names size])
            {
                id a = [compnames at:i];
                id b = [comptypes at:i];

                /* let's give a precise message explaining what the problem
                 * really is */
                if (![a isEqual:[names at:i]] || ![b isEqual:[types at:i]])
                {
                    int no    = [[names at:i] lineno];
                    char * fn = [[[names at:i] filename] str];
                    char * msg =
                        "%s variable '%s' conflicts with definition at %s:%d";

                    fatalat (a, msg, what, [a str], fn, no);
                }
            }
        }
        if (n != [names size])
        {
            char * me = [self classname];

            fatal ("list of %s variables doesn't match '%s' interface", what,
                   me);
        }
        [self undefcomps];
    }
    return self;
}

- checkivars:aList
{
    return [self checkvars:"instance":ivarnames:ivartypes:aList];
}

- checkcvars:aList
{
    return [self checkvars:"class":cvarnames:cvartypes:aList];
}

- addclsdisp:method
{
    if (!clsdisptbl)
    {
        clsdisptbl  = [OrdCltn new];
        clsdispsels = [Set new];
    }
    assert ([method isKindOf:(id)[MethodDef class]]);
    [clsdisptbl add:method];
    [clsdispsels add:[method selector]];
    return self;
}

- addclssel:method
{
    if (!clssels)
        clssels = [OrdCltn new];
    [clssels add:method];
    assert ([method isKindOf:(id)[Selector class]]);
    return self;
}

- addnstdisp:method
{
    if (!nstdisptbl)
    {
        nstdisptbl  = [OrdCltn new];
        nstdispsels = [Set new];
    }
    assert ([method isKindOf:(id)[MethodDef class]]);
    [nstdisptbl add:method];
    [nstdispsels add:[method selector]];
    return self;
}

- addnstsel:method
{
    if (!nstsels)
        nstsels = [OrdCltn new];
    [nstsels add:method];
    assert ([method isKindOf:(id)[Selector class]]);
    return self;
}

- addMethod:(Method)aMeth
{
    if (!methsForSels)
        methsForSels = [Dictionary new];
    [methsForSels atKey:[aMeth selector] put:aMeth];
    return self;
}

- check:sels includedin:impls factory:(BOOL)f
{
    int i, n;

    for (i = 0, n = [sels size]; i < n; i++)
    {
        id t = [sels at:i];

        if (![impls includes:t])
        {
            if (superc)
                if (![superc lookupSelector:t forDecl:nil])
                    warn ("can't find implementation of %s%s", (f) ? "+" : "-",
                          [t str]);
        }
    }
    return self;
}

- warnimplnotfound
{
    [self check:clssels includedin:clsdispsels factory:YES];
    [self check:nstsels includedin:nstdispsels factory:NO];
    return self;
}

- undefcomps
{
    compdic   = nil;
    compnames = nil;
    comptypes = nil;
    return self;
}

- addivars
{
    if (!ivardic)
    {
        ivardic   = [Dictionary new];
        ivarnames = [OrdCltn new];
        ivartypes = [OrdCltn new];
    }

    [compdic keysDo:
             { :each |
          dbg("Putting for %s\n", [each str]);
                 [ivardic atKey:each put:[compdic atKey:each]]
             }];
    [ivarnames addContentsOf:compnames];
    [ivartypes addContentsOf:comptypes];
    return [self undefcomps];
}

- defivars
{
    ivardic   = compdic;
    ivarnames = compnames;
    ivartypes = comptypes;
    return [self undefcomps];
}

- defcvars
{
    cvardic   = compdic;
    cvarnames = compnames;
    cvartypes = comptypes;
    return [self undefcomps];
}

- ivarnames { return ivarnames; }

- cvarnames { return cvarnames; }

- synth
{
    id outerstruct;
    char * s = [self classname];

    unit = trlunit;

    [self rootclassdef];
    if (superc)
        shartypename = [superc shartypename];
    if (cvars)
        shartypename = [[String sprintf:"%s_SHARED", s] strCopy];
    outerstruct      = curstruct;
    curstruct = self;
    if (ivars)
    {
        [ivars elementsPerform:_cmd];
        [self defivars];
    }
    if (cvars)
    {
        [cvars elementsPerform:_cmd];
        [self defcvars];
    }
    curstruct = outerstruct;
    return self;
}

- genlineno
{
    gl ([classname lineno], [[classname filename] str]);
    return self;
}

- genivars
{
    if (superc)
        [superc genivars];
    if (ivars)
        [ivars elementsPerform:@selector (gen)];
    return self;
}

- gencvars
{
    if (superc)
        [superc gencvars];
    if (cvars)
        [cvars elementsPerform:@selector (gen)];
    return self;
}

- genVarList_isForFactory:(BOOL)isFactory
{
    OrdCltn varnames, vartypes;
    const char * pszName = [classname str];
    const char cSuffix   = isFactory ? 'c' : 'i';

    if (!isFactory)
        (varnames = ivarnames, vartypes = ivartypes);
    else
        (varnames = cvarnames, vartypes = cvartypes);

    gf ("objC_iVar %s_%cvars[] =\n"
        "{\n",
        pszName, cSuffix);

    if (varnames)
        for (int i = 0, n = [varnames size]; i < n; i++)
        {
            gf ("{\n"
                "  \"%s\",\n"
                "  \"%s\",\n",
                [[varnames at:i] str], [[[vartypes at:i] encode] str]);

            /* size */
            gs ("sizeof(");
            [[vartypes at:i] genabstrtype];
            gs ("),");

            /* offset */
            gs ("sizeof(");
            [[vartypes at:i] genabstrtype];
            gs (")");

            if (i)
                for (int i2 = i - 1; i2 >= 0; i2--)
                {
                    gs ("+ sizeof(");
                    [[vartypes at:i2] genabstrtype];
                    gs (")");
                }

            /* final_offset */
            gs (",\n"
                "  0"
                "}");

            if (i == n - 1)
                gs ("\n");
            else
                gs (",\n");
        }

    gs ("};\n");

    gf ("objC_iVarList %s_%cvarlist =\n", pszName, cSuffix);
    gs ("{\n");
    gf ("  %d,\n", [varnames size]);
    gf ("  &%s_%cvars\n", pszName, cSuffix);
    gs ("};\n");
    return self;
}

- genprivtype
{
    int i, n;
    String s = [String str:privtypename];

    if ([trlunit isgentype:s])
        return self;
    [trlunit addgentype:s];

    [self genlineno];
    gf ("struct %s {\n", privtypename);
    [self genivars];
    gs ("};\n");

    if (o_otb)
    {
        gf ("struct %s {\n", otbtypename);
        gf ("  struct %s *ptr;\n", privtypename);
        g_otbvars ();
        gs ("};\n");
    }

    if (ivars)
        for (i = 0, n = [ivars size]; i < n; i++)
        {
            [[[trlunit lookupstruct:[Symbol sprintf:"%s", privtypename]]
                defcomp:[ivarnames at:i]
                 astype:[ivartypes at:i]] synth];
        }

    gf ("static long * __%s_i_offsets[];\n", [self classname]);
    gf ("static long * __%s_c_offsets[];\n", [self classname]);

    return self;
}

- genshartype
{
    id s = [String str:shartypename];

    if ([trlunit isgentype:s])
        return self;
    [trlunit addgentype:s];

    gf ("struct %s\n{\n", shartypename);
    gs ("  id isa;\n");
    gs ("  id clsSuper;\n");
    gs ("  char *clsName;\n");
    gs ("  char *clsTypes;\n");
    gs ("  long clsSizInstance;\n");
    gs ("  long clsSizDict;\n");
    gs ("  struct _SLT *clsDispTable;\n");
    gs ("  long clsStatus;\n");
    gs ("  struct modDescriptor *clsMod;\n");
    gs ("  unsigned clsVersion;\n");
    gs ("  id *clsGlbl;\n");
    gs ("  struct objC_iVarList_s * clsIVars;\n");
    gs ("  long ** clsIVarOffsets;\n");
    [self gencvars];
    gs ("};\n");
    return self;
}

- genslt:methdef
{
    if (o_cplus)
    {
        gf ("\n{\"%s\", \"%s\",(id (*)(...))%s},", [methdef selname],
            [[methdef encode] str], [methdef impname]);
    }
    else
    {
        gf ("\n{\"%s\", \"%s\", (id (*)())%s},", [methdef selname],
            [[methdef encode] str], [methdef impname]);
    }
    return self;
}

- gennilslt
{
    if (o_cplus)
    {
        gs ("\n{(char*)0, 0, (id (*)(...))0}");
    }
    else
    {
        gs ("\n{(char*)0, 0, (id (*)())0}");
    }
    return self;
}

- genclsdisptbl
{
    int i, n;

    n = (clsdisptbl) ? [clsdisptbl size] : 0;
    gf ("static struct _SLT %s[] ={", clsdisptblname);
    for (i = 0; i < n; i++)
    {
        [self genslt:[clsdisptbl at:i]];
    }
    [self gennilslt];
    gs ("\n};\n");
    return self;
}

- gennstdisptbl
{
    int i, n;

    n = (nstdisptbl) ? [nstdisptbl size] : 0;
    gf ("static struct _SLT %s[] ={", nstdisptblname);
    for (i = 0; i < n; i++)
    {
        [self genslt:[nstdisptbl at:i]];
    }
    [self gennilslt];
    gs ("\n};\n");
    return self;
}

/* clsStatus field values : these must match objcrt.m */
#define CLS_FACTORY 0x1L
#define CLS_META 0x2L
#define CLS_INITIALIZED 0x4L
#define CLS_POSING 0x8L
#define CLS_MAPPED 0x10L
#define CLS_CAT 0x20L
#define CLS_REFCNT 0x40L

- genclassimpl
{
    long st;

    [self genVarList_isForFactory:NO];
    [self genVarOffsetVars_isForFactory:NO className:nil];
    [self genVarOffsetsArray_isForFactory:NO className:nil];

    if (!iscategory)
    {
        st = CLS_FACTORY | CLS_POSING;
    }
    else
    {
        st = CLS_FACTORY | CLS_POSING | CLS_CAT;
    }
    if (o_refcnt)
    {
        st |= CLS_REFCNT;
    }
    gf ("struct %s ", shartypename);

    if (!o_otb)
    {
        gf (" %s = {\n", _classname);
    }
    else
    {
        gf (" %s_OTB = {\n", _classname);
    }

    gf ("  (id)&%s,", _m_classname);
    gcom ("/* isa */");

    /* if no shareddata (DLL's), then this field is set at runtime */
    if (superc != nil && o_shareddata)
    {
        gf ("  (id)&%s,", [superc _classname]);
        gcom ("/* clsSuper */");
    }
    else
    {
        gf ("  0,");
        gcom ("/* clsSuper */");
    }

    gf ("  \"%s\",", [self classname]);
    gcom ("/* clsName */");

    gs ("  0,");
    gcom ("/* clsTypes */");

    gf ("  sizeof(struct %s),", privtypename);
    gcom ("/* clsSizInstance */");

    gf ("  %d,", (nstdisptbl) ? [nstdisptbl size] : 0);
    gcom ("/* clsSizDict */");

    gf ("  %s,", nstdisptblname);
    gcom ("/* _nstDispatchTbl */");

    gf ("  %d,", st);
    gcom ("/* clsStatus */");

    gf ("  &%s,", [trlunit moddescname]);
    gcom ("/* clsMod */");

    gs ("  0,");
    gcom ("/* clsVersion */");

    gs ("  0,");
    gcom ("/* clsGlbl */");

    gf ("  &%s_ivarlist,", [self classname]);
    gcom ("/* clsIVarList */");

    gf ("  __%s_i_offsets,", [self classname]);
    gcom ("/* clsIVarOffsets */");

    gs ("};\n");

    if (o_otb)
    {
        char * z = _classname;

        gf ("struct OTB %s={ (struct _PRIVATE*)&%s_OTB,0,0 };\n", z, z);
    }
    gf ("id %s %s(void)", o_bind, _classfunname);
    gf (" { return (id)&%s; }\n", _classname);

    gf ("id %s %s(void)", o_bind, _superfunname);
    if (!o_otb)
    {
        gf (" { return %s.clsSuper; }\n", _classname);
    }
    else
    {
        gf (" { return %s_OTB.clsSuper; }\n", _classname);
    }

    return self;
}

- genmetaimpl
{
    long st = CLS_META;

    [self genVarList_isForFactory:YES];
    [self genVarOffsetVars_isForFactory:YES className:nil];
    [self genVarOffsetsArray_isForFactory:YES className:nil];

    if (o_refcnt)
    {
        st |= CLS_REFCNT;
    }
    if (!o_otb)
    {
        gf ("struct _SHARED %s = {\n", _m_classname);
    }
    else
    {
        gf ("struct _SHARED %s_OTB = {\n", _m_classname);
    }

    if (o_shareddata)
    {
        gf ("  (id)&%s,", [rootc _m_classname]);
        gcom ("/* isa */");
    }
    else
    {
        gs ("  (id)0,");
        gcom ("/* isa */"); /* field set in BIND() */
    }

    if (o_shareddata)
    {
        if (superc)
        {
            gf ("  (id)&%s,", [superc _m_classname]);
            gcom ("/* clsSuper */");
        }
        else
        {
            /* meta hierarchy is ended by the root class */
            gf ("  (id)&%s,", [rootc _classname]);
            gcom ("/* clsSuper */");
        }
    }
    else
    {
        gs ("  (id)0,");
        gcom ("/* clsSuper */"); /* field set in BIND() */
    }

    gf ("  \"%s\",", [self classname]);
    gcom ("/* clsName */");

    gs ("  0,");
    gcom ("/* clsTypes */");

    gf ("  sizeof(struct %s),", shartypename);
    gcom ("/* clsSizInstance */");

    gf ("  %d,", (clsdisptbl) ? [clsdisptbl size] : 0);
    gcom ("/* clsSizDict */");

    gf ("  %s,", clsdisptblname);
    gcom ("/* _clsDispatchTbl */");

    gf ("  %d,", st);
    gcom ("/* clsStatus */");

    gf ("  &%s,", [trlunit moddescname]);
    gcom ("/* clsMod */");

    gs ("  0,");
    gcom ("/* clsVersion */");

    gs ("  0,");
    gcom ("/* clsGlbl */");

    gf ("  &%s_cvarlist,", [self classname]);
    gcom ("/* clsIVarList */");

    gf ("  __%s_c_offsets,", [self classname]);
    gcom ("/* clsIVarOffsets */");

    gs ("};\n");

    if (o_otb)
    {
        char * z = _m_classname;

        gf ("struct OTB %s={ (struct _PRIVATE*)&%s_OTB,0,0 };\n", z, z);
    }
    gf ("id %s %s(void)", o_bind, _m_classfunname);
    gf (" { return (id)&%s; }\n", _m_classname);

    gf ("id %s %s(void)", o_bind, _m_superfunname);
    if (!o_otb)
    {
        gf (" { return %s.clsSuper; }\n", _m_classname);
    }
    else
    {
        gf (" { return %s_OTB.clsSuper; }\n", _m_classname);
    }

    return self;
}

- genclassglobal
{
    char * s = [self c_classname];

    if (!o_shareddata)
        gs ("static");
    gf ("id %s = (id)&%s;\n", s, _classname);
    gf ("id %s *%s(void) { return &%s; }\n", o_bind, globfunname, s);
    return self;
}

- genclassref
{
    if (!o_shareddata)
    {
        assert (globfunname);
        gf ("*%s()", globfunname);
    }
    else
    {
        gs ([self c_classname]);
    }
    return self;
}

- genglobfuncall
{
    char * s;

    if (superc)
    {
        s = [superc _classfunname];
        if (!o_otb)
        {
            gf ("  %s.clsSuper = %s();\n", _classname, s);
        }
        else
        {
            gf ("  %s_OTB.clsSuper = %s();\n", _classname, s);
        }
    }
    s = [rootc _m_classfunname];
    if (!o_otb)
    {
        gf ("  %s.isa = %s();\n", _m_classname, s);
    }
    else
    {
        gf ("  %s_OTB.isa = %s();\n", _m_classname, s);
    }

    s = (superc) ? [superc _m_classfunname] : [rootc _classfunname];
    if (!o_otb)
    {
        gf ("  %s.clsSuper = %s();\n", _m_classname, s);
    }
    else
    {
        gf ("  %s_OTB.clsSuper = %s();\n", _m_classname, s);
    }

    return self;
}

- gen
{
    gf ("typedef struct _PRIVATE * %s;\n", [classname str]);

    if (isimpl)
    {
        [self genprivtype]; /* for instance variables */
        [self genshartype]; /* need this for class variables */
        [self genfwddecl];
    }
    return self;
}

- gensuper
{
    if (o_otb || !o_shareddata)
    {
        gf ("%s()", _superfunname);
    }
    else
    {
        gf ("%s.clsSuper", _classname);
    }
    return self;
}

- genmetasuper
{
    if (o_otb || !o_shareddata)
    {
        gf ("%s()", _m_superfunname);
    }
    else
    {
        gf ("%s.clsSuper", _m_classname);
    }
    return self;
}

- use
{
    if (!o_postlink)
        [trlunit usesentry:classname];
    return self;
}

- define
{
    [trlunit addclsimpl:self];
    if (!o_postlink)
        [trlunit definesentry:classname];
    return self;
}

- (BOOL)isimpl { return isimpl; }

- forceimpl
{
    if (isimpl)
    {
        return self;
    }
    else
    {
        isimpl = YES;
        [self define];
        [superc use];
        return self;
    }
}

- iscategory:(BOOL)isit
{
    iscategory = isit;
    return self;
}

- (BOOL)forcegenintf
{
    if (o_shareddata)
    {
        gf ("extern id %s %s;\n", o_bind, c_classname);
        return NO;
    }
    else
    {
        /* with windows DLL's cant use global, must use function */
        gf ("extern id %s *%s(void);\n", o_bind, globfunname);
        return YES;
    }
}

- genintf
{
    if (emitintf)
    {
        return self;
    }
    else
    {
        emitintf = YES;
        [self genlineno];
        [self forcegenintf];
        return self;
    }
}

- genfwddecl
{
    /* forward decls for the stuff defined in genimpl */
    if (emitfwddecl)
    {
        return self;
    }
    else
    {
        emitfwddecl = YES;
        [self genintf];
        [self genlineno];
        if (!o_otb)
        {
            gf ("extern struct %s %s;\n", shartypename, _classname);
            gf ("extern struct _SHARED %s;\n", _m_classname);
        }
        else
        {
            assert (!o_shareddata);
            gf ("extern struct OTB %s;\n", _classname);
            gf ("extern struct %s %s_OTB;\n", shartypename, _classname);
            gf ("extern struct OTB %s;\n", _m_classname);
            gf ("extern struct _SHARED %s_OTB;\n", _m_classname);
        }
        if (!o_shareddata)
        {
            gf ("extern id %s %s(void);\n", o_bind, _classfunname);
            gf ("extern id %s %s(void);\n", o_bind, _superfunname);
            gf ("extern id %s %s(void);\n", o_bind, _m_classfunname);
            gf ("extern id %s %s(void);\n", o_bind, _m_superfunname);
        }
        return self;
    }
}

- genimpl
{
    if (emitimpl)
    {
        return self;
    }
    else
    {
        emitimpl = YES;
        [rootc genfwddecl];
        if (superc)
            [superc genfwddecl];
        [self genfwddecl];
        [self genprivtype];
        [self genshartype]; /* in case not yet emitted */
        o_nolinetags++;
        if (fileinmethod)
        {
            [fileinmethod gen];
            gc ('\n');
        }
        if (fileoutmethod)
        {
            [fileoutmethod gen];
            gc ('\n');
        }
        if (decrefsmethod)
        {
            [decrefsmethod gen];
            gc ('\n');
        }
        if (increfsmethod)
        {
            [increfsmethod gen];
            gc ('\n');
        }
        if (propmeths)
            [propmeths do:
                       { : each |[each gen];
                       }];
        [self genclsdisptbl];
        [self gennstdisptbl];
        [self genclassglobal];
        [self genclassimpl];
        [self genmetaimpl];
        o_nolinetags--;
        return self;
    }
}

- defcomp:sym astype:t
{
    if (!compdic)
    {
        compdic   = [Dictionary new];
        compnames = [OrdCltn new];
        comptypes = [OrdCltn new];
    }
    if (superc && ([superc isivar:sym] || [superc iscvar:sym]))
    {
        id which, next;

        for (which = superc, next = [which superclassdef]; next; which = next)
        {
            if (!([next isivar:sym] || [next iscvar:sym]))
                break;
        }
        fatalat (sym, "'%s' previously declared by '%s'", [sym str],
                 [which classname]);
    }
    else
    {
        [compdic atKey:sym put:t];
        [compnames add:sym];
        [comptypes add:t];
    }
    return self;
}

- lookupivar:sym
{
    id t;

    if (ivardic && (t = [ivardic atKey:sym]))
        return t;
    return (superc) ? [superc lookupivar:sym] : nil;
}

- lookupcvar:sym
{
    id t;

    if (cvardic && (t = [cvardic atKey:sym]))
        return t;
    return (superc) ? [superc lookupcvar:sym] : nil;
}

- (BOOL)isivar:sym
{
    if (!allivarnames)
    {
        id x, c;

        allivarnames = [Set new];
        for (c = self; c; c = [c superclassdef])
        {
            if ((x = [c ivarnames]))
                [allivarnames addAll:x];
        }
    }
    return [allivarnames contains:sym];
}

- (BOOL)iscvar:sym
{
    BOOL iscvar;

    if (!allcvarnames)
    {
        id x, c;

        allcvarnames = [Set new];
        for (c = self; c; c = [c superclassdef])
        {
            if ((x = [c cvarnames]))
                [allcvarnames addAll:x];
        }
    }
    iscvar = [allcvarnames contains:sym];
    if (iscvar && [trlunit usingselfassign])
    {
        if (o_warnsuggest)
        {
            warnat (sym,
                    "suggest using -noSelfAssign when using class variables");
        }
    }
    return iscvar;
}

- (int)bytesizeOf:c
{
    int i, n;
    int bs = 0;
    for (i = 0, n = [c size]; i < n; i++)
    {
        bs += [[c at:i] bytesize];
    }
    return bs;
}

- (int)ivarbytesize { return (ivartypes) ? [self bytesizeOf:ivartypes] : 0; }

- (int)cvarbytesize { return (cvartypes) ? [self bytesizeOf:cvartypes] : 0; }

- browsevars
{
    id fn;
    FILE * f;
    int i, n;

    fn = [String sprintf:"Menu.vars%s", [self classname]];
    f = freopen (browsepath ([fn str]), "w", stderr);
    if (!f)
    {
        fatal ("cannot open %s for writing\n", [fn str]);
        return self;
    }

    gstderr ();

    fprintf (f, "menu=%s variables\n", [self classname]);
    for (i = 0, n = [ivarnames size]; i < n; i++)
    {
        fprintf (f, "name='");
        [[ivartypes at:i] gendef:[ivarnames at:i]];
        fprintf (f, "'\n");
        fprintf (f, "action=none\n");
    }
    for (i = 0, n = [cvarnames size]; i < n; i++)
    {
        fprintf (f, "name='");
        [[cvartypes at:i] gendef:[cvarnames at:i]];
        fprintf (f, "'\n");
        fprintf (f, "action=none\n");
    }

    fclose (f);
    gnormal ();

    return self;
}

- browsemethods
{
    id fn;
    FILE * f;
    int i, n;

    fn = [String sprintf:"Menu.methods%s", [self classname]];
    f = freopen (browsepath ([fn str]), "w", stdout);
    if (!f)
    {
        fatal ("cannot open %s for writing\n", [fn str]);
        return self;
    }

    printf ("menu=%s methods\n", [self classname]);
    for (i = 0, n = [clssels size]; i < n; i++)
    {
        printf ("name=%s\n", [[clssels at:i] str]);
        printf ("action=none\n");
    }
    for (i = 0, n = [nstsels size]; i < n; i++)
    {
        printf ("name=%s\n", [[nstsels at:i] str]);
        printf ("action=none\n");
    }

    fclose (f);
    return self;
}

- browse
{
    id fn;
    FILE * f;

    fn = [String sprintf:"Menu.%s", [self classname]];
    f = freopen (browsepath ([fn str]), "w", stdout);
    if (!f)
    {
        fatal ("cannot open %s for writing\n", [fn str]);
        return self;
    }

    printf ("menu=%s\n", [self classname]);
    printf ("name=Spawn hierarchy\n");
    printf ("action=open Menu.super%s\n", [self classname]);
    printf ("name=Inspect variables\n");
    printf ("action=open Menu.vars%s\n", [self classname]);
    printf ("name=Method categories\n");
    printf ("action=open Menu.categories%s\n", [self classname]);
    printf ("name=Show methods\n");
    printf ("action=open Menu.methods%s\n", [self classname]);
    printf ("name=Spawn protocol\n");
    printf ("action=open Menu.protocol%s\n", [self classname]);
    fclose (f);

    [self browsevars];
    [self browsemethods];
    return self;
}

- addpropmeth:propmeth
{
    if (!propmeths)
        propmeths = [OrdCltn new];
    [propmeths add:propmeth];
    return self;
}

- propmeths { return propmeths; }

- clssels { return clssels; }
- nstsels { return nstsels; }

static BOOL checkUpCast (ClassDef one, ClassDef two)
{
    ClassDef superOne;
    if (!one || !two)
        return YES;
    else if (one == two)
        return YES;
    else if ((superOne = [one superclassdef]) && (two == superOne))
        return NO;
    else if (superOne)
        return checkUpCast (superOne, two);
    return YES;
}

static BOOL checkRelation (ClassDef one, ClassDef two)
{
    return checkUpCast (one, two) || checkUpCast (two, one);
}

- (BOOL)checkAssign:(ClassDef)aClass { return checkUpCast (self, aClass); }

- (BOOL)isRelated:(ClassDef)aClass { return checkRelation (self, aClass); }

- lookupSelector:(Selector)aSel forDecl:(Decl)aDecl
{
    if (!aSel)
        return nil;
    else
    {
        Selector candidate = [clssels findMatching:aSel];
        if (!candidate)
            candidate = [nstsels findMatching:aSel];
        if (!candidate && !iscategory && superc)
            candidate = [superc lookupSelector:aSel forDecl:aDecl];
        if (!candidate && categories)
            candidate = [[categories
                detect:{ : each | [each lookupSelector:aSel forDecl:aDecl]}]
                lookupSelector:aSel
                       forDecl:aDecl];

        return candidate;
    }
}

- (Method)methodForSelector:(Selector)aSel forDecl:(Decl)aDecl
{
    Method aMeth;

    aMeth = [methsForSels atKey:aSel];
    if (!aMeth && superc && !iscategory)
        aMeth = [superc methodForSelector:aSel forDecl:aDecl];
    if (!aMeth && categories)
        aMeth = [[categories
            detect:{ : each | [each methodForSelector:aSel forDecl:aDecl]}]
            methodForSelector:aSel
                      forDecl:aDecl];
    return aMeth;
}

@end
