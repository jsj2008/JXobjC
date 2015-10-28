/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#include <math.h>
#include <sys/types.h>
#include <sys/time.h>
#include <time.h>

#import "outofbnd.h"
#import "Date.h"

#define EPSILON 0.0000001f

#define DISTANT_FUTURE 63113990400.0
#define DISTANT_PAST -63113817600.0

static id _distantPast, _distantFuture;

#define DblComp(one, two) fabs (one - two) < EPSILON

#define returnGmTimeField(seconds, x)                                          \
    time_t sec = (time_t)seconds;                                              \
    struct tm tm;                                                              \
                                                                               \
    if (sec != floor (seconds))                                                \
        [[OutOfBounds new:seconds] signal];                                    \
                                                                               \
    if (gmtime_r (&sec, &tm) == NULL)                                          \
        [[OutOfBounds new:seconds] signal];                                    \
                                                                               \
    return tm.tm_##x;

@implementation Date

+ date { return [[self alloc] init]; }

+ dateWithTimeIntervalSinceNow:(TimeInterval)seconds
{
    return [[self alloc] initWithTimeIntervalSinceNow:seconds];
}

+ dateWithTimeIntervalSince1970:(TimeInterval)seconds
{
    return [[self alloc] initWithTimeIntervalSince1970:seconds];
}

+ distantFuture
{
    if (!_distantFuture)
        _distantFuture =
            [[self alloc] initWithTimeIntervalSince1970:DISTANT_FUTURE];
    return _distantFuture;
}

+ distantPast
{
    if (!_distantPast)
        _distantPast =
            [[self alloc] initWithTimeIntervalSince1970:DISTANT_PAST];
    return _distantPast;
}

- init
{
    struct timeval t;
    [super init];
    gettimeofday (&t, NULL);
    seconds = t.tv_sec;
    seconds += ((TimeInterval)t.tv_usec / (TimeInterval)1000000);
    return self;
}

- initWithTimeInterval:(TimeInterval)secsToBeAdded sinceDate:(Date *)anotherDate
{
    [super init];
    seconds = anotherDate->seconds + secsToBeAdded;
    return self;
}

- initWithTimeIntervalSinceNow:(TimeInterval)secsToBeAdded
{
    [self init];
    seconds += secsToBeAdded;
    return self;
}
- initWithTimeIntervalSince1970:(TimeInterval)secs
{
    [super init];
    seconds = secs;
    return self;
}

/* Interrogation */

- (unsigned)hash { return (unsigned)seconds; }

- (BOOL)isEqual:(id)otherObject
{
    if (otherObject == nil)
        return NO;
    if ([otherObject isKindOf:Date] && DblComp (seconds, [otherObject seconds]))
        return YES;
    return NO;
}

- (Date *)earlierDate:(Date *)otherDate
{
    return [otherDate seconds] < seconds ? otherDate : (Date *)self;
}

- (Date *)laterDate:(Date *)otherDate
{
    return [otherDate seconds] > seconds ? otherDate : (Date *)self;
}

- (unsigned int)microsecond
{
    return rint ((seconds - floor (seconds)) * 1000000);
}

- (unsigned char)second { returnGmTimeField (seconds, sec); }
- (unsigned char)minute { returnGmTimeField (seconds, min); }
- (unsigned char)hour { returnGmTimeField (seconds, hour); }
- (unsigned char)dayOfMonth { returnGmTimeField (seconds, mday); }
- (unsigned char)month { returnGmTimeField (seconds, mon + 1); }
- (unsigned short)year { returnGmTimeField (seconds, year + 1900); }

@end