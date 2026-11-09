{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom formats library - the battlescape palettes of TFTD         }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.BattlescapePalette;

interface

uses
  System.SysUtils, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Palette, DelphiDoom.Xcom.Intf;

type
  /// <summary>
  ///   The palettes PAL_BATTLESCAPE, PAL_BATTLESCAPE_1, _2 and _3 that Mod::loadVanillaResources builds from
  ///   UFOGRAPH\D0.LBM .. D3.LBM when the game has them (TFTD): the colors of the CMAP, the last one replaced by
  ///   a background color and Palette::setColors applied (alpha 255, color 0 transparent, and the colors from
  ///   16 on that look like the color 0 made one step lighter so a surface does not merge them with it)
  /// </summary>
  TXcomBattlescapePalette = class
  public
    const
      /// <summary>The number of LBM palettes (D0..D3)</summary>
      COUNT = 4;
    /// <summary>The name of the file of the palette AIndex (0..3): UFOGRAPH/D0.LBM...</summary>
    class function FileName(AIndex: Integer): string; static;
    /// <summary>Palette::setColors on the colors of an LBM, with the background color of the palette AIndex</summary>
    class function FromLbm(const AColors: TXcomPalette; AIndex: Integer): TXcomPalette; static;
    /// <summary>
    ///   False when the game does not have the file of the palette (as the original, that then keeps the
    ///   palette of PALETTES.DAT); an LBM that cannot be read is EXcomDataException
    /// </summary>
    class function TryLoad(const AFiles: IXcomDataFiles; const AReader: IXcomLbmReader; AIndex: Integer;
      out APalette: TXcomPalette): Boolean; static;
  end;

implementation

const
  BACK_COLORS: array[0..TXcomBattlescapePalette.COUNT - 1, 0..2] of Byte = (
    (0, 5, 4), (0, 10, 34), (2, 9, 24), (2, 0, 24));

{ TXcomBattlescapePalette }

class function TXcomBattlescapePalette.FileName(AIndex: Integer): string;
begin
  if (AIndex < 0) or (AIndex >= COUNT) then
    raise EXcomException.CreateFmt(SXcomOffsetInvalid, [AIndex]);
  Result := Format('UFOGRAPH/D%d.LBM', [AIndex]);
end;

class function TXcomBattlescapePalette.FromLbm(const AColors: TXcomPalette; AIndex: Integer): TXcomPalette;
var
  LIndex: Integer;
  LSource: TXcomPalette;
begin
  if (AIndex < 0) or (AIndex >= COUNT) then
    raise EXcomException.CreateFmt(SXcomOffsetInvalid, [AIndex]);
  if AColors.Count <> XCOM_PALETTE_COLORS then
    raise EXcomException.CreateFmt(SXcomPaletteBadCount, [AColors.Count, XCOM_PALETTE_COLORS]);
  LSource := AColors;
  LSource.Colors[255].Red := BACK_COLORS[AIndex, 0];
  LSource.Colors[255].Green := BACK_COLORS[AIndex, 1];
  LSource.Colors[255].Blue := BACK_COLORS[AIndex, 2];
  Result := TXcomPalette.Create(XCOM_PALETTE_COLORS);
  for LIndex := 0 to XCOM_PALETTE_COLORS - 1 do
  begin
    Result.Colors[LIndex].Red := LSource.Colors[LIndex].Red;
    Result.Colors[LIndex].Green := LSource.Colors[LIndex].Green;
    Result.Colors[LIndex].Blue := LSource.Colors[LIndex].Blue;
    Result.Colors[LIndex].Alpha := 255;
    if (LIndex > 15) and (Result.Colors[LIndex].Red = Result.Colors[0].Red) and
      (Result.Colors[LIndex].Green = Result.Colors[0].Green) and
      (Result.Colors[LIndex].Blue = Result.Colors[0].Blue) then
    begin
      // the byte wraps like the Uint8 of SDL_Color
      Result.Colors[LIndex].Red := Byte(Result.Colors[LIndex].Red + 1);
      Result.Colors[LIndex].Green := Byte(Result.Colors[LIndex].Green + 1);
      Result.Colors[LIndex].Blue := Byte(Result.Colors[LIndex].Blue + 1);
    end;
  end;
  Result.Colors[0].Alpha := 0;
end;

class function TXcomBattlescapePalette.TryLoad(const AFiles: IXcomDataFiles; const AReader: IXcomLbmReader;
  AIndex: Integer; out APalette: TXcomPalette): Boolean;
var
  LPicture: TXcomLbmPicture;
begin
  FillChar(APalette, SizeOf(APalette), 0);
  Result := AFiles.Exists(FileName(AIndex));
  if not Result then
    Exit;
  LPicture := AReader.Read(AFiles.ReadAll(FileName(AIndex)));
  APalette := FromLbm(LPicture.Image.Palette, AIndex);
end;

end.
