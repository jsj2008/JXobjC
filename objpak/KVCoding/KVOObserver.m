#import "Block.h"
#import "KVOStore.h"

@implementation KPObserver

- initWithKeyPath:kp selector:(SEL)sel target:targ userInfo:arg
{
    [self init];
    keyPath  = kp;
    selector = sel;
    target   = targ;
    userInfo = arg;
    return self;
}

- initWithKeyPath:kp block:blk target:targ userInfo:arg
{
    [self init];
    keyPath  = kp;
    target   = targ;
    block    = blk;
    userInfo = arg;
    return self;
}

+ newWithKeyPath:kp selector:(SEL)sel target:targ userInfo:arg
{
    return
        [[self alloc] initWithKeyPath:kp selector:sel target:targ userInfo:arg];
}

+ newWithKeyPath:kp block:blk target:targ userInfo:arg
{
    return [[self alloc] initWithKeyPath:kp block:blk target:targ userInfo:arg];
}

- ARC_dealloc
{
    target   = nil;
    userInfo = nil;
    block    = nil;
    keyPath  = nil;
    return [super ARC_dealloc];
}

- (unsigned)hash
{
    return selector ? [selector hash] % [target hash]
                    : [block hash] % [target hash];
}

- (BOOL)isEqual:anObject
{
    if (![anObject isKindOf:KPObserver])
        return NO;
    else if (([anObject matchesSelector:selector
                                 target:target
                               userInfo:userInfo] ||
              [anObject matchesBlock:block userInfo:userInfo]) &&
             [keyPath isEqual:[anObject keyPath]])
        return YES;
    else
        return NO;
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

- (BOOL)matchesKeyPath:kp { return [keyPath isEqual:kp]; }

- (String *)keyPath { return keyPath; }

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