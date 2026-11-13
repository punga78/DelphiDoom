{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom surface library - surfaces, SDL operations,    }
{  shades, fonts                                                                }
{                                                                              }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomSurface.Surface;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Palette,
  DelphiDoom.XcomSurface.Types, DelphiDoom.XcomSurface.Sdl, DelphiDoom.XcomSurface.Surface,
  DelphiDoom.XcomSurface.Intf, DelphiDoom.XcomSurface.Shade, DelphiDoom.XcomSurface.Font,
  DelphiDoom.XcomSurface.Factory;

type
  [TestFixture]
  [Category('xcom-surface')]
  TTestXcomSurface = class(TObject)
  public
    [Test]
    procedure DovrebbeConvertireLeMisureDiUnRettangoloComeSDL;
    [Test]
    procedure DovrebbeIntersecareDueSottoinsiemi;
    [Test]
    procedure DovrebbeTrovareIlColorePiuVicino;
    [Test]
    procedure DovrebbeCreareUnaSuperficieVuota;
    [Test]
    procedure DovrebbeRifiutareUnaMisuraNonValida;
    [Test]
    procedure DovrebbeLeggereZeroFuoriDallaSuperficie;
    [Test]
    procedure DovrebbeRifiutareUnMoltiplicatoreZero;
    [Test]
    procedure DovrebbeRifiutareUnBloccoZero;
    [Test]
    procedure DovrebbeSommareLOffsetSoloAiPixelNonTrasparenti;
    [Test]
    procedure DovrebbeInvertereIntornoAlValoreCentrale;
    [Test]
    procedure DovrebbeDisegnareUnRettangoloRitagliato;
    [Test]
    procedure DovrebbeIgnorareUnRettangoloVuoto;
    [Test]
    procedure DovrebbeCopiareLaParteSovrapposta;
    [Test]
    procedure DovrebbeCopiareSenzaGliIndiciZeroConIlBlit;
    [Test]
    procedure DovrebbeNonDisegnareUnaSuperficieNascosta;
    [Test]
    procedure DovrebbeUsareIlRitaglioNelBlit;
    [Test]
    procedure DovrebbeMappareIColoriSeLePaletteSonoDiverse;
    [Test]
    procedure DovrebbeClonareSenzaLUltimoColoreDellaPalette;
    [Test]
    procedure DovrebbeRidisegnareDopoUnCambioDiMisura;
    [Test]
    procedure DovrebbeSfumareUnBlitConLaSfumatura;
    [Test]
    procedure DovrebbeSostituireIlGruppoDiColore;
    [Test]
    procedure DovrebbeDisegnareSoloMetaConHalf;
    [Test]
    procedure DovrebbeLimitareLaSfumaturaAUnIntervallo;
    [Test]
    procedure DovrebbeTrovareLeCelleDiUnFontMonospace;
    [Test]
    procedure DovrebbeRitagliareLeCelleDiUnFontProporzionale;
    [Test]
    procedure DovrebbeUsareIlPuntoInterrogativoPerUnCarattereSconosciuto;
    [Test]
    procedure DovrebbeDareLeMisureDeiCaratteriNonStampabili;
    [Test]
    procedure DovrebbeCaricareUnFontDaUnaDefinizione;
    [Test]
    procedure DovrebbeRifiutareUnFontSenzaImmagini;
    [Test]
    procedure DovrebbeRifiutareUnaCellaPiuLargaDellImmagine;
    [Test]
    procedure DovrebbeUnireLeCoppieSurrogate;
    [Test]
    procedure DovrebbeCreareLeClassiDallaFabbrica;
  end;

implementation

type
  TFakeLoader = class(TInterfacedObject, IXcomSurfaceLoader)
  public
    Loaded: Integer;
    function LoadImage(const AName: string; AWidth, AHeight: Integer): TXcomSurface;
  end;

function TFakeLoader.LoadImage(const AName: string; AWidth, AHeight: Integer): TXcomSurface;
begin
  Inc(Loaded);
  Result := TXcomSurface.Create(AWidth * 4, AHeight * 2);
  Result.SetPixel(1, 1, 5);
