#!/bin/bash

tigcc -v --optimize-nops pdtlib.asm -o pdtlib

mv *.??z ../bin/
cp pdtlib.h ../include/asm

# Debug (as dev)
cp ../bin/pdtlib.??z ../../VTI
cp pdtlib.h ../../as/src
cp pdtlib.h ../../test
