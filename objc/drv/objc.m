/*
 * Portable Object Compiler (c) 1997,98.  All Rights Reserved.
 *
 * $Id: objc.m.in,v 1.3 2004/07/24 18:50:39 stes Exp $
 *
 * @WARNING@
 */

#include "config.h"
#include <stdio.h>		/* printf,tmpnam */
#include <stdlib.h>		/* getenv */
#include <signal.h>		/* signal */
#include "ocstring.h"
#include "ordcltn.h"
#include "sequence.h"
#include <string.h>		/* strtok */
#include "drv/objcdrv.h"

/*
 * This program is supposed to be exactly equivalent in functionality
 * to the Bourne shell driver "objc".  The only difference being that it
 * is written in Objective C (for the MS-DOS port, or any platform where
 * we don't have a /bin/sh).
 *
 * Note that objc.exe is not the compiler itself: the compiler is called
 * objc1.
 * It is the "driver" for the different steps (cpp,objc1,cc etc.) involved
 * in compiling an Objective C file.
 *
 * Ideally, we would have been able to use a Bourne shell driver
 * on all platforms, because it has many advantages (in terms of
 * flexibility)
 * over a compiled, binary, driver.  For now, we try to maintain the two
 * implementations in parallel.  And a binary version has the potential
 * advantage of being faster (although we're sceptical...).
 *
 * On MS-DOS, only this program is available (as OBJC.EXE).
 * On UNIX, "objc" is the Bourne shell driver, which can be configured to
 * invoke this program (objc.exe), or objc.exe can simply be renamed "objc".
 */

BOOL comments = NO;
BOOL precompile = YES;
BOOL compile = YES;
BOOL link = YES;
BOOL linkdl = NO;
BOOL include = YES;
BOOL uselibs = YES;
BOOL blocks = YES;
BOOL ppi = NO;
BOOL verbose = NO;
BOOL printfsystem = DPRINTFSYSTEM;
BOOL debug = NO;
BOOL dynamic = NO;
BOOL retain = NO;
BOOL retaincpp = NO;
BOOL profile = NO;
BOOL useoutput = NO;
BOOL cplusplus = NO;
BOOL postlink = DPOSTLINK;
BOOL shortcmdline = DSHORTCMDLINE;
BOOL runxstr = NO;

STR objcrt="objcrt";
STR objpak="objpak";
STR cakit="cakit";

STR objsuffix = DOBJSUFFIX;	/* o/obj for UNIX/DOS */
STR libsuffix = DLIBSUFFIX;	/* a/lib for UNIX/DOS */
STR cppsuffix = DCPPSUFFIX;	/* .P sometimes .i if it's hardcoded */
STR dotobjsuffix = "." DOBJSUFFIX;	/* o/obj for UNIX/DOS */
STR dotlibsuffix = "." DLIBSUFFIX;	/* a/lib for UNIX/DOS */
STR dotshlibsuffix = DDOTSHLIBSUFFIX; /* _s.lib or .so DOS/UNIX */
STR dotdllsuffix = ".dll";
BOOL uselflag = DUSELFLAG;

STR ccminuscflag = DCCMINUSCFLAG;	/* -c on UNIX, empty on WATCOM/MPW */
STR ccminusoflag = DCCMINUSOFLAG;	/* -o on UNIX, -fo= on WATCOM */
STR ldminusoflag = DLDMINUSOFLAG;	/* -o on UNIX, /OUT: on MSVC */
STR ccminusiflag = DCCMINUSIFLAG;	/* -I on UNIX, -i= on WATCOM */
STR ccminusdflag = DCCMINUSDFLAG;	/* -D on UNIX, -d  on MPW */
STR cppminusoflag = DCPPMINUSOFLAG;	/* > on UNIX, -fo= on WATCOM */

STR picflag = DPICFLAG;
STR staticflag = DSTATICFLAG;
STR picocargs = DPICOCARGS;
STR dlargs = DDLARGS;
STR dlfile = DDLFILE;
STR dlxldargs = DDLXLDARGS;
STR dlxccargs = DDLXCCARGS;

STR linkformat = DLINKFORMAT;	/* unix or watcom */

/*
 * Utilities for verbose logging.
 */

static void 
setbool(BOOL *global, const char *name, BOOL value)
{
  if (verbose)
    fprintf(stderr,"%s=%s\n", name, (value) ? "YES" : "NO");
  *global = value;
}

static void 
setstring(id *global, const char *name, id value)
{
  if (verbose)
    fprintf(stderr,"%s=\"%s\"\n", name, [value str]);
  *global = value;
}

STR pathsep;

static void 
dfltpathsep(void)
{
  pathsep = getenv("OBJCPATHSEP");
  pathsep = (pathsep) ? pathsep : OBJCRT_DEFAULT_PATHSEPC;
}

static id 
basnam(STR s, STR sep)
{
  int m;

  if (s && (m = strlen(s))) {
    STR x = s + m;
    int n = strlen(sep);

    while (--x != s)
      if (strncmp(x, sep, n) == 0) {
	x += n;
	break;
      }
    return [String str:x];
  } else {
    return [String new];
  }
}

static id 
debuglib(id basnam)
{
  return [[[basnam copy] concatSTR:"_g"] concatSTR:dotlibsuffix];
}

static id 
sharedlib(id basnam)
{
  return [[basnam copy] concatSTR:dotshlibsuffix];
}

static id 
proflib(id basnam)
{
  return [[[basnam copy] concatSTR:"_p"] concatSTR:dotlibsuffix];
}

static id 
staticlib(id basnam)
{
  return [[basnam copy] concatSTR:dotlibsuffix];
}

/*
 * Default value for objcdir.
 * Defaults to "INSTALLDIR", can be set as environment variable.
 * Can also later be overridden using the -B option.
 */

id objcdir;

static void 
dfltobjcdir(void)
{
  char *s = getenv("OBJCDIR");

  /* use INSTALLDIRC, not INSTALLDIR here (for double backslash) */
  setstring(&objcdir, "objcdir", [String str:(s) ? s : DINSTALLDIRC]);
}

id tmpdir; /* it's actually a path prefix, not a directory */

static void 
dflttmpdir(void)
{
  char *s = getenv("TMPDIR");

  if (s) {
    id p = [String sprintf:"%s%s", s, pathsep];

    setstring(&tmpdir, "tmpdir", p);
  }
}

/*
 * Set values for bin, lib and include directories.
 * Using objcdir but only after -B option.
 */

id bindir;
id libdir;
id hdrdir;
id  gcdir; /* in fact the prefix */

static id 
addprefix(id path, id element)
{
  return [String sprintf:"%s%s", [path str], [element str]];
}

static id 
pathcat(id path, char *element)
{
  return [String sprintf:"%s%s%s", [path str], pathsep, element];
}

static id 
makeD(char *element)
{
  /* this can be -Delement, -d element */
  return [String sprintf:"%s%s", ccminusdflag, element];
}

static id 
makeI(id dir,char *element)
{
 if (element) {
  id path = pathcat(dir, element);
  /* this can be -Ipath, -i path, or -i=path */
  return [String sprintf:"%s%s", ccminusiflag, [path str]];
 } else {
  return [String sprintf:"%s%s", ccminusiflag, [dir str]];
 }
}

