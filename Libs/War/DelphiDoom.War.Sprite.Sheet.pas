{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the sprites of the drawing                        }
{                                                                              }
{  Port of war1 (acoto87/war1), war_sprites.c (WarSprite: wspr_createSprite,   }
{  wspr_createSpriteFromFrames, wspr_createSpriteFromResource,                 }
{  wspr_getSpriteFrame, wspr_renderSprite, wspr_renderSubSprite), (c) 2019     }
{  Alejandro Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt).     }
{  This is an altered version, not the original.                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Sprite.Sheet;

{$R-}
{$Q-}

interface

uses
  System.SysUtils, DelphiDoom.War.Types, DelphiDoom.War.Graphics.Types, DelphiDoom.War.Render.Types,
  DelphiDoom.War.Render.Transform;

const
  /// <summary>MAX_SPRITE_FRAME_COUNT of war.h: the most frames of a WarSprite</summary>
  WAR_MAX_SPRITE_FRAMES = 100;

type
  /// <summary>
  ///   A WarSprite as pixels: frames that share the size of their area, each one RGBA bytes of the whole area (the
  ///   frame is drawn at its place, the rest is transparent). Made from an image, a cursor or the frames of a sprite
  ///   record, all of them or a list of them in the order the caller wants; the pixels are copied. The color of a
  ///   drawing (the tint) and the flip are the ones of TWarRenderTransform: the remake has no table of colors per player
  /// </summary>
  TWarSpriteSheet = class
  strict private
    FFrameWidth: Integer;
    FFrameHeight: Integer;
    FFrames: TArray<TWarSpriteFrame>;
    function GetFrameCount: Integer;
    constructor Create(AFrameWidth, AFrameHeight: Integer; const AFrames: TArray<TWarSpriteFrame>);
  public
    /// <summary>wspr_createSprite: one frame, the whole image</summary>
    class function FromImage(const AImage: TWarImage): TWarSpriteSheet; static;
    /// <summary>wspr_createSprite for the pixels of a cursor</summary>
    class function FromCursor(const ACursor: TWarCursor): TWarSpriteSheet; static;
    /// <summary>
    ///   wspr_createSpriteFromResource of a sprite record: all the frames, or only those in AFrameIndices in that order
    ///   (an index outside the record is EWarException; the original asserts). A WarSprite holds at most 100 frames
    /// </summary>
    class function FromSprite(const ASprite: TWarSprite; const AFrameIndices: TArray<Integer>): TWarSpriteSheet; static;
    /// <summary>wspr_getSpriteFrame; EWarException if the frame is not there</summary>
    function GetFrame(AIndex: Integer): TWarSpriteFrame;
    /// <summary>wspr_renderSprite: the whole area at the position, scaled; one blit</summary>
    procedure Render(const ATransform: TWarRenderTransform; APositionX, APositionY, AScaleX, AScaleY: Single);
    /// <summary>wspr_renderSubSprite: a part of the area to a rectangle, scaled; one blit</summary>
    procedure RenderPart(const ATransform: TWarRenderTransform; const ASource, ADestination: TWarRectF;
      AScaleX, AScaleY: Single);
    property FrameWidth: Integer read FFrameWidth;
    property FrameHeight: Integer read FFrameHeight;
    property FrameCount: Integer read GetFrameCount;
  end;

resourcestring
  SWarSpriteFrameIndex = 'The frame %d is not in the sprite, that has %d';
  SWarSpriteTooManyFrames = 'A sprite holds at most %d frames, %d were asked';
  SWarSpriteImageTooLarge = 'The image is %d x %d pixels, a sprite is at most 65535 in each side';
  SWarSpritePixels = 'The frame %d has %d bytes, %d are needed';

implementation

{ TWarSpriteSheet }

constructor TWarSpriteSheet.Create(AFrameWidth, AFrameHeight: Integer; const AFrames: TArray<TWarSpriteFrame>);
begin
  inherited Create;
  FFrameWidth := AFrameWidth;
  FFrameHeight := AFrameHeight;
  FFrames := AFrames;
end;

function TWarSpriteSheet.GetFrameCount: Integer;
begin
  Result := Length(FFrames);
end;

class function TWarSpriteSheet.FromImage(const AImage: TWarImage): TWarSpriteSheet;
var
  LFrames: TArray<TWarSpriteFrame>;
  LNeeded: Integer;
begin
  LNeeded := AImage.Width * AImage.Height * WAR_PIXEL_SIZE;
  if Length(AImage.Pixels) < LNeeded then
    raise EWarException.CreateFmt(SWarSpritePixels, [0, Length(AImage.Pixels), LNeeded]);
  SetLength(LFrames, 1);
  LFrames[0].Dx := 0;
  LFrames[0].Dy := 0;
  LFrames[0].Width := AImage.Width;
  LFrames[0].Height := AImage.Height;
  LFrames[0].Offset := 0;
  LFrames[0].Pixels := Copy(AImage.Pixels, 0, LNeeded);
  Result := TWarSpriteSheet.Create(AImage.Width, AImage.Height, LFrames);
end;

class function TWarSpriteSheet.FromCursor(const ACursor: TWarCursor): TWarSpriteSheet;
var
  LImage: TWarImage;
begin
  LImage.Width := ACursor.Width;
  LImage.Height := ACursor.Height;
  LImage.Pixels := ACursor.Pixels;
  Result := FromImage(LImage);
end;

class function TWarSpriteSheet.FromSprite(const ASprite: TWarSprite; const AFrameIndices: TArray<Integer>): TWarSpriteSheet;
var
  LFrames: TArray<TWarSpriteFrame>;
  LCount: Integer;
  LIndex: Integer;
  LSource: Integer;
  LNeeded: Integer;
begin
  if Length(AFrameIndices) > 0 then
    LCount := Length(AFrameIndices)
  else
    LCount := Length(ASprite.Frames);
  if LCount > WAR_MAX_SPRITE_FRAMES then
    raise EWarException.CreateFmt(SWarSpriteTooManyFrames, [WAR_MAX_SPRITE_FRAMES, LCount]);
  LNeeded := ASprite.FrameWidth * ASprite.FrameHeight * WAR_PIXEL_SIZE;
  SetLength(LFrames, LCount);
  for LIndex := 0 to LCount - 1 do
  begin
    if Length(AFrameIndices) > 0 then
      LSource := AFrameIndices[LIndex]
    else
      LSource := LIndex;
    if (LSource < 0) or (LSource >= Length(ASprite.Frames)) then
      raise EWarException.CreateFmt(SWarSpriteFrameIndex, [LSource, Length(ASprite.Frames)]);
    if Length(ASprite.Frames[LSource].Pixels) < LNeeded then
      raise EWarException.CreateFmt(SWarSpritePixels, [LSource, Length(ASprite.Frames[LSource].Pixels), LNeeded]);
    LFrames[LIndex] := ASprite.Frames[LSource];
    // wspr_createSpriteFromFrames: the offset of the pixels in the record is not kept
    LFrames[LIndex].Offset := 0;
    LFrames[LIndex].Pixels := Copy(ASprite.Frames[LSource].Pixels, 0, LNeeded);
  end;
  Result := TWarSpriteSheet.Create(ASprite.FrameWidth, ASprite.FrameHeight, LFrames);
end;

function TWarSpriteSheet.GetFrame(AIndex: Integer): TWarSpriteFrame;
begin
  if (AIndex < 0) or (AIndex >= Length(FFrames)) then
    raise EWarException.CreateFmt(SWarSpriteFrameIndex, [AIndex, Length(FFrames)]);
  Result := FFrames[AIndex];
end;

procedure TWarSpriteSheet.Render(const ATransform: TWarRenderTransform; APositionX, APositionY, AScaleX, AScaleY: Single);
var
  LSource: TWarRectF;
  LDestination: TWarRectF;
begin
  LSource.X := 0;
  LSource.Y := 0;
  LSource.Width := FFrameWidth;
  LSource.Height := FFrameHeight;
  LDestination.X := APositionX;
  LDestination.Y := APositionY;
  LDestination.Width := FFrameWidth;
  LDestination.Height := FFrameHeight;
  ATransform.SubImage(LSource, LDestination, AScaleX, AScaleY);
end;

procedure TWarSpriteSheet.RenderPart(const ATransform: TWarRenderTransform; const ASource, ADestination: TWarRectF;
  AScaleX, AScaleY: Single);
begin
  ATransform.SubImage(ASource, ADestination, AScaleX, AScaleY);
end;

end.
