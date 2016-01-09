#!/usr/bin/env sh

kmk cleandoc
cd doc
mkdir -p Runtime
headerdoc2html -o `pwd`/Runtime -p `pwd`/../objcrt/hdr
gatherheaderdoc `pwd`/Runtime index.html
