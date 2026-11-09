{******************************************************************************}
{                                                                              }
{  DelphiDoom: Imaging library - writes a patch of Doom                         }
{  Copyright (C) 2021-2022 by Jim Valavanis (original DD_FONT)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Imaging.PatchWriter;

interface

uses
  System.SysUtils, System.Classes,
  DelphiDoom.Imaging.Types,
  DelphiDoom.Imaging.Intf;

type
  /// <summary>
  ///   FF_CreateDoomPatch of DD_FONT (and the same job that SaveBmpAsPatch of DD_VOXEL did): the header of 8
  ///   bytes, the table of the offsets of the columns (32 bits, from the start of the patch) and, for each
  ///   column, its posts (top delta, length, a byte of padding, the pixels, a byte of padding) and the end of
  ///   the column, which here is $FF followed by a 0 byte, as DD_FONT wrote it. The pixels that are not
  ///   transparent are the ones that are not 0, unless the patch is solid
  /// </summary>
  TImagingPatchWriter = class(TInterfacedObject, IImagingPatchWriter)
  strict private
    const
      MAX_POST_LENGTH = 255;
      MAX_PATCH_WIDTH = 32767;
      END_OF_COLUMN = $FF;
    class procedure FlushPost(AStream: TStream; const ARun: TBytes; ARunLength, AEndRow: Integer); static;
  public
    function Build(const APixels: TBytes; AWidth, AHeight: Integer; ASolid: Boolean; ALeftOffset,
      ATopOffset: Integer): TBytes; overload;
    function Build(const APixels: TBytes; AWidth, AHeight: Integer; ASolid: Boolean): TBytes; overload;
  end;

implementation

{ TImagingPatchWriter }

class procedure TImagingPatchWriter.FlushPost(AStream: TStream; const ARun: TBytes; ARunLength,
  AEndRow: Integer);
const
  PADDING: Byte = 0;
var
  LTopDelta: Byte;
  LLength: Byte;
begin
  if ARunLength = 0 then
    Exit;
  LTopDelta := Byte(AEndRow - ARunLength);
  LLength := Byte(ARunLength);
  AStream.WriteBuffer(LTopDelta, 1);
  AStream.WriteBuffer(LLength, 1);
  AStream.WriteBuffer(PADDING, 1);
  AStream.WriteBuffer(ARun[0], ARunLength);
  AStream.WriteBuffer(PADDING, 1);
end;

function TImagingPatchWriter.Build(const APixels: TBytes; AWidth, AHeight: Integer; ASolid: Boolean;
  ALeftOffset, ATopOffset: Integer): TBytes;
var
  LHeader: TImagingPatchHeader;
  LPosts: TBytesStream;
  LTable: TArray<Integer>;
  LRun: TBytes;
  LRunLength: Integer;
  LColumn: Integer;
  LRow: Integer;
  LPixel: Byte;
  LEnd: Byte;
  LPadding: Byte;
  LHeaderSize: Integer;
begin
  if (AWidth < 0) or (AHeight < 0) or (AWidth > MAX_PATCH_WIDTH) or (AHeight > MAX_POST_LENGTH) then
    raise EImagingException.Create(SImagingPatchPictureSize);
  if Int64(Length(APixels)) < Int64(AWidth) * AHeight then
    raise EImagingException.Create(SImagingPatchPictureTooSmall);

  LHeaderSize := SizeOf(TImagingPatchHeader) + AWidth * SizeOf(Integer);
  SetLength(LTable, AWidth);
  SetLength(LRun, AHeight + 1);
  LEnd := END_OF_COLUMN;
  LPadding := 0;
  LPosts := TBytesStream.Create;
  try
    for LColumn := 0 to AWidth - 1 do
    begin
      LTable[LColumn] := LHeaderSize + Integer(LPosts.Position);
      LRunLength := 0;
      for LRow := 0 to AHeight - 1 do
      begin
        LPixel := APixels[LColumn + LRow * AWidth];
        if (not ASolid) and (LPixel = 0) then
        begin
          FlushPost(LPosts, LRun, LRunLength, LRow);
          LRunLength := 0;
          Continue;
        end;
        LRun[LRunLength] := LPixel;
        Inc(LRunLength);
      end;
      FlushPost(LPosts, LRun, LRunLength, AHeight);
      LPosts.WriteBuffer(LEnd, 1);
      LPosts.WriteBuffer(LPadding, 1);
    end;

    LHeader.Width := SmallInt(AWidth);
    LHeader.Height := SmallInt(AHeight);
    LHeader.LeftOffset := SmallInt(ALeftOffset);
    LHeader.TopOffset := SmallInt(ATopOffset);
    SetLength(Result, LHeaderSize + Integer(LPosts.Size));
    Move(LHeader, Result[0], SizeOf(LHeader));
    if AWidth > 0 then
      Move(LTable[0], Result[SizeOf(LHeader)], AWidth * SizeOf(Integer));
    if LPosts.Size > 0 then
      Move(LPosts.Bytes[0], Result[LHeaderSize], LPosts.Size);
  finally
    LPosts.Free;
  end;
end;

function TImagingPatchWriter.Build(const APixels: TBytes; AWidth, AHeight: Integer; ASolid: Boolean): TBytes;
begin
  Result := Build(APixels, AWidth, AHeight, ASolid, AWidth div 2, AHeight);
end;

end.
