{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of Pascal Script - Extended constants in a compiled script }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.ScriptHost.CompiledExtended;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  ps_defs,
  ps_utils,
  ps_keywords,
  ps_compiler,
  ps_runtime;

type
  /// <summary>
  ///   A compiled script (.ddout) is the same file at 32 and at 64 bit: an Extended constant is
  ///   always the 10 bytes of the x87, also where the type Extended is a Double (issue #40)
  /// </summary>
  [TestFixture]
  [Category('scripthost')]
  TTestScriptHostCompiledExtended = class
  strict private
    function Compile(const ASource: string): TbtString;
    function Run(const ACompiled: TbtString; const AVariable: Integer): Double;
    class function FromHex(const AHex: string): TbtString; static;
    class function ToHex(const ABytes: TbtString): string; static;
  public
    [Test]
    procedure DovrebbeScrivereLExtendedInDieciByte;
    [Test]
    procedure DovrebbeDareLoStessoCompilatoDiWin32;
    [Test]
    procedure DovrebbeCaricareIlCompilatoDiWin32;
    [Test]
    procedure DovrebbeEseguireCioCheCompila;
  end;

implementation

const
  SOURCE_EXTENDED =
    'var e: Extended; f: Extended;'#13#10 +
    'begin'#13#10 +
    '  e := 1.5;'#13#10 +
    '  f := e * 2.25 + 0.125;'#13#10 +
    'end.';
  // 1.5 as the x87 writes it: mantissa $C000000000000000, exponent $3FFF
  EXTENDED_ONE_AND_HALF = '0000000000000000C0FF3F';
  // SOURCE_EXTENDED compiled by the 32 bit compiler (the bytes of GetOutput)
  COMPILED_BY_WIN32 =
    '49465053170000001D000000020000000200000001000000000000000D00000000050000000010000000000E000000001800' +
    '00000009000000000800000000070000000011000000000A0000000005000000000600000000040000000003000000000200' +
    '0000000A000000001C000000001C000000001C000000000A000000001C000000001300000000140000000012000000000100' +
    '000000030000000005000000008107000000424F4F4C45414E00000000010000000002F80000004D00000005000000214D41' +
    '494E020000002D310245010000060000000B000000214D415354455250524F43020000002D31050000000005000000000000' +
    '00000000010500000000000000000000C0FF3F00000100000000000000000102000100000001050000000000000000000090' +
    '00400100000100000001050000000000000000000080FC3F09050000000009';

function OnUsesOnlySystem(Sender: TPSPascalCompiler; const Name: TbtString): Boolean;
begin
  Result := string(Name) = 'SYSTEM';
end;

{ TTestScriptHostCompiledExtended }

function TTestScriptHostCompiledExtended.Compile(const ASource: string): TbtString;
var
  LCompiler: TPSPascalCompiler;
begin
  LCompiler := TPSPascalCompiler.Create(PRTabArray(@DefaultLookupTable), DEFAULT_KEYWORD_COUNT);
  try
    LCompiler.OnUses := OnUsesOnlySystem;
    Assert.IsTrue(LCompiler.Compile(TbtString(ASource)), 'compile');
    LCompiler.GetOutput(Result);
  finally
    LCompiler.Free;
  end;
end;

function TTestScriptHostCompiledExtended.Run(const ACompiled: TbtString; const AVariable: Integer): Double;
var
  LExec: TPSExec;
  LVariable: PIFVariant;
begin
  LExec := TPSExec.Create;
  try
    Assert.IsTrue(LExec.LoadData(ACompiled), 'load');
    Assert.IsTrue(LExec.RunScript, 'run');
    LVariable := LExec.GetVarNo(AVariable);
    Result := PSGetReal(@PPSVariantData(LVariable).Data, LVariable.FType);
  finally
    LExec.Free;
  end;
end;

class function TTestScriptHostCompiledExtended.FromHex(const AHex: string): TbtString;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(AHex) div 2);
  for LIndex := 1 to Length(Result) do
    Result[LIndex] := AnsiChar(StrToInt('$' + Copy(AHex, LIndex * 2 - 1, 2)) and $FF);
end;

class function TTestScriptHostCompiledExtended.ToHex(const ABytes: TbtString): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 1 to Length(ABytes) do
    Result := Result + IntToHex(Ord(ABytes[LIndex]), 2);
end;

procedure TTestScriptHostCompiledExtended.DovrebbeScrivereLExtendedInDieciByte;
begin
  Assert.IsTrue(Pos(EXTENDED_ONE_AND_HALF, ToHex(Compile(SOURCE_EXTENDED))) > 0,
    'the compiled script has no 10 byte image of 1.5');
end;

procedure TTestScriptHostCompiledExtended.DovrebbeDareLoStessoCompilatoDiWin32;
begin
  Assert.AreEqual(COMPILED_BY_WIN32, ToHex(Compile(SOURCE_EXTENDED)));
end;

procedure TTestScriptHostCompiledExtended.DovrebbeCaricareIlCompilatoDiWin32;
var
  LCompiled: TbtString;
begin
  LCompiled := FromHex(COMPILED_BY_WIN32);
  Assert.AreEqual<Double>(1.5, Run(LCompiled, 0));
  Assert.AreEqual<Double>(3.5, Run(LCompiled, 1));
end;

procedure TTestScriptHostCompiledExtended.DovrebbeEseguireCioCheCompila;
var
  LCompiled: TbtString;
begin
  LCompiled := Compile(SOURCE_EXTENDED);
  Assert.AreEqual<Double>(1.5, Run(LCompiled, 0));
  Assert.AreEqual<Double>(3.5, Run(LCompiled, 1));
end;

end.
