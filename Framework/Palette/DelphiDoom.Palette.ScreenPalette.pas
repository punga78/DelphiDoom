{******************************************************************************}
{                                                                              }
{  DelphiDoom: palette library - the colors of the screen from the palette     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Palette.ScreenPalette;

interface

const
  /// <summary>The alpha channel of the colors of the screen palettes of the engine (opaque)</summary>
  SCREEN_PALETTE_OPAQUE = Cardinal($FF000000);

type
  /// <summary>
  ///   The conversions that V_SetPalette, V_CalcColorMapPalette and V_InitDefaultPalette did on the 256 colors
  ///   of a palette (three bytes each): the gamma table of a level, the packing as $AARRGGBB. The buffers stay
  ///   where the engine keeps them, nothing is allocated and no interface is called: the engine runs it at
  ///   each change of palette, which is not the path of a pixel but is not worth a copy either
  /// </summary>
  TScreenPalette = class sealed
  public
    const
      COLOR_COUNT = 256;
    /// <summary>
    ///   Each color of ASource (256 * 3 bytes: R, G, B) goes through the gamma table AGamma (256 bytes) and is
    ///   packed as $00RRGGBB or-ed with AAlpha into ADest (256 values)
    /// </summary>
    class procedure Convert(ASource: PByte; AGamma: PByte; ADest: PCardinal; AAlpha: Cardinal); static;
    /// <summary>
    ///   Like Convert, but the color i is the one that the colormap AColormap (256 bytes) gives to the index i:
    ///   the palette seen through a custom colormap (the Doom and Strife effects of the sectors)
    /// </summary>
    class procedure ConvertThroughColormap(APalette: PByte; AColormap: PByte; AGamma: PByte;
      ADest: PCardinal; AAlpha: Cardinal); static;
    /// <summary>The palette as it is, no gamma: $00RRGGBB (the default palette of the engine)</summary>
    class procedure Unpack(ASource: PByte; ADest: PCardinal); static;
  end;

implementation

{$POINTERMATH ON}

{ TScreenPalette }

class procedure TScreenPalette.Convert(ASource: PByte; AGamma: PByte; ADest: PCardinal;
  AAlpha: Cardinal);
var
  LIndex: Integer;
begin
  for LIndex := 0 to COLOR_COUNT - 1 do
  begin
    ADest^ := (Cardinal(AGamma[ASource[0]]) shl 16) or
              (Cardinal(AGamma[ASource[1]]) shl 8) or
              Cardinal(AGamma[ASource[2]]) or AAlpha;
    Inc(ADest);
    Inc(ASource, 3);
  end;
end;

class procedure TScreenPalette.ConvertThroughColormap(APalette: PByte; AColormap: PByte;
  AGamma: PByte; ADest: PCardinal; AAlpha: Cardinal);
var
  LIndex: Integer;
  LSource: PByte;
begin
  for LIndex := 0 to COLOR_COUNT - 1 do
  begin
    LSource := APalette + 3 * AColormap[LIndex];
    ADest^ := (Cardinal(AGamma[LSource[0]]) shl 16) or
              (Cardinal(AGamma[LSource[1]]) shl 8) or
              Cardinal(AGamma[LSource[2]]) or AAlpha;
    Inc(ADest);
  end;
end;

class procedure TScreenPalette.Unpack(ASource: PByte; ADest: PCardinal);
var
  LIndex: Integer;
begin
  for LIndex := 0 to COLOR_COUNT - 1 do
  begin
    ADest^ := (Cardinal(ASource[0]) shl 16) or (Cardinal(ASource[1]) shl 8) or Cardinal(ASource[2]);
    Inc(ADest);
    Inc(ASource, 3);
  end;
end;

end.
