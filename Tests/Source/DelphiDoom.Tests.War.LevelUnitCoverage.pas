{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the unit types the levels use        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.LevelUnitCoverage;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.War.Intf, DelphiDoom.War.Level.Intf;

type
  /// <summary>
  ///   Which unit types of the real levels the game tables cannot make (issue 253: human mission 4 stops on the
  ///   assert of wu_getUnitStats in the C). Needs DATA.WAR: ignored when it is missing.
  /// </summary>
  [TestFixture]
  [Category('war')]
  TTestWarLevelUnitCoverage = class(TObject)
  strict private
    FLoader: IWarLevelLoader;
    procedure OpenData;
    function MissingTypes(AIndex: Integer): string;
  public
    [Test]
    procedure DovrebbeTrovareSoloLeUnitaFeriteNelLivelloDelleMissioneQuattroDegliUmani;
  end;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.War.Factory, DelphiDoom.War.Level.Factory, DelphiDoom.War.Level.Types,
  DelphiDoom.War.Model.Intf, DelphiDoom.War.Model.Database, DelphiDoom.War.Model.UnitClassifier,
  DelphiDoom.War.Model.Stats.Types, DelphiDoom.Tests.War.RealData;

{ TTestWarLevelUnitCoverage }

procedure TTestWarLevelUnitCoverage.OpenData;
var
  LCatalog: IWarCatalog;
  LArchive: IWarArchive;
begin
  LCatalog := TWarFactory.CreateCatalog;
  LArchive := TWarFactory.OpenFile(TWarRealData.RequireDataWar, LCatalog);
  FLoader := TWarLevelFactory.CreateLevelLoader(LArchive, LCatalog);
end;

// the types of the starting units of a level that the model cannot create (no size, or a dude without statistics)
function TTestWarLevelUnitCoverage.MissingTypes(AIndex: Integer): string;
var
  LDatabase: IWarDatabase;
  LUnit: TWarLevelUnit;
  LStats: TWarUnitStatsFull;
  LSizeX: Integer;
  LSizeY: Integer;
  LLevel: IWarLevel;
begin
  Result := '';
  LDatabase := TWarDatabase.Create;
  LLevel := FLoader.Load(AIndex);
  for LUnit in LLevel.Info.StartEntities do
  begin
    if not LDatabase.TryGetUnitSize(LUnit.UnitType, LSizeX, LSizeY) then
      Result := Result + Format('[%d senza misure]', [LUnit.UnitType])
    else if TWarUnitClassifier.IsDude(LUnit.UnitType) and not LDatabase.TryGetUnitStats(LUnit.UnitType, LStats) then
      Result := Result + Format('[%d senza statistiche]', [LUnit.UnitType]);
  end;
end;

procedure TTestWarLevelUnitCoverage.DovrebbeTrovareSoloLeUnitaFeriteNelLivelloDelleMissioneQuattroDegliUmani;
var
  LPosition: Integer;
  LIndex: Integer;
  LMissing: string;
  LWithMissing: string;
begin
  OpenData;
  LWithMissing := '';
  for LPosition := 0 to FLoader.LevelCount - 1 do
  begin
    LIndex := FLoader.GetLevelIndex(LPosition);
    LMissing := MissingTypes(LIndex);
    if LMissing <> '' then
      LWithMissing := LWithMissing + Format('%d:%s ', [LIndex, LMissing]);
  end;
  // WAR_UNIT_WOUNDED is 16: the tables of the remake have no statistics for it (the original is not available)
  // five of them in the level 123; no other level has a unit type the model cannot create
  Assert.AreEqual('123:[16 senza statistiche][16 senza statistiche]' +
    '[16 senza statistiche][16 senza statistiche][16 senza statistiche] ', LWithMissing);
end;

end.
