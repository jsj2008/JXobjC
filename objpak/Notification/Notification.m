/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import "Notification.h"

@implementation Notification

+ (Notification)notificationWithName:(String)name object:object
{
    return [[self alloc] initWithName:name object:object userInfo:nil];
}

+ (Notification)notificationWithName:(String)aName
                              object:anObject
                            userInfo:(Dictionary)anUserInfo
{
    return
        [[self alloc] initWithName:aName object:anObject userInfo:anUserInfo];
}

- initWithName:(String)aName object:anObject userInfo:(Dictionary)anUserInfo
{
    name     = [aName copy];
    userInfo = [anUserInfo copy];
    object   = anObject;
    return self;
}

- ARC_dealloc
{
    name     = nil;
    object   = nil;
    userInfo = nil;
    return [super ARC_dealloc];
}

- (String)notificationName { return name; }

- (STR)name { return [name str]; }

- notificationObject { return object; }

- object { return object; }

- (Dictionary)userInfo { return userInfo; }

- deepCopy
{
    return [[[self class] alloc] initWithName:name
                                       object:object
                                     userInfo:userInfo];
}

@end
