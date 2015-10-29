/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#include <pthread.h>
#include <stdlib.h>
#include "private/_resolv.h"

#import "Block.h"
#import "Exceptn.h"

static pthread_mutex_t getaddrinfo_mtx = PTHREAD_MUTEX_INITIALIZER;

static resolvinfo_t ** _jx_resolv_impl (String * host, unsigned short port,
                                        int typ)
{
    int err;
    size_t num            = 0;
    resolvinfo_t *results = 0, **ret = 0, *resnext, **retnext;
    struct addrinfo hints = {0}, *addrinfo, *addrinfo1;
    char port_str[6];

    hints.ai_flags    = AI_NUMERICSERV;
    hints.ai_family   = AF_UNSPEC;
    hints.ai_socktype = typ;

    snprintf (port_str, 6, "%d", port);

    if ((err = getaddrinfo ([host str], port_str, &hints, &addrinfo1)))
        [Exception signal:"Failed to resolve host: getaddrinfo failed."];

    for (addrinfo = addrinfo1; addrinfo != NULL; addrinfo = addrinfo->ai_next)
        num++;

    if (!num)
    {
        freeaddrinfo (addrinfo1);
        [Exception
            signal:"Failed to resolve host: getaddrinfo returned no results."];
    }

    ret     = calloc (num + 1, sizeof (*ret));
    results = malloc (num * sizeof (*results));

    for (retnext = ret, resnext = results, addrinfo = addrinfo1;
         addrinfo != NULL; retnext++, resnext++, addrinfo = addrinfo->ai_next)
    {
        resnext->ai_family   = addrinfo->ai_family;
        resnext->ai_socktype = addrinfo->ai_socktype;
        resnext->ai_protocol = addrinfo->ai_protocol;
        resnext->ai_addr     = addrinfo->ai_addr;
        resnext->ai_addrlen  = (socklen_t)addrinfo->ai_addrlen;
        *retnext             = resnext;
    }

    *retnext         = NULL;
    ret[0]->addrinfo = addrinfo;

    return ret;
}

resolvinfo_t ** jx_resolv (String * host, unsigned short port, int protocol)
{
    resolvinfo_t ** result = 0;
    Exception * except     = 0;

    pthread_mutex_lock (&getaddrinfo_mtx);
    [
        {
            result = _jx_resolv_impl (host, port, protocol);
        } on:Exception
          do:
          { :exc | except = exc;
          }];
    pthread_mutex_unlock (&getaddrinfo_mtx);

    if (except)
        [except signal];

    return result;
}

void jx_freeresolv (resolvinfo_t ** toFree)
{
    free (toFree[0]->addrinfo);
    free (toFree[0]);
    free (toFree);
}