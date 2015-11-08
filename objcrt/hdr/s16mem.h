#ifndef S16MEM_H_
#define S16MEM_H_

void s16mem_init ();
void * s16mem_alloc (unsigned long nbytes);
void s16mem_free (void * ap);

#endif