{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the keen library - the AdLib sound effects         }
{  against the original id_sd.c                                                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.AdLibParity;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework;

type
  /// <summary>
  ///   The scripts that Tools\Verifica\165\audio runs on the original id_sd.c (Open Watcom, 16 bit, in DOSBox):
  ///   the golden file has the hash of the registers that each script writes to the card, with the services of
  ///   the timer between them. See Tests\Data\README.md
  /// </summary>
  [TestFixture]
  [Category('keen')]
  [Category('keen-parity')]
  TTestKeenAdLibParity = class(TObject)
  public
    /// <summary>With DELPHIDOOM_KEEN_ADLIB_SCENARIOS set to a path, writes there the input of the C harness (SCEN.TXT)</summary>
    [Test]
    procedure GeneraGliScenariPerIlC;
    /// <summary>With DELPHIDOOM_KEEN_ADLIB_PORT_OUT set to a path, writes there what the port does (to compare with OUT.TXT)</summary>
    [Test]
    procedure ScriviIlRisultatoDelPorting;
    [Test]
    procedure DovrebbeScrivereGliStessiRegistriDelCInOgniScenario;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Tests.Keen.AdLibScenarios, DelphiDoom.Tests.Shared.Files, DelphiDoom.Tests.Shared.Skip;

const
  SCENARIO_COUNT = 300;

{ TTestKeenAdLibParity }

procedure TTestKeenAdLibParity.GeneraGliScenariPerIlC;
var
  LPath: string;
  LScript: string;
  LBuilder: TStringBuilder;
begin
  LPath := GetEnvironmentVariable('DELPHIDOOM_KEEN_ADLIB_SCENARIOS');
  if LPath = '' then
    TTestSkip.Ignore('DELPHIDOOM_KEEN_ADLIB_SCENARIOS non impostata: nessun file da scrivere per il harness C');
  LBuilder := TStringBuilder.Create;
  try
    for LScript in TKeenAdLibScenarios.Generate(SCENARIO_COUNT) do
      LBuilder.Append(LScript);
    TFile.WriteAllText(LPath, LBuilder.ToString, TEncoding.ASCII);
  finally
    LBuilder.Free;
  end;
  Assert.IsTrue(TFile.Exists(LPath));
end;

procedure TTestKeenAdLibParity.ScriviIlRisultatoDelPorting;
var
  LPath: string;
  LScript: string;
  LBuilder: TStringBuilder;
begin
  LPath := GetEnvironmentVariable('DELPHIDOOM_KEEN_ADLIB_PORT_OUT');
  if LPath = '' then
    TTestSkip.Ignore('DELPHIDOOM_KEEN_ADLIB_PORT_OUT non impostata: nessun file da scrivere');
  LBuilder := TStringBuilder.Create;
  try
    for LScript in TKeenAdLibScenarios.Generate(SCENARIO_COUNT) do
      LBuilder.Append(TKeenAdLibScenarios.Run(LScript));
    TFile.WriteAllText(LPath, LBuilder.ToString, TEncoding.ASCII);
  finally
    LBuilder.Free;
  end;
  Assert.IsTrue(TFile.Exists(LPath));
end;

procedure TTestKeenAdLibParity.DovrebbeScrivereGliStessiRegistriDelCInOgniScenario;
var
  LGolden: TStringList;
  LScripts: TArray<string>;
  LIndex: Integer;
  LText: string;
  LParts: TArray<string>;
  LDifferent: Integer;
  LFirst: string;
begin
  LGolden := TTestFiles.Lines(TTestFiles.DataFile('Keen', 'adlib.golden.txt'));
  try
    LScripts := TKeenAdLibScenarios.Generate(SCENARIO_COUNT);
    Assert.AreEqual(Length(LScripts), LGolden.Count, 'scripts and lines of the golden file');
    LDifferent := 0;
    LFirst := '';
    for LIndex := 0 to High(LScripts) do
    begin
      LText := TKeenAdLibScenarios.Run(LScripts[LIndex]);
      LParts := LGolden[LIndex].Split([' ']);
      if IntToHex(TKeenAdLibScenarios.Hash(LText), 8) <> LParts[3] then
      begin
        Inc(LDifferent);
        if LFirst = '' then
          LFirst := Format('#%d: golden %s, port %s', [LIndex, LParts[3], IntToHex(TKeenAdLibScenarios.Hash(LText), 8)]) +
            sLineBreak + LScripts[LIndex] + sLineBreak + LText;
      end;
    end;
    Assert.AreEqual(0, LDifferent, Format('%d scripts differ from the C. %s', [LDifferent, LFirst]));
  finally
    LGolden.Free;
  end;
end;

end.
