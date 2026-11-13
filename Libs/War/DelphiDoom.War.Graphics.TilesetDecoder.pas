{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the image of a tileset                            }
{                                                                              }
{  Port of war1 (acoto87/war1), wres_loadTileset of war_resources.c,           }
{  (c) 2019 Alejandro Coto Gutierrez, zlib License (see Libs\War\LICENSE-      }
{  war1.txt). This is an altered version, not the original.                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Graphics.TilesetDecoder;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.War.Graphics.Types;

type
  /// <summary>
  ///   A tileset record is a list of mega tiles, 8 bytes each: four 16 bit numbers (top left, top right, bottom
  ///   left, bottom right) whose bit 1 flips the mini tile in X, bit 0 in Y and the other bits, without the two
  ///   low ones and times two (wrapped to 16 bits, {$Q-}), are the offset of its 8 x 8 pixels in the tiles
  ///   record. The mega tiles are laid out 32 to a row in an image of 512 x 256 pixels. The original read past
  ///   the tiles record and wrote past the image for bad data; here it is EWarException
  /// </summary>
  TWarTilesetDecoder = class
  public
    /// <param name="ARaw">The bytes of the tileset record</param>
    /// <param name="ATiles">The bytes of the tiles record the catalog points to (indices of the palette)</param>
    /// <param name="ALookup">The colors of the palette of the tiles record</param>
    class function Decode(const ARaw, ATiles: TBytes; const ALookup: TWarColorLookup): TWarTileset; static;
  end;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.War.LittleEndian, DelphiDoom.War.Graphics.ColorLookup;

const
  // the table flip[] of the original (its last value, 8, is never used)
  FLIP: array[0..7] of Integer = (7, 6, 5, 4, 3, 2, 1, 0);

{ TWarTilesetDecoder }

class function TWarTilesetDecoder.Decode(const ARaw, ATiles: TBytes;
  const ALookup: TWarColorLookup): TWarTileset;
var
  LIndexed: TBytes;
  LTile: Integer;
  LMiniY: Integer;
  LMiniX: Integer;
  LValue: Word;
  LOffset: Word;
  LFlipX: Boolean;
  LFlipY: Boolean;
  LTileX: Integer;
  LTileY: Integer;
  LY: Integer;
  LX: Integer;
  LFromY: Integer;
  LFromX: Integer;
  LSource: Integer;
  LPixel: Integer;
begin
  Result.TilesCount := Cardinal(Length(ARaw) div SizeOf(TWarTilesetEntry));
  if Result.TilesCount > WAR_TILESET_MAX_TILES then
    raise EWarException.CreateFmt(SWarGraphicsTooManyTiles, [Result.TilesCount, WAR_TILESET_MAX_TILES]);

  SetLength(LIndexed, WAR_TILESET_WIDTH * WAR_TILESET_HEIGHT);
  for LTile := 0 to Integer(Result.TilesCount) - 1 do
    for LMiniY := 0 to 1 do
      for LMiniX := 0 to 1 do
      begin
        LValue := TWarLittleEndian.ReadWord(ARaw, LTile * SizeOf(TWarTilesetEntry) + (LMiniY * 2 + LMiniX) * 2);
        LFlipX := (LValue and $02) <> 0;
        LFlipY := (LValue and $01) <> 0;
        LOffset := Word((LValue and $FFFC) shl 1);
        LTileX := LMiniX + (LTile mod WAR_TILESET_TILES_PER_ROW) * 2;
        LTileY := LMiniY + (LTile div WAR_TILESET_TILES_PER_ROW) * 2;
        for LY := 0 to WAR_MINI_TILE_SIZE - 1 do
          for LX := 0 to WAR_MINI_TILE_SIZE - 1 do
          begin
            if LFlipY then
              LFromY := FLIP[LY]
            else
              LFromY := LY;
            if LFlipX then
              LFromX := FLIP[LX]
            else
              LFromX := LX;
            LSource := LOffset + LFromY * WAR_MINI_TILE_SIZE + LFromX;
            if LSource >= Length(ATiles) then
              raise EWarException.CreateFmt(SWarGraphicsTileOutside, [LTile * 4 + LMiniY * 2 + LMiniX, LSource, Length(ATiles)]);
            LIndexed[(LY + LTileY * WAR_MINI_TILE_SIZE) * WAR_TILESET_WIDTH + LTileX * WAR_MINI_TILE_SIZE + LX] := ATiles[LSource];
          end;
      end;

  SetLength(Result.Pixels, WAR_TILESET_WIDTH * WAR_TILESET_HEIGHT * WAR_PIXEL_SIZE);
  for LPixel := 0 to WAR_TILESET_WIDTH * WAR_TILESET_HEIGHT - 1 do
    TWarColorLookupBuilder.PutPixel(ALookup, LIndexed[LPixel], Result.Pixels, LPixel * WAR_PIXEL_SIZE);
end;

end.