end;

{ TTestXcomSurface }

procedure TTestXcomSurface.DovrebbeConvertireLeMisureDiUnRettangoloComeSDL;
var
  LRect: TXcomRect;
begin
  LRect := TXcomRect.Make(40000, -40000, -3, 70000);
  Assert.AreEqual(-25536, Integer(LRect.X));
  Assert.AreEqual(25536, Integer(LRect.Y));
  Assert.AreEqual(65533, Integer(LRect.W));
  Assert.AreEqual(4464, Integer(LRect.H));
end;

procedure TTestXcomSurface.DovrebbeIntersecareDueSottoinsiemi;
var
  LResult: TXcomGraphSubset;
begin
  LResult := TXcomGraphSubset.Intersection(TXcomGraphSubset.Make(0, 10, 0, 10), TXcomGraphSubset.Make(5, 20, -3, 4));
  Assert.AreEqual(5, LResult.BegX);
  Assert.AreEqual(10, LResult.EndX);
  Assert.AreEqual(0, LResult.BegY);
  Assert.AreEqual(4, LResult.EndY);
  LResult := TXcomGraphSubset.Intersection(TXcomGraphSubset.Make(0, 10, 0, 10), TXcomGraphSubset.Make(12, 20, 0, 4));
  Assert.AreEqual(0, LResult.SizeX);
  Assert.AreEqual(4, LResult.SizeY);
  LResult := LResult.Offset(2, 3);
  Assert.AreEqual(2, LResult.BegX);
  Assert.AreEqual(3, LResult.BegY);
end;

procedure TTestXcomSurface.DovrebbeTrovareIlColorePiuVicino;
var
  LPalette: TXcomPalette;
begin
  LPalette := TXcomPalette.Create(4);
  LPalette.Colors[1].Red := 100;
  LPalette.Colors[2].Red := 100;
  LPalette.Colors[3].Red := 200;
  Assert.AreEqual(Integer(1), Integer(TXcomSdl.FindColor(LPalette, 100, 0, 0)), 'il primo uguale');
  Assert.AreEqual(Integer(3), Integer(TXcomSdl.FindColor(LPalette, 180, 0, 0)));
  Assert.AreEqual(Integer(0), Integer(TXcomSdl.FindColor(LPalette, 10, 0, 0)));
end;

procedure TTestXcomSurface.DovrebbeCreareUnaSuperficieVuota;
var
  LSurface: TXcomSurface;
begin
  LSurface := TXcomSurface.Create(5, 3, 7, 8);
  try
    Assert.AreEqual(5, LSurface.Width);
    Assert.AreEqual(3, LSurface.Height);
    Assert.AreEqual(7, LSurface.X);
    Assert.AreEqual(8, LSurface.Y);
    Assert.AreEqual<Integer>(15, Length(LSurface.Pixels));
    Assert.AreEqual(Integer(0), Integer(LSurface.GetPixel(4, 2)));
    Assert.IsTrue(LSurface.Visible);
    Assert.AreEqual(256, LSurface.Palette.Count);
  finally
    LSurface.Free;
  end;
end;

procedure TTestXcomSurface.DovrebbeRifiutareUnaMisuraNonValida;
begin
  Assert.WillRaise(
    procedure
    begin
      TXcomSurface.Create(0, 4).Free;
    end, EXcomException);
end;

procedure TTestXcomSurface.DovrebbeLeggereZeroFuoriDallaSuperficie;
var
  LSurface: TXcomSurface;
begin
  LSurface := TXcomSurface.Create(2, 2);
  try
    LSurface.SetPixel(1, 1, 9);
    LSurface.SetPixel(5, 5, 9);
    Assert.AreEqual(Integer(9), Integer(LSurface.GetPixel(1, 1)));
    Assert.AreEqual(Integer(0), Integer(LSurface.GetPixel(-1, 0)));
    Assert.AreEqual(Integer(0), Integer(LSurface.GetPixel(2, 0)));
  finally
    LSurface.Free;
  end;
end;

