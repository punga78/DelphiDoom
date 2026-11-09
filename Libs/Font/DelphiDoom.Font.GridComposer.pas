{******************************************************************************}
{                                                                              }
{  DelphiDoom: font library - draws the grid of the characters of a font        }
{  Copyright (C) 2021-2022 by Jim Valavanis (original DD_FONT)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Font.GridComposer;

interface

uses
  System.SysUtils,
  DelphiDoom.Font.Types,
  DelphiDoom.Font.Settings,
  DelphiDoom.Font.Intf;

type
  /// <summary>
  ///   DrawToBitmap of TFontEngine without GDI: the picture of the cells filled with the background, and in each
  ///   cell, row by row, the character with the code of its number
  /// </summary>
  TFontGridComposer = class(TInterfacedObject, IFontGridComposer)
  strict private
    FRasterizer: IFontRasterizer;
  public
    constructor Create(const ARasterizer: IFontRasterizer);
    function Compose(const ASettings: TFontSettings): TFontImage;
  end;

implementation

uses
  System.Math;

{ TFontGridComposer }

constructor TFontGridComposer.Create(const ARasterizer: IFontRasterizer);
begin
  inherited Create;
  if not Assigned(ARasterizer) then
    raise EArgumentNilException.Create('ARasterizer');
  FRasterizer := ARasterizer;
end;

function TFontGridComposer.Compose(const ASettings: TFontSettings): TFontImage;
var
  LCellWidth: Integer;
  LCellHeight: Integer;
  LColumns: Integer;
  LRows: Integer;
  LBackground: Cardinal;
  LLetter: TFontImage;
  LCell: Integer;
  LX: Integer;
  LY: Integer;
  LRow: Integer;
  LCopyWidth: Integer;
  LCopyHeight: Integer;
begin
  LCellWidth := Max(0, ASettings.DrawWidth);
  LCellHeight := Max(0, ASettings.DrawHeight);
  LColumns := Max(0, ASettings.GridWidth);
  LRows := Max(0, ASettings.GridHeight);
  Result := TFontImage.Create(LCellWidth * LColumns, LCellHeight * LRows);
  LBackground := TFontSettings.ToRgb(ASettings.BackColor);
  for LCell := 0 to Length(Result.Pixels) - 1 do
    Result.Pixels[LCell] := LBackground;

  for LCell := 0 to LColumns * LRows - 1 do
  begin
    LLetter := FRasterizer.RenderCharacter(ASettings, Char(LCell and $FFFF));
    if not LLetter.IsValid then
      raise EFontException.Create(SFontBadImage);
    LX := (LCell mod LColumns) * LCellWidth;
    LY := (LCell div LColumns) * LCellHeight;
    LCopyWidth := Min(LLetter.Width, LCellWidth);
    LCopyHeight := Min(LLetter.Height, LCellHeight);
    for LRow := 0 to LCopyHeight - 1 do
      Move(LLetter.Pixels[LRow * LLetter.Width], Result.Pixels[(LY + LRow) * Result.Width + LX],
        LCopyWidth * SizeOf(Cardinal));
  end;
end;

end.
