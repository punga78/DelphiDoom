{******************************************************************************}
{                                                                              }
{  DelphiDoom: sound decoder - DWVW (Delta With Variable Word width)           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sound.Codec.Dwvw;

interface

uses
  System.SysUtils, DelphiDoom.Sndfile.Intf;

type
  /// <summary>
  ///   Decoder of DWVW, the lossless delta coding of AIFF-C (Delta With
  ///   Variable Word width). The state is a reservoir of bits and the last
  ///   delta width and sample, as in libsndfile; the stream has no frame
  ///   count, so it is decoded to the end to find out
  /// </summary>
  TDwvwDecoder = class
  private
    FSource: TBytes;
    FPosition: Int64;
    FBitWidth, FDwmMaxSize, FMaxDelta, FSpan: Integer;
    FBitCount, FBits, FLastDeltaWidth, FLastSample: Integer;
    FBufferIndex, FBufferEnd: Integer;
    FBuffer: array[0..255] of Byte;
    FTrailing: Integer;
    FHasTrailing: Boolean;
    function LoadBits(ABitCount: Integer): Integer;
    function DecodeData(var ATarget: TArray<Integer>; AOffset, ALength: Integer): Integer;
  public
    constructor Create(const ASource: TBytes; AStart: Int64; ABitWidth: Integer);
    /// <summary>
    ///   Decodes the samples of the stream that starts at ADataOffset (to the
    ///   end of the file, whatever the chunk says), justified to the top of a
    ///   32 bit integer. ADataLength only decides, like libsndfile, whether the
    ///   count of frames is worked out (up to 16 MB) or left unlimited.
    ///   AFrames is how many frames there are, or High(Int64) when unknown.
    ///   The last sample, when the stream ends with the last bit, is stored by
    ///   libsndfile but not counted: ATrailing is it
    /// </summary>
    class function Decode(const ASource: TBytes; ADataOffset, ADataLength: Int64;
      ABitWidth, AChannels: Integer; out AData: TArray<Integer>;
      out AFrames: Int64; out ATrailing: Integer;
      out AHasTrailing: Boolean): Integer; static;
  end;

implementation

const
  MAX_COUNTED_LENGTH = $1000000;
  // Size of the buffer of integers libsndfile counts the frames through
  COUNT_BUFFER_ITEMS = 2048;

{ TDwvwDecoder }

constructor TDwvwDecoder.Create(const ASource: TBytes; AStart: Int64; ABitWidth: Integer);
begin
  inherited Create;
  FSource := ASource;
  FPosition := AStart;
  FBitWidth := ABitWidth;
  FDwmMaxSize := ABitWidth div 2;
  FMaxDelta := 1 shl (ABitWidth - 1);
  FSpan := 1 shl ABitWidth;
end;

function TDwvwDecoder.LoadBits(ABitCount: Integer): Integer;
var
  LGetModifier: Boolean;
  LCount: Integer;
begin
  LGetModifier := False;
  // A negative count asks for the delta width modifier
  if ABitCount < 0 then
  begin
    LGetModifier := True;
    ABitCount := FDwmMaxSize;
  end;

  while FBitCount < ABitCount do
  begin
    if FBufferIndex >= FBufferEnd then
    begin
      LCount := Length(FSource) - FPosition;
      if LCount > SizeOf(FBuffer) then
        LCount := SizeOf(FBuffer);
      if LCount < 0 then
        LCount := 0;
      if LCount > 0 then
        Move(FSource[Integer(FPosition)], FBuffer[0], LCount);
      Inc(FPosition, LCount);
      FBufferEnd := LCount;
      FBufferIndex := 0;
    end;

    // The end of the stream
    if (ABitCount < 8) and (FBufferEnd = 0) then
      Exit(-1);

    FBits := Integer(Cardinal(FBits) shl 8);
    if FBufferIndex < FBufferEnd then
    begin
      FBits := FBits or FBuffer[FBufferIndex];
      Inc(FBufferIndex);
    end;
    Inc(FBitCount, 8);
  end;

  if not LGetModifier then
  begin
    Result := Integer(Cardinal(FBits) shr (FBitCount - ABitCount)) and ((1 shl ABitCount) - 1);
    Dec(FBitCount, ABitCount);
    Exit;
  end;

  Result := 0;
  while Result < FDwmMaxSize do
  begin
    Dec(FBitCount);
    if (FBits and (1 shl FBitCount)) <> 0 then
      Break;
    Inc(Result);
  end;
end;

function TDwvwDecoder.DecodeData(var ATarget: TArray<Integer>; AOffset,
  ALength: Integer): Integer;
var
  LModifier, LDeltaWidth, LNegative, LDelta, LSample, LCount: Integer;
begin
  LDeltaWidth := FLastDeltaWidth;
  LSample := FLastSample;
  LCount := 0;
  while LCount < ALength do
  begin
    LModifier := LoadBits(-1);
    // The end of the stream
    if (LModifier < 0) or ((FBufferEnd = 0) and (LCount = 0)) then
      Break;

    if (LModifier <> 0) and (LoadBits(1) <> 0) then
      LModifier := -LModifier;

    LDeltaWidth := (LDeltaWidth + LModifier + FBitWidth) mod FBitWidth;

    LDelta := 0;
    if LDeltaWidth <> 0 then
    begin
      LDelta := LoadBits(LDeltaWidth - 1) or (1 shl (LDeltaWidth - 1));
      LNegative := LoadBits(1);
      if LDelta = FMaxDelta - 1 then
        Inc(LDelta, LoadBits(1));
      if LNegative <> 0 then
        LDelta := -LDelta;
    end;

    Inc(LSample, LDelta);
    if LSample >= FMaxDelta then
      Dec(LSample, FSpan)
    else if LSample < -FMaxDelta then
      Inc(LSample, FSpan);

    // Justified to the most significant bit
    ATarget[AOffset + LCount] := Integer(Cardinal(LSample) shl (32 - FBitWidth));

    // The sample that comes with the last bit is stored but not counted
    if (FBufferEnd = 0) and (FBitCount = 0) then
    begin
      FTrailing := ATarget[AOffset + LCount];
      FHasTrailing := True;
      Break;
    end;
    Inc(LCount);
  end;

  FLastDeltaWidth := LDeltaWidth;
  FLastSample := LSample;
  Result := LCount;
end;

class function TDwvwDecoder.Decode(const ASource: TBytes; ADataOffset,
  ADataLength: Int64; ABitWidth, AChannels: Integer; out AData: TArray<Integer>;
  out AFrames: Int64; out ATrailing: Integer; out AHasTrailing: Boolean): Integer;
var
  LDecoder: TDwvwDecoder;
  LBuffer: TArray<Integer>;
  LReadLength, LCount: Integer;
  LTotal: Int64;
  LCapacity: Integer;
begin
  AData := nil;
  AFrames := 0;
  ATrailing := 0;
  AHasTrailing := False;
  if (ABitWidth < 2) or (ABitWidth > 24) or (AChannels < 1) then
    Exit(SNDFILE_ERR_MALFORMED_FILE);

  // A file of more than 16 MB is not decoded to count its frames
  if ADataLength > MAX_COUNTED_LENGTH then
    AFrames := High(Int64);

  if ADataOffset > Length(ASource) then
    ADataOffset := Length(ASource);
  LDecoder := TDwvwDecoder.Create(ASource, ADataOffset, ABitWidth);
  try
    LReadLength := COUNT_BUFFER_ITEMS div AChannels * AChannels;
    if LReadLength < 1 then
      LReadLength := 1;
    SetLength(LBuffer, LReadLength);
    LTotal := 0;
    LCapacity := 0;
    repeat
      LCount := LDecoder.DecodeData(LBuffer, 0, LReadLength);
      if LCount > 0 then
      begin
        if LTotal + LCount > LCapacity then
        begin
          LCapacity := Integer((LTotal + LCount) * 2);
          SetLength(AData, LCapacity);
        end;
        Move(LBuffer[0], AData[Integer(LTotal)], LCount * SizeOf(Integer));
        Inc(LTotal, LCount);
      end;
    until LCount <= 0;
    SetLength(AData, LTotal);
    ATrailing := LDecoder.FTrailing;
    AHasTrailing := LDecoder.FHasTrailing;
  finally
    LDecoder.Free;
  end;

  if AFrames = 0 then
    AFrames := LTotal div AChannels;
  Result := SNDFILE_OK;
end;

end.
