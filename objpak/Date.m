/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#include <sys/types.h>
#include <sys/time.h>
#include <time.h>

#import "Date.h"

#define DISTANT_FUTURE 63113990400.0
#define DISTANT_PAST -63113817600.0

static id _distantPast, _distantFuture;

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

- (unsigned int)microsecond;
- (unsigned int)second;
- (unsigned int)minute;
- (unsigned int)hour;

@end