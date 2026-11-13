{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - palettes and colors                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.Palette;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.War.Graphics.Types;

type
  [TestFixture]
  [Category('war')]
  TTestWarPaletteDecoder = class(TObject)
  private
    function Ramp(ALength: Integer): TBytes;
  public
    [Test]
    procedure DovrebbeMoltiplicareOgniComponentePerQuattro;
    [Test]
    procedure DovrebbeTroncareAOttoBitIlProdotto;
    [Test]
    procedure DovrebbeCompletareConZeriUnRecordCorto;
    [Test]
    procedure DovrebbeIgnorareICodiciOltreLeComponenti;
    [Test]
    procedure DovrebbeCorreggereLaPaletta255;
    [Test]
    procedure DovrebbeCorreggereLaPaletta217;
    [Test]
    procedure DovrebbeLasciareInvariataUnaPalettaQualunque;
  end;

  [TestFixture]
  [Category('war')]
  TTestWarPaletteComposer = class(TObject)
  private
    function Solid(ARed, AGreen, ABlue: Byte): TBytes;
  public
    [Test]
    procedure DovrebbeDareTuttiZeriSenzaPalette;
    [Test]
    procedure DovrebbeCopiareLaPrimaPaletta;
    [Test]
    procedure DovrebbeSostituireIlMagentaDellaPrimaMetaConLaSeconda;
    [Test]
    procedure DovrebbeTenereIColoriNonMagentaDellaPrimaMeta;
    [Test]
    procedure DovrebbeSovrascrivereLaSecondaMetaConIColoriNonMagentaDellaSeconda;
    [Test]
    procedure DovrebbeTenereLaSecondaMetaDoveLaSecondaEMagenta;
    [Test]
    procedure DovrebbeUsareSoloLaSecondaSuUnaBaseVuota;
    [Test]
    procedure DovrebbeRifiutareUnaPalettaDiLunghezzaSbagliata;
    [Test]
    procedure DovrebbeNonCambiareLeDuePaletteDate;
  end;

  [TestFixture]
  [Category('war')]
  TTestWarColorLookup = class(TObject)
  private
    function Gray: TBytes;
  public
    [Test]
    procedure DovrebbeFareTrasparenteIlColoreZero;
    [Test]
    procedure DovrebbeFareTrasparenteIlColoreZeroAnchePerUnaPalettaNonNera;
    [Test]
    procedure DovrebbeCostruireIColoriOpachiConLoStessoNumeroDelRemake;
    [Test]
    procedure DovrebbeScrivereIQuattroByteRGBA;
    [Test]
    procedure DovrebbeRifiutareUnaPalettaDiLunghezzaSbagliata;
  end;

implementation

uses
  DelphiDoom.War.Graphics.PaletteDecoder, DelphiDoom.War.Graphics.PaletteComposer, DelphiDoom.War.Graphics.ColorLookup;

function ColorOf(const APalette: TBytes; AColor: Integer): string;
begin
  Result := Format('%d,%d,%d', [APalette[AColor * 3], APalette[AColor * 3 + 1], APalette[AColor * 3 + 2]]);
end;

{ TTestWarPaletteDecoder }

function TTestWarPaletteDecoder.Ramp(ALength: Integer): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, ALength);
  for LIndex := 0 to ALength - 1 do
    Result[LIndex] := Byte(LIndex mod 64);
end;

procedure TTestWarPaletteDecoder.DovrebbeMoltiplicareOgniComponentePerQuattro;
var
  LPalette: TBytes;
begin
  LPalette := TWarPaletteDecoder.Decode(1, Ramp(768));
  Assert.AreEqual(768, Length(LPalette));
  Assert.AreEqual(0, Integer(LPalette[0]));
  Assert.AreEqual(4, Integer(LPalette[1]));
  Assert.AreEqual(252, Integer(LPalette[63]));
end;

procedure TTestWarPaletteDecoder.DovrebbeTroncareAOttoBitIlProdotto;
var
  LRaw: TBytes;
  LPalette: TBytes;
begin
  SetLength(LRaw, 768);
  LRaw[0] := 64;
  LRaw[1] := 255;
  LPalette := TWarPaletteDecoder.Decode(1, LRaw);
  Assert.AreEqual(0, Integer(LPalette[0]));
  Assert.AreEqual(252, Integer(LPalette[1]));
end;

procedure TTestWarPaletteDecoder.DovrebbeCompletareConZeriUnRecordCorto;
var
  LPalette: TBytes;
begin
  LPalette := TWarPaletteDecoder.Decode(1, Ramp(10));
  Assert.AreEqual(768, Length(LPalette));
  Assert.AreEqual(36, Integer(LPalette[9]));
  Assert.AreEqual(0, Integer(LPalette[10]));
  Assert.AreEqual(0, Integer(LPalette[767]));
end;

procedure TTestWarPaletteDecoder.DovrebbeIgnorareICodiciOltreLeComponenti;
var
  LPalette: TBytes;
