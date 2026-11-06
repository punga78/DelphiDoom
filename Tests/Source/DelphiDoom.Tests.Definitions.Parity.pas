{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the definitions library - parity with the old code     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Definitions.Parity;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework;

type
  /// <summary>
  ///   The *.golden.txt files of Tests\Data\Definitions were written by the old code
  ///   (P_InitFTAnims, P_InitSwitchList, P_TerrainTypeForName) on the texts of the *.cases.txt
  ///   and terrain.names.txt files: the library has to write the same dump
  /// </summary>
  [TestFixture]
  [Category('definitions')]
  TTestDefinitionsParity = class(TObject)
  private
    procedure CheckSameDump(AActual: TStringList; const AGoldenFile: string; AMinimumCases: Integer);
  public
    [Test]
    procedure TestAnimDefsDaLoStessoEsitoDelVecchioCodice;
    [Test]
    [TestCase('doom', 'Doom')]
    [TestCase('strife', 'Strife')]
    procedure TestInterruttoriDaLoStessoEsitoDelVecchioCodice(const AGame: string);
    [Test]
    [TestCase('doom', 'Doom')]
    [TestCase('heretic', 'Heretic')]
    [TestCase('hexen', 'Hexen')]
    [TestCase('strife', 'Strife')]
    procedure TestTerrenoDaLoStessoEsitoDelVecchioCodice(const AGame: string);
    [Test]
    [TestCase('doom', 'Doom')]
    [TestCase('heretic', 'Heretic')]
    [TestCase('hexen', 'Hexen')]
    [TestCase('strife', 'Strife')]
    procedure TestLeTabelleDegliInterruttoriSonoQuelleDelSorgente(const AGame: string);
  end;

implementation

uses
  DelphiDoom.Definitions.Types, DelphiDoom.Tests.Definitions.Corpus;

function GameOf(const AName: string): TDefGame;
begin
  if AName = 'Doom' then
    Result := TDefGame.Doom
  else if AName = 'Heretic' then
    Result := TDefGame.Heretic
  else if AName = 'Hexen' then
    Result := TDefGame.Hexen
  else
    Result := TDefGame.Strife;
end;

{ TTestDefinitionsParity }

procedure TTestDefinitionsParity.CheckSameDump(AActual: TStringList; const AGoldenFile: string;
  AMinimumCases: Integer);
var
  LGolden: TStringList;
  LDetail: string;
  LCount: Integer;
  LCases: Integer;
  LLine: string;
begin
  LGolden := TDefinitionsCorpus.LoadLines(TDefinitionsCorpus.DataPath(AGoldenFile));
  try
    LCases := 0;
    for LLine in LGolden do
      if Copy(LLine, 1, 4) = '=== ' then
        Inc(LCases);
    Assert.IsTrue(LCases >= AMinimumCases, 'il file golden ha i casi');
    LCount := TDefinitionsCorpus.Compare(AActual, LGolden, LDetail);
    Assert.AreEqual(0, LCount, 'casi diversi: ' + LDetail);
  finally
    LGolden.Free;
    AActual.Free;
  end;
end;

procedure TTestDefinitionsParity.TestAnimDefsDaLoStessoEsitoDelVecchioCodice;
begin
  CheckSameDump(TDefinitionsCorpus.DumpAnimations(TDefinitionsCorpus.DataPath('animdefs.cases.txt')),
    'animdefs.golden.txt', 40);
end;

procedure TTestDefinitionsParity.TestInterruttoriDaLoStessoEsitoDelVecchioCodice(const AGame: string);
begin
  CheckSameDump(TDefinitionsCorpus.DumpSwitches(TDefinitionsCorpus.DataPath('switches.cases.txt'),
    AGame = 'Strife'), 'switches.' + LowerCase(AGame) + '.golden.txt', 30);
end;

procedure TTestDefinitionsParity.TestTerrenoDaLoStessoEsitoDelVecchioCodice(const AGame: string);
var
  LActual: TStringList;
  LGolden: TStringList;
begin
  LActual := TDefinitionsCorpus.DumpTerrain(GameOf(AGame), TDefinitionsCorpus.DataPath('terrain.names.txt'));
  LGolden := TDefinitionsCorpus.LoadLines(TDefinitionsCorpus.DataPath('terrain.' + LowerCase(AGame) + '.golden.txt'));
  try
    Assert.IsTrue(LGolden.Count > 50, 'il file golden ha i nomi');
    Assert.AreEqual(LGolden.Text, LActual.Text);
  finally
    LActual.Free;
    LGolden.Free;
  end;
end;

procedure TTestDefinitionsParity.TestLeTabelleDegliInterruttoriSonoQuelleDelSorgente(const AGame: string);
var
  LActual: TStringList;
  LGolden: TStringList;
begin
  LActual := TDefinitionsCorpus.DumpSwitchTable(GameOf(AGame));
  LGolden := TDefinitionsCorpus.LoadLines(TDefinitionsCorpus.DataPath('switchtables.' + LowerCase(AGame) + '.golden.txt'));
  try
    Assert.IsTrue(LGolden.Count >= 2, 'il file golden ha le coppie');
    Assert.AreEqual(LGolden.Text, LActual.Text);
  finally
    LActual.Free;
    LGolden.Free;
  end;
end;

end.
