{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - contracts of the variables of the scripts         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.Variables.Intf;

interface

uses
  System.SysUtils;

type
  /// <summary>Whole files, as the variables of the scripts save and load themselves</summary>
  IScriptVariablesFiles = interface
    ['{5B8D2E61-F3A4-4C07-9E15-A62D70B4C83F}']
    /// <summary>All the bytes of the file</summary>
    function ReadFile(const AName: string): TBytes;
    /// <summary>Writes the bytes in the file, which is created or replaced</summary>
    procedure WriteFile(const AName: string; const ABytes: TBytes);
  end;

  /// <summary>Where a failure of the variables goes: the application stops (or a test records it)</summary>
  IScriptVariablesFailure = interface
    ['{C71A94E0-3D6B-48F2-B5A9-0E8F1D2C6B47}']
    /// <summary>
    ///   Reports the failure. The application does not come back from the call; if it does the
    ///   variables raise EScriptVariablesException
    /// </summary>
    procedure Report(const AMessage: string);
  end;

  /// <summary>
  ///   The variables of the scripts of a map or of the world: strings, integers and floats, by
  ///   name. The name does not distinguish the case. A variable that does not exist has the
  ///   value 0 or the empty string; setting it creates it. An integer can be read as a float
  ///   and the other way round
  /// </summary>
  IScriptVariables = interface
    ['{0E39B6D5-A218-4F7C-8D43-C95B1A7E2F60}']
    function GetInteger(const AName: string): Integer;
    procedure PutInteger(const AName: string; const AValue: Integer);
    function GetIntegerArray(const AName: string; const AIndex: Integer): Integer;
    procedure PutIntegerArray(const AName: string; const AIndex: Integer; const AValue: Integer);
    function GetFloat(const AName: string): Single;
    procedure PutFloat(const AName: string; const AValue: Single);
    function GetFloatArray(const AName: string; const AIndex: Integer): Single;
    procedure PutFloatArray(const AName: string; const AIndex: Integer; const AValue: Single);
    function GetString(const AName: string): string;
    procedure PutString(const AName: string; const AValue: string);
    function GetStringArray(const AName: string; const AIndex: Integer): string;
    procedure PutStringArray(const AName: string; const AIndex: Integer; const AValue: string);

    /// <summary>Adds the variable or changes its value; the position in the list of its type</summary>
    function AddString(const AName: string; const AValue: string): Integer;
    function AddInteger(const AName: string; const AValue: Integer): Integer;
    function AddFloat(const AName: string; const AValue: Single): Integer;

    /// <summary>True if the list of that type has the name exactly as given (no case folding, no upper case)</summary>
    function HasString(const AName: string): Boolean;
    function HasInteger(const AName: string): Boolean;
    function HasFloat(const AName: string): Boolean;
    function StringCount: Integer;
    function IntegerCount: Integer;
    function FloatCount: Integer;

    /// <summary>Removes every variable</summary>
    procedure Clear;

    /// <summary>
    ///   Reads the variables from the buffer that SaveToBuffer wrote; the bytes read. Integers
    ///   have 4 bytes, floats 4 bytes, a string has the length (4 bytes) and 2 bytes for each
    ///   character; order: strings, integers, floats
    /// </summary>
    function LoadFromBuffer(const ABuffer: Pointer): Integer;
    /// <summary>The same, with the length of the buffer: a buffer that ends too soon raises EScriptVariablesException</summary>
    function LoadFromBufferBounded(const ABuffer: Pointer; const ALength: Integer): Integer;
    /// <summary>Writes the variables in the buffer, which is StructureSize bytes long; the bytes written</summary>
    function SaveToBuffer(const ABuffer: Pointer): Integer;
    /// <summary>The bytes that SaveToBuffer writes</summary>
    function StructureSize: Integer;
    /// <summary>The file has the length of the data (4 bytes) and the data of SaveToBuffer</summary>
    procedure LoadFromFile(const AName: string);
    procedure SaveToFile(const AName: string);

    property IntVal[const AName: string]: Integer read GetInteger write PutInteger;
    property IntValArray[const AName: string; const AIndex: Integer]: Integer read GetIntegerArray write PutIntegerArray;
    property FloatVal[const AName: string]: Single read GetFloat write PutFloat;
    property FloatValArray[const AName: string; const AIndex: Integer]: Single read GetFloatArray write PutFloatArray;
    property StrVal[const AName: string]: string read GetString write PutString;
    property StrValArray[const AName: string; const AIndex: Integer]: string read GetStringArray write PutStringArray;
  end;

implementation

end.
