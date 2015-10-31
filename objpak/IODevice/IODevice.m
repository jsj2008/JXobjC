/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import "IODevice.h"

@implementation IODevice

- (void)close { [self subclassResponsibility:_cmd]; }

- (void)flushReads;
- (void)flushWrites;

- (size_t)rawReadIntoBuffer:(void *)buffer length:(size_t)length
{
    [self subclassResponsibility:_cmd];
    return 0;
}

- (void)rawWriteBuffer:(const void *)buffer length:(size_t)length
{
    [self subclassResponsibility:_cmd];
}

/* Retrieve a file descriptor for reading or writing to respectively ✔ */
- (int)readDescriptor
{
    [self subclassResponsibility:_cmd];
    return 0;
}

- (int)writeDescriptor
{
    [self subclassResponsibility:_cmd];
    return 0;
}

@end
