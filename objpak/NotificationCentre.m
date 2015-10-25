/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import "Block.h"
#import "NotificationCentre.h"
#import "set.h"

@interface _Observer : Object
{
    /* The object that receives the notification. */
    volatile id object;
    /* The senders from which the notification should be from.
     * If the sender of a notification is in this list, then
     * the notification is sent. */
    Set * senders;
    SEL selector;
}

- initWithObject:_object selector:(SEL)_selector sender:_sender
{
    [super init];
    object   = _object;
    selector = _selector;
    senders  = [[Set new] add:_sender];
    return self;
}

+ observerWithObject:_object selector:(SEL)_selector sender:_sender
{
    return
        [[self alloc] initWithObject:_object selector:_selector sender:_sender];
}

- ARC_dealloc
{
    object  = nil;
    senders = nil;
    return [super ARC_dealloc];
}

- addAcceptedSender:sender
{
    [senders add:sender];
    return self;
}

- removeAcceptedSender:sender
{
    [senders remove:sender];
    return self;
}

- (void)postNotification:(Notification *)notification
{
    if ([senders contains:[notification object]] || [senders contains:nil] ||
        !senders)
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

- init
{
    [super init];
    nameToObserverDict = [Dictionary new];
    return self;
}

- ARC_dealloc
{
    nameToObserverDict = nil;
    return [super ARC_dealloc];
}

- (void)postNotification:(Notification *)notification
{
    id val = [nameToObserverDict atKey:[notification notificationName]];
    [val keysDo:
         {
        :each | [val postNotification:notification];
         }];
}

- (void)addObserver:observer
           selector:(SEL)selector
               name:(String *)name
             object:sender
{
    id obsDict = [nameToObserverDict atKey:name], obs;
    if (obsDict)
    {
        if ((obs = [obsDict atKey:observer]))
            [obs addAcceptedSender:sender];
        else
            [obsDict atKey:observer
                       put:[_Observer observerWithObject:observer
                                                selector:selector
                                                  sender:sender]];
    }
    else
    {
        [nameToObserverDict atKey:name put:[Dictionary new]];
        [[nameToObserverDict atKey:name]
            atKey:observer
              put:[_Observer observerWithObject:observer
                                       selector:selector
                                         sender:sender]];
    }
}

@end
