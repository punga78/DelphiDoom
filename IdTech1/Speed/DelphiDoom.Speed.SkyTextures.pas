{******************************************************************************}
{                                                                              }
{  DelphiDoom: Speed library - the sky of every circuit as a texture           }
{  Copyright (C) 1995 by Noriaworks                                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom, GLSpeed)     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Speed.SkyTextures;

interface

uses
  System.SysUtils, DelphiDoom.GameData.Intf;

type
  /// <summary>The sky texture that was made for a circuit</summary>
  TSpeedSkyEntry = record
    /// <summary>The marker of the circuit: E1M1..</summary>
    Level: string;
    /// <summary>The name of the texture (and of its picture): SKY and the name of the circuit</summary>
    Texture: string;
  end;

  /// <summary>
  ///   The circuits of Speed Haste have a sky (NUBES0..7, 320 x 70) and mountains (MOUNT0..7, 320 x 35..49
  ///   with holes) that the fork drew in two layers. The sky of the engine of Doom is one texture of 128
  ///   rows: the clouds on top and the mountains over them at
  ///   the bottom, as one picture of the sky in P_START..P_END and a texture of that picture in TEXTURE3
  ///   (with the name added to PNAMES)
  /// </summary>
  TSpeedSkyTextures = class
  public
    /// <summary>
    ///   Adds the pictures, a new PNAMES (the old names first, then the new ones: the last lump with a name
    ///   is the one that the engine reads) and TEXTURE3 for the circuits of the WAD
    /// </summary>
    /// <param name="APatches">Makes the lump of a picture from its columns</param>
    /// <param name="ATransparent">The index that means "no pixel" in the pictures of the game</param>
    /// <returns>The texture of each circuit that has a sky and mountains in the WAD</returns>
    /// <exception cref="EArgumentNilException">An argument is nil</exception>
    class function Append(const AWad: IGameWadComposer; const APatches: IGamePatchBuilder;
      ATransparent: Byte): TArray<TSpeedSkyEntry>; static;
  end;

implementation

uses
  System.Classes, System.Math, System.Generics.Collections, DelphiDoom.Speed.MapInfoReader, DelphiDoom.Racing.Types;

const
  MAPDATA_LUMP = 'MAPDATA';
  PNAMES_LUMP = 'PNAMES';
  TEXTURE_LUMP = 'TEXTURE3';
  MAP_LUMP_SPAN = 13;
  NAME_SIZE = 8;
  PATCH_HEADER_SIZE = 8;
  MAP_TEXTURE_SIZE = 22;
  MAP_PATCH_SIZE = 10;
  PATCH_START = 'P_START';
  PATCH_END = 'P_END';
  // the column drawer of the sky reads 128 rows
  SKY_HEIGHT = 128;

type
  TPicture = record
    Width: Integer;
    Height: Integer;
    // row after row, from the top
    Pixels: TBytes;
  end;

procedure WriteName(AStream: TStream; const AName: string);
var
  LBytes: TBytes;
begin
  SetLength(LBytes, NAME_SIZE);
  TEncoding.ASCII.GetBytes(UpperCase(AName), 1, Length(AName), LBytes, 0);
  AStream.WriteBuffer(LBytes[0], NAME_SIZE);
end;

// The row of the clouds that a row of the sky shows: below the last one they are mirrored, so that
// the sky goes on down to the horizon without a seam
function SourceRow(ARow, AHeight: Integer): Integer;
begin
  if ARow < AHeight then
    Result := ARow
  else
    Result := Max(0, 2 * AHeight - 1 - ARow);
end;

// The picture of a patch lump (a column made of posts), the holes as ATransparent
function DecodePatch(const AWad: IGameWadComposer; const AName: string; ATransparent: Byte;
  out APicture: TPicture): Boolean;
var
  LIndex, LColumn, LOffset, LRow, LCount, LPixel: Integer;
  LData: TBytes;
