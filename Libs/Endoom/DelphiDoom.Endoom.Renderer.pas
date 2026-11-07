{******************************************************************************}
{                                                                              }
{  DelphiDoom: endoom library - TEndoomRenderer                                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Endoom.Renderer;

interface

uses
  System.SysUtils, System.Math,
  DelphiDoom.Endoom.Intf;

type
  /// <summary>The picture of the ENDOOM screen, as the old e_endoom.pas drew it</summary>
  TEndoomRenderer = class(TInterfacedObject, IEndoomRenderer)
  public
    procedure RenderIndexed(const AScreen, AFont: TBytes; const AColorIndices: array of Byte;
      ABlinkVisible: Boolean; var AOutput: TBytes);
    procedure ConvertToRgb32(const AIndexed: TBytes; const APalette: array of Cardinal;
      AStride: Integer; var AOutput: TArray<Cardinal>);
  end;

implementation

uses
  DelphiDoom.Endoom.Types;

{ TEndoomRenderer }

procedure TEndoomRenderer.RenderIndexed(const AScreen, AFont: TBytes;
  const AColorIndices: array of Byte; ABlinkVisible: Boolean; var AOutput: TBytes);
var
  LCell: Integer;
  LCode: Integer;
  LFlags: Integer;
  LForeground: Byte;
  LBackground: Byte;
  LShowForeground: Boolean;
  LFontColumn: Integer;
  LFontRow: Integer;
  LScreenOffset: Integer;
  LFontOffset: Integer;
  LPixelRow: Integer;
  LPixelColumn: Integer;
  LText: array[0..ENDOOM_LUMP_SIZE - 1] of Byte;
  LGlyphs: array[0..ENDOOM_FONT_SIZE - 1] of Byte;
begin
  if Length(AColorIndices) <> ENDOOM_COLOR_COUNT then
    raise EEndoomException.CreateFmt(SEndoomBadColorTable, [Length(AColorIndices)]);

  // a lump or a font that is too short reads as zeros (the old code read past the end)
  FillChar(LText, SizeOf(LText), 0);
  if Length(AScreen) > 0 then
    Move(AScreen[0], LText[0], Min(Length(AScreen), ENDOOM_LUMP_SIZE));
  FillChar(LGlyphs, SizeOf(LGlyphs), 0);
  if Length(AFont) > 0 then
    Move(AFont[0], LGlyphs[0], Min(Length(AFont), ENDOOM_FONT_SIZE));

  if Length(AOutput) <> ENDOOM_WIDTH * ENDOOM_HEIGHT then
    SetLength(AOutput, ENDOOM_WIDTH * ENDOOM_HEIGHT);

  for LCell := 0 to ENDOOM_CELLS - 1 do
  begin
    LCode := LText[LCell * 2];
    LFlags := LText[LCell * 2 + 1];
    LForeground := AColorIndices[LFlags and 15];
    LBackground := AColorIndices[(LFlags shr 4) and 7];
    // the first character of the font is the code 1
    LFontColumn := (LCode - 1) mod 16;
    LFontRow := (LCode - 1) div 16;
    if ABlinkVisible then
      LShowForeground := True
    else
      LShowForeground := (LFlags shr 7) = 0;
    for LPixelRow := 0 to ENDOOM_CELL_SIZE - 1 do
    begin
      LScreenOffset := (LCell mod ENDOOM_COLUMNS) * ENDOOM_CELL_SIZE +
        ((LCell div ENDOOM_COLUMNS) * ENDOOM_CELL_SIZE + LPixelRow) * ENDOOM_WIDTH;
      LFontOffset := LFontColumn * ENDOOM_CELL_SIZE +
        (LFontRow * ENDOOM_CELL_SIZE + LPixelRow) * ENDOOM_FONT_WIDTH;
      for LPixelColumn := 0 to ENDOOM_CELL_SIZE - 1 do
      begin
        if (LCode = 0) or (LGlyphs[LFontOffset] = 0) or (not LShowForeground) then
          AOutput[LScreenOffset] := LBackground
        else
          AOutput[LScreenOffset] := LForeground;
        Inc(LScreenOffset);
        Inc(LFontOffset);
      end;
    end;
  end;
end;

procedure TEndoomRenderer.ConvertToRgb32(const AIndexed: TBytes; const APalette: array of Cardinal;
  AStride: Integer; var AOutput: TArray<Cardinal>);
var
  LRow: Integer;
  LColumn: Integer;
  LSource: Integer;
  LTarget: Integer;
begin
  if Length(APalette) <> ENDOOM_PALETTE_SIZE then
    raise EEndoomException.CreateFmt(SEndoomBadPalette, [Length(APalette)]);
  if AStride < ENDOOM_WIDTH then
    raise EEndoomException.CreateFmt(SEndoomBadStride, [AStride]);
  if Length(AIndexed) < ENDOOM_WIDTH * ENDOOM_HEIGHT then
    Exit;

  // a buffer already bigger (the engine keeps a texture of 1024x256) is not cut
  if Length(AOutput) < AStride * ENDOOM_HEIGHT then
    SetLength(AOutput, AStride * ENDOOM_HEIGHT);

  for LRow := 0 to ENDOOM_HEIGHT - 1 do
  begin
    LSource := LRow * ENDOOM_WIDTH;
    LTarget := LRow * AStride;
    for LColumn := 0 to ENDOOM_WIDTH - 1 do
    begin
      AOutput[LTarget + LColumn] := APalette[AIndexed[LSource + LColumn]] or $FF000000;
    end;
  end;
end;

end.
