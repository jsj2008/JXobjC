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

static TimeInterval _currentTime ()
{
    struct timeval tv;
    TimeInterval curtime;

    gettimeofday (&tv, NULL);
    curtime = tv.tv_sec;
    curtime += ((TimeInterval)tv.tv_usec / (TimeInterval)1000000);

    return curtime;
}

struct timeval JXtimevalFromTimeInterval (TimeInterval ti)
{
    struct timeval res;

    if (ti < 0)
    {
        res.tv_sec  = 0;
        res.tv_usec = 0;
        return res;
    }

    res.tv_sec  = floor (ti);
    res.tv_usec = ((ti - floor (ti)) * 1000000);
    return res;
}

@implementation Date

+ date { return [[self alloc] init]; }

+ dateWithTimeIntervalSinceNow:(TimeInterval)secs
{
    return [[self alloc] initWithTimeIntervalSinceNow:secs];
}

+ dateWithTimeIntervalSince1970:(TimeInterval)secs
{
    return [[self alloc] initWithTimeIntervalSince1970:secs];
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
    [super init];
    seconds = _currentTime ();
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

- (uintptr_t)hash { return (unsigned)seconds; }

- (BOOL)isEqual:(id)otherObject
{
    if (otherObject == nil)
        return NO;
    if ([otherObject isKindOf:Date] && DblComp (seconds, [otherObject seconds]))
        return YES;
    return NO;
}

- (int)compare:anObject { return (int)(seconds - [anObject seconds]); }

- (Date *)earlierDate:(Date *)otherDate
{
    return [otherDate seconds] < seconds ? otherDate : (Date *)self;
}

- (Date *)laterDate:(Date *)otherDate
{
    return [otherDate seconds] > seconds ? otherDate : (Date *)self;
}

/* Intervals adding and subtracting */

- (Date *)addTimeInterval:(TimeInterval)sec
{
    return [[self copy] setSeconds:seconds + sec];
}

- (TimeInterval)timeIntervalSince1970 { return seconds; }

- (TimeInterval)timeIntervalSinceDate:(Date *)otherDate
{
    return seconds - [otherDate seconds];
}

- (TimeInterval)timeIntervalSinceNow { return seconds - _currentTime (); }

/* Extract components */

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