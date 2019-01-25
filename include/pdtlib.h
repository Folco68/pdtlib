#ifndef PDTLIB_H
#define PDTLIB_H

#include "ramcall.h"

// pdtlib_ParseCmdline callback prototypes
typedef int (*CB_NotASwitch)(void* Data asm("a0"));
typedef int (*CB_Switch)(void* Data asm("a0"), int Sign asm("d0"));

// CMDLINE structure which must be passed to Pdtlib when using command line functions
typedef struct CMDLINE {
    int a;
    long b;
    int c;
} CMDLINE;

// Pdtlib exported functions. Define export, rank, prototype and type definitions
#define pdtlib_InstallTrampolines pdtlib__0000
#define PDTLIB_INSTALL_TRAMPOLINES 0
LibRef* pdtlib_InstallTrampolines(char* LibName asm("a0"), char Version asm("d1"), unsigned int* FunctionTable asm("a1"), unsigned int* OffsetTable asm("a2"), char* BaseAddress asm("a3"));
typedef LibRef* (*pdtlib_InstallTrampolines_t)(char* LibName asm("a0"), char Version asm("d1"), unsigned int* FunctionTable asm("a1"), unsigned int* OffsetTable asm("a2"), char* BaseAddress asm("a3"));

#define pdtlib_InitCmdline pdtlib__0001
#define PDTLIB_INIT_CMDLINE 1
void pdtlib_InitCmdline(CMDLINE* CmdLine asm("a0"), char** Argv asm("a1"), int Argc asm("d0"));
typedef void (*pdtlib_InitCmdline_t)(CMDLINE* CmdLine asm("a0"), char** Argv asm("a1"), int Argc asm("d0"));

#define pdtlib_ResetCmdline pdtlib__0002
#define PDTLIB_RESET_CMDLINE 2
void pdtlib_ResetCmdline(CMDLINE* CmdLine asm("a0"));
typedef void (*pdtlib_ResetCmdline_t)(CMDLINE* CmdLine asm("a0"));

#define pdtlib_GetNextArg pdtlib__0003
#define PDTLIB_GET_NEXT_ARG 3
char* pdtlib_GetNextArg(CMDLINE* CmdLine asm("a0"));
typedef char* (*pdtlib_GetNextArg_t)(CMDLINE* CmdLine asm("a0"));

#define pdtlib_GetCurrentArg pdtlib__0004
#define PDTLIB_GET_CURRENT_ARG 4
char* pdtlib_GetCurrentArg(CMDLINE* CmdLine asm("a0"));
typedef char* (*pdtlib_GetCurrentArg_t)(CMDLINE* CmdLine asm("a0"));

#define pdtlib_ParseCmdline pdtlib__0005
#define PDTLIB_PARSE_CMDLINE 5
int pdtlib_ParseCmdline(CMDLINE* CmdLine, void* Data, char* SwitchTable, CB_NotASwitch* NotASwitch, CB_Switch* Switch, ...);
typedef int (*pdtlib_ParseCmdline_t)(CMDLINE* CmdLine, void* Data, char* SwitchTable, CB_NotASwitch* NotASwitch, CB_Switch* Switch, ...);

#define pdtlib_GetFilePtr pdtlib__0006
#define PDTLIB_GET_FILE_PTR 6
void* pdtlib_GetFilePtr(char* FileName asm("a0"));
typedef void* (*pdtlib_GetFilePtr_t)(char* FileName asm("a0"));

#define pdtlib_CheckFileType pdtlib__0007
#define PDTLIB_CHECK_FILE_TYPE 7
int pdtlib_CheckFileType(char* Filename asm("a0"), char* CustomTag asm("a1"), char Tag asm("d2"));
typedef int (*pdtlib_CheckFileType_t)(char* Filename asm("a0"), char* CustomTag asm("a1"), char Tag asm("d2"));
 
#define pdtlib_InstallTrampolines_C pdtlib__0008
#define PDTLIB_INSTALL_TRAMPOLINES_C 8
LibRef* pdtlib_InstallTrampolines_C(LibRef* Libref, unsigned int* FunctionTable, unsigned int* OffsetTable, char* BaseAddress);
typedef LibRef* (*pdtlib_InstallTrampolines_C_t)(LibRef* Libref, unsigned int* FunctionTable, unsigned int* OffsetTable, char* BaseAddress);

// Return values of pdtlib_ParseCmdline
#define PDTLIB_END_OF_PARSING       0
#define PDTLIB_INVALID_SWITCH       1
#define PDTLIB_SWITCH_NOT_FOUND     2
#define PDTLIB_INVALID_RETURN_VALUE 3
#define PDTLIB_STOPPED_BY_CALLBACK  4

// Size of a CMDLINE structure
#define PDTLIB_CMDLINE_SIZEOF       8

// Return values of CLI callbacks
#define PDTLIB_CONTINUE_PARSING     0
#define PDTLIB_STOP_PARSING         1

#endif // PDTLIB_H
