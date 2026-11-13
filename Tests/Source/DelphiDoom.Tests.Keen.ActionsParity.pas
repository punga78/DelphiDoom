{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the keen library - the actions against the C       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.ActionsParity;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework;

type
  /// <summary>
  ///   The same scenarios that Tools\Verifica\165 runs on the original functions of kd_keen.c, kd_act1.c and
  ///   kd_act2.c (Open Watcom, 16 bit, in DOSBox): the golden file has the hash of what each scenario did. See
  ///   Tests\Data\README.md for how it is made
  /// </summary>
  [TestFixture]
  [Category('keen')]
  [Category('keen-parity')]
  TTestKeenActionsParity = class(TObject)
  public
    /// <summary>With DELPHIDOOM_KEEN_SCENARIOS set to a path, writes there the input of the C harness (SCEN.TXT)</summary>
    [Test]
    procedure GeneraGliScenariPerIlC;
    /// <summary>With DELPHIDOOM_KEEN_PORT_OUT set to a path, writes there what the port does, in the format of OUT.TXT of the harness (to compare with a diff)</summary>
    [Test]
    procedure ScriviIlRisultatoDelPorting;
    [Test]
    procedure DovrebbeDareLoStessoRisultatoDelCInOgniScenario;
    [Test]
    procedure DovrebbeCoprireOgniFunzioneDegliStati;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Keen.ActionIds, DelphiDoom.Keen.StateTable, DelphiDoom.Tests.Keen.ActionScenarios;

const
  SCENARIOS_PER_ACTION = 30;

{ TTestKeenActionsParity }

procedure TTestKeenActionsParity.GeneraGliScenariPerIlC;
var
  LPath: string;
begin
  LPath := GetEnvironmentVariable('DELPHIDOOM_KEEN_SCENARIOS');
  if LPath = '' then
  begin
    Assert.Pass('Set DELPHIDOOM_KEEN_SCENARIOS to write the file for the C harness');
    Exit;
  end;
  TFile.WriteAllText(LPath, TKeenActionScenarios.ToHarnessText(TKeenActionScenarios.Generate(SCENARIOS_PER_ACTION)),
    TEncoding.ASCII);
  Assert.IsTrue(TFile.Exists(LPath));
end;

procedure TTestKeenActionsParity.ScriviIlRisultatoDelPorting;
var
  LPath: string;
  LBuilder: TStringBuilder;
  LScenario: TKeenScenario;
begin
  LPath := GetEnvironmentVariable('DELPHIDOOM_KEEN_PORT_OUT');
  if LPath = '' then
  begin
    Assert.Pass('Set DELPHIDOOM_KEEN_PORT_OUT to write what the port does');
    Exit;
  end;
  LBuilder := TStringBuilder.Create;
  try
    for LScenario in TKeenActionScenarios.Generate(SCENARIOS_PER_ACTION) do
      LBuilder.Append(TKeenActionScenarios.Run(LScenario));
    TFile.WriteAllText(LPath, LBuilder.ToString, TEncoding.ASCII);
  finally
    LBuilder.Free;
  end;
end;

procedure TTestKeenActionsParity.DovrebbeDareLoStessoRisultatoDelCInOgniScenario;
var
  LGoldenPath: string;
  LLines: TStringList;
  LScenarios: TArray<TKeenScenario>;
  LIndex: Integer;
  LText: string;
  LParts: TArray<string>;
  LFailures: string;
  LCount: Integer;
  LNames: TStringList;
begin
  LGoldenPath := TPath.GetFullPath(ExtractFilePath(ParamStr(0)) + '..\..\Tests\Data\Keen\actions.golden.txt');
  if not TFile.Exists(LGoldenPath) then
  begin
    Assert.Pass('The golden file of the actions is not here');
    Exit;
  end;
  LScenarios := TKeenActionScenarios.Generate(SCENARIOS_PER_ACTION);
  LLines := TStringList.Create;
  try
    LLines.LoadFromFile(LGoldenPath);
    Assert.AreEqual<Integer>(Length(LScenarios), LLines.Count, 'scenarios and lines of the golden file');
    LFailures := '';
    LCount := 0;
    LNames := TStringList.Create;
    LNames.Sorted := True;
    LNames.Duplicates := dupIgnore;
    for LIndex := 0 to High(LScenarios) do
    begin
      LText := TKeenActionScenarios.Run(LScenarios[LIndex]);
      LParts := LLines[LIndex].Split([' ']);
      if IntToHex(TKeenActionScenarios.Hash(LText), 8) <> LParts[3] then
      begin
        Inc(LCount);
        LNames.Add(LScenarios[LIndex].Name + ' ' + LScenarios[LIndex].Kind);
        if LCount <= 1 then
          LFailures := LFailures + sLineBreak + Format('#%d %s %s: golden %s, port %s', [LIndex, LScenarios[LIndex].Name,
            LScenarios[LIndex].Kind, LParts[3], IntToHex(TKeenActionScenarios.Hash(LText), 8)]) + sLineBreak + LText;
      end;
    end;
    try
      Assert.AreEqual(0, LCount, Format('%d scenarios differ from the C (%s):%s', [LCount, LNames.CommaText, LFailures]));
    finally
      LNames.Free;
    end;
  finally
    LLines.Free;
  end;
end;

procedure TTestKeenActionsParity.DovrebbeCoprireOgniFunzioneDegliStati;
var
  LScenarios: TArray<TKeenScenario>;
  LScenario: TKeenScenario;
  LSeen: array[0..KEEN_ACTION_COUNT - 1] of Boolean;
  LAction: Integer;
  LMissing: string;
begin
  FillChar(LSeen, SizeOf(LSeen), 0);
  LScenarios := TKeenActionScenarios.Generate(SCENARIOS_PER_ACTION);
  for LScenario in LScenarios do
    LSeen[LScenario.Action] := True;
  LMissing := '';
  for LAction := 1 to KEEN_ACTION_COUNT - 1 do
    if not LSeen[LAction] then
      LMissing := LMissing + ' ' + KEEN_ACTION_NAMES[LAction];
  // ScoreThink draws into the sprite memory: it has its own tests
  Assert.AreEqual(' ScoreThink', LMissing);
end;

end.
