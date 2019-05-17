#!/bin/bash

tigcc -v --optimize-nops pdtlib.asm -o pdtlib

mv *.??z ../bin/
cp pdtlib.h ../include/asm

# Debug
cp ../bin/*.9xz ../../VTI
cp pdtlib.h ../../as/src
