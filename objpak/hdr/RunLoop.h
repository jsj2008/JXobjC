/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import "Object.h"
#import "OrdCltn.h"

@interface RunLoop : Object
{
    OrdCltn * _timers;
} : 
{
    id mainRunLoop;
}

@property BOOL running;

+ (RunLoop *)mainRunLoop;
+ (RunLoop *)currentRunLoop;

@end