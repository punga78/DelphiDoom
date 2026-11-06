{******************************************************************************}
{                                                                              }
{  DelphiDoom: texture definitions library - the lumps TEXTURE1, 2 and 3       }
{  Copyright (C) 2004-2023 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.TextureDefs.TextureLumpReader;

interface

uses
  System.SysUtils, DelphiDoom.TextureDefs.Intf, DelphiDoom.TextureDefs.Types;

type
  /// <summary>
  ///   A lump TEXTUREx: a 32 bit count, then that many 32 bit offsets (from the start of the
  ///   lump), then the textures at those offsets. Each one is a header and its patches (the
  ///   layout is the one of the game). Every patch has to name an entry of PNAMES. The old code
  ///   only checked that an offset was not past the end: here a texture has to fit entirely in
  ///   the lump, a negative count of patches is wrong and so is an index outside PNAMES
  /// </summary>
  TTextureDefsTextureLumpReader = class(TInterfacedObject, ITextureDefsTextureLumpReader)
  strict private
    FFormat: TTextureDefsFormat;
    function HeaderSize: Integer;
    function PatchSize: Integer;
  public
    constructor Create(AFormat: TTextureDefsFormat);
    function Read(const ABytes: TBytes; AOrigin: TTextureDefsOrigin;
      const APatchNames: TArray<string>): TArray<TTextureDefsTexture>;
  end;

implementation

uses
  DelphiDoom.TextureDefs.Names;

const
  SLumpTooShort = 'TEXTURE: the lump is too short for the count of textures';
  SBadTextureDirectory = 'TEXTURE: bad texture directory (texture %d does not fit the lump)';
  SBadPatchIndex = 'TEXTURE: the texture %s names the patch %d, that is not in PNAMES';

{ TTextureDefsTextureLumpReader }

constructor TTextureDefsTextureLumpReader.Create(AFormat: TTextureDefsFormat);
begin
  inherited Create;
  FFormat := AFormat;
end;

function TTextureDefsTextureLumpReader.HeaderSize: Integer;
begin
  if FFormat = TTextureDefsFormat.Strife then
    Result := TEXTUREDEFS_HEADER_SIZE_STRIFE
  else
    Result := TEXTUREDEFS_HEADER_SIZE_STANDARD;
end;

function TTextureDefsTextureLumpReader.PatchSize: Integer;
begin
  if FFormat = TTextureDefsFormat.Strife then
    Result := TEXTUREDEFS_PATCH_SIZE_STRIFE
  else
    Result := TEXTUREDEFS_PATCH_SIZE_STANDARD;
end;

function TTextureDefsTextureLumpReader.Read(const ABytes: TBytes; AOrigin: TTextureDefsOrigin;
  const APatchNames: TArray<string>): TArray<TTextureDefsTexture>;
var
  LCount: Integer;
  LIndex: Integer;
  LPatchIndex: Integer;
  LOffset: Integer;
  LPatchCount: Integer;
  LPatchOffset: Integer;
  LStandardHeader: TTextureDefsMapTextureStandard;
  LStrifeHeader: TTextureDefsMapTextureStrife;
  LStandardPatch: TTextureDefsMapPatchStandard;
  LStrifePatch: TTextureDefsMapPatchStrife;
  LTexture: TTextureDefsTexture;
  LPatch: TTextureDefsPatch;
  LRawIndex: Integer;
begin
  if Length(ABytes) < SizeOf(Integer) then
    raise ETextureDefsException.Create(TTextureDefsError.TruncatedLump, SLumpTooShort);
  Move(ABytes[0], LCount, SizeOf(Integer));
  if (LCount < 0) or (Int64(SizeOf(Integer)) * (Int64(LCount) + 1) > Length(ABytes)) then
    raise ETextureDefsException.Create(TTextureDefsError.TruncatedLump, SLumpTooShort);

  SetLength(Result, LCount);
  for LIndex := 0 to LCount - 1 do
  begin
    Move(ABytes[SizeOf(Integer) * (LIndex + 1)], LOffset, SizeOf(Integer));
    if (LOffset < 0) or (Int64(LOffset) + HeaderSize > Length(ABytes)) then
      raise ETextureDefsException.Create(TTextureDefsError.BadDirectory,
        Format(SBadTextureDirectory, [LIndex]));

    LTexture := Default(TTextureDefsTexture);
    LTexture.Origin := AOrigin;
    if FFormat = TTextureDefsFormat.Strife then
    begin
      Move(ABytes[LOffset], LStrifeHeader, SizeOf(LStrifeHeader));
      LTexture.Name := TTextureDefsNames.Decode(ABytes, LOffset);
      LTexture.Masked := LStrifeHeader.Masked;
      LTexture.Width := LStrifeHeader.Width;
      LTexture.Height := LStrifeHeader.Height;
      LPatchCount := LStrifeHeader.PatchCount;
    end
    else
    begin
      Move(ABytes[LOffset], LStandardHeader, SizeOf(LStandardHeader));
      LTexture.Name := TTextureDefsNames.Decode(ABytes, LOffset);
      LTexture.Masked := LStandardHeader.Masked;
      LTexture.Width := LStandardHeader.Width;
      LTexture.Height := LStandardHeader.Height;
      LPatchCount := LStandardHeader.PatchCount;
    end;

    if (LPatchCount < 0) or
      (Int64(LOffset) + HeaderSize + Int64(LPatchCount) * PatchSize > Length(ABytes)) then
      raise ETextureDefsException.Create(TTextureDefsError.BadDirectory,
        Format(SBadTextureDirectory, [LIndex]));

    SetLength(LTexture.Patches, LPatchCount);
    for LPatchIndex := 0 to LPatchCount - 1 do
    begin
      LPatchOffset := LOffset + HeaderSize + LPatchIndex * PatchSize;
      LPatch := Default(TTextureDefsPatch);
      if FFormat = TTextureDefsFormat.Strife then
      begin
        Move(ABytes[LPatchOffset], LStrifePatch, SizeOf(LStrifePatch));
        LPatch.OriginX := LStrifePatch.OriginX;
        LPatch.OriginY := LStrifePatch.OriginY;
        LRawIndex := LStrifePatch.PatchIndex;
      end
      else
      begin
        Move(ABytes[LPatchOffset], LStandardPatch, SizeOf(LStandardPatch));
        LPatch.OriginX := LStandardPatch.OriginX;
        LPatch.OriginY := LStandardPatch.OriginY;
        LRawIndex := LStandardPatch.PatchIndex;
      end;
      if (LRawIndex < 0) or (LRawIndex >= Length(APatchNames)) then
        raise ETextureDefsException.Create(TTextureDefsError.BadPatchIndex,
          Format(SBadPatchIndex, [LTexture.Name, LRawIndex]));
      LPatch.PatchIndex := LRawIndex;
      LPatch.PatchName := APatchNames[LRawIndex];
      LTexture.Patches[LPatchIndex] := LPatch;
    end;
    Result[LIndex] := LTexture;
  end;
end;

end.
