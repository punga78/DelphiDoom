{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the minimap and the visual map       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.MapMinimap;

interface

uses
  System.SysUtils, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.War.Types, DelphiDoom.War.Map.Types,
  DelphiDoom.War.Map.Fog, DelphiDoom.War.Map.Minimap;

type
  [TestFixture]
  [Category('war')]
  TTestWarMinimap = class(TObject)
  private
    FFog: TWarFogOfWar;
    FMinimap: TWarMinimap;
    FUnits: TList<TWarMapUnit>;
    function Pixel(const ABytes: TBytes; AX, AY: Integer): TWarMinimapColor;
    function MakeUnit(AType, AX, AY, ASize: Integer; APlayer: Byte): TWarMapUnit;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbePartireNera;
    [Test]
    procedure DovrebbeSollevareEccezioneSeLImmagineDelTilesetEBreve;
    [Test]
    procedure DovrebbeFareLaMediaDeiPixelDiUnaTegola;
    [Test]
    procedure DovrebbeSollevareEccezioneSeLaTegolaNonEnellImmagine;
    [Test]
    procedure DovrebbeFareIlTerrenoDiTutteLeTegole;
    [Test]
    procedure DovrebbeSollevareEccezioneSeLaMappaVisivaECorta;
    [Test]
    procedure DovrebbeAggiornareUnPixelDelTerrenoSoloSeLaTegolaESiVista;
    [Test]
    procedure DovrebbeColorareLeUnitaSecondoIlGiocatore;
    [Test]
    procedure DovrebbeCopiareIlTerrenoSoloDoveIlGiocatoreHaVisto;
    [Test]
    procedure DovrebbeMostrareTuttoSenzaLaNebbia;
    [Test]
    procedure DovrebbeDisegnareLeUnitaViste;
    [Test]
    procedure NonDovrebbeDisegnareLeUnitaNonViste;
    [Test]
    procedure DovrebbeDisegnareUnaUnitaGiaVistaAncheSeOraELontana;
    [Test]
    procedure NonDovrebbeDisegnareICadaveriELeUnitaFinite;
    [Test]
    procedure DovrebbeAndareACapoSeUnaUnitaSuperaLaFineDellaRiga;
    [Test]
    procedure DovrebbeSollevareEccezioneSeUnaUnitaSuperaLUltimaRiga;
  end;

  [TestFixture]
  [Category('war')]
  TTestWarMapTilePainter = class(TObject)
  private
    FFog: TWarFogOfWar;
    FMinimap: TWarMinimap;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeScrivereLaTegolaEAggiornareIlPixelDelTerreno;
    [Test]
    procedure DovrebbeDareLaTegolaDiUnaCella;
    [Test]
    procedure DovrebbeLasciareInvariataLaMappaOriginale;
    [Test]
    procedure DovrebbeSollevareEccezioneFuoriDallaMappaOLaTegolaNonEUnWord;
    [Test]
    procedure DovrebbeSollevareEccezioneSeLaMappaECorta;
  end;

implementation

uses
  DelphiDoom.War.Level.Types, DelphiDoom.War.Map.Intf, DelphiDoom.War.Map.TilePainter, DelphiDoom.Tests.War.MapSupport;

{ TTestWarMinimap }

procedure TTestWarMinimap.Setup;
begin
  FFog := TWarFogOfWar.Create;
  FMinimap := TWarMinimap.Create(TMapFixtures.Tileset);
  FUnits := TList<TWarMapUnit>.Create;
end;

procedure TTestWarMinimap.TearDown;
begin
  FUnits.Free;
  FMinimap.Free;
  FFog.Free;
end;

function TTestWarMinimap.Pixel(const ABytes: TBytes; AX, AY: Integer): TWarMinimapColor;
begin
  Result.R := ABytes[(AY * WAR_MINIMAP_SIZE + AX) * 4];
  Result.G := ABytes[(AY * WAR_MINIMAP_SIZE + AX) * 4 + 1];
  Result.B := ABytes[(AY * WAR_MINIMAP_SIZE + AX) * 4 + 2];
end;

function TTestWarMinimap.MakeUnit(AType, AX, AY, ASize: Integer; APlayer: Byte): TWarMapUnit;
begin
  Result := Default(TWarMapUnit);
  Result.UnitType := AType;
  Result.TileX := AX;
  Result.TileY := AY;
  Result.SizeX := ASize;
  Result.SizeY := ASize;
  Result.Player := APlayer;
end;

procedure TTestWarMinimap.DovrebbePartireNera;
begin
  Assert.AreEqual<Integer>(WAR_MINIMAP_BYTES, Length(FMinimap.Frame));
  Assert.AreEqual<Integer>(0, Integer(FMinimap.Frame[0]));
  Assert.AreEqual<Integer>(255, Integer(FMinimap.Frame[3]));
  Assert.AreEqual<Integer>(255, Integer(FMinimap.Terrain[WAR_MINIMAP_BYTES - 1]));
end;

procedure TTestWarMinimap.DovrebbeSollevareEccezioneSeLImmagineDelTilesetEBreve;
begin
  Assert.WillRaise(
    procedure
    begin
      TWarMinimap.Create(nil).Free;
    end, EWarException);
end;

procedure TTestWarMinimap.DovrebbeFareLaMediaDeiPixelDiUnaTegola;
var
  LColor: TWarMinimapColor;
begin
  // the tile 300 is the solid color (300 mod 256, 150, 7)
  LColor := FMinimap.TileAverage(300);
  Assert.AreEqual<Integer>(44, Integer(LColor.R));
  Assert.AreEqual<Integer>(150, Integer(LColor.G));
  Assert.AreEqual<Integer>(7, Integer(LColor.B));
end;

procedure TTestWarMinimap.DovrebbeSollevareEccezioneSeLaTegolaNonEnellImmagine;
begin
  Assert.WillRaise(
    procedure
    begin
      FMinimap.TileAverage(512);
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      FMinimap.TileAverage(-1);
    end, EWarException);
end;

procedure TTestWarMinimap.DovrebbeFareIlTerrenoDiTutteLeTegole;
var
  LVisual: TArray<Word>;
begin
  LVisual := TMapFixtures.FlatVisual(10);
  LVisual[65] := 20;
  FMinimap.BuildTerrain(LVisual);
  Assert.AreEqual<Integer>(10, Integer(Pixel(FMinimap.Terrain, 0, 0).R));
  Assert.AreEqual<Integer>(5, Integer(Pixel(FMinimap.Terrain, 0, 0).G));
  Assert.AreEqual<Integer>(20, Integer(Pixel(FMinimap.Terrain, 1, 1).R));
  Assert.AreEqual<Integer>(255, Integer(FMinimap.Terrain[3]));
end;

procedure TTestWarMinimap.DovrebbeSollevareEccezioneSeLaMappaVisivaECorta;
begin
  Assert.WillRaise(
    procedure
    begin
      FMinimap.BuildTerrain(nil);
    end, EWarException);
end;

procedure TTestWarMinimap.DovrebbeAggiornareUnPixelDelTerrenoSoloSeLaTegolaESiVista;
var
  LVisual: TArray<Word>;
begin
  LVisual := TMapFixtures.FlatVisual(10);
  FMinimap.UpdateTile(FFog, LVisual, 3, 4);
  Assert.AreEqual<Integer>(0, Integer(Pixel(FMinimap.Terrain, 3, 4).R), 'sconosciuta');
  FFog.SetState(2, 3, 5, 5, wtsFog);
  FMinimap.UpdateTile(FFog, LVisual, 3, 4);
  Assert.AreEqual<Integer>(10, Integer(Pixel(FMinimap.Terrain, 3, 4).R), 'in nebbia');
  FFog.Enabled := False;
  FMinimap.UpdateTile(FFog, LVisual, 30, 30);
  Assert.AreEqual<Integer>(10, Integer(Pixel(FMinimap.Terrain, 30, 30).R), 'senza nebbia');
  Assert.WillRaise(
    procedure
    begin
      FMinimap.UpdateTile(FFog, LVisual, 64, 0);
    end, EWarException);
end;

procedure TTestWarMinimap.DovrebbeColorareLeUnitaSecondoIlGiocatore;
begin
  Assert.AreEqual<Integer>(255, Integer(TWarMinimap.UnitColor(MakeUnit(WAR_UNIT_TOWNHALL_ORCS, 0, 0, 3, 1)).R));
  Assert.AreEqual<Integer>(255, Integer(TWarMinimap.UnitColor(MakeUnit(WAR_UNIT_TOWNHALL_HUMANS, 0, 0, 3, 0)).G));
  Assert.AreEqual<Integer>(199, Integer(TWarMinimap.UnitColor(MakeUnit(WAR_UNIT_FOOTMAN, 0, 0, 1, 0)).G));
  Assert.AreEqual<Integer>(199, Integer(TWarMinimap.UnitColor(MakeUnit(WAR_UNIT_GRUNT, 0, 0, 1, 3)).R));
  Assert.AreEqual<Integer>(211, Integer(TWarMinimap.UnitColor(MakeUnit(WAR_UNIT_GRUNT, 0, 0, 1, 4)).R));
end;

procedure TTestWarMinimap.DovrebbeCopiareIlTerrenoSoloDoveIlGiocatoreHaVisto;
begin
  FMinimap.BuildTerrain(TMapFixtures.FlatVisual(10));
  FFog.SetState(10, 10, 4, 4, wtsVisible);
  FFog.SetState(20, 20, 4, 4, wtsFog);
  FMinimap.Compose(FFog, FUnits);
  Assert.AreEqual<Integer>(10, Integer(Pixel(FMinimap.Frame, 11, 11).R));
  Assert.AreEqual<Integer>(10, Integer(Pixel(FMinimap.Frame, 21, 21).R));
  Assert.AreEqual<Integer>(0, Integer(Pixel(FMinimap.Frame, 30, 30).R));
  Assert.AreEqual<Integer>(255, Integer(FMinimap.Frame[(30 * 64 + 30) * 4 + 3]));
end;

procedure TTestWarMinimap.DovrebbeMostrareTuttoSenzaLaNebbia;
begin
  FMinimap.BuildTerrain(TMapFixtures.FlatVisual(10));
  FFog.Enabled := False;
  FMinimap.Compose(FFog, FUnits);
  Assert.AreEqual<Integer>(10, Integer(Pixel(FMinimap.Frame, 30, 30).R));
end;

procedure TTestWarMinimap.DovrebbeDisegnareLeUnitaViste;
begin
  FMinimap.BuildTerrain(TMapFixtures.FlatVisual(10));
  FFog.SetState(8, 8, 8, 8, wtsVisible);
  FUnits.Add(MakeUnit(WAR_UNIT_BARRACKS_HUMANS, 10, 10, 3, 0));
  FMinimap.Compose(FFog, FUnits);
  Assert.AreEqual<Integer>(199, Integer(Pixel(FMinimap.Frame, 10, 10).G));
  Assert.AreEqual<Integer>(199, Integer(Pixel(FMinimap.Frame, 12, 12).G));
  Assert.AreEqual<Integer>(10, Integer(Pixel(FMinimap.Frame, 13, 13).R));
  Assert.AreEqual<Integer>(255, Integer(FMinimap.Frame[(10 * 64 + 10) * 4 + 3]));
end;

procedure TTestWarMinimap.NonDovrebbeDisegnareLeUnitaNonViste;
begin
  FMinimap.BuildTerrain(TMapFixtures.FlatVisual(10));
  FUnits.Add(MakeUnit(WAR_UNIT_FOOTMAN, 40, 40, 1, 1));
  FMinimap.Compose(FFog, FUnits);
  Assert.AreEqual<Integer>(0, Integer(Pixel(FMinimap.Frame, 40, 40).R));
end;

procedure TTestWarMinimap.DovrebbeDisegnareUnaUnitaGiaVistaAncheSeOraELontana;
var
  LUnit: TWarMapUnit;
begin
  FMinimap.BuildTerrain(TMapFixtures.FlatVisual(10));
  LUnit := MakeUnit(WAR_UNIT_TOWNHALL_ORCS, 40, 40, 3, 1);
  LUnit.HasBeenSeen := True;
  FUnits.Add(LUnit);
  FMinimap.Compose(FFog, FUnits);
  Assert.AreEqual<Integer>(255, Integer(Pixel(FMinimap.Frame, 41, 41).R));
end;

procedure TTestWarMinimap.NonDovrebbeDisegnareICadaveriELeUnitaFinite;
var
  LUnit: TWarMapUnit;
begin
  FFog.Enabled := False;
  FUnits.Add(MakeUnit(WAR_UNIT_HUMAN_CORPSE, 5, 5, 1, 0));
  LUnit := MakeUnit(WAR_UNIT_FOOTMAN, 6, 6, 1, 0);
  LUnit.IsGone := True;
  FUnits.Add(LUnit);
  FMinimap.Compose(FFog, FUnits);
  Assert.AreEqual<Integer>(0, Integer(Pixel(FMinimap.Frame, 5, 5).G));
  Assert.AreEqual<Integer>(0, Integer(Pixel(FMinimap.Frame, 6, 6).G));
end;

procedure TTestWarMinimap.DovrebbeAndareACapoSeUnaUnitaSuperaLaFineDellaRiga;
begin
  FFog.Enabled := False;
  FUnits.Add(MakeUnit(WAR_UNIT_BARRACKS_HUMANS, 62, 10, 3, 0));
  FMinimap.Compose(FFog, FUnits);
  // the third column of the unit is the first pixel of the next row (as in the original)
  Assert.AreEqual<Integer>(199, Integer(Pixel(FMinimap.Frame, 63, 10).G));
  Assert.AreEqual<Integer>(199, Integer(Pixel(FMinimap.Frame, 0, 11).G));
end;

procedure TTestWarMinimap.DovrebbeSollevareEccezioneSeUnaUnitaSuperaLUltimaRiga;
begin
  FFog.Enabled := False;
  FUnits.Add(MakeUnit(WAR_UNIT_BARRACKS_HUMANS, 10, 62, 3, 0));
  Assert.WillRaise(
    procedure
    begin
      FMinimap.Compose(FFog, FUnits);
    end, EWarException);
end;

{ TTestWarMapTilePainter }

procedure TTestWarMapTilePainter.Setup;
begin
  FFog := TWarFogOfWar.Create;
  FMinimap := TWarMinimap.Create(TMapFixtures.Tileset);
end;

procedure TTestWarMapTilePainter.TearDown;
begin
  FMinimap.Free;
  FFog.Free;
end;

procedure TTestWarMapTilePainter.DovrebbeScrivereLaTegolaEAggiornareIlPixelDelTerreno;
var
  LPainter: IWarTilePainter;
begin
  FFog.Enabled := False;
  LPainter := TWarMapTilePainter.Create(TMapFixtures.FlatVisual(10), FMinimap, FFog);
  LPainter.SetTileIndex(7, 8, 40);
  Assert.AreEqual<Integer>(40, LPainter.GetTileIndex(7, 8));
  Assert.AreEqual<Integer>(40, Integer(FMinimap.Terrain[(8 * 64 + 7) * 4]));
end;

procedure TTestWarMapTilePainter.DovrebbeDareLaTegolaDiUnaCella;
var
  LPainter: IWarTilePainter;
begin
  LPainter := TWarMapTilePainter.Create(TMapFixtures.FlatVisual(10), FMinimap, FFog);
  Assert.AreEqual<Integer>(10, LPainter.GetTileIndex(0, 0));
  Assert.AreEqual<Integer>(WAR_MAP_TILE_COUNT, Length(LPainter.GetVisual));
end;

procedure TTestWarMapTilePainter.DovrebbeLasciareInvariataLaMappaOriginale;
var
  LVisual: TArray<Word>;
  LPainter: IWarTilePainter;
begin
  LVisual := TMapFixtures.FlatVisual(10);
  LPainter := TWarMapTilePainter.Create(LVisual, FMinimap, FFog);
  LPainter.SetTileIndex(1, 1, 99);
  Assert.AreEqual<Integer>(10, Integer(LVisual[65]));
end;

procedure TTestWarMapTilePainter.DovrebbeSollevareEccezioneFuoriDallaMappaOLaTegolaNonEUnWord;
var
  LPainter: IWarTilePainter;
begin
  LPainter := TWarMapTilePainter.Create(TMapFixtures.FlatVisual(10), FMinimap, FFog);
  Assert.WillRaise(
    procedure
    begin
      LPainter.SetTileIndex(64, 0, 5);
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      LPainter.SetTileIndex(0, 0, 65536);
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      LPainter.GetTileIndex(0, 64);
    end, EWarException);
end;

procedure TTestWarMapTilePainter.DovrebbeSollevareEccezioneSeLaMappaECorta;
begin
  Assert.WillRaise(
    procedure
    begin
      TWarMapTilePainter.Create(nil, FMinimap, FFog).Free;
    end, EWarException);
end;

end.
