{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixTexturePart                               }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of GenerateTextures of radix_xlat_wad.pas                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.TexturePart;

interface

uses
  System.SysUtils, System.Classes,
  DelphiDoom.Radix.Types, DelphiDoom.Radix.Context;

type
  /// <summary>
  ///   The wall textures: a patch RDXWnnnn for every bitmap of the lump "WallBitmaps" (and a
  ///   stub, the number 0), three skies of two patches, then TEXTURE0 and PNAMES0 (or TEXTURE1 and
  ///   PNAMES for the Doom names)
  /// </summary>
  TRadixTexturePart = class(TInterfacedObject, IRadixPart)
  strict private
    FPnames: string;
    FTexture: string;
    class procedure WriteName(const AStream: TStream; const AName: string); static;
    class procedure WriteTexture(const AStream: TStream; const AName: string; AWidth, AHeight,
      APatchCount, AFirstPatch: Integer); static;
  public
    /// <param name="APnames">The name of the lump of the patch names (PNAMES0 or PNAMES)</param>
    /// <param name="ATexture">The name of the lump of the textures (TEXTURE0 or TEXTURE1)</param>
    constructor Create(const APnames, ATexture: string);
    procedure Build(const AContext: TRadixTranslationContext);
  end;

implementation

uses
  DelphiDoom.Radix.Container, DelphiDoom.Radix.BitmapTable;

type
  // maptexture_t with one patch: 22 bytes and the patch of 10
  TRadixMapTexture = packed record
    Name: packed array[0..7] of AnsiChar;
    Masked: Integer;
    Width: SmallInt;
    Height: SmallInt;
    Filler: Cardinal;
    PatchCount: SmallInt;
    OriginX: SmallInt;
    OriginY: SmallInt;
    Patch: SmallInt;
    StepDirection: SmallInt;
    ColorMap: SmallInt;
  end;

  TRadixMapPatch = packed record
    OriginX: SmallInt;
    OriginY: SmallInt;
    Patch: SmallInt;
    StepDirection: SmallInt;
    ColorMap: SmallInt;
  end;

const
  SkyCount = 3;

{ TRadixTexturePart }

constructor TRadixTexturePart.Create(const APnames, ATexture: string);
begin
  inherited Create;
  FPnames := APnames;
  FTexture := ATexture;
end;

class procedure TRadixTexturePart.WriteName(const AStream: TStream; const AName: string);
var
  LName: packed array[0..7] of AnsiChar;
  LIndex: Integer;
begin
  FillChar(LName, SizeOf(LName), 0);
  for LIndex := 1 to Length(AName) do
    LName[LIndex - 1] := AnsiChar(Byte(Ord(AName[LIndex])));
  AStream.WriteBuffer(LName, SizeOf(LName));
end;

class procedure TRadixTexturePart.WriteTexture(const AStream: TStream; const AName: string;
  AWidth, AHeight, APatchCount, AFirstPatch: Integer);
var
  LTexture: TRadixMapTexture;
  LIndex: Integer;
begin
  FillChar(LTexture, SizeOf(LTexture), 0);
  for LIndex := 1 to Length(AName) do
    LTexture.Name[LIndex - 1] := AnsiChar(Byte(Ord(AName[LIndex])));
  LTexture.Width := AWidth;
  LTexture.Height := AHeight;
  LTexture.PatchCount := APatchCount;
  LTexture.Patch := AFirstPatch;
  AStream.WriteBuffer(LTexture, SizeOf(LTexture));
end;

procedure TRadixTexturePart.Build(const AContext: TRadixTranslationContext);
var
  LTable: TArray<TRadixBitmapRecord>;
  LPatchNames: TBytesStream;
  LTextures: TBytesStream;
  LCount: Integer;
  LInteger: Integer;
  LIndex: Integer;
  LOffset: Integer;
  LName: string;
  LRaw: TBytes;
  LImage: TBytes;
  LPatch: TBytes;
  LSky: Integer;
  LFound: Boolean;
  LLumpName: string;
  LExtra: TRadixMapPatch;
  LWidth: Integer;
  LHeight: Integer;