begin
  Result := False;
  LIndex := AWad.IndexOf(AName);
  if LIndex < 0 then
    Exit;
  LData := AWad.LumpData[LIndex];
  if Length(LData) < PATCH_HEADER_SIZE then
    Exit;
  APicture.Width := PSmallInt(@LData[0])^;
  APicture.Height := PSmallInt(@LData[2])^;
  if (APicture.Width <= 0) or (APicture.Height <= 0) or
     (PATCH_HEADER_SIZE + 4 * APicture.Width > Length(LData)) then
    Exit;
  SetLength(APicture.Pixels, APicture.Width * APicture.Height);
  FillChar(APicture.Pixels[0], Length(APicture.Pixels), ATransparent);
  for LColumn := 0 to APicture.Width - 1 do
  begin
    LOffset := PInteger(@LData[PATCH_HEADER_SIZE + 4 * LColumn])^;
    while (LOffset >= 0) and (LOffset < Length(LData)) and (LData[LOffset] <> 255) do
    begin
      if LOffset + 3 > Length(LData) then
        Exit;
      LRow := LData[LOffset];
      LCount := LData[LOffset + 1];
      if LOffset + 3 + LCount > Length(LData) then
        Exit;
      for LPixel := 0 to LCount - 1 do
        if LRow + LPixel < APicture.Height then
          APicture.Pixels[(LRow + LPixel) * APicture.Width + LColumn] := LData[LOffset + 3 + LPixel];
      Inc(LOffset, LCount + 4);
    end;
  end;
  Result := True;
end;

{ TSpeedSkyTextures }

class function TSpeedSkyTextures.Append(const AWad: IGameWadComposer; const APatches: IGamePatchBuilder;
  ATransparent: Byte): TArray<TSpeedSkyEntry>;
var
  LEpisode, LMap, LMarker, LLump, LCount, LIndex, LColumn, LRow, LTop: Integer;
  LName: string;
  LInfo: TSpeedMapInfo;
  LNames: TList<string>;
  LEntries: TList<TSpeedSkyEntry>;
  LPictures: TList<TBytes>;
  LTextureNames: TList<string>;
  LTextureWidths: TList<Integer>;
  LEntry: TSpeedSkyEntry;
  LSky, LMountain, LComposite: TPicture;
  LOld, LNewPnames, LTextureBytes, LColumns: TBytes;
  LStream: TBytesStream;
  LNumber, LOffset: Integer;
  LValue: SmallInt;
