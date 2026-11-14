{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - what the units of the player see     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.ModelFogRevealer;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.War.Map.Fog, DelphiDoom.War.Model.Types,
  DelphiDoom.Tests.War.ModelRig;

type
  /// <summary>updateFoW and determineFoWTypes over the units of the model (TWarFogRevealer)</summary>
  [TestFixture]
  [Category('war')]
  TTestWarFogRevealer = class(TObject)
  private
    FRig: TModelRig;
    FFog: TWarFogOfWar;
    procedure Attack(AAttackerSlot, ATargetSlot: Integer);
    function Pixel(ATileX, ATileY: Integer): TWarVec2;
    function TileVec(ATileX, ATileY: Integer): TWarVec2;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeIlluminareLeCaselleDiUnaUnitaEIlSuoRaggioDiVistaSenzaGliAngoli;
    [Test]
    procedure DovrebbeLasciareInNebbiaCioCheLUnitaHaVistoQuandoSiAllontana;
    [Test]
    procedure DovrebbeLasciareSconosciutoCioCheNessunoHaVisto;
    [Test]
    procedure DovrebbeVedereUnEdificioDelGiocatoreSenzaCheNessunoLoGuardi;
    [Test]
    procedure DovrebbeTogliereDallaSelezioneUnNemicoFuoriVista;
    [Test]
    procedure DovrebbeLasciareNellaSelezioneUnNemicoInVista;
    [Test]
    procedure DovrebbeSegnareVistoPerSempreUnEdificioNemicoCheEInVista;
    [Test]
    procedure DovrebbeNonSegnareVistoUnEdificioNemicoLontano;
    [Test]
    procedure DovrebbeIlluminareUnQuadratoDiSetteCaselleConUnIncantesimoDiVista;
    [Test]
    procedure DovrebbeRivelareIlBersaglioDiUnAttaccoSeELInPortataAncheSeFuoriDallaVista;
    [Test]
    procedure DovrebbeNonRivelareIlBersaglioSeEFuoriPortata;
    [Test]
    procedure DovrebbeRivelareChiAttaccaUnaUnitaDelGiocatore;
    [Test]
    procedure DovrebbeNonRivelareLaCasellaDiUnPezzoDiMuroBersaglioDifettoDelC;
    [Test]
    procedure DovrebbeNonMostrareNienteSeLaNebbiaEDisattivata;
    [Test]
    procedure DovrebbeLeggereLaVistaUnaVoltaPerTipoDiUnita;
    [Test]
    procedure DovrebbeDireAlModelloChePuoNonCostruireSuUnaCasellaSconosciuta;
  end;

implementation

uses
  DelphiDoom.War.Level.Types, DelphiDoom.War.Map.Types, DelphiDoom.War.Model.Context,
  DelphiDoom.War.Model.Factory, DelphiDoom.War.Model.State.Types, DelphiDoom.War.Model.StateMachine,
  DelphiDoom.War.Model.Spells, DelphiDoom.War.Model.TerrainEntities;

{ TTestWarFogRevealer }

procedure TTestWarFogRevealer.Setup;
begin
  FRig := TModelRig.Create;
  FFog := TWarFogOfWar.Create;
  FFog.Enabled := True;
  TWarModelFactory.AttachFog(FRig.World, FFog);
end;

procedure TTestWarFogRevealer.TearDown;
begin
  FRig.Free;
  FFog.Free;
end;

function TTestWarFogRevealer.Pixel(ATileX, ATileY: Integer): TWarVec2;
begin
  Result.X := ATileX * 16 + 8;
  Result.Y := ATileY * 16 + 8;
end;

function TTestWarFogRevealer.TileVec(ATileX, ATileY: Integer): TWarVec2;
begin
  Result.X := ATileX;
  Result.Y := ATileY;
end;

procedure TTestWarFogRevealer.Attack(AAttackerSlot, ATargetSlot: Integer);
var
  LState: PWarStateAttack;
begin
  LState := FRig.World.Machine.CreateAttack(AAttackerSlot, FRig.Entity(ATargetSlot)^.Id,
    FRig.Entity(ATargetSlot)^.Position);
  FRig.World.Machine.ResetState(AAttackerSlot, PWarStateBase(LState), WAR_CAUSE_PLAYER_ORDER);
end;

procedure TTestWarFogRevealer.DovrebbeIlluminareLeCaselleDiUnaUnitaEIlSuoRaggioDiVistaSenzaGliAngoli;
begin
  // a footman sees 2 tiles: the square of 5 x 5 tiles without its four corners
  FRig.AddDude(WAR_UNIT_FOOTMAN, 30, 30);
  FRig.TickAll;
  Assert.IsTrue(FFog.IsTileVisible(30, 30));
  Assert.IsTrue(FFog.IsTileVisible(28, 30));
  Assert.IsTrue(FFog.IsTileVisible(32, 30));
  Assert.IsTrue(FFog.IsTileVisible(30, 28));
  Assert.IsTrue(FFog.IsTileVisible(32, 31));
  Assert.IsFalse(FFog.IsTileVisible(28, 28), 'angolo');
  Assert.IsFalse(FFog.IsTileVisible(32, 32), 'angolo');
  Assert.IsFalse(FFog.IsTileVisible(33, 30), 'oltre la vista');
  Assert.AreEqual(21, FFog.CountState(wtsVisible));
end;

procedure TTestWarFogRevealer.DovrebbeLasciareInNebbiaCioCheLUnitaHaVistoQuandoSiAllontana;
var
  LSlot: Integer;
begin
  LSlot := FRig.AddDude(WAR_UNIT_FOOTMAN, 30, 30);
  FRig.TickAll;
  FRig.Move(LSlot, [Pixel(30, 30), Pixel(45, 30)]);
  FRig.RunAll(20);
  Assert.IsTrue(FFog.IsTileFog(30, 30), 'dove era');
  Assert.IsFalse(FFog.IsTileUnknown(30, 30));
  Assert.IsTrue(FFog.IsTileVisible(45, 30), 'dove e''');
end;

procedure TTestWarFogRevealer.DovrebbeLasciareSconosciutoCioCheNessunoHaVisto;
begin
  FRig.AddDude(WAR_UNIT_FOOTMAN, 30, 30);
  FRig.TickAll;
  Assert.IsTrue(FFog.IsTileUnknown(5, 5));
  Assert.IsTrue(FFog.IsTileUnknown(60, 60));
end;

procedure TTestWarFogRevealer.DovrebbeVedereUnEdificioDelGiocatoreSenzaCheNessunoLoGuardi;
var
  LSlot: Integer;
begin
  LSlot := FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 20, 20);
  Assert.IsFalse(FRig.Entity(LSlot)^.UnitData.HasBeenSeen);
  FRig.TickAll;
  Assert.IsTrue(FRig.Entity(LSlot)^.UnitData.HasBeenSeen);
