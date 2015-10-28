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

- (Date *)earlierDate:(Date *)otherDate;
- (Date *)laterDate:(Date *)otherDate;

- (unsigned int)microsecond;
- (unsigned char)second;
- (unsigned char)minute;
- (unsigned char)hour;
- (unsigned char)dayOfMonth;
- (unsigned char)month;
- (unsigned short)year;

@end