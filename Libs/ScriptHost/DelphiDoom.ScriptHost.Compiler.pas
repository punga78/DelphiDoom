{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - compiler of the scripts                           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  It was the part of ps_import.pas that does not name the engine: the         }
{  functions, classes and constants of the scripts, the files they include     }
{  and the game come from the IScriptHostServices given by the caller.         }
{                                                                              }
{******************************************************************************}

{$I Doom32.inc}

unit DelphiDoom.ScriptHost.Compiler;
{$I PascalScript.inc}

interface

uses
  d_delphi,
  ps_defs,
  ps_compiler,
  uPSPreProcessor,
  DelphiDoom.ScriptHost.Services.Intf;

type
  /// <summary>The compiler of Pascal Script with the host of the scripts: preprocessor, units, DLLs</summary>
  TDoomCompiler = class(TPSPascalCompiler)
  private
    FPP: TPSPreProcessor;
    funitnames: TDStringList;
    FServices: IScriptHostServices;
  public
    /// <exception cref="EScriptHostException">If another compiler is active: there can be only one</exception>
    constructor CreateDoomCompiler(const AServices: IScriptHostServices); virtual;
    property Services: IScriptHostServices read FServices;
    function CompileDoomScript(const source: TbtString; var pcode: TbtString): Boolean; virtual;
    destructor Destroy; override;
    property unitnames: TDStringList read funitnames;
  end;

//==============================================================================
//
// PS_ScriptOnUses
// The OnUses of the compiler: SYSTEM gives the basic types, the classes and the
// constants; ALL the units of the registry; any other name is a unit of the registry
//
//==============================================================================
function PS_ScriptOnUses(Sender: TPSPascalCompiler; const Name: TbtString): Boolean;

implementation

uses
  System.SysUtils,
  Classes,
  uPSC_dateutils,
  uPSC_dll,
  ps_keywords,
  DelphiDoom.ScriptHost.Compiled,
  DelphiDoom.ScriptHost.Factory,
  DelphiDoom.ScriptHost.Types;

resourcestring
  SScriptCompilerAlreadyActive = 'TDoomCompiler.CreateDoomCompiler(): Compiler is already active!';

var
  dccnt: integer = 0;

//==============================================================================
//
// PS_ScriptOnUses
//
//==============================================================================
function PS_ScriptOnUses(Sender: TPSPascalCompiler; const Name: TbtString): Boolean;
var
  LName: string;
  LServices: IScriptHostServices;
{ the OnUses callback function is called for each "uses" in the script.
  It's always called with the parameter 'SYSTEM' at the top of the script.
  For example: uses ii1, ii2;
  This will call this function 3 times. First with 'SYSTEM' then 'II1' and then 'II2'.
}
begin
  LServices := (Sender as TDoomCompiler).Services;
  if Name = 'SYSTEM' then
  begin
    // Functions
    with Sender.AddClassN(nil, '!TOBJECT') do
    begin
      RegisterMethod('constructor Create');
      RegisterMethod('procedure Free');
    end;
    Sender.AddTypeS('TActorArray', 'array of LongWord');
    Sender.AddTypeS('TIntegerArray', 'array of integer');
    Sender.AddTypeS('TInt64Array', 'array of int64');
    Sender.AddTypeS('TLongWordArray', 'array of LongWord');
    Sender.AddTypeS('TSingleArray', 'array of single');
    Sender.AddTypeS('TFloatArray', 'array of single');
    Sender.AddTypeS('TDoubleArray', 'array of double');
    Sender.AddTypeS('TExtendedArray', 'array of extended');
    Sender.AddTypeS('float', 'single');
    Sender.AddTypeS('real', 'double');
    Sender.AddTypeS('fixed_t', 'integer');
    Sender.AddTypeS('angle_t', 'longword');
    RegisterDateTimeLibrary_C(Sender);
    LServices.Classes.RegisterCompiler(Sender);

    LServices.Registry.RegisterCompiler(string(Name), Sender);

    // the constants of every script: NaN, the flags of the mobjs, the angles...
    LServices.Constants.Describe(TScriptHostFactory.CreateCompilerConstants(Sender));

    Result := True;
  end
  else if Name = 'ALL' then
  begin
    for LName in LServices.Registry.CompilerUnitNames do
      PS_ScriptOnUses(Sender, TbtString(LName));
    Result := True;
  end
  else
  begin
    if LServices.Registry.RegisterCompiler(string(Name), Sender) then
    begin
      Result := True;
    end
    else
    begin
      Sender.MakeError('', ecUnknownIdentifier, '');
      Result := False;
    end;
  end;

  if Result then
    (Sender as TDoomCompiler).unitnames.Add(string(Name));
