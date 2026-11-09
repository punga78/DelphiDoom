{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom formats library - the frames of a set in a single picture   }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.SpriteSheet;

interface

uses
  System.SysUtils, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Image;

type
  /// <summary>A contact sheet: the frames of a set one after the other, ACOLUMNS in a row, to look at them</summary>
  TXcomSpriteSheet = class
  public
    /// <summary>
    ///   The frames in a grid of AColumns columns; the cells have the size of the biggest frame. The palette
    ///   is the one of the first frame. EXcomException for no frames or no columns
    /// </summary>
    class function Compose(const AFrames: TArray<TXcomImage>; AColumns: Integer): TXcomImage; static;
  end;

implementation

{ TXcomSpriteSheet }

class function TXcomSpriteSheet.Compose(const AFrames: TArray<TXcomImage>; AColumns: Integer): TXcomImage;
var
  LCellWidth: Integer;
  LCellHeight: Integer;
  LRows: Integer;
  LIndex: Integer;
  LX: Integer;
  LY: Integer;
  LRow: Integer;
  LOriginX: Integer;
  LOriginY: Integer;
begin
  if (Length(AFrames) = 0) or (AColumns <= 0) then
    raise EXcomException.CreateFmt(SXcomSizeInvalid, [AColumns, Length(AFrames)]);
  LCellWidth := 0;
  LCellHeight := 0;
  for LIndex := 0 to High(AFrames) do
  begin
    if AFrames[LIndex].Width > LCellWidth then
      LCellWidth := AFrames[LIndex].Width;
    if AFrames[LIndex].Height > LCellHeight then
      LCellHeight := AFrames[LIndex].Height;
  end;
  if AColumns > Length(AFrames) then
    AColumns := Length(AFrames);
  LRows := (Length(AFrames) + AColumns - 1) div AColumns;
  Result := TXcomImage.Create(LCellWidth * AColumns, LCellHeight * LRows);
  Result.HasPalette := AFrames[0].HasPalette;
  Result.Palette := AFrames[0].Palette;
  for LIndex := 0 to High(AFrames) do
  begin
    LOriginX := (LIndex mod AColumns) * LCellWidth;
    LOriginY := (LIndex div AColumns) * LCellHeight;
    for LY := 0 to AFrames[LIndex].Height - 1 do
    begin
      LRow := LY * AFrames[LIndex].Width;
      for LX := 0 to AFrames[LIndex].Width - 1 do
        Result.Pixels[(LOriginY + LY) * Result.Width + LOriginX + LX] := AFrames[LIndex].Pixels[LRow + LX];
    end;
  end;
end;

end.
