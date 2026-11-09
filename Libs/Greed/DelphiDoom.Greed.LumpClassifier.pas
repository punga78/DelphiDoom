{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - what a lump is                                   }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): r_public.pas, d_disk.pas    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.LumpClassifier;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf;

type
  /// <summary>
  ///   The sprites, flats and walls are the lumps between the markers startsprites/endsprites,
  ///   startflats/endflats and startwalls/endwalls (the game finds them like that); "palette" is the palette; any
  ///   other lump is a picture if its size is the 8 bytes of the header plus width * height, and nothing else
  ///   if not (the fonts, the sounds, the scripts, the markers)
  /// </summary>
  TGreedLumpClassifier = class(TInterfacedObject, IGreedLumpClassifier)
  strict private
    FArchive: IGreedArchive;
    FPalette: Integer;
    FSpritesFirst: Integer;
    FSpritesLast: Integer;
    FFlatsFirst: Integer;
    FFlatsLast: Integer;
    FWallsFirst: Integer;
    FWallsLast: Integer;
    function IsInside(AIndex, AFirst, ALast: Integer): Boolean;
  public
    constructor Create(const AArchive: IGreedArchive);
    function Classify(AIndex: Integer): TGreedLumpKind;
    function DecoderOf(AKind: TGreedLumpKind): IGreedImageDecoder;
  end;

implementation

uses
  DelphiDoom.Greed.PictureDecoder, DelphiDoom.Greed.FlatDecoder, DelphiDoom.Greed.WallDecoder,
  DelphiDoom.Greed.SpriteDecoder;

{ TGreedLumpClassifier }

constructor TGreedLumpClassifier.Create(const AArchive: IGreedArchive);
begin
  inherited Create;
  if not Assigned(AArchive) then
    raise EArgumentNilException.Create('AArchive');
  FArchive := AArchive;
  FPalette := FArchive.IndexOf(GREED_LUMP_PALETTE);
  FSpritesFirst := FArchive.IndexOf(GREED_LUMP_START_SPRITES);
  FSpritesLast := FArchive.IndexOf(GREED_LUMP_END_SPRITES);
  FFlatsFirst := FArchive.IndexOf(GREED_LUMP_START_FLATS);
  FFlatsLast := FArchive.IndexOf(GREED_LUMP_END_FLATS);
  FWallsFirst := FArchive.IndexOf(GREED_LUMP_START_WALLS);
  FWallsLast := FArchive.IndexOf(GREED_LUMP_END_WALLS);
end;

function TGreedLumpClassifier.IsInside(AIndex, AFirst, ALast: Integer): Boolean;
begin
  Result := (AFirst >= 0) and (ALast > AFirst) and (AIndex > AFirst) and (AIndex < ALast);
end;

function TGreedLumpClassifier.Classify(AIndex: Integer): TGreedLumpKind;
var
  LBytes: TBytes;
  LWidth: Integer;
  LHeight: Integer;
begin
  Result := glkOther;
  if FArchive.GetLumpSize(AIndex) = 0 then
    Exit;
  if AIndex = FPalette then
    Exit(glkPalette);
  if IsInside(AIndex, FWallsFirst, FWallsLast) then
    Exit(glkWall);
  if IsInside(AIndex, FFlatsFirst, FFlatsLast) then
    Exit(glkFlat);
  if IsInside(AIndex, FSpritesFirst, FSpritesLast) then
    Exit(glkSprite);
  if FArchive.GetLumpSize(AIndex) < GREED_PICTURE_HEADER_BYTES then
    Exit;
  LBytes := FArchive.ReadLump(AIndex);
  LWidth := SmallInt(Word(LBytes[0]) or (Word(LBytes[1]) shl 8));
  LHeight := SmallInt(Word(LBytes[2]) or (Word(LBytes[3]) shl 8));
  if (LWidth > 0) and (LHeight > 0) and (GREED_PICTURE_HEADER_BYTES + LWidth * LHeight = Length(LBytes)) then
    Result := glkPicture;
end;

function TGreedLumpClassifier.DecoderOf(AKind: TGreedLumpKind): IGreedImageDecoder;
begin
  case AKind of
    glkPicture:
      Result := TGreedPictureDecoder.Create;
    glkFlat:
      Result := TGreedFlatDecoder.Create;
    glkWall:
      Result := TGreedWallDecoder.Create;
    glkSprite:
      Result := TGreedSpriteDecoder.Create;
  else
    Result := nil;
  end;
end;

end.
