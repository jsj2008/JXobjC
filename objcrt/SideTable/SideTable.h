/* Copyright (c) 2016 D. Mackay. All rights reserved. */

#ifndef SideTable_H_
#define SideTable_H_

#include <pthread.h>

void sideTable_init ();
pthread_mutex_t * mutexForObject (id anObject);
void destroySideTableForObject (id anObject);

#endif
