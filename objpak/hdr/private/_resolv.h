/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#include "private/_sockets.h"
#import "OCString.h"

typedef struct resolvinfo_s
{
    int ai_family;
    int ai_socktype;
    int ai_protocol;
    socklen_t ai_addrlen;
    struct sockaddr * ai_addr;
    void * addrinfo;
} resolvinfo_t;

resolvinfo_t ** jx_resolv (String * host, unsigned short port, int typ);