static id 
makeO(char *element)
{
  if (strlen(ccminusoflag)) {
    /* this can be -o , -fo= etc. */
    return [String sprintf:"%s%s", ccminusoflag, element];
  } else {
    /* on LCC it's implicit, can't specify output */
    return [String new];
  }
}

static id 
makeldO(char *element)
{
  /* this can be -o, -fo=, /OUT: etc. */
  return [String sprintf:"%s%s", ldminusoflag, element];
}

static void 
setbindir(id prefix)
{
  setstring(&bindir, "bindir", pathcat(prefix, "bin"));
  setstring(&libdir, "libdir", pathcat(prefix, "lib"));
  setstring(&hdrdir, "hdrdir", pathcat(prefix, "include"));
}

/*
 * LIB stuff
 */

id libs;
id finlibs;

static BOOL 
isreadable(id input)
{
  FILE *f;

  /*
   * this compiles easier everywhere compared to stat() stuff
   */

  f = fopen([input str], "r");
  if (f)
    fclose(f);
  return f != NULL;
}

static void 
addlib(STR nam)
{
  id lib;
  id basnam = pathcat(libdir,nam);

  if (profile) {
    lib = proflib(basnam);
    if (isreadable(lib)) {
      [libs add:lib];
      return;
    }
  }
  if (debug) {
    lib = debuglib(basnam);
    if (isreadable(lib)) {
      [libs add:lib];
      return;
    }
  }
  if (dynamic) {
    lib = sharedlib(basnam);
    if (isreadable(lib)) {
      if (uselflag) {
	[libs add:[[String str:"-L"] concatSTR:[libdir str]]];
	[libs add:[[String str:"-l"] concatSTR:nam]];
	return;
      } else {
	[libs add:lib];
	return;
      }
    }
  }
  lib = staticlib(basnam);
  if (isreadable(lib)) {
    [libs add:lib];
  } else {
    fprintf(stderr, "objc: warning: can't find %s\n",[lib str]);
  }
}

static void 
addlibs(void)
{
  addlib(cakit);
  addlib(objpak);
  addlib(objcrt);
}

/*
 * The default initcall for NeXT is oc_objcInit (to avoid a name
 * clash with their runtime initializer _objcInit).  On all other
 * platforms it is currently _objcInit.
 *
 * For cross compiles, the -init option overrides the value set here.
 */

id initcall;

static void 
dfltinitcall(void)
{
  setstring(&initcall, "initcall", [String str:"oc_objcInit"]);
}

/*
 * Some binary names.
 */

id cc;
id cxx;
id ld;
id postlinkexe;
id cpp;
id xstr;
id cppfilter;
id objc1filter;
id xstrdb;

static void 
dfltbins()
{
  char *s;

  s = getenv("CC");
  cc = ([String str:(s) ? s : DCC]);

  s = getenv("CCPLUS");
  cxx = ([String str:(s) ? s : DCCPLUS]);

  s = getenv("CPP");
  cpp = ([String str:(s) ? s : DCPP]);

  s = getenv("LD");
  ld = ([String str:(s) ? s : DLD]);

  xstr = ([String str:"xstr"]);

  s = getenv("CPPFILTER");
  cppfilter = ([String str:(s) ? s : DCPPFILTER]);

  s = getenv("OBJC1FILTER");
  objc1filter = ([String str:(s) ? s : DOBJC1FILTER]);
}

/*
 * Default Argument Lists.
 * These are implemented as OrdCltn instances, so that we can later
 * easily add additional String instances.
 */

id cpargs;
id ocargs;
id ccargs;
id ldargs;

static id 
addifnonempty(id aCltn, char *s)
{
  id str = [String str:s];

  if ([str size])
    [aCltn add:str];
  return aCltn;
}

static void 
dfltargs(void)
{
  cpargs = addifnonempty([OrdCltn new], DOC_CPARGS);
  ocargs = addifnonempty([OrdCltn new], DOC_OCARGS);
  ccargs = addifnonempty([OrdCltn new], DOC_CCARGS);
  ldargs = addifnonempty([OrdCltn new], DOC_LDARGS);
}

/*
 * Default Inputs.
 */

id output;
id actionc;
id actioncc;
id inputs;
id extensions;
id actions;

/* default output "a.exe" for DOS, "a.out" on UNIX */
STR aout = DAOUTNAME;

static void 
dfltinputs(void)
{
  output = [String str:aout];
  actionc = [String str:"c"];
  actioncc = [String str:"cc"];
  inputs = [OrdCltn new];
  extensions = [OrdCltn new];
  actions = [OrdCltn new];
}

/*
 * All Defaults.  Assumed to be called before doptions().
 */

static void 
ddefaults(void)
{
  dfltpathsep();
  dfltobjcdir();
  dflttmpdir();
  dfltbins();
  dfltargs();
  dfltinputs();
  dfltinitcall();

  libs = [OrdCltn new];
  finlibs = [OrdCltn new];
}

/*
 * Version and Usage messages.
 */

static void 
dumpfile(FILE * f)
{
  char linebuf[BUFSIZ + 1];

  while (fgets(linebuf, BUFSIZ, f) != NULL) {
    if (fputs(linebuf, stdout) == EOF)
      break;
  }

  if (ferror(f))
    fprintf(stderr, "objc: error reading file\n");
}

/* system cat will not work on the Mac */
static void 
dumpfilenamed(STR s)
{
  FILE *f;

  if ((f = fopen(s, "r"))) {
    dumpfile(f);
    fclose(f);
  } else {
    printf("objc: can't access %s\n", s);
  }
}

static void 
usage(void)
{
  id n;

  setbindir(objcdir);		/* force def */
  n = pathcat(libdir, "objchelp.txt");
  if (!isreadable(n))
    fprintf(stderr, "objc: can't open %s", [n str]);
  dumpfilenamed([n str]);
}

static void 
pversion(void)
{
  printf("JXObjC Objective-C Compile and Link Utility (@NAME@ - @TARGET@)\n");
  printf("Use is subject to licence terms.\n");
}

/*
 * Auxiliaries for parsing command line arguments.
 */

static int 
mystrlen(const char *s)
{
  int c = 0;

  while (*s++)
    c++;
  return c;
}

static BOOL 
prefixtest(const char *s, const char *prefix)
{
  int c;

  while ((c = *prefix++))
    if (*s++ != c)
      return NO;
  return YES;
}

#define streq(x,y) (strcmp((x),(y)) == 0)

static BOOL 
suffixtest(const char *s, const char *suffix)
{
  int c;

  s += mystrlen(s) - mystrlen(suffix);
  while ((c = *suffix++))
    if (*s++ != c)
      return NO;
  return YES;
}

static id 
delprefix(id arg, const char *prefix)
{
  return [String str:[arg str] + mystrlen(prefix)];
}

static id 
replacesuffix(id input, id oldsuffix, STR newsuffix)
{
  id base = basnam([input str], pathsep);

  if ([base size] >= [oldsuffix size]) {
    id res = [String chars:[base str] count:[base size] - [oldsuffix size]];

    [res concatSTR:newsuffix];
    return res;
  } else {
    return base;
  }
}

/*
 * Mac libs to link by default (allow to override with env.var).
 */

