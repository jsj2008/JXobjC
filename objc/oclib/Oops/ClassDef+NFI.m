#include "Exceptn.h"
#include "OrdCltn.h"
#include "classdef.h"
#include "identxpr.h"
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
        [[[t_int deepCopy] decl:mkarraydecl (nil, nil)] ampersand];
    [trlunit defdata:[self offsetsTableSymbol_factory:NO] astype:longPtrsArray];
    [trlunit defdata:[self offsetsTableSymbol_factory:YES]
              astype:longPtrsArray];
    return self;
}

- (IndexExpr *)offsetEntryForVar:(Symbol *)aVar isFactory:(BOOL)isFactory
{
    ConstantExpr * subXpr = nil;
    int idx               = isFactory ? [self indexOfCVar:aVar] : [self indexOfIVar:aVar];

    if (idx == -1)
        [Exception signal:"Var not found"];
    subXpr = mkconstexpr ([[Symbol sprintf:"%d", idx] type:t_int], nil);

    return mkindexexpr (mkidentexpr ([self offsetsTableSymbol_factory:NO]),
                        subXpr);
}

- (Expr *)fastAddressForVar:(Symbol *)aVar isFactory:(BOOL)isFactory
{
    Type * charPtrT = [[t_char deepCopy] ampersand];
    /* Note: if this is a cVar being accessed from an instance, this should
     * instead use self->isa. */
    Expr * castedSelf =
        mkprecexpr (mkcastexpr (charPtrT, [[e_self copy] lhsself:1]));
    Expr * offs =
        mkdereference ([self offsetEntryForVar:aVar isFactory:isFactory]);
    Type * varType =
        isFactory ? [self lookupcvar:aVar] : [self lookupivar:aVar];
    return mkdereference (mkcastexpr (
        [varType ampersand], mkprecexpr (mkbinexpr (castedSelf, "+", offs))));
}

- (Expr *)fastAddressForIVar:(Symbol *)aVar
{
    return [self fastAddressForVar:aVar isFactory:NO];
}

- (Expr *)fastAddressForCVar:(Symbol *)aVar
{
    return [self fastAddressForVar:aVar isFactory:YES];
}

- genVarOffsetVars_isForFactory:(BOOL)isFactory className:(String *)aName
{
    OrdCltn * varnames;
    const char * pszName = [aName ?: classname str];
    const char cSuffix   = isFactory ? 'c' : 'i';

    if (!isFactory)
        (varnames = ivarnames);
    else
        (varnames = cvarnames);

    if (superc)
        [superc genVarOffsetVars_isForFactory:isFactory
                                    className:aName ?: classname];

    if (varnames)
        for (int i = 0, n = [varnames size]; i < n; i++)
            gf ("static long __%s_%c_%s_offset = 0;\n", pszName, cSuffix,
                [[varnames at:i] str]);

    return self;
}

- genVarOffsetsArray_isForFactory:(BOOL)isFactory className:(String *)aName
{
    OrdCltn * varnames;
    const char * pszName = [aName ?: classname str];
    const char cSuffix   = isFactory ? 'c' : 'i';

    if (!isFactory)
        (varnames = ivarnames);
    else
        (varnames = cvarnames);

    if (!aName)
        gf ("static long * __%s_%c_offsets[] =\n{\n", pszName, cSuffix);

    if (superc)
        [superc genVarOffsetsArray_isForFactory:isFactory
                                      className:aName ?: classname];

    if (varnames)
        for (int i = 0, n = [varnames size]; i < n; i++)
            gf ("&__%s_%c_%s_offset,\n", pszName, cSuffix,
                [[varnames at:i] str]);

    if (!aName)
        gf ("};\n");

    return self;
}

@end