begin
  if not TRadixBitmapTable.TryRead(AContext.Container, LTable) then
    Exit;
  LCount := Length(LTable);
  // the flats that follow use the sizes: one slot for the stub and one for every bitmap
  AContext.SetTextureSlots(LCount + 1);
  AContext.Wad.AddMarker('P_START');
  LPatchNames := TBytesStream.Create;
  LTextures := TBytesStream.Create;
  try
    // 1 stub, the bitmaps, 3 skies of 2 patches
    LInteger := LCount + 7;
    LPatchNames.WriteBuffer(LInteger, SizeOf(Integer));
    // the skies have 2 patches, but the textures are 3 less than the patches
    LInteger := LCount + 4;
    LTextures.WriteBuffer(LInteger, SizeOf(Integer));
    LOffset := 0;
    for LIndex := 0 to LCount do
    begin
      LOffset := (LCount + 4) * 4 + 4 + LIndex * SizeOf(TRadixMapTexture);
      LTextures.WriteBuffer(LOffset, SizeOf(Integer));
    end;
    for LSky := 1 to SkyCount do
    begin
      LOffset := LOffset + SizeOf(TRadixMapTexture);
      if LSky > 1 then
        LOffset := LOffset + SizeOf(TRadixMapPatch);
      LTextures.WriteBuffer(LOffset, SizeOf(Integer));
    end;

    // the stub texture: a 32 x 32 patch of zeros
    SetLength(LImage, 32 * 32);
    LName := RADIX_WALL_PREFIX + '0000';
    AContext.Wad.AddLump(LName, AContext.Patches.FromColumns(LImage, 32, 32, True));
    AContext.TextureWidths[0] := 32;
    AContext.TextureHeights[0] := 32;
    WriteName(LPatchNames, LName);
    WriteTexture(LTextures, LName, 32, 32, 1, 0);

    for LIndex := 0 to LCount - 1 do
    begin
      LWidth := LTable[LIndex].Width;
      LHeight := LTable[LIndex].Height;
      LImage := AContext.Container.ReadAt(LTable[LIndex].Position, LWidth * LHeight);
      LName := RADIX_WALL_PREFIX + Format('%.4d', [LIndex + 1]);
      AContext.Wad.AddLump(LName, AContext.Patches.FromColumns(LImage, LWidth, LHeight, True));
      AContext.TextureWidths[LIndex + 1] := LWidth;
      AContext.TextureHeights[LIndex + 1] := LHeight;
      if LWidth = LHeight then
        AContext.MarkFlats[LIndex + 1] := True;
      WriteName(LPatchNames, LName);
      WriteTexture(LTextures, LName, LWidth, LHeight, 1, LIndex + 1);
      LLumpName := TRadixContainer.ReadName(LTable[LIndex].Name);
      AContext.AddAlias(LName, LLumpName);
      AContext.TextureNames.Add(LLumpName);
    end;

    FillChar(LExtra, SizeOf(LExtra), 0);
    LExtra.OriginX := 256;
    LExtra.OriginY := 0;
    for LSky := 1 to SkyCount do
    begin
      LFound := AContext.Container.IndexOf('MainEpisodeImage[' + IntToStr(LSky) + ']') >= 0;
      if LFound then
        LLumpName := 'MainEpisodeImage[' + IntToStr(LSky) + ']'
      else
        LLumpName := 'MainEpisodeImage[1]';
      if AContext.Container.TryRead(LLumpName, LRaw) then
      begin
        // the sky: height, width, then the pixels by columns
        LHeight := LRaw[0] or (LRaw[1] shl 8);
        LWidth := LRaw[2] or (LRaw[3] shl 8);
        LImage := Copy(LRaw, 4, Length(LRaw) - 4);
        LPatch := AContext.Patches.SkyFromColumns(LImage, LWidth, LHeight);
        LName := 'RSKY' + IntToStr(LSky);
        AContext.Wad.AddLump(LName, LPatch);
        WriteName(LPatchNames, LName);
        WriteTexture(LTextures, 'SKY' + IntToStr(LSky), LWidth * 2, LHeight, 2,
          LCount + 2 * LSky - 1);
        if LFound then
          AContext.AddAlias(LName, LLumpName);
        AContext.TextureNames.Add('SKY' + IntToStr(LSky));
      end;

      if LFound then
        LLumpName := 'FillEpisodeImage[' + IntToStr(LSky) + ']'
      else
        LLumpName := 'FillEpisodeImage[1]';
      if AContext.Container.TryRead(LLumpName, LRaw) then
      begin
        LHeight := LRaw[0] or (LRaw[1] shl 8);
        LWidth := LRaw[2] or (LRaw[3] shl 8);
        LImage := Copy(LRaw, 4, Length(LRaw) - 4);
        LPatch := AContext.Patches.SkyFromColumns(LImage, LWidth, LHeight);
        LName := 'RSKY' + IntToStr(LSky) + 'B';
        AContext.Wad.AddLump(LName, LPatch);
        WriteName(LPatchNames, LName);
        // the second patch of the texture
        LExtra.Patch := LCount + 2 * LSky;
        LTextures.WriteBuffer(LExtra, SizeOf(LExtra));
        if LFound then
          AContext.AddAlias(LName, LLumpName);
      end;
    end;

    AContext.Wad.AddMarker('P_END');
    AContext.Wad.AddLump(FTexture, Copy(LTextures.Bytes, 0, LTextures.Size));
    AContext.Wad.AddLump(FPnames, Copy(LPatchNames.Bytes, 0, LPatchNames.Size));
  finally
    LTextures.Free;
    LPatchNames.Free;
  end;
end;

end.
