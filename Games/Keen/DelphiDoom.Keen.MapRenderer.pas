{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - a whole map as one picture                        }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  the tiles that ID_RF draws (RFL_NewTile, RFL_MaskForegroundTiles)            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.MapRenderer;

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf;

type
  /// <summary>
  ///   Draws every tile of a map: the background plane is a 16x16 tile for each word (a negative word is a
  ///   tile that is never drawn), and over it the foreground plane (0 is no tile, a negative word is never
  ///   drawn) with its mask: the screen becomes (screen and mask) or color. The actors of the info plane,
  ///   the animation of the tiles and the sprites are not drawn: it is the map as the tiles make it
  /// </summary>
  TKeenMapRenderer = class(TInterfacedObject, IKeenMapRenderer)
  public
    function Render(const AMap: IKeenMap; const AGraphics: IKeenGraphics): TKeenChunkyImage;
  end;

implementation

uses
  DelphiDoom.Keen.PlanarConverter;

{ TKeenMapRenderer }

function TKeenMapRenderer.Render(const AMap: IKeenMap;
  const AGraphics: IKeenGraphics): TKeenChunkyImage;
var
  LBackground: array of TKeenChunkyImage;
  LForeground: array of TKeenChunkyImage;
  LForegroundMask: array of TBytes;
  LTileX: Integer;
  LTileY: Integer;
  LTile: SmallInt;
  LPlanar: TBytes;
  LRow: Integer;
  LColumn: Integer;
  LTarget: Integer;
  LSource: Integer;
begin
  if not Assigned(AMap) then
    raise EArgumentNilException.Create('AMap');
  if not Assigned(AGraphics) then
    raise EArgumentNilException.Create('AGraphics');
  Result.Width := AMap.Width * KEEN_TILE16_SIZE;
  Result.Height := AMap.Height * KEEN_TILE16_SIZE;
  SetLength(Result.Pixels, Result.Width * Result.Height);
  SetLength(LBackground, KEEN_NUMTILE16);
  SetLength(LForeground, KEEN_NUMTILE16M);
  SetLength(LForegroundMask, KEEN_NUMTILE16M);

  for LTileY := 0 to AMap.Height - 1 do
    for LTileX := 0 to AMap.Width - 1 do
    begin
      LTile := SmallInt(AMap.GetTile(0, LTileX, LTileY));
      if LTile >= KEEN_NUMTILE16 then
        raise EKeenDataException.CreateFmt(SKeenTileInvalid, [LTile, KEEN_NUMTILE16]);
      if LTile >= 0 then
      begin
        if Length(LBackground[LTile].Pixels) = 0 then
        begin
          LPlanar := AGraphics.Tile16(LTile);
          if Length(LPlanar) > 0 then
            LBackground[LTile] := TKeenPlanarConverter.ToChunky(LPlanar, 0, 2, KEEN_TILE16_SIZE);
        end;
        if Length(LBackground[LTile].Pixels) > 0 then
          for LRow := 0 to KEEN_TILE16_SIZE - 1 do
            Move(LBackground[LTile].Pixels[LRow * KEEN_TILE16_SIZE],
              Result.Pixels[(LTileY * KEEN_TILE16_SIZE + LRow) * Result.Width + LTileX * KEEN_TILE16_SIZE],
              KEEN_TILE16_SIZE);
      end;
    end;

  for LTileY := 0 to AMap.Height - 1 do
    for LTileX := 0 to AMap.Width - 1 do
    begin
      LTile := SmallInt(AMap.GetTile(1, LTileX, LTileY));
      if LTile >= KEEN_NUMTILE16M then
        raise EKeenDataException.CreateFmt(SKeenTileInvalid, [LTile, KEEN_NUMTILE16M]);
      if LTile > 0 then
      begin
        if Length(LForeground[LTile].Pixels) = 0 then
        begin
          LPlanar := AGraphics.Tile16Masked(LTile);
          if Length(LPlanar) > 0 then
            LForeground[LTile] := TKeenPlanarConverter.ToChunkyMasked(LPlanar, 0, 2, KEEN_TILE16_SIZE,
              LForegroundMask[LTile]);
        end;
        if Length(LForeground[LTile].Pixels) > 0 then
          for LRow := 0 to KEEN_TILE16_SIZE - 1 do
            for LColumn := 0 to KEEN_TILE16_SIZE - 1 do
            begin
              LSource := LRow * KEEN_TILE16_SIZE + LColumn;
              LTarget := (LTileY * KEEN_TILE16_SIZE + LRow) * Result.Width + LTileX * KEEN_TILE16_SIZE + LColumn;
              Result.Pixels[LTarget] := (Result.Pixels[LTarget] and LForegroundMask[LTile][LSource]) or
                LForeground[LTile].Pixels[LSource];
            end;
      end;
    end;
end;

end.
