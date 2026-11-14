{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Doom script library - parity with the C++     }
{  of Doom 3                                                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.DoomScript.Parity;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework;

type
  /// <summary>
  ///   Parity of the library with the real Script_*.cpp, Event.cpp and Class.cpp of Doom 3: every scenario
  ///   of Tests\Data\DoomScript\scenarios runs on the Pascal driver and its lines are compared, one by one,
  ///   with the golden the C++ harness (Tools\Verifica\110) wrote. The only differences accepted are the
  ///   ones declared in <c>SameLine</c>.
  /// </summary>
  [TestFixture]
  [Category('DoomScript')]
  TTestDoomScriptParity = class
  strict private
    class function DataFolder: string; static;
    class function SameLine(const AExpected, AActual: string): Boolean; static;
    class function SameStack(const AExpected, AActual: string): Boolean; static;
    class function ApplyDeclared(const AScenario, AGoldenLine: string): string; static;
    procedure RunScenario(const AName: string);
  public
    [Test]
    procedure DovrebbeDareLeRigheDelCppPerCompileErrors;
    [Test]
    procedure DovrebbeDareLeRigheDelCppPerDebug;
    [Test]
    procedure DovrebbeDareLeRigheDelCppPerEvents;
    [Test]
    procedure DovrebbeDareLeRigheDelCppPerExpr;
    [Test]
    procedure DovrebbeDareLeRigheDelCppPerFlow;
    [Test]
    procedure DovrebbeDareLeRigheDelCppPerLimits;
    [Test]
    procedure DovrebbeDareLeRigheDelCppPerNamespaces;
    [Test]
    procedure DovrebbeDareLeRigheDelCppPerObjects;
    [Test]
    procedure DovrebbeDareLeRigheDelCppPerPreprocRestart;
    [Test]
    procedure DovrebbeDareLeRigheDelCppPerRuntimeErrors;
    [Test]
    procedure DovrebbeDareLeRigheDelCppPerSave;
    [Test]
    procedure DovrebbeDareLeRigheDelCppPerSmoke;
    [Test]
    procedure DovrebbeDareLeRigheDelCppPerSysmath;
    [Test]
    procedure DovrebbeDareLeRigheDelCppPerSysworld;
    [Test]
    procedure DovrebbeDareLeRigheDelCppPerThreads;
    [Test]
    procedure DovrebbeDareLeRigheDelCppPerTypes;
    [Test]
    procedure DovrebbeAccettareNellaPilaSoloIPuntatoriAiCampi;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Tests.DoomScript.Parity.Scenario;

class function TTestDoomScriptParity.DataFolder: string;
begin
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\..\..\Tests\Data\DoomScript'));
end;

type
  TDeclaredDifference = record
    Scenario: string;
    Golden: string;
    Port: string;
  end;

const
  // The differences from the goldens that are accepted, value by value. sys.sin and sys.cos call the sinf and
  // cosf of the C runtime: the one of the harness (bcc32c) reduces a large angle in single precision and is
  // some units in the last place away from the exact value; the port, as the game on the x87, gives the
  // correctly rounded one. Only sin( 1234.5 ) and cos( -777.25 ) of script/sysmath.script show it: their
  // bits (as RETURN prints them and as the bytes of the globals) and the six decimals of the second one.
  DeclaredDifferences: array[0..3] of TDeclaredDifference = (
    (Scenario: 'sysmath'; Golden: '3F0A7D50'; Port: '3F0A7D4B'),
    (Scenario: 'sysmath'; Golden: '507D0A3F'; Port: '4B7D0A3F'),
    (Scenario: 'sysmath'; Golden: '116CDC3E'; Port: '016CDC3E'),
    (Scenario: 'sysmath'; Golden: ' -1 0.540975'; Port: ' -1 0.540974'));

class function TTestDoomScriptParity.ApplyDeclared(const AScenario, AGoldenLine: string): string;
var
  LIndex: Integer;
begin
  Result := AGoldenLine;
  for LIndex := Low(DeclaredDifferences) to High(DeclaredDifferences) do
    if (DeclaredDifferences[LIndex].Scenario = AScenario) then
      Result := StringReplace(Result, DeclaredDifferences[LIndex].Golden, DeclaredDifferences[LIndex].Port,
        [rfReplaceAll]);
end;

class function TTestDoomScriptParity.SameStack(const AExpected, AActual: string): Boolean;
var
  LIndex: Integer;
  LWord: Cardinal;
begin
  // A local stack may hold the temporary of OP_ADDRESS, a pointer to a field of a script object: a machine
  // address in the original, a checked handle here ($80000000 or entity shl 18 or offset). Only such a
  // word (little endian, 8 hex digits) may differ, and only where the original has something too.
  if Length(AExpected) <> Length(AActual) then
    Exit(False);
  LIndex := 1;
  while LIndex + 7 <= Length(AExpected) do
  begin
    if Copy(AExpected, LIndex, 8) <> Copy(AActual, LIndex, 8) then
    begin
      LWord := Cardinal(StrToInt64('$' + Copy(AActual, LIndex + 6, 2) + Copy(AActual, LIndex + 4, 2) +
        Copy(AActual, LIndex + 2, 2) + Copy(AActual, LIndex, 2)));
      if ((LWord and $C0000000) <> $80000000) or (Copy(AExpected, LIndex, 8) = '00000000') then
        Exit(False);
    end;
    Inc(LIndex, 8);
  end;
  Result := LIndex > Length(AExpected);
end;

class function TTestDoomScriptParity.SameLine(const AExpected, AActual: string): Boolean;
var
  LExpectedParts: TArray<string>;
  LActualParts: TArray<string>;
begin
  if AExpected = AActual then
    Exit(True);
  Result := False;
  LExpectedParts := AExpected.Split([' ']);
  LActualParts := AActual.Split([' ']);
  // "STACK <thread> <hex>" and "SAVE stack <index> <hex>"
  if (Length(LExpectedParts) = 3) and (Length(LActualParts) = 3) and (LExpectedParts[0] = 'STACK') and
    (LActualParts[0] = 'STACK') and (LExpectedParts[1] = LActualParts[1]) then
    Result := SameStack(LExpectedParts[2], LActualParts[2])
  else if (Length(LExpectedParts) = 4) and (Length(LActualParts) = 4) and (LExpectedParts[0] = 'SAVE') and
    (LExpectedParts[1] = 'stack') and (LActualParts[0] = 'SAVE') and (LActualParts[1] = 'stack') and
    (LExpectedParts[2] = LActualParts[2]) then
    Result := SameStack(LExpectedParts[3], LActualParts[3]);
end;

procedure TTestDoomScriptParity.RunScenario(const AName: string);
var
  LScenario: TDoomScriptParityScenario;
  LCommands: TStringList;
  LGolden: TStringList;
  LIndex: Integer;
  LActualFolder: string;
begin
  LCommands := TStringList.Create;
  LGolden := TStringList.Create;
  LScenario := TDoomScriptParityScenario.Create(TPath.Combine(DataFolder, 'scripts'));
  try
    LCommands.LoadFromFile(TPath.Combine(DataFolder, 'scenarios\' + AName + '.scn'), TEncoding.ANSI);
    LGolden.LoadFromFile(TPath.Combine(DataFolder, 'golden\' + AName + '.golden.txt'), TEncoding.ANSI);
    LScenario.Run(LCommands);
    // to look at a difference: set DOOMSCRIPT_PARITY_OUT to a folder and the lines of the port go there
    LActualFolder := GetEnvironmentVariable('DOOMSCRIPT_PARITY_OUT');
    if LActualFolder <> '' then
      LScenario.Lines.SaveToFile(TPath.Combine(LActualFolder, AName + '.actual.txt'), TEncoding.ANSI);
    for LIndex := 0 to LGolden.Count - 1 do
    begin
      if LIndex >= LScenario.Lines.Count then
        Assert.Fail(Format('%s: the port stops at line %d, the golden goes on with: %s', [AName, LIndex + 1,
          LGolden[LIndex]]));
      if not SameLine(ApplyDeclared(AName, LGolden[LIndex]), LScenario.Lines[LIndex]) then
        Assert.Fail(Format('%s, line %d'#13#10'  golden: %s'#13#10'  port:   %s', [AName, LIndex + 1,
          LGolden[LIndex], LScenario.Lines[LIndex]]));
    end;
    if LScenario.Lines.Count > LGolden.Count then
      Assert.Fail(Format('%s: the golden ends at line %d, the port goes on with: %s', [AName, LGolden.Count,
        LScenario.Lines[LGolden.Count]]));
    Assert.IsTrue(LGolden.Count > 0, AName + ': empty golden');
  finally
    LScenario.Free;
    LGolden.Free;
    LCommands.Free;
  end;
end;

procedure TTestDoomScriptParity.DovrebbeDareLeRigheDelCppPerCompileErrors;
begin
  RunScenario('compile_errors');
end;

procedure TTestDoomScriptParity.DovrebbeDareLeRigheDelCppPerDebug;
begin
  RunScenario('debug');
end;

procedure TTestDoomScriptParity.DovrebbeDareLeRigheDelCppPerEvents;
begin
  RunScenario('events');
end;

procedure TTestDoomScriptParity.DovrebbeDareLeRigheDelCppPerExpr;
begin
  RunScenario('expr');
end;

procedure TTestDoomScriptParity.DovrebbeDareLeRigheDelCppPerFlow;
begin
  RunScenario('flow');
end;

procedure TTestDoomScriptParity.DovrebbeDareLeRigheDelCppPerLimits;
begin
  RunScenario('limits');
end;

procedure TTestDoomScriptParity.DovrebbeDareLeRigheDelCppPerNamespaces;
begin
  RunScenario('namespaces');
end;

procedure TTestDoomScriptParity.DovrebbeDareLeRigheDelCppPerObjects;
begin
  RunScenario('objects');
end;

procedure TTestDoomScriptParity.DovrebbeDareLeRigheDelCppPerPreprocRestart;
begin
  RunScenario('preproc_restart');
end;

procedure TTestDoomScriptParity.DovrebbeDareLeRigheDelCppPerRuntimeErrors;
begin
  RunScenario('runtime_errors');
end;

procedure TTestDoomScriptParity.DovrebbeDareLeRigheDelCppPerSave;
begin
  RunScenario('save');
end;

procedure TTestDoomScriptParity.DovrebbeDareLeRigheDelCppPerSmoke;
begin
  RunScenario('smoke');
end;

procedure TTestDoomScriptParity.DovrebbeDareLeRigheDelCppPerSysmath;
begin
  RunScenario('sysmath');
end;

procedure TTestDoomScriptParity.DovrebbeDareLeRigheDelCppPerSysworld;
begin
  RunScenario('sysworld');
end;

procedure TTestDoomScriptParity.DovrebbeDareLeRigheDelCppPerThreads;
begin
  RunScenario('threads');
end;

procedure TTestDoomScriptParity.DovrebbeDareLeRigheDelCppPerTypes;
begin
  RunScenario('types');
end;

procedure TTestDoomScriptParity.DovrebbeAccettareNellaPilaSoloIPuntatoriAiCampi;
begin
  Assert.IsTrue(SameLine('STACK 1 0000803F', 'STACK 1 0000803F'));
  // a machine address against a handle of the port
  Assert.IsTrue(SameLine('STACK 1 0000803F78563412', 'STACK 1 0000803F04000480'));
  Assert.IsTrue(SameLine('SAVE stack 0 78563412', 'SAVE stack 0 04000480'));
  // not a handle, another thread, another length, nothing in the original, another kind of line
  Assert.IsFalse(SameLine('STACK 1 0000803F', 'STACK 1 00000040'));
  Assert.IsFalse(SameLine('STACK 1 78563412', 'STACK 2 04000480'));
  Assert.IsFalse(SameLine('STACK 1 78563412', 'STACK 1 0400048000000000'));
  Assert.IsFalse(SameLine('STACK 1 00000000', 'STACK 1 04000480'));
  Assert.IsFalse(SameLine('SAVE thread 0 78563412', 'SAVE thread 0 04000480'));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDoomScriptParity);

end.
