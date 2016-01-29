#include "Exceptn.h"
#include "OrdCltn.h"
#include "classdef.h"
#include "expr.h"
#include "indexxpr.h"
#include "constxpr.h"
#include "trlunit.h"
#include "type.h"
#include "util.h"

@implementation ClassDef (NFI)

- (int)indexOfVar:(Symbol *)aSym
    startingPoint:(size_t *)index
        isFactory:(BOOL)isFactory
{
    Symbol * potentialIVar = nil;
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

- (Symbol *)offsetsTableSymbol_factory:(BOOL)isFactory
{
    return [Symbol
        sprintf:"__%s_%c_offsets", [self classname], isFactory ? 'c' : 'i'];
}

- declareOffsetTables
{
    Type * longPtrsArray =
        [[[t_int deepCopy] ampersand] decl:mkarraydecl (nil, nil)];
    [trlunit def:[self offsetsTableSymbol_factory:NO] astype:longPtrsArray];
    [trlunit def:[self offsetsTableSymbol_factory:YES] astype:longPtrsArray];
    return self;
}

- (IndexExpr *)offsetEntryForVar:(Symbol *)aVar isFactory:(BOOL)isFactory
{
    ConstantExpr * subXpr = nil;
    int idx               = isFactory ? [self indexOfCVar:aVar] : [self indexOfIVar:aVar];

    if (idx == -1)
        [Exception signal:"Var not found"];
    subXpr = mkconstexpr ([[Symbol sprintf:"%d", idx] type:t_int], nil);

    return mkindexexpr ([self offsetsTableSymbol_factory:NO], subXpr);
}

@end