{******************************************************************************}
{                                                                              }
{  DelphiDoom: parity of the bot chat with Quake III Arena (DUnitX)            }
{                                                                              }
{  Tests\Data\BotAi\chat.golden.txt is what the REAL be_ai_chat.c, l_script.c  }
{  and l_precomp.c write for Tests\Data\BotAi\scenario.txt (Tools\Verifica\124)}
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.BotAi.Parity;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('BotAi')]
  TTestBotChatParity = class
  public
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelCSuTuttoLoScenario;
    [Test]
    procedure DovrebbeEseguireTuttiIComandiDelloScenario;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.IOUtils, DelphiDoom.Tests.BotAi.Support,
  DelphiDoom.Tests.BotAi.ScenarioRunner;

{ TTestBotChatParity }

procedure TTestBotChatParity.DovrebbeDareLeStesseRisposteDelCSuTuttoLoScenario;
var
  LScenario: TStringList;
  LGolden: TStringList;
  LRunner: TBotScenarioRunner;
  LIndex: Integer;
  LCount: Integer;
begin
  LScenario := TStringList.Create;
  LGolden := TStringList.Create;
  LRunner := TBotScenarioRunner.Create(TFolderBotFiles.Create(BotDataFolder));
  try
    LScenario.LoadFromFile(TPath.Combine(BotDataFolder, 'scenario.txt'), TEncoding.ANSI);
    LGolden.LoadFromFile(TPath.Combine(BotDataFolder, 'chat.golden.txt'), TEncoding.ANSI);
    LRunner.Run(LScenario);
    Assert.IsTrue(LGolden.Count > 700, 'golden vuoto');
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

procedure TTestBotChatParity.DovrebbeEseguireTuttiIComandiDelloScenario;
var
  LScenario: TStringList;
  LRunner: TBotScenarioRunner;
  LLine: string;
begin
  LScenario := TStringList.Create;
  LRunner := TBotScenarioRunner.Create(TFolderBotFiles.Create(BotDataFolder));
  try
    LScenario.LoadFromFile(TPath.Combine(BotDataFolder, 'scenario.txt'), TEncoding.ANSI);
    LRunner.Run(LScenario);
    for LLine in LRunner.Output do
      Assert.IsFalse(LLine.StartsWith('UNKNOWN COMMAND'), LLine);
  finally
    LRunner.Free;
    LScenario.Free;
  end;
end;

end.
