#import "RunLoop.h"

@implementation RunLoopDescriptor

- init
{
    [super init];
    readFd  = -1;
    writeFd = -1;
    return self;
}

- ARC_dealloc
{
    iod = nil;
    return [super ARC_dealloc];
}

- setIOD:anIOD eventTypes:(FdEvSourceType_t)types
{
    descriptorEventType = types;
    if (types & FDEV_READ)
        readFd = [anIOD readDescriptor];
    if (types & FDEV_WRITE)
        writeFd = [anIOD writeDescriptor];
    if ((types & FDEV_READ) && (types & FDEV_EXCEPT))
        readExc = YES;
    if ((types & FDEV_WRITE) && (types & FDEV_EXCEPT))
        writeExc = YES;

    return self;
}

@end