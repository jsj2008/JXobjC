/*
 * Copyright (c) 1998,1999,2000 David Stes.
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
 *
 */

/* some methods to which both compound statement and block expr respond */

- enclosing { return enclosing; }

- addtmpvar:tvar
{
    if (!tmpvars)
        tmpvars = [OrdCltn new];
    [tmpvars add:tvar];
    return self;
}

- addicache:tvar
{
    if (!icaches)
        icaches = [OrdCltn new];
    [icaches add:tvar];
    return self;
}

- addincref:v withType:t
{
    if (!increfs)
        increfs = [OrdCltn new];
    if (!increfts)
        increfts = [OrdCltn new];
    [increfs add:v];
    return self;
}

- genincrefs
{
    int i, n = [increfs size];

    for (i = 0; i < n; i++)
    {
        if (lbrace)
            gl ([lbrace lineno], [[lbrace filename] str]);
        gf ("idincref((id)%s);\n", [[increfs at:i] str]);
    }
    gc ('\n');
    return self;
}

- adddecref:v withType:t
{
    if (!decrefs)
        decrefs = [OrdCltn new];
    if (!decrefts)
        decrefts = [OrdCltn new];
    [decrefs add:v];
    [decrefts add:t];
    /* get this to be added to both curcompound and stmt of for(;;) */
    if (curloopcompound && self != curloopcompound)
        [curloopcompound adddecref:v withType:t];
    return self;
}

- gendecrefs
{
    int i, n = [decrefs size];

    for (i = 0; i < n; i++)
    {
        char * s = [[decrefs at:i] str];

        if (rbrace)
            gl ([rbrace lineno], [[rbrace filename] str]);
        gf ("%s=(", s);
        [[decrefts at:i] genabstrtype];
        gf (")iddecref((id)%s);\n", s);
    }
    gc ('\n');
    return self;
}

- lookuplocal:sym { return (localdic) ? [localdic atKey:sym] : nil; }

- deflocal:sym astype:t
{
    if (!localdic)
    {
        localdic = [Dictionary new];
        locals   = [OrdCltn new];
    }
    [localdic atKey:sym put:t];
    [locals add:sym];
    if (curdef && ([curdef ismethdef]))
    {
        assert (curclassdef);
        if ([curclassdef isivar:sym])
        {
            warnat (sym, "definition of local '%s' hides instance variable",
                    [sym str]);
        }
        if ([curclassdef iscvar:sym])
        {
            warnat (sym, "definition of local '%s' hides class variable",
                    [sym str]);
        }
    }
    return self;
}

- genheapvarptr
{
    char * p = heapvarptrname;
    char * t = heapvartypename;

    assert (heapnames);
    /* this must be a Calloc to set the refcnt to 0 and for 'id' vars */
    gf ("%s *%s=(%s *)OC_Calloc(sizeof(%s));\n", t, p, t, t);
    return self;
}

- freeheapvarptr:(BOOL)decRefs
{
    char * p = heapvarptrname;

    gf ("if (%s->heaprefcnt-- == 0) {\n", p);
    if (o_refcnt && decRefs)
        [self gendecrefsheapvars];
    gf ("OC_Free(%s);\n", p);
    gs ("}\n");

    return self;
}

- gendecrefsheapvars
{
    int i, n   = [heapnames size];
    char * hvp = heapvarptrname;

    for (i = 0; i < n; i++)
    {
        id x = [heapnames at:i];
        id t = [heaptypes at:i];

        assert (t != nil);
        if ([t isid])
        {
            char * s = [x str];
            gf ("%s->%s=(", hvp, s);
            [t genabstrtype];
            gf (")iddecref((id)%s->%s);\n", hvp, s);
        }
    }
    return self;
}

- genheapvartype
{
    int i, n = [heapnames size];

    if (!n)
        return self;
    gf ("%s {\n", heapvartypename);
    gs ("int heaprefcnt;\n");
    for (i = 0; i < n; i++)
    {
        id x = [heapnames at:i];
        id t = [heaptypes at:i];

        assert (t != nil);
        [t gendef:x];
        gs (";\n");
    }
    gs ("};\n");
    return self;
}

- heapvars { return nil; }

- (BOOL)isheapvar:x { return (heapvars) ? [heapvars contains:x] : NO; }

- defheapvar:x type:t
{
    int i;

    if (!heapvars)
    {
        heapvars        = [Set new];
        heapnames       = [OrdCltn new];
        heaptypes       = [OrdCltn new];
        i               = [trlunit heapvarcount];
        heapvarptrname  = [[String sprintf:"heapvars%i", i] strCopy];
        heapvartypename = [[String sprintf:"struct heaptype%i", i] strCopy];
    }
    if ([t isstatic])
    {
        char * msg = "can't use static local variables (%s) from within block";

        fatalat (x, msg, [x str]);
    }
    else
    {
        if ([heapvars addNTest:x] != nil)
        {
            [heapnames add:x];
            [heaptypes add:t];
        }
    }
    return self;
}

- (char *)heapvarptrname
{
    assert (heapvarptrname);
    return heapvarptrname;
}

- (char *)heapvartypename
{
    assert (heapvartypename);
    return heapvartypename;
}

- removeheapvarsfromdatadefs
{
    int n;

    assert (heapvars);
    initializers = [OrdCltn new];

    if (parmnames)
    {
        n = [parmnames size];
        while (n--)
        {
            id p = [parmnames at:n];

            if ([heapvars contains:p])
            {
                id x = [[mkidentexpr (p) lhsself:YES] synth];
                id y = mkidentexpr (p); /* don't synth */

                [initializers add:mkexprstmt (mkassignexpr (x, "=", y))];
            }
        }
    }
    if (datadefs)
    {
        n = [datadefs size];
        while (n--)
        {
            id def = [datadefs at:n];

            [def removevars:heapvars initializers:initializers];
            if ([def decllist] == nil)
                [datadefs removeAt:n];
        }
    }
    if ([datadefs size] == 0)
        datadefs = nil;
    return self;
}