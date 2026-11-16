{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the sprite cache of the immediate interface       }
{                                                                              }
{  Port of war1 (acoto87/war1), war_imui.c (imui_getOrCreateSprite and the     }
{  spriteCache of WarImuiState), (c) 2019 Alejandro Coto Gutierrez, zlib       }
{  License (see Games\War\LICENSE-war1.txt). This is an altered version, not   }
{  the original.                                                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Ui.SpriteCache;

interface

uses
  System.SysUtils, DelphiDoom.War.Ui.Types, DelphiDoom.War.Ui.Intf;

type
  /// <summary>
  ///   Up to 64 sprites for the pairs (record, frame), made at the first request, with the texture of each filled
  ///   with the pixels of its frame. Defects of the original that are kept: a hit does not update lastUsedFrame (only
  ///   an eviction does), so the entry that goes is the first one with the smallest number, not the least recently
  ///   used; and the sprite that arrives after an eviction is returned without being put in a free place. Not kept:
  ///   the evicted sprite is freed in the original even if the caller still holds it (here the reference count keeps it)
  /// </summary>
  TWarUiSpriteCache = class
  strict private
    type
      TEntry = record
        ResourceIndex: Integer;
        FrameIndex: Integer;
        LastUsedFrame: Integer;
        Sprite: IWarUiSprite;
      end;
  strict private
    FSprites: IWarUiSprites;
    FEntries: array[0..WAR_IMUI_SPRITE_CACHE_SIZE - 1] of TEntry;
    FCount: Integer;
    FEvictions: Integer;
  public
    constructor Create(const ASprites: IWarUiSprites);
    /// <summary>
    ///   imui_getOrCreateSprite: nil for an invalid record (the zero WarSprite); AFrameCount is the frame the game is on
    ///   (what the eviction writes in lastUsedFrame)
    /// </summary>
    function GetOrCreate(AResourceIndex, AFrameIndex, AGameFrame: Integer): IWarUiSprite;
    /// <summary>Sprites in the cache</summary>
    property Count: Integer read FCount;
    /// <summary>How many times a sprite was evicted</summary>
    property Evictions: Integer read FEvictions;
  end;

implementation

{ TWarUiSpriteCache }

constructor TWarUiSpriteCache.Create(const ASprites: IWarUiSprites);
begin
  inherited Create;
  FSprites := ASprites;
end;

function TWarUiSpriteCache.GetOrCreate(AResourceIndex, AFrameIndex, AGameFrame: Integer): IWarUiSprite;
var
  LIndex: Integer;
  LLeastUsed: Integer;
  LSprite: IWarUiSprite;
begin
  if AResourceIndex < 0 then
    Exit(nil);
  LLeastUsed := 0;
  for LIndex := 0 to FCount - 1 do
  begin
    if (FEntries[LIndex].ResourceIndex = AResourceIndex) and (FEntries[LIndex].FrameIndex = AFrameIndex) then
      Exit(FEntries[LIndex].Sprite);
    if FEntries[LIndex].LastUsedFrame < FEntries[LLeastUsed].LastUsedFrame then
      LLeastUsed := LIndex;
  end;
  LSprite := FSprites.CreateSprite(AResourceIndex);
  if (AFrameIndex >= 0) and (AFrameIndex < LSprite.FrameCount) then
    LSprite.UpdateImage(AFrameIndex);
  if FCount < WAR_IMUI_SPRITE_CACHE_SIZE then
  begin
    FEntries[FCount].ResourceIndex := AResourceIndex;
    FEntries[FCount].FrameIndex := AFrameIndex;
    FEntries[FCount].LastUsedFrame := 0;
    FEntries[FCount].Sprite := LSprite;
    Inc(FCount);
    Exit(LSprite);
  end;
  Inc(FEvictions);
  FEntries[LLeastUsed].ResourceIndex := AResourceIndex;
  FEntries[LLeastUsed].FrameIndex := AFrameIndex;
  FEntries[LLeastUsed].LastUsedFrame := AGameFrame;
  FEntries[LLeastUsed].Sprite := LSprite;
  Result := LSprite;
end;

end.