begin
  if not Assigned(AWad) then
    raise EArgumentNilException.Create('AWad');
  if not Assigned(APatches) then
    raise EArgumentNilException.Create('APatches');
  LNames := TList<string>.Create;
  LEntries := TList<TSpeedSkyEntry>.Create;
  LPictures := TList<TBytes>.Create;
  LTextureNames := TList<string>.Create;
  LTextureWidths := TList<Integer>.Create;
  try
    LIndex := AWad.IndexOf(PNAMES_LUMP);
    if LIndex < 0 then
      Exit(nil);
    LOld := AWad.LumpData[LIndex];
    if Length(LOld) < 4 then
      Exit(nil);
    LCount := PInteger(@LOld[0])^;
    if (LCount < 0) or (4 + LCount * NAME_SIZE > Length(LOld)) then
      Exit(nil);
    for LIndex := 0 to LCount - 1 do
      LNames.Add(UpperCase(Trim(StringReplace(TEncoding.ASCII.GetString(LOld, 4 + LIndex * NAME_SIZE, NAME_SIZE),
        #0, ' ', [rfReplaceAll]))));

    for LEpisode := 1 to RACING_MAX_EPISODES do
      for LMap := 1 to RACING_MAX_MAPS do
      begin
        LName := Format('E%dM%d', [LEpisode, LMap]);
        LMarker := AWad.IndexOf(LName);
        if LMarker < 0 then
          Continue;
        for LLump := LMarker + 1 to LMarker + MAP_LUMP_SPAN - 1 do
          if (LLump < AWad.Count) and SameText(AWad.LumpNames[LLump], MAPDATA_LUMP) then
          begin
            LInfo := TSpeedMapInfoReader.Parse(TEncoding.ASCII.GetString(AWad.LumpData[LLump]));
            if DecodePatch(AWad, LInfo.SkyTexture, ATransparent, LSky) and
               DecodePatch(AWad, LInfo.MountainTexture, ATransparent, LMountain) and
               (LSky.Height <= SKY_HEIGHT) and (LMountain.Height <= SKY_HEIGHT) then
            begin
              // the clouds, mirrored below their last row down to the horizon, and the mountains at the bottom
              LComposite.Width := LSky.Width;
              LComposite.Height := SKY_HEIGHT;
              SetLength(LComposite.Pixels, LComposite.Width * LComposite.Height);
              for LRow := 0 to SKY_HEIGHT - 1 do
                for LColumn := 0 to LComposite.Width - 1 do
                  LComposite.Pixels[LRow * LComposite.Width + LColumn] :=
                    LSky.Pixels[SourceRow(LRow, LSky.Height) * LSky.Width + LColumn];
              LTop := SKY_HEIGHT - LMountain.Height;
              for LRow := 0 to LMountain.Height - 1 do
                for LColumn := 0 to Min(LMountain.Width, LComposite.Width) - 1 do
                  if LMountain.Pixels[LRow * LMountain.Width + LColumn] <> ATransparent then
                    LComposite.Pixels[(LTop + LRow) * LComposite.Width + LColumn] :=
                      LMountain.Pixels[LRow * LMountain.Width + LColumn];
              // the patches are made of columns
              SetLength(LColumns, Length(LComposite.Pixels));
              for LColumn := 0 to LComposite.Width - 1 do
                for LRow := 0 to SKY_HEIGHT - 1 do
                  LColumns[LColumn * SKY_HEIGHT + LRow] := LComposite.Pixels[LRow * LComposite.Width + LColumn];
              LPictures.Add(APatches.FromColumns(LColumns, LComposite.Width, SKY_HEIGHT, True, 0, 0));
              LTextureNames.Add('SKY' + LName);
              LTextureWidths.Add(LComposite.Width);
              LEntry.Level := LName;
              LEntry.Texture := 'SKY' + LName;
              LEntries.Add(LEntry);
            end;
            Break;
          end;
      end;
    if LEntries.Count = 0 then
      Exit(nil);

    // the engine takes the patches of a texture only from between P_START and P_END
    AWad.AddMarker(PATCH_START);
    for LIndex := 0 to LEntries.Count - 1 do
      AWad.AddLump(LTextureNames[LIndex], LPictures[LIndex]);
    AWad.AddMarker(PATCH_END);

    // PNAMES: the names of before and the new ones
    for LIndex := 0 to LTextureNames.Count - 1 do
      LNames.Add(LTextureNames[LIndex]);
    LStream := TBytesStream.Create;
    try
      LNumber := LNames.Count;
      LStream.WriteBuffer(LNumber, 4);
      for LName in LNames do
        WriteName(LStream, LName);
      LNewPnames := Copy(LStream.Bytes, 0, LStream.Size);
    finally
      LStream.Free;
    end;
    AWad.AddLump(PNAMES_LUMP, LNewPnames);

    // TEXTURE3: the directory of the offsets, then a texture of one patch each
    LStream := TBytesStream.Create;
    try
      LNumber := LEntries.Count;
      LStream.WriteBuffer(LNumber, 4);
      LOffset := 4 + 4 * LEntries.Count;
      for LIndex := 0 to LEntries.Count - 1 do
      begin
        LStream.WriteBuffer(LOffset, 4);
        Inc(LOffset, MAP_TEXTURE_SIZE + MAP_PATCH_SIZE);
      end;
      for LIndex := 0 to LEntries.Count - 1 do
      begin
        WriteName(LStream, LTextureNames[LIndex]);
        LNumber := 0;
        LStream.WriteBuffer(LNumber, 4);
        LValue := SmallInt(LTextureWidths[LIndex]);
        LStream.WriteBuffer(LValue, 2);
        LValue := SKY_HEIGHT;
        LStream.WriteBuffer(LValue, 2);
        LStream.WriteBuffer(LNumber, 4);
        LValue := 1;
        LStream.WriteBuffer(LValue, 2);
        LValue := 0;
        LStream.WriteBuffer(LValue, 2);
        LStream.WriteBuffer(LValue, 2);
        LValue := SmallInt(LNames.Count - LTextureNames.Count + LIndex);
        LStream.WriteBuffer(LValue, 2);
        LValue := 1;
        LStream.WriteBuffer(LValue, 2);
        LValue := 0;
        LStream.WriteBuffer(LValue, 2);
      end;
      LTextureBytes := Copy(LStream.Bytes, 0, LStream.Size);
    finally
      LStream.Free;
    end;
    AWad.AddLump(TEXTURE_LUMP, LTextureBytes);
    Result := LEntries.ToArray;
  finally
    LTextureWidths.Free;
    LTextureNames.Free;
    LPictures.Free;
    LEntries.Free;
    LNames.Free;
  end;
end;

end.
