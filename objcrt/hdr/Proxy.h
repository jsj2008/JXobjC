/* Copyright (c) 2016 D. Mackay. All rights reserved. */

#ifndef __PROXY_H__
#define __PROXY_H__

#include "objcrt.h"
#include <stdarg.h>
#include <string.h>
#include "RtObject.h"

/*!
 Proxy is a secondary root class in JX Objective-C.
 It is designed for use with classes that will act as proxies to other
 objects, whether they be instance variables of it or even on a remote
 server.
*/
@interface Proxy : RtObject
@end

#endif /* __OBJECT_H__ */
