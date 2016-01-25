#include "OrdCltn.h"
#include "classdef.h"

@implementation ClassDef (NFI)

- (int)indexOfIVar:(Symbol *)aSym startingPoint:(size_t *)index
{
    Symbol * potentialIVar = 0;

    if (superc)
    {
        int potentialResult;
        if ((potentialResult = [super indexOfIVar:aSym startingPoint:index]) !=
            -1)
            return *index + potentialResult;
    }

    potentialIVar = [ivarnames findMatching:aSym];

    if (potentialIVar)
    {
        return [ivarnames offsetOf:potentialIVar];
    }

    *index += [ivars size];
    return -1;
}

- (int)indexOfIVar:(Symbol *)aSym
{
    size_t * startingPoint = 0;
    return [self indexOfIVar:aSym startingPoint:startingPoint];
}

@end