begin
  LPalette := TWarPaletteDecoder.Decode(1, Ramp(800));
  Assert.AreEqual(768, Length(LPalette));
end;

procedure TTestWarPaletteDecoder.DovrebbeCorreggereLaPaletta255;
var
  LPalette: TBytes;
begin
  LPalette := TWarPaletteDecoder.Decode(255, Ramp(768));
  Assert.AreEqual('0,0,0', ColorOf(LPalette, 0));
  Assert.AreEqual('176,184,208', ColorOf(LPalette, 190));
  Assert.AreEqual('208,208,236', ColorOf(LPalette, 191));
  Assert.AreEqual('204,212,180', ColorOf(LPalette, 214));
  Assert.AreEqual('32,32,44', ColorOf(LPalette, 208));
  Assert.AreEqual('80,104,104', ColorOf(LPalette, 211));
  Assert.AreEqual('12,20,12', ColorOf(LPalette, 184));
  Assert.AreEqual('28,32,32', ColorOf(LPalette, 185));
  Assert.AreEqual('56,64,68', ColorOf(LPalette, 186));
  Assert.AreEqual('144,156,176', ColorOf(LPalette, 189));
  // un colore non toccato resta quello del file per quattro
  Assert.AreEqual(Format('%d,%d,%d', [(3 mod 64) * 4, (4 mod 64) * 4, (5 mod 64) * 4]), ColorOf(LPalette, 1));
end;

procedure TTestWarPaletteDecoder.DovrebbeCorreggereLaPaletta217;
var
  LPalette: TBytes;
begin
  LPalette := TWarPaletteDecoder.Decode(217, Ramp(768));
  Assert.AreEqual('108,72,40', ColorOf(LPalette, 96));
  Assert.AreEqual('46,54,54', ColorOf(LPalette, 150));
  Assert.AreEqual('40,64,112', ColorOf(LPalette, 158));
  Assert.AreEqual('32,20,24', ColorOf(LPalette, 215));
  // la 217 non ha le correzioni della 255
  Assert.AreEqual('0,4,8', ColorOf(LPalette, 0));
end;

procedure TTestWarPaletteDecoder.DovrebbeLasciareInvariataUnaPalettaQualunque;
var
  LPalette: TBytes;
begin
  LPalette := TWarPaletteDecoder.Decode(191, Ramp(768));
  Assert.AreEqual('0,4,8', ColorOf(LPalette, 0));
  Assert.AreEqual('128,132,136', ColorOf(LPalette, 96));
end;

{ TTestWarPaletteComposer }

function TTestWarPaletteComposer.Solid(ARed, AGreen, ABlue: Byte): TBytes;
var
  LColor: Integer;
begin
  SetLength(Result, 768);
  for LColor := 0 to 255 do
  begin
    Result[LColor * 3] := ARed;
    Result[LColor * 3 + 1] := AGreen;
    Result[LColor * 3 + 2] := ABlue;
  end;
end;

procedure TTestWarPaletteComposer.DovrebbeDareTuttiZeriSenzaPalette;
var
  LResult: TBytes;
begin
  LResult := TWarPaletteComposer.Compose(nil, nil);
  Assert.AreEqual(768, Length(LResult));
  Assert.AreEqual(0, Integer(LResult[100]));
end;

procedure TTestWarPaletteComposer.DovrebbeCopiareLaPrimaPaletta;
var
  LResult: TBytes;
begin
  LResult := TWarPaletteComposer.Compose(Solid(1, 2, 3), nil);
  Assert.AreEqual('1,2,3', ColorOf(LResult, 0));
  Assert.AreEqual('1,2,3', ColorOf(LResult, 255));
end;

procedure TTestWarPaletteComposer.DovrebbeSostituireIlMagentaDellaPrimaMetaConLaSeconda;
var
  LFirst: TBytes;
  LResult: TBytes;
begin
  LFirst := Solid(10, 20, 30);
  LFirst[5 * 3] := 252;
  LFirst[5 * 3 + 1] := 0;
  LFirst[5 * 3 + 2] := 252;
  LResult := TWarPaletteComposer.Compose(LFirst, Solid(7, 8, 9));
  Assert.AreEqual('7,8,9', ColorOf(LResult, 5));
end;

procedure TTestWarPaletteComposer.DovrebbeTenereIColoriNonMagentaDellaPrimaMeta;
var
  LResult: TBytes;
begin
  LResult := TWarPaletteComposer.Compose(Solid(10, 20, 30), Solid(7, 8, 9));
  Assert.AreEqual('10,20,30', ColorOf(LResult, 0));
  Assert.AreEqual('10,20,30', ColorOf(LResult, 127));
end;

procedure TTestWarPaletteComposer.DovrebbeSovrascrivereLaSecondaMetaConIColoriNonMagentaDellaSeconda;
var
  LResult: TBytes;
