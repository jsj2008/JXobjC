/* Copyright (c) 2015 D. Mackay. All rights reserved. */

#include "encxpr.h"

@implementation Encode

+ new { return [[super new] op:"@encode"]; }

- typesynth
{
    type = t_str;
    return self;
}

- synth
{
    typeForEncoding = [typeForEncoding synth];
    return self;
}

- gen
{
    gf ("\"%s\"", [[typeForEncoding encode] str]);
    return self;
}

@end