{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TFontLumpNames and of the types of the font library     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Font.LumpNames;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Font.Types,
  DelphiDoom.Font.LumpNames;

type
  [TestFixture]
  [Category('font')]
  TTestFontLumpNames = class(TObject)
  public
    [Test]
    procedure DovrebbeTogliereGliSpaziDalNome;
    [Test]
    procedure DovrebbeRiempireDiZeriIlNumero;
    [Test]
    procedure DovrebbeLasciareUnNumeroPiuLungoDelPrevisto;
    [Test]
    procedure DovrebbeDareIlNomeDiUnTestoInMaiuscoloTagliatoAOttoCaratteri;
    [Test]
    procedure DovrebbeDareVuotoPerUnTestoDiSoliSpazi;
    [Test]
    procedure DovrebbeDareIlNomeDiUnCarattereComeStcfn033;
    [Test]
    procedure DovrebbeDareIlNomeDiUnaCifraComeSttnum0;
    [Test]
    procedure DovrebbeTagliareUnPrefissoLungo;
    [Test]
    procedure DovrebbeSostituireUnCarattereOltreIlByte;
    [Test]
    procedure DovrebbeDareITipiDiBaseDelleImmagini;
    [Test]
    procedure DovrebbeVedereValideSoloLeImmaginiComplete;
    [Test]
    procedure DovrebbeVedereValidaUnaPaletteDi256ColoriConUnIntervalloGiusto;
    [Test]
    procedure DovrebbeCrearePrefissiEOpzioniDelleRichieste;
  end;

implementation

{ TTestFontLumpNames }

procedure TTestFontLumpNames.DovrebbeTogliereGliSpaziDalNome;
begin
  Assert.AreEqual('HelloWorld', TFontLumpNames.RemoveSpaces('Hello World'));
  Assert.AreEqual('', TFontLumpNames.RemoveSpaces('   '));
  Assert.AreEqual('a'#9'b', TFontLumpNames.RemoveSpaces('a'#9' b'), 'solo gli spazi');
end;

procedure TTestFontLumpNames.DovrebbeRiempireDiZeriIlNumero;
begin
  Assert.AreEqual('033', TFontLumpNames.ZeroFill(3, 33));
  Assert.AreEqual('007', TFontLumpNames.ZeroFill(3, 7));
  Assert.AreEqual('127', TFontLumpNames.ZeroFill(3, 127));
end;

procedure TTestFontLumpNames.DovrebbeLasciareUnNumeroPiuLungoDelPrevisto;
begin
  Assert.AreEqual('1234', TFontLumpNames.ZeroFill(3, 1234));
end;

procedure TTestFontLumpNames.DovrebbeDareIlNomeDiUnTestoInMaiuscoloTagliatoAOttoCaratteri;
begin
  Assert.AreEqual('HELLOWOR', TFontLumpNames.ForText('Hello World 12345'));
  Assert.AreEqual('DOOM', TFontLumpNames.ForText('doom'));
  Assert.AreEqual('A', TFontLumpNames.ForText(' a '));
end;

procedure TTestFontLumpNames.DovrebbeDareVuotoPerUnTestoDiSoliSpazi;
begin
  Assert.AreEqual('', TFontLumpNames.ForText('    '));
  Assert.AreEqual('', TFontLumpNames.ForText(''));
end;

procedure TTestFontLumpNames.DovrebbeDareIlNomeDiUnCarattereComeStcfn033;
begin
  Assert.AreEqual('STCFN033', TFontLumpNames.ForCharacter('STCFN', 33));
  Assert.AreEqual('STCFN127', TFontLumpNames.ForCharacter('STCFN', 127));
  Assert.AreEqual('STCFN065', TFontLumpNames.ForCharacter('stcfn', 65), 'maiuscolo');
end;

procedure TTestFontLumpNames.DovrebbeDareIlNomeDiUnaCifraComeSttnum0;
begin
  Assert.AreEqual('STTNUM0', TFontLumpNames.ForDigit('STTNUM', '0'));
  Assert.AreEqual('STTNUM9', TFontLumpNames.ForDigit('STTNUM', '9'));
end;

procedure TTestFontLumpNames.DovrebbeTagliareUnPrefissoLungo;
begin
  // as the old writer did: the number is cut with the rest
  Assert.AreEqual('LONGPREF', TFontLumpNames.ForCharacter('LONGPREFIX', 33));
  Assert.AreEqual('STTNUM12', TFontLumpNames.ForDigit('STTNUM12', '3'));
end;

procedure TTestFontLumpNames.DovrebbeSostituireUnCarattereOltreIlByte;
begin
  Assert.AreEqual('A?B', TFontLumpNames.ForText('A' + Char($0416) + 'B'));
  Assert.AreEqual('A' + Char($E9), TFontLumpNames.ForText('A' + Char($E9)), 'un carattere a 8 bit resta');
end;

procedure TTestFontLumpNames.DovrebbeDareITipiDiBaseDelleImmagini;
var
  LImage: TFontImage;
begin
  LImage := TFontImage.Create(3, 2);
  Assert.AreEqual<Integer>(6, Length(LImage.Pixels));
  Assert.IsTrue(LImage.IsValid);
  Assert.AreEqual(Cardinal(0), LImage.Pixels[5]);
end;

procedure TTestFontLumpNames.DovrebbeVedereValideSoloLeImmaginiComplete;
var
  LImage: TFontImage;
begin
  LImage := TFontImage.Create(4, 4);
  SetLength(LImage.Pixels, 15);
  Assert.IsFalse(LImage.IsValid, 'un pixel manca');
  LImage.Width := -1;
  SetLength(LImage.Pixels, 16);
  Assert.IsFalse(LImage.IsValid, 'larghezza negativa');
  LImage.Width := 4;
  LImage.Height := 3;
  Assert.IsTrue(LImage.IsValid, 'pixel in piu non fanno male');
end;

procedure TTestFontLumpNames.DovrebbeVedereValidaUnaPaletteDi256ColoriConUnIntervalloGiusto;
var
  LColors: TArray<Cardinal>;
begin
  SetLength(LColors, 256);
  Assert.IsTrue(TFontPaletteSelection.Create(LColors, 1, 255).IsValid);
  Assert.IsTrue(TFontPaletteSelection.Create(LColors, 0, 0).IsValid);
  Assert.IsFalse(TFontPaletteSelection.Create(LColors, 5, 4).IsValid, 'al contrario');
  Assert.IsFalse(TFontPaletteSelection.Create(LColors, -1, 4).IsValid);
  Assert.IsFalse(TFontPaletteSelection.Create(LColors, 1, 256).IsValid, 'oltre l ultimo colore');
  SetLength(LColors, 255);
  Assert.IsFalse(TFontPaletteSelection.Create(LColors, 1, 100).IsValid, 'meno di 256 colori');
end;

procedure TTestFontLumpNames.DovrebbeCrearePrefissiEOpzioniDelleRichieste;
var
  LRequest: TFontGenerationRequest;
  LOptions: TFontExportOptions;
begin
  LRequest := TFontGenerationRequest.ForText('Doom', True, False);
  Assert.AreEqual(Ord(fskText), Ord(LRequest.Kind));
  Assert.AreEqual('Doom', LRequest.Text);
  Assert.IsTrue(LRequest.FixedPitch);
  Assert.IsFalse(LRequest.PerlinNoise);
  LRequest := TFontGenerationRequest.ForCharacters('STCFN', False, True);
  Assert.AreEqual(Ord(fskCharacters), Ord(LRequest.Kind));
  Assert.AreEqual('STCFN', LRequest.Prefix);
  Assert.IsTrue(LRequest.PerlinNoise);
  LRequest := TFontGenerationRequest.ForDigits('STTNUM', False, False);
  Assert.AreEqual(Ord(fskDigits), Ord(LRequest.Kind));
  LOptions := TFontExportOptions.Create(True, True, True, 5, -6);
  Assert.IsFalse(LOptions.DefaultOffsets);
  Assert.AreEqual(5, LOptions.OffsetX);
  Assert.AreEqual(-6, LOptions.OffsetY);
  Assert.IsTrue(TFontExportOptions.CreateWithDefaultOffsets(False, False, False).DefaultOffsets);
end;

end.
