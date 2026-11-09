{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRadixSpriteList and TRadixSpriteCatalog               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Radix.SpriteList;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Radix.SpriteList, DelphiDoom.Radix.SpriteCatalog, DelphiDoom.Radix.Things;

type
  [TestFixture]
  [Category('radix')]
  TTestRadixSpriteList = class(TObject)
  strict private
    FList: TRadixSpriteList;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareUnaVoceVuotaSeNonSiAggiungeNulla;
    [Test]
    procedure DovrebbeNominareIFotogrammiNonRotantiDaA0;
    [Test]
    procedure DovrebbeFareOttoAngoliPerOgniFotogramma;
    [Test]
    procedure DovrebbeNumerareLeBitmapDelleRotazioniDiOttoSenzaInterruzioni;
    [Test]
    procedure DovrebbeUsareGliAngoliDiSediciNellOrdineDelVecchioCodice;
    [Test]
    procedure DovrebbeFareSoloUnAngoloQuandoSiDaLaMaschera;
    [Test]
    procedure DovrebbeScegliereIlNomeDelloSpriteDalNumeroDellaCosa;
    [Test]
    procedure DovrebbeTagliareUnNomeDiLumpDiPiuDiOttoCaratteri;
    [Test]
    procedure DovrebbeTenereOffsetEFlagDellaVoce;
    [Test]
    procedure DovrebbeIniziareDalFotogrammaDato;
    [Test]
    procedure DovrebbeAvereNelCatalogoGliSpriteNellOrdineDelVecchioCodice;
  end;

implementation

{ TTestRadixSpriteList }

procedure TTestRadixSpriteList.Setup;
begin
  FList := TRadixSpriteList.Create;
end;

procedure TTestRadixSpriteList.TearDown;
begin
  FList.Free;
end;

procedure TTestRadixSpriteList.DovrebbeDareUnaVoceVuotaSeNonSiAggiungeNulla;
begin
  Assert.AreEqual(0, FList.Count);
end;

procedure TTestRadixSpriteList.DovrebbeNominareIFotogrammiNonRotantiDaA0;
begin
  FList.AddNonRotating('FullArmour', MTRX_FULLARMOR, 3);
  Assert.AreEqual(3, FList.Count);
  Assert.AreEqual('FullArmour_1', FList[0].BitmapName);
  Assert.AreEqual('XR00A0', FList[0].LumpName);
  Assert.AreEqual('XR00B0', FList[1].LumpName);
  Assert.AreEqual('XR00C0', FList[2].LumpName);
end;

procedure TTestRadixSpriteList.DovrebbeFareOttoAngoliPerOgniFotogramma;
begin
  FList.AddRotating8('Drone', MTRX_BATTLEDRONE1, 2);
  Assert.AreEqual(16, FList.Count);
  Assert.AreEqual('XR33A1', FList[0].LumpName);
  Assert.AreEqual('XR33A8', FList[7].LumpName);
  Assert.AreEqual('XR33B1', FList[8].LumpName);
end;

procedure TTestRadixSpriteList.DovrebbeNumerareLeBitmapDelleRotazioniDiOttoSenzaInterruzioni;
begin
  FList.AddRotating8('Drone', MTRX_BATTLEDRONE1, 2);
  Assert.AreEqual('Drone_1', FList[0].BitmapName);
  Assert.AreEqual('Drone_8', FList[7].BitmapName);
  Assert.AreEqual('Drone_9', FList[8].BitmapName);
  Assert.AreEqual('Drone_16', FList[15].BitmapName);
end;

procedure TTestRadixSpriteList.DovrebbeUsareGliAngoliDiSediciNellOrdineDelVecchioCodice;
begin
  FList.AddRotating16('Nuke', MTTX_RADIXNUKE, 1);
  Assert.AreEqual(16, FList.Count);
  Assert.AreEqual('X075A1', FList[0].LumpName);
  Assert.AreEqual('X075A9', FList[1].LumpName);
  Assert.AreEqual('X075A2', FList[2].LumpName);
  Assert.AreEqual('X075AA', FList[3].LumpName);
  Assert.AreEqual('X075AG', FList[15].LumpName);
  Assert.AreEqual('Nuke_16', FList[15].BitmapName);
end;

procedure TTestRadixSpriteList.DovrebbeFareSoloUnAngoloQuandoSiDaLaMaschera;
begin
  FList.AddRotating16('Missile', MTTX_ENEMYMISSILE, 1, 14, 12, False, False, 1);
  Assert.AreEqual(1, FList.Count);
  Assert.AreEqual('Missile_1', FList[0].BitmapName);
  Assert.AreEqual('X081A1', FList[0].LumpName);
end;

procedure TTestRadixSpriteList.DovrebbeScegliereIlNomeDelloSpriteDalNumeroDellaCosa;
begin
  // up to the last thing of the editor: XRnn; then Xnnn; the runtime things of the doom numbers: 4 letters
  FList.AddOne('A', 5);
  FList.AddOne('B', MTTX_RADIXPLASMA);
  FList.AddOne('C', DOOM_THING_2_RADIX + 5);
  FList.AddOne('D', 9000);
  Assert.AreEqual('XR05A0', FList[0].LumpName);
  Assert.AreEqual('X067A0', FList[1].LumpName);
  Assert.AreEqual('PLAYA0', FList[2].LumpName);
  Assert.AreEqual('9000A0', FList[3].LumpName);
end;

procedure TTestRadixSpriteList.DovrebbeTagliareUnNomeDiLumpDiPiuDiOttoCaratteri;
begin
  FList.AddOne('A', 5, -255, -255, True, True, 'A', '0', 'XYZ');
  Assert.AreEqual('XR05A0XY', FList[0].LumpName);
end;

procedure TTestRadixSpriteList.DovrebbeTenereOffsetEFlagDellaVoce;
begin
  FList.AddOne('Thing', 3, 12, 34, False, False);
  Assert.AreEqual(12, FList[0].OffsetX);
  Assert.AreEqual(34, FList[0].OffsetY);
  Assert.IsFalse(FList[0].CenterOffsets);
  Assert.IsFalse(FList[0].DefaultOffsets);
  FList.AddOne('Other', 3);
  Assert.AreEqual(RADIX_SPRITE_NO_OFFSET, FList[1].OffsetX);
  Assert.IsTrue(FList[1].CenterOffsets);
  Assert.IsTrue(FList[1].DefaultOffsets);
end;

procedure TTestRadixSpriteList.DovrebbeIniziareDalFotogrammaDato;
begin
  FList.AddNonRotating('X', 1, 2, -255, -255, True, True, 'D');
  Assert.AreEqual('XR01D0', FList[0].LumpName);
  Assert.AreEqual('XR01E0', FList[1].LumpName);
end;

procedure TTestRadixSpriteList.DovrebbeAvereNelCatalogoGliSpriteNellOrdineDelVecchioCodice;
begin
  TRadixSpriteCatalog.Fill(FList);
  Assert.IsTrue(FList.Count > 800);
  Assert.AreEqual('FullArmour_1', FList[0].BitmapName);
  Assert.AreEqual('XR00A0', FList[0].LumpName);
  // the two sprites of the briefing screen are the last
  Assert.AreEqual('9000A0', FList[FList.Count - 2].LumpName);
  Assert.AreEqual('MissileWallBitmap', FList[FList.Count - 1].BitmapName);
  Assert.AreEqual('9001A0', FList[FList.Count - 1].LumpName);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRadixSpriteList);

end.
