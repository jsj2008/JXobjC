/*
 * LibSunshine
 *
 * Function & type definitions for linked list implementation.
 */

#ifndef List_h_
#define List_h_

typedef struct List_s_
{
    void * data;
    struct List_s_ * Link;
} List_t_;

typedef struct List_s
{
    List_t_ * List;
} List_t;

#endif