#define OBJC_SIOUX_LIBS "\"{MWPPCLibraries}MathLib\" \"{MWPPCLibraries}InterfaceLib\" \"{MWPPCLibraries}MSL RuntimePPC.Lib\" \"{MWPPCLibraries}MSL C.PPC.Lib\""

#define OBJC_MPW_LIBS "\"{MWPPCLibraries}MathLib\" \"{MWPPCLibraries}InterfaceLib\" \"{MWPPCLibraries}MSL MPWCRuntime.Lib\" \"{MWPPCLibraries}MSL MPW C.PPC.Lib\" \"{MWPPCLibraries}PPCToolLibs.o\""

#define OBJC_APPL_LIBS "\"{MWPPCLibraries}MathLib\" \"{MWPPCLibraries}InterfaceLib\" \"{MWPPCLibraries}MWStdCRuntime.Lib\" \"{MWPPCLibraries}StdCLib\" \"{MWPPCLibraries}PPCToolLibs.o\""

/*
 * Parsing command line arguments.
 */

#define eq(x) ([arg isEqualSTR:x])
#define isprefix(x) (prefixtest([arg str],x))
#define issuffix(x) (suffixtest([arg str],x))
#define shiftarg() (arg = [args next])

static id envoptions(id aCltn, STR s);

