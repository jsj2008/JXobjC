#include <assert.h>
#include <stdlib.h>
#include "objc-type.h"

int JX_sizeof_type (TYP type)
{
    assert (type);

    switch (*type)
    {
    case T_VOID: return 0;
    case T_ID: return sizeof (id);
    case T_SEL: return sizeof (SEL);
    case T_CHAR: return sizeof (char);
    case T_UCHAR: return sizeof (unsigned char);
    case T_SHORT: return sizeof (short);
    case T_USHORT: return sizeof (unsigned short);
    case T_INT: return sizeof (int);
    case T_UINT: return sizeof (unsigned int);
    case T_LONG: return sizeof (long);
    case T_ULONG: return sizeof (unsigned long);
    case T_FLOAT: return sizeof (float);
    case T_DOUBLE: return sizeof (double);
    case T_LONGLONG: return sizeof (long long);
    case T_ULONGLONG: return sizeof (unsigned long long);

    case T_PTR:
    case T_STR: return sizeof (char *);

    case T_ARRAY:
    {
        TYP aryType;
        int length = strtol (++type, &aryType, 10);
        return length * JX_sizeof_type (aryType);
    }

    default: printf ("Error: unknown type encoding %s\n", type); return 0;
    }
}

TYP JX_skip_type (TYP type)
{
    switch (*type)
    {
    case T_VOID:
    case T_ID:
    case T_SEL:
    case T_CHAR:
    case T_UCHAR:
    case T_SHORT:
    case T_USHORT:
    case T_INT:
    case T_UINT:
    case T_LONG:
    case T_ULONG:
    case T_FLOAT:
    case T_DOUBLE:
    case T_LONGLONG:
    case T_ULONGLONG:
    case T_STR: type++; break;

    case T_PTR: type = JX_skip_type (++type); break;

    case T_ARRAY:
        do
            type++;
        while (*type != ']');
        type++;
        break;

    case T_STRUCT:
    {
        int depth = 1;
        do
            if (*type == '{')
                depth++;
            else if (*type == '}')
                depth--;
        while (type++ && depth != 0);
        type++;
        break;
    }

    default: printf ("Error: unknown type encoding %s\n", type);
    }

    return type;
}