procedure TTestXcomSurface.DovrebbeRifiutareUnMoltiplicatoreZero;
var
  LSurface: TXcomSurface;
begin
  LSurface := TXcomSurface.Create(2, 2);
  try
    Assert.WillRaise(
      procedure
      begin
        LSurface.Offset(3, -1, -1, 0);
      end, EXcomSurfaceException);
  finally
    LSurface.Free;
  end;
end;

procedure TTestXcomSurface.DovrebbeRifiutareUnBloccoZero;
var
  LSurface: TXcomSurface;
begin
  LSurface := TXcomSurface.Create(2, 2);
  try
    Assert.WillRaise(
      procedure
      begin
        LSurface.OffsetBlock(3, 0, 1);
      end, EXcomSurfaceException);
    LSurface.OffsetBlock(0, 0, 0);
  finally
    LSurface.Free;
  end;
end;

procedure TTestXcomSurface.DovrebbeSommareLOffsetSoloAiPixelNonTrasparenti;
var
  LSurface: TXcomSurface;
begin
  LSurface := TXcomSurface.Create(3, 1);
  try
    LSurface.SetPixel(1, 0, 10);
    LSurface.SetPixel(2, 0, 250);
    LSurface.Offset(8, -1, 255, 1);
    Assert.AreEqual(Integer(0), Integer(LSurface.GetPixel(0, 0)));
    Assert.AreEqual(Integer(18), Integer(LSurface.GetPixel(1, 0)));
    Assert.AreEqual(Integer(255), Integer(LSurface.GetPixel(2, 0)), 'limite massimo');
    LSurface.Offset(-30, 0, -1, 1);
    Assert.AreEqual(Integer(0), Integer(LSurface.GetPixel(1, 0)), 'limite minimo');
    LSurface.SetPixel(1, 0, 40);
    LSurface.OffsetBlock(20, 16, 1);
    Assert.AreEqual(Integer(48), Integer(LSurface.GetPixel(1, 0)), 'resta nel blocco di 16');
  finally
    LSurface.Free;
  end;
end;

procedure TTestXcomSurface.DovrebbeInvertereIntornoAlValoreCentrale;
var
  LSurface: TXcomSurface;
begin
  LSurface := TXcomSurface.Create(2, 1);
  try
    LSurface.SetPixel(0, 0, 100);
    LSurface.Invert(130);
    Assert.AreEqual(Integer(160), Integer(LSurface.GetPixel(0, 0)));
    Assert.AreEqual(Integer(0), Integer(LSurface.GetPixel(1, 0)));
  finally
    LSurface.Free;
  end;
end;

procedure TTestXcomSurface.DovrebbeDisegnareUnRettangoloRitagliato;
var
  LSurface: TXcomSurface;
begin
  LSurface := TXcomSurface.Create(4, 4);
  try
    LSurface.DrawRect(-2, -2, 4, 4, 7);
    Assert.AreEqual(Integer(7), Integer(LSurface.GetPixel(1, 1)));
    Assert.AreEqual(Integer(0), Integer(LSurface.GetPixel(2, 2)));
    LSurface.Clear(3);
    Assert.AreEqual(Integer(3), Integer(LSurface.GetPixel(3, 3)));
  finally
    LSurface.Free;
  end;
end;

procedure TTestXcomSurface.DovrebbeIgnorareUnRettangoloVuoto;
var
  LSurface: TXcomSurface;
begin
  LSurface := TXcomSurface.Create(4, 4);
  try
    LSurface.DrawRect(0, 0, 0, 4, 7);
    LSurface.DrawRect(TXcomRect.Make(0, 0, 4, 0), 7);
    LSurface.DrawRect(TXcomRect.Make(1, 1, 1, 1), 8);
    Assert.AreEqual(Integer(0), Integer(LSurface.GetPixel(0, 0)));
    Assert.AreEqual(Integer(8), Integer(LSurface.GetPixel(1, 1)));
  finally
    LSurface.Free;
  end;
end;

procedure TTestXcomSurface.DovrebbeCopiareLaParteSovrapposta;
var
  LSource, LTarget: TXcomSurface;
