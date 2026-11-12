{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the greed library - parity of the intro, of the         }
{  mission briefings and of the endings with the original code                  }
{                                                                              }
{  The golden files intro*.golden.txt of Tests\Data\Greed are what the          }
{  ORIGINAL dointro of intro.pas and MissionBriefing and EndGame1..3 of         }
{  utils.pas gave (harness Tools\Verifica\175-menu, IntroParity): screen and    }
{  palette at every tic, calls to the game and what the scenario leaves.        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.IntroParity;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Greed.Intf;

type
  [TestFixture]
  [Category('greed')]
  [Category('golden')]
  TTestGreedIntroParity = class(TObject)
  strict private
    procedure CheckGolden(const AArchive: IGreedArchive; const AGoldenName: string);
  public
    [Test]
    procedure DovrebbeDareGliStessiSchermiDelloOriginaleSuiDatiSintetici;
    [Test]
    procedure DovrebbeDareGliStessiSchermiDelloOriginaleNelGiocoCompleto;
    [Test]
    procedure DovrebbeDareGliStessiSchermiDelloOriginaleNellaDemo20;
    [Test]
    procedure DovrebbeCoprireITreTipiDiScenarioEIlMenuDellIntro;
  end;

implementation

uses
  DelphiDoom.Tests.Shared.Skip, DelphiDoom.Tests.Greed.RealData, DelphiDoom.Tests.Greed.IntroScenarios;

{ TTestGreedIntroParity }

procedure TTestGreedIntroParity.CheckGolden(const AArchive: IGreedArchive; const AGoldenName: string);
var
  LGolden, LLines: TStringList;
  LIndex, LDifferent: Integer;
  LFirst: string;
begin
  LGolden := TStringList.Create;
  try
    LGolden.LoadFromFile(TGreedRealData.GoldenPath(AGoldenName));
    LLines := IntroLibraryLines(AArchive);
    try
      Assert.AreEqual(INTRO_SCENARIOS, LLines.Count);
      Assert.AreEqual(LGolden.Count, LLines.Count, 'the golden file has other scenarios');
      LDifferent := 0;
      LFirst := '';
      for LIndex := 0 to LLines.Count - 1 do
        if LLines[LIndex] <> LGolden[LIndex] then
        begin
          if LDifferent = 0 then
            LFirst := LGolden[LIndex] + ' / ' + LLines[LIndex];
          Inc(LDifferent);
        end;
      Assert.AreEqual(0, LDifferent, 'scenarios that differ from the original; the first (original / library): ' +
        LFirst);
    finally
      LLines.Free;
    end;
  finally
    LGolden.Free;
  end;
end;

procedure TTestGreedIntroParity.DovrebbeDareGliStessiSchermiDelloOriginaleSuiDatiSintetici;
begin
  CheckGolden(nil, 'intro.golden.txt');
end;

procedure TTestGreedIntroParity.DovrebbeDareGliStessiSchermiDelloOriginaleNelGiocoCompleto;
begin
  if TGreedRealData.FullFolder = '' then
    TTestSkip.Ignore('i dati del gioco completo (GREED.BLO) non ci sono');
  CheckGolden(TGreedRealData.OpenArchive(TGreedRealData.FullFolder), 'intro.full.golden.txt');
end;

procedure TTestGreedIntroParity.DovrebbeDareGliStessiSchermiDelloOriginaleNellaDemo20;
begin
  if TGreedRealData.Demo20Folder = '' then
    TTestSkip.Ignore('i dati della demo 2.0 (GREED.BLO) non ci sono');
  CheckGolden(TGreedRealData.OpenArchive(TGreedRealData.Demo20Folder), 'intro.demo20.golden.txt');
end;

procedure TTestGreedIntroParity.DovrebbeCoprireITreTipiDiScenarioEIlMenuDellIntro;
var
  LKinds: array[TIntroKind] of Integer;
  LIndex, LQuits: Integer;
  LRunner: TIntroLibraryRunner;
  LScenario: TIntroScenario;
begin
  // the parity is worth what the scenarios reach: the three pieces, and the menu of the intro left with the quit
  LKinds[ikIntro] := 0;
  LKinds[ikBriefing] := 0;
  LKinds[ikEndGame] := 0;
  LQuits := 0;
  LRunner := TIntroLibraryRunner.Create(nil);
  try
    for LIndex := 0 to INTRO_SCENARIOS - 1 do
    begin
      LScenario := TIntroScenarios.Scenario(LIndex);
      Inc(LKinds[LScenario.Kind]);
      LRunner.Run(LScenario);
      if LRunner.Host.QuitAsked then
        Inc(LQuits);
    end;
  finally
    LRunner.Free;
  end;
  Assert.IsTrue(LKinds[ikIntro] >= 20, 'intro');
  Assert.IsTrue(LKinds[ikBriefing] >= 10, 'briefing');
  Assert.IsTrue(LKinds[ikEndGame] >= 6, 'endgame');
  Assert.IsTrue(LQuits >= 2, 'the quit of the menu of the intro');
end;

end.