begin
  LResult := TWarPaletteComposer.Compose(Solid(10, 20, 30), Solid(7, 8, 9));
  Assert.AreEqual('7,8,9', ColorOf(LResult, 128));
  Assert.AreEqual('7,8,9', ColorOf(LResult, 255));
end;

procedure TTestWarPaletteComposer.DovrebbeTenereLaSecondaMetaDoveLaSecondaEMagenta;
var
  LSecond: TBytes;
  LResult: TBytes;
begin
  LSecond := Solid(7, 8, 9);
  LSecond[200 * 3] := 252;
  LSecond[200 * 3 + 1] := 0;
  LSecond[200 * 3 + 2] := 252;
  LResult := TWarPaletteComposer.Compose(Solid(10, 20, 30), LSecond);
  Assert.AreEqual('10,20,30', ColorOf(LResult, 200));
  Assert.AreEqual('7,8,9', ColorOf(LResult, 201));
end;

procedure TTestWarPaletteComposer.DovrebbeUsareSoloLaSecondaSuUnaBaseVuota;
var
  LResult: TBytes;
begin
  LResult := TWarPaletteComposer.Compose(nil, Solid(7, 8, 9));
  Assert.AreEqual('0,0,0', ColorOf(LResult, 0));
  Assert.AreEqual('7,8,9', ColorOf(LResult, 128));
end;

procedure TTestWarPaletteComposer.DovrebbeRifiutareUnaPalettaDiLunghezzaSbagliata;
var
  LShort: TBytes;
begin
  SetLength(LShort, 10);
  Assert.WillRaise(
    procedure
    begin
      TWarPaletteComposer.Compose(LShort, nil);
    end, EArgumentException);
  Assert.WillRaise(
    procedure
    begin
      TWarPaletteComposer.Compose(nil, LShort);
    end, EArgumentException);
end;

procedure TTestWarPaletteComposer.DovrebbeNonCambiareLeDuePaletteDate;
var
  LFirst: TBytes;
  LSecond: TBytes;
begin
  LFirst := Solid(10, 20, 30);
  LSecond := Solid(7, 8, 9);
  TWarPaletteComposer.Compose(LFirst, LSecond);
  Assert.AreEqual('10,20,30', ColorOf(LFirst, 200));
  Assert.AreEqual('7,8,9', ColorOf(LSecond, 0));
end;

{ TTestWarColorLookup }

function TTestWarColorLookup.Gray: TBytes;
var
  LColor: Integer;
begin
  SetLength(Result, 768);
  for LColor := 0 to 255 do
  begin
    Result[LColor * 3] := Byte(LColor);
    Result[LColor * 3 + 1] := Byte(LColor);
    Result[LColor * 3 + 2] := Byte(LColor);
  end;
end;

procedure TTestWarColorLookup.DovrebbeFareTrasparenteIlColoreZero;
begin
  Assert.AreEqual(Cardinal(0), TWarColorLookupBuilder.Build(Gray)[0]);
end;

procedure TTestWarColorLookup.DovrebbeFareTrasparenteIlColoreZeroAnchePerUnaPalettaNonNera;
var
  LPalette: TBytes;
begin
  LPalette := Gray;
  LPalette[0] := 200;
  LPalette[1] := 100;
  LPalette[2] := 50;
  Assert.AreEqual(Cardinal(0), TWarColorLookupBuilder.Build(LPalette)[0]);
end;

procedure TTestWarColorLookup.DovrebbeCostruireIColoriOpachiConLoStessoNumeroDelRemake;
var
  LPalette: TBytes;
begin
  LPalette := Gray;
  LPalette[3] := $11;
  LPalette[4] := $22;
  LPalette[5] := $33;
  Assert.AreEqual(Cardinal($FF332211), TWarColorLookupBuilder.Build(LPalette)[1]);
end;

procedure TTestWarColorLookup.DovrebbeScrivereIQuattroByteRGBA;
var
  LPalette: TBytes;
  LLookup: TWarColorLookup;
  LBuffer: TBytes;
begin
  LPalette := Gray;
  LPalette[3] := $11;
  LPalette[4] := $22;
  LPalette[5] := $33;
  LLookup := TWarColorLookupBuilder.Build(LPalette);
  SetLength(LBuffer, 8);
  TWarColorLookupBuilder.PutPixel(LLookup, 1, LBuffer, 4);
  Assert.AreEqual(0, Integer(LBuffer[0]));
  Assert.AreEqual($11, Integer(LBuffer[4]));
  Assert.AreEqual($22, Integer(LBuffer[5]));
  Assert.AreEqual($33, Integer(LBuffer[6]));
  Assert.AreEqual($FF, Integer(LBuffer[7]));
end;

procedure TTestWarColorLookup.DovrebbeRifiutareUnaPalettaDiLunghezzaSbagliata;
var
  LShort: TBytes;
begin
  SetLength(LShort, 767);
  Assert.WillRaise(
    procedure
    begin
      TWarColorLookupBuilder.Build(LShort);
    end, EArgumentException);
end;

end.
