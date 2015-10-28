/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import "Object.h"

@interface Date : Object

@property TimeInterval seconds;

+ date;
+ dateWithTimeIntervalSinceNow:(TimeInterval)seconds;
+ dateWithTimeIntervalSince1970:(TimeInterval)seconds;
+ distantFuture;
+ distantPast;

- initWithTimeInterval:(TimeInterval)secsToBeAdded
             sinceDate:(Date *)anotherDate;
- initWithTimeIntervalSinceNow:(TimeInterval)secsToBeAdded;
- initWithTimeIntervalSince1970:(TimeInterval)secs;

- (unsigned int)microsecond;
- (unsigned int)second;
- (unsigned int)minute;
- (unsigned int)hour;

@end