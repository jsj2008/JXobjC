/* Copyright (c) 2016 D. Mackay. All rights reserved. */

#ifndef IVAR_H_
#define IVAR_H_

/*
  The objC_iVar and objC_iVarList types are emitted in trlunit.m.
  Here is a reference:
      gs ("typedef struct objC_iVar_s\n"
        "{\n"
        "  const char * name;\n"
        "  const char * type;\n"
        "  int offset, final_offset;\n"
        "} objC_iVar;\n");

    gs ("typedef struct objC_iVarList_s\n"
        "{\n"
        "  int count;\n"
        "  objC_iVar (*list)[];\n"
        "} objC_iVarList;\n");
 */

#endif