end;

procedure TTestWarFogRevealer.DovrebbeTogliereDallaSelezioneUnNemicoFuoriVista;
var
  LEnemy: Integer;
begin
  FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
  LEnemy := FRig.AddDude(WAR_UNIT_GRUNT, 50, 50, 1);
  FRig.World.Context.Selection.Add(FRig.Entity(LEnemy)^.Id);
  Assert.AreEqual(1, FRig.World.Context.Selection.Count);
  FRig.TickAll;
  Assert.AreEqual(0, FRig.World.Context.Selection.Count);
end;

procedure TTestWarFogRevealer.DovrebbeLasciareNellaSelezioneUnNemicoInVista;
var
  LEnemy: Integer;
begin
  FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
  LEnemy := FRig.AddDude(WAR_UNIT_GRUNT, 11, 10, 1);
  FRig.World.Context.Selection.Add(FRig.Entity(LEnemy)^.Id);
  FRig.TickAll;
  Assert.AreEqual(1, FRig.World.Context.Selection.Count);
end;

procedure TTestWarFogRevealer.DovrebbeSegnareVistoPerSempreUnEdificioNemicoCheEInVista;
var
  LBuilding: Integer;
begin
  FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
  LBuilding := FRig.AddBuilding(WAR_UNIT_FARM_ORCS, 11, 10, 1);
  FRig.TickAll;
  Assert.IsTrue(FRig.Entity(LBuilding)^.UnitData.HasBeenSeen);
end;

procedure TTestWarFogRevealer.DovrebbeNonSegnareVistoUnEdificioNemicoLontano;
var
  LBuilding: Integer;
begin
  FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
  LBuilding := FRig.AddBuilding(WAR_UNIT_FARM_ORCS, 40, 40, 1);
  FRig.TickAll;
  Assert.IsFalse(FRig.Entity(LBuilding)^.UnitData.HasBeenSeen);
end;

procedure TTestWarFogRevealer.DovrebbeIlluminareUnQuadratoDiSetteCaselleConUnIncantesimoDiVista;
begin
  TWarSpells.SpawnSight(FRig.World.Context, TileVec(40, 20), 10.0);
  FRig.TickAll;
  Assert.IsTrue(FFog.IsTileVisible(40, 20), 'centro');
  Assert.IsTrue(FFog.IsTileVisible(37, 20), 'ovest');
  Assert.IsTrue(FFog.IsTileVisible(43, 22), 'est');
  Assert.IsTrue(FFog.IsTileVisible(37, 21), 'ovest basso');
  // the four corners of the square of 7 x 7 are left out
  Assert.IsFalse(FFog.IsTileVisible(37, 17));
  Assert.IsFalse(FFog.IsTileVisible(43, 23 + 1));
  Assert.IsFalse(FFog.IsTileVisible(44, 20));
  Assert.AreEqual(45, FFog.CountState(wtsVisible));
end;

procedure TTestWarFogRevealer.DovrebbeRivelareIlBersaglioDiUnAttaccoSeELInPortataAncheSeFuoriDallaVista;
var
  LCatapult: Integer;
  LEnemy: Integer;