begin
  LSource := TXcomSurface.Create(4, 4, 2, 0);
  LTarget := TXcomSurface.Create(3, 2, 0, 0);
  try
    LSource.SetPixel(0, 0, 5);
    LSource.SetPixel(1, 0, 6);
    LTarget.Copy(LSource);
    Assert.AreEqual(Integer(0), Integer(LTarget.GetPixel(0, 0)), 'fuori dalla sorgente');
    Assert.AreEqual(Integer(5), Integer(LTarget.GetPixel(2, 0)));
  finally
    LTarget.Free;
    LSource.Free;
  end;
end;

procedure TTestXcomSurface.DovrebbeCopiareSenzaGliIndiciZeroConIlBlit;
var
  LSource, LTarget: TXcomSurface;
begin
  LSource := TXcomSurface.Create(2, 1, 1, 0);
  LTarget := TXcomSurface.Create(4, 1);
  try
    LSource.SetPixel(1, 0, 4);
    LTarget.Clear(9);
    LSource.Blit(LTarget);
    Assert.AreEqual(Integer(9), Integer(LTarget.GetPixel(1, 0)), 'trasparente');
    Assert.AreEqual(Integer(4), Integer(LTarget.GetPixel(2, 0)));
  finally
    LTarget.Free;
    LSource.Free;
  end;
end;

procedure TTestXcomSurface.DovrebbeNonDisegnareUnaSuperficieNascosta;
var
  LSource, LTarget: TXcomSurface;
begin
  LSource := TXcomSurface.Create(2, 1);
  LTarget := TXcomSurface.Create(2, 1);
  try
    LSource.Clear(3);
    LSource.Hidden := True;
    LSource.Blit(LTarget);
    Assert.AreEqual(Integer(0), Integer(LTarget.GetPixel(0, 0)));
    LSource.Hidden := False;
    LSource.Visible := False;
    LSource.Blit(LTarget);
    Assert.AreEqual(Integer(0), Integer(LTarget.GetPixel(0, 0)));
  finally
    LTarget.Free;
    LSource.Free;
  end;
end;

procedure TTestXcomSurface.DovrebbeUsareIlRitaglioNelBlit;
var
  LSource, LTarget: TXcomSurface;
begin
  LSource := TXcomSurface.Create(4, 1, 0, 0);
  LTarget := TXcomSurface.Create(4, 1);
  try
    LSource.Clear(2);
    LSource.Crop := TXcomRect.Make(1, 0, 2, 1);
    LSource.Blit(LTarget);
    Assert.AreEqual(Integer(2), Integer(LTarget.GetPixel(0, 0)));
    Assert.AreEqual(Integer(2), Integer(LTarget.GetPixel(1, 0)));
    Assert.AreEqual(Integer(0), Integer(LTarget.GetPixel(2, 0)));
    LSource.ResetCrop;
    Assert.AreEqual(0, Integer(LSource.Crop.W));
  finally
    LTarget.Free;
    LSource.Free;
  end;
end;

procedure TTestXcomSurface.DovrebbeMappareIColoriSeLePaletteSonoDiverse;
var
  LSource, LTarget: TXcomSurface;
  LColors: array[0..1] of TXcomColor;
begin
  LSource := TXcomSurface.Create(1, 1);
  LTarget := TXcomSurface.Create(1, 1);
  try
    FillChar(LColors, SizeOf(LColors), 0);
    LColors[1].Red := 200;
    LSource.SetColors(LColors);
    LSource.SetPixel(0, 0, 1);
    LColors[1].Red := 0;
    LColors[0].Red := 0;
    LTarget.SetColors([LColors[0], LColors[0]]);
    LTarget.SetColors([LColors[1]], 5);
    Assert.AreEqual(256, LTarget.Palette.Count);
    LSource.Blit(LTarget);
    // the nearest color of the target to (200, 0, 0) is the first one that is the darkest of them all: index 0
    Assert.AreEqual(Integer(0), Integer(LTarget.GetPixel(0, 0)));
  finally
    LTarget.Free;
    LSource.Free;
  end;
