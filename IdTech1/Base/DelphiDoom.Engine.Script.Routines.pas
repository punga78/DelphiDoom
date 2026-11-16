{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the routines that scripts call for SYSTEM and PS_FIXED }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Script.Routines;

interface

uses
  DelphiDoom.ScriptHost.Fixed.Functions,
  DelphiDoom.ScriptHost.System.Functions;

type
  /// <summary>
  ///   The routine for every function of the units SYSTEM and PS_FIXED, as ps_import.pas always
  ///   registered them: the PS_* procedures of psi_system (that reach the bodies of the class
  ///   TScriptSystemFunctions), the ones of psi_globals (the variables of map and world) and the
  ///   plain routines of the engine that scripts call directly (P_Random, the range tests,
  ///   m_fixed). The order of the functions is the one of the declarations of the groups
  /// </summary>
  TEngineScriptRoutines = class
  public
    class function SystemRoutines: TScriptSystemRoutines; static;
    class function FixedRoutines: TScriptFixedRoutines; static;
  end;

implementation

uses
  d_delphi,
  m_fixed,
  m_rnd,
  psi_globals,
  psi_system;

{ TEngineScriptRoutines }

class function TEngineScriptRoutines.SystemRoutines: TScriptSystemRoutines;
begin
  Result[ssrOutputDebugString] := @PS_OutputDebugString;
  Result[ssrOutputDebugStringFmt] := @PS_OutputDebugStringFmt;
  Result[ssrBreakPoint] := @PS_BreakPoint;
  Result[ssrConsoleCommand] := @PS_ConsoleCommand;
  Result[ssrGetConsoleStr] := @PS_GetConsoleStr;
  Result[ssrSetConsoleStr] := @PS_SetConsoleStr;
  Result[ssrGetConsoleInt] := @PS_GetConsoleInt;
  Result[ssrSetConsoleInt] := @PS_SetConsoleInt;
  Result[ssrGetConsoleBool] := @PS_GetConsoleBool;
  Result[ssrSetConsoleBool] := @PS_SetConsoleBool;
  Result[ssrWrite] := @PS_Write;
  Result[ssrWriteFmt] := @PS_WriteFmt;
  Result[ssrWriteln] := @PS_Writeln;
  Result[ssrWritelnFmt] := @PS_WritelnFmt;
  Result[ssrLevelTime] := @PS_Leveltime;
  Result[ssrFineSine] := @PS_FineSine;
  Result[ssrFineCosine] := @PS_FineCosine;
  Result[ssrFineTangent] := @PS_FineTangent;
  Result[ssrGetMapString] := @PS_GetMapStr;
  Result[ssrSetMapString] := @PS_SetMapStr;
  Result[ssrGetMapInteger] := @PS_GetMapInt;
  Result[ssrSetMapInteger] := @PS_SetMapInt;
  Result[ssrGetMapFloat] := @PS_GetMapFloat;
  Result[ssrSetMapFloat] := @PS_SetMapFloat;
  Result[ssrGetWorldString] := @PS_GetWorldStr;
  Result[ssrSetWorldString] := @PS_SetWorldStr;
  Result[ssrGetWorldInteger] := @PS_GetWorldInt;
  Result[ssrSetWorldInteger] := @PS_SetWorldInt;
  Result[ssrGetWorldFloat] := @PS_GetWorldFloat;
  Result[ssrSetWorldFloat] := @PS_SetWorldFloat;
  Result[ssrTan] := @PS_Tan;
  Result[ssrSin360] := @PS_Sin360;
  Result[ssrCos360] := @PS_Cos360;
  Result[ssrTan360] := @PS_Tan360;
  Result[ssrP_Random] := @P_Random;
  Result[ssrFormat] := @PS_Format;
  Result[ssrIsIntegerInRange] := @IsIntegerInRange;
  Result[ssrIsLongWordInRange] := @IsLongWordInRange;
  Result[ssrIsSingleInRange] := @IsFloatInRange;
  Result[ssrIsFloatInRange] := @IsFloatInRange;
  Result[ssrIsDoubleInRange] := @IsDoubleInRange;
  Result[ssrIsExtendedInRange] := @IsExtendedInRange;
  Result[ssrIFI] := @PS_IFI;
  Result[ssrIFF] := @PS_IFF;
  Result[ssrIFS] := @PS_IFS;
  Result[ssrOdd] := @PS_Odd;
  Result[ssrEven] := @PS_Even;
  Result[ssrMergeIntegerArrays] := @PS_MergeIntegerArrays;
  Result[ssrMergeInt64Arrays] := @PS_MergeInt64Arrays;
  Result[ssrMergeLongWordArrays] := @PS_MergeLongWordArrays;
  Result[ssrMergeSingleArrays] := @PS_MergeSingleArrays;
  Result[ssrMergeFloatArrays] := @PS_MergeSingleArrays;
  Result[ssrMergeDoubleArrays] := @PS_MergeDoubleArrays;
  Result[ssrMergeExtendedArrays] := @PS_MergeExtendedArrays;
  Result[ssrIsPrime] := @PS_IsPrime;
  Result[ssrRandomRange] := @PS_RandomRange;
end;

class function TEngineScriptRoutines.FixedRoutines: TScriptFixedRoutines;
begin
  Result[sfrFixedMul] := @FixedMulEx;
  Result[sfrFixedDiv] := @FixedDivEx;
  Result[sfrFixedSqrt] := @FixedSqrt;
  Result[sfrFloatToFixed] := @FloatToFixed;
  Result[sfrDoubleToFixed] := @DoubleToFixed;
  Result[sfrExtendedToFixed] := @ExtendedToFixed;
  Result[sfrFixedToFloat] := @FixedToFloat;
  Result[sfrFixedToDouble] := @FixedToDouble;
  Result[sfrFixedToExtended] := @FixedToExtended;
end;

end.
