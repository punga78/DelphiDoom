{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - what the SYSTEM functions ask of the application  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.System.Intf;

interface

type
  /// <summary>Where the text that a script writes goes, and how a script formats it</summary>
  IScriptSystemOutput = interface
    ['{E4F07B31-5A92-4C6D-B8D3-7A1E96C05F28}']
    /// <summary>Writes the text as it is (the console of the game and the log of the output)</summary>
    procedure WriteText(const AText: string);
    /// <summary>Writes the text in the debug file of the game, if there is one</summary>
    procedure WriteDebug(const AText: string);
    /// <summary>
    ///   The text of a format (%d, %s, %f...) with its arguments; if the format is not valid the
    ///   application warns and the format itself is the text
    /// </summary>
    function FormatText(const AFormat: string; const AArguments: array of const): string;
  end;

  /// <summary>The world that the SYSTEM functions read: the level and the trigonometric tables</summary>
  IScriptSystemEnvironment = interface
    ['{19C6D2A8-7E40-4B15-9AF3-D82B5E1C47A6}']
    /// <summary>The tics since the level started</summary>
    function LevelTime: Integer;
    /// <summary>The table of the sine of the fine angles (the angle is taken modulo the size of the table)</summary>
    function FineSine(const AAngle: LongWord): Integer;
    function FineCosine(const AAngle: LongWord): Integer;
    function FineTangent(const AAngle: LongWord): Integer;
  end;

  /// <summary>The console of the game and its variables, as the scripts use them</summary>
  IScriptSystemConsole = interface
    ['{A83E5C09-D127-4F6B-8C94-0B7D31E2F5A8}']
    /// <summary>Queues a command line of the console</summary>
    procedure AddCommand(const ACommand: string);
    /// <summary>The value of a variable (a variable of the configuration) as text, empty if it does not exist</summary>
    function GetString(const AName: string): string;
    function GetInteger(const AName: string): Integer;
    function GetBoolean(const AName: string): Boolean;
    /// <summary>Sets a variable; false if it does not exist or is not of the type</summary>
    function SetString(const AName, AValue: string): Boolean;
    function SetInteger(const AName: string; const AValue: Integer): Boolean;
    function SetBoolean(const AName: string; const AValue: Boolean): Boolean;
  end;

  /// <summary>
  ///   The bodies of the functions of the unit SYSTEM: what the PS_* routines of psi_system
  ///   forward to. The functions are the ones that scripts call, with the names of their purpose
  /// </summary>
  IScriptSystemFunctions = interface
    ['{64B1F8D3-0A5E-4E97-B2C8-9D7A3F16E04B}']
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
    function BreakPointMessage: string;
  end;
implementation

end.