end;

procedure TTestXcomSurface.DovrebbeClonareSenzaLUltimoColoreDellaPalette;
var
  LSurface, LCopy: TXcomSurface;
  LColors: array[0..255] of TXcomColor;
  LIndex: Integer;
begin
  LSurface := TXcomSurface.Create(2, 2, 3, 4);
  try
    for LIndex := 0 to 255 do
    begin
      LColors[LIndex].Red := LIndex;
      LColors[LIndex].Green := 1;
      LColors[LIndex].Blue := 2;
      LColors[LIndex].Alpha := 0;
    end;
    LSurface.SetColors(LColors);
    LSurface.SetColors([LColors[0]], 300);
    LSurface.SetPixel(1, 1, 33);
    LCopy := LSurface.Clone;
    try
      Assert.AreEqual(Integer(33), Integer(LCopy.GetPixel(1, 1)));
      Assert.AreEqual(3, LCopy.X);
      Assert.AreEqual(Integer(254), Integer(LCopy.Palette.Colors[254].Red));
      Assert.AreEqual(Integer(0), Integer(LCopy.Palette.Colors[255].Red), 'l''ultimo colore non si copia');
    finally
      LCopy.Free;
    end;
  finally
    LSurface.Free;
  end;
end;

procedure TTestXcomSurface.DovrebbeRidisegnareDopoUnCambioDiMisura;
var
  LSurface, LTarget: TXcomSurface;
begin
  LSurface := TXcomSurface.Create(2, 2);
  LTarget := TXcomSurface.Create(4, 4);
  try
    LSurface.Clear(5);
    LSurface.SetWidth(3);
    Assert.AreEqual(3, LSurface.Width);
    Assert.IsTrue(LSurface.Redraw);
    Assert.AreEqual(Integer(5), Integer(LSurface.GetPixel(1, 1)), 'tiene i pixel che entrano');
    LSurface.SetHeight(3);
    LSurface.Blit(LTarget);
    Assert.IsFalse(LSurface.Redraw);
    Assert.AreEqual(Integer(0), Integer(LTarget.GetPixel(0, 0)), 'ha ripulito prima del blit');
  finally
    LTarget.Free;
    LSurface.Free;
  end;
end;

procedure TTestXcomSurface.DovrebbeSfumareUnBlitConLaSfumatura;
var
  LSource, LTarget: TXcomSurface;
begin
  LSource := TXcomSurface.Create(2, 1);
  LTarget := TXcomSurface.Create(2, 1);
  try
    LSource.SetPixel(0, 0, $23);
    LSource.SetPixel(1, 0, $2E);
    TXcomSurfaceShader.Blit(LSource, LTarget, 0, 0, 2);
    Assert.AreEqual(Integer($25), Integer(LTarget.GetPixel(0, 0)));
    Assert.AreEqual(15, Integer(LTarget.GetPixel(1, 0)), 'troppo scuro diventa 15');
  finally
    LTarget.Free;
    LSource.Free;
  end;
end;

procedure TTestXcomSurface.DovrebbeSostituireIlGruppoDiColore;
var
  LSource, LTarget: TXcomSurface;
begin
  LSource := TXcomSurface.Create(1, 1);
  LTarget := TXcomSurface.Create(1, 1);
  try
    LSource.SetPixel(0, 0, $23);
    TXcomSurfaceShader.Blit(LSource, LTarget, 0, 0, 1, False, 3);
    Assert.AreEqual(Integer($24), Integer(LTarget.GetPixel(0, 0)));
  finally
    LTarget.Free;
    LSource.Free;
  end;
end;

procedure TTestXcomSurface.DovrebbeDisegnareSoloMetaConHalf;
var
  LSource, LTarget: TXcomSurface;
begin
  LSource := TXcomSurface.Create(4, 1);
  LTarget := TXcomSurface.Create(4, 1);
  try
    LSource.Clear(1);
    TXcomSurfaceShader.Blit(LSource, LTarget, 0, 0, 0, True);
    Assert.AreEqual(Integer(0), Integer(LTarget.GetPixel(1, 0)));
    Assert.AreEqual(Integer(1), Integer(LTarget.GetPixel(2, 0)));
  finally
    LTarget.Free;
    LSource.Free;
  end;
