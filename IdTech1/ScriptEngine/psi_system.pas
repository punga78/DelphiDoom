//------------------------------------------------------------------------------
//
//  DelphiDoom is a source port of the game Doom and it is
//  based on original Linux Doom as published by "id Software"
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2004-2022 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
// DESCRIPTION:
//  Pascal Script RTL - system import.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit psi_system;

interface

uses
  DelphiDoom.ScriptHost.System.Intf;

type
  // the same types as the arrays of TScriptSystemFunctions (a dynamic array is the same in memory)
  TDynamicIntegerArray = TArray<Integer>;
  TDynamicInt64Array = TArray<Int64>;
  TDynamicLongWordArray = TArray<LongWord>;
  TDynamicSingleArray = TArray<Single>;
  TDynamicDoubleArray = TArray<Double>;
  TDynamicExtendedArray = TArray<Extended>;

//==============================================================================
//
// PS_LevelTime
//
//==============================================================================
function PS_LevelTime: integer;

//==============================================================================
//
// PS_Write
//
//==============================================================================
procedure PS_Write(const parm: string);

//==============================================================================
//
// PS_WriteFmt
//
//==============================================================================
procedure PS_WriteFmt(const Fmt: string; const args: array of const);

//==============================================================================
//
// PS_Writeln
//
//==============================================================================
procedure PS_Writeln(const parm: string);

//==============================================================================
//
// PS_WritelnFmt
//
//==============================================================================
procedure PS_WritelnFmt(const Fmt: string; const args: array of const);

//==============================================================================
//
// PS_OutputDebugString
//
//==============================================================================
procedure PS_OutputDebugString(const parm: string);

//==============================================================================
//
// PS_OutputDebugStringFmt
//
//==============================================================================
procedure PS_OutputDebugStringFmt(const Fmt: string; const args: array of const);

//==============================================================================
//
// PS_BreakPoint
//
//==============================================================================
procedure PS_BreakPoint(const msg: string);

//==============================================================================
//
// PS_FineSine
//
//==============================================================================
function PS_FineSine(const parm: LongWord): Integer;

//==============================================================================
//
// PS_FineCosine
//
//==============================================================================
function PS_FineCosine(const parm: LongWord): Integer;

//==============================================================================
//
// PS_FineTangent
//
//==============================================================================
function PS_FineTangent(const parm: LongWord): Integer;

//==============================================================================
//
// PS_Tan
//
//==============================================================================
function PS_Tan(const parm: Extended): Extended;

//==============================================================================
//
// PS_Sin360
//
//==============================================================================
function PS_Sin360(const parm: Extended): Extended;

//==============================================================================
//
// PS_Cos360
//
//==============================================================================
function PS_Cos360(const parm: Extended): Extended;

//==============================================================================
//
// PS_Tan360
//
//==============================================================================
function PS_Tan360(const parm: Extended): Extended;

//==============================================================================
//
// PS_Format
//
//==============================================================================
function PS_Format(const Fmt: string; const args: array of const): string;

//==============================================================================
//
// PS_IFI
//
//==============================================================================
function PS_IFI(const condition: boolean; const iftrue, iffalse: Int64): Int64;

//==============================================================================
//
// PS_IFF
//
//==============================================================================
function PS_IFF(const condition: boolean; const iftrue, iffalse: Extended): Extended;

//==============================================================================
//
// PS_IFS
//
//==============================================================================
function PS_IFS(const condition: boolean; const iftrue, iffalse: string): string;

//==============================================================================
//
// PS_Odd
//
//==============================================================================
function PS_Odd(const x: integer): boolean;

//==============================================================================
//
// PS_Even
//
//==============================================================================
function PS_Even(const x: integer): boolean;

//==============================================================================
//
// PS_MergeIntegerArrays
//
//==============================================================================
function PS_MergeIntegerArrays(const A1, A2: TDynamicIntegerArray): TDynamicIntegerArray;

//==============================================================================
//
// PS_MergeInt64Arrays
//
//==============================================================================
function PS_MergeInt64Arrays(const A1, A2: TDynamicInt64Array): TDynamicInt64Array;

//==============================================================================
//
// PS_MergeLongWordArrays
//
//==============================================================================
function PS_MergeLongWordArrays(const A1, A2: TDynamicLongWordArray): TDynamicLongWordArray;

//==============================================================================
//
// PS_MergeSingleArrays
//
//==============================================================================
function PS_MergeSingleArrays(const A1, A2: TDynamicSingleArray): TDynamicSingleArray;

//==============================================================================
//
// PS_MergeDoubleArrays
//
//==============================================================================
function PS_MergeDoubleArrays(const A1, A2: TDynamicDoubleArray): TDynamicDoubleArray;

//==============================================================================
//
// PS_MergeExtendedArrays
//
//==============================================================================
function PS_MergeExtendedArrays(const A1, A2: TDynamicExtendedArray): TDynamicExtendedArray;

//==============================================================================
//
// PS_IsPrime
//
//==============================================================================
function PS_IsPrime(const N: Int64): Boolean;

