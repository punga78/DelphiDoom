{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom surface library - the SDL_gfx primitives       }
{                                                                              }
{  Tests\Data\XcomSurface\gfx.script.txt (cases made by                          }
{  Tools\Verifica\176\gfx\gfxharness.cpp) and gfx.golden.txt: what the real     }
{  SDL 1.2.15 and SDL_gfx make, called as Surface::drawLine, drawCircle,        }
{  drawPolygon, drawTexturedPolygon and drawString do, as the FNV-1a of the     }
{  pixels. A case is  W H palette pixels | TW TH palette pixels | ops           }
{  (the palette is the colors of the file repeated up to 256)                   }
{                                                                              }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomSurface.Gfx;

interface

uses
  DelphiDoom.Tests.Shared.Fnv,
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.XcomSurface.Surface;

type
  [TestFixture]
  [Category('xcom-surface')]
  [Category('xcom-golden')]
  TTestXcomGfx = class(TObject)
  private
    function DataFile(const AName: string): string;
    function BuildSurface(AWidth, AHeight: Integer; const APalette, APixels: string): TXcomSurface;
    function RunCase(const ALine: string): string;
    function Fnv(ASurface: TXcomSurface): string;
    function Blank(AWidth, AHeight: Integer; AColors: Integer = 256): TXcomSurface;
  public
    [Test]
    procedure DovrebbeDisegnareCometSdlGfx;
    [Test]
    procedure DovrebbeDisegnareUnaLineaOrizzontaleEUnaVerticale;
    [Test]
    procedure DovrebbeDisegnareUnaLineaDiagonaleConEstremiInclusi;
    [Test]
    procedure DovrebbeRitagliareUnaLineaFuoriDallaSuperficie;
    [Test]
    procedure DovrebbeScartareUnaLineaTuttaFuori;
    [Test]
    procedure DovrebbeDisegnareUnPuntoConRaggioZero;
    [Test]
    procedure DovrebbeNonDisegnareUnCerchioConRaggioNegativo;
    [Test]
    procedure DovrebbeRiempireUnCerchio;
    [Test]
    procedure DovrebbeRiempireUnTriangolo;
    [Test]
    procedure DovrebbeIgnorareUnPoligonoConDuePunti;
    [Test]
    procedure DovrebbeUsareIlPrimoColoreUgualeDellaPalette;
    [Test]
    procedure DovrebbeRipetereLaTexturaNelPoligono;
    [Test]
    procedure DovrebbeLasciareIlFondoDoveLaTexturaETrasparente;
    [Test]
    procedure DovrebbeRifiutareUnaTexturaVuotaMaNonUnPoligonoFuoriDallaSuperficie;
    [Test]
    procedure DovrebbeScriverUnaStringaConIlFontOttoPerOtto;
    [Test]
    procedure DovrebbeFermarsiAlPrimoByteZeroDellaStringa;
    [Test]
    procedure DovrebbeRitagliareUnaStringaCheEsceDalBordo;
    [Test]
    procedure DovrebbeUsareLaTabellaTreTreDueNelleLettere;
    [Test]
    procedure DovrebbeRifiutareUnaScansioneCheTrabocca;
    [Test]
    procedure DovrebbeRifiutareUnaPendenzaCheNonEntraIn16Bit;
  end;

implementation

uses
  System.Generics.Collections, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Palette, DelphiDoom.XcomSurface.Types,
  DelphiDoom.XcomSurface.Gfx, System.IOUtils;

function HexByte(const AText: string; AIndex: Integer): Byte;
begin
  Result := StrToInt('$' + Copy(AText, AIndex * 2 + 1, 2));
end;

function SplitFields(const ALine: string; ADelimiter: Char): TArray<string>;
var
  LList: TStringList;
  LIndex: Integer;
begin
  LList := TStringList.Create;
  try
    LList.Delimiter := ADelimiter;
    LList.StrictDelimiter := True;
    LList.DelimitedText := ALine;
    SetLength(Result, LList.Count);
    for LIndex := 0 to LList.Count - 1 do
      Result[LIndex] := Trim(LList[LIndex]);
  finally
    LList.Free;
  end;