end;

procedure TTestXcomSurface.DovrebbeLimitareLaSfumaturaAUnIntervallo;
var
  LSource, LTarget: TXcomSurface;
begin
  LSource := TXcomSurface.Create(4, 4);
  LTarget := TXcomSurface.Create(4, 4);
  try
    LSource.Clear(1);
    TXcomSurfaceShader.Blit(LSource, LTarget, 0, 0, 0, TXcomGraphSubset.Make(1, 3, 2, 10));
    Assert.AreEqual(Integer(0), Integer(LTarget.GetPixel(0, 2)));
    Assert.AreEqual(Integer(1), Integer(LTarget.GetPixel(1, 2)));
    Assert.AreEqual(Integer(1), Integer(LTarget.GetPixel(2, 3)));
    Assert.AreEqual(Integer(0), Integer(LTarget.GetPixel(3, 3)));
    Assert.AreEqual(Integer(0), Integer(LTarget.GetPixel(1, 1)));
  finally
    LTarget.Free;
    LSource.Free;
  end;
end;

procedure TTestXcomSurface.DovrebbeTrovareLeCelleDiUnFontMonospace;
var
  LFont: TXcomFont;
  LChar: TXcomFontChar;
begin
  LFont := TXcomFont.Create;
  try
    LFont.Monospace := True;
    LFont.AddImage(4, 5, 1, TXcomSurface.Create(8, 10));
    LFont.Init(0, [65, 66, 67]);
    Assert.IsTrue(LFont.TryGetChar(67, LChar));
    Assert.AreEqual(0, Integer(LChar.Rect.X));
    Assert.AreEqual(5, Integer(LChar.Rect.Y), 'la terza cella e'' sulla seconda riga');
    Assert.AreEqual(4, Integer(LChar.Rect.W));
    Assert.AreEqual(4, LFont.Width);
    Assert.AreEqual(5, LFont.Height);
    Assert.AreEqual(1, LFont.Spacing);
  finally
    LFont.Free;
  end;
end;

procedure TTestXcomSurface.DovrebbeRitagliareLeCelleDiUnFontProporzionale;
var
  LFont: TXcomFont;
  LSurface: TXcomSurface;
  LChar: TXcomFontChar;
begin
  LFont := TXcomFont.Create;
  try
    LSurface := TXcomSurface.Create(8, 4);
    LSurface.SetPixel(2, 1, 1);
    LSurface.SetPixel(3, 3, 1);
    LFont.AddImage(4, 4, 0, LSurface);
    LFont.Init(0, [65, 66]);
    Assert.IsTrue(LFont.TryGetChar(65, LChar));
    Assert.AreEqual(2, Integer(LChar.Rect.X));
    Assert.AreEqual(2, Integer(LChar.Rect.W));
    Assert.IsTrue(LFont.TryGetChar(66, LChar));
    Assert.AreEqual(1, Integer(LChar.Rect.W), 'una cella vuota diventa larga uno');
    Assert.AreEqual(-1, Integer(LChar.Rect.X), 'x di una cella vuota e'' -1');
  finally
    LFont.Free;
  end;
end;

procedure TTestXcomSurface.DovrebbeUsareIlPuntoInterrogativoPerUnCarattereSconosciuto;
var
  LFont: TXcomFont;
  LQuestion: TXcomSurface;
begin
  LFont := TXcomFont.Create;
  try
    LFont.Monospace := True;
    LFont.AddImage(2, 2, 0, TXcomSurface.Create(4, 2));
    LFont.AddImage(2, 2, 0, TXcomSurface.Create(4, 2));
    LFont.Init(1, [Ord('?')]);
    LQuestion := LFont.GetChar(Ord('?'));
    Assert.AreSame(LQuestion, LFont.GetChar(Ord('z')));
    Assert.AreEqual(2, Integer(LFont.GetCharSize(Ord('z')).W));
  finally
    LFont.Free;
  end;
