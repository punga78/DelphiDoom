{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixSpriteList                                }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of MakeNonRotatingSprite, MakeRotatingSprite8, MakeRotatingSprite16    }
{  and MakeOneSprite of GenerateSprites (radix_xlat_wad.pas)                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.SpriteList;

interface

uses
  System.SysUtils, System.Generics.Collections;

const
  /// <summary>The offset the Make* functions take to say "not given"</summary>
  RADIX_SPRITE_NO_OFFSET = -255;

type
  /// <summary>A sprite of the WAD and the bitmap of Radix it is made from</summary>
  TRadixSpriteInfo = record
    /// <summary>The name of the bitmap in ObjectBitmaps (at most 32 characters)</summary>
    BitmapName: string;
    /// <summary>The name of the lump (at most 8 characters)</summary>
    LumpName: string;
    OffsetX: Integer;
    OffsetY: Integer;
    CenterOffsets: Boolean;
    DefaultOffsets: Boolean;
  end;

  /// <summary>The list of the sprites that the translator makes, in order</summary>
  TRadixSpriteList = class
  strict private
    FItems: TList<TRadixSpriteInfo>;
    function GetCount: Integer;
    function GetItem(AIndex: Integer): TRadixSpriteInfo;
    /// <summary>get_sprite_name: the 4 characters of the lump of a thing</summary>
    function SpriteName(AThing: Integer): string;
    procedure Add(const ABitmapName, ALumpName: string; AOffsetX, AOffsetY: Integer;
      ACenter, ADefault: Boolean);
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>MakeNonRotatingSprite: frames "prefix_1", "prefix_2".. as A0, B0..</summary>
    procedure AddNonRotating(const APrefix: string; AThing, AFrames: Integer;
      AOffsetX: Integer = RADIX_SPRITE_NO_OFFSET; AOffsetY: Integer = RADIX_SPRITE_NO_OFFSET;
      ACenter: Boolean = True; ADefault: Boolean = True; AStartFrame: Char = 'A');
    /// <summary>MakeRotatingSprite8: eight angles for each frame</summary>
    procedure AddRotating8(const APrefix: string; AThing, AFrames: Integer;
      AOffsetX: Integer = RADIX_SPRITE_NO_OFFSET; AOffsetY: Integer = RADIX_SPRITE_NO_OFFSET;
      ACenter: Boolean = True; ADefault: Boolean = True; AStartFrame: Char = 'A');
    /// <summary>MakeRotatingSprite16: sixteen angles (1, 9, 2, A, 3, B..) for each frame</summary>
    /// <param name="AMask">Only the angle with this number (1..16); -1 for all</param>
    procedure AddRotating16(const APrefix: string; AThing, AFrames: Integer;
      AOffsetX: Integer = RADIX_SPRITE_NO_OFFSET; AOffsetY: Integer = RADIX_SPRITE_NO_OFFSET;
      ACenter: Boolean = True; ADefault: Boolean = True; AMask: Integer = -1;
      AStartFrame: Char = 'A');
    /// <summary>MakeOneSprite</summary>
    procedure AddOne(const ABitmapName: string; AThing: Integer;
      AOffsetX: Integer = RADIX_SPRITE_NO_OFFSET; AOffsetY: Integer = RADIX_SPRITE_NO_OFFSET;
      ACenter: Boolean = True; ADefault: Boolean = True; AFrame: Char = 'A';
      AAngle: Char = '0'; const AExtraFrame: string = '');
    property Count: Integer read GetCount;
    property Items[AIndex: Integer]: TRadixSpriteInfo read GetItem; default;
  end;

implementation

uses
  DelphiDoom.Radix.Things;

const
  Sprite16Angles = '192A3B4C5D6E7F8G';
  ExtraSpriteNames: array[0..5] of string = ('EXPB', 'EXPS', 'SMOB', 'SMOS', 'PUFF', 'PLAY');

{ TRadixSpriteList }

constructor TRadixSpriteList.Create;
begin
  inherited Create;
  FItems := TList<TRadixSpriteInfo>.Create;
end;

destructor TRadixSpriteList.Destroy;
begin
  FItems.Free;
  inherited Destroy;
end;

function TRadixSpriteList.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TRadixSpriteList.GetItem(AIndex: Integer): TRadixSpriteInfo;
begin
  Result := FItems[AIndex];
end;

function TRadixSpriteList.SpriteName(AThing: Integer): string;
begin
  if AThing <= MTRX_RADIXMAXEDITORTHING then
    Result := 'XR' + Format('%.2d', [AThing])
  else if AThing < DOOM_THING_2_RADIX then
    Result := 'X' + Format('%.3d', [AThing])
  else if AThing < DOOM_THING_2_RADIX + Length(ExtraSpriteNames) then
    Result := ExtraSpriteNames[AThing - DOOM_THING_2_RADIX]
  else
    Result := Format('%.4d', [AThing]);
end;

procedure TRadixSpriteList.Add(const ABitmapName, ALumpName: string; AOffsetX, AOffsetY: Integer;
  ACenter, ADefault: Boolean);
var
  LInfo: TRadixSpriteInfo;
begin
  // the old record had a string[32] and a string[8]: a longer name was cut
  LInfo.BitmapName := Copy(ABitmapName, 1, 32);
  LInfo.LumpName := Copy(ALumpName, 1, 8);
  LInfo.OffsetX := AOffsetX;
  LInfo.OffsetY := AOffsetY;
  LInfo.CenterOffsets := ACenter;
  LInfo.DefaultOffsets := ADefault;
  FItems.Add(LInfo);
end;

procedure TRadixSpriteList.AddNonRotating(const APrefix: string; AThing, AFrames: Integer;
  AOffsetX, AOffsetY: Integer; ACenter, ADefault: Boolean; AStartFrame: Char);
var
  LFrame: Integer;
begin
  for LFrame := 1 to AFrames do
    Add(APrefix + '_' + IntToStr(LFrame),
      SpriteName(AThing) + Chr(Ord(AStartFrame) + LFrame - 1) + '0',
      AOffsetX, AOffsetY, ACenter, ADefault);
end;

procedure TRadixSpriteList.AddRotating8(const APrefix: string; AThing, AFrames: Integer;
  AOffsetX, AOffsetY: Integer; ACenter, ADefault: Boolean; AStartFrame: Char);
var
  LFrame: Integer;
  LAngle: Integer;
begin
  for LFrame := 1 to AFrames do
    for LAngle := 1 to 8 do
      Add(APrefix + '_' + IntToStr(LAngle + (LFrame - 1) * 8),
        SpriteName(AThing) + Chr(Ord(AStartFrame) + LFrame - 1) + IntToStr(LAngle),
        AOffsetX, AOffsetY, ACenter, ADefault);
end;

procedure TRadixSpriteList.AddRotating16(const APrefix: string; AThing, AFrames: Integer;
  AOffsetX, AOffsetY: Integer; ACenter, ADefault: Boolean; AMask: Integer; AStartFrame: Char);
var
  LFrame: Integer;
  LAngle: Integer;
begin
  for LFrame := 1 to AFrames do
    for LAngle := 1 to 16 do
      if (AMask = -1) or (LAngle = AMask) then
        Add(APrefix + '_' + IntToStr(LAngle + (LFrame - 1) * 16),
          SpriteName(AThing) + Chr(Ord(AStartFrame) + LFrame - 1) + Sprite16Angles[LAngle],
          AOffsetX, AOffsetY, ACenter, ADefault);
end;

procedure TRadixSpriteList.AddOne(const ABitmapName: string; AThing: Integer;
  AOffsetX, AOffsetY: Integer; ACenter, ADefault: Boolean; AFrame, AAngle: Char;
  const AExtraFrame: string);
begin
  Add(ABitmapName, SpriteName(AThing) + AFrame + AAngle + AExtraFrame, AOffsetX, AOffsetY,
    ACenter, ADefault);
end;

end.
