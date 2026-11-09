{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom formats library - a palette of 8 bit images                 }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.Palette;

interface

uses
  System.SysUtils, DelphiDoom.Xcom.Types;

type
  /// <summary>
  ///   The colors of an image of 8 bits per pixel (Palette of OpenXcom). It is a value: a copy is a different
  ///   palette. Only the first Count colors are meaningful, the others are zero
  /// </summary>
  TXcomPalette = record
  public
    Count: Integer;
    Colors: array[0..XCOM_PALETTE_COLORS - 1] of TXcomColor;
    /// <summary>A palette of ACount colors, all black and with alpha 0</summary>
    class function Create(ACount: Integer): TXcomPalette; static;
    /// <summary>The color AIndex; EXcomException if the palette does not have it</summary>
    function ColorAt(AIndex: Integer): TXcomColor;
    /// <summary>
    ///   Replaces the colors XCOM_BACKPOS + 16 .. + 31 with the greyish gradient that Mod::loadVanillaResources
    ///   gives to the palette of the battlescape; the palette must have at least 256 colors
    /// </summary>
    procedure ApplyBattlescapeGradient;
    /// <summary>
    ///   The 768 bytes R, G, B of the 256 colors, as IPaletteConverter of the video library wants them
    ///   (the colors that the palette does not have are black)
    /// </summary>
    function ToRgbBytes: TBytes;
  end;

implementation

const
  GRADIENT: array[0..XCOM_GRADIENT_COLORS - 1, 0..2] of Byte = (
    (140, 152, 148), (132, 136, 140), (116, 124, 132), (108, 116, 124),
    (92, 104, 108), (84, 92, 100), (76, 80, 92), (56, 68, 84),
    (48, 56, 68), (40, 48, 56), (32, 36, 48), (24, 28, 32),
    (16, 20, 24), (8, 12, 16), (3, 4, 8), (3, 3, 6));

{ TXcomPalette }

class function TXcomPalette.Create(ACount: Integer): TXcomPalette;
begin
  if (ACount < 0) or (ACount > XCOM_PALETTE_COLORS) then
    raise EXcomException.CreateFmt(SXcomPaletteBadCount, [ACount, XCOM_PALETTE_COLORS]);
  FillChar(Result, SizeOf(Result), 0);
  Result.Count := ACount;
end;

function TXcomPalette.ColorAt(AIndex: Integer): TXcomColor;
begin
  if (AIndex < 0) or (AIndex >= Count) then
    raise EXcomException.CreateFmt(SXcomPaletteBadIndex, [AIndex, Count]);
  Result := Colors[AIndex];
end;

procedure TXcomPalette.ApplyBattlescapeGradient;
var
  LIndex: Integer;
  LTarget: Integer;
begin
  if Count < XCOM_PALETTE_COLORS then
    raise EXcomException.CreateFmt(SXcomPaletteBadCount, [Count, XCOM_PALETTE_COLORS]);
  for LIndex := 0 to XCOM_GRADIENT_COLORS - 1 do
  begin
    LTarget := XCOM_BACKPOS + 16 + LIndex;
    Colors[LTarget].Red := GRADIENT[LIndex, 0];
    Colors[LTarget].Green := GRADIENT[LIndex, 1];
    Colors[LTarget].Blue := GRADIENT[LIndex, 2];
    Colors[LTarget].Alpha := 255;
  end;
end;

function TXcomPalette.ToRgbBytes: TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, XCOM_PALETTE_COLORS * 3);
  for LIndex := 0 to Count - 1 do
  begin
    Result[LIndex * 3] := Colors[LIndex].Red;
    Result[LIndex * 3 + 1] := Colors[LIndex].Green;
    Result[LIndex * 3 + 2] := Colors[LIndex].Blue;
  end;
end;

end.
