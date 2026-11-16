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
    class procedure WriteSkipPost(AStream: TStream); static;
    class procedure FlushTallPost(AStream: TStream; const ARun: TBytes; var ARunLength: Integer;
      AEndRow: Integer; var ALastDelta: Integer); static;
  public
    function Build(const APixels: TBytes; AWidth, AHeight: Integer; ASolid: Boolean; ALeftOffset,
      ATopOffset: Integer): TBytes; overload;
    function Build(const APixels: TBytes; AWidth, AHeight: Integer; ASolid: Boolean): TBytes; overload;
    function BuildTall(const AImage: TImagingPatchImage; AMaxPostLength: Integer): TBytes;
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

class procedure TImagingPatchWriter.WriteSkipPost(AStream: TStream);
const
  SKIP_POST: array[0..3] of Byte = (IMAGING_TALL_POST_ROW, 0, 0, 0);
begin
  AStream.WriteBuffer(SKIP_POST[0], SizeOf(SKIP_POST));
end;

class procedure TImagingPatchWriter.FlushTallPost(AStream: TStream; const ARun: TBytes;
  var ARunLength: Integer; AEndRow: Integer; var ALastDelta: Integer);
const
  PADDING: Byte = 0;
var
  LRealDelta: Integer;
  LRestDelta: Integer;
  LTopDelta: Byte;
  LLength: Byte;
begin
  if ARunLength = 0 then
    Exit;
  LRealDelta := AEndRow - ARunLength;
  if LRealDelta >= IMAGING_TALL_POST_ROW then
  begin
    if ALastDelta < IMAGING_TALL_POST_ROW then
    begin
      LRestDelta := LRealDelta - IMAGING_TALL_POST_ROW;
      WriteSkipPost(AStream);
    end
    else
      LRestDelta := LRealDelta - ALastDelta;
    while LRestDelta >= IMAGING_TALL_POST_ROW + 1 do
    begin
      Dec(LRestDelta, IMAGING_TALL_POST_ROW);
      WriteSkipPost(AStream);
    end;
    LTopDelta := Byte(LRestDelta);
  end
  else
    LTopDelta := Byte(LRealDelta);
  ALastDelta := LRealDelta;
  LLength := Byte(ARunLength);
  AStream.WriteBuffer(LTopDelta, 1);
  AStream.WriteBuffer(LLength, 1);
  AStream.WriteBuffer(PADDING, 1);
  AStream.WriteBuffer(ARun[0], ARunLength);
  AStream.WriteBuffer(PADDING, 1);
  ARunLength := 0;
end;

function TImagingPatchWriter.BuildTall(const AImage: TImagingPatchImage;
  AMaxPostLength: Integer): TBytes;
var
  LHeader: TImagingPatchHeader;
  LPosts: TBytesStream;
  LTable: TArray<Integer>;
  LRun: TBytes;
  LRunLength: Integer;
  LLastDelta: Integer;
  LColumn: Integer;
  LRow: Integer;
  LIndex: Integer;
  LEnd: Byte;
  LPadding: Byte;
  LHeaderSize: Integer;
begin
  if (AImage.Width < 0) or (AImage.Height < 0) or (AImage.Width > MAX_PATCH_WIDTH) or
    (AImage.Height > MAX_PATCH_WIDTH) then
    raise EImagingException.Create(SImagingTallPatchSize);
  if (AMaxPostLength < 1) or (AMaxPostLength > MAX_POST_LENGTH) then
    raise EImagingException.Create(SImagingPatchPostLength);
  if (Int64(Length(AImage.Pixels)) < Int64(AImage.Width) * AImage.Height) or
    (Int64(Length(AImage.Opaque)) < Int64(AImage.Width) * AImage.Height) then
    raise EImagingException.Create(SImagingPatchPictureTooSmall);

  LHeaderSize := SizeOf(TImagingPatchHeader) + AImage.Width * SizeOf(Integer);
  SetLength(LTable, AImage.Width);
  SetLength(LRun, AMaxPostLength);
  LEnd := END_OF_COLUMN;
  LPadding := 0;
  LPosts := TBytesStream.Create;
  try
    for LColumn := 0 to AImage.Width - 1 do
    begin
      LTable[LColumn] := LHeaderSize + Integer(LPosts.Position);
      LRunLength := 0;
      LLastDelta := -1;
      for LRow := 0 to AImage.Height - 1 do
      begin
        LIndex := LColumn + LRow * AImage.Width;
        if AImage.Opaque[LIndex] = 0 then
        begin
          FlushTallPost(LPosts, LRun, LRunLength, LRow, LLastDelta);
          Continue;
        end;
        if LRunLength = AMaxPostLength then
          FlushTallPost(LPosts, LRun, LRunLength, LRow, LLastDelta);
        LRun[LRunLength] := AImage.Pixels[LIndex];
        Inc(LRunLength);
      end;
      FlushTallPost(LPosts, LRun, LRunLength, AImage.Height, LLastDelta);
      LPosts.WriteBuffer(LEnd, 1);
      LPosts.WriteBuffer(LPadding, 1);
    end;

    LHeader.Width := SmallInt(AImage.Width);
    LHeader.Height := SmallInt(AImage.Height);
    LHeader.LeftOffset := SmallInt(AImage.LeftOffset);
    LHeader.TopOffset := SmallInt(AImage.TopOffset);
    SetLength(Result, LHeaderSize + Integer(LPosts.Size));
    Move(LHeader, Result[0], SizeOf(LHeader));
    if AImage.Width > 0 then
      Move(LTable[0], Result[SizeOf(LHeader)], AImage.Width * SizeOf(Integer));
    if LPosts.Size > 0 then
      Move(LPosts.Bytes[0], Result[LHeaderSize], LPosts.Size);
  finally
    LPosts.Free;
  end;
end;

end.
