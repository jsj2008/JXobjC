/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#include <stdint.h>

#import "Block.h"
#import "NotificationCentre.h"
#import "set.h"

@interface _ObserverDictEntry : Object
{
    /* The name of the notification. */
    String * name;
    /* The object that sent the notification. */
    volatile id object;
}

- _initWithName:_name object:_object
{
    [self init];
    name   = _name;
    object = _object;
    return self;
}

+ _keyWithName:_name object:_object
{
    return [[self alloc] _initWithName:_name object:_object];
}

- ARC_dealloc
{
    name   = nil;
    object = nil;
    return [super ARC_dealloc];
}

- (BOOL)isEqual:anObject
{
    _ObserverDictEntry * otherObject;
    if (![anObject isKindOf:_ObserverDictEntry])
        return NO;
    otherObject = anObject;
    if ((otherObject->name == name || [otherObject->name isEqual:(id)name]) &&
        otherObject->object == object)
        return YES;
    else
        return NO;
}

- (unsigned)hash { return ((uintptr_t)object ^ (uintptr_t)[name hash]); }

@end

@interface _ObserverDictValue : Object
{
    /* Option one: an object and a selector */
    volatile id object;
    SEL selector;
    /* Option two: a block. */
    id block;
}

- initWithObject:_object selector:(SEL)_selector
{
    [super init];
    object   = _object;
    selector = _selector;
    return self;
}

- initWithBlock:_block
{
    [super init];
    block = _block;
    return self;
}

+ _valueWithBlock:_block { return [[self alloc] initWithBlock:_block]; }

+ _valueWithObject:_object selector:(SEL)_selector
{
    return [[self alloc] initWithObject:_object selector:_selector];
}

- ARC_dealloc
{
    object = nil;
    block  = nil;
    return [super ARC_dealloc];
}

- (BOOL)isEqual:anObject
{
    _ObserverDictValue * otherObject;
    if (![anObject isKindOf:_ObserverDictValue])
        return NO;
    otherObject = anObject;
    if (object && otherObject->object == object &&
        otherObject->selector == selector)
        return YES;
    else if (block && otherObject->block == block)
        return YES;
    else
        return NO;
}

- (unsigned)hash
{
    return block ? [block hash] : ((uintptr_t)object ^ (uintptr_t)selector);
}

- _matchesObjOrBlock:objorblock
{
    if (block == objorblock || object == objorblock)
        return self;
    else
        return nil;
}

@end

@implementation NotificationCentre

+ (NotificationCentre *)defaultCentre
{
    if (!defaultCentre)
        defaultCentre = [[[self class] alloc] init];
    return defaultCentre;
}

- init
{
    [super init];
    observers = [Dictionary new];
    return self;
}

- ARC_dealloc
{
    observers = nil;
    return [super ARC_dealloc];
}

- (void)postNotification:(Notification *)notification {}

- (void)addObserver:observer
           selector:(SEL)selector
               name:(String *)name
             sender:sender
{
    id key    = [_ObserverDictEntry _keyWithName:name object:sender];
    id theSet = [observers atKey:key];

    if (!theSet)
    {
        theSet = [Set new];
        [observers atKey:key put:theSet];
    }

    [theSet
        add:[_ObserverDictValue _valueWithObject:observer selector:selector]];
}

- (void)removeObserver:observer name:(String *)name object:sender
{
    id key    = [_ObserverDictEntry _keyWithName:name object:sender];
    id theSet = [observers atKey:key];

    if (!theSet)
        return;

    [theSet do:
            { :each | id matched;
                if ((matched = [each _matchesObjOrBlock:observer]))
                    [theSet remove:matched];
            }];
    if (![theSet size])
        [observers removeKey:key];
}

- (void)removeObserver:observer
{
    [observers keysDo:
               { :key | id set = [observers atKey:key];
                   [set do:
                        { :each | id matched;
                            if ((matched = [each _matchesObjOrBlock:observer]))
                                [set remove:matched];
                        }];
                   if (![set size])
                       [observers removeKey:key];
               }];
}

@end
