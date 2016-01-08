/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#include <stdlib.h>
#include "private/_resolv.h"

#import "Block.h"
#import "Exceptn.h"
#import "TCPSocket.h"

#ifndef SOCK_CLOEXEC
#define SOCK_CLOEXEC 0
#define NOSOCK_CLOEXEC
#endif

@implementation TCPSocket

- (void)close
{
    if (addrlen)
        free (addr);
    addr    = 0;
    addrlen = 0;
    sockclose (descriptor);
}

- connectToHostname:(String *)host port:(unsigned short)port
{
    resolvinfo_t **results, **resnext;

    if (descriptor != -1)
        [Exception signal:"Already connected"];

    free (readBuffer);
    readBuffer       = NULL;
    readBufferLength = 0;

    results = jx_resolv (host, port, SOCK_STREAM);

    for (resnext = results; *resnext != NULL; resnext++)
    {
        if ((descriptor = socket ((*results)->ai_family,
                                  (*results)->ai_socktype | SOCK_CLOEXEC,
                                  (*results)->ai_protocol)) == -1)
            continue;

        if (connect (descriptor, (*results)->ai_addr, (*results)->ai_addrlen) ==
            -1)
        {
            close (descriptor);
            descriptor = -1;
            continue;
        }
    }

    jx_freeresolv (results);

    if (descriptor == -1)
        [Exception signal:"Failed to connect to host"];

    return self;
}

- (unsigned short)bindToHostname:(String *)host port:(unsigned short)port
{
    resolvinfo_t ** results;
    /* Because we aren't sure what protocol will be used, we use this union.
     * sockaddr_storage is the maximum size of a protocol's sockaddr, and we
     * can find out the concrete type of what we've stored in there by querying
     * its ss_family member. This allows us to retrieve our port number. */
    union
    {
        struct sockaddr_storage storage;
        struct sockaddr_in in;
        struct sockaddr_in6 in6;
    } baddr;
    socklen_t baddrlen;

    if (descriptor != -1)
        [Exception signal:"Already connected"];

    results = jx_resolv (host, port, SOCK_STREAM);

    [
        {
            if ((descriptor = socket (results[0]->ai_family,
                                      results[0]->ai_socktype | SOCK_CLOEXEC,
                                      results[0]->ai_protocol)) == -1)
                [Exception
                    signal:"Failed to open socket: socket() returned -1"];
#ifdef NOSOCK_CLOEXEC
            fcntl (descriptor, F_SETFD,
                   fcntl (descriptor, F_GETFD, 0) | FD_CLOEXEC);
#endif
            setsockopt (descriptor, SOL_SOCKET, SO_REUSEADDR, &(int){1},
                        sizeof (int));
            if (bind (descriptor, results[0]->ai_addr,
                      results[0]->ai_addrlen) == -1)
            {
                close (descriptor);
                descriptor = -1;
                [Exception signal:"Failed to bind socket: bind() returned -1"];
            }
        } on:Exception
          do:
          { :exception |
              jx_freeresolv(results);
              [exception signal];
          }];

    if (port > 0)
    {
        return port;
    }

    baddrlen = (socklen_t)sizeof (baddr.storage);

    if (getsockname (descriptor, (struct sockaddr *)&baddr.storage,
                     &baddrlen) != 0)
    {
        close (descriptor);
        descriptor = -1;
        [Exception signal:"Failed to bind: getsockname failed"];
    }

    if (baddr.storage.ss_family == AF_INET)
        return ntohs (baddr.in.sin_port);
    else if (baddr.storage.ss_family == AF_INET6)
        return ntohs (baddr.in6.sin6_port);
    else
    {
        close (descriptor);
        descriptor = -1;
        [Exception signal:"Failed to bind: protocol not INET or INET6"];
        return -1; /* clang doesn't know that Exception transfers control */
    }
}

- listen { return [self listenWithBacklog:SOMAXCONN]; }

- listenWithBacklog:(int)backlog
{
    if (descriptor == -1)
        [Exception signal:"Failed to listen on socket: socket is not valid"];
    if (listen (descriptor, backlog) == -1)
        [Exception signal:"Failed to listen on socket: listen() returned -1"];

    [self setListening:YES];
    return self;
}

- accept
{
    TCPSocket * cl = [[self class] new];
    socklen_t alen;

    cl.addr    = malloc (sizeof (struct sockaddr_storage));
    cl.addrlen = (socklen_t)sizeof (struct sockaddr_storage);

#if defined(SOCK_NOCLOEXEC)
    [cl _setDescriptor:accept (descriptor, cl.addr, &cl->addrlen)];
    if ([cl _descriptor] == -1)
        [Exception signal:"Failed to accept connection: accept() returned -1"];

    fcntl ([cl _descriptor], F_SETFD,
           fcntl ([cl _descriptor], F_GETFD, 0) | FD_CLOEXEC);
#else
    [cl _setDescriptor:accept4 (descriptor, cl.addr, &alen, SOCK_CLOEXEC)];
    cl.addrlen = alen;
    if ([cl _descriptor] == -1)
        [Exception signal:"Failed to accept connection: accept4() returned -1"];
#endif

    return cl;
}

@end