//==============================================================================
//
// PS_RandomRange
//
//==============================================================================
function PS_RandomRange(const x1, x2: integer): integer;

//==============================================================================
// PS_ConsoleCommand
//
// --------------------------- CONSOLE -----------------------------------------
//
//==============================================================================
procedure PS_ConsoleCommand(const parm: string);

//==============================================================================
//
// PS_GetConsoleStr
//
//==============================================================================
function PS_GetConsoleStr(const cvar: string): string;

//==============================================================================
//
// PS_SetConsoleStr
//
//==============================================================================
function PS_SetConsoleStr(const cvar: string; const value: string): boolean;

//==============================================================================
//
// PS_GetConsoleInt
//
//==============================================================================
function PS_GetConsoleInt(const cvar: string): integer;

//==============================================================================
//
// PS_SetConsoleInt
//
//==============================================================================
function PS_SetConsoleInt(const cvar: string; const value: integer): boolean;

//==============================================================================
//
// PS_GetConsoleBool
//
//==============================================================================
function PS_GetConsoleBool(const cvar: string): boolean;

//==============================================================================
//
// PS_SetConsoleBool
//
//==============================================================================
function PS_SetConsoleBool(const cvar: string; const value: boolean): boolean;

//==============================================================================
//
// PS_ConfigureSystem
// The functions of the unit SYSTEM of the scripts, given by the composition root: the
// PS_* routines above are the entries that the interpreter calls and they only forward to it
//
//==============================================================================
procedure PS_ConfigureSystem(const AFunctions: IScriptSystemFunctions);

implementation

uses
  i_system;

var
  // given by the composition root
  ps_system_ref: IScriptSystemFunctions = nil;

//==============================================================================
//
// PS_ConfigureSystem
//
//==============================================================================
procedure PS_ConfigureSystem(const AFunctions: IScriptSystemFunctions);
begin
  ps_system_ref := AFunctions;
end;

//==============================================================================
//
// PS_System
//
//==============================================================================
function PS_System: IScriptSystemFunctions;
begin
  if ps_system_ref = nil then
    I_Error('PS_ConfigureSystem() was not called: the functions of the unit SYSTEM are missing');
  result := ps_system_ref;
end;

//==============================================================================
//
// PS_LevelTime
//
//==============================================================================
function PS_LevelTime: integer;
begin
  Result := PS_System.LevelTime;
end;

//==============================================================================
//
// PS_Write
//
//==============================================================================
procedure PS_Write(const parm: string);
begin
  PS_System.WriteText(parm);
end;

//==============================================================================
//
// PS_WriteFmt
//
//==============================================================================
procedure PS_WriteFmt(const Fmt: string; const args: array of const);
begin
  PS_System.WriteFormatted(Fmt, args);
end;

//==============================================================================
//
// PS_Writeln
//
//==============================================================================
procedure PS_Writeln(const parm: string);
begin
  PS_System.WriteLine(parm);
end;

//==============================================================================
//
// PS_WritelnFmt
//
//==============================================================================
procedure PS_WritelnFmt(const Fmt: string; const args: array of const);
begin
  PS_System.WriteLineFormatted(Fmt, args);
end;

//==============================================================================
//
// PS_OutputDebugString
//
//==============================================================================
procedure PS_OutputDebugString(const parm: string);
begin
  PS_System.WriteDebug(parm);
end;

//==============================================================================
//
// PS_OutputDebugStringFmt
//
//==============================================================================
procedure PS_OutputDebugStringFmt(const Fmt: string; const args: array of const);
begin
  PS_System.WriteDebugFormatted(Fmt, args);
end;

//==============================================================================
//
// PS_BreakPoint
// Actually for debuging the engine, not script
//
//==============================================================================
procedure PS_BreakPoint(const msg: string);
begin
  PS_System.BreakPoint(msg);
end;

//==============================================================================
//
// PS_FineSine
//
//==============================================================================
function PS_FineSine(const parm: LongWord): Integer;
begin
  Result := PS_System.FineSine(parm);
end;

//==============================================================================
//
// PS_FineCosine
//
//==============================================================================
function PS_FineCosine(const parm: LongWord): Integer;
begin
  Result := PS_System.FineCosine(parm);
end;

//==============================================================================
//
// PS_FineTangent
//
//==============================================================================
function PS_FineTangent(const parm: LongWord): Integer;
begin
  Result := PS_System.FineTangent(parm);
end;

//==============================================================================
//
// PS_Tan
//
//==============================================================================
function PS_Tan(const parm: Extended): Extended;
begin
  Result := PS_System.TangentOfRadians(parm);
end;

//==============================================================================
//
// PS_Sin360
//
//==============================================================================
function PS_Sin360(const parm: Extended): Extended;
begin
  Result := PS_System.SineOfDegrees(parm);
end;

//==============================================================================
//
// PS_Cos360
//
//==============================================================================
function PS_Cos360(const parm: Extended): Extended;
begin
  Result := PS_System.CosineOfDegrees(parm);
end;

//==============================================================================
//
// PS_Tan360
//
//==============================================================================
function PS_Tan360(const parm: Extended): Extended;
begin
  Result := PS_System.TangentOfDegrees(parm);