static void 
doptions(id args)
{
  id arg;

  while ((arg = [args next])) {

    /* option for DOS where we have limits on cmd line length */
    if (isprefix("@")) {
      id cltn;
      id name = delprefix(arg, "@");

      if ((cltn = envoptions([OrdCltn new], [name str]))) {
	doptions([cltn eachElement]);
      } else {
	fprintf(stderr, "objc: no '%s' file or env.variable",
		[name str]);
	exit(-1);
      }

      continue;
    }
    if (eq("-c")||eq("-Fo")) {
      link = NO;
      continue;
    }
    if (eq("-C")||eq("-Fi")||eq("-Fii")) {
      link = NO;
      compile = NO;
      retain = YES;
      comments = YES; /* when used with -E */
      continue;
    }
    if (eq("-objc") || eq("-ObjC")) {
      actionc = [String str:"m"];
      actioncc = [String str:"mm"];
      continue;
    }
    if (eq("-dollars")) {
      [ccargs add:[String str:DCCDOLLARFLAG]];
      continue;
    }
    if (eq("-ObjCpp") || eq("-import")) {
      [cpargs add:[String str:DCPPIMPORTFLAG]];
      continue;
    }
    if (eq("-cplus")) {
      cplusplus = YES;
      postlink = YES;
      continue;
    }
    if (eq("-dump")) {
      link = NO;
      compile = NO;
      retain = YES;
      [ocargs add:[String str:"-objc"]];
      continue;
    }
    if (eq("-errout")) {
      STR fname = [shiftarg() str];
      if (!freopen(fname,"w",stderr)) {
	fprintf(stderr,"Can't open %s\n",fname);
      }
      continue;
    }
    if (eq("-export")) {
      [ocargs add:arg];
      [ocargs add:shiftarg()];
      continue;
    }
    if (eq("-dllexport")) {
      [ocargs add:arg];
      continue;
    }
    if (eq("-E")) {
      link = NO;
      precompile = NO;
      continue;
    }
    if (eq("-i")) {
      [cpargs add:arg];
      continue;			/* tcc */
    }
    if (eq("-N")) {
      [cpargs add:arg];
      continue;
    }
    if (eq("-nostdinc")) {
      [cpargs add:arg];
      continue;
    }
    if (eq("-ppi")) {
      [ocargs add:arg];
      [ocargs add:[String str:"-oneperfile -noFwd -noBlocks"]];
      [ccargs add:[String str:DCCDOLLARFLAG]];
      [cpargs add:[String str:DCPPIMPORTFLAG]];
      ppi = 1;
      continue;
    }
    if (eq("-noobjcinc") || eq("-noI")) {
      include = NO;
      continue;
    }
    if (eq("-noLibs")) {
      uselibs = NO;
      continue;
    }
    if (eq("-noBlocks")) {
      blocks = NO;
      continue;
    }
    if (eq("-noFiler")) {
      [ocargs add:arg];
      continue;
    }
    if (eq("-fwd")) {
      [ocargs add:arg];
      continue;
    }
    if (eq("-noFwd")) {
      [ocargs add:arg];
      continue;
    }
    if (eq("-noSelfAssign")) {
      [ocargs add:arg];
      continue;
    }
    if (eq("-noCategories")) {
      [ocargs add:arg];
      continue;
    }
    if (eq("-noCache")) {
      [ocargs add:arg];
      continue;
    }
    if (eq("-noNilRcvr")) {
      [ocargs add:arg];
      continue;
    }
    if (eq("-debugInfo")) {
      [ocargs add:arg];
      continue;
    }
    /* watcom debug */
    if (eq("-d0") || eq("-d1") || eq("-d1+")
	|| eq("-d2t") || eq("-d2i") || eq("-d2")
	|| eq("-d3")) {
      debug = YES;
      [ccargs add:arg];
      continue;
    }
    /* watcom stuff per ronny */
    if (eq("-dos")) {
      [ldargs add:[String str:"system dos4g"]];
      continue;
    }
    if (eq("-win95")) {
      [ldargs add:[String str:"system win95"]];
      continue;
    }
    /* MSVC debug */
    if (eq("-Zi") || eq("-Zd") || eq("/Zi")
	|| eq("/Zd")) { 
      debug = YES;
      [ccargs add:arg];
      continue;
    }
    /* watcom building dll's */
    /* difference with -pic is that -pic also does -dllexport */
    if (eq("-bd") || eq("-br")) {
      [ccargs add:arg];
      continue;
    }
    /* watcom building for dos4g etc. */
    if (isprefix("-bt=")) {
      [ccargs add:arg];
      continue;
    }
    /* watcom turn off optimize */
    if (eq("-od")) {
      [ccargs add:arg];
      continue;
    }
    /* watcom some optimize option combinations */
    if (eq("-oneatxh")) {
      [ccargs add:arg];
      continue;
    }
    /* watcom stack overflow checks */
    if (eq("-s")) {
      [ccargs add:arg];
      continue;
    }
    /* watcom register/stack calling conventions */

    if (eq("-3r")) {
      [ccargs add:arg];
      continue;
    }
    if (eq("-3s")) {
      [ccargs add:arg];
      continue;
    }
    if (eq("-4r")) {
      [ccargs add:arg];
      continue;
    }
    if (eq("-4s")) {
      [ccargs add:arg];
      continue;
    }
    if (eq("-5r")) {
      [ccargs add:arg];
      continue;
    }
    if (eq("-5s")) {
      [ccargs add:arg];
      continue;
    }
    if (eq("-6r")) {
      [ccargs add:arg];
      continue;
    }
    if (eq("-6s")) {
      [ccargs add:arg];
      continue;
    }
    /* Macintosh mpw debug -sym on */
    if (eq("-sym")) {
      [ccargs add:arg];
      [ccargs add:shiftarg()];
      debug = eq("on");
      continue;
    }
    if (eq("-st80")) {
      [ocargs add:arg];
      continue;
    }
    /* Macintosh mpw optimizing flags */
    if (eq("-opt")) {
      [ccargs add:arg];
      [ccargs add:shiftarg()];
      continue;
    }
    if (eq("-g")) {
      debug = YES;
      [ccargs add:arg];
      continue;
    }
    /* UNIX style -o flag to native style */
    if (eq("-o")) {
      useoutput = YES;
      output = shiftarg();
      continue;
    }
    if (eq("-pg")) {
      profile = YES;
      [ldargs add:arg];
      [ccargs add:arg];
      continue;
    }
    if (eq("-q") || eq("-quiet")) {
      [ocargs add:[String str:"-quiet"]];
      continue;
    }
    if (eq("-u") || eq("-unbuf")) {
      [ocargs add:[String str:"-u"]];
      continue;
    }
    if (eq("-help") || eq("--help")) {
      usage();
      exit(0);
    }
    if (eq("-usage") || eq("--usage")) {
      usage();
      exit(0);
    }
    if (eq("-version") || eq("--version")) {
      pversion();
      exit(0);
    }
    if (eq("-init")) {
      initcall = shiftarg();
      continue;
    }
    if (eq("-main")) {
      [ocargs add:arg];
      [ocargs add:shiftarg()];
      continue;
    }
    if (eq("-builtinfunction") || eq("-builtinFunction")) {
      [ocargs add:[String str:"-builtinfunction"]];
      [ocargs add:shiftarg()];
      continue;
    }
    if (eq("-builtintype") || eq("-builtinType")) {
      [ocargs add:[String str:"-builtintype"]];
      [ocargs add:shiftarg()];
      continue;
    }
    if (eq("-retain")) {
      retain = YES;
      retaincpp = YES;
      continue;
    }
    if (eq("-retaincpp")) {
      retaincpp = YES;
      continue;
    }
    if (eq("-xstr")) {
      runxstr = YES;
      xstrdb = shiftarg();
      continue;
    }
    if (eq("-noSelTbl")) {
      [ocargs add:arg];
      continue;
    }
    if (eq("-undef")) {
      [cpargs add:arg];
      [ccargs add:arg];
      continue;
    }
    if (eq("-mpwtool")) {
      STR t = getenv("OBJCMPWLIBS");

      t = (t) ? t : OBJC_MPW_LIBS;
      /* the following works with MWLinkPPC and PPCLink */
      [ldargs add:[String str:"-c 'MPS ' -t MPST"]];
      /* depends on MWLinkPPC and PPCLink */
      [libs add:[String str:t]];
      continue;
    }
    if (eq("-sioux")) {
      STR t = getenv("OBJCSIOUXLIBS");

      t = (t) ? t : OBJC_SIOUX_LIBS;
      /* Metrowerks Sioux app */
      [libs add:[String str:t]];
      continue;
    }
    if (eq("-appl")) {
      STR t = getenv("OBJCAPPLLIBS");

      t = (t) ? t : OBJC_APPL_LIBS;
      /* regular Mac app */
      [libs add:[String str:t]];
      continue;
    }
    if (eq("-static")) {
      [libs add:[String str:staticflag]];
      continue;
    }
    if (eq("-pic")) {
      [ccargs add:[String str:picflag]];
      [ocargs add:[String str:picocargs]];	/* like -dllexport */
      [ocargs add:[String str:"-noShared"]];

      /* idea here is to not define objcInit() when compiling
       * objcrt as a DLL (with -pic)
       * this means that user will *have* to use -dynamic
       * to use the DLL
       */

      [cpargs add:makeD("OBJCRT_NOSHARED")];
      continue;
    }
    if (eq("-fpic")) {
      [ccargs add:arg];
      continue;
    }
    if (eq("+z")) {
      [ccargs add:arg];
      continue;
    }
    if (eq("+Z")) {
      [ccargs add:arg];
      continue;
    }
    if (eq("-dl")) {
      linkdl = YES;
      postlink = YES;
      continue;
    }
    if (eq("-dlx") || eq("-dynamic")) {
      [ldargs add:[String str:dlxldargs]];
      [ccargs add:[String str:dlxccargs]];
      [ocargs add:[String str:"-noShared"]];
      initcall = [String str:"_objcInitNoShared"];
      dynamic = YES;
      continue;
    }
    if (eq("-linkFormat")) {
      linkformat = [shiftarg()str];
      continue;
    }
    /* metrowerks MWLinkPPC */
    if (eq("-xm")) {
      [ldargs add:arg];
      [ldargs add:shiftarg()];	/* app,sharedlibrary,mpwtool */
      continue;
    }
    if (eq("-inlinecache") || eq("-inlineCache")) {
      [ocargs add:[String str:"-inlinecache"]];
      continue;
    }
    if (eq("-oneperfile")) {
      [ocargs add:arg];
      continue;
    }
    if (eq("-printfSystem") || eq("-check")) {
      printfsystem = 1;
      continue;
    }
    if (eq("-otb")) {
      objcrt="otbcrt";
      objpak="otbpak";
      cakit="cakitb";
      [ocargs add:arg];
      [cpargs add:makeD("OTBCRT=1")];
      continue;
    }
    if (eq("-cthreads")) {
      objcrt="objcrtth";
      continue;
    }
    if (eq("-pthreads")) {
      objcrt="objcrtth";
      [finlibs add:[String str:"-lpthread"]];
      continue;
    }
    if (eq("-gc") || eq("-refcnt")) {
      objcrt="objcrtr";
      objpak="objpakr";
      [cpargs add:makeD("OBJC_REFCNT=1")];
      [ocargs add:arg];
      continue;
    }
    if (eq("-boehm")) {
      /* need double backslash ... don't use GCPREFIX */
      id gc = [String str:DGCPREFIXC];
      objcrt="objcrtgc";
      [cpargs add:makeI(gc,"include")];
      [finlibs add:staticlib(pathcat(pathcat(gc,"lib"),"gc"))];
      continue;
    }
    if (eq("-postlink") || eq("-postLink")) {
      postlink = YES;
      continue;
    }
    if (eq("-noPostlink") || eq("-noPostLink")) {
      postlink = NO;
      continue;
    }
    if (eq("-nolinetags") || eq("-noTags")) {
      [ocargs add:[String str:"-nolinetags"]];
      continue;
    }
    if (eq("-shortTags")) {
      [ocargs add:arg];
      continue;
    }
    if (eq("-objc1trace")) {
      [ocargs add:[String str:"-trace"]];
      continue;
    }
    if (eq("-v") || eq("-verbose")) {
      verbose = YES;
      continue;
    }
    if (eq("-w")) {
      [ocargs add:arg]; /* turns off all warnings */
      continue;
    }
    if (eq("-wClassUsedAsType")) {
      [ocargs add:arg];
      continue;
    }
    if (eq("-wTypeConflict")) {
      [ocargs add:arg];
      continue;
    }
    if (eq("-wLocalInstance")) {
      [ocargs add:arg];
      continue;
    }
    if (eq("-wUndefinedMethod")) {
      [ocargs add:arg];
      continue;
    }
    if (eq("-wInterfaceNotFound")) {
      [ocargs add:arg];
      continue;
    }
    if (eq("-Wall")) {
      [ccargs add:arg];
      continue;
    }
    if (eq("-WLex")) {
      [ocargs add:arg];
      continue;
    }
    if (isprefix("-cpOpt:")) {
      [cpargs add:delprefix(arg, "-cpOpt:")];
      continue;
    }
    if (isprefix("-cppOpt:")) {
      [cpargs add:delprefix(arg, "-cppOpt:")];
      continue;
    }
    if (isprefix("-ocOpt:")) {
      [ocargs add:delprefix(arg, "-ocOpt:")];
      continue;
    }
    if (isprefix("-objc1Opt:")) {
      [ocargs add:delprefix(arg, "-objc1Opt:")];
      continue;
    }
    if (isprefix("-ccOpt:")) {
      [ccargs add:delprefix(arg, "-ccOpt:")];
      continue;
    }
    if (isprefix("-Wc:")) {
      [ccargs add:delprefix(arg, "-Wc:")];
      continue;
    }
    if (isprefix("-Wc,")) {
      [ccargs add:delprefix(arg, "-Wc,")];
      continue;
    }
    if (isprefix("-ldOpt:")) {
      [ldargs add:delprefix(arg, "-ldOpt:")];
      continue;
    }
    if (isprefix("-Wl,")) {
      [ldargs add:delprefix(arg, "-Wl,")];
      continue;
    }
    if (isprefix("-Wl:")) {
      [ldargs add:delprefix(arg, "-Wl:")];
      continue;
    }
    if (eq("-64")) {
      [ccargs add:arg];
      continue;
    }
    if (eq("-32")) {
      [ccargs add:arg];
      continue;
    }
    if (eq("-n32")) {
      [ccargs add:arg];
      continue;
    }
    if (eq("-noobject")) {
      [ccargs add:arg];
      continue;
    }
    if (eq("-migrate")) {
      [ccargs add:arg];
      continue;
    }
    if (eq("-assume")) {
      [ccargs add:arg];
      [ccargs add:shiftarg()];
      continue;
    }
    if (isprefix("-mips")) {
      [ccargs add:arg];
      continue;
    }
    if (isprefix("-w")) {
      [ccargs add:arg];
      continue;
    }
    if (isprefix("-edit")) {
      [ccargs add:arg];
      continue;
    }
    if (issuffix(".h")) {
      [inputs add:arg];
      [extensions add:[String str:"h"]];
      [actions add:[String str:"m"]];
      continue;
    }
    if (issuffix(".m")) {
      [inputs add:arg];
      [extensions add:[String str:"m"]];
      [actions add:[String str:"m"]];
      continue;
    }
    if (issuffix(".c")) {
      [inputs add:arg];
      [extensions add:[String str:"c"]];
      [actions add:actionc];
      continue;
    }
    if (issuffix(".cc")) {
      [inputs add:arg];
      [extensions add:[String str:"cc"]];
      [actions add:actioncc];
      cplusplus = YES;
      postlink = YES;
      continue;
    }
    if (issuffix(".C")) {
      [inputs add:arg];
      [extensions add:[String str:"C"]];
      [actions add:actioncc];
      cplusplus = YES;
      postlink = YES;
      continue;
    }
    if (issuffix(".cpp")) {
      [inputs add:arg];
      [extensions add:[String str:"cpp"]];
      [actions add:actioncc];
      cplusplus = YES;
      postlink = YES;
      continue;
    }
    if (issuffix(".cxx")) {
      [inputs add:arg];
      [extensions add:[String str:"cxx"]];
      [actions add:actioncc];
      cplusplus = YES;
      postlink = YES;
      continue;
    }
    if (issuffix(".mm")) {
      [inputs add:arg];
      [extensions add:[String str:"mm"]];
      [actions add:[String str:"mm"]];
      cplusplus = YES;
      postlink = YES;
      continue;
    }
    /* for matching the dot is important */
    if (issuffix(dotobjsuffix)) {
      [inputs add:arg];
      [extensions add:[String str:objsuffix]];
      [actions add:[String str:objsuffix]];
      continue;
    }
    if (issuffix(dotlibsuffix)) {
      [libs add:arg];
      continue;
    }
    if (issuffix(".so")) {
      [libs add:arg];
      continue;
    }
    /* try to translate to native style (-d ) on MPW */
    if (isprefix("-D")) {
      id e = delprefix(arg, "-D");

      e = makeD([e str]);
      [ccargs add:e];
      continue;
    }
    if (isprefix("-U")) {
      [ccargs add:arg];
      continue;
    }
    if (isprefix("-Y")) {
      [ccargs add:arg];
      continue;			/* tcc */
    }
    /* accept native convention (-i) on MPW */
    if (eq(ccminusiflag)) {
      [cpargs add:arg];
      [cpargs add:shiftarg()];
      continue;
    }
    /* accept native convention (-i= etc.) on WATCOM */
    if (isprefix(ccminusiflag)) {
      [cpargs add:arg];
      continue;
    }
    /* try to translate UNIX option to native style */
    if (isprefix("-I")) {
      id path = delprefix(arg, "-I");

      [cpargs add:[String sprintf:"%s%s", ccminusiflag, [path str]]];
      continue;
    }
    if (isprefix("-L")) {
      [libs add:arg];
      continue;
    }
    if (isprefix("-l")) {
      [libs add:arg];
      continue;
    }
    if (isprefix("-O")) {
      [ccargs add:arg];
      continue;
    }
    if (isprefix("-g")) {
      [ccargs add:arg];
      continue;
    }
    if (isprefix("-B")) {
      objcdir = delprefix(arg, "-B");
      continue;
    }
    if (isprefix("-T")) {
      tmpdir = delprefix(arg, "-T");
      continue;
    }
    if (isprefix("-") || isprefix("/")) {
      [ccargs add:arg];
      continue;
    }
    fprintf(stderr, "objc: Illegal option or file %s\n", [arg str]);
    exit(1);
  }
}

