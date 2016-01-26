#include "OrdCltn.h"
#include "classdef.h"

@implementation ClassDef (NFI)

- (int)indexOfIVar:(Symbol *)aSym startingPoint:(size_t *)index
{
    Symbol * potentialIVar = nil;

    if (superc)
    {
        int potentialResult = [super indexOfIVar:aSym startingPoint:index];
        if (potentialResult != -1)
            return potentialResult;
    }

    potentialIVar = [ivarnames findMatching:aSym];

    if (potentialIVar)
        return *index + [ivarnames offsetOf:potentialIVar];

    *index += [ivars size];
    return -1;
}

- (int)indexOfIVar:(Symbol *)aSym
{
    size_t startingPoint = 0;
    return [self indexOfIVar:aSym startingPoint:&startingPoint];
}

@end