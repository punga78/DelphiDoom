{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the fog of war and its update        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.MapFog;

interface

uses
  System.SysUtils, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.War.Types, DelphiDoom.War.Map.Types,
  DelphiDoom.War.Map.Intf, DelphiDoom.War.Map.Fog;

type
  [TestFixture]
  [Category('war')]
  TTestWarFogOfWar = class(TObject)
  private
    FFog: TWarFogOfWar;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbePartireConTutteLeCaselleSconosciute;
    [Test]
    procedure DovrebbeEscludereGliAngoliDelRettangolo;
    [Test]
    procedure DovrebbeSpostareLaPartenzaDelRettangoloAlBordoSenzaAccorciarlo;
    [Test]
    procedure DovrebbeTagliareLaFineDelRettangoloAlBordo;
    [Test]
    procedure DovrebbeDireSeUnaCasellaEInUnoStato;
    [Test]
    procedure DovrebbeDireSeAlcuneOTutteLeCaselleSonoInUnoStato;
    [Test]
    procedure DovrebbeDareVeroPerTutteLeCaselleDiUnRettangoloVuoto;
    [Test]
    procedure DovrebbeVedereTuttoSenzaLaNebbia;
    [Test]
    procedure DovrebbeDireSeUnaPosizioneInPixelEVisibile;
    [Test]
    procedure DovrebbeDireSeUnaUnitaEInVistaInParteOPerIntero;
    [Test]
    procedure DovrebbeMettereInNebbiaLeCaselleVisibiliEPulireIPezzi;
    [Test]
    procedure DovrebbeDeciderePezziEConfiniDallEstremoDellaVista;
    [Test]
    procedure NonDovrebbeDeciderePezziSeLaNebbiaEDisattivata;
    [Test]
    procedure DovrebbeSollevareEccezioneSeUnaCasellaEFuoriDallaMappa;
  end;

  [TestFixture]
  [Category('war')]
  TTestWarFogUpdater = class(TObject)
  private
    FFog: TWarFogOfWar;
    FUnits: TList<TWarMapUnit>;
    FCatalog: IWarUnitCatalog;
    procedure Update;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeIlluminareLeCaselleAttornoAUnaUnitaAmica;
    [Test]
    procedure DovrebbeVedereGliEdificiAmiciPerSempre;
    [Test]
    procedure DovrebbeMettereInNebbiaCioCheNonSiVedePiu;
    [Test]
    procedure DovrebbeVedereUnEdificioNemicoSoloSeInVista;
    [Test]
    procedure NonDovrebbeVedereUnaUnitaNemicaCheNonEUnEdificio;
    [Test]
    procedure DovrebbeSollevareEccezioneSeLaUnitaNonHaVista;
  end;

implementation

uses
  DelphiDoom.War.Level.Types, DelphiDoom.War.Map.FogUpdater, DelphiDoom.War.Map.Factory;

function SomeUnit(AId: Word; AType, AX, AY, ASize: Integer; APlayer: Byte): TWarMapUnit;
begin
  Result := Default(TWarMapUnit);
  Result.Id := AId;
  Result.UnitType := AType;
  Result.TileX := AX;
  Result.TileY := AY;
  Result.SizeX := ASize;
  Result.SizeY := ASize;
  Result.Player := APlayer;
end;

{ TTestWarFogOfWar }

procedure TTestWarFogOfWar.Setup;
begin
  FFog := TWarFogOfWar.Create;
end;

procedure TTestWarFogOfWar.TearDown;
begin
  FFog.Free;
end;

procedure TTestWarFogOfWar.DovrebbePartireConTutteLeCaselleSconosciute;
begin
  Assert.IsTrue(FFog.Enabled);
  Assert.AreEqual<Integer>(WAR_MAP_TILE_COUNT, FFog.CountState(wtsUnknown));
  Assert.AreEqual<Integer>(0, FFog.CountState(wtsVisible));
  Assert.IsTrue(FFog.GetTile(3, 4).Boundary = wfbNone);
  Assert.AreEqual<Integer>(0, Integer(FFog.GetTile(3, 4).PieceType));
end;

procedure TTestWarFogOfWar.DovrebbeEscludereGliAngoliDelRettangolo;
begin
  FFog.SetState(10, 10, 4, 3, wtsVisible);
  Assert.AreEqual<Integer>(12 - 4, FFog.CountState(wtsVisible));
  Assert.IsTrue(FFog.IsTileUnknown(10, 10));
  Assert.IsTrue(FFog.IsTileUnknown(13, 12));
  Assert.IsTrue(FFog.IsTileVisible(11, 10));
  Assert.IsTrue(FFog.IsTileVisible(10, 11));
end;

procedure TTestWarFogOfWar.DovrebbeSpostareLaPartenzaDelRettangoloAlBordoSenzaAccorciarlo;
begin
  // the start goes to 0 and the width stays 7, so the area reaches the tile 6 (as in the original)
  FFog.SetState(-3, 20, 7, 3, wtsVisible);
  Assert.IsTrue(FFog.IsTileVisible(5, 21));
  Assert.IsFalse(FFog.IsTileVisible(0, 20), 'angolo');
  Assert.IsTrue(FFog.IsTileVisible(6, 21));
  Assert.IsFalse(FFog.IsTileVisible(7, 21));
end;

procedure TTestWarFogOfWar.DovrebbeTagliareLaFineDelRettangoloAlBordo;
begin
  FFog.SetState(60, 60, 10, 10, wtsFog);
  Assert.IsTrue(FFog.IsTileFog(62, 62));
  Assert.IsTrue(FFog.IsTileFog(63, 61));
  Assert.IsTrue(FFog.IsTileUnknown(63, 63));
end;

procedure TTestWarFogOfWar.DovrebbeDireSeUnaCasellaEInUnoStato;
begin
  FFog.SetState(5, 5, 3, 3, wtsFog);
  Assert.IsTrue(FFog.IsTileInState(6, 6, wtsFog));
  Assert.IsFalse(FFog.IsTileInState(6, 6, wtsVisible));
  Assert.IsTrue(FFog.IsTileFog(6, 6));
  Assert.AreEqual<Integer>(2, Ord(FFog.GetTile(6, 6).State));
end;

procedure TTestWarFogOfWar.DovrebbeDireSeAlcuneOTutteLeCaselleSonoInUnoStato;
begin
  FFog.SetState(5, 5, 5, 5, wtsVisible);
  Assert.IsTrue(FFog.IsAnyTileInState(0, 0, 8, 8, wtsVisible));
  Assert.IsFalse(FFog.IsAnyTileInState(0, 0, 4, 4, wtsVisible));
  Assert.IsTrue(FFog.AreAllTilesInState(6, 6, 2, 2, wtsVisible));
  Assert.IsFalse(FFog.AreAllTilesInState(4, 4, 3, 3, wtsVisible));
end;

procedure TTestWarFogOfWar.DovrebbeDareVeroPerTutteLeCaselleDiUnRettangoloVuoto;
begin
  Assert.IsTrue(FFog.AreAllTilesInState(70, 70, 2, 2, wtsVisible));
  Assert.IsFalse(FFog.IsAnyTileInState(70, 70, 2, 2, wtsVisible));
end;

procedure TTestWarFogOfWar.DovrebbeVedereTuttoSenzaLaNebbia;
begin
  FFog.Enabled := False;
  Assert.IsTrue(FFog.IsTileVisible(10, 10));
  Assert.IsFalse(FFog.IsTileUnknown(10, 10));
  Assert.IsFalse(FFog.IsTileFog(10, 10));
  Assert.IsTrue(FFog.IsAnyTileInState(0, 0, 3, 3, wtsVisible));
  Assert.IsFalse(FFog.IsAnyTileInState(0, 0, 3, 3, wtsFog));
  Assert.IsTrue(FFog.AreAllTilesInState(0, 0, 3, 3, wtsVisible));
  Assert.IsFalse(FFog.AreAllTilesInState(0, 0, 3, 3, wtsUnknown));
  Assert.IsTrue(FFog.IsTileVisible(99, 99));
end;

procedure TTestWarFogOfWar.DovrebbeDireSeUnaPosizioneInPixelEVisibile;
begin
  FFog.SetState(2, 2, 5, 5, wtsVisible);
  Assert.IsTrue(FFog.IsPositionVisible(4 * 16 + 3, 4 * 16));
  Assert.IsFalse(FFog.IsPositionVisible(20 * 16, 4 * 16));
  Assert.IsFalse(FFog.IsPositionVisible(-1, 16));
  Assert.IsFalse(FFog.IsPositionVisible(16, 64 * 16));
end;

procedure TTestWarFogOfWar.DovrebbeDireSeUnaUnitaEInVistaInParteOPerIntero;
var
  LUnit: TWarMapUnit;
begin
  FFog.SetState(10, 10, 6, 6, wtsVisible);
  LUnit := SomeUnit(1, WAR_UNIT_GOLDMINE, 14, 14, 3, 0);
  Assert.IsTrue(FFog.IsUnitPartiallyIn(LUnit, wtsVisible));
  Assert.IsFalse(FFog.IsUnitEntirelyIn(LUnit, wtsVisible));
  LUnit := SomeUnit(2, WAR_UNIT_FOOTMAN, 12, 12, 1, 0);
  Assert.IsTrue(FFog.IsUnitEntirelyIn(LUnit, wtsVisible));
end;

procedure TTestWarFogOfWar.DovrebbeMettereInNebbiaLeCaselleVisibiliEPulireIPezzi;
begin
  FFog.SetState(10, 10, 6, 6, wtsVisible);
  FFog.DetermineTypes;
  FFog.BeginUpdate;
  Assert.AreEqual<Integer>(0, FFog.CountState(wtsVisible));
  Assert.AreEqual<Integer>(32, FFog.CountState(wtsFog));
  Assert.AreEqual<Integer>(0, Integer(FFog.GetTile(12, 12).PieceType));
  Assert.IsTrue(FFog.GetTile(12, 12).Boundary = wfbNone);
end;

procedure TTestWarFogOfWar.DovrebbeDeciderePezziEConfiniDallEstremoDellaVista;
begin
  FFog.SetState(10, 10, 6, 6, wtsVisible);
  FFog.DetermineTypes;
  // inside the area every neighbor is in sight and the tile has no piece of fog: its boundary stays none
  Assert.IsTrue(FFog.GetTile(12, 12).Boundary = wfbNone);
  // the edge of the sight meets what is unknown
  Assert.IsTrue(FFog.GetTile(10, 12).Boundary = wfbUnknown);
  // a tile in fog next to the sight looks at the unknown too
  FFog.SetState(30, 30, 3, 3, wtsFog);
  FFog.DetermineTypes;
  Assert.IsTrue(FFog.GetTile(31, 30).Boundary = wfbUnknown);
  // a visible tile that touches fog has the fog as its boundary
  FFog.SetState(32, 30, 3, 3, wtsVisible);
  FFog.SetState(35, 30, 3, 3, wtsFog);
  FFog.DetermineTypes;
  Assert.IsTrue(FFog.GetTile(34, 31).Boundary = wfbFog);
end;

procedure TTestWarFogOfWar.NonDovrebbeDeciderePezziSeLaNebbiaEDisattivata;
begin
  FFog.SetState(10, 10, 6, 6, wtsVisible);
  FFog.Enabled := False;
  FFog.DetermineTypes;
  Assert.IsTrue(FFog.GetTile(10, 12).Boundary = wfbNone);
end;

procedure TTestWarFogOfWar.DovrebbeSollevareEccezioneSeUnaCasellaEFuoriDallaMappa;
begin
  Assert.WillRaise(
    procedure
    begin
      FFog.GetTile(64, 0);
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      FFog.IsTileFog(0, -1);
    end, EWarException);
end;

{ TTestWarFogUpdater }

procedure TTestWarFogUpdater.Setup;
begin
  FFog := TWarFogOfWar.Create;
  FUnits := TList<TWarMapUnit>.Create;
  FCatalog := TWarMapFactory.CreateUnitCatalog;
end;

procedure TTestWarFogUpdater.TearDown;
begin
  FUnits.Free;
  FFog.Free;
end;

procedure TTestWarFogUpdater.Update;
var
  LUpdater: TWarFogUpdater;
begin
  LUpdater := TWarFogUpdater.Create(FCatalog, 0);
  try
    LUpdater.Update(FFog, FUnits);
  finally
    LUpdater.Free;
  end;
end;

procedure TTestWarFogUpdater.DovrebbeIlluminareLeCaselleAttornoAUnaUnitaAmica;
begin
  // the footman sees 2 tiles around its own: a square 5 x 5 without its corners
  FUnits.Add(SomeUnit(1, WAR_UNIT_FOOTMAN, 20, 20, 1, 0));
  Update;
  Assert.AreEqual<Integer>(25 - 4, FFog.CountState(wtsVisible));
  Assert.IsTrue(FFog.IsTileVisible(20, 20));
  Assert.IsTrue(FFog.IsTileVisible(18, 20));
  Assert.IsFalse(FFog.IsTileVisible(18, 18));
end;

procedure TTestWarFogUpdater.DovrebbeVedereGliEdificiAmiciPerSempre;
begin
  FUnits.Add(SomeUnit(1, WAR_UNIT_TOWNHALL_HUMANS, 20, 20, 3, 0));
  Update;
  Assert.IsTrue(FUnits[0].HasBeenSeen);
end;

procedure TTestWarFogUpdater.DovrebbeMettereInNebbiaCioCheNonSiVedePiu;
begin
  FUnits.Add(SomeUnit(1, WAR_UNIT_FOOTMAN, 20, 20, 1, 0));
  Update;
  FUnits[0] := SomeUnit(1, WAR_UNIT_FOOTMAN, 40, 40, 1, 0);
  Update;
  Assert.IsTrue(FFog.IsTileFog(20, 20));
  Assert.IsTrue(FFog.IsTileVisible(40, 40));
end;

procedure TTestWarFogUpdater.DovrebbeVedereUnEdificioNemicoSoloSeInVista;
begin
  FUnits.Add(SomeUnit(1, WAR_UNIT_FOOTMAN, 20, 20, 1, 0));
  FUnits.Add(SomeUnit(2, WAR_UNIT_TOWNHALL_ORCS, 21, 21, 3, 1));
  FUnits.Add(SomeUnit(3, WAR_UNIT_BARRACKS_ORCS, 50, 50, 3, 1));
  Update;
  Assert.IsTrue(FUnits[1].HasBeenSeen);
  Assert.IsFalse(FUnits[2].HasBeenSeen);
end;

procedure TTestWarFogUpdater.NonDovrebbeVedereUnaUnitaNemicaCheNonEUnEdificio;
begin
  FUnits.Add(SomeUnit(1, WAR_UNIT_FOOTMAN, 20, 20, 1, 0));
  FUnits.Add(SomeUnit(2, WAR_UNIT_GRUNT, 21, 20, 1, 1));
  Update;
  Assert.IsFalse(FUnits[1].HasBeenSeen);
end;

procedure TTestWarFogUpdater.DovrebbeSollevareEccezioneSeLaUnitaNonHaVista;
begin
  FUnits.Add(SomeUnit(1, WAR_UNIT_WOUNDED, 20, 20, 1, 0));
  Assert.WillRaise(
    procedure
    begin
      Update;
    end, EWarException);
end;

end.
