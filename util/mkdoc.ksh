#!/usr/bin/env sh

cd doc
rm -f masterTOC.html
rm -rf Runtime
mkdir -p Runtime
headerdoc2html -o `pwd`/Runtime -p `pwd`/../objcrt/hdr
gatherheaderdoc .