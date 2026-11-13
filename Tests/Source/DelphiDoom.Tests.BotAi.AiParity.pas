{******************************************************************************}
{                                                                              }
{  DelphiDoom: parity of the characters, fuzzy weights, weapons and structures }
{  of the bots with Quake III Arena (DUnitX)                                   }
{                                                                              }
{  Tests\Data\BotAi\botscenario.golden.txt is what the REAL be_ai_char.c,      }
{  be_ai_weight.c, be_ai_weap.c, l_struct.c, l_libvar.c, l_script.c and        }
{  l_precomp.c write for Tests\Data\BotAi\botscenario.txt (Tools\Verifica\123); }
{  botscenario_alt1/alt2.golden.txt the same for botscenario_alt.txt on the    }
{  folders alt1 and alt2.                                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.BotAi.AiParity;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('BotAi')]
  TTestBotAiParity = class
  strict private
    procedure CompareWithGolden(const ADataFolder, AScenarioFile, AGoldenFile: string; const AMinimumLines: Integer);
  public
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelCSuTuttoLoScenario;
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelCConUnDefaultSenzaLivelli;
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelCSenzaIlFileDiDefault;
    [Test]
    procedure DovrebbeEseguireTuttiIComandiDelloScenario;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.IOUtils, DelphiDoom.Tests.BotAi.Support,
  DelphiDoom.Tests.BotAi.AiScenarioRunner;

{ TTestBotAiParity }

procedure TTestBotAiParity.CompareWithGolden(const ADataFolder, AScenarioFile, AGoldenFile: string;
  const AMinimumLines: Integer);
var
  LScenario: TStringList;
  LGolden: TStringList;
  LRunner: TBotAiScenarioRunner;
  LIndex: Integer;
  LCount: Integer;
begin
  LScenario := TStringList.Create;
  LGolden := TStringList.Create;
  LRunner := TBotAiScenarioRunner.Create(TFolderBotFiles.Create(ADataFolder));
  try
    LScenario.LoadFromFile(TPath.Combine(BotDataFolder, AScenarioFile), TEncoding.ANSI);
    LGolden.LoadFromFile(TPath.Combine(BotDataFolder, AGoldenFile), TEncoding.ANSI);
    LRunner.Run(LScenario);
    Assert.IsTrue(LGolden.Count > AMinimumLines, 'golden vuoto');
    LCount := LGolden.Count;
    if LRunner.Output.Count < LCount then
      LCount := LRunner.Output.Count;
    for LIndex := 0 to LCount - 1 do
      Assert.AreEqual(LGolden[LIndex].TrimRight, LRunner.Output[LIndex].TrimRight, 'riga ' + IntToStr(LIndex + 1));
    Assert.AreEqual(LGolden.Count, LRunner.Output.Count, 'numero di righe');
  finally
    LRunner.Free;
    LGolden.Free;
    LScenario.Free;
  end;
end;

procedure TTestBotAiParity.DovrebbeDareLeStesseRisposteDelCSuTuttoLoScenario;
begin
  CompareWithGolden(BotDataFolder, 'botscenario.txt', 'botscenario.golden.txt', 3000);
end;

procedure TTestBotAiParity.DovrebbeDareLeStesseRisposteDelCConUnDefaultSenzaLivelli;
begin
  CompareWithGolden(TPath.Combine(BotDataFolder, 'alt1'), 'botscenario_alt.txt', 'botscenario_alt1.golden.txt', 1000);
end;

procedure TTestBotAiParity.DovrebbeDareLeStesseRisposteDelCSenzaIlFileDiDefault;
begin
  CompareWithGolden(TPath.Combine(BotDataFolder, 'alt2'), 'botscenario_alt.txt', 'botscenario_alt2.golden.txt', 1000);
end;

procedure TTestBotAiParity.DovrebbeEseguireTuttiIComandiDelloScenario;
var
  LScenario: TStringList;
  LRunner: TBotAiScenarioRunner;
  LLine: string;
begin
  LScenario := TStringList.Create;
  LRunner := TBotAiScenarioRunner.Create(TFolderBotFiles.Create(BotDataFolder));
  try
    LScenario.LoadFromFile(TPath.Combine(BotDataFolder, 'botscenario.txt'), TEncoding.ANSI);
    LRunner.Run(LScenario);
    for LLine in LRunner.Output do
      Assert.IsFalse(LLine.StartsWith('UNKNOWN COMMAND'), LLine);
  finally
    LRunner.Free;
    LScenario.Free;
  end;
end;

end.
