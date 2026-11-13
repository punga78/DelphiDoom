{ LEGACY COPY (parity tests of issue 228): DelphiDoom.XcomAudio.Mixer as it was before it moved to Libs\AudioMix, commit b6fedafb. Do not tidy. }
unit DelphiDoom.Tests.XcomEngine.LegacyMixer;

interface

uses
  System.SysUtils, System.SyncObjs, DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomAudio.Intf;

type
  /// <summary>
  ///   Mix_OpenAudio, Mix_AllocateChannels(16), Mix_ReserveChannels(4) and the hook of the music: IXcomAudioDevice
  ///   for the effects (a sound goes to the first free channel from 4 to 15, none free: it is dropped as
  ///   Mix_PlayChannel does), IXcomChannelMixer for the battlescape (a chosen channel, loops, position, the volume of
  ///   each channel), IXcomMusicSink for the music and IXcomPcmSource for the output that asks for samples from its
  ///   own thread. The calls from the game and the callback of the output never run together
  /// </summary>
  /// <remarks>
  ///   The sounds of PlayWave come with the volume applied (TXcomGame.PlaySound), those of PlayChannel take the volume
  ///   of their channel as Mix_Volume does. A SetVolume with no sound and no interface volume (backgroundMute) silences
  ///   the sounds of PlayWave too
  /// </remarks>
  TLegacyXcomMixer = class(TInterfacedObject, IXcomAudioDevice, IXcomChannelMixer, IXcomMusicSink, IXcomPcmSource,
    IXcomMixerMeter)
  strict private
    const
      CHANNEL_COUNT = 16;
      RESERVED_CHANNELS = 4;
      AMBIENT_CHANNEL = 3;
      MAX_VOLUME = 128;
    type
      TChannel = record
        Samples: TArray<SmallInt>;
        Position: Integer;
        Active: Boolean;
        /// <summary>Plays left: -1 forever</summary>
        Plays: Integer;
        /// <summary>The volume of the sound is already in the samples (PlayWave)</summary>
        Baked: Boolean;
        GainLeft: Single;
        GainRight: Single;
      end;
    var
      FOutput: IXcomPcmOutput;
      FRate: Integer;
      FDecoder: IXcomSampleDecoder;
      FLock: TCriticalSection;
      FChannels: array[0..CHANNEL_COUNT - 1] of TChannel;
      FChannelVolume: array[0..CHANNEL_COUNT - 1] of Integer;
      FAmbientVolume: Double;
      FSilenced: Boolean;
      FTrack: IXcomMusicTrack;
      FPaused: Boolean;
      FMusicVolume: Single;
      FTemp: TArray<SmallInt>;
      FStats: TXcomMixerStatistics;
      FSumSquares: Double;
      FSampleCount: Int64;
      FOpen: Boolean;
    procedure Mix(ADestination: PSmallInt; ASamples: PSmallInt; ACount: Integer);
    procedure MixChannel(ADestination: PSmallInt; AIndex, ACount: Integer);
    procedure RenderChannel(ADestination: PSmallInt; AIndex, ACount: Integer);
    procedure Start(AIndex: Integer; const ASamples: TArray<SmallInt>; ALoops: Integer; ABaked: Boolean);
  public
    /// <param name="AOutput">Where the mix goes (nil: nothing plays, as with no audio device)</param>
    /// <param name="ARate">Options::audioSampleRate</param>
    /// <param name="ADecoder">Reads the sound files (Mix_LoadWAV_RW); EArgumentNilException when nil</param>
    constructor Create(const AOutput: IXcomPcmOutput; ARate: Integer; const ADecoder: IXcomSampleDecoder);
    destructor Destroy; override;
    /// <summary>Mix_OpenAudio: opens the output; false when there is none, and the game goes on without sound</summary>
    function Open: Boolean;
    procedure Close;
    function IsAvailable: Boolean;
    procedure SetVolume(ASound, AMusic, AUi: Integer);
    procedure PlayWave(const AWave: TBytes);
    function PlayChannel(const AWave: TBytes; AChannel, ALoops: Integer): Integer;
    procedure SetPosition(AChannel, AAngle, ADistance: Integer);
    procedure HaltChannel(AChannel: Integer);
    function IsChannelPlaying(AChannel: Integer): Boolean;
    procedure SetChannelVolume(AChannel, AVolume: Integer);
    function FreeInterfaceChannel: Integer;
    procedure SetAmbientVolume(AValue: Double);
    procedure PlayTrack(const ATrack: IXcomMusicTrack; ALoop: Integer);
    procedure StopTrack;
    procedure PauseTrack(APaused: Boolean);
    function CurrentTrack: IXcomMusicTrack;
    /// <summary>The callback of the audio: fills the buffer with the sounds and the music</summary>
    procedure Render(ABuffer: PByte; ABytes: Integer);
    function Statistics: TXcomMixerStatistics;
    /// <summary>The number of channels that play a sound now</summary>
    function ActiveChannels: Integer;
    property Rate: Integer read FRate;
  end;

