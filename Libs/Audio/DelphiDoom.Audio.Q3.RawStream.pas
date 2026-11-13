{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - Quake III sound, raw samples (music and video)  }
{  Based on the Quake III Arena GPL Source Code (id Software)                  }
{  Copyright (C) 1999-2005 Id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.Q3.RawStream;

interface

uses
  DelphiDoom.Audio.Q3.State;

type
  /// <summary>
  ///   S_RawSamples: the ring of 16384 sample pairs that the mixer copies under the
  ///   effects, fed by streams (music, the audio of a RoQ video). The samples are
  ///   resampled to the rate of the device by taking the nearest one, scaled by the volume
  ///   (intVolume = 256 * volume) and stored shifted by 8 bits, like the C
  /// </summary>
  /// <remarks>
  ///   Difference from the original: a rate of 0 or less raises EQ3SoundException (the C
  ///   would loop for ever with a scale of 0)
  /// </remarks>
  TQ3RawStream = class
  strict private
    FState: TQ3SoundState;
    procedure Store(ALeft, ARight: Integer);
  public
    constructor Create(AState: TQ3SoundState);
    /// <summary>
    ///   S_RawSamples on a buffer in memory: ASamples frames of AChannels (1 or 2) channels
    ///   of AWidth (1 = unsigned 8 bit, 2 = signed 16 bit little endian) bytes. The buffer
    ///   must hold them. Nothing happens if the system is not started or is muted
    /// </summary>
    procedure RawSamples(ASamples, ARate, AWidth, AChannels: Integer; AData: PByte;
      AVolume: Single); overload;
    /// <summary>
    ///   The same for 16 bit samples in an array (interleaved if stereo); the frames are
    ///   the ones the array holds
    /// </summary>
    procedure RawSamples(const AData: TArray<SmallInt>; ARate, AChannels: Integer;
      AVolume: Single); overload;
  end;

implementation

{$Q-}
{$R-}
{$POINTERMATH ON}

uses
  DelphiDoom.Audio.Q3.Types;

{ TQ3RawStream }

constructor TQ3RawStream.Create(AState: TQ3SoundState);
begin
  inherited Create;
  FState := AState;
end;

procedure TQ3RawStream.Store(ALeft, ARight: Integer);
var
  LDestination: Integer;
begin
  LDestination := FState.RawEnd and (Q3_MAX_RAW_SAMPLES - 1);
  Inc(FState.RawEnd);
  FState.RawSamples[LDestination].Left := ALeft;
  FState.RawSamples[LDestination].Right := ARight;
end;

procedure TQ3RawStream.RawSamples(ASamples, ARate, AWidth, AChannels: Integer;
  AData: PByte; AVolume: Single);
var
  LIntVolume, LIndex, LSource: Integer;
  LScale, LPosition: Single;
  LShorts: PSmallInt;
  LChars: PShortInt;
begin
  if (not FState.SoundStarted) or FState.SoundMuted then
    Exit;
  if (ARate <= 0) or (FState.Dma.Speed <= 0) then
    raise EQ3SoundException.CreateFmt(SQ3BadSampleRate, [ARate]);

  LIntVolume := TQ3Math.TruncToInt(Single(256) * AVolume);

  if FState.RawEnd < FState.SoundTime then
    FState.RawEnd := FState.SoundTime;

  LScale := Single(ARate) / Single(FState.Dma.Speed);
  LShorts := PSmallInt(AData);
  LChars := PShortInt(AData);

  if (AChannels = 2) and (AWidth = 2) then
  begin
    if LScale = 1.0 then
      for LIndex := 0 to ASamples - 1 do
        Store(LShorts[LIndex * 2] * LIntVolume, LShorts[LIndex * 2 + 1] * LIntVolume)
    else
    begin
      LIndex := 0;
      while True do
      begin
        LPosition := Single(LIndex) * LScale;
        LSource := TQ3Math.TruncToInt(LPosition);
        if LSource >= ASamples then
          Break;
        Store(LShorts[LSource * 2] * LIntVolume, LShorts[LSource * 2 + 1] * LIntVolume);
        Inc(LIndex);
      end;
    end;
  end
  else if (AChannels = 1) and (AWidth = 2) then
  begin
    LIndex := 0;
    while True do
    begin
      LPosition := Single(LIndex) * LScale;
      LSource := TQ3Math.TruncToInt(LPosition);
      if LSource >= ASamples then
        Break;
      Store(LShorts[LSource] * LIntVolume, LShorts[LSource] * LIntVolume);
      Inc(LIndex);
    end;
  end
  else if (AChannels = 2) and (AWidth = 1) then
  begin
    LIntVolume := LIntVolume * 256;
    LIndex := 0;
    while True do
    begin
      LPosition := Single(LIndex) * LScale;
      LSource := TQ3Math.TruncToInt(LPosition);
      if LSource >= ASamples then
        Break;
      Store(LChars[LSource * 2] * LIntVolume, LChars[LSource * 2 + 1] * LIntVolume);
      Inc(LIndex);
    end;
  end
  else if (AChannels = 1) and (AWidth = 1) then
  begin
    LIntVolume := LIntVolume * 256;
    LIndex := 0;
    while True do
    begin
      LPosition := Single(LIndex) * LScale;
      LSource := TQ3Math.TruncToInt(LPosition);
      if LSource >= ASamples then
        Break;
      Store((AData[LSource] - 128) * LIntVolume, (AData[LSource] - 128) * LIntVolume);
      Inc(LIndex);
    end;
  end;
end;

procedure TQ3RawStream.RawSamples(const AData: TArray<SmallInt>; ARate, AChannels: Integer;
  AVolume: Single);
begin
  if (Length(AData) = 0) or (AChannels < 1) or (AChannels > 2) then
    Exit;
  RawSamples(Length(AData) div AChannels, ARate, 2, AChannels, PByte(@AData[0]), AVolume);
end;

end.
