/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#import "Object.h"
#import "Dictionary.h"

@interface KVOStore : Object
{
} :
{
    /* This is a dictionary of VolatileReferences corresponding to the objects
     * that own the property represented in a keypath.
     * It maps to another dictionary; a dictionary of property names mapped to
     * a set of KPObservers. */
    Dictionary * ownerRefToKPObserverDict;
}
@end