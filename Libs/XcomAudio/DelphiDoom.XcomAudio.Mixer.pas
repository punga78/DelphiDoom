{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom audio library - the mixer (the channels of SDL_mixer: the   }
{  sounds, the music that is hooked, the volumes)                               }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomAudio.Mixer;

interface

uses
  System.SysUtils, System.SyncObjs, DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomAudio.Intf;

type
  /// <summary>
  ///   Mix_OpenAudio, Mix_AllocateChannels(16), Mix_ReserveChannels(4) and the hook of the music: IXcomAudioDevice
  ///   for the effects (a sound goes to the first free channel from 4 to 15, none free: it is dropped as
  ///   Mix_PlayChannel does), IXcomMusicSink for the music and IXcomPcmSource for the output that asks for samples
  ///   from its own thread. The calls from the game and the callback of the output never run together
  /// </summary>
  TXcomMixer = class(TInterfacedObject, IXcomAudioDevice, IXcomMusicSink, IXcomPcmSource, IXcomMixerMeter)
  strict private
    const
      CHANNEL_COUNT = 16;
      RESERVED_CHANNELS = 4;
    type
      TChannel = record
        Samples: TArray<SmallInt>;
        Position: Integer;
        Active: Boolean;
      end;
    var
      FOutput: IXcomPcmOutput;
      FRate: Integer;
      FLock: TCriticalSection;
      FChannels: array[0..CHANNEL_COUNT - 1] of TChannel;
      FTrack: IXcomMusicTrack;
      FPaused: Boolean;
      FMusicVolume: Single;
      FTemp: TArray<SmallInt>;
      FStats: TXcomMixerStatistics;
      FSumSquares: Double;
      FSampleCount: Int64;
      FOpen: Boolean;
    procedure Mix(ADestination: PSmallInt; ASamples: PSmallInt; ACount: Integer);
  public
    /// <param name="AOutput">Where the mix goes (nil: nothing plays, as with no audio device)</param>
    /// <param name="ARate">Options::audioSampleRate</param>
    constructor Create(const AOutput: IXcomPcmOutput; ARate: Integer);
    destructor Destroy; override;
    /// <summary>Mix_OpenAudio: opens the output; false when there is none, and the game goes on without sound</summary>
    function Open: Boolean;
    procedure Close;
    function IsAvailable: Boolean;
    procedure SetVolume(ASound, AMusic, AUi: Integer);
    procedure PlayWave(const AWave: TBytes);
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
  System.Math, DelphiDoom.XcomEngine.Volume, DelphiDoom.XcomAudio.Types, DelphiDoom.XcomAudio.WaveDecoder;

{ TXcomMixer }

constructor TXcomMixer.Create(const AOutput: IXcomPcmOutput; ARate: Integer);
begin
  inherited Create;
  FOutput := AOutput;
  FRate := ARate;
  FLock := TCriticalSection.Create;
  FMusicVolume := 1;
end;

destructor TXcomMixer.Destroy;
begin
  Close;
  FTrack := nil;
  FLock.Free;
  inherited Destroy;
end;

function TXcomMixer.Open: Boolean;
begin
  if FOutput = nil then
    Exit(False);
  if not FOpen then
    FOpen := FOutput.Open(FRate, Self);
  Result := FOpen;
end;

procedure TXcomMixer.Close;
begin
  if FOpen then
  begin
    // the output stops asking for samples before the mixer goes
    FOutput.Close;
    FOpen := False;
  end;
end;

function TXcomMixer.IsAvailable: Boolean;
begin
  Result := FOpen;
end;

procedure TXcomMixer.SetVolume(ASound, AMusic, AUi: Integer);
begin
  // the sounds come with the volume applied (TXcomGame.PlaySound); the music is scaled when it is rendered
  if AMusic >= 0 then
  begin
    FLock.Enter;
    try
      FMusicVolume := TXcomVolume.Exponent(AMusic);
    finally
      FLock.Leave;
    end;
  end;
end;

procedure TXcomMixer.PlayWave(const AWave: TBytes);
var
  LSamples: TArray<SmallInt>;
  LIndex: Integer;
begin
  if not FOpen then
    Exit;
  try
    LSamples := TXcomWaveDecoder.ToStereo16(AWave, FRate);
  except
    on EXcomAudioException do
      Exit;
  end;
  FLock.Enter;
  try
    for LIndex := RESERVED_CHANNELS to CHANNEL_COUNT - 1 do
      if not FChannels[LIndex].Active then
      begin
        FChannels[LIndex].Samples := LSamples;
        FChannels[LIndex].Position := 0;
        FChannels[LIndex].Active := True;
        Inc(FStats.SoundsStarted);
        Exit;
      end;
  finally
    FLock.Leave;
  end;
end;

procedure TXcomMixer.PlayTrack(const ATrack: IXcomMusicTrack; ALoop: Integer);
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

procedure TXcomMixer.StopTrack;
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

procedure TXcomMixer.PauseTrack(APaused: Boolean);
begin
  FLock.Enter;
  try
    FPaused := APaused;
  finally
    FLock.Leave;
  end;
end;

function TXcomMixer.CurrentTrack: IXcomMusicTrack;
begin
  FLock.Enter;
  try
    Result := FTrack;
  finally
    FLock.Leave;
  end;
end;

procedure TXcomMixer.Mix(ADestination: PSmallInt; ASamples: PSmallInt; ACount: Integer);
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

procedure TXcomMixer.Render(ABuffer: PByte; ABytes: Integer);
var
  LCount: Integer;
  LChannel: Integer;
  LTake: Integer;
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
      if FChannels[LChannel].Active then
      begin
        LTake := Length(FChannels[LChannel].Samples) - FChannels[LChannel].Position;
        if LTake > LCount then
          LTake := LCount;
        Mix(PSmallInt(ABuffer), @FChannels[LChannel].Samples[FChannels[LChannel].Position], LTake);
        Inc(FChannels[LChannel].Position, LTake);
        if FChannels[LChannel].Position >= Length(FChannels[LChannel].Samples) then
        begin
          FChannels[LChannel].Active := False;
          FChannels[LChannel].Samples := nil;
        end;
      end;
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

function TXcomMixer.Statistics: TXcomMixerStatistics;
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

function TXcomMixer.ActiveChannels: Integer;
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
