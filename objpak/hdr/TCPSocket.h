/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#include "private/_sockets.h"

#import "AbstractSocket.h"
#import "OCString.h"

/* This class defines a TCP socket. */

@interface TCPSocket : AbstractSocket

@property struct sockaddr * addr;
@property socklen_t addrlen;
@property /* (readonly) */ BOOL listening;
@property BOOL keepAlive;

- connectToHostname:(String *)host port:(unsigned short)port;

/* A port of 0 will result in the choosing of a random port.
 * That port number will be returned. */
- (unsigned short)bindToHostname:(String *)host port:(unsigned short)port;

- listen;
- listenWithBacklog:(int)backlog;

- accept;

@end