end;

{ TTestXcomGfx }

function TTestXcomGfx.DataFile(const AName: string): string;
begin
  Result := TPath.GetFullPath(ExtractFilePath(ParamStr(0)) + '..\..\Tests\Data\XcomSurface\' + AName);
end;

function TTestXcomGfx.Blank(AWidth, AHeight, AColors: Integer): TXcomSurface;
var
  LColors: array of TXcomColor;
  LIndex: Integer;
begin
  Result := TXcomSurface.Create(AWidth, AHeight);
  SetLength(LColors, 256);
  for LIndex := 0 to 255 do
  begin
    LColors[LIndex].Red := (LIndex mod AColors) * 255 div (AColors - 1 + Ord(AColors = 1));
    LColors[LIndex].Green := LColors[LIndex].Red;
    LColors[LIndex].Blue := LColors[LIndex].Red;
    LColors[LIndex].Alpha := 255;
  end;
  Result.SetColors(LColors);
end;

function TTestXcomGfx.BuildSurface(AWidth, AHeight: Integer; const APalette, APixels: string): TXcomSurface;
var
  LColors: array of TXcomColor;
  LCount, LIndex: Integer;
begin
  Result := TXcomSurface.Create(AWidth, AHeight);
  LCount := Length(APalette) div 6;
  SetLength(LColors, 256);
  for LIndex := 0 to 255 do
  begin
    LColors[LIndex].Red := HexByte(APalette, (LIndex mod LCount) * 3);
    LColors[LIndex].Green := HexByte(APalette, (LIndex mod LCount) * 3 + 1);
    LColors[LIndex].Blue := HexByte(APalette, (LIndex mod LCount) * 3 + 2);
    LColors[LIndex].Alpha := 255;
  end;
  Result.SetColors(LColors);
  for LIndex := 0 to AWidth * AHeight - 1 do
    Result.SetPixel(LIndex mod AWidth, LIndex div AWidth, HexByte(APixels, LIndex));
end;

function TTestXcomGfx.Fnv(ASurface: TXcomSurface): string;
begin
  Result := UIntToStr(TTestFnv.Hash64(ASurface.Pixels, ASurface.Width * ASurface.Height));
end;

function TTestXcomGfx.RunCase(const ALine: string): string;
var
  LParts: TArray<string>;
  LHead, LTexture: TArray<string>;
  LTarget, LTextureSurface: TXcomSurface;
  LOps: TArray<string>;
  LOp: string;
  LFields: TArray<string>;
  LCount, LIndex: Integer;
  LX, LY: array of SmallInt;
  LText: RawByteString;
  LHex: string;
begin
  LParts := SplitFields(ALine, '|');
  LHead := SplitFields(LParts[0], ' ');
  LTexture := SplitFields(LParts[1], ' ');
  LTarget := BuildSurface(StrToInt(LHead[0]), StrToInt(LHead[1]), LHead[2], LHead[3]);
  LTextureSurface := nil;
  try
    if StrToInt(LTexture[0]) > 0 then
      LTextureSurface := BuildSurface(StrToInt(LTexture[0]), StrToInt(LTexture[1]), LTexture[2], LTexture[3]);
    LOps := SplitFields(LParts[2], ';');
    for LOp in LOps do
    begin
      if LOp = '' then
        Continue;
      LFields := SplitFields(LOp, ' ');
      if LFields[0] = 'L' then
        TXcomGfx.DrawLine(LTarget, StrToInt(LFields[1]), StrToInt(LFields[2]), StrToInt(LFields[3]),
          StrToInt(LFields[4]), StrToInt(LFields[5]))
      else if LFields[0] = 'C' then
        TXcomGfx.DrawCircle(LTarget, StrToInt(LFields[1]), StrToInt(LFields[2]), StrToInt(LFields[3]),
          StrToInt(LFields[4]))
      else if (LFields[0] = 'G') or (LFields[0] = 'T') then
      begin
        if LFields[0] = 'G' then
          LIndex := 1
        else
          LIndex := 0;
        LCount := StrToInt(LFields[LIndex + 1]);
        SetLength(LX, LCount);
        SetLength(LY, LCount);
        Inc(LIndex, 2);
        for LCount := 0 to High(LX) do
        begin
          LX[LCount] := StrToInt(LFields[LIndex + LCount * 2]);
          LY[LCount] := StrToInt(LFields[LIndex + LCount * 2 + 1]);
        end;
        if LFields[0] = 'G' then
          TXcomGfx.DrawPolygon(LTarget, LX, LY, StrToInt(LFields[1]))
        else if Assigned(LTextureSurface) then
          TXcomGfx.DrawTexturedPolygon(LTarget, LX, LY, LTextureSurface, StrToInt(LFields[LIndex + Length(LX) * 2]),
            StrToInt(LFields[LIndex + Length(LX) * 2 + 1]));
      end
      else if LFields[0] = 'S' then
      begin
        LHex := LFields[4];
        LText := '';
        if LHex <> '-' then
          for LIndex := 0 to Length(LHex) div 2 - 1 do
            LText := LText + AnsiChar(HexByte(LHex, LIndex));
        TXcomGfx.DrawString(LTarget, StrToInt(LFields[1]), StrToInt(LFields[2]), LText, StrToInt(LFields[3]));
      end;
    end;
    Result := Fnv(LTarget);
  finally
    LTextureSurface.Free;
    LTarget.Free;
  end;
end;

procedure TTestXcomGfx.DovrebbeDisegnareCometSdlGfx;
var
  LScript, LGolden: TStringList;
  LIndex, LFailures: Integer;
  LFirst: string;
begin
  LScript := TStringList.Create;
  LGolden := TStringList.Create;
  try
    LScript.LoadFromFile(DataFile('gfx.script.txt'));
    LGolden.LoadFromFile(DataFile('gfx.golden.txt'));
    Assert.AreEqual(LScript.Count, LGolden.Count);
    Assert.IsTrue(LScript.Count >= 800);
    LFailures := 0;
    LFirst := '';
    for LIndex := 0 to LScript.Count - 1 do
      if RunCase(LScript[LIndex]) <> LGolden[LIndex] then
      begin
        Inc(LFailures);
        if LFirst = '' then
          LFirst := IntToStr(LIndex);
      end;
    Assert.AreEqual(0, LFailures, 'differences with SDL_gfx, the first case is ' + LFirst);
  finally
    LGolden.Free;
    LScript.Free;
  end;
end;

procedure TTestXcomGfx.DovrebbeDisegnareUnaLineaOrizzontaleEUnaVerticale;
var
  LSurface: TXcomSurface;
begin
  LSurface := Blank(6, 5);
  try
    TXcomGfx.DrawLine(LSurface, 4, 1, 1, 1, 3);
    TXcomGfx.DrawLine(LSurface, 2, 4, 2, 0, 7);
    Assert.AreEqual(3, Integer(LSurface.GetPixel(1, 1)));
    Assert.AreEqual(3, Integer(LSurface.GetPixel(4, 1)));
    Assert.AreEqual(0, Integer(LSurface.GetPixel(5, 1)));
    Assert.AreEqual(7, Integer(LSurface.GetPixel(2, 0)));
    Assert.AreEqual(7, Integer(LSurface.GetPixel(2, 4)));
  finally
    LSurface.Free;
  end;
end;

procedure TTestXcomGfx.DovrebbeDisegnareUnaLineaDiagonaleConEstremiInclusi;
var
  LSurface: TXcomSurface;
  LIndex: Integer;
begin
  LSurface := Blank(8, 8);
  try
    TXcomGfx.DrawLine(LSurface, 0, 0, 7, 7, 9);
    for LIndex := 0 to 7 do
      Assert.AreEqual(9, Integer(LSurface.GetPixel(LIndex, LIndex)));
    Assert.AreEqual(0, Integer(LSurface.GetPixel(1, 0)));
  finally
    LSurface.Free;
  end;
end;

procedure TTestXcomGfx.DovrebbeRitagliareUnaLineaFuoriDallaSuperficie;
var
  LSurface: TXcomSurface;
begin
  LSurface := Blank(8, 8);
  try
    TXcomGfx.DrawLine(LSurface, -20, 3, 30, 3, 5);
    Assert.AreEqual(5, Integer(LSurface.GetPixel(0, 3)));
    Assert.AreEqual(5, Integer(LSurface.GetPixel(7, 3)));
    TXcomGfx.DrawLine(LSurface, -10, -10, 20, 20, 6);
    Assert.AreEqual(6, Integer(LSurface.GetPixel(4, 4)));
  finally
    LSurface.Free;
  end;
end;

procedure TTestXcomGfx.DovrebbeScartareUnaLineaTuttaFuori;
var
  LSurface: TXcomSurface;
  LIndex: Integer;
begin
  LSurface := Blank(8, 8);
  try
    TXcomGfx.DrawLine(LSurface, -5, -5, -1, 20, 5);
    TXcomGfx.DrawLine(LSurface, 9, 0, 30, 5, 5);
    for LIndex := 0 to 63 do
      Assert.AreEqual(0, Integer(LSurface.GetPixel(LIndex mod 8, LIndex div 8)));
  finally
    LSurface.Free;
  end;
end;

procedure TTestXcomGfx.DovrebbeDisegnareUnPuntoConRaggioZero;
var
  LSurface: TXcomSurface;
begin
  LSurface := Blank(8, 8);
  try
    TXcomGfx.DrawCircle(LSurface, 3, 4, 0, 8);
    Assert.AreEqual(8, Integer(LSurface.GetPixel(3, 4)));
    Assert.AreEqual(0, Integer(LSurface.GetPixel(4, 4)));
  finally
    LSurface.Free;
  end;
end;

procedure TTestXcomGfx.DovrebbeNonDisegnareUnCerchioConRaggioNegativo;
var
  LSurface: TXcomSurface;
begin
  LSurface := Blank(8, 8);
  try
    TXcomGfx.DrawCircle(LSurface, 3, 4, -3, 8);
    Assert.AreEqual(0, Integer(LSurface.GetPixel(3, 4)));
  finally
    LSurface.Free;
  end;
end;

procedure TTestXcomGfx.DovrebbeRiempireUnCerchio;
var
  LSurface: TXcomSurface;
begin
  LSurface := Blank(21, 21);
  try
    TXcomGfx.DrawCircle(LSurface, 10, 10, 5, 4);
    Assert.AreEqual(4, Integer(LSurface.GetPixel(10, 10)));
    Assert.AreEqual(4, Integer(LSurface.GetPixel(5, 10)));
    Assert.AreEqual(4, Integer(LSurface.GetPixel(10, 15)));
    Assert.AreEqual(0, Integer(LSurface.GetPixel(4, 10)));
    Assert.AreEqual(0, Integer(LSurface.GetPixel(14, 14)));
  finally
    LSurface.Free;
  end;
end;

procedure TTestXcomGfx.DovrebbeRiempireUnTriangolo;
var
  LSurface: TXcomSurface;
begin
  LSurface := Blank(12, 12);
  try
    TXcomGfx.DrawPolygon(LSurface, [1, 10, 1], [1, 1, 10], 6);
    Assert.AreEqual(6, Integer(LSurface.GetPixel(3, 3)));
    Assert.AreEqual(6, Integer(LSurface.GetPixel(2, 8)));
    Assert.AreEqual(0, Integer(LSurface.GetPixel(9, 9)));
    Assert.AreEqual(0, Integer(LSurface.GetPixel(11, 11)));
  finally
    LSurface.Free;
  end;
end;

procedure TTestXcomGfx.DovrebbeIgnorareUnPoligonoConDuePunti;
var
  LSurface: TXcomSurface;
begin
  LSurface := Blank(8, 8);
  try
    TXcomGfx.DrawPolygon(LSurface, [1, 5], [1, 5], 6);
    Assert.AreEqual(0, Integer(LSurface.GetPixel(1, 1)));
  finally
    LSurface.Free;
  end;
end;

procedure TTestXcomGfx.DovrebbeUsareIlPrimoColoreUgualeDellaPalette;
var
  LSurface: TXcomSurface;
begin
  // a palette of 4 colors repeated: the color 6 looks like the color 2 and SDL draws the first one
  LSurface := Blank(8, 8, 4);
  try
    TXcomGfx.DrawLine(LSurface, 0, 0, 7, 0, 6);
    Assert.AreEqual(2, Integer(LSurface.GetPixel(3, 0)));
  finally
    LSurface.Free;
  end;
end;

procedure TTestXcomGfx.DovrebbeRipetereLaTexturaNelPoligono;
var
  LSurface, LTexture: TXcomSurface;
begin
  LSurface := Blank(16, 8);
  LTexture := Blank(2, 1);
  try
    LTexture.SetPixel(0, 0, 3);
    LTexture.SetPixel(1, 0, 5);
    TXcomGfx.DrawTexturedPolygon(LSurface, [0, 15, 15, 0], [0, 0, 7, 7], LTexture, 0, 0);
    Assert.AreEqual(3, Integer(LSurface.GetPixel(2, 3)));
    Assert.AreEqual(5, Integer(LSurface.GetPixel(3, 3)));
    Assert.AreEqual(3, Integer(LSurface.GetPixel(10, 6)));
    // moving the texture moves the pattern
    TXcomGfx.DrawTexturedPolygon(LSurface, [0, 15, 15, 0], [0, 0, 7, 7], LTexture, 1, 0);
    Assert.AreEqual(5, Integer(LSurface.GetPixel(2, 3)));
  finally
    LTexture.Free;
    LSurface.Free;
  end;
end;

procedure TTestXcomGfx.DovrebbeLasciareIlFondoDoveLaTexturaETrasparente;
var
  LSurface, LTexture: TXcomSurface;
begin
  LSurface := Blank(8, 4);
  LTexture := Blank(2, 1);
  try
    LSurface.SetPixel(0, 1, 9);
    LTexture.SetPixel(1, 0, 4);
    TXcomGfx.DrawTexturedPolygon(LSurface, [0, 7, 7, 0], [0, 0, 3, 3], LTexture, 0, 0);
    Assert.AreEqual(9, Integer(LSurface.GetPixel(0, 1)));
    Assert.AreEqual(4, Integer(LSurface.GetPixel(1, 1)));
  finally
    LTexture.Free;
    LSurface.Free;
  end;
end;

procedure TTestXcomGfx.DovrebbeRifiutareUnaTexturaVuotaMaNonUnPoligonoFuoriDallaSuperficie;
var
  LSurface, LTexture: TXcomSurface;
begin
  LSurface := Blank(8, 8);
  LTexture := Blank(2, 2);
  try
    // outside the surface: nothing happens and the texture is not even looked at
    TXcomGfx.DrawTexturedPolygon(LSurface, [-30, -20, -20], [1, 1, 5], LTexture, 0, 0);
    Assert.AreEqual(0, Integer(LSurface.GetPixel(0, 1)));
    // fewer than 3 points
    TXcomGfx.DrawTexturedPolygon(LSurface, [1, 2], [1, 2], LTexture, 0, 0);
    Assert.AreEqual(0, Integer(LSurface.GetPixel(1, 1)));
  finally
    LTexture.Free;
    LSurface.Free;
  end;
end;

procedure TTestXcomGfx.DovrebbeScriverUnaStringaConIlFontOttoPerOtto;
var
  LSurface: TXcomSurface;
  LRow, LColumn, LLit: Integer;
begin
  LSurface := Blank(24, 8, 2);
  try
    // palette of 2 colors: black and white (the 3-3-2 table of white is the index 1)
    TXcomGfx.DrawString(LSurface, 0, 0, 'AB', 1);
    LLit := 0;
    for LRow := 0 to 7 do
      for LColumn := 0 to 7 do
        if LSurface.GetPixel(LColumn, LRow) <> 0 then
          Inc(LLit);
    // the 'A' of the font: 7E 81 81 81 FF 81 81 00 has 6+2+2+2+8+2+2 pixels
    Assert.IsTrue(LLit > 0);
    Assert.AreEqual(0, Integer(LSurface.GetPixel(20, 0)));
    Assert.AreEqual(0, Integer(LSurface.GetPixel(0, 7)));
  finally
    LSurface.Free;
  end;
end;

procedure TTestXcomGfx.DovrebbeFermarsiAlPrimoByteZeroDellaStringa;
var
  LSurface: TXcomSurface;
  LIndex, LFirst: Integer;
begin
  LSurface := Blank(24, 8, 2);
  try
    TXcomGfx.DrawString(LSurface, 0, 0, RawByteString('A'#0'A'), 1);
    LFirst := 0;
    for LIndex := 8 to 23 do
      LFirst := LFirst + LSurface.GetPixel(LIndex, 4);
    Assert.AreEqual(0, LFirst);
  finally
    LSurface.Free;
  end;
end;

procedure TTestXcomGfx.DovrebbeRitagliareUnaStringaCheEsceDalBordo;
var
  LSurface: TXcomSurface;
begin
  LSurface := Blank(10, 8, 2);
  try
    TXcomGfx.DrawString(LSurface, -4, 0, 'AAAA', 1);
    TXcomGfx.DrawString(LSurface, 6, 5, 'A', 1);
    TXcomGfx.DrawString(LSurface, 30, 5, 'A', 1);
    Assert.IsTrue(True);
  finally
    LSurface.Free;
  end;
end;

procedure TTestXcomGfx.DovrebbeUsareLaTabellaTreTreDueNelleLettere;
var
  LSurface: TXcomSurface;
  LColors: array of TXcomColor;
  LIndex: Integer;
begin
  // the text color is the pure red of the color 77; the table of 3-3-2 colors finds for (255, 0, 0) the color 77,
  // and the pixels that the glyph does not light are also sent through the table: the color 1 (200, 0, 0)
  // has the 3-3-2 color (219, 0, 0), whose nearest palette color is the color 1 itself
  LSurface := TXcomSurface.Create(8, 8);
  try
    SetLength(LColors, 256);
    for LIndex := 0 to 255 do
      LColors[LIndex].Alpha := 255;
    LColors[77].Red := 255;
    LColors[1].Red := 200;
    LSurface.SetColors(LColors);
    LSurface.Clear(1);
    TXcomGfx.DrawString(LSurface, 0, 0, '#', 77);
    // '#' is 6C 6C FE 6C FE 6C 6C 00: the row 2 is 11111110
    Assert.AreEqual(77, Integer(LSurface.GetPixel(0, 2)));
    Assert.AreEqual(77, Integer(LSurface.GetPixel(6, 2)));
    Assert.AreEqual(1, Integer(LSurface.GetPixel(7, 2)));
    Assert.AreEqual(1, Integer(LSurface.GetPixel(0, 7)));
  finally
    LSurface.Free;
  end;
end;
procedure TTestXcomGfx.DovrebbeRifiutareUnaScansioneCheTrabocca;
var
  LSurface: TXcomSurface;
begin
  LSurface := Blank(8, 8);
  try
    Assert.WillRaise(
      procedure
      begin
        TXcomGfx.DrawPolygon(LSurface, [-32768, 32767, 0], [-32768, 32767, 32767], 3);
      end, EXcomSurfaceException);
  finally
    LSurface.Free;
  end;
end;

procedure TTestXcomGfx.DovrebbeRifiutareUnaPendenzaCheNonEntraIn16Bit;
var
  LSurface: TXcomSurface;
begin
  LSurface := Blank(8, 8);
  try
    Assert.WillRaise(
      procedure
      begin
        TXcomGfx.DrawLine(LSurface, -30000, -30000, 5, 30000, 1);
      end, EXcomSurfaceException);
  finally
    LSurface.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomGfx);

end.
