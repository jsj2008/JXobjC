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

/*!
 * @abstract Date
 * @discussion Stores a date. Dates are internally represented as a
 * (Double-type) number of seconds from 1970.
 * @indexgroup Container
 */
@interface Date : Object

/*! Number of seconds from 1970. */
@property TimeInterval seconds;

/*! Creates a new Date representing the current date. */
+ date;

+ dateWithTimeIntervalSinceNow:(TimeInterval)seconds;
+ dateWithTimeIntervalSince1970:(TimeInterval)seconds;

/*! Creates a new Date representing a date in the distant future. */
+ distantFuture;

/*! Creates a new Date representing a date in the distant past. */
+ distantPast;

- initWithTimeInterval:(TimeInterval)secsToBeAdded sinceDate:(Date)anotherDate;
- initWithTimeIntervalSinceNow:(TimeInterval)secsToBeAdded;
- initWithTimeIntervalSince1970:(TimeInterval)secs;

- (Date)earlierDate:(Date)otherDate;
- (Date)laterDate:(Date)otherDate;

- (TimeInterval)timeIntervalSince1970;
- (TimeInterval)timeIntervalSinceDate:(Date)otherDate;
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
