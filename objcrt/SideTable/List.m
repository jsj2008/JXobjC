/*
 * LibSunshine
 *
 * Implementation of linked lists.
 */

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>

#include "List.h"

List_t * List_new ()
{
    List_t * new = calloc (1, sizeof (List_t));
    return new;
}

void List_add (List_t * n, void * data)
{
    List_t_ *temp, *t;

    if (n == 0)
        n = List_new ();

    if (n->List == 0)
    {
        /* create new list */
        t       = malloc (sizeof (List_t_));
        t->data = data;
        t->Link = NULL;
        n->List = t;
    }
    else
    {
        t    = n->List;
        temp = malloc (sizeof (List_t_));
        while (t->Link != NULL)
            t      = t->Link;
        temp->data = data;
        temp->Link = NULL;
        t->Link    = temp;
    }
}

void List_del (List_t * n, void * data)
{
    List_t_ *current, *previous;

    previous = NULL;

    for (current = n->List; current != NULL;
         previous = current, current = current->Link)
    {
        if (current->data == data)
        {
            if (previous == NULL)
            {
                // correct the first
                n->List = current->Link;
            }
            else
            {
                // skip
                previous->Link = current->Link;
            }

            free (current);
        }
    }
}

void List_destroy (List_t * n)
{
    if (!n)
        return;
    for (List_t_ *it = n->List, *tmp; it != NULL; it = tmp)
    {
        tmp = it->Link;
        free (it);
    }
    free (n);
}

List_t_ * List_begin (List_t * n)
{
    if (!n)
        return 0;
    return n->List;
}

void List_iterator_next (List_t_ ** it) { *it = (*it)->Link; }

void * List_lpop (List_t * n)
{
    void * ret;
    List_t_ * tmp;

    if (n->List == NULL)
    {
        return 0;
    }
    else
    {
        ret = n->List->data;

        if (n->List->Link)
        {
            tmp = n->List->Link;
            free (n->List);
            n->List = tmp;
        }
        else
        {
            free (n->List);
            n->List = NULL;
        }

        return ret;
    }
}

void * List_lget (List_t * n)
{
    if (n == NULL || n->List == NULL)
    {
        return 0;
    }
    else
    {
        return n->List->data;
    }
}

void List_print (List_t * n)
{
    List_t_ * t;

    t = n->List;

    if (t == NULL)
        printf ("Empty list\n");

    else
    {
        printf ("Begin list.\n");
        while (t != NULL)
        {
            printf ("%d\n", t->data);
            t = t->Link;
        }
        printf ("End list.\n");
    }
    return;
}
