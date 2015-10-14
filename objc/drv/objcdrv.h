#pragma once

#if defined(DRVUNIX)

#warning UNIX

#ifndef DINSTALLDIRC
#define DINSTALLDIRC "/usr/local"
#endif
#define DGCPREFIXC "/usr/local"

#define DCC "cc"
#define DCCPLUS "CC"
#define DCPP "cc -E"
#define DLD "cc"
#define DRM "rm -f"
#define DCAT "cat"
#define DNM "nm"

#define DCPPFILTER ""
#define DOBJC1FILTER ""

#define DOC_CPARGS "-D__PORTABLE_OBJC__"
#define DOC_OCARGS "-gnu -shortTags"
#define DOC_CCARGS ""
#define DOC_LDARGS ""

#define DAOUTNAME "a.out"

#define DPRINTFSYSTEM 0
#define DPOSTLINK 0
#define DSHORTCMDLINE 0
#define DUSELFLAG 0

#define DOBJSUFFIX "o"
#define DLIBSUFFIX "a"
#define DCPPSUFFIX "P"
#define DDOTSHLIBSUFFIX ".so"

#define DCCMINUSCFLAG "-c"
#define DCCMINUSOFLAG "-o"
#define DLDMINUSOFLAG "-o"
#define DCCMINUSIFLAG "-I"
#define DCCMINUSDFLAG "-D"
#define DCPPMINUSOFLAG " > "

#define DPICFLAG "-fpic"
#define DSTATICFLAG "-static"
#define DPICOCARGS ""
#define DDLARGS "-bogus"
#define DDLFILE "objcdlso.ld"
#define DDLXLDARGS ""
#define DDLXCCARGS ""
#define DPLLDARGS ""

#define DCCDOLLARFLAG "-fdollars-in-identifiers"
#define DCPPIMPORTFLAG "-x objective-c -Wno-import"

#define DLINKFORMAT "unix"

#elif defined(DRVWATCOM)

#warning WAT

#ifndef DINSTALLDIRC
#define DINSTALLDIRC "\\jxobjc"
#endif
#define DGCPREFIXC "\\jxobjc"

#define DCC "wcc386"
#define DCCPLUS "wcc386"
#define DCPP "wcc386 -ppl"
#define DLD "wlink"
#define DRM "del"
#define DCAT "cat"
#define DNM "nm"

#define DCPPFILTER "fixwcpp"
#define DOBJC1FILTER ""

#define DOC_CPARGS "-D__PORTABLE_OBJC__"
#define DOC_OCARGS "-gnu -msdos -watcom -linemax 127"
#define DOC_CCARGS "-zq"
#define DOC_LDARGS "option caseexact"

#define DAOUTNAME "a.exe"

#define DPRINTFSYSTEM 0
#define DPOSTLINK 1
#define DSHORTCMDLINE 1
#define DUSELFLAG 0

#define DOBJSUFFIX "obj"
#define DLIBSUFFIX "lib"
#define DCPPSUFFIX "P1"
#define DDOTSHLIBSUFFIX "_s.lib"

#define DCCMINUSCFLAG ""
#define DCCMINUSOFLAG "-fo="
#define DLDMINUSOFLAG "-fo="
#define DCCMINUSIFLAG "-i="
#define DCCMINUSDFLAG "-D"
#define DCPPMINUSOFLAG "-fo="

#define DPICFLAG "-bd -br"
#define DSTATICFLAG "-static"
#define DPICOCARGS "-dllexport"
#define DDLARGS "system nt_dll initinstance terminstance"
#define DDLFILE "objcdlnt.wat"
#define DDLXLDARGS ""
#define DDLXCCARGS "-br"
#define DPLLDARGS "option map=postlink.map"

#define DCCDOLLARFLAG ""
#define DCPPIMPORTFLAG ""

#define DLINKFORMAT "watcom"

#endif