end;

//==============================================================================
//
// CompTranslateLineInfo
//
//==============================================================================
procedure CompTranslateLineInfo(Sender: TPSPascalCompiler; var Pos, Row, Col: Cardinal; var Name: TbtString);
var
  res: TPSLineInfoResults;
begin
  if TDoomCompiler(Sender).FPP.CurrentLineInfo.GetLineInfo(Name, Pos, Res) then
  begin
    Pos := Res.Pos;
    Row := Res.Row;
    Col := Res.Col;
    Name := Res.Name;
  end;
end;

procedure callObjectOnProcessDirective (
  Sender: TPSPreProcessor;
  Parser: TPSPascalPreProcessorParser;
  const Active: Boolean;
  const DirectiveName, DirectiveParam: TbtString;
  var Continue: Boolean);
begin
end;

procedure callObjectOnProcessUnknowDirective (
  Sender: TPSPreProcessor;
  Parser: TPSPascalPreProcessorParser;
  const Active: Boolean;
  const DirectiveName, DirectiveParam: TbtString;
  var Continue: Boolean);
begin
end;

//==============================================================================
//
// FPPNeedFile
//
//==============================================================================
function FPPNeedFile(Sender: TPSPreProcessor; const callingfilename: TbtString; var FileName, Output: TbtString): Boolean;
begin
  Output := TbtString(TDoomCompiler(Sender.Id).Services.Sources.ReadText(string(FileName)));
  Result := Output <> '';
end;

//==============================================================================
//
// TDoomCompiler.CreateDoomCompiler
//
//==============================================================================
constructor TDoomCompiler.CreateDoomCompiler(const AServices: IScriptHostServices);
begin
  if dccnt <> 0 then
    raise EScriptHostException.Create(SScriptCompilerAlreadyActive);

  Inc(dccnt);

  FServices := AServices;
  inherited Create(@DefaultLookupTable, DEFAULT_KEYWORD_COUNT);
  OnUses := PS_ScriptOnUses;
  OnExternalProc := DllExternalProc;
  AllowNoEnd := true;

  FPP := TPSPreProcessor.Create;
  FPP.Id := Self;
  FPP.OnNeedFile := FPPNeedFile;

  funitnames := TDStringList.Create;
end;

//==============================================================================
//
// TDoomCompiler.Destroy
//
//==============================================================================
destructor TDoomCompiler.Destroy;
begin
  Dec(dccnt);
  FPP.Free;
  funitnames.Free;

  inherited;
end;

//==============================================================================
//
// TDoomCompiler.CompileDoomScript
//
//==============================================================================
function TDoomCompiler.CompileDoomScript(const source: TbtString; var pcode: TbtString): Boolean;
var
  ppsrc: TbtString;
  ppout: TbtString;
  unitstr: TbtString;
  len: integer;
  LDefine: string;
begin
  FServices.Registry.Reset;

  FPP.Clear;

  // the game, DEBUG, DEVPARM, the X_OR_Y of the game and OPENGL (TScriptDefines)
  for LDefine in FServices.Defines do
    FPP.Defines.Add(LDefine);

  OnTranslateLineInfo := CompTranslateLineInfo;
  FPP.OnProcessDirective := callObjectOnProcessDirective;
  FPP.OnProcessUnknowDirective := callObjectOnProcessUnknowDirective;
  FPP.MainFile := source;
  FPP.MainFileName := '';
  FPP.PreProcess(FPP.MainFileName, ppsrc);

  funitnames.Clear;

  Result := Compile(ppsrc);

  if Result then
    GetOutput(ppout)
  else
    ppout := '';

  unitstr := TbtString(FServices.GameName) + #13#10 + TbtString(funitnames.Text);
  len := Length(unitstr);
  pcode := '            ' + unitstr + ppout;
  PLongWord(@pcode[1])^ := SCRIPT_COMPILED_ID;
  PLongWord(@pcode[5])^ := SCRIPT_COMPILED_VERSION;
  PLongWord(@pcode[9])^ := len;

  FPP.AdjustMessages(Self);
end;

end.
