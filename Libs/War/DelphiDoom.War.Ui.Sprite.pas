{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - a sprite with its texture                         }
{                                                                              }
{  Port of war1 (acoto87/war1), war_sprites.c (WarSprite with its SDL_Texture: }
{  wspr_updateSpriteImage, wspr_getSpriteFrame), (c) 2019 Alejandro Coto       }
{  Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an altered  }
{  version, not the original.                                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Ui.Sprite;

{$R-}
{$Q-}

interface

uses
  System.SysUtils, DelphiDoom.War.Graphics.Types, DelphiDoom.War.Render.Types, DelphiDoom.War.Render.Transform,
  DelphiDoom.War.Sprite.Sheet, DelphiDoom.War.Ui.Intf;

type
  /// <summary>
  ///   The frames of a TWarSpriteSheet and one texture of the size of a frame. As in the original (the texture of
  ///   wspr_createSpriteFromFrames is never filled) the texture is transparent until UpdateImage puts a frame in it.
  ///   The pixels of a frame are shared with the texture, not copied
  /// </summary>
  TWarUiSprite = class(TInterfacedObject, IWarUiSprite)
  strict private
    FSheet: TWarSpriteSheet;
    FTexture: TWarImage;
  public
    /// <summary>The sprite owns the sheet; APreload puts the frame 0 in the texture (an image or a cursor)</summary>
    constructor Create(const ASheet: TWarSpriteSheet; APreload: Boolean);
    destructor Destroy; override;
    function GetFrameWidth: Integer;
    function GetFrameHeight: Integer;
    function GetFrameCount: Integer;
    function GetTexture: TWarImage;
    function GetFrame(AIndex: Integer): TWarSpriteFrame;
    procedure UpdateImage(AFrameIndex: Integer);
    /// <summary>
    ///   wspr_renderSprite(sprite, VEC2_ZERO, VEC2_ONE): the whole frame at the origin of the transform, one blit from
    ///   the texture of the sprite
    /// </summary>
    class procedure Draw(const ATransform: TWarRenderTransform; const ASprite: IWarUiSprite); static;
  end;

implementation

{ TWarUiSprite }

constructor TWarUiSprite.Create(const ASheet: TWarSpriteSheet; APreload: Boolean);
begin
  inherited Create;
  FSheet := ASheet;
  FTexture.Width := ASheet.FrameWidth;
  FTexture.Height := ASheet.FrameHeight;
  // SDL_CreateSurface clears the pixels
  SetLength(FTexture.Pixels, ASheet.FrameWidth * ASheet.FrameHeight * WAR_PIXEL_SIZE);
  if Length(FTexture.Pixels) > 0 then
    FillChar(FTexture.Pixels[0], Length(FTexture.Pixels), 0);
  // wspr_createSprite (an image or a cursor) fills the texture with its pixels; the frames of a sprite record do not
  if APreload and (ASheet.FrameCount > 0) then
    UpdateImage(0);
end;

destructor TWarUiSprite.Destroy;
begin
  FSheet.Free;
  inherited Destroy;
end;

function TWarUiSprite.GetFrameWidth: Integer;
begin
  Result := FSheet.FrameWidth;
end;

function TWarUiSprite.GetFrameHeight: Integer;
begin
  Result := FSheet.FrameHeight;
end;

function TWarUiSprite.GetFrameCount: Integer;
begin
  Result := FSheet.FrameCount;
end;

function TWarUiSprite.GetTexture: TWarImage;
begin
  Result := FTexture;
end;

function TWarUiSprite.GetFrame(AIndex: Integer): TWarSpriteFrame;
begin
  Result := FSheet.GetFrame(AIndex);
end;

procedure TWarUiSprite.UpdateImage(AFrameIndex: Integer);
begin
  FTexture.Pixels := FSheet.GetFrame(AFrameIndex).Pixels;
end;

class procedure TWarUiSprite.Draw(const ATransform: TWarRenderTransform; const ASprite: IWarUiSprite);
var
  LSource: TWarRectF;
begin
  LSource.X := 0;
  LSource.Y := 0;
  LSource.Width := ASprite.FrameWidth;
  LSource.Height := ASprite.FrameHeight;
  ATransform.SetTexture(ASprite.Texture);
  ATransform.SubImage(LSource, LSource, 1, 1);
  ATransform.ClearTexture;
end;

end.
