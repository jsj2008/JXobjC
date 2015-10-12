#!/usr/bin/env sh

OBJCOPT="-C -noFwd -noFiler -postlink -noI"
OBJCOPT="${OBJCOPT} -init oc_objcInit -nostdinc -I../util/hdr -I./ -I."
export OBJCOPT="${OBJCOPT} -I../../util/hdr -D__dead2="

OBJC="objc ${OBJCOPT}"

rm -rf BootDist
mkdir BootDist
cd BootDist

OCLIB_SRCS="../objc/oclib/addrof.m ../objc/oclib/classdef.m ../objc/oclib/def.m ../objc/oclib/funcall.m ../objc/oclib/indexxpr.m ../objc/oclib/options.m ../objc/oclib/scalar.m ../objc/oclib/symbol.m
../objc/oclib/arrowxpr.m ../objc/oclib/commaxpr.m ../objc/oclib/deref.m ../objc/oclib/fundecl.m ../objc/oclib/initdecl.m ../objc/oclib/parmdef.m ../objc/oclib/selector.m ../objc/oclib/trlunit.m
../objc/oclib/arydecl.m ../objc/oclib/compdef.m ../objc/oclib/dfltstmt.m ../objc/oclib/fundef.m ../objc/oclib/keywdecl.m ../objc/oclib/parmlist.m ../objc/oclib/selxpr.m ../objc/oclib/type.m
../objc/oclib/aryvar.m ../objc/oclib/compstmt.m ../objc/oclib/dostmt.m ../objc/oclib/gasmop.m ../objc/oclib/keywxpr.m ../objc/oclib/pfixdecl.m ../objc/oclib/typeof.m
../objc/oclib/assign.m ../objc/oclib/condxpr.m ../objc/oclib/dotxpr.m ../objc/oclib/gasmstmt.m ../objc/oclib/lblstmt.m ../objc/oclib/pfixxpr.m ../objc/oclib/sizeof.m ../objc/oclib/unyxpr.m
../objc/oclib/bflddecl.m ../objc/oclib/constxpr.m ../objc/oclib/enumsp.m ../objc/oclib/gatrdecl.m ../objc/oclib/listxpr.m ../objc/oclib/pointer.m ../objc/oclib/stardecl.m ../objc/oclib/util.m
../objc/oclib/binxpr.m ../objc/oclib/contstmt.m ../objc/oclib/enumtor.m ../objc/oclib/gattrib.m ../objc/oclib/methdef.m ../objc/oclib/precdecl.m ../objc/oclib/stclass.m ../objc/oclib/var.m
../objc/oclib/blockxpr.m ../objc/oclib/cppdirec.m ../objc/oclib/expr.m ../objc/oclib/globdef.m ../objc/oclib/method.m ../objc/oclib/precxpr.m ../objc/oclib/stkframe.m ../objc/oclib/whilstmt.m
../objc/oclib/btincall.m ../objc/oclib/dasmstmt.m ../objc/oclib/exprstmt.m ../objc/oclib/gotostmt.m ../objc/oclib/msgxpr.m ../objc/oclib/propdef.m ../objc/oclib/stmt.m
../objc/oclib/casestmt.m ../objc/oclib/datadef.m ../objc/oclib/forstmt.m ../objc/oclib/identxpr.m ../objc/oclib/namedecl.m ../objc/oclib/relxpr.m ../objc/oclib/structsp.m
../objc/oclib/castxpr.m ../objc/oclib/decl.m ../objc/oclib/funbody.m ../objc/oclib/ifstmt.m ../objc/oclib/node.m ../objc/oclib/rtrnstmt.m ../objc/oclib/switstmt.m
../objc/oclib/propdef.m ../objc/oclib/protodef.m"
OBJC_SRCS="../../objc/objc1.m ../../objc/lexfiltr.m yacc.m lex.m"
PLINK_SRCS="../../objc/postlink.m"

mkdir objc
mkdir plink

${OBJC} -I../objcrt ../objcrt/*.m
${OBJC} -I../include/objcrt -I../objpak -I../objpak/hdr ../objpak/*.m
${OBJC} -I../include/objcrt -I../objpak/hdr -I../objc/oclib ${OCLIB_SRCS}

cd objc

byacc -dtv -o yacc.m ../../objc/yacc.ym
flex -o lex.m ../../objc/lex.lm
${OBJC} -I../../objc/oclib -I../../objcrt -I../../objpak/hdr ${OBJC_SRCS}

cd ../plink
${OBJC} -I../../objc/oclib -I../../objpak/hdr -I../../objpak -I../../objcrt ${PLINK_SRCS}
cd ../

cp ../util/_objc1.c ./objc
cp ../util/_plink.c ./plink

cat <<'EOF' > build.sh
#!/bin/sh

CC="gcc -x c"

${CC} -c *.i
cd objc && ${CC} -c *.i *.c && cd ../plink
${CC} -c *.i *.c && cd ../

gcc *.o objc/*.o -o objc1
gcc *.o plink/*.o -o postlink

EOF

chmod +x build.sh

cd ../