implementation

uses
  System.Math, DelphiDoom.XcomEngine.Volume, DelphiDoom.XcomAudio.Types;

{ TLegacyXcomMixer }

constructor TLegacyXcomMixer.Create(const AOutput: IXcomPcmOutput; ARate: Integer; const ADecoder: IXcomSampleDecoder);
var
  LIndex: Integer;
begin
  inherited Create;
  if not Assigned(ADecoder) then
    raise EArgumentNilException.Create('ADecoder');
  FOutput := AOutput;
  FRate := ARate;
  FDecoder := ADecoder;
  FLock := TCriticalSection.Create;
  FMusicVolume := 1;
  // Game::setVolume without a battle: the ambience is half of the sounds
  FAmbientVolume := 0.5;
  for LIndex := 0 to CHANNEL_COUNT - 1 do
    FChannelVolume[LIndex] := MAX_VOLUME;
end;

destructor TLegacyXcomMixer.Destroy;
begin
  Close;
  FTrack := nil;
  FLock.Free;
  inherited Destroy;
end;

function TLegacyXcomMixer.Open: Boolean;
begin
  if FOutput = nil then
    Exit(False);
  if not FOpen then
    FOpen := FOutput.Open(FRate, Self);
  Result := FOpen;
end;

procedure TLegacyXcomMixer.Close;
begin
  if FOpen then
  begin
    // the output stops asking for samples before the mixer goes
    FOutput.Close;
    FOpen := False;
  end;
end;

function TLegacyXcomMixer.IsAvailable: Boolean;
begin
  Result := FOpen;
end;

procedure TLegacyXcomMixer.SetVolume(ASound, AMusic, AUi: Integer);
var
  LValue: Integer;
  LIndex: Integer;
begin
  FLock.Enter;
  try
    if ASound >= 0 then
    begin
      // Game::setVolume: every channel, then the ambience channel
      LValue := TXcomVolume.Mixer(ASound);
      for LIndex := 0 to CHANNEL_COUNT - 1 do
        FChannelVolume[LIndex] := LValue;
      FChannelVolume[AMBIENT_CHANNEL] := Trunc(LValue * FAmbientVolume);
      FSilenced := (ASound = 0) and (AUi = 0);
    end;
    if AUi >= 0 then
    begin
      FChannelVolume[1] := TXcomVolume.Mixer(AUi);
      FChannelVolume[2] := TXcomVolume.Mixer(AUi);
    end;
    // the sounds come with the volume applied (TXcomGame.PlaySound); the music is scaled when it is rendered
    if AMusic >= 0 then
      FMusicVolume := TXcomVolume.Exponent(AMusic);
  finally
    FLock.Leave;
  end;
end;

procedure TLegacyXcomMixer.Start(AIndex: Integer; const ASamples: TArray<SmallInt>; ALoops: Integer; ABaked: Boolean);
begin
  FChannels[AIndex].Samples := ASamples;
  FChannels[AIndex].Position := 0;
  FChannels[AIndex].Active := True;
  if ALoops < 0 then
    FChannels[AIndex].Plays := -1
  else
    FChannels[AIndex].Plays := ALoops + 1;
  FChannels[AIndex].Baked := ABaked;
  FChannels[AIndex].GainLeft := 1;
  FChannels[AIndex].GainRight := 1;
  Inc(FStats.SoundsStarted);
end;

procedure TLegacyXcomMixer.PlayWave(const AWave: TBytes);
var
  LSamples: TArray<SmallInt>;
  LIndex: Integer;
begin
  if not FOpen then
    Exit;
  if not FDecoder.TryDecode(AWave, FRate, LSamples) then
    Exit;
  FLock.Enter;
  try
    for LIndex := RESERVED_CHANNELS to CHANNEL_COUNT - 1 do
      if not FChannels[LIndex].Active then
      begin
        Start(LIndex, LSamples, 0, True);
        Exit;
      end;
  finally
    FLock.Leave;
  end;
end;

function TLegacyXcomMixer.PlayChannel(const AWave: TBytes; AChannel, ALoops: Integer): Integer;
var
  LSamples: TArray<SmallInt>;
  LIndex: Integer;
