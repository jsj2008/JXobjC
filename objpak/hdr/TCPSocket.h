/* Copyright (c) 2015-2016 D. Mackay. All rights reserved. */

#include "private/_sockets.h"

#import "AbstractSocket.h"
#import "OCString.h"

/*!
 * @abstract TCP Socket
 * @discussion Socket using the TCP protocol. May act as client or server.
 * @indexgroup I/O
 */
@interface TCPSocket : AbstractSocket

/* For a per-client socket, the sockaddr of the client. */
@property struct sockaddr * addr;

/* For a per-client socket, the addrlen of the client. */
@property socklen_t addrlen;

/*! Whether the socket will use the KeepAlive protocol. */
@property BOOL keepAlive;

/*! Whether the socket is listening. */
@property /* (readonly) */ BOOL listening;

/*!
 * @abstract Connects to the specified hostname and port.
 * @discussion If connection fails, an exception will be signaled
 * detailing the problem. Otherwise, you may read or write to the
 * socket or place it into a @link RunLoop @/link.
 * @param host String hostname to connect to.
 * @param port Unsigned short port to connect to.
 */
- (id)connectToHostname:(String)host port:(unsigned short)port;

/*!
 * @abstract Binds to the specified hostname and port.
 *
 * @discussion A port of 0 will result in the choosing of a random port.
 * That port number will be returned.
 * If binding fails, signals an exception detailing the problem.
 * @param host String hostname to bind to.
 * @param port Unsigned short port to bind to.
 */
- (unsigned short)bindToHostname:(String)host port:(unsigned short)port;

/*!
 * @abstract Begins listening for connections.
 *
 * @discussion After this, the socket can be read from or placed into a
 * @link RunLoop @/link.
 * If listening fails, signals an exception. */
- listen;

- listenWithBacklog:(int)backlog;

- accept;

@end
