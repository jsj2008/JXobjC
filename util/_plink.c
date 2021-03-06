
/* dummy def for compilers that require struct def */
struct modDescriptor
{
    int dummy;
};

extern struct modDescriptor * _OBJCBIND_postlink ();
extern struct modDescriptor * _OBJCBIND_unknownt ();
extern struct modDescriptor * _OBJCBIND_crt ();
extern struct modDescriptor * _OBJCBIND_cltn ();
extern struct modDescriptor * _OBJCBIND_stktrace ();
extern struct modDescriptor * _OBJCBIND_ConstantString ();
extern struct modDescriptor * _OBJCBIND_SideTable ();
extern struct modDescriptor * _OBJCBIND_outofbnd ();
extern struct modDescriptor * _OBJCBIND_badvers ();
extern struct modDescriptor * _OBJCBIND_Exceptn ();
extern struct modDescriptor * _OBJCBIND_Message ();
extern struct modDescriptor * _OBJCBIND_MutableString ();
extern struct modDescriptor * _OBJCBIND_Set ();
extern struct modDescriptor * _OBJCBIND_SetSequence ();
extern struct modDescriptor * _OBJCBIND_cltnseq ();
extern struct modDescriptor * _OBJCBIND_notfound ();
extern struct modDescriptor * _OBJCBIND_seltab ();
extern struct modDescriptor * _OBJCBIND_Object ();
extern struct modDescriptor * _OBJCBIND_typeinc ();
extern struct modDescriptor * _OBJCBIND_OCString ();
extern struct modDescriptor * _OBJCBIND_RtObject ();
extern struct modDescriptor * _OBJCBIND_OrdCltn ();
extern struct modDescriptor * _OBJCBIND_dictionary ();
extern struct modDescriptor * _OBJCBIND_OutOfMem ();
extern struct modDescriptor * _OBJCBIND_sequence ();
extern struct modDescriptor * _OBJCBIND_Array ();
extern struct modDescriptor * _OBJCBIND_mod ();
extern struct modDescriptor * _OBJCBIND_Block ();
extern struct modDescriptor * _OBJCBIND_memory ();
extern struct modDescriptor * _OBJCBIND_ascfiler ();
extern struct modDescriptor * _OBJCBIND_messenger ();

/* this must match objcrt.m datatype */
static struct modEntry
{
    struct modDescriptor * (*modLink) ();
    struct modDescriptor * modInfo;
} _msgControl[] = {{_OBJCBIND_postlink, 0},   {_OBJCBIND_unknownt, 0},
                   {_OBJCBIND_crt, 0},        {_OBJCBIND_cltn, 0},
                   {_OBJCBIND_stktrace, 0},   {_OBJCBIND_ConstantString, 0},
                   {_OBJCBIND_SideTable, 0},  {_OBJCBIND_outofbnd, 0},
                   {_OBJCBIND_badvers, 0},    {_OBJCBIND_Exceptn, 0},
                   {_OBJCBIND_Message, 0},    {_OBJCBIND_MutableString, 0},
                   {_OBJCBIND_Set, 0},        {_OBJCBIND_SetSequence, 0},
                   {_OBJCBIND_cltnseq, 0},    {_OBJCBIND_notfound, 0},
                   {_OBJCBIND_seltab, 0},     {_OBJCBIND_Object, 0},
                   {_OBJCBIND_typeinc, 0},    {_OBJCBIND_OCString, 0},
                   {_OBJCBIND_RtObject, 0},   {_OBJCBIND_OrdCltn, 0},
                   {_OBJCBIND_dictionary, 0}, {_OBJCBIND_OutOfMem, 0},
                   {_OBJCBIND_sequence, 0},   {_OBJCBIND_Array, 0},
                   {_OBJCBIND_mod, 0},        {_OBJCBIND_Block, 0},
                   {_OBJCBIND_memory, 0},     {_OBJCBIND_ascfiler, 0},
                   {_OBJCBIND_messenger, 0},  {0, 0}};

/* non-NULL _objcModules disables auto-init */
struct modEntry * _objcModules = _msgControl;
