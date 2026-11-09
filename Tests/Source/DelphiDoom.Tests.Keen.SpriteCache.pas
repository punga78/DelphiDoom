{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the keen library - the sprites with their shifts        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.SpriteCache;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf;

type
  [TestFixture]
  [Category('keen')]
  TTestKeenSpriteCache = class(TObject)
  strict private
    FGraphics: IKeenGraphics;
    FCache: IKeenSpriteCache;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeTenereLaCopiaSenzaSpostamentoPerPrima;
    [Test]
    procedure DovrebbeFareQuattroCopieConQuattroSpostamenti;
    [Test]
    procedure DovrebbeFareDueCopieConDueSpostamenti;
    [Test]
    procedure DovrebbeUsareLaCopiaPiattaPerTuttiConUnSoloSpostamento;
    [Test]
    procedure DovrebbeDareLeStesseCopieAlleChiamateSuccessive;
    [Test]
    procedure DovrebbeDareLaRigaDellaTabellaDegliSprite;
    [Test]
    procedure DovrebbeRifiutareUnoSpriteCheNonEsiste;
    [Test]
    procedure DovrebbeRifiutareUnNumeroDiSpostamentiNonValido;
    [Test]
    procedure DovrebbeRifiutareIPianiTroppoCorti;
  end;

implementation

uses
  DelphiDoom.Keen.SpriteCache, DelphiDoom.Keen.PlanarConverter, DelphiDoom.Tests.Keen.VideoFakes;

{ TTestKeenSpriteCache }

procedure TTestKeenSpriteCache.Setup;
begin
  FGraphics := TFakeKeenGraphics.Create(3);
  FCache := TKeenSpriteCache.Create(FGraphics);
end;

procedure TTestKeenSpriteCache.DovrebbeTenereLaCopiaSenzaSpostamentoPerPrima;
var
  LSprite: TKeenSprite;
  LPlanar: TBytes;
begin
  LSprite := FCache.GetSprite(KEEN_STARTSPRITES);
  LPlanar := FGraphics.SpritePlanar(0);
  Assert.AreEqual(0, Integer(LSprite.SourceOffset[0]));
  Assert.AreEqual(3, Integer(LSprite.Width[0]));
  Assert.AreEqual(60, Integer(LSprite.PlaneSize[0]));
  Assert.AreEqual(TBytes(LPlanar), TBytes(Copy(LSprite.Data, 0, Length(LPlanar))));
end;

procedure TTestKeenSpriteCache.DovrebbeFareQuattroCopieConQuattroSpostamenti;
var
  LSprite: TKeenSprite;
begin
  LSprite := FCache.GetSprite(KEEN_STARTSPRITES);
  // the plain copy is 3 * 20 * 5 bytes, the shifted ones (3 + 1) * 20 * 5
  Assert.AreEqual(300, Integer(LSprite.SourceOffset[1]));
  Assert.AreEqual(700, Integer(LSprite.SourceOffset[2]));
  Assert.AreEqual(1100, Integer(LSprite.SourceOffset[3]));
  Assert.AreEqual(1500, Length(LSprite.Data));
  Assert.AreEqual(4, Integer(LSprite.Width[1]));
  Assert.AreEqual(80, Integer(LSprite.PlaneSize[3]));
end;

procedure TTestKeenSpriteCache.DovrebbeFareDueCopieConDueSpostamenti;
var
  LSprite: TKeenSprite;
begin
  LSprite := FCache.GetSprite(KEEN_STARTSPRITES + 1);
  // the shifts 0 and 1 are the plain copy, 2 and 3 the copy moved by 4 pixels
  Assert.AreEqual(Integer(LSprite.SourceOffset[0]), Integer(LSprite.SourceOffset[1]));
  Assert.AreEqual(Integer(LSprite.SourceOffset[2]), Integer(LSprite.SourceOffset[3]));
  Assert.AreEqual(2, Integer(LSprite.Width[1]));
  Assert.AreEqual(3, Integer(LSprite.Width[2]));
  Assert.AreEqual(2 * 10 * 5 + 3 * 10 * 5, Length(LSprite.Data));
end;

procedure TTestKeenSpriteCache.DovrebbeUsareLaCopiaPiattaPerTuttiConUnSoloSpostamento;
var
  LSprite: TKeenSprite;
  LShift: Integer;
begin
  LSprite := FCache.GetSprite(KEEN_STARTSPRITES + 2);
  for LShift := 1 to 3 do
  begin
    Assert.AreEqual(Integer(LSprite.SourceOffset[0]), Integer(LSprite.SourceOffset[LShift]));
    Assert.AreEqual(Integer(LSprite.Width[0]), Integer(LSprite.Width[LShift]));
  end;
  Assert.AreEqual(2 * 8 * 5, Length(LSprite.Data));
end;

procedure TTestKeenSpriteCache.DovrebbeDareLeStesseCopieAlleChiamateSuccessive;
var
  LFirst: TKeenSprite;
  LSecond: TKeenSprite;
begin
  LFirst := FCache.GetSprite(KEEN_STARTSPRITES);
  LSecond := FCache.GetSprite(KEEN_STARTSPRITES);
  Assert.AreEqual(TBytes(LFirst.Data), TBytes(LSecond.Data));
end;

procedure TTestKeenSpriteCache.DovrebbeDareLaRigaDellaTabellaDegliSprite;
begin
  Assert.AreEqual(-40, Integer(FCache.GetEntry(KEEN_STARTSPRITES + 3).OriginX));
  Assert.AreEqual(12, Integer(FCache.GetEntry(KEEN_STARTSPRITES + 3).Height));
end;

procedure TTestKeenSpriteCache.DovrebbeRifiutareUnoSpriteCheNonEsiste;
begin
  Assert.WillRaise(
    procedure
    begin
      FCache.GetSprite(KEEN_STARTSPRITES + 99);
    end, EKeenDataException);
  Assert.WillRaise(
    procedure
    begin
      FCache.GetEntry(KEEN_STARTSPRITES - 1);
    end, EKeenDataException);
end;

procedure TTestKeenSpriteCache.DovrebbeRifiutareUnNumeroDiSpostamentiNonValido;
begin
  Assert.WillRaise(
    procedure
    begin
      TKeenSpriteCache.Build(TBytes.Create(1, 2, 3, 4, 5), 1, 1, 3, KEEN_STARTSPRITES);
    end, EKeenDataException);
end;

procedure TTestKeenSpriteCache.DovrebbeRifiutareIPianiTroppoCorti;
begin
  Assert.WillRaise(
    procedure
    begin
      TKeenSpriteCache.Build(TBytes.Create(1, 2, 3), 1, 1, 1, KEEN_STARTSPRITES);
    end, EKeenDataException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestKeenSpriteCache);

end.
