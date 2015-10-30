/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#include "private/_sockets.h"

#import "TCPSocket.h"
#import "Set.h"

/* This class defines a pipe.
 * Depending on whether system select() supports file descriptors or sockets,
 * the pipe is implemented with either pipe() or a TCP socket pair. */

@interface Pipe : IODevice
{
#if defined(OBJC_WINDOWS)
    TCPSocket readFd, writeFd;
#else
    int readFd, writeFd;
#endif
} :
{
    /* 49,644 to 50,668 */
    Set * ports;
}
@end