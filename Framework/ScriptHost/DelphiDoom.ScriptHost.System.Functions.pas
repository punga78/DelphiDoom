{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - the SYSTEM unit of script                         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  The 56 functions that every script has (the first lines of ps_import.pas    }
{  and the PS_* routines of psi_system.pas): the declarations as they were,    }
{  in the same order, and the bodies of the ones that this unit owns.          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.System.Functions;

interface

uses
  DelphiDoom.MathCore.Intf,
  DelphiDoom.ScriptHost.Intf,
  DelphiDoom.ScriptHost.System.Intf;

type
  /// <summary>The functions of the unit SYSTEM, one slot for each</summary>
  TScriptSystemRoutine = (
    ssrOutputDebugString,
    ssrOutputDebugStringFmt,
    ssrBreakPoint,
    ssrConsoleCommand,
    ssrGetConsoleStr,
    ssrSetConsoleStr,
    ssrGetConsoleInt,
    ssrSetConsoleInt,
    ssrGetConsoleBool,
    ssrSetConsoleBool,
    ssrWrite,
    ssrWriteFmt,
    ssrWriteln,
    ssrWritelnFmt,
    ssrLevelTime,
    ssrFineSine,
    ssrFineCosine,
    ssrFineTangent,
    ssrGetMapString,
    ssrSetMapString,
    ssrGetMapInteger,
    ssrSetMapInteger,
    ssrGetMapFloat,
    ssrSetMapFloat,
    ssrGetWorldString,
    ssrSetWorldString,
    ssrGetWorldInteger,
    ssrSetWorldInteger,
    ssrGetWorldFloat,
    ssrSetWorldFloat,
    ssrTan,
    ssrSin360,
    ssrCos360,
    ssrTan360,
    ssrP_Random,
    ssrFormat,
    ssrIsIntegerInRange,
    ssrIsLongWordInRange,
    ssrIsSingleInRange,
    ssrIsFloatInRange,
    ssrIsDoubleInRange,
    ssrIsExtendedInRange,
    ssrIFI,
    ssrIFF,
    ssrIFS,
    ssrOdd,
    ssrEven,
    ssrMergeIntegerArrays,
    ssrMergeInt64Arrays,
    ssrMergeLongWordArrays,
    ssrMergeSingleArrays,
    ssrMergeFloatArrays,
    ssrMergeDoubleArrays,
    ssrMergeExtendedArrays,
    ssrIsPrime,
    ssrRandomRange
  );

  /// <summary>
  ///   The routine that the interpreter calls for every function. A script calls a plain
  ///   routine of the register convention: the PS_* procedures of psi_system are the ones that
  ///   reach the bodies of this class, the others are routines of the engine that scripts call
  ///   directly
  /// </summary>
  TScriptSystemRoutines = array[TScriptSystemRoutine] of Pointer;

  /// <summary>
  ///   The unit SYSTEM of the scripts: it describes its functions to the registry and it owns the
  ///   bodies of the ones that do not need the engine (text, arrays, trigonometry, the numbers
  ///   that tell odd from even or prime), and of the ones that ask the application for
  ///   output, level, console and random numbers
  /// </summary>
  TScriptSystemFunctions = class(TInterfacedObject, IScriptFunctionGroup, IScriptSystemFunctions)
  strict private
    FRoutines: TScriptSystemRoutines;
    FOutput: IScriptSystemOutput;
    FEnvironment: IScriptSystemEnvironment;
    FConsole: IScriptSystemConsole;
    FRandom: IGameRandom;
    FBreakPointMessage: string;
    class function MergeArrays<T>(const AFirst, ASecond: TArray<T>): TArray<T>; static;
  public
    /// <param name="ARoutines">What the interpreter calls for every function</param>
    /// <exception cref="EArgumentNilException">If a service is nil</exception>
    constructor Create(const ARoutines: TScriptSystemRoutines; const AOutput: IScriptSystemOutput;
      const AEnvironment: IScriptSystemEnvironment; const AConsole: IScriptSystemConsole;
      const ARandom: IGameRandom);

    function UnitName: string;
    procedure Describe(const ATable: IScriptFunctionTable);

    function LevelTime: Integer;
    procedure WriteText(const AText: string);
    procedure WriteFormatted(const AFormat: string; const AArguments: array of const);
    procedure WriteLine(const AText: string);
    procedure WriteLineFormatted(const AFormat: string; const AArguments: array of const);
    procedure WriteDebug(const AText: string);
    procedure WriteDebugFormatted(const AFormat: string; const AArguments: array of const);
    /// <summary>Remembers the message: a place where a debugger of the engine can stop</summary>
    procedure BreakPoint(const AMessage: string);
    function FineSine(const AAngle: LongWord): Integer;
    function FineCosine(const AAngle: LongWord): Integer;
    function FineTangent(const AAngle: LongWord): Integer;
    function TangentOfRadians(const AValue: Extended): Extended;
    function SineOfDegrees(const AValue: Extended): Extended;
    function CosineOfDegrees(const AValue: Extended): Extended;
    function TangentOfDegrees(const AValue: Extended): Extended;
    function FormatText(const AFormat: string; const AArguments: array of const): string;
    function IfInteger(const ACondition: Boolean; const ATrue, AFalse: Int64): Int64;
    function IfFloat(const ACondition: Boolean; const ATrue, AFalse: Extended): Extended;
    function IfString(const ACondition: Boolean; const ATrue, AFalse: string): string;
    function IsOdd(const AValue: Integer): Boolean;
    function IsEven(const AValue: Integer): Boolean;
    function MergeIntegerArrays(const AFirst, ASecond: TArray<Integer>): TArray<Integer>;
    function MergeInt64Arrays(const AFirst, ASecond: TArray<Int64>): TArray<Int64>;
    function MergeLongWordArrays(const AFirst, ASecond: TArray<LongWord>): TArray<LongWord>;
    function MergeSingleArrays(const AFirst, ASecond: TArray<Single>): TArray<Single>;
    function MergeDoubleArrays(const AFirst, ASecond: TArray<Double>): TArray<Double>;
    function MergeExtendedArrays(const AFirst, ASecond: TArray<Extended>): TArray<Extended>;
    function IsPrime(const AValue: Int64): Boolean;
    /// <summary>A number between the two, from the random numbers of the game (one for each call)</summary>
    function RandomRange(const AFirst, ASecond: Integer): Integer;
    procedure ExecuteConsoleCommand(const ACommand: string);
    function GetConsoleString(const AName: string): string;
    function SetConsoleString(const AName, AValue: string): Boolean;
    function GetConsoleInteger(const AName: string): Integer;
    function SetConsoleInteger(const AName: string; const AValue: Integer): Boolean;
    function GetConsoleBoolean(const AName: string): Boolean;
    function SetConsoleBoolean(const AName: string; const AValue: Boolean): Boolean;

    /// <summary>The last message of BreakPoint</summary>
    function BreakPointMessage: string;
  end;

const
  /// <summary>
  ///   The declarations of the functions of SYSTEM as the compiler of the scripts reads them
  ///   (they are not tidied: they are the contract of every script written so far)
  /// </summary>
  SCRIPT_SYSTEM_DECLARATIONS: array[TScriptSystemRoutine] of string = (
    'procedure OutputDebugString(const parm: string);',
    'procedure OutputDebugStringFmt(const Fmt: string; const args: array of const);',
    'procedure BreakPoint(const msg: string);',
    'procedure ConsoleCommand(Data: string)',
    'function GetConsoleStr(const cvar: string): string;',
    'function SetConsoleStr(const cvar: string; const value: string): boolean;',
    'function GetConsoleInt(const cvar: string): integer;',
    'function SetConsoleInt(const cvar: string; const value: integer): boolean;',
    'function GetConsoleBool(const cvar: string): boolean;',
    'function SetConsoleBool(const cvar: string; const value: boolean): boolean;',
    'procedure Write(Data: string)',
    'procedure WriteFmt(const Fmt: string; const args: array of const);',
    'procedure Writeln(Data: string)',
    'procedure WritelnFmt(const Fmt: string; const args: array of const);',
    'function LevelTime: integer',
    'function FineSine(const parm: LongWord): Integer',
    'function FineCosine(const parm: LongWord): Integer',
    'function FineTangent(const parm: LongWord): Integer',
    'function GetMapString(const x: string): string;',
    'procedure SetMapString(const x: string; const v: string);',
    'function GetMapInteger(const x: string): integer;',
    'procedure SetMapInteger(const x: string; const v: integer);',
    'function GetMapFloat(const x: string): single;',
    'procedure SetMapFloat(const x: string; const v: single);',
    'function GetWorldString(const x: string): string;',
    'procedure SetWorldString(const x: string; const v: string);',
    'function GetWorldInteger(const x: string): integer;',
    'procedure SetWorldInteger(const x: string; const v: integer);',
    'function GetWorldFloat(const x: string): single;',
    'procedure SetWorldFloat(const x: string; const v: single);',
    'function Tan(const parm: Extended): Extended;',
    'function Sin360(const parm: Extended): Extended;',
    'function Cos360(const parm: Extended): Extended;',
    'function Tan360(const parm: Extended): Extended;',
    'function P_Random: integer;',
    'function Format(const Fmt: string; const args: array of const): string;',
    'function IsIntegerInRange(const test, i1, i2: integer): boolean;',
    'function IsLongWordInRange(const test, i1, i2: LongWord): boolean;',
    'function IsSingleInRange(const test, f1, f2: single): boolean;',
    'function IsFloatInRange(const test, f1, f2: single): boolean;',
    'function IsDoubleInRange(const test, f1, f2: double): boolean;',
    'function IsExtendedInRange(const test, f1, f2: Extended): boolean;',
    'function IFI(const condition: boolean; const iftrue, iffalse: Int64): Int64;',
    'function IFF(const condition: boolean; const iftrue, iffalse: Extended): Extended;',
    'function IFS(const condition: boolean; const iftrue, iffalse: string): string;',
    'function Odd(const x: integer): boolean;',
    'function Even(const x: integer): boolean;',
    'function MergeIntegerArrays(const A1, A2: TIntegerArray): TIntegerArray;',
    'function MergeInt64Arrays(const A1, A2: TInt64Array): TInt64Array;',
    'function MergeLongWordArrays(const A1, A2: TLongWordArray): TLongWordArray;',
    'function MergeSingleArrays(const A1, A2: TSingleArray): TSingleArray;',
    'function MergeFloatArrays(const A1, A2: TFloatArray): TFloatArray;',
    'function MergeDoubleArrays(const A1, A2: TDoubleArray): TDoubleArray;',
    'function MergeExtendedArrays(const A1, A2: TExtendedArray): TExtendedArray;',
    'function IsPrime(const N: Int64): Boolean;',
    'function RandomRange(const x1, x2: integer): integer;'
  );

implementation

uses
  System.Math,
  System.SysUtils,
  DelphiDoom.ScriptHost.Types;

{ TScriptSystemFunctions }

constructor TScriptSystemFunctions.Create(const ARoutines: TScriptSystemRoutines;
  const AOutput: IScriptSystemOutput; const AEnvironment: IScriptSystemEnvironment;
  const AConsole: IScriptSystemConsole; const ARandom: IGameRandom);
begin
  inherited Create;
  if not Assigned(AOutput) then
    raise EArgumentNilException.Create('AOutput');
  if not Assigned(AEnvironment) then
    raise EArgumentNilException.Create('AEnvironment');
  if not Assigned(AConsole) then
    raise EArgumentNilException.Create('AConsole');
  if not Assigned(ARandom) then
    raise EArgumentNilException.Create('ARandom');
  FRoutines := ARoutines;
  FOutput := AOutput;
  FEnvironment := AEnvironment;
  FConsole := AConsole;
  FRandom := ARandom;
end;

function TScriptSystemFunctions.UnitName: string;
begin
  Result := SCRIPT_UNIT_SYSTEM;
end;

procedure TScriptSystemFunctions.Describe(const ATable: IScriptFunctionTable);
var
  LRoutine: TScriptSystemRoutine;
begin
  for LRoutine := Low(TScriptSystemRoutine) to High(TScriptSystemRoutine) do
    ATable.Add(SCRIPT_SYSTEM_DECLARATIONS[LRoutine], FRoutines[LRoutine]);
end;

function TScriptSystemFunctions.LevelTime: Integer;
begin
  Result := FEnvironment.LevelTime;
end;

procedure TScriptSystemFunctions.WriteText(const AText: string);
begin
  FOutput.WriteText(AText);
end;

procedure TScriptSystemFunctions.WriteFormatted(const AFormat: string;
  const AArguments: array of const);
begin
  WriteText(FormatText(AFormat, AArguments));
end;

procedure TScriptSystemFunctions.WriteLine(const AText: string);
begin
  FOutput.WriteText(AText + #13#10);
end;

procedure TScriptSystemFunctions.WriteLineFormatted(const AFormat: string;
  const AArguments: array of const);
begin
  WriteLine(FormatText(AFormat, AArguments));
end;

procedure TScriptSystemFunctions.WriteDebug(const AText: string);
begin
  FOutput.WriteDebug(AText);
end;

procedure TScriptSystemFunctions.WriteDebugFormatted(const AFormat: string;
  const AArguments: array of const);
begin
  WriteDebug(FormatText(AFormat, AArguments));
end;

procedure TScriptSystemFunctions.BreakPoint(const AMessage: string);
begin
  FBreakPointMessage := AMessage;
end;

function TScriptSystemFunctions.BreakPointMessage: string;
begin
  Result := FBreakPointMessage;
end;

function TScriptSystemFunctions.FineSine(const AAngle: LongWord): Integer;
begin
  Result := FEnvironment.FineSine(AAngle);
end;

function TScriptSystemFunctions.FineCosine(const AAngle: LongWord): Integer;
begin
  Result := FEnvironment.FineCosine(AAngle);
end;

function TScriptSystemFunctions.FineTangent(const AAngle: LongWord): Integer;
begin
  Result := FEnvironment.FineTangent(AAngle);
end;

function TScriptSystemFunctions.TangentOfRadians(const AValue: Extended): Extended;
begin
  Result := Tan(AValue);
end;

function TScriptSystemFunctions.SineOfDegrees(const AValue: Extended): Extended;
begin
  Result := Sin(AValue / 360 * 2 * Pi);
end;

function TScriptSystemFunctions.CosineOfDegrees(const AValue: Extended): Extended;
begin
  Result := Cos(AValue / 360 * 2 * Pi);
end;

function TScriptSystemFunctions.TangentOfDegrees(const AValue: Extended): Extended;
begin
  Result := Tan(AValue / 360 * 2 * Pi);
end;

function TScriptSystemFunctions.FormatText(const AFormat: string;
  const AArguments: array of const): string;
begin
  Result := FOutput.FormatText(AFormat, AArguments);
end;

function TScriptSystemFunctions.IfInteger(const ACondition: Boolean;
  const ATrue, AFalse: Int64): Int64;
begin
  if ACondition then
    Result := ATrue
  else
    Result := AFalse;
end;

function TScriptSystemFunctions.IfFloat(const ACondition: Boolean;
  const ATrue, AFalse: Extended): Extended;
begin
  if ACondition then
    Result := ATrue
  else
    Result := AFalse;
end;

function TScriptSystemFunctions.IfString(const ACondition: Boolean;
  const ATrue, AFalse: string): string;
begin
  if ACondition then
    Result := ATrue
  else
    Result := AFalse;
end;

function TScriptSystemFunctions.IsOdd(const AValue: Integer): Boolean;
begin
  Result := Odd(AValue);
end;

function TScriptSystemFunctions.IsEven(const AValue: Integer): Boolean;
begin
  Result := not Odd(AValue);
end;

class function TScriptSystemFunctions.MergeArrays<T>(const AFirst, ASecond: TArray<T>): TArray<T>;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(AFirst) + Length(ASecond));
  for LIndex := 0 to Length(AFirst) - 1 do
    Result[LIndex] := AFirst[LIndex];
  for LIndex := 0 to Length(ASecond) - 1 do
    Result[Length(AFirst) + LIndex] := ASecond[LIndex];
end;

function TScriptSystemFunctions.MergeIntegerArrays(const AFirst,
  ASecond: TArray<Integer>): TArray<Integer>;
begin
  Result := MergeArrays<Integer>(AFirst, ASecond);
end;

function TScriptSystemFunctions.MergeInt64Arrays(const AFirst,
  ASecond: TArray<Int64>): TArray<Int64>;
begin
  Result := MergeArrays<Int64>(AFirst, ASecond);
end;

function TScriptSystemFunctions.MergeLongWordArrays(const AFirst,
  ASecond: TArray<LongWord>): TArray<LongWord>;
begin
  Result := MergeArrays<LongWord>(AFirst, ASecond);
end;

function TScriptSystemFunctions.MergeSingleArrays(const AFirst,
  ASecond: TArray<Single>): TArray<Single>;
begin
  Result := MergeArrays<Single>(AFirst, ASecond);
end;

function TScriptSystemFunctions.MergeDoubleArrays(const AFirst,
  ASecond: TArray<Double>): TArray<Double>;
begin
  Result := MergeArrays<Double>(AFirst, ASecond);
end;

function TScriptSystemFunctions.MergeExtendedArrays(const AFirst,
  ASecond: TArray<Extended>): TArray<Extended>;
begin
  Result := MergeArrays<Extended>(AFirst, ASecond);
end;

function TScriptSystemFunctions.IsPrime(const AValue: Int64): Boolean;
var
  LTest: Int64;
  LLimit: Int64;
  LRoot: Extended;
begin
  if AValue <= 3 then
    Result := AValue > 1
  else if ((AValue mod 2) = 0) or ((AValue mod 3) = 0) then
    Result := False
  else
  begin
    Result := True;
    LRoot := AValue;
    LLimit := Trunc(Sqrt(LRoot));
    LTest := 5;
    while LTest <= LLimit do
    begin
      if ((AValue mod LTest) = 0) or ((AValue mod (LTest + 2)) = 0) then
      begin
        Result := False;
        Break;
      end;
      LTest := LTest + 6;
    end;
  end;
end;

function TScriptSystemFunctions.RandomRange(const AFirst, ASecond: Integer): Integer;
var
  LFirstPart: Single;
  LSecondPart: Single;
  LRandom: Integer;
begin
  LRandom := FRandom.NextPlay;
  LFirstPart := (LRandom * AFirst) / 255;
  LSecondPart := ((255 - LRandom) * ASecond) / 255;
  Result := Round(LFirstPart + LSecondPart);
end;

procedure TScriptSystemFunctions.ExecuteConsoleCommand(const ACommand: string);
begin
  FConsole.AddCommand(ACommand);
end;

function TScriptSystemFunctions.GetConsoleString(const AName: string): string;
begin
  Result := FConsole.GetString(AName);
end;

function TScriptSystemFunctions.SetConsoleString(const AName, AValue: string): Boolean;
begin
  Result := FConsole.SetString(AName, AValue);
end;

function TScriptSystemFunctions.GetConsoleInteger(const AName: string): Integer;
begin
  Result := FConsole.GetInteger(AName);
end;

function TScriptSystemFunctions.SetConsoleInteger(const AName: string;
  const AValue: Integer): Boolean;
begin
  Result := FConsole.SetInteger(AName, AValue);
end;

function TScriptSystemFunctions.GetConsoleBoolean(const AName: string): Boolean;
begin
  Result := FConsole.GetBoolean(AName);
end;

function TScriptSystemFunctions.SetConsoleBoolean(const AName: string;
  const AValue: Boolean): Boolean;
begin
  Result := FConsole.SetBoolean(AName, AValue);
end;

end.
