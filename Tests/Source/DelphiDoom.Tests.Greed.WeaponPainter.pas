{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the greed library - the weapon in the hands drawn on    }
{  the buffer of the HUD, and the light of the level on it                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.WeaponPainter;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf,
  DelphiDoom.Greed.Game.State, DelphiDoom.Greed.Render.Assets.Intf, DelphiDoom.Greed.Render.Types,
  DelphiDoom.Greed.Render.State, DelphiDoom.Greed.Canvas, DelphiDoom.Greed.Hud.Intf,
  DelphiDoom.Greed.WeaponLight, DelphiDoom.Greed.WeaponPictures, DelphiDoom.Greed.WeaponPainter,
  DelphiDoom.Tests.Greed.HudScenarios;

type
  /// <summary>A light that turns each color into the next one and says which tile it was asked for</summary>
  TWeaponLightFake = class(TInterfacedObject, IGreedWeaponLight)
  strict private
    FTable: TBytes;
  public
    AskedMapSpot: Integer;
    constructor Create;
    function WeaponColormap(AMapSpot: Integer): PByte;
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedWeaponPainter = class(TObject)
  strict private
    FArchive: IGreedArchive;
    FRunner: THudLibraryRunner;
    FLight: TWeaponLightFake;
    FLightIntf: IGreedWeaponLight;
    FPainter: TGreedWeaponPainter;
    function Picture(AMode: Integer): TBytes;
    function CountPixels: Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeSollevareSenzaUnaDipendenza;
    [Test]
    procedure DovrebbeNonDisegnarePrimaCheUnArmaSiaCaricata;
    [Test]
    procedure DovrebbeNonDisegnareSeIlGiocatoreEMorto;
    [Test]
    procedure DovrebbeIlluminareLArmaARiposoConLaLuceDellaCasella;
    [Test]
    procedure DovrebbeTagliareLArmaARiposoInFondoAllaFinestra;
    [Test]
    procedure DovrebbeDisegnareLArmaCheSparaComeEConLaSuaOrigine;
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedWeaponLight = class(TObject)
  strict private
    FState: TGreedRenderState;
    FLight: TGreedWeaponLight;
    FLightIntf: IGreedWeaponLight;
    function Table(AIndex: Integer): PByte;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeSollevareSenzaLoStatoDelRenderer;
    [Test]
    procedure DovrebbeUsareLaLuceDellaCasellaSenzaEffetto;
    [Test]
    procedure DovrebbeUsareLeTabelleDelFotogrammaConGliEffettiDaUnoAQuattro;
    [Test]
    procedure DovrebbeDareLucePienaSoloNelTurnoDelCiclo;
    [Test]
    procedure DovrebbeAggiungereIlQuartoTremolio;
    [Test]
    procedure DovrebbeDareLucePienaPerUnEffettoSconosciuto;
    [Test]
    procedure DovrebbeLeggereLaLuceDegliSpriteEZeroFuoriMappa;
  end;

implementation

{ TWeaponLightFake }

constructor TWeaponLightFake.Create;
var
  LIndex: Integer;
begin
  inherited Create;
  SetLength(FTable, 256);
  for LIndex := 0 to 255 do
    FTable[LIndex] := Byte(LIndex + 1);
  AskedMapSpot := -1;
end;

function TWeaponLightFake.WeaponColormap(AMapSpot: Integer): PByte;
begin
  AskedMapSpot := AMapSpot;
  Result := @FTable[0];
end;

{ TTestGreedWeaponPainter }

procedure TTestGreedWeaponPainter.Setup;
begin
  FArchive := THudScenarios.SyntheticArchive;
  FRunner := THudLibraryRunner.Create(THudScenarios.Describe(FArchive));
  FLight := TWeaponLightFake.Create;
  FLightIntf := FLight;
  FPainter := TGreedWeaponPainter.Create(FRunner.State, FRunner.Weapons, FArchive, FRunner.Canvas, FLightIntf);
  FRunner.State.Player.Angst := 10;
  FRunner.State.Player.MapSpot := 1234;
  FRunner.Canvas.ApproxZero := 250;
end;

procedure TTestGreedWeaponPainter.TearDown;
begin
  FPainter.Free;
  FLightIntf := nil;
  FRunner.Free;
  FArchive := nil;
end;

function TTestGreedWeaponPainter.Picture(AMode: Integer): TBytes;
begin
  Result := FArchive.ReadLump(FRunner.Weapons.PictureLump(AMode));
end;

function TTestGreedWeaponPainter.CountPixels: Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 0 to High(FRunner.Canvas.Pixels) do
    if FRunner.Canvas.Pixels[LIndex] <> 0 then
      Inc(Result);
end;

procedure TTestGreedWeaponPainter.DovrebbeSollevareSenzaUnaDipendenza;
begin
  Assert.WillRaise(
    procedure
    begin
      TGreedWeaponPainter.Create(nil, FRunner.Weapons, FArchive, FRunner.Canvas, FLightIntf).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedWeaponPainter.Create(FRunner.State, nil, FArchive, FRunner.Canvas, FLightIntf).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedWeaponPainter.Create(FRunner.State, FRunner.Weapons, nil, FRunner.Canvas, FLightIntf).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedWeaponPainter.Create(FRunner.State, FRunner.Weapons, FArchive, nil, FLightIntf).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedWeaponPainter.Create(FRunner.State, FRunner.Weapons, FArchive, FRunner.Canvas, nil).Free;
    end, EArgumentNilException);
end;

procedure TTestGreedWeaponPainter.DovrebbeNonDisegnarePrimaCheUnArmaSiaCaricata;
begin
  FPainter.Draw(100, 100, 200);
  Assert.AreEqual(0, CountPixels);
  Assert.AreEqual(-1, FLight.AskedMapSpot);
end;

procedure TTestGreedWeaponPainter.DovrebbeNonDisegnareSeIlGiocatoreEMorto;
begin
  FRunner.Weapons.LoadWeapon(1);
  FRunner.State.Player.Angst := 0;
  FPainter.Draw(100, 100, 200);
  Assert.AreEqual(0, CountPixels);
end;

procedure TTestGreedWeaponPainter.DovrebbeIlluminareLArmaARiposoConLaLuceDellaCasella;
var
  LPicture: TBytes;
  LWidth, LRow, LColumn: Integer;
  LColor, LExpected: Byte;
begin
  FRunner.Weapons.LoadWeapon(1);
  FRunner.State.WeapMode := 0;
  LPicture := Picture(0);
  LWidth := TGreedCanvas.PictureWidth(LPicture);
  FPainter.Draw(100, 20, 200);
  Assert.AreEqual(1234, FLight.AskedMapSpot);
  for LRow := 0 to TGreedCanvas.PictureHeight(LPicture) - 1 do
    for LColumn := 0 to LWidth - 1 do
    begin
      LColor := LPicture[GREED_PICTURE_HEADER_BYTES + LRow * LWidth + LColumn];
      // the table of the fake gives the next color; 255 becomes 0, which is drawn as the approx zero
      if LColor = 0 then
        LExpected := 0
      else if LColor = 255 then
        LExpected := 250
      else
        LExpected := LColor + 1;
      Assert.AreEqual(LExpected, FRunner.Canvas.GetPixel(100 + LColumn, 20 + LRow));
    end;
end;

procedure TTestGreedWeaponPainter.DovrebbeTagliareLArmaARiposoInFondoAllaFinestra;
var
  LIndex: Integer;
begin
  FRunner.Weapons.LoadWeapon(1);
  FRunner.State.WeapMode := 0;
  FPainter.Draw(100, 150, 160);
  Assert.IsTrue(CountPixels > 0);
  for LIndex := 160 * 320 to High(FRunner.Canvas.Pixels) do
    Assert.AreEqual(Byte(0), FRunner.Canvas.Pixels[LIndex]);
end;

procedure TTestGreedWeaponPainter.DovrebbeDisegnareLArmaCheSparaComeEConLaSuaOrigine;
var
  LPicture: TBytes;
  LWidth, LRow, LColumn: Integer;
begin
  FRunner.Weapons.LoadWeapon(1);
  FRunner.State.WeapMode := 1;
  LPicture := Picture(1);
  LWidth := TGreedCanvas.PictureWidth(LPicture);
  FPainter.Draw(100, 20, 200);
  Assert.AreEqual(-1, FLight.AskedMapSpot, 'no light on the weapon that shoots');
  // the second picture of the synthetic weapons has the origin (3, 2)
  for LRow := 0 to TGreedCanvas.PictureHeight(LPicture) - 1 do
    for LColumn := 0 to LWidth - 1 do
      Assert.AreEqual(LPicture[GREED_PICTURE_HEADER_BYTES + LRow * LWidth + LColumn],
        FRunner.Canvas.GetPixel(100 - 3 + LColumn, 20 - 2 + LRow));
end;

{ TTestGreedWeaponLight }

procedure TTestGreedWeaponLight.Setup;
var
  LAssets: THudAssetsFake;
  LIndex: Integer;
begin
  LAssets := THudAssetsFake.Create;
  SetLength(LAssets.ColorMapBytes, HUD_COLORMAPS * 256 + 512);
  for LIndex := 0 to High(LAssets.ColorMapBytes) do
    LAssets.ColorMapBytes[LIndex] := Byte(LIndex div 256);
  FState := TGreedRenderState.Create(LAssets);
  FState.WallGlow := 7;
  FState.WallFlicker1 := 8;
  FState.WallFlicker2 := 9;
  FState.WallFlicker3 := 10;
  FState.WallFlicker4 := 3;
  FState.WallCycle := 2;
  FLight := TGreedWeaponLight.Create(FState);
  FLightIntf := FLight;
end;

procedure TTestGreedWeaponLight.TearDown;
begin
  FLightIntf := nil;
  FState.Free;
end;

function TTestGreedWeaponLight.Table(AIndex: Integer): PByte;
begin
  Result := PByte(NativeUInt(FState.ColorMaps) + NativeUInt(AIndex * 256));
end;

procedure TTestGreedWeaponLight.DovrebbeSollevareSenzaLoStatoDelRenderer;
begin
  Assert.WillRaise(
    procedure
    begin
      TGreedWeaponLight.Create(nil).Free;
    end, EArgumentNilException);
end;

procedure TTestGreedWeaponLight.DovrebbeUsareLaLuceDellaCasellaSenzaEffetto;
begin
  FState.MapLights[100] := 2;
  FState.RealLight[100] := 5;
  Assert.AreEqual(NativeUInt(FState.LightColormap(21)), NativeUInt(FLightIntf.WeaponColormap(100)));
  Assert.AreEqual(0, FState.WallShadow);
  FState.RealLight[100] := -5000;
  Assert.AreEqual(NativeUInt(FState.ZColormap[0]), NativeUInt(FLightIntf.WeaponColormap(100)), 'not below 0');
  FState.RealLight[100] := 500000;
  Assert.AreEqual(NativeUInt(FState.ZColormap[GREED_MAX_Z_LIGHT]), NativeUInt(FLightIntf.WeaponColormap(100)));
end;

procedure TTestGreedWeaponLight.DovrebbeUsareLeTabelleDelFotogrammaConGliEffettiDaUnoAQuattro;
begin
  FState.MapEffects[5] := 1;
  Assert.AreEqual(NativeUInt(Table(7)), NativeUInt(FLightIntf.WeaponColormap(5)));
  Assert.AreEqual(1, FState.WallShadow, 'the effect is left in the renderer, as the original does');
  FState.MapEffects[5] := 2;
  Assert.AreEqual(NativeUInt(Table(8)), NativeUInt(FLightIntf.WeaponColormap(5)));
  FState.MapEffects[5] := 3;
  Assert.AreEqual(NativeUInt(Table(9)), NativeUInt(FLightIntf.WeaponColormap(5)));
  FState.MapEffects[5] := 4;
  Assert.AreEqual(NativeUInt(Table(10)), NativeUInt(FLightIntf.WeaponColormap(5)));
end;

procedure TTestGreedWeaponLight.DovrebbeDareLucePienaSoloNelTurnoDelCiclo;
begin
  FState.MapLights[5] := 4;
  FState.MapEffects[5] := 7;
  Assert.AreEqual(NativeUInt(FState.ColorMaps), NativeUInt(FLightIntf.WeaponColormap(5)), '7 - 5 is the cycle');
  FState.MapEffects[5] := 6;
  Assert.AreEqual(NativeUInt(FState.LightColormap(32)), NativeUInt(FLightIntf.WeaponColormap(5)));
end;

procedure TTestGreedWeaponLight.DovrebbeAggiungereIlQuartoTremolio;
begin
  FState.MapLights[5] := 4;
  FState.MapEffects[5] := 9;
  Assert.AreEqual(NativeUInt(FState.LightColormap(35)), NativeUInt(FLightIntf.WeaponColormap(5)));
end;

procedure TTestGreedWeaponLight.DovrebbeDareLucePienaPerUnEffettoSconosciuto;
begin
  FState.MapLights[5] := 200;
  FState.MapEffects[5] := 10;
  Assert.AreEqual(NativeUInt(FState.ColorMaps), NativeUInt(FLightIntf.WeaponColormap(5)));
  // a tile outside the map counts as the tile 0
  FState.MapEffects[0] := 1;
  Assert.AreEqual(NativeUInt(Table(7)), NativeUInt(FLightIntf.WeaponColormap(-3)));
end;

procedure TTestGreedWeaponLight.DovrebbeLeggereLaLuceDegliSpriteEZeroFuoriMappa;
var
  LLights: IGreedTileLights;
begin
  LLights := FLight;
  FState.RealLight[4095] := -77;
  Assert.AreEqual(-77, LLights.RealLight(4095));
  Assert.AreEqual(0, LLights.RealLight(4096));
  Assert.AreEqual(0, LLights.RealLight(-1));
end;

end.