/*
 * This implements the "set $OBJCOPT $*" that we have in the beginning
 * of the Bourne shell driver.
 */

static id 
stroptions(id aCltn, char *s)
{
  char *p;
  char *delims = " \t\n\r";
  id buffer = [String str:s];

  p = strtok([buffer str], delims);

  while (p != NULL) {
    [aCltn add:[String str:p]];
    p = strtok(NULL, delims);
  }

  return aCltn;
}

static id 
fileoptions(id aCltn, FILE * f)
{
  char buf[BUFSIZ + 1];

  while (!feof(f)) {
    if (fgets(buf, BUFSIZ, f)) {
      /* this works 'cause strtok also deletes \n */
      stroptions(aCltn, buf);
    }
  }

  return aCltn;
}

/* this is mostly for MS-DOS cmd line length limitations */

static id 
envoptions(id aCltn, STR s)
{
  STR t;
  FILE *f;

  /* maybe there's such an environment variable */
  if ((t = getenv(s)))
    return stroptions(aCltn, t);

  /* maybe there's such a file */
  if ((f = fopen(s, "r"))) {
    aCltn = fileoptions(aCltn, f);
    fclose(f);
    return aCltn;
  }
  /* nope */
  return nil;
}

static id 
eacharg(int argc, char **argv)
{
  id cltn = [OrdCltn new];

  envoptions(cltn, "OBJCOPT");	/* no error if absent */
  while (argc--)
    [cltn add:[String str:*argv++]];
  return [cltn eachElement];
}

/*
 * These are assigned a value after doptions().
 */

id objc1;
id objfiles;
id objcplus1;

