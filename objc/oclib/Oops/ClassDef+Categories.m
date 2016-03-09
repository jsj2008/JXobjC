/*
 * Copyright © 2016 D. Mackay. All rights reserved.
 */

#import <OrdCltn.h>
#import "classdef.h"
#import "ClassDef+Categories.h"

@implementation ClassDef (Categories)

- addCategory:(ClassDef)aCategory
{
    if (!categories)
        categories = [OrdCltn new];
    [categories add:aCategory];
    return self;
}

@end
