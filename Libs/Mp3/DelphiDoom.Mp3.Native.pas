{******************************************************************************}
{                                                                              }
{  DelphiDoom: mp3 - adapter to the decoder of MP3LIB (layer III)              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Mp3.Native;

// The units mp3_* (MP3LIB) pull their data from a stream and write to an
// output buffer, one frame at a time, from a thread of their own player.
// This unit drives them from the caller's thread instead: the input is a
// TMp3FeedStream filled by Feed, the output a TMp3PcmBuffer, and a frame is
// handed to the decoder only when all of its bytes have arrived. Besides
// MP3LIB, it needs only the stand-ins of Libs\Mp3\Shim in place of d_delphi
// and i_system, so that the DLL does not drag the rest of the engine.

interface

{$SCOPEDENUMS ON}

uses
  mp3_Shared, mp3_CRC, mp3_BitStream, mp3_Header, mp3_SynthFilter, mp3_Layer3,
  DelphiDoom.Mp3.Stream, DelphiDoom.Mp3.FrameLocator, DelphiDoom.Mp3.PcmBuffer;

type
  /// <summary>
  ///   Outcome of DecodeFrame
  /// </summary>
  TMp3NativeStatus = (
    /// <summary>A frame was decoded: its PCM is in PcmData</summary>
    FrameDecoded,
    /// <summary>
    ///   A frame was consumed but produced no PCM (layer III needs the data
    ///   of the previous frames at the beginning of a stream)
    /// </summary>
    NoOutput,
    /// <summary>The buffered input holds no complete frame</summary>
    NeedData);

  /// <summary>
  ///   One layer III decoding session over MP3LIB. Not thread safe
  /// </summary>
  TMp3Native = class
  private
    FChannelMode: TChannels;
    FScaleFactor: Single;
    FStream: TMp3FeedStream;
    FBitStream: TBitStream;
    FHeader: THeader;
    FChecksum: TCRC16;
    FOwnedChecksum: TCRC16;
    FFilterFirst: TSynthesisFilter;
    FFilterSecond: TSynthesisFilter;
    FLocator: TMp3FrameLocator;
    FPcm: TMp3PcmBuffer;
    FLayer3: TLayerIII_Decoder;
    FTagChecked: Boolean;
    FTagBytesLeft: Integer;
    FFrequency: Cardinal;
    FChannels: Integer;
    procedure Build;
    procedure Teardown;
    function SkipTag: Boolean;
    procedure UpdateFormat;
    function GetPcmByteCount: Integer;
    function GetPcmData: PSmallInt;
    function GetPendingBytes: Integer;
  public
    /// <param name="AChannelMode">One of the MP3_CHANNELS_* values</param>
    /// <param name="AVolumePercent">
    ///   MP3_VOLUME_MIN..MP3_VOLUME_MAX; 100 leaves the samples at full scale
    /// </param>
    /// <exception cref="EMp3Exception">
    ///   MP3_ERROR_INVALID_ARGUMENT for a value out of range
    /// </exception>
    constructor Create(AChannelMode, AVolumePercent: Integer);
    destructor Destroy; override;

    /// <summary>
    ///   Drops the input and the state of the decoder, keeping the settings
    /// </summary>
    procedure Reset;

    /// <summary>
    ///   Appends MP3 bytes to the input
    /// </summary>
    /// <exception cref="EMp3Exception">
    ///   MP3_ERROR_LIMIT when more than MP3_MAX_BUFFERED_BYTES would be pending
    /// </exception>
    procedure Feed(AData: Pointer; ASize: Cardinal);

    /// <summary>
    ///   Decodes the next complete frame, if there is one
    /// </summary>
    /// <exception cref="EMp3Exception">
    ///   MP3_ERROR_UNSUPPORTED for a layer I or II frame and MP3_ERROR_DATA for
    ///   a frame that cannot be read; in both cases the frame is consumed
    /// </exception>
    function DecodeFrame: TMp3NativeStatus;

    /// <summary>Sampling rate, 0 before the first header</summary>
    property Frequency: Cardinal read FFrequency;

    /// <summary>PCM channels, 0 before the first header</summary>
    property Channels: Integer read FChannels;

    /// <summary>PCM of the last decoded frame (interleaved)</summary>
    property PcmData: PSmallInt read GetPcmData;
    property PcmByteCount: Integer read GetPcmByteCount;

    /// <summary>Bytes fed and not consumed yet</summary>
    property PendingBytes: Integer read GetPendingBytes;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Mp3.Intf;

const
  ID3_HEADER_SIZE = 10;
  ID3_FOOTER_SIZE = 10;
  ID3_FOOTER_FLAG = $10;

{ TMp3Native }

constructor TMp3Native.Create(AChannelMode, AVolumePercent: Integer);
begin
  inherited Create;

  case AChannelMode of
    MP3_CHANNELS_BOTH:    FChannelMode := Both;
    MP3_CHANNELS_LEFT:    FChannelMode := Left;
    MP3_CHANNELS_RIGHT:   FChannelMode := Right;
    MP3_CHANNELS_DOWNMIX: FChannelMode := Downmix;
  else
    raise EMp3Exception.CreateCode(MP3_ERROR_INVALID_ARGUMENT);
  end;

  if (AVolumePercent < MP3_VOLUME_MIN) or (AVolumePercent > MP3_VOLUME_MAX) then
    raise EMp3Exception.CreateCode(MP3_ERROR_INVALID_ARGUMENT);
  // The filters scale the float samples (-1.0..1.0) to the 16 bit range
  FScaleFactor := 32768.0 * AVolumePercent / MP3_VOLUME_MAX;

  Build;
end;

destructor TMp3Native.Destroy;
begin
  Teardown;
  inherited;
end;

procedure TMp3Native.Build;
begin
  FStream := TMp3FeedStream.Create;
  FBitStream := TBitStream.Create(FStream);
  FHeader := THeader.Create;
  FFilterFirst := TSynthesisFilter.Create(0, FScaleFactor);
  FFilterSecond := TSynthesisFilter.Create(1, FScaleFactor);
  FLocator := TMp3FrameLocator.Create;

  FChecksum := nil;
  FOwnedChecksum := nil;
  FPcm := nil;
  FLayer3 := nil;
  FTagChecked := False;
  FTagBytesLeft := 0;
  FFrequency := 0;
  FChannels := 0;
end;

procedure TMp3Native.Teardown;
begin
  // The checksum object is created by THeader but never released by it; the
  // header only keeps a reference, so it is freed here, once
  FChecksum := nil;
  FreeAndNil(FOwnedChecksum);
  FreeAndNil(FLayer3);
  FreeAndNil(FPcm);
  FreeAndNil(FFilterFirst);
  FreeAndNil(FFilterSecond);
  FreeAndNil(FHeader);
  FreeAndNil(FBitStream);
  FreeAndNil(FStream);
  FreeAndNil(FLocator);
end;

procedure TMp3Native.Reset;
begin
  Teardown;
  Build;
end;

procedure TMp3Native.Feed(AData: Pointer; ASize: Cardinal);
begin
  if (ASize > MP3_MAX_BUFFERED_BYTES) or
     (Int64(FStream.Available) + ASize > MP3_MAX_BUFFERED_BYTES) then
    raise EMp3Exception.CreateCode(MP3_ERROR_LIMIT);

  FStream.Append(AData, Integer(ASize));
end;

function TMp3Native.SkipTag: Boolean;
var
  LBytes: PByte;
  LSkipped: Integer;
begin
  Result := True;

  if not FTagChecked then
  begin
    if FStream.Available < ID3_HEADER_SIZE then
      Result := False
    else
    begin
      // An ID3v2 tag may hold bytes that look like a frame header (cover art
      // for instance): skip it as a whole using the size in its header
      LBytes := FStream.Peek;
      if (LBytes[0] = Ord('I')) and (LBytes[1] = Ord('D')) and
         (LBytes[2] = Ord('3')) and
         (((LBytes[6] or LBytes[7] or LBytes[8] or LBytes[9]) and $80) = 0) then
      begin
        FTagBytesLeft := ID3_HEADER_SIZE +
          ((Integer(LBytes[6]) shl 21) or (Integer(LBytes[7]) shl 14) or
           (Integer(LBytes[8]) shl 7) or Integer(LBytes[9]));
        if (LBytes[5] and ID3_FOOTER_FLAG) <> 0 then
          Inc(FTagBytesLeft, ID3_FOOTER_SIZE);
      end;
      FTagChecked := True;
    end;
  end;

  if Result and (FTagBytesLeft > 0) then
  begin
    LSkipped := FStream.Available;
    if LSkipped > FTagBytesLeft then
      LSkipped := FTagBytesLeft;
    FStream.Skip(LSkipped);
    Dec(FTagBytesLeft, LSkipped);
    Result := FTagBytesLeft = 0;
  end;
end;

procedure TMp3Native.UpdateFormat;
begin
  if FChannels = 0 then
  begin
    FFrequency := FHeader.Frequency;
    // Same rule as the engine: mono when the stream is mono or only one
    // channel is requested
    if (FHeader.Mode = SingleChannel) or (FChannelMode <> Both) then
      FChannels := 1
    else
      FChannels := 2;
  end;
end;

function TMp3Native.DecodeFrame: TMp3NativeStatus;
var
  LOffset, LFrameSize: Integer;
  LHeaderBytes: array[0..3] of Byte;
begin
  if not SkipTag then
    Exit(TMp3NativeStatus.NeedData);

  if FLocator.Locate(FStream.Peek, FStream.Available, LOffset, LFrameSize) =
    TMp3LocateResult.NeedMore then
  begin
    FStream.Skip(LOffset);
    Exit(TMp3NativeStatus.NeedData);
  end;

  FStream.Skip(LOffset);
  Move(FStream.Peek^, LHeaderBytes, SizeOf(LHeaderBytes));

  // Restart only resets the frame counters (the stream has no history). The
  // header uses them to index a table sized from the stream length, which here
  // grows with the data: keeping the counter at zero keeps the index valid
  FBitStream.Restart;
  if not FHeader.ReadHeader(FBitStream, FChecksum) then
    raise EMp3Exception.CreateCode(MP3_ERROR_DATA);
  if Assigned(FChecksum) then
    FOwnedChecksum := FChecksum;
  FLocator.Remember(@LHeaderBytes[0]);
  UpdateFormat;

  if FHeader.Layer <> 3 then
    raise EMp3Exception.CreateCode(MP3_ERROR_UNSUPPORTED);

  if not Assigned(FLayer3) then
  begin
    FPcm := TMp3PcmBuffer.Create(FChannels);
    FLayer3 := TLayerIII_Decoder.Create(FBitStream, FHeader, FFilterFirst,
      FFilterSecond, FPcm, FChannelMode);
  end;

  FPcm.Reset;
  FLayer3.Decode;
  if FPcm.Complete then
    Result := TMp3NativeStatus.FrameDecoded
  else
    Result := TMp3NativeStatus.NoOutput;
end;

function TMp3Native.GetPcmByteCount: Integer;
begin
  if Assigned(FPcm) then
    Result := FPcm.ByteCount
  else
    Result := 0;
end;

function TMp3Native.GetPcmData: PSmallInt;
begin
  if Assigned(FPcm) then
    Result := FPcm.Data
  else
    Result := nil;
end;

function TMp3Native.GetPendingBytes: Integer;
begin
  Result := FStream.Available;
end;

end.