begin
  Result := -1;
  if (not FOpen) or (AChannel >= CHANNEL_COUNT) or (AChannel < -1) then
    Exit;
  if not FDecoder.TryDecode(AWave, FRate, LSamples) then
    Exit;
  FLock.Enter;
  try
    if AChannel >= 0 then
    begin
      Start(AChannel, LSamples, ALoops, False);
      Exit(AChannel);
    end;
    for LIndex := RESERVED_CHANNELS to CHANNEL_COUNT - 1 do
      if not FChannels[LIndex].Active then
      begin
        Start(LIndex, LSamples, ALoops, False);
        Exit(LIndex);
      end;
  finally
    FLock.Leave;
  end;
end;

procedure TLegacyXcomMixer.SetPosition(AChannel, AAngle, ADistance: Integer);
var
  LPan: Double;
  LDistance: Single;
begin
  if (AChannel < 0) or (AChannel >= CHANNEL_COUNT) then
    Exit;
  // angle modulo 360, 0 in front, 90 to the right, 270 to the left: the other side fades out completely at 90
  LPan := Sin(DegToRad(Abs(AAngle) mod 360));
  LDistance := (255 - EnsureRange(ADistance, 0, 255)) / 255;
  FLock.Enter;
  try
    FChannels[AChannel].GainLeft := (1 - Max(0, LPan)) * LDistance;
    FChannels[AChannel].GainRight := (1 + Min(0, LPan)) * LDistance;
  finally
    FLock.Leave;
  end;
end;

procedure TLegacyXcomMixer.HaltChannel(AChannel: Integer);
var
  LIndex: Integer;
begin
  FLock.Enter;
  try
    for LIndex := 0 to CHANNEL_COUNT - 1 do
      if (AChannel < 0) or (AChannel = LIndex) then
      begin
        FChannels[LIndex].Active := False;
        FChannels[LIndex].Samples := nil;
      end;
  finally
    FLock.Leave;
  end;
end;

function TLegacyXcomMixer.IsChannelPlaying(AChannel: Integer): Boolean;
begin
  Result := False;
  if (AChannel < 0) or (AChannel >= CHANNEL_COUNT) then
    Exit;
  FLock.Enter;
  try
    Result := FChannels[AChannel].Active;
  finally
    FLock.Leave;
  end;
end;

procedure TLegacyXcomMixer.SetChannelVolume(AChannel, AVolume: Integer);
var
  LIndex: Integer;
begin
  AVolume := EnsureRange(AVolume, 0, MAX_VOLUME);
  FLock.Enter;
  try
    for LIndex := 0 to CHANNEL_COUNT - 1 do
      if (AChannel < 0) or (AChannel = LIndex) then
        FChannelVolume[LIndex] := AVolume;
  finally
    FLock.Leave;
  end;
end;

function TLegacyXcomMixer.FreeInterfaceChannel: Integer;
var
  LIndex: Integer;
begin
  Result := -1;
  FLock.Enter;
  try
    for LIndex := 1 to 2 do
      if not FChannels[LIndex].Active then
        Exit(LIndex);
  finally
    FLock.Leave;
  end;
end;

procedure TLegacyXcomMixer.SetAmbientVolume(AValue: Double);
begin
  FLock.Enter;
  try
    FAmbientVolume := AValue;
  finally
    FLock.Leave;
  end;
end;

procedure TLegacyXcomMixer.PlayTrack(const ATrack: IXcomMusicTrack; ALoop: Integer);
begin
  FLock.Enter;
  try
    if (FTrack <> nil) and (FTrack <> ATrack) then
      FTrack.Stop;
    FTrack := ATrack;
    FPaused := False;
    if FTrack <> nil then
      FTrack.Start(ALoop);
  finally
    FLock.Leave;
  end;
end;

procedure TLegacyXcomMixer.StopTrack;
begin
  FLock.Enter;
  try
    if FTrack <> nil then
      FTrack.Stop;
    FTrack := nil;
  finally
    FLock.Leave;
  end;
end;

procedure TLegacyXcomMixer.PauseTrack(APaused: Boolean);
begin
  FLock.Enter;
  try
    FPaused := APaused;
  finally
    FLock.Leave;
  end;
end;

function TLegacyXcomMixer.CurrentTrack: IXcomMusicTrack;
begin
  FLock.Enter;
  try
    Result := FTrack;
  finally
    FLock.Leave;
  end;
end;

procedure TLegacyXcomMixer.Mix(ADestination: PSmallInt; ASamples: PSmallInt; ACount: Integer);
var
  LIndex: Integer;
  LSum: Integer;
begin
  for LIndex := 0 to ACount - 1 do
  begin
    LSum := Integer(ADestination^) + Integer(ASamples^);
    if LSum > 32767 then
      LSum := 32767
    else if LSum < -32768 then
      LSum := -32768;
    ADestination^ := SmallInt(LSum);
    Inc(ADestination);
    Inc(ASamples);
  end;
end;

