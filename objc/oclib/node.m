/*
 * Copyright (c) 1998 David Stes.
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

#include <stddef.h>
#include <stdlib.h>
#include <ctype.h>
#include <assert.h>
#include <string.h>
#include "MutableString.h"
#include "OrdCltn.h"
#include "node.h"
#include "symbol.h"
#include "options.h"

#define KNRM "\x1B[0m"
#define KBLD "\x1B[1m"
#define KULN "\x1B[4m"
#define KRED "\x1B[31m"
#define KGRN "\x1B[32m"
#define KYEL "\x1B[33m"
#define KBLU "\x1B[34m"
#define KMAG "\x1B[35m"
#define KCYN "\x1B[36m"
#define KWHT "\x1B[37m"

FILE * gfile;
id infilename;
char * outfilename;
int exitstatus, inlineno, outlineno;
id loadedmodules; /* for VICI */

static FILE * backupgfile;
static BOOL lastisalpha;

char * browsepath (char * filename)
{
    if (!o_browsedir)
    {
        fatal ("browse dir not set");
        return NULL;
    }
    else
    {
        MutableString * buf = [MutableString str:o_browsedir];
        [buf concatSTR:o_pathsep];
        [buf concatSTR:filename];
        return [buf str];
    }
}

void gstderr (void)
{
    backupgfile = gfile;
    o_nolinetags++;
    gfile = stderr;
}

void gnormal (void)
{
    gfile = backupgfile;
    o_nolinetags--;
}

BOOL needspace (char c) { return isalnum (c) || c == '_' || c == '$'; }

void gc (char c)
{
    if (needspace (c))
    {
        if (lastisalpha)
            fputc (' ', gfile);
        fputc (c, gfile);
        lastisalpha = needspace (c);
    }
    else
    {
        if (c == '\n')
            outlineno++;
        fputc (c, gfile);
        lastisalpha = NO;
    }
}

void gextc (void)
{
    if (o_cplus)
        gs ("extern \"C\" ");
}

void g_otbvars (void)
{
    /* used at several locations */
    gs ("  struct OTB *previnst;\n");
    gs ("  struct OTB *nextinst;\n");
}

void gs (char * s)
{
    int i, n = strlen (s);

    if (n && lastisalpha && needspace (s[0]))
        fputc (' ', gfile);
    for (i = 0; i < n; i++)
        if (s[i] == '\n')
            outlineno++;
    fputs (s, gfile);
    if (n)
        lastisalpha = needspace (s[n - 1]);
}

void gf (char * s, ...)
{
    OC_VA_LIST ap;
    int i, n = strlen (s);

    if (n && lastisalpha && needspace (s[0]))
        fputc (' ', gfile);
    for (i = 0; i < n; i++)
        if (s[i] == '\n')
            outlineno++; /* assumes nl in format */
    OC_VA_START (ap, s);
    vfprintf (gfile, s, ap);
    OC_VA_END (ap);
    if (n)
        lastisalpha = needspace (s[n - 1]);
}

void gcom (char * cm)
{
    if (o_comments)
        gs (cm);
    gc ('\n');
}

/* automatically generated variables (for message expressions) */

#define NUM_VARS_PER_LINE 5

void gvarlist (id c, char * cm, char * iz)
{
    int j, k, n;

    for (k = 0, n = [c size]; k < n;)
    {
        gf ("    %s     ", cm);
        for (j = 0; j < NUM_VARS_PER_LINE && k < n; j++, k++)
        {
            if (j)
                gc (',');
            gs ([[c at:k] str]);
            gs (iz);
        }
        gc (';');
        gc ('\n');
    }
}

void gcommalist (id args)
{
    int i, n = [args size];

    if (n)
        [[args at:0] gen];
    for (i = 1; i < n; i++)
    {
        gc (',');
        [[args at:i] gen];
    }
}

void gl (int no, char * fn)
{
    int d = no - outlineno;

    if (o_nolinetags || no == 0 || fn == NULL)
        return;

    /* usually outfilename will be pointer equal to 'fn' */
    if (0 < d && d < 4 && outfilename == fn)
    {
        while (d--)
            gc ('\n');
        outlineno = no;
    }
    else
    {
        if (d != 0 || outfilename != fn)
        {
            if (outlineno)
                fputc ('\n', gfile); /* next char (#) must be 1st col */
            fprintf (gfile, o_tagformat, no, fn);
            outlineno   = no;
            outfilename = fn;
        }
    }
}

void vwarn (char * s, OC_VA_LIST ap)
{
    int n;
    vfprintf (stderr, s, ap);
    if ((n = strlen (s)) && s[n - 1] != '\n')
        fprintf (stderr, KNRM "\n");
}

#define LNO "%s:%d: "
#define WSTR "Warning: "
#define ESTR "Error: "
#define WARN KBLD LNO KYEL WSTR KWHT
#define ERRO KBLD LNO KRED ESTR KWHT

void warnat (id sym, char * s, ...)
{
    if (o_warnings)
    {
        OC_VA_LIST ap;
        int no    = [sym lineno];
        char * fn = [[sym filename] str];

        OC_VA_START (ap, s);
        fprintf (stderr, KBLD);
        if (no)
            fprintf (stderr, WARN, fn ?: "(std-in)", no);
        vwarn (s, ap);
        OC_VA_END (ap);
    }
}

void warn (char * s, ...)
{
    if (o_warnings)
    {
        OC_VA_LIST ap;

        OC_VA_START (ap, s);
        fprintf (stderr, WARN, [infilename str], inlineno);
        vwarn (s, ap);
        OC_VA_END (ap);
    }
}

void vfatal (char * s, OC_VA_LIST ap)
{
    int n;

    vfprintf (stderr, s, ap);
    if ((n = strlen (s)) && s[n - 1] != '\n')
        fprintf (stderr, KNRM "\n");
    exitstatus = 1;
}

void fatal (char * s, ...)
{
    OC_VA_LIST ap;

    OC_VA_START (ap, s);
    fprintf (stderr, ERRO, [infilename str], inlineno);
    vfatal (s, ap);
    OC_VA_END (ap);
}

void fatalat (id sym, char * s, ...)
{
    OC_VA_LIST ap;
    int no    = [sym lineno];
    char * fn = [[sym filename] str];

    OC_VA_START (ap, s);
    if (no)
        fprintf (stderr, ERRO, fn ?: "(std-in)", no);
    vfatal (s, ap);
    OC_VA_END (ap);
}

@implementation Node

- synth { return [self subclassResponsibility:_cmd]; }

- sgen
{
    o_nolinetags++;
    [self gen];
    o_nolinetags--;
    return self;
}

- gen { return [self subclassResponsibility:_cmd]; }

- st80 { return self; }

- (BOOL)isstorageclass { return NO; /* overridden by StorageClass */ }

- (BOOL)isscalartype { return NO; /* overridden by Type */ }

- (BOOL)isgnuattrib { return NO; /* overridden by GnuAttribDecl */ }

- (BOOL)isid { return NO; }

- (BOOL)isvoid { return NO; }

- dot:sym { return nil; }

@end
