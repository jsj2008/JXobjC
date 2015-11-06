#import "Block.h"
#import "KVOStore.h"
#import "OCString.h"

@implementation KPObserver

- initWithKeyPath:kp selector:(SEL)sel observer:targ userInfo:arg
{
    [self init];
    keyPath           = kp;
    keyPathComponents = [keyPath componentsSeparatedByString:@"."];
    selector          = sel;
    observer          = targ;
    userInfo          = arg;
    return self;
}

- initWithKeyPath:kp block:blk observer:targ userInfo:arg
{
    [self init];
    keyPath           = kp;
    keyPathComponents = [keyPath componentsSeparatedByString:@"."];
    observer          = targ;
    block             = blk;
    userInfo          = arg;
    return self;
}

+ newWithKeyPath:kp selector:(SEL)sel observer:targ userInfo:arg
{
    return [[self alloc] initWithKeyPath:kp
                                selector:sel
                                observer:targ
                                userInfo:arg];
}

+ newWithKeyPath:kp block:blk observer:targ userInfo:arg
{
    return
        [[self alloc] initWithKeyPath:kp block:blk observer:targ userInfo:arg];
}

- ARC_dealloc
{
    observer          = nil;
    userInfo          = nil;
    block             = nil;
    keyPath           = nil;
    keyPathComponents = nil;
    return [super ARC_dealloc];
}

- (unsigned)hash
{
    return selector ? [selector hash] % [observer hash] % [keyPath hash]
                    : [block hash] % [observer hash] % [keyPath hash];
}

- (BOOL)isEqual:anObject
{
    if (![anObject isKindOf:KPObserver])
        return NO;
    else if (([anObject matchesSelector:selector
                               observer:observer
                               userInfo:userInfo] ||
              [anObject matchesBlock:block userInfo:userInfo]) &&
             [keyPath isEqual:[anObject keyPath]])
        return YES;
    else
        return NO;
}

- (BOOL)matchesSelector:(SEL)sel observer:targ userInfo:arg
{
    if (!targ || !sel)
        return NO;
    else if (observer == targ && selector == sel && userInfo == arg)
        return YES;
    else
        return NO;
}

- (BOOL)matchesTarget:targ
{
    if (!targ)
        return NO;
    else if (observer == targ)
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

- (BOOL)matchesObserver:obs
{
    if (!obs)
        return NO;
    else if (observer == obs)
        return YES;
    else
        return NO;
}

- (String *)keyPath { return keyPath; }

- (OrdCltn *)keyPathComponents { return keyPathComponents; }

- (void)fire:info
{

    if (selector)
    {
        [
            {
                [observer perform:selector with:info];
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