@echo off

REM Clean binary folder
del ..\bin\*.??z

REM Compile
tigcc -v --optimize-nops pdtlib.asm -o pdtlib.asm

REM Move binaries to binary folder
move *.??z ..\bin
