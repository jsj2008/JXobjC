#import "Block.h"
#import "RunLoop.h"

@implementation RunLoopExecutor

- initWithSelector:(SEL)sel target:targ argument:arg
{
    [super init];
    selector = sel;
    target   = targ;
    argument = arg;
    return self;
}

- initWithBlock:blk argument:arg
{
    [super init];
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
             { :msg :rcv | printf("Exception in RunLoop executor method.\n");
             }];
    }
}

@end