begin
  // a catapult sees 5 tiles and reaches 8: the target at 7 is seen because it is attacked
  LCatapult := FRig.AddDude(WAR_UNIT_CATAPULT_HUMANS, 20, 30);
  LEnemy := FRig.AddDude(WAR_UNIT_GRUNT, 27, 30, 1);
  Assert.IsFalse(FFog.IsTileVisible(27, 30));
  Attack(LCatapult, LEnemy);
  FRig.TickAll;
  Assert.IsTrue(FFog.IsTileVisible(27, 30));
end;

procedure TTestWarFogRevealer.DovrebbeNonRivelareIlBersaglioSeEFuoriPortata;
var
  LCatapult: Integer;
  LEnemy: Integer;
begin
  LCatapult := FRig.AddDude(WAR_UNIT_CATAPULT_HUMANS, 20, 30);
  LEnemy := FRig.AddDude(WAR_UNIT_GRUNT, 40, 30, 1);
  Attack(LCatapult, LEnemy);
  FRig.TickAll;
  Assert.IsFalse(FFog.IsTileVisible(40, 30));
end;

procedure TTestWarFogRevealer.DovrebbeRivelareChiAttaccaUnaUnitaDelGiocatore;
var
  LFootman: Integer;
  LArcher: Integer;
begin
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 30, 30);
  LArcher := FRig.AddDude(WAR_UNIT_ARCHER, 30, 37, 1);
  Assert.IsFalse(FFog.IsTileVisible(30, 37));
  Attack(LArcher, LFootman);
  FRig.TickAll(2);
  // the archer is at 7 tiles, the footman sees 2: whoever attacks is revealed with its own sight
  Assert.IsTrue(FFog.IsTileVisible(30, 37));
end;

procedure TTestWarFogRevealer.DovrebbeNonRivelareLaCasellaDiUnPezzoDiMuroBersaglioDifettoDelC;
var
  LCatapult: Integer;
  LWall: Integer;
  LState: PWarStateAttack;
  LPiece: Integer;
begin
  // defect of the original kept: the piece of wall that is attacked is lit as a rectangle of one tile, and the corners of
  // a rectangle are left out, which are all of its tiles
  LCatapult := FRig.AddDude(WAR_UNIT_CATAPULT_HUMANS, 20, 30);
  LWall := TWarTerrainEntities.CreateWall(FRig.World.Context, FRig.World.Machine);
  LPiece := FRig.World.Context.Walls.Add(26, 30, 1);
  Assert.AreEqual(0, LPiece);
  FRig.World.Context.Walls[LPiece]^.Hp := WAR_WALL_MAX_HP;
  FRig.World.Context.Walls[LPiece]^.MaxHp := WAR_WALL_MAX_HP;
  LState := FRig.World.Machine.CreateAttack(LCatapult, FRig.Entity(LWall)^.Id, Pixel(26, 30));
  FRig.World.Machine.ResetState(LCatapult, PWarStateBase(LState), WAR_CAUSE_PLAYER_ORDER);
  FRig.TickAll;
  Assert.IsFalse(FFog.IsTileVisible(26, 30));
  Assert.IsTrue(FFog.IsTileUnknown(26, 30));
end;

procedure TTestWarFogRevealer.DovrebbeNonMostrareNienteSeLaNebbiaEDisattivata;
begin
  FFog.Enabled := False;
  FRig.AddDude(WAR_UNIT_FOOTMAN, 30, 30);
  FRig.TickAll;
  // everything is seen when the fog is off, so nothing is outside the sight and an enemy is never deselected
  Assert.IsTrue(FFog.IsTileVisible(5, 5));
  Assert.IsFalse(FFog.IsTileUnknown(5, 5));
end;

procedure TTestWarFogRevealer.DovrebbeLeggereLaVistaUnaVoltaPerTipoDiUnita;
var
  LFirst: Integer;
  LSecond: Integer;
begin
  LFirst := FRig.AddDude(WAR_UNIT_ARCHER, 10, 10);
  LSecond := FRig.AddDude(WAR_UNIT_ARCHER, 40, 40);
  FRig.TickAll;
  // two units of the same type: the same square (an archer sees 5 tiles)
  Assert.IsTrue(FFog.IsTileVisible(15, 10));
  Assert.IsTrue(FFog.IsTileVisible(45, 40));
  Assert.IsFalse(FFog.IsTileVisible(16, 10));
  Assert.IsFalse(FFog.IsTileVisible(46, 40));
  Assert.IsTrue((LFirst <> 0) and (LSecond <> 0));
end;

procedure TTestWarFogRevealer.DovrebbeDireAlModelloChePuoNonCostruireSuUnaCasellaSconosciuta;
begin
  Assert.AreSame(FFog, FRig.World.Context.Fog);
  Assert.IsTrue(FRig.World.Context.Fog.IsTileUnknown(3, 3));
  FRig.AddDude(WAR_UNIT_FOOTMAN, 3, 3);
  FRig.TickAll;
  Assert.IsFalse(FRig.World.Context.Fog.IsTileUnknown(3, 3));
end;

end.
