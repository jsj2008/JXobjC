/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import "IODevice.h"

/* This partially abstract class defines a Socket; e.g. TCP or UDP or Unix. */

@interface AbstractSocket : IODevice
{
    /* this is set to -1 if there is no connection */
    SocketDescriptor descriptor;
}

@end