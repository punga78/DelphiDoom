{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Gui library - parity with the code of Quake III    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Gui.Parity;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework;

type
  /// <summary>
  ///   The scenarios of Tests\Data\Gui\scenarios run with the classes of the library, against the golden files
  ///   that Tools\Verifica\125 made with the real ui_shared.c, the botlib precompiler and tr_font.c
  /// </summary>
  [TestFixture]
  [Category('gui')]
  TTestGuiParity = class(TObject)
  private
    function SameButLine(const AActual, AExpected: string): Boolean;
    procedure Compare(const AScenario: string; const AInput: Boolean = False);
  public
    [Test]
    procedure DovrebbeLeggereTuttiIMenuComeIlCodiceDiQuake;
    [Test]
    procedure DovrebbeLeggereLaListaDeiMenuComeIlCodiceDiQuake;
    [Test]
    procedure DovrebbeDareGliStessiErroriENumeriDelCodiceDiQuake;
    [Test]
    procedure DovrebbeLeggereIFontComeRegisterFont;
    [Test]
    procedure DovrebbeEseguireGliScriptComeItemRunScript;
    [Test]
    procedure DovrebbeGestirePilaFocusMouseETastiComeIlCodiceDiQuake;
    [Test]
    procedure DovrebbeTrascinareBarreECampiDiTestoComeIlCodiceDiQuake;
  end;

implementation

uses
  DelphiDoom.Tests.Gui.Fakes, DelphiDoom.Tests.Gui.Scenario, DelphiDoom.Tests.Gui.InputScenario;

// The only declared tolerance: the line number of an error message may differ by one. The botlib precompiler
// counts lines in its own way after "#" directives and at the end of the file (see README.md of the library);
// the idLexer counts the line where the token is. Text and every other line are exact.
function TTestGuiParity.SameButLine(const AActual, AExpected: string): Boolean;
const
  MARKER = ', line ';
var
  LActualAt: Integer;
  LExpectedAt: Integer;
  LActualLine: Integer;
  LExpectedLine: Integer;
  LActualEnd: Integer;
  LExpectedEnd: Integer;
begin
  Result := False;
  if Copy(AExpected, 1, 12) <> 'log ^1ERROR:' then
    Exit;
  LActualAt := Pos(MARKER, AActual);
  LExpectedAt := Pos(MARKER, AExpected);
  if (LActualAt = 0) or (LActualAt <> LExpectedAt) then
    Exit;
  LActualEnd := Pos(':', Copy(AActual, LActualAt, MaxInt)) + LActualAt - 1;
  LExpectedEnd := Pos(':', Copy(AExpected, LExpectedAt, MaxInt)) + LExpectedAt - 1;
  if not TryStrToInt(Copy(AActual, LActualAt + Length(MARKER), LActualEnd - LActualAt - Length(MARKER)), LActualLine) then
    Exit;
  if not TryStrToInt(Copy(AExpected, LExpectedAt + Length(MARKER), LExpectedEnd - LExpectedAt - Length(MARKER)),
    LExpectedLine) then
    Exit;
  Result := (Abs(LActualLine - LExpectedLine) <= 1) and (Copy(AActual, 1, LActualAt) = Copy(AExpected, 1, LExpectedAt)) and
    (Copy(AActual, LActualEnd, MaxInt) = Copy(AExpected, LExpectedEnd, MaxInt));
end;

procedure TTestGuiParity.Compare(const AScenario: string; const AInput: Boolean);
var
  LActual: TStringList;
  LExpected: TStringList;
  LFiltered: TStringList;
  LLine: string;
  LIndex: Integer;
begin
  LActual := TStringList.Create;
  LExpected := TStringList.Create;
  LFiltered := TStringList.Create;
  try
    if AInput then
      TGuiInputScenarioRunner.Run(GuiDataFolder + 'files\', GuiDataFolder + 'scenarios\' + AScenario + '.txt', LActual)
    else
      TGuiScenarioRunner.Run(GuiDataFolder + 'files\', GuiDataFolder + 'scenarios\' + AScenario + '.txt', LActual);
    LExpected.LoadFromFile(GuiDataFolder + 'golden\' + AScenario + '.golden.txt');
    // the C driver prints the milliseconds of UI_LoadMenus; the library does not measure time
    for LLine in LExpected do
      if Copy(LLine, 1, 24) <> 'log UI menu load time = ' then
        LFiltered.Add(LLine);
    for LIndex := 0 to LFiltered.Count - 1 do
    begin
      if LIndex >= LActual.Count then
        Assert.Fail(Format('%s: the transcript ends at line %d, expected: %s', [AScenario, LIndex + 1, LFiltered[LIndex]]));
      if (LActual[LIndex] <> LFiltered[LIndex]) and (not SameButLine(LActual[LIndex], LFiltered[LIndex])) then
        Assert.Fail(Format('%s, line %d' + sLineBreak + 'expected: %s' + sLineBreak + 'actual:   %s',
          [AScenario, LIndex + 1, LFiltered[LIndex], LActual[LIndex]]));
    end;
    Assert.AreEqual(LFiltered.Count, LActual.Count, AScenario + ': number of lines');
  finally
    LFiltered.Free;
    LExpected.Free;
    LActual.Free;
  end;
end;

procedure TTestGuiParity.DovrebbeLeggereTuttiIMenuComeIlCodiceDiQuake;
begin
  Compare('menus');
end;

procedure TTestGuiParity.DovrebbeLeggereLaListaDeiMenuComeIlCodiceDiQuake;
begin
  Compare('menulist');
end;

procedure TTestGuiParity.DovrebbeDareGliStessiErroriENumeriDelCodiceDiQuake;
begin
  Compare('broken');
end;

procedure TTestGuiParity.DovrebbeLeggereIFontComeRegisterFont;
begin
  Compare('fonts');
end;

procedure TTestGuiParity.DovrebbeEseguireGliScriptComeItemRunScript;
begin
  Compare('scripts');
end;

procedure TTestGuiParity.DovrebbeGestirePilaFocusMouseETastiComeIlCodiceDiQuake;
begin
  Compare('input', True);
end;

procedure TTestGuiParity.DovrebbeTrascinareBarreECampiDiTestoComeIlCodiceDiQuake;
begin
  Compare('input2', True);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGuiParity);

end.
