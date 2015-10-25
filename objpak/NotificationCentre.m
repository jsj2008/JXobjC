/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import "NotificationCentre.h"

@interface _Observer : Object
{
    volatile id object;
    SEL selector;
}

- initWithObject:_object selector:(SEL)_selector
{
    [super init];
    object   = _object;
    selector = _selector;
    return self;
}

+ observerWithObject:_object selector:(SEL)_selector
{
    return [[self alloc] initWithObject:_object selector:_selector];
}

- (void)postNotification:(Notification *)notification
{
    [object perform:selector with:(id)notification];
}

@end

@implementation NotificationCentre

+ (NotificationCentre *)defaultCentre
{
    if (!defaultCentre)
        defaultCentre = [[[self class] alloc] init];
    return defaultCentre;
}

- ARC_dealloc
{
    objects     = nil;
    nullObjects = nil;
    return [super ARC_dealloc];
}

@end
