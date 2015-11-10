/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#if defined(_MSC_VER) || defined(__MINGW32__)
#include <time.h>
#ifndef _TIMEVAL_DEFINED
#define _TIMEVAL_DEFINED
struct timeval
{
    long tv_sec;
    long tv_usec;
};
#endif
#else
#include <time.h>
#include <sys/time.h>
#endif

#import "Object.h"
#import "KVO.h"

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

- (TimeInterval)timeIntervalSince1970;
- (TimeInterval)timeIntervalSinceDate:(Date *)otherDate;
- (TimeInterval)timeIntervalSinceNow;

- (unsigned int)microsecond;
- (unsigned char)second;
- (unsigned char)minute;
- (unsigned char)hour;
- (unsigned char)dayOfMonth;
- (unsigned char)month;
- (unsigned short)year;

@end

struct timeval JXtimevalFromTimeInterval (TimeInterval ti);