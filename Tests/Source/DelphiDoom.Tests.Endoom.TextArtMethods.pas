{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the methods of the text art                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Endoom.TextArtMethods;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Endoom.TextArt.Types, DelphiDoom.Endoom.TextArt.Intf;

type
  /// <summary>The four methods that choose a cell from its four pixels (the whole screens are in TextArtConverter)</summary>
  [TestFixture]
  [Category('endoom')]
  TTestEndoomTextArtMethods = class(TObject)
  strict private
    function Samples(ATopLeft, ATopRight, ABottomLeft, ABottomRight: Cardinal): TEndoomTextArtSamples;
    function Same(AColor: Cardinal): TEndoomTextArtSamples;
    function Cell(ABackground, AForeground: Integer; ACode: Byte): TEndoomTextArtCell;
  public
    [Test]
    procedure DovrebbeDareLeMedieDeiCanali;
    [Test]
    procedure DovrebbeDareICampioniNellOrdineDelleQuattroCelle;
    [Test]
    procedure DovrebbeDareIlNomeEIlTipoDiOgniMetodo;
    [Test]
    procedure DovrebbeCambiareSoloLoSfondoConIlMetodoSoloSfondo;
    [Test]
    procedure DovrebbeUsareSoloGliSfondiConIlMetodoSoloSfondo;
    [Test]
    procedure DovrebbeScegliereUnoSfondoConUnBlankSeIlColoreEScuro;
    [Test]
    procedure DovrebbeScegliereUnPrimoPianoConUnBloccoSeIlColoreEChiaro;
    [Test]
    procedure DovrebbeUsareUnaSfumaturaPerUnColoreDiMezzo;
    [Test]
    procedure DovrebbeUsareIlBloccoPienoPerUnColoreDelPrimoPiano;
    [Test]
    procedure DovrebbePreferireIlBlankAParita;
    [Test]
    procedure DovrebbeUsareUnaMetaDellaCellaConIlMetodoDeiCaratteriSpeciali;
    [Test]
    procedure DovrebbeUsareLaMetaSuperioreEInferiore;
    [Test]
    procedure DovrebbeUsareUnaCornicePerUnQuartoDiUnColoreIntermedio;
    [Test]
    procedure DovrebbeUsareSoloIPrimiSeiCaratteriNelMetodoNonEsteso;
  end;

implementation

uses
  DelphiDoom.Endoom.TextArt.Factory, DelphiDoom.Endoom.Types;

{ TTestEndoomTextArtMethods }

function TTestEndoomTextArtMethods.Samples(ATopLeft, ATopRight, ABottomLeft,
  ABottomRight: Cardinal): TEndoomTextArtSamples;
begin
  Result.TopLeft := ATopLeft;
  Result.TopRight := ATopRight;
  Result.BottomLeft := ABottomLeft;
  Result.BottomRight := ABottomRight;
end;

function TTestEndoomTextArtMethods.Same(AColor: Cardinal): TEndoomTextArtSamples;
begin
  Result := Samples(AColor, AColor, AColor, AColor);
end;

function TTestEndoomTextArtMethods.Cell(ABackground, AForeground: Integer; ACode: Byte): TEndoomTextArtCell;
begin
  Result.Background := ABackground;
  Result.Foreground := AForeground;
  Result.Code := ACode;
end;

procedure TTestEndoomTextArtMethods.DovrebbeDareLeMedieDeiCanali;
begin
  Assert.AreEqual(Int64($102030), Int64(Same($102030).Average));
  // each channel on its own, the remainder cut: (1 + 2 + 2 + 2) div 4 = 1
  Assert.AreEqual(Int64($010101), Int64(Samples($000000, $020202, $020202, $010101).Average));
  Assert.AreEqual(Int64($7F7F7F), Int64(Samples($000000, $FFFFFF, $000000, $FFFFFF).Average));
  Assert.AreEqual(Int64($FF0000), Int64(Samples($FF0000, $FF0000, $FF0000, $FF0000).Average));
  Assert.AreEqual(Int64($3F0000), Int64(Samples($FF0000, $000000, $000000, $000000).Average));
end;

procedure TTestEndoomTextArtMethods.DovrebbeDareICampioniNellOrdineDelleQuattroCelle;
var
  LSamples: TEndoomTextArtSamples;
begin
  LSamples := Samples(1, 2, 3, 4);
  Assert.AreEqual(Int64(1), Int64(LSamples.Item(0)));
  Assert.AreEqual(Int64(2), Int64(LSamples.Item(1)));
  Assert.AreEqual(Int64(3), Int64(LSamples.Item(2)));
  Assert.AreEqual(Int64(4), Int64(LSamples.Item(3)));
end;

procedure TTestEndoomTextArtMethods.DovrebbeDareIlNomeEIlTipoDiOgniMetodo;
var
  LKind: TEndoomTextArtKind;
begin
  for LKind := Low(TEndoomTextArtKind) to High(TEndoomTextArtKind) do
  begin
    Assert.AreEqual(Ord(LKind), Ord(TEndoomTextArtFactory.CreateMethod(LKind).Kind));
    Assert.IsTrue(ENDOOM_TEXT_ART_NAMES[LKind] <> '');
  end;
  Assert.AreEqual('Dithering', ENDOOM_TEXT_ART_NAMES[eakDither]);
end;

procedure TTestEndoomTextArtMethods.DovrebbeCambiareSoloLoSfondoConIlMetodoSoloSfondo;
var
  LCell: TEndoomTextArtCell;
begin
  LCell := Cell(0, 9, 65);
  TEndoomTextArtFactory.CreateMethod(eakBackgroundOnly).Convert(Same($0000AA), LCell);
  Assert.AreEqual(1, LCell.Background);
  Assert.AreEqual(9, LCell.Foreground);
  Assert.AreEqual(65, Integer(LCell.Code));
end;

procedure TTestEndoomTextArtMethods.DovrebbeUsareSoloGliSfondiConIlMetodoSoloSfondo;
var
  LCell: TEndoomTextArtCell;
begin
  LCell := Cell(0, 0, 0);
  TEndoomTextArtFactory.CreateMethod(eakBackgroundOnly).Convert(Same($FFFFFF), LCell);
  // the white is not a background: the light gray is the nearest
  Assert.AreEqual(7, LCell.Background);
end;

procedure TTestEndoomTextArtMethods.DovrebbeScegliereUnoSfondoConUnBlankSeIlColoreEScuro;
var
  LCell: TEndoomTextArtCell;
begin
  LCell := Cell(5, 6, 99);
  TEndoomTextArtFactory.CreateMethod(eakBackgroundForeground).Convert(Same($00AA00), LCell);
  Assert.AreEqual(2, LCell.Background);
  Assert.AreEqual(6, LCell.Foreground);
  Assert.AreEqual(Integer(Ord(' ')), Integer(LCell.Code));
end;

procedure TTestEndoomTextArtMethods.DovrebbeScegliereUnPrimoPianoConUnBloccoSeIlColoreEChiaro;
var
  LCell: TEndoomTextArtCell;
begin
  LCell := Cell(5, 6, 99);
  TEndoomTextArtFactory.CreateMethod(eakBackgroundForeground).Convert(Same($FFFF55), LCell);
  Assert.AreEqual(5, LCell.Background);
  Assert.AreEqual(14, LCell.Foreground);
  Assert.AreEqual(Integer($DB), Integer(LCell.Code));
end;

procedure TTestEndoomTextArtMethods.DovrebbeUsareUnaSfumaturaPerUnColoreDiMezzo;
var
  LCell: TEndoomTextArtCell;
begin
  // $555555 is half way between black and light gray ($AAAAAA): the middle shade of the two, which is
  // found before the dark gray itself (a foreground with a full block) because its foreground comes first
  LCell := Cell(0, 0, 0);
  TEndoomTextArtFactory.CreateMethod(eakDither).Convert(Same($555555), LCell);
  Assert.AreEqual(0, LCell.Background);
  Assert.AreEqual(7, LCell.Foreground);
  Assert.AreEqual(Integer($B1), Integer(LCell.Code));
end;

procedure TTestEndoomTextArtMethods.DovrebbeUsareIlBloccoPienoPerUnColoreDelPrimoPiano;
var
  LCell: TEndoomTextArtCell;
begin
  LCell := Cell(0, 0, 0);
  TEndoomTextArtFactory.CreateMethod(eakDither).Convert(Same($FFFFFF), LCell);
  Assert.AreEqual(15, LCell.Foreground);
  Assert.AreEqual(Integer($DB), Integer(LCell.Code));
end;

procedure TTestEndoomTextArtMethods.DovrebbePreferireIlBlankAParita;
var
  LCell: TEndoomTextArtCell;
begin
  LCell := Cell(3, 3, 3);
  TEndoomTextArtFactory.CreateMethod(eakDither).Convert(Same($000000), LCell);
  Assert.AreEqual(0, LCell.Background);
  Assert.AreEqual(Integer(Ord(' ')), Integer(LCell.Code));
  LCell := Cell(3, 3, 3);
  TEndoomTextArtFactory.CreateMethod(eakSpecialCharacters).Convert(Same($000000), LCell);
  Assert.AreEqual(0, LCell.Background);
  Assert.AreEqual(Integer(Ord(' ')), Integer(LCell.Code));
end;

procedure TTestEndoomTextArtMethods.DovrebbeUsareUnaMetaDellaCellaConIlMetodoDeiCaratteriSpeciali;
var
  LCell: TEndoomTextArtCell;
begin
  // the left half white, the right half black: a half block with a white foreground
  LCell := Cell(0, 0, 0);
  TEndoomTextArtFactory.CreateMethod(eakSpecialCharacters).Convert(Samples($FFFFFF, $000000, $FFFFFF, $000000), LCell);
  Assert.AreEqual(Integer($DD), Integer(LCell.Code));
  Assert.AreEqual(0, LCell.Background);
  Assert.AreEqual(15, LCell.Foreground);
end;

procedure TTestEndoomTextArtMethods.DovrebbeUsareLaMetaSuperioreEInferiore;
var
  LCell: TEndoomTextArtCell;
begin
  LCell := Cell(0, 0, 0);
  TEndoomTextArtFactory.CreateMethod(eakSpecialCharacters).Convert(Samples($FFFFFF, $FFFFFF, $000000, $000000), LCell);
  Assert.AreEqual(Integer($DF), Integer(LCell.Code));
  Assert.AreEqual(15, LCell.Foreground);
  LCell := Cell(0, 0, 0);
  TEndoomTextArtFactory.CreateMethod(eakSpecialCharacters).Convert(Samples($000000, $000000, $FFFFFF, $FFFFFF), LCell);
  Assert.AreEqual(Integer($DC), Integer(LCell.Code));
end;

procedure TTestEndoomTextArtMethods.DovrebbeUsareUnaCornicePerUnQuartoDiUnColoreIntermedio;
var
  LCell: TEndoomTextArtCell;
begin
  // three quarters of black and one of $555555, which is the middle color of black and light gray:
  // the corner $DA ("BBBf") with a light gray foreground on black has it exactly
  LCell := Cell(3, 3, 3);
  TEndoomTextArtFactory.CreateMethod(eakExtendedSpecialCharacters).Convert(
    Samples($000000, $000000, $000000, $555555), LCell);
  Assert.AreEqual(Integer($DA), Integer(LCell.Code));
  Assert.AreEqual(0, LCell.Background);
  Assert.AreEqual(7, LCell.Foreground);
end;
procedure TTestEndoomTextArtMethods.DovrebbeUsareSoloIPrimiSeiCaratteriNelMetodoNonEsteso;
var
  LCell: TEndoomTextArtCell;
  LAllowed: set of Byte;
begin
  LAllowed := [$DB, $DC, $DD, $DF, Ord(' ')];
  LCell := Cell(0, 0, 0);
  TEndoomTextArtFactory.CreateMethod(eakSpecialCharacters).Convert(
    Samples($000000, $000000, $000000, $555555), LCell);
  Assert.IsTrue(LCell.Code in LAllowed);
end;

end.
