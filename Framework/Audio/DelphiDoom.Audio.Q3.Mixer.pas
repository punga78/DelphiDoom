{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - Quake III sound, mixing (snd_mix.c)             }
{  Based on the Quake III Arena GPL Source Code (id Software)                  }
{  Copyright (C) 1999-2005 Id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.Q3.Mixer;

interface

uses
  DelphiDoom.Audio.Q3.Types, DelphiDoom.Audio.Q3.Sfx, DelphiDoom.Audio.Q3.Intf,
  DelphiDoom.Audio.Q3.State;

type
  /// <summary>
  ///   The mixer of Quake III: S_PaintChannels fills a paint buffer of 4096 sample pairs
  ///   with the raw stream, the channels and the loop channels, and
  ///   S_TransferPaintBuffer clamps it into the DMA buffer of the device
  ///   (S_TransferStereo16 for 16 bit stereo, the general case for 8 bit or mono)
  /// </summary>
  /// <remarks>
  ///   Integer arithmetic wraps as in the C ({$Q-} {$R-}). Only the uncompressed sounds
  ///   (S_PaintChannelFrom16) exist: ADPCM, wavelet and mu-law are not ported. Differences
  ///   from the original: the chain of chunks is a padded array that wraps at its end where
  ///   the C would read through a null chunk; a channel whose start is still
  ///   START_SAMPLE_IMMEDIATE is skipped (S_Update_ never mixes one); a missing DMA buffer
  ///   skips the transfer
  /// </remarks>
  TQ3Mixer = class
  strict private
    FState: TQ3SoundState;
    FDevice: IQ3SoundDevice;
    FPaint: array[0..Q3_PAINTBUFFER_SIZE - 1] of TQ3SamplePair;
    FSoundVolume: Integer;
    procedure PaintChannelFrom16(const AChannel: TQ3Channel; ASfx: TQ3Sfx; ACount,
      ASampleOffset, ABufferOffset: Integer);
    procedure TransferStereo16(ABuffer: PSmallInt; AEndTime: Integer);
    procedure TransferPaintBuffer(AEndTime: Integer);
  public
    constructor Create(AState: TQ3SoundState; const ADevice: IQ3SoundDevice);
    /// <summary>S_PaintChannels: mixes from PaintedTime to AEndTime</summary>
    procedure PaintChannels(AEndTime: Integer);
    /// <summary>A pair of the paint buffer (the last block mixed)</summary>
    function PaintBufferAt(AIndex: Integer): TQ3SamplePair;
    /// <summary>snd_vol: s_volume * 255, as set by the last PaintChannels</summary>
    property SoundVolume: Integer read FSoundVolume;
  end;

implementation

{$Q-}
{$R-}
{$POINTERMATH ON}

uses
  System.Math;

{ TQ3Mixer }

constructor TQ3Mixer.Create(AState: TQ3SoundState; const ADevice: IQ3SoundDevice);
begin
  inherited Create;
  FState := AState;
  FDevice := ADevice;
end;

function TQ3Mixer.PaintBufferAt(AIndex: Integer): TQ3SamplePair;
begin
  Result := FPaint[AIndex];
end;

procedure TQ3Mixer.PaintChannelFrom16(const AChannel: TQ3Channel; ASfx: TQ3Sfx; ACount,
  ASampleOffset, ABufferOffset: Integer);
var
  LSamples: TArray<SmallInt>;
  LChunk, LChunks, LPosition, LBase: Integer;
  LLeftVolume, LRightVolume, LData, LIndex: Integer;
  LFloatLeft, LFloatRight, LOffset, LData2, LDivisor: Single;
  LBefore, LAfter, LJ: Integer;

  // samp[i].x += (fdata * fvol) / fdiv: an int plus a float, back to int. A zero divisor
  // gives a NaN or an infinity in the C, and the conversion then gives $80000000
  function AddScaled(AValue: Integer; AProduct, ADivisor: Single): Integer;
  var
    LQuotient: Single;
  begin
    if ADivisor = 0 then
      Result := Integer($80000000)
    else
    begin
      LQuotient := AProduct / ADivisor;
      LQuotient := Single(AValue) + LQuotient;
      Result := TQ3Math.TruncToInt(LQuotient);
    end;
  end;

begin
  LSamples := ASfx.Samples;
  LChunks := ASfx.ChunkCount;
  if (LChunks = 0) or (ASampleOffset < 0) then
    Exit;

  if AChannel.Doppler then
    ASampleOffset := TQ3Math.TruncToInt(Single(ASampleOffset) * AChannel.OldDopplerScale);

  LChunk := 0;
  while ASampleOffset >= Q3_SND_CHUNK_SIZE do
  begin
    Inc(LChunk);
    Dec(ASampleOffset, Q3_SND_CHUNK_SIZE);
    if LChunk >= LChunks then
      LChunk := 0;
  end;

  if (not AChannel.Doppler) or ((not IsNan(AChannel.DopplerScale)) and
    (AChannel.DopplerScale = 1.0)) then
  begin
    LLeftVolume := AChannel.LeftVolume * FSoundVolume;
    LRightVolume := AChannel.RightVolume * FSoundVolume;
    LPosition := LChunk * Q3_SND_CHUNK_SIZE + ASampleOffset;
    for LIndex := 0 to ACount - 1 do
    begin
      LData := LSamples[LPosition];
      Inc(LPosition);
      Inc(FPaint[ABufferOffset + LIndex].Left, TQ3Math.Sar(LData * LLeftVolume, 8));
      Inc(FPaint[ABufferOffset + LIndex].Right, TQ3Math.Sar(LData * LRightVolume, 8));
      // the end of the last chunk: the C has no next chunk, here it wraps
      if LPosition >= Length(LSamples) then
        LPosition := 0;
    end;
  end
  else
  begin
    LFloatLeft := AChannel.LeftVolume * FSoundVolume;
    LFloatRight := AChannel.RightVolume * FSoundVolume;
    LOffset := ASampleOffset;
    LBase := LChunk * Q3_SND_CHUNK_SIZE;
    for LIndex := 0 to ACount - 1 do
    begin
      LBefore := TQ3Math.TruncToInt(LOffset);
      LOffset := LOffset + AChannel.DopplerScale;
      LAfter := TQ3Math.TruncToInt(LOffset);
      LData2 := 0;
      LJ := LBefore;
      // a while and not a for: the limit can be $80000000 (an infinite scale)
      while LJ < LAfter do
      begin
        if LJ = Q3_SND_CHUNK_SIZE then
        begin
          Inc(LChunk);
          if LChunk >= LChunks then
            LChunk := 0;
          LBase := LChunk * Q3_SND_CHUNK_SIZE;
          LOffset := LOffset - Q3_SND_CHUNK_SIZE;
        end;
        LData2 := LData2 + LSamples[LBase + (LJ and (Q3_SND_CHUNK_SIZE - 1))];
        Inc(LJ);
      end;
      // an integer product (it wraps), then a float
      LDivisor := Single(256 * (LAfter - LBefore));
      FPaint[ABufferOffset + LIndex].Left :=
        AddScaled(FPaint[ABufferOffset + LIndex].Left, LData2 * LFloatLeft, LDivisor);
      FPaint[ABufferOffset + LIndex].Right :=
        AddScaled(FPaint[ABufferOffset + LIndex].Right, LData2 * LFloatRight, LDivisor);
    end;
  end;
end;

procedure TQ3Mixer.TransferStereo16(ABuffer: PSmallInt; AEndTime: Integer);
var
  LSource: PInteger;
  LPaintedTime, LPosition, LLinearCount, LIndex, LValue: Integer;
  LOut: PSmallInt;
begin
  LSource := PInteger(@FPaint[0]);
  LPaintedTime := FState.PaintedTime;
  while LPaintedTime < AEndTime do
  begin
    // handle recirculating buffer issues
    LPosition := LPaintedTime and ((FState.Dma.Samples shr 1) - 1);
    LOut := ABuffer + (LPosition shl 1);
    LLinearCount := (FState.Dma.Samples shr 1) - LPosition;
    if LPaintedTime + LLinearCount > AEndTime then
      LLinearCount := AEndTime - LPaintedTime;
    LLinearCount := LLinearCount shl 1;

    // S_WriteLinearBlastStereo16
    LIndex := 0;
    while LIndex < LLinearCount do
    begin
      LValue := TQ3Math.Sar(LSource[LIndex], 8);
      if LValue > $7FFF then
        LOut[LIndex] := $7FFF
      else if LValue < -32768 then
        LOut[LIndex] := -32768
      else
        LOut[LIndex] := LValue;
      LValue := TQ3Math.Sar(LSource[LIndex + 1], 8);
      if LValue > $7FFF then
        LOut[LIndex + 1] := $7FFF
      else if LValue < -32768 then
        LOut[LIndex + 1] := -32768
      else
        LOut[LIndex + 1] := LValue;
      Inc(LIndex, 2);
    end;

    LSource := LSource + LLinearCount;
    Inc(LPaintedTime, LLinearCount shr 1);
  end;
end;

procedure TQ3Mixer.TransferPaintBuffer(AEndTime: Integer);
var
  LBuffer: PByte;
  LIndex, LCount, LMask, LOutIndex, LStep, LValue, LSource: Integer;
  LPaint: PInteger;
  LOut16: PSmallInt;
begin
  LBuffer := FDevice.GetBuffer;

  if FState.TestSound <> 0 then
  begin
    // a fixed sine wave
    LCount := AEndTime - FState.PaintedTime;
    for LIndex := 0 to LCount - 1 do
    begin
      LValue := TQ3Math.TruncToInt(Sin((FState.PaintedTime + LIndex) * 0.1) * 20000 * 256);
      FPaint[LIndex].Left := LValue;
      FPaint[LIndex].Right := LValue;
    end;
  end;

  if LBuffer = nil then
    Exit;

  if (FState.Dma.SampleBits = 16) and (FState.Dma.Channels = 2) then
    TransferStereo16(PSmallInt(LBuffer), AEndTime)
  else
  begin
    LPaint := PInteger(@FPaint[0]);
    LSource := 0;
    LCount := (AEndTime - FState.PaintedTime) * FState.Dma.Channels;
    LMask := FState.Dma.Samples - 1;
    LOutIndex := FState.PaintedTime * FState.Dma.Channels and LMask;
    LStep := 3 - FState.Dma.Channels;

    if FState.Dma.SampleBits = 16 then
    begin
      LOut16 := PSmallInt(LBuffer);
      while LCount > 0 do
      begin
        Dec(LCount);
        LValue := TQ3Math.Sar(LPaint[LSource], 8);
        Inc(LSource, LStep);
        if LValue > $7FFF then
          LValue := $7FFF
        else if LValue < -32768 then
          LValue := -32768;
        LOut16[LOutIndex] := LValue;
        LOutIndex := (LOutIndex + 1) and LMask;
      end;
    end
    else if FState.Dma.SampleBits = 8 then
    begin
      while LCount > 0 do
      begin
        Dec(LCount);
        LValue := TQ3Math.Sar(LPaint[LSource], 8);
        Inc(LSource, LStep);
        if LValue > $7FFF then
          LValue := $7FFF
        else if LValue < -32768 then
          LValue := -32768;
        LBuffer[LOutIndex] := Byte(TQ3Math.Sar(LValue, 8) + 128);
        LOutIndex := (LOutIndex + 1) and LMask;
      end;
    end;
  end;
end;

procedure TQ3Mixer.PaintChannels(AEndTime: Integer);
var
  LIndex, LEnd, LTime, LCount, LSampleOffset, LStop, LSlot: Integer;
  LSfx: TQ3Sfx;
  LVolume: Single;
begin
  LVolume := FState.Volume * 255;
  FSoundVolume := TQ3Math.TruncToInt(LVolume);

  while FState.PaintedTime < AEndTime do
  begin
    // if the paint buffer is smaller than the DMA buffer we may need to fill it
    // several times
    LEnd := AEndTime;
    if AEndTime - FState.PaintedTime > Q3_PAINTBUFFER_SIZE then
      LEnd := FState.PaintedTime + Q3_PAINTBUFFER_SIZE;

    // clear the paint buffer to either music or zeros
    if FState.RawEnd < FState.PaintedTime then
      FillChar(FPaint, (LEnd - FState.PaintedTime) * SizeOf(TQ3SamplePair), 0)
    else
    begin
      if LEnd < FState.RawEnd then
        LStop := LEnd
      else
        LStop := FState.RawEnd;
      LIndex := FState.PaintedTime;
      while LIndex < LStop do
      begin
        LSlot := LIndex and (Q3_MAX_RAW_SAMPLES - 1);
        FPaint[LIndex - FState.PaintedTime] := FState.RawSamples[LSlot];
        Inc(LIndex);
      end;
      while LIndex < LEnd do
      begin
        FPaint[LIndex - FState.PaintedTime].Left := 0;
        FPaint[LIndex - FState.PaintedTime].Right := 0;
        Inc(LIndex);
      end;
    end;

    // paint in the channels
    for LIndex := 0 to Q3_MAX_CHANNELS - 1 do
    begin
      LSfx := FState.Channels[LIndex].Sfx;
      if (LSfx = nil) or ((FState.Channels[LIndex].LeftVolume <= 0) and
        (FState.Channels[LIndex].RightVolume <= 0)) then
        Continue;
      if FState.Channels[LIndex].StartSample = Q3_START_SAMPLE_IMMEDIATE then
        Continue;

      LTime := FState.PaintedTime;
      LSampleOffset := LTime - FState.Channels[LIndex].StartSample;
      LCount := LEnd - LTime;
      if LSampleOffset + LCount > LSfx.SoundLength then
        LCount := LSfx.SoundLength - LSampleOffset;
      if LCount > 0 then
        PaintChannelFrom16(FState.Channels[LIndex], LSfx, LCount, LSampleOffset,
          LTime - FState.PaintedTime);
    end;

    // paint in the looped channels
    for LIndex := 0 to FState.NumLoopChannels - 1 do
    begin
      LSfx := FState.LoopChannels[LIndex].Sfx;
      if (LSfx = nil) or ((FState.LoopChannels[LIndex].LeftVolume = 0) and
        (FState.LoopChannels[LIndex].RightVolume = 0)) then
        Continue;
      if LSfx.SoundLength = 0 then
        Continue;

      LTime := FState.PaintedTime;
      // two passes if the end of the sample is hit
      repeat
        LSampleOffset := LTime mod LSfx.SoundLength;
        LCount := LEnd - LTime;
        if LSampleOffset + LCount > LSfx.SoundLength then
          LCount := LSfx.SoundLength - LSampleOffset;
        if LCount > 0 then
        begin
          PaintChannelFrom16(FState.LoopChannels[LIndex], LSfx, LCount, LSampleOffset,
            LTime - FState.PaintedTime);
          Inc(LTime, LCount);
        end;
      until LTime >= LEnd;
    end;

    // transfer out according to the DMA format
    TransferPaintBuffer(LEnd);
    FState.PaintedTime := LEnd;
  end;
end;

end.
