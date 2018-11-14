#!/bin/bash

tigcc -v --optimize-nops pdtlib.asm -o pdtlib.asm

mv *.??z ../bin/

# Debug
cp ../bin/*.9xz ../../VTI
cp pdtlib.h ../../as/src

