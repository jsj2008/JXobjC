/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#include <ctype.h>

#import "Block.h"
#import "OCString.h"
#import "OrdCltn.h"
#import "Obj+KVC.h"

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

    strSet = [key copy];
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

- valueForKeyPath:keyPath { return nil; }

- (void)setValue:value forKeyPath:keyPath
{
    id components = [keyPath componentsSeparatedByString:@"."], indirStr = nil,
       indirector = nil;

    if ([components size] == 1)
        [self setValue:value forKey:keyPath];
    else
    {
        id newPath = [String new];

        indirStr = [components removeFirst];
        [components do:
                    { :each | [newPath concat:each];
                    }];
        indirector = [self valueForKey:indirStr];
        [indirector setValue:value forKeyPath:newPath];
    }

#ifndef OBJC_REFCNT
    [indirStr free];
    [[components freeContents] free];
#endif
}

@end