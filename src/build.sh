#!/bin/bash

tigcc -v --optimize-nops pdtlib.asm -o pdtlib

mv *.??z ../bin/
cp pdtlib.h ../include/asm

# Debug (as dev)
cp ../bin/*.9xz ../../VTI
cp pdtlib.h ../../as/src

# Debug (test)
cp ../bin/*.9xz ../../test
cp pdtlib.h ../../test
cp ../bin/*.9xz ../../testc
cp ../include/c/pdtlib.h ../../testc
