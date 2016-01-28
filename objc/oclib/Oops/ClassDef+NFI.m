#include "OrdCltn.h"
#include "classdef.h"

@implementation ClassDef (NFI)

- (int)indexOfVar:(Symbol *)aSym
    startingPoint:(size_t *)index
        isFactory:(BOOL)isFactory
{
    Symbol * potentialIVar = nil;
    OrdCltn * vars         = isFactory ? cvars : ivars;
    OrdCltn * varnames     = isFactory ? cvarnames : ivarnames;

    if (superc)
    {
        int potentialResult =
            [superc indexOfVar:aSym startingPoint:index isFactory:isFactory];
        if (potentialResult != -1)
            return potentialResult;
    }

    potentialIVar = [varnames findMatching:aSym];

    if (potentialIVar)
        return *index + [varnames offsetOf:potentialIVar];

    *index += [varnames size];
    return -1;
}

- (int)indexOfIVar:(Symbol *)aSym
{
    size_t startingPoint = 0;
    return [self indexOfVar:aSym startingPoint:&startingPoint isFactory:NO];
}

- (int)indexOfCVar:(Symbol *)aSym
{
    size_t startingPoint = 0;
    return [self indexOfVar:aSym startingPoint:&startingPoint isFactory:YES];
}

@end