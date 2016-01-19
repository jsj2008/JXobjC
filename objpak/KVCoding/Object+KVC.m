/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#include <ctype.h>

#import "Block.h"
#import "KVOStore.h"
#import "MutableString.h"
#import "OrdCltn.h"
#import "KVC.h"
#import "Pair.h"

@implementation Object (KeyValueCoding)

- valueForKey:key
{
    SEL get;

    if (!key)
        return nil;

    get = selUid ([key str]);
    if (!get)
        return nil;

    if ([self respondsTo:get])
    {
        /* Later, it will be a good idea to take advantage of type information
         * associated with a class, that we can handle arbitrary return types,
         * not just id. */
        return [self perform:get];
    }
    return nil;
}

- (void)setValue:value forKey:key
{
    id strSet;
    SEL set;

    if (!key)
        return;

    strSet = [key mutableCopy];
    [[[strSet at:0 insert:"set" count:3] concatSTR:":"]
        charAt:3
           put:toupper ([strSet charAt:3])];

    set = selUid ([strSet str]);

    if ([self respondsTo:set])
    {
        /* Later, it will be a good idea to take advantage of type information
         * associated with a class, that we can handle arbitrary return types,
         * not just id. */
        [self perform:set with:value];
    }

#ifndef OBJC_REFCNT
    [strSet free];
#endif
}

- (Pair *)resolveKeyPathFirst:keyPath
{
    Pair * indirector$remainder = [Pair new];
    OrdCltn * components         = [keyPath componentsSeparatedByString:@"."],
            * first               = nil;

    first = [components removeFirst];

    if (![components size])
    {
        indirector$remainder.second = first;
    }
    else
    {
        indirector$remainder.first = first;
        indirector$remainder.second =
            [components componentsJoinedByString:@"."];
    }

#ifndef OBJC_REFCNT
    [[components freeContents] free];
#endif

    return indirector$remainder;
}

- valueForKeyPath:keyPath
{
    id result = nil, indirector = nil;
    Pair * resolved = [self resolveKeyPathFirst:keyPath];

    if (!resolved.first)
        result = [self valueForKey:resolved.second];
    else
    {
        indirector = [self valueForKey:resolved.first];
        result     = [indirector valueForKeyPath:resolved.second];
    }

#ifndef OBJC_REFCNT
    [resolved free];
#endif

    return result;
}

- (void)setValue:value forKeyPath:keyPath
{
    id indirector   = nil;
    Pair * resolved = [self resolveKeyPathFirst:keyPath];

    if (!resolved.first)
        [self setValue:value forKey:resolved.second];
    else
    {
        indirector = [self valueForKey:resolved.first];
        [indirector setValue:value forKeyPath:resolved.second];
    }

#ifndef OBJC_REFCNT
    [resolved free];
#endif
}

@end