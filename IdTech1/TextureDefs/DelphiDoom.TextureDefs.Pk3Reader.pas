{******************************************************************************}
{                                                                              }
{  DelphiDoom: texture definitions library - TEXTURE0, the textures of a PK3   }
{  Copyright (C) 2004-2023 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.TextureDefs.Pk3Reader;

interface

uses
  System.SysUtils, DelphiDoom.TextureDefs.Intf, DelphiDoom.TextureDefs.Types;

type
  /// <summary>
  ///   The engine turns the pictures of a PK3 into patches and writes the lump TEXTURE0: a
  ///   32 bit count and then that many entries of a header and exactly one patch, one after
  ///   the other (there is no directory of offsets). The picture and the texture have the same
  ///   name, so the patch is the one with the name of the texture: the index of the patch that
  ///   the entry carries is not read. The count of patches of the header is not read either:
  ///   it is always one. This is what the old code did. An entry that does not fit the lump is
  ///   an error
  /// </summary>
  TTextureDefsPk3Reader = class(TInterfacedObject, ITextureDefsPk3Reader)
  strict private
    FFormat: TTextureDefsFormat;
    function HeaderSize: Integer;
    function EntrySize: Integer;
  public
    constructor Create(AFormat: TTextureDefsFormat);
    function Read(const ABytes: TBytes): TArray<TTextureDefsTexture>;
  end;

implementation

uses
  DelphiDoom.TextureDefs.Names;

const
  SPk3LumpTooShort = 'TEXTURE0: the lump is too short for the count of textures';

{ TTextureDefsPk3Reader }

constructor TTextureDefsPk3Reader.Create(AFormat: TTextureDefsFormat);
begin
  inherited Create;
  FFormat := AFormat;
end;

function TTextureDefsPk3Reader.HeaderSize: Integer;
begin
  if FFormat = TTextureDefsFormat.Strife then
    Result := TEXTUREDEFS_HEADER_SIZE_STRIFE
  else
    Result := TEXTUREDEFS_HEADER_SIZE_STANDARD;
end;

function TTextureDefsPk3Reader.EntrySize: Integer;
begin
  if FFormat = TTextureDefsFormat.Strife then
    Result := HeaderSize + TEXTUREDEFS_PATCH_SIZE_STRIFE
  else
    Result := HeaderSize + TEXTUREDEFS_PATCH_SIZE_STANDARD;
end;

function TTextureDefsPk3Reader.Read(const ABytes: TBytes): TArray<TTextureDefsTexture>;
var
  LCount: Integer;
  LIndex: Integer;
  LOffset: Integer;
  LStandardHeader: TTextureDefsMapTextureStandard;
  LStrifeHeader: TTextureDefsMapTextureStrife;
  LStandardPatch: TTextureDefsMapPatchStandard;
  LStrifePatch: TTextureDefsMapPatchStrife;
  LTexture: TTextureDefsTexture;
begin
  if Length(ABytes) < SizeOf(Integer) then
    raise ETextureDefsException.Create(TTextureDefsError.TruncatedLump, SPk3LumpTooShort);
  Move(ABytes[0], LCount, SizeOf(Integer));
  if (LCount < 0) or
    (SizeOf(Integer) + Int64(LCount) * EntrySize > Length(ABytes)) then
    raise ETextureDefsException.Create(TTextureDefsError.TruncatedLump, SPk3LumpTooShort);

  SetLength(Result, LCount);
  for LIndex := 0 to LCount - 1 do
  begin
    LOffset := SizeOf(Integer) + LIndex * EntrySize;
    LTexture := Default(TTextureDefsTexture);
    LTexture.Origin := TTextureDefsOrigin.Pk3;
    LTexture.Name := TTextureDefsNames.Decode(ABytes, LOffset);
    SetLength(LTexture.Patches, 1);
    LTexture.Patches[0].PatchIndex := -1;
    LTexture.Patches[0].PatchName := LTexture.Name;
    if FFormat = TTextureDefsFormat.Strife then
    begin
      Move(ABytes[LOffset], LStrifeHeader, SizeOf(LStrifeHeader));
      Move(ABytes[LOffset + HeaderSize], LStrifePatch, SizeOf(LStrifePatch));
      LTexture.Masked := LStrifeHeader.Masked;
      LTexture.Width := LStrifeHeader.Width;
      LTexture.Height := LStrifeHeader.Height;
      LTexture.Patches[0].OriginX := LStrifePatch.OriginX;
      LTexture.Patches[0].OriginY := LStrifePatch.OriginY;
    end
    else
    begin
      Move(ABytes[LOffset], LStandardHeader, SizeOf(LStandardHeader));
      Move(ABytes[LOffset + HeaderSize], LStandardPatch, SizeOf(LStandardPatch));
      LTexture.Masked := LStandardHeader.Masked;
      LTexture.Width := LStandardHeader.Width;
      LTexture.Height := LStandardHeader.Height;
      LTexture.Patches[0].OriginX := LStandardPatch.OriginX;
      LTexture.Patches[0].OriginY := LStandardPatch.OriginY;
    end;
    Result[LIndex] := LTexture;
  end;
end;

end.