end;

procedure TTestXcomSurface.DovrebbeDareLeMisureDeiCaratteriNonStampabili;
var
  LFont: TXcomFont;
begin
  LFont := TXcomFont.Create;
  try
    LFont.AddImage(8, 12, 1, TXcomSurface.Create(16, 12));
    Assert.AreEqual(4, Integer(LFont.GetCharSize(32).W), 'spazio: mezza larghezza');
    Assert.AreEqual(2, Integer(LFont.GetCharSize($A0).W), 'spazio che non va a capo: un quarto');
    Assert.AreEqual(6, Integer(LFont.GetCharSize(9).W), 'tabulazione: tre quarti');
    Assert.AreEqual(13, Integer(LFont.GetCharSize(10).H));
    LFont.Monospace := True;
    Assert.AreEqual(9, Integer(LFont.GetCharSize(32).W));
  finally
    LFont.Free;
  end;
end;

procedure TTestXcomSurface.DovrebbeCaricareUnFontDaUnaDefinizione;
var
  LFont: TXcomFont;
  LDefinition: TXcomFontDefinition;
  LLoader: TFakeLoader;
  LInterface: IXcomSurfaceLoader;
begin
  LLoader := TFakeLoader.Create;
  LInterface := LLoader;
  LFont := TXcomSurfaceFactory.CreateFont;
  try
    LDefinition.Monospace := True;
    SetLength(LDefinition.Images, 1);
    LDefinition.Images[0].Width := 3;
    LDefinition.Images[0].Height := 4;
    LDefinition.Images[0].Spacing := 1;
    LDefinition.Images[0].FileName := 'font.png';
    LDefinition.Images[0].Chars := 'AB';
    LFont.Load(LDefinition, LInterface);
    Assert.AreEqual(1, LLoader.Loaded);
    Assert.AreEqual(3, LFont.Width);
    Assert.IsTrue(LFont.Monospace);
    Assert.AreEqual(4, Integer(LFont.GetCharSize(Ord('B')).W));
  finally
    LFont.Free;
  end;
end;

procedure TTestXcomSurface.DovrebbeRifiutareUnFontSenzaImmagini;
var
  LFont: TXcomFont;
begin
  LFont := TXcomFont.Create;
  try
    Assert.WillRaise(
      procedure
      begin
        LFont.Width;
      end, EXcomSurfaceException);
    Assert.WillRaise(
      procedure
      begin
        LFont.Height;
      end, EXcomSurfaceException);
    Assert.WillRaise(
      procedure
      begin
        LFont.Spacing;
      end, EXcomSurfaceException);
  finally
    LFont.Free;
  end;
end;

procedure TTestXcomSurface.DovrebbeRifiutareUnaCellaPiuLargaDellImmagine;
var
  LFont: TXcomFont;
begin
  LFont := TXcomFont.Create;
  try
    LFont.AddImage(9, 4, 0, TXcomSurface.Create(8, 4));
    Assert.WillRaise(
      procedure
      begin
        LFont.Init(0, [65]);
      end, EXcomSurfaceException);
  finally
    LFont.Free;
  end;
end;

procedure TTestXcomSurface.DovrebbeUnireLeCoppieSurrogate;
var
  LCodes: TArray<Cardinal>;
begin
  LCodes := TXcomFont.CodePoints('A' + Char($D83D) + Char($DE00) + 'B' + Char($D83D));
  Assert.AreEqual<Integer>(4, Length(LCodes));
  Assert.AreEqual(Cardinal($1F600), LCodes[1]);
  Assert.AreEqual(Cardinal($D83D), LCodes[3], 'un surrogato isolato resta com''e''');
end;

procedure TTestXcomSurface.DovrebbeCreareLeClassiDallaFabbrica;
var
  LSurface: TXcomSurface;
begin
  LSurface := TXcomSurfaceFactory.CreateSurface(3, 3, 1, 2);
  try
    Assert.AreEqual(2, LSurface.Y);
  finally
    LSurface.Free;
  end;
end;

end.
