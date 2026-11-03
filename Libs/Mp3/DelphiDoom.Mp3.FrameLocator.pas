{******************************************************************************}
{                                                                              }
{  DelphiDoom: mp3 - finds complete frames in buffered data                    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Mp3.FrameLocator;

interface

{$SCOPEDENUMS ON}

type
  /// <summary>
  ///   Outcome of a search for a frame
  /// </summary>
  TMp3LocateResult = (
    /// <summary>A complete frame starts at the returned offset</summary>
    Found,
    /// <summary>
    ///   No complete frame yet: the returned offset is the number of leading
    ///   bytes that can be dropped, the rest may be the start of a frame
    /// </summary>
    NeedMore);

  /// <summary>
  ///   Tells where the next MPEG audio frame starts and how long it is, so
  ///   that the decoder reads a frame only when all of its bytes are buffered
  ///   (TBitStream and THeader would otherwise consume a partial frame and
  ///   lose it)
  /// </summary>
  /// <remarks>
  ///   Applies the same synchronization rules as TBitStream.GetHeader: the
  ///   first frame is accepted on the sync word alone, the following ones must
  ///   also agree with the first on version, sampling rate and single channel
  ///   mode (see Remember). Candidates that THeader would turn into a frame
  ///   larger than the buffer of the bit stream, or with a negative amount of
  ///   layer III data, are skipped
  /// </remarks>
  TMp3FrameLocator = class
  private
    FSynced: Boolean;
    FSyncVersionByte: Byte;
    FSyncFrequencyByte: Byte;
    FSingleChannel: Boolean;
    function TryGetFrameSize(AHeader: System.PByte; out AFrameSize: Integer): Boolean;
  public
    /// <summary>
    ///   Forgets the first header: the next frame is accepted on the sync
    ///   word alone again
    /// </summary>
    procedure Reset;

    /// <summary>
    ///   Searches AData (ASize bytes) for the first frame. AOffset is the
    ///   position of its first byte and AFrameSize its length in bytes,
    ///   header included
    /// </summary>
    function Locate(AData: System.PByte; ASize: Integer; out AOffset,
      AFrameSize: Integer): TMp3LocateResult;

    /// <summary>
    ///   Records the four header bytes of the frame just read as the pattern
    ///   that the following frames must match
    /// </summary>
    procedure Remember(AHeader: System.PByte);

    property Synced: Boolean read FSynced;
  end;

implementation

uses
  mp3_BitStream;

const
  HEADER_SIZE = 4;

  // Largest frame the bit stream can hold (its buffer excludes the header)
  MAX_FRAME_PAYLOAD = BUFFERINTSIZE * SizeOf(Cardinal);

  // Bit rates in bit/s [version: 0 = MPEG-2 LSF, 1 = MPEG-1][layer - 1][index].
  // Same table as mp3_Header (which keeps it private)
  BITRATES: array[0..1, 0..2, 0..15] of Integer = (
    ((0, 32000, 48000, 56000, 64000, 80000, 96000, 112000, 128000, 144000, 160000, 176000, 192000, 224000, 256000, 0),
     (0, 8000, 16000, 24000, 32000, 40000, 48000, 56000, 64000, 80000, 96000, 112000, 128000, 144000, 160000, 0),
     (0, 8000, 16000, 24000, 32000, 40000, 48000, 56000, 64000, 80000, 96000, 112000, 128000, 144000, 160000, 0)),
    ((0, 32000, 64000, 96000, 128000, 160000, 192000, 224000, 256000, 288000, 320000, 352000, 384000, 416000, 448000, 0),
     (0, 32000, 48000, 56000, 64000, 80000, 96000, 112000, 128000, 160000, 192000, 224000, 256000, 320000, 384000, 0),
     (0, 32000, 40000, 48000, 56000, 64000, 80000, 96000, 112000, 128000, 160000, 192000, 224000, 256000, 320000, 0)));

  // Sampling rates in Hz [version][index]
  FREQUENCIES: array[0..1, 0..2] of Integer = (
    (22050, 24000, 16000),
    (44100, 48000, 32000));

{ TMp3FrameLocator }

procedure TMp3FrameLocator.Reset;
begin
  FSynced := False;
  FSyncVersionByte := 0;
  FSyncFrequencyByte := 0;
  FSingleChannel := False;
end;

function TMp3FrameLocator.TryGetFrameSize(AHeader: System.PByte;
  out AFrameSize: Integer): Boolean;
var
  LVersion, LLayer, LBitrateIndex, LFrequencyIndex, LPadding: Integer;
  LMono, LProtected: Boolean;
  LSideInfoSize, LCrcSize: Integer;
begin
  AFrameSize := 0;
  Result := False;

  if AHeader[0] <> $FF then
    Exit;

  if FSynced then
  begin
    if ((AHeader[1] and $F8) <> FSyncVersionByte) or
       ((AHeader[2] and $0C) <> FSyncFrequencyByte) or
       (((AHeader[3] and $C0) = $C0) <> FSingleChannel) then
      Exit;
  end
  else if (AHeader[1] and $F0) <> $F0 then
    Exit;

  LVersion := (AHeader[1] shr 3) and 1;
  if ((AHeader[1] shr 1) and 3) = 0 then
    Exit;
  LLayer := 4 - ((AHeader[1] shr 1) and 3);
  LProtected := (AHeader[1] and 1) = 0;
  LBitrateIndex := AHeader[2] shr 4;
  LFrequencyIndex := (AHeader[2] shr 2) and 3;
  LPadding := (AHeader[2] shr 1) and 1;
  LMono := (AHeader[3] and $C0) = $C0;

  // Free format, reserved bit rate index and reserved sampling rate
  if (LBitrateIndex = 0) or (LBitrateIndex = 15) or (LFrequencyIndex = 3) then
    Exit;

  if LLayer = 1 then
    AFrameSize := ((12 * BITRATES[LVersion, 0, LBitrateIndex]) div
      FREQUENCIES[LVersion, LFrequencyIndex] + LPadding) * 4
  else
  begin
    AFrameSize := (144 * BITRATES[LVersion, LLayer - 1, LBitrateIndex]) div
      FREQUENCIES[LVersion, LFrequencyIndex];
    if LVersion = 0 then
      AFrameSize := AFrameSize shr 1;
    Inc(AFrameSize, LPadding);
  end;

  if (AFrameSize <= HEADER_SIZE) or
     (AFrameSize - HEADER_SIZE > MAX_FRAME_PAYLOAD) then
    Exit;

  if LLayer = 3 then
  begin
    // Layer III data left after header, optional checksum and side info
    if LVersion = 1 then
    begin
      if LMono then
        LSideInfoSize := 17
      else
        LSideInfoSize := 32;
    end
    else
    begin
      if LMono then
        LSideInfoSize := 9
      else
        LSideInfoSize := 17;
    end;
    if LProtected then
      LCrcSize := 2
    else
      LCrcSize := 0;
    if AFrameSize - LSideInfoSize - LCrcSize - HEADER_SIZE < 0 then
      Exit;
  end;

  Result := True;
end;

function TMp3FrameLocator.Locate(AData: System.PByte; ASize: Integer; out AOffset,
  AFrameSize: Integer): TMp3LocateResult;
var
  LIndex: Integer;
begin
  AOffset := 0;
  AFrameSize := 0;

  LIndex := 0;
  while LIndex + HEADER_SIZE <= ASize do
  begin
    if TryGetFrameSize(AData + LIndex, AFrameSize) then
    begin
      AOffset := LIndex;
      if LIndex + AFrameSize <= ASize then
        Result := TMp3LocateResult.Found
      else
        Result := TMp3LocateResult.NeedMore;
      Exit;
    end;
    Inc(LIndex);
  end;

  // No header in the data: only the last bytes can still begin one
  AFrameSize := 0;
  if ASize >= HEADER_SIZE then
    AOffset := ASize - (HEADER_SIZE - 1)
  else
    AOffset := 0;
  Result := TMp3LocateResult.NeedMore;
end;

procedure TMp3FrameLocator.Remember(AHeader: System.PByte);
begin
  FSynced := True;
  FSyncVersionByte := AHeader[1] and $F8;
  FSyncFrequencyByte := AHeader[2] and $0C;
  FSingleChannel := (AHeader[3] and $C0) = $C0;
end;

end.
