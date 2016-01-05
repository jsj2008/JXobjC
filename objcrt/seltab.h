/* Copyright (c) 2016 D. Mackay. All rights reserved. */

#ifndef SELTAB_H_
#define SELTAB_H_

#include "objcrt.h"

int strCmp (char * s1, char * s2);

void hashInit ();
PHASH hashNew (STR key, PHASH link);
PHASH search (STR key, long * slot, PHASH * prev);
PHASH hashEnter (STR key, long slot);
PHASH hashLookup (STR key, long * slot);

#endif