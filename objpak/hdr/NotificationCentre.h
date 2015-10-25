/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import "Object.h"
#import "OCString.h"
#import "Dictionary.h"
#import "Notification.h"

@interface NotificationCentre : Object
{
    Dictionary * objects;
    id nullObjects;
}
: {
	id defaultCentre;
}

+ (NotificationCentre *)defaultCentre;

- ARC_dealloc;

- (void)postNotification:(Notification *)notification;
- (void)postNotificationName:(String *)notificationName object:object;
- (void)postNotificationName:(String *)notificationName
                      object:object
                    userInfo:(Dictionary *)userInfo;

- (void)addObserver:observer
           selector:(SEL)selector
               name:(String *)name
             object:object;
- (void)removeObserver:observer name:(String *)name object:object;
- (void)removeObserver:observer;

@end