end;

//==============================================================================
//
// PS_Format
//
//==============================================================================
function PS_Format(const Fmt: string; const args: array of const): string;
begin
  Result := PS_System.FormatText(Fmt, args);
end;

//==============================================================================
//
// PS_IFI
//
//==============================================================================
function PS_IFI(const condition: boolean; const iftrue, iffalse: Int64): Int64;
begin
  Result := PS_System.IfInteger(condition, iftrue, iffalse);
end;

//==============================================================================
//
// PS_IFF
//
//==============================================================================
function PS_IFF(const condition: boolean; const iftrue, iffalse: Extended): Extended;
begin
  Result := PS_System.IfFloat(condition, iftrue, iffalse);
end;

//==============================================================================
//
// PS_IFS
//
//==============================================================================
function PS_IFS(const condition: boolean; const iftrue, iffalse: string): string;
begin
  Result := PS_System.IfString(condition, iftrue, iffalse);
end;

//==============================================================================
//
// PS_Odd
//
//==============================================================================
function PS_Odd(const x: integer): boolean;
begin
  Result := PS_System.IsOdd(x);
end;

//==============================================================================
//
// PS_Even
//
//==============================================================================
function PS_Even(const x: integer): boolean;
begin
  Result := PS_System.IsEven(x);
end;

//==============================================================================
//
// PS_MergeIntegerArrays
//
//==============================================================================
function PS_MergeIntegerArrays(const A1, A2: TDynamicIntegerArray): TDynamicIntegerArray;
begin
  Result := PS_System.MergeIntegerArrays(A1, A2);
end;

//==============================================================================
//
// PS_MergeInt64Arrays
//
//==============================================================================
function PS_MergeInt64Arrays(const A1, A2: TDynamicInt64Array): TDynamicInt64Array;
begin
  Result := PS_System.MergeInt64Arrays(A1, A2);
end;

//==============================================================================
//
// PS_MergeLongWordArrays
//
//==============================================================================
function PS_MergeLongWordArrays(const A1, A2: TDynamicLongWordArray): TDynamicLongWordArray;
begin
  Result := PS_System.MergeLongWordArrays(A1, A2);
end;

//==============================================================================
//
// PS_MergeSingleArrays
//
//==============================================================================
function PS_MergeSingleArrays(const A1, A2: TDynamicSingleArray): TDynamicSingleArray;
begin
  Result := PS_System.MergeSingleArrays(A1, A2);
end;

//==============================================================================
//
// PS_MergeDoubleArrays
//
//==============================================================================
function PS_MergeDoubleArrays(const A1, A2: TDynamicDoubleArray): TDynamicDoubleArray;
begin
  Result := PS_System.MergeDoubleArrays(A1, A2);
end;

//==============================================================================
//
// PS_MergeExtendedArrays
//
//==============================================================================
function PS_MergeExtendedArrays(const A1, A2: TDynamicExtendedArray): TDynamicExtendedArray;
begin
  Result := PS_System.MergeExtendedArrays(A1, A2);
end;

//==============================================================================
//
// PS_IsPrime
//
//==============================================================================
function PS_IsPrime(const N: Int64): Boolean;
begin
  Result := PS_System.IsPrime(N);
end;

//==============================================================================
//
// PS_RandomRange
//
//==============================================================================
function PS_RandomRange(const x1, x2: integer): integer;
begin
  Result := PS_System.RandomRange(x1, x2);
end;

//==============================================================================
//
// PS_ConsoleCommand
//
//==============================================================================
procedure PS_ConsoleCommand(const parm: string);
begin
  PS_System.ExecuteConsoleCommand(parm);
end;

//==============================================================================
//
// PS_GetConsoleStr
//
//==============================================================================
function PS_GetConsoleStr(const cvar: string): string;
begin
  Result := PS_System.GetConsoleString(cvar);
end;

//==============================================================================
//
// PS_SetConsoleStr
//
//==============================================================================
function PS_SetConsoleStr(const cvar: string; const value: string): boolean;
begin
  Result := PS_System.SetConsoleString(cvar, value);
end;

//==============================================================================
//
// PS_GetConsoleInt
//
//==============================================================================
function PS_GetConsoleInt(const cvar: string): integer;
begin
  Result := PS_System.GetConsoleInteger(cvar);
end;

//==============================================================================
//
// PS_SetConsoleInt
//
//==============================================================================
function PS_SetConsoleInt(const cvar: string; const value: integer): boolean;
begin
  Result := PS_System.SetConsoleInteger(cvar, value);
end;

//==============================================================================
//
// PS_GetConsoleBool
//
//==============================================================================
function PS_GetConsoleBool(const cvar: string): boolean;
begin
  Result := PS_System.GetConsoleBoolean(cvar);
end;

//==============================================================================
//
// PS_SetConsoleBool
//
//==============================================================================
function PS_SetConsoleBool(const cvar: string; const value: boolean): boolean;
begin
  Result := PS_System.SetConsoleBoolean(cvar, value);
end;

end.