static void 
setglobals()
{
  /* because this is ran after doptions(),
   * that is after verbose is possibly set to YES,
   * this is a good location for logging values to the user
   */

  setbindir(objcdir);
  if (tmpdir)
    setstring(&tmpdir, "tmpdir", tmpdir);
  setstring(&cc, "cc", cc);
  setstring(&cpp, "cpp", cpp);
  setstring(&cppfilter, "cppfilter", cppfilter);
  setstring(&objc1filter, "objc1filter", objc1filter);
  setstring(&objc1, "objc1", pathcat(bindir, "objc1"));
  setstring(&objcplus1, "objcplus1", pathcat(bindir, "objc1"));

  objfiles = [OrdCltn new];

  if (cplusplus) {
    [ocargs add:[String str:"-cplus"]];
    [ocargs add:[String str:"-noFwd"]];
  }
  setbool(&postlink, "postlink", postlink);
  setstring(&postlinkexe, "postlink", pathcat(bindir, "postlink"));

  if (postlink) {
    [ocargs add:[String str:"-postlink"]];
    [ldargs add:[String str:DPLLDARGS]];
  }
  [[ocargs add:[String str:"-init"]] add:initcall];

  if (include) {
    [cpargs add:makeI(hdrdir,"objcrt")];
    [cpargs add:makeI(hdrdir,"objpak")];
    [cpargs add:makeI(hdrdir,"cakit")];
    [cpargs add:makeI(hdrdir,NULL)];
  }
  if (ppi) {
    [cpargs add:makeI(hdrdir,"ppi")];
  }
  if (blocks) {
    [cpargs add:makeD("OBJC_BLOCKS=1")];
  } else {
    [cpargs add:makeD("OBJC_BLOCKS=0")];
    [ocargs add:[String str:"-noBlocks"]];
  }
}

/*
 * Deleting temporary files.
 */

static BOOL 
systemcall(id command)
{
  /* the MPW driver can't use system() since, (although defined for ANSI)
   * it doesn't do anything on the Mac.  we set printfsystem=1 for this
   * driver (the commands are redirected to the MPW shell).
   */

  if (verbose || printfsystem)
    fprintf(stderr,"%s\n", [command str]);

  /* in addition the metrowerks libs don't define system() at all */

#if OBJC_HAVE_SYSTEM_CALL
  return (printfsystem) ? YES : (system([command str]) != -1);
#else
  return YES;			/* no system() stub available, e.g. Metrowerks MWCPPC */
#endif
}

static id 
unlinkfile(id file)
{
#if 0
  char *s = [file str];

  /* we could do this using unlink(),
   * but the header location is nonstandard
   */
  if (verbose)
    fprintf(stderr,"removing %s\n", s);
  if (unlink(s) == -1)
    printf("error while removing %s\n", s);
#endif

  id cmd = [String sprintf:DRM "%s", [file str]];

  if (!systemcall(cmd)) {
    fprintf(stderr, "objc: could not remove %s\n", [file str]);
    /* don't exit if "del" fails : sort of -f option */
  }
  return file;
}

static void 
unlinkfiles(id files)
{
  id file;

  while ((file = [files removeLast]))
    unlinkfile(file);
}

/*
 * SIGINT Handler.
 * Upon hitting Control-C, we unlink the files in junk.
 */

id junk;

static void 
exits(int status)
{
  unlinkfiles(junk);
  exit(status);
}

static void 
sighandler(int i)
{
  printf("objc: *** Interrupt\n");

  /* very unlikely to be a problem, but in
   * theory you need to set noCacheFlag when
   * sending objc messages from within a handler
   * because the signal might have been delivered while
   * the message lookup cache was being updated for one of
   * the messages that is being sent from within the handler
   */

#ifdef __PORTABLE_OBJC__
  noCacheFlag = 1;
#endif

  exits(1);
}

/*
 * Passing commands to the shell
 */

static id 
catargs(id command, id args)
{
  id arg;

  while ((arg = [args next])) {
    [command concatSTR:" "];
    [command concatSTR:[arg str]];
  }
  return command;
}

static void 
saveargs(STR filename, id args)
{
  FILE *f = fopen(filename, "w");

  if (f) {
    id arg;

    while ((arg = [args next])) {
      fputs([arg str], f);
      fputs(" ", f);
    }
    fclose(f);
  } else {
    fprintf(stderr, "objc: could not write options to file '%s'\n", filename);
  }

  /* ld.opt is twice added with same value */
  if (!retain)
    [junk addIfAbsentMatching:[String str:filename]];
}

/*
 * drvcmd() takes two collections as arguments.
 * The first collection is passed in the WATCOM 10.0 case via a @file.
 * The second collection are those arguments that need to be specified
 * on the command line.
 */

static BOOL 
drvcmd(id command, STR optfile, id arguments, id filenames)
{
  id cmd;

  if (optfile != NULL && shortcmdline) {
    saveargs(optfile, [arguments eachElement]);
    cmd = [[[command copy] concatSTR:" @"] concatSTR:optfile];
  } else {
    cmd = catargs([command copy], [arguments eachElement]);
  }

  if (filenames)
    cmd = catargs(cmd, [filenames eachElement]);
  return systemcall(cmd);
}

/*
 * Processing Inputs
 */

static id 
outputfor(id input, id extension)
{
  if (useoutput && !link) {
    return output;
  } else {
    return replacesuffix(input, extension, objsuffix);
  }
}

static void 
processO(id input, id extension)
{
  [objfiles add:input];
}

static void 
processA(id input, id extension)
{
  /* for the WATCOM the difference matters (can't put it in objfiles) */
  [libs add:input];
}

static BOOL 
drivercpp1(id input, id result)
{
  id cargs, filenames;

  cargs = [OrdCltn new];
  [cargs addAll:ccargs];	/* can contain stuff like -ansi */
  [cargs addAll:cpargs];	/* cpp specific */

  filenames = [OrdCltn new];
  [filenames add:input];

  /* by setting cppminusoflag, suppress output file (lcc -E case) */
  if (strlen(cppminusoflag)) {
    /* '>' would for WATCOM redirect error messages into the file */
    [filenames add:[String sprintf:"%s%s", cppminusoflag, [result str]]];
  }
  return drvcmd(cpp, "cpp.opt", cargs, filenames);
}

/*
 * Ugly hack for SGI cc preprocessor.
 * On SGI (only there as far as I know, although that it may
 * happen on other systems) cc -E file.m is defining
 * FORTRAN_LANGUAGE.  In other words, it wants the suffix to be
 * .c of the file, or it doesn't consider the source file to be C.
 * We can work around this (by undefining FORTRAN_LANGUAGE etc.)
 * or by invoking the /lib/cpp directly instead of using the cc -E
 * interface, but this has many disadvantages (such as that our
 * work-around for IRIX5.3 didn't work on IRIX6,2).
 * I believe therefore that the best way to deal with this, is to
 * effectively make a .c copy of the input file before running cc -E.
 *
 * (might want to use a flag to only do this on SGI, or platforms that
 * need it)
 */

static BOOL 
maketmpviacat(id mfile, id cfile)
{
  id cmd = [String sprintf:DCAT " %s > %s", [mfile str], [cfile str]];

  return systemcall(cmd);
}

