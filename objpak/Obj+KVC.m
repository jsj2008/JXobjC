#include <ctype.h>

#import "ocstring.h"
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
    if (!set)
        return;

    if ([self respondsTo:set])
    {
        /* Later, it will be a good idea to take advantage of type information
         * associated with a class, that we can handle arbitrary return types,
         * not just id. */
        [self perform:set with:value];
    }
}

- valueForKeyPath:keyPath { return nil; }

- (void)setValue:value forKeyPath:keyPath {}

@end