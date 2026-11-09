{******************************************************************************}
{                                                                              }
{  DelphiDoom: a real interpreter of Pascal Script for the tests of the host   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.ScriptHost.Interpreter;

interface

uses
  System.SysUtils,
  ps_defs,
  ps_utils,
  ps_keywords,
  ps_compiler,
  ps_runtime;

type
  /// <summary>
  ///   Compiles a script with the real compiler and loads it in a real interpreter (no unit but
  ///   SYSTEM): for the events and the serializer of the script state
  /// </summary>
  TTestInterpreter = class(TObject)
  strict private
    FExec: TPSExec;
  public
    /// <summary>Compiles and loads the script; with ARun the main block runs too (the variables get their values)</summary>
    constructor Create(const ASource: string; const ARun: Boolean);
    destructor Destroy; override;
    /// <summary>The value of the variable of the position, as an integer</summary>
    function IntegerOf(const AIndex: Integer): Integer;
    /// <summary>The value of the variable of the position, as a string</summary>
    function StringOf(const AIndex: Integer): string;
    /// <summary>The value of the variable of the position, as a float</summary>
    function FloatOf(const AIndex: Integer): Double;
    property Exec: TPSExec read FExec;
  end;

implementation

function OnUsesOnlySystem(Sender: TPSPascalCompiler; const Name: TbtString): Boolean;
begin
  Result := string(Name) = 'SYSTEM';
end;

{ TTestInterpreter }

constructor TTestInterpreter.Create(const ASource: string; const ARun: Boolean);
var
  LCompiler: TPSPascalCompiler;
  LBytes: TbtString;
begin
  inherited Create;
  LCompiler := TPSPascalCompiler.Create(PRTabArray(@DefaultLookupTable), DEFAULT_KEYWORD_COUNT);
  try
    LCompiler.OnUses := OnUsesOnlySystem;
    if not LCompiler.Compile(TbtString(ASource)) then
    begin
      if LCompiler.MsgCount > 0 then
        raise Exception.Create('compile: ' + string(LCompiler.Msg[0].MessageToString));
      raise Exception.Create('compile');
    end;
    LCompiler.GetOutput(LBytes);
  finally
    LCompiler.Free;
  end;
  FExec := TPSExec.Create;
  if not FExec.LoadData(LBytes) then
    raise Exception.Create('load');
  if ARun and not FExec.RunScript then
    raise Exception.Create('run');
end;

destructor TTestInterpreter.Destroy;
begin
  FExec.Free;
  inherited Destroy;
end;

function TTestInterpreter.IntegerOf(const AIndex: Integer): Integer;
var
  LVariable: PIFVariant;
begin
  LVariable := FExec.GetVarNo(AIndex);
  Result := PSGetInt(@PPSVariantData(LVariable).Data, LVariable.FType);
end;

function TTestInterpreter.StringOf(const AIndex: Integer): string;
var
  LVariable: PIFVariant;
begin
  LVariable := FExec.GetVarNo(AIndex);
  Result := string(PSGetUnicodeString(@PPSVariantData(LVariable).Data, LVariable.FType));
end;

function TTestInterpreter.FloatOf(const AIndex: Integer): Double;
var
  LVariable: PIFVariant;
begin
  LVariable := FExec.GetVarNo(AIndex);
  Result := PSGetReal(@PPSVariantData(LVariable).Data, LVariable.FType);
end;

end.