static BOOL 
maketmpc(id mfile, id cfile)
{
  if (printfsystem) {
    /* this is for MPW */
    return maketmpviacat(mfile, cfile);
  } else {
    BOOL ok = YES;
    FILE *mf, *cf;

    cf = fopen([cfile str], "w");
    mf = fopen([mfile str], "r");

    if (cf != NULL && mf != NULL) {
      int c;
      fprintf(cf, "#line 1 \"%s\"\n", [mfile str]);
      while ((c = fgetc(mf)) != EOF) {
	if (fputc(c,cf) == EOF) {ok = NO;break;}
      }
      if (ferror(mf)) ok = NO;
      fclose(mf);
      fclose(cf);
      return ok;
    } else {
      return NO;
    }
  }
}

static BOOL 
havefilter(id aFilter)
{
  return aFilter != nil
      && [aFilter isEqualSTR:"none"] == NO
      && [aFilter isEqualSTR:""] == NO;
}

static BOOL 
driverfilter(id aFilter, id input, id result)
{
  id cargs = [OrdCltn new];

  [cargs add:input];
  [cargs add:result];

  return drvcmd(aFilter, NULL, cargs, nil);
}

static BOOL 
drivercpp(id input, id extension, id result)
{
  BOOL success;
  id fixed = nil;
  BOOL fixfile = havefilter(cppfilter);

  if (fixfile) {
    fixed = result;
    result = replacesuffix(input, extension, cppsuffix);
    if (tmpdir)
      result = addprefix(tmpdir, result);
    /* this might cause the .i file to be added twice,
     * so use addIfAbsentMatching */
    if (!retaincpp)
      [junk addIfAbsentMatching:result];
  }
  if ([extension isEqualSTR:"c"]) {
    success = drivercpp1(input, result);
  } else {
    id tmpc = replacesuffix(input, extension, (cplusplus) ? "cc" : "c");

#if 0
    /* this is wrong on the DEC, for DEC cc this changes the include path */
    if (tmpdir)
      tmpc = addprefix(tmpdir, tmpc);
#endif

    success = maketmpc(input, tmpc);
    if (!retain)
      [junk add:tmpc];
    if (success)
      success = drivercpp1(tmpc, result);
  }

  if (fixfile) {
    if (success)
      success = driverfilter(cppfilter, result, fixed);
  }
  return success;
}

static BOOL 
driverobjc(id name, id extension, id input, id result)
{
  id cargs;
  BOOL success;
  id fixed = nil;
  BOOL fixfile = havefilter(objc1filter);

  if (fixfile) {
    fixed = result;
    result = replacesuffix(name, extension, "ix");
  }
  cargs = [OrdCltn new];
  [cargs addAll:ocargs];
  [cargs add:[String str:"-filename"]];
  [cargs add:name];
  [cargs add:input];
  [cargs add:result];

  success = drvcmd((cplusplus) ? objcplus1 : objc1, NULL, cargs, nil);

  if (fixfile) {
    if (success)
      success = driverfilter(cppfilter, result, fixed);
  }
  return success;
}

static BOOL 
drivercc(id input, id result)
{
  id cargs;
  id filenames;

  /* normal operation of the WATCOM is '-c' */
  /* MPW compilers don't emit a .o file when given -c */

  cargs = [OrdCltn new];
  cargs = [cargs add:[String str:ccminuscflag]];
  [cargs addAll:ccargs];
  [cargs addAll:cpargs]; /* so that -I works when compiling .c files */

  filenames = [OrdCltn new];
  [filenames add:input];

  if (useoutput) {
    /* -fo= on WATCOM, -o on UNIX */
    [filenames add:makeO([result str])];
  }
  return drvcmd((cplusplus) ? cxx : cc, "cc.opt", cargs, filenames);
}

/* this is for compiling _postlnk.c etc. (never use cplusplus here) */

static BOOL 
simplecc(id input, id ofile)
{
  id cargs, filenames;


  /* normal operation of the WATCOM is '-c' */
  /* MPW compilers don't emit a .o file when given -c */

  cargs = [OrdCltn new];
  cargs = [cargs add:[String str:ccminuscflag]];
  [cargs addAll:ccargs];

  filenames = [OrdCltn new];
  [filenames add:input];
  /* result must be _postlnk.o,not _postlink.c.o, on MPW */
  filenames = [filenames add:makeO([ofile str])];

  return drvcmd(cc, "cc.opt", cargs, filenames);
}


static void 
processC(id input, id extension)
{
  id result = outputfor(input, extension);

  if (compile && drivercc(input, result)) {
    [objfiles add:result];
  } else {
    exits(1);
  }
}

static void 
processM(id input, id extension)
{
  id result;
  id tmpp, tmpi;

  result = outputfor(input, extension);
  tmpp = replacesuffix(input, extension, "P");
  if (tmpdir)
    tmpp = addprefix(tmpdir, tmpp);
  tmpi = replacesuffix(input, extension, (cplusplus) ? "ii" : "i");
  if (tmpdir)
    tmpi = addprefix(tmpdir, tmpi);

  if (!retain)
    [junk add:tmpi];
  if (!retaincpp)
    [junk add:tmpp];

  /* -E -C changes the meaning of '-C' to preserve comments */
  if (!precompile && comments) [ccargs add:[String str:"-C"]];

  if (drivercpp(input, extension, tmpp)) {
    if (precompile) {
      if (driverobjc(input, extension, tmpp, tmpi)) {
	if (compile && drivercc(tmpi, result)) {
	  [objfiles add:result];
	} else {
	  exits(1);
	}
      } else {
	exits(1);
      }
    } else {
      dumpfilenamed([tmpp str]);	/* most portable way of -E */
    }
  } else {
    exits(1);
  }

  unlinkfiles(junk);
}

static void 
processinput(id input, id extension, id action)
{
/* don't want this warning in MPW -printfSystem case */
#if 0
  if (!isreadable(input))
    printf("objc: can't open %s\n", [input str]);
#endif

  if ([action isEqualSTR:"m"]) {
    processM(input, extension);
    return;
  }
  if ([action isEqualSTR:"mm"]) {
    processM(input, extension);
    return;
  }
  if ([action isEqualSTR:"c"]) {
    processC(input, extension);
    return;
  }
  if ([action isEqualSTR:"cc"]) {
    processC(input, extension);
    return;
  }
  if ([action isEqualSTR:objsuffix]) {
    processO(input, extension);
    return;
  }
  if ([action isEqualSTR:libsuffix]) {
    processA(input, extension);
    return;
  }
}

static void 
processinputs(void)
{
  int i, n;

  for (i = 0, n = [inputs size]; i < n; i++) {
    processinput([inputs at:i], [extensions at:i], [actions at:i]);
  }
}

/*
 * Processing Outputs
 */

/*
 * Regular link, using "ld".  Only possible if we have auto-initialization,
 * which requires support of the compiler for common storage of data.
 * UNIX compilers do this (on SGI it's an option).  WINDOWS does not.
 */

static BOOL 
unixld(void)
{
  id args, filenames;

  args = [OrdCltn new];
  [args addAll:ldargs];
  [args addAll:objfiles];
  [args addAll:libs];

  filenames = [OrdCltn new];
  [filenames add:makeldO([output str])];

  return drvcmd(ld, "ld.opt", args, filenames);
}

/*
 * This function is used from within Postlink on WATCOM.
 * It is NOT the way the final program is linked on WATCOM.
 * Uses wlink syntax, which is not UNIX compatible.
 */

