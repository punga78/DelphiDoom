{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the definitions library - the terrain without a table  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Definitions.TerrainTables;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Definitions.Types;

type
  /// <summary>
  ///   TTerrainTables.KindForName is what r_data calls for every flat in place of the old
  ///   P_TerrainTypeForName of p_terrain.pas: it must give the answers of the old code
  ///   (terrain.*.golden.txt) and of TTerrainTable over the same list
  /// </summary>
  [TestFixture]
  [Category('definitions')]
  TTestTerrainTables = class(TObject)
  public
    [Test]
    [TestCase('doom', 'Doom')]
    [TestCase('heretic', 'Heretic')]
    [TestCase('hexen', 'Hexen')]
    [TestCase('strife', 'Strife')]
    procedure DovrebbeDareLoStessoTerrenoDelVecchioCodice(const AGame: string);
    [Test]
    procedure DovrebbeDareLaRispostaDellaTabellaPerOgniVoceDiOgniGioco;
    [TestCase('Minuscolo', 'Doom,nukage2,4')]
    [TestCase('Misto', 'Heretic,FltLava1,2')]
    [TestCase('Ghiaccio', 'Hexen,f_033,5')]
    [TestCase('Sconosciuto', 'Strife,F_WATR04,0')]
    [TestCase('Vuoto', 'Doom,,0')]
    [TestCase('Parziale', 'Doom,LAVA,0')]
    [TestCase('NomeDiUnAltroGioco', 'Heretic,NUKAGE1,0')]
    procedure DovrebbeTrovareIlTerrenoDiUnNome(const AGame, AName: string; AExpected: Integer);
  end;

implementation

uses
  DelphiDoom.Definitions.Intf, DelphiDoom.Definitions.Factory,
  DelphiDoom.Definitions.TerrainTables, DelphiDoom.Tests.Definitions.Corpus;

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

{ TTestTerrainTables }

procedure TTestTerrainTables.DovrebbeDareLoStessoTerrenoDelVecchioCodice(const AGame: string);
var
  LNames: TStringList;
  LGolden: TStringList;
  LActual: TStringList;
  LIndex: Integer;
begin
  LNames := TDefinitionsCorpus.LoadLines(TDefinitionsCorpus.DataPath('terrain.names.txt'));
  LGolden := TDefinitionsCorpus.LoadLines(TDefinitionsCorpus.DataPath(
    'terrain.' + LowerCase(AGame) + '.golden.txt'));
  LActual := TStringList.Create;
  try
    for LIndex := 0 to LNames.Count - 1 do
      LActual.Add(Format('%s'#9'%d', [LNames[LIndex], TDefinitionsCorpus.OldTerrainNumber(
        GameOf(AGame), TTerrainTables.KindForName(GameOf(AGame), LNames[LIndex]))]));
    Assert.IsTrue(LGolden.Count > 50, 'il file golden ha i nomi');
    Assert.AreEqual(LGolden.Text, LActual.Text);
  finally
    LActual.Free;
    LGolden.Free;
    LNames.Free;
  end;
end;

procedure TTestTerrainTables.DovrebbeDareLaRispostaDellaTabellaPerOgniVoceDiOgniGioco;
var
  LGame: TDefGame;
  LTable: IDefTerrainTable;
  LIndex: Integer;
  LName: string;
begin
  for LGame := Low(TDefGame) to High(TDefGame) do
  begin
    LTable := TDefinitionsFactory.CreateTerrainTable(LGame);
    for LIndex := 0 to LTable.Count - 1 do
    begin
      LName := LTable.Entry(LIndex).Name;
      Assert.IsTrue(LTable.KindForName(LName) = TTerrainTables.KindForName(LGame, LName), LName);
      Assert.IsTrue(LTable.KindForName(LowerCase(LName)) =
        TTerrainTables.KindForName(LGame, LowerCase(LName)), LName);
      Assert.IsTrue(TTerrainTables.KindForName(LGame, LName) <> TDefTerrainKind.Solid, LName);
    end;
  end;
end;

procedure TTestTerrainTables.DovrebbeTrovareIlTerrenoDiUnNome(const AGame, AName: string;
  AExpected: Integer);
begin
  Assert.AreEqual(AExpected, Integer(Ord(TTerrainTables.KindForName(GameOf(AGame), AName))));
end;

end.
