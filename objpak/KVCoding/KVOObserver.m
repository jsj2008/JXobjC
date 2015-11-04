#import "Block.h"
#import "KVOStore.h"

@implementation KPObserver

- initWithSelector:(SEL)sel target:targ userInfo:arg
{
    [self init];
    selector = sel;
    target   = targ;
    userInfo = arg;
    return self;
}

- initWithBlock:blk target:targ userInfo:arg
{
    [self init];
    target   = targ;
    block    = blk;
    userInfo = arg;
    return self;
}

+ newWithSelector:(SEL)sel target:targ userInfo:arg
{
    return [[self alloc] initWithSelector:sel target:targ userInfo:arg];
}

+ newWithBlock:blk target:targ userInfo:arg
{
    return [[self alloc] initWithBlock:blk target:targ userInfo:arg];
}

- ARC_dealloc
{
    target   = nil;
    userInfo = nil;
    block    = nil;
    return [super ARC_dealloc];
}

- (BOOL)matchesSelector:(SEL)sel target:targ userInfo:arg
{
    if (!targ || !sel)
        return NO;
    else if (target == targ && selector == sel && userInfo == arg)
        return YES;
    else
        return NO;
}

- (BOOL)matchesTarget:targ
{
    if (!targ)
        return NO;
    else if (target == targ)
        return YES;
    else
        return NO;
}

- (BOOL)matchesBlock:blk userInfo:arg
{
    if (!blk)
        return NO;
    else if (block == blk && userInfo == arg)
        return YES;
    else
        return NO;
}

- (BOOL)matchesBlock:blk
{
    if (!blk)
        return NO;
    else if (block == blk)
        return YES;
    else
        return NO;
}

- (void)fire:info
{

    if (target)
    {
        [
            {
                [target perform:selector with:info];
            } ifError:
              { :msg :rcv | printf("Exception in KVO callback method.\n");
              }];
    }
    else
    {
        [block value:info
             ifError:
             { :msg :rcv | printf("Exception in KVO callback block.\n");
             }];
    }
}

@end