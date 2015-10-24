/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import "Object.h"
#import "Dictionary.h"
#import "OCString.h"

@interface Notification : Object
{
	String * name;
	volatile id object;
	id userInfo;
}
+ (Notification *)notificationWithName:(String*)name object:object;
+ (Notification *)notificationWithName:(String*)aName
  object:anObject userInfo:(Dictionary*)userInfo;

- (id)initWithName:(String *)aName object:anObject 
  userInfo:(Dictionary *)anUserInfo;
- (String *)notificationName;
- notificationObject;
- object;
- (Dictionary *)userInfo;

@end