static BOOL 
watcomld(void)
{
  id args, filenames;

  /* ldargs contains option map=postlink.map */
  args = [OrdCltn new];
  [args addAll:ldargs];

  /* stes 11/97 include all debug info; there also exists
   * "debug line" which maybe should be an option
   */

  if (debug) {
    [args add:[String str:"debug all"]];
  }
  if ([objfiles size]) {
    [args add:[String str:"file {"]];
    [args addAll:objfiles];
    [args add:[String str:"}"]];
  }
  if ([libs size]) {
    [args add:[String str:"library { "]];
    [args addAll:libs];
    [args add:[String str:" }"]];
  }
  filenames = [OrdCltn new];
  [filenames add:[String sprintf:"name %s", [output str]]];

  return drvcmd(ld, "ld.opt", args, filenames);
}

/*
 * MPW using Metrowerks compiler.
 */

static BOOL 
metrowerksld(void)
{
  return unixld();
}

/*
 * Microsoft MS VC.  Configured for automatic runtime init by default.
 */

static BOOL 
msvcld(void)
{
  return unixld();
}

/*
 * IBM VisualAge for C++ on OS/2.  Configured for automatic runtime init
 * by default.
 */

static BOOL 
ibmvacld(void)
{
  return unixld();
}

static BOOL 
driverld(void)
{
  if (streq(linkformat, "unix"))
    return unixld();
  if (streq(linkformat, "watcom"))
    return watcomld();
  if (streq(linkformat, "mpw"))
    return metrowerksld();
  if (streq(linkformat, "metrowerks"))
    return metrowerksld();
  if (streq(linkformat, "msvc"))
    return msvcld();
  if (streq(linkformat, "ibmvac"))
    return ibmvacld();
  fprintf(stderr, "objc: unknown link format '%s'", linkformat);
  return NO;
}

/*
 * postlink stuff.
 */

static BOOL 
unixplink(id image, id cfile)
{
  id cmd;
  char *fmt = DNM " %s | %s > %s";	/* default format is UNIX */

  cmd = [String sprintf:fmt, [image str], [postlinkexe str], [cfile str]];

  return systemcall(cmd);
}

static BOOL 
watcomplink(id image, id cfile)
{
  id cmd;
  char *fmt = "%s -f watcom - postlink.map %s";

  if (!retain)
    [junk add:[String str:"postlink.map"]];

  /* don't really need "image" unlike UNIX, but rather wlink map */
  /* this map is produced in the function watcomld() */
  cmd = [String sprintf:fmt, [postlinkexe str], [cfile str]];

  return systemcall(cmd);
}

static BOOL 
mwerksplink(id image, id cfile)
{
  id cmd;
  id postlinkprogram = pathcat(bindir, "postlink");
  char *fmt = "%s -f metrowerks - postlink.map %s";

  if (!retain)
    [junk add:[String str:"postlink.map"]];

  /* don't really need "image" unlike UNIX, but rather MW map */
  /* this map is produced in the function metrowerksld() */
  cmd = [String sprintf:fmt, [postlinkprogram str], [cfile str]];

  return systemcall(cmd);
}

static BOOL 
msvcplink(id image, id cfile)
{
  return watcomplink(image, cfile);
}

static BOOL 
ibmvacplink(id image, id cfile)
{
  id cmd;
  char *fmt = "%s -f ibmvac - postlink.map %s";

  if (!retain)
    [junk add:[String str:"postlink.map"]];

  /* don't really need "image" unlike UNIX, but rather icc map */
  /* this map is produced in the function ibmvacld() */
  cmd = [String sprintf:fmt, [postlinkexe str], [cfile str]];

  return systemcall(cmd);
}

static BOOL 
mkpostlink(id image, id cfile)
{
  if (streq(linkformat, "unix"))
    return unixplink(image, cfile);
  if (streq(linkformat, "watcom"))
    return watcomplink(image, cfile);
  if (streq(linkformat, "msvc"))
    return msvcplink(image, cfile);
  if (streq(linkformat, "mpw"))
    return mwerksplink(image, cfile);
  if (streq(linkformat, "metrowerks")) {
    return mwerksplink(image, cfile);
  }
  if (streq(linkformat, "ibmvac"))
    return ibmvacplink(image, cfile);
  fprintf(stderr, "objc: unknown link format '%s'", linkformat);
  return NO;
}

/*
 * Just a utility for performing the double link of "postlink"
 */

static BOOL 
linkstep1(id ofile)
{
  [objfiles add:ofile];
  if (!driverld())
    return NO;
  return (ofile == [objfiles remove:ofile]);
}

static BOOL 
linkstep2(id cfile, id ofile)
{
  if (!simplecc(cfile, ofile))
    return NO;
  else
    return linkstep1(ofile);
}

static BOOL 
dpostlink(STR prelink)
{
  id opre, cpost, opost;

  cpost = [String str:"_postlnk.c"];	/* 8+3 filename ! */
  opost = [String sprintf:"_postlnk.%s", objsuffix];

  /* prelink is a library file */
  opre = [String sprintf:"%s.%s", prelink, objsuffix];
  opre = pathcat(libdir, [opre str]);

  if (!isreadable(opre)) {
    fprintf(stderr, "Can't find file %s.", [opre str]);
    exit(1);
  }
  [junk add:opost];
  if (!retain) {
    [junk add:cpost];
  }
  [junk add:output];

  /* the executable produced in this first link will fail to work
   * it serves to run "postlink" on (to generate a table of
   * all classes in the image)
   */

  if (!linkstep1(opre))
    return NO;

  /* compile and link again */

  if (!mkpostlink(output, cpost))
    return NO;
  if (!linkstep2(cpost, opost))
    return NO;

  return (output == [junk remove:output]);
}

/*
 * Processing Outputs
 */

static void 
linkdynlib(void)
{
  id n;

  [ldargs add:[String str:dlargs]];

  /* small kludge, but already better than stuff
   * that was here before (which was totally win32 specific)
   * idea currently is to use -a option for postlink
   * so this can be customized for each platform by having
   * a specific objcdl file (objcdlnt.wat, objcdlos.vac  etc)
   */

  n = pathcat(libdir, dlfile);
  if (!isreadable(n))
    fprintf(stderr, "objc: can't open %s", [n str]);

  postlinkexe = [postlinkexe concatSTR:" -a "];
  postlinkexe = [postlinkexe concatSTR:[n str]];

  if (!dpostlink("_predll"))
    exits(1);
}

static void 
linkoutputs(void)
{
  if ((!linkdl && uselibs) || (linkdl && dynamic))
    addlibs();

  /* add stuff that needs to be at the end */
  [libs addAll:finlibs];

  if (linkdl) {
    linkdynlib();
  } else {
    if (postlink) {
      if (!dpostlink("_prelink"))
	exits(1);
    } else {
      if (!driverld())
	exits(1);
    }
  }
}

/*
 * Entry point.
 */

void 
main(int argc, char **argv)
{
  /* remove junk contents on SIGINT */
  junk = [OrdCltn new];
  signal(SIGINT, sighandler);

  ddefaults();

  if (argc == 1) {
    pversion();
    usage();
    exit(0);
  } else {
    doptions(eacharg(argc - 1, argv + 1));
  }

  setglobals();
  processinputs();

  if (link)
    linkoutputs();

  exits(0);
}


