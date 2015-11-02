#import "Block.h"
#import "RunLoop.h"

@implementation RunLoopExecutor

- initWithSelector:(SEL)sel target:targ argument:arg
{
    [self init];
    selector = sel;
    target   = targ;
    argument = arg;
    return self;
}

- initWithBlock:blk argument:arg
{
    [self init];
    block    = blk;
    argument = arg;
    return self;
}

+ newWithSelector:(SEL)sel target:targ argument:arg
{
    return [[self alloc] initWithSelector:sel target:targ argument:arg];
}

+ newWithBlock:blk argument:arg
{
    return [[self alloc] initWithBlock:blk argument:arg];
}

- ARC_dealloc
{
    target   = nil;
    argument = nil;
    block    = nil;
    return [super ARC_dealloc];
}

- (BOOL)matchesSelector:(SEL)sel target:targ argument:arg
{
    if (!targ || !sel)
        return NO;
    else if (target == targ && selector == sel && argument == arg)
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

- (BOOL)matchesBlock:blk argument:arg
{
    if (!blk)
        return NO;
    else if (block == blk && argument == arg)
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

- (void)fire
{

    if (target)
    {
        [
            {
                [target perform:selector with:argument];
            } ifError:
              { :msg :rcv | printf("Exception in RunLoop executor method.\n");
              }];
    }
    else
    {
        [block value:argument
             ifError:
             { :msg :rcv | printf("Exception in RunLoop executor block.\n");
             }];
    }
}

@end