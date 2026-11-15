{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the images that the map draws                     }
{                                                                              }
{  Port of war1 (acoto87/war1), war_map.c (createMapAndMinimapSprites,          }
{  initBlackSprite) and the sprites of the entities, (c) 2019 Alejandro Coto    }
{  Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an altered  }
{  version, not the original.                                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.MapUi.Sprites;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.War.Graphics.Types, DelphiDoom.War.Ui.Intf;

type
  /// <summary>
  ///   What the map draws from: the image of the tileset (512 x 256), the black tile of the fog (16 x 16), the image of
  ///   the minimap (64 x 64, filled again each frame) and the sprites of the units and the effects, made once per
  ///   record of DATA.WAR. The original made a sprite (and a texture) for each entity: a texture is filled with the
  ///   frame just before every blit, so a shared sprite draws the same pixels
  /// </summary>
  TWarMapSprites = class
  strict private
    FSource: IWarUiSprites;
    FSprites: TDictionary<Integer, IWarUiSprite>;
    FTileset: TWarImage;
    FBlack: TWarImage;
    FMinimap: TWarImage;
  public
    /// <summary>ATilesetPixels is the image of the tileset of the level (TWarTileset.Pixels, 512 x 256 x 4 bytes)</summary>
    constructor Create(const ASource: IWarUiSprites; const ATilesetPixels: TBytes);
    destructor Destroy; override;
    /// <summary>The sprite of a record of DATA.WAR (an image, a sprite or a cursor); the same object each time</summary>
    function Get(AResourceIndex: Integer): IWarUiSprite;
    /// <summary>map->sprite</summary>
    property Tileset: TWarImage read FTileset;
    /// <summary>map->blackSprite</summary>
    property Black: TWarImage read FBlack;
    /// <summary>map->minimapSprite</summary>
    property Minimap: TWarImage read FMinimap;
    /// <summary>wspr_updateSpriteImage of the minimap: the pixels of the frame that is drawn next (shared, not copied)</summary>
    procedure SetMinimapPixels(const APixels: TBytes);
  end;

implementation

uses
  DelphiDoom.War.Map.Types;

{ TWarMapSprites }

constructor TWarMapSprites.Create(const ASource: IWarUiSprites; const ATilesetPixels: TBytes);
var
  LIndex: Integer;
begin
  inherited Create;
  FSource := ASource;
  FSprites := TDictionary<Integer, IWarUiSprite>.Create;
  FTileset.Width := WAR_TILESET_WIDTH;
  FTileset.Height := WAR_TILESET_HEIGHT;
  FTileset.Pixels := ATilesetPixels;
  FBlack.Width := WAR_MEGA_TILE_SIZE;
  FBlack.Height := WAR_MEGA_TILE_SIZE;
  SetLength(FBlack.Pixels, WAR_MEGA_TILE_SIZE * WAR_MEGA_TILE_SIZE * 4);
  for LIndex := 0 to WAR_MEGA_TILE_SIZE * WAR_MEGA_TILE_SIZE - 1 do
    FBlack.Pixels[LIndex * 4 + 3] := 255;
  FMinimap.Width := WAR_MINIMAP_SIZE;
  FMinimap.Height := WAR_MINIMAP_SIZE;
end;

destructor TWarMapSprites.Destroy;
begin
  FSprites.Free;
  FSource := nil;
  inherited Destroy;
end;

procedure TWarMapSprites.SetMinimapPixels(const APixels: TBytes);
begin
  FMinimap.Pixels := APixels;
end;

function TWarMapSprites.Get(AResourceIndex: Integer): IWarUiSprite;
begin
  if not FSprites.TryGetValue(AResourceIndex, Result) then
  begin
    Result := FSource.CreateSprite(AResourceIndex);
    FSprites.Add(AResourceIndex, Result);
  end;
end;

end.