procedure TLegacyXcomMixer.MixChannel(ADestination: PSmallInt; AIndex, ACount: Integer);
var
  LIndex: Integer;
  LSum: Integer;
  LSource: PSmallInt;
  LLeft: Single;
  LRight: Single;
  LVolume: Single;
  LGain: Single;
begin
  LSource := @FChannels[AIndex].Samples[FChannels[AIndex].Position];
  if FChannels[AIndex].Baked then
  begin
    // the volume is in the samples: with the sounds silenced (backgroundMute) nothing is added
    if not FSilenced then
      Mix(ADestination, LSource, ACount);
    Exit;
  end;
  LVolume := FChannelVolume[AIndex] / MAX_VOLUME;
  LLeft := FChannels[AIndex].GainLeft * LVolume;
  LRight := FChannels[AIndex].GainRight * LVolume;
  for LIndex := 0 to ACount - 1 do
  begin
    if (LIndex and 1) = 0 then
      LGain := LLeft
    else
      LGain := LRight;
    LSum := Integer(ADestination^) + Trunc(LSource^ * LGain);
    ADestination^ := SmallInt(EnsureRange(LSum, -32768, 32767));
    Inc(ADestination);
    Inc(LSource);
  end;
end;

procedure TLegacyXcomMixer.RenderChannel(ADestination: PSmallInt; AIndex, ACount: Integer);
var
  LTake: Integer;
begin
  while FChannels[AIndex].Active and (ACount > 0) do
  begin
    LTake := Length(FChannels[AIndex].Samples) - FChannels[AIndex].Position;
    if LTake <= 0 then
    begin
      // nothing to play (an empty sound) or the end of a pass
      if (Length(FChannels[AIndex].Samples) = 0) or (FChannels[AIndex].Plays = 1) then
      begin
        FChannels[AIndex].Active := False;
        FChannels[AIndex].Samples := nil;
        Exit;
      end;
      if FChannels[AIndex].Plays > 1 then
        Dec(FChannels[AIndex].Plays);
      FChannels[AIndex].Position := 0;
      Continue;
    end;
    if LTake > ACount then
      LTake := ACount;
    MixChannel(ADestination, AIndex, LTake);
    Inc(ADestination, LTake);
    Inc(FChannels[AIndex].Position, LTake);
    Dec(ACount, LTake);
  end;
  if FChannels[AIndex].Active and (FChannels[AIndex].Plays = 1) and
    (FChannels[AIndex].Position >= Length(FChannels[AIndex].Samples)) then
  begin
    FChannels[AIndex].Active := False;
    FChannels[AIndex].Samples := nil;
  end;
end;

procedure TLegacyXcomMixer.Render(ABuffer: PByte; ABytes: Integer);
var
  LCount: Integer;
  LChannel: Integer;
  LPointer: PSmallInt;
  LIndex: Integer;
  LValue: Integer;
begin
  if (ABytes <= 0) or ((ABytes and 3) <> 0) then
    raise EXcomAudioException.Create(SXcomBufferNotWhole);
  LCount := ABytes div 2;
  FillChar(ABuffer^, ABytes, 0);
  FLock.Enter;
  try
    if (FTrack <> nil) and (not FPaused) then
    begin
      if Length(FTemp) < LCount then
        SetLength(FTemp, LCount);
      FillChar(FTemp[0], ABytes, 0);
      FTrack.Render(@FTemp[0], ABytes, FMusicVolume);
      Mix(PSmallInt(ABuffer), @FTemp[0], LCount);
    end;
    for LChannel := 0 to CHANNEL_COUNT - 1 do
      RenderChannel(PSmallInt(ABuffer), LChannel, LCount);
    LPointer := PSmallInt(ABuffer);
    for LIndex := 0 to LCount - 1 do
    begin
      LValue := LPointer^;
      FSumSquares := FSumSquares + Double(LValue) * LValue;
      if Abs(LValue) > FStats.Peak then
        FStats.Peak := Abs(LValue);
      Inc(LPointer);
    end;
    Inc(FSampleCount, LCount);
    Inc(FStats.RenderedBytes, ABytes);
  finally
    FLock.Leave;
  end;
end;

function TLegacyXcomMixer.Statistics: TXcomMixerStatistics;
begin
  FLock.Enter;
  try
    Result := FStats;
    if FSampleCount > 0 then
      Result.Rms := Sqrt(FSumSquares / FSampleCount);
  finally
    FLock.Leave;
  end;
end;

function TLegacyXcomMixer.ActiveChannels: Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  FLock.Enter;
  try
    for LIndex := 0 to CHANNEL_COUNT - 1 do
      if FChannels[LIndex].Active then
        Inc(Result);
  finally
    FLock.Leave;
  end;
end;

end.
