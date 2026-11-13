{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the sound device that mixes to PCM               }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): what BASS did for           }
{  modplay.pas, as samples that an output asks for                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.PcmMixer;

interface

uses
  System.SysUtils, System.SyncObjs, DelphiDoom.Logging.Intf, DelphiDoom.AudioMix.NearestRateVoice,
  DelphiDoom.AudioMix.VoiceList, DelphiDoom.Greed.Sound.Intf;

const
  /// <summary>The rate of the samples that the mixer makes, if the caller has no other</summary>
  GREED_PCM_DEFAULT_RATE = 44100;

type
  /// <summary>A song that is being played: the next frames of 16 bit stereo, as a tracker makes them</summary>
  IGreedSongRenderer = interface
    ['{D0A6F3B1-58E4-4C29-9B7A-16C3E8F2A045}']
    /// <summary>Writes AFrames frames (left and right, interleaved) at the start of ASamples</summary>
    procedure Render(const ASamples: TArray<SmallInt>; AFrames: Integer);
  end;

  /// <summary>What reads a module (S3M, MOD ...) and plays it in a loop at a rate</summary>
  IGreedSongDecoder = interface
    ['{4E92B7C5-0A1D-4F63-8E58-C7B4D9A61F30}']
    /// <summary>nil when the bytes are not a module that it knows</summary>
    function Open(const AModule: TBytes; ARate: Integer): IGreedSongRenderer;
  end;

  /// <summary>What the mixer did since it was made: the proof that the game has sound, without ears</summary>
  TGreedMixerStatistics = record
    /// <summary>Frames given to the output</summary>
    FramesRendered: Int64;
    /// <summary>Frames in which the left or the right sample was not zero</summary>
    FramesWithSound: Int64;
    /// <summary>The highest absolute sample given to the output (0..32767)</summary>
    Peak: Integer;
    /// <summary>Samples that went over the 16 bits and were cut</summary>
    ClippedSamples: Int64;
    EffectsStarted: Integer;
    /// <summary>Effects that were asked for with bytes that are not a WAV that the mixer plays</summary>
    EffectsRejected: Integer;
    /// <summary>Effects that played to their end</summary>
    EffectsEnded: Integer;
    /// <summary>Effects that are playing now</summary>
    ActiveEffects: Integer;
    SongsStarted: Integer;
    SongsRejected: Integer;
    /// <summary>Frames in which the song gave a sample that was not zero</summary>
    FramesWithMusic: Int64;
    SongPlaying: Boolean;
  end;

  /// <summary>What an output asks of the mixer: the next samples, 16 bit stereo at the rate of the mixer</summary>
  IGreedPcmRenderer = interface
    ['{B81D5E07-3A6C-4F92-A0D4-7E25C9F1B683}']
    /// <summary>Fills AByteCount bytes (a multiple of 4) of ABuffer; silence where nothing plays</summary>
    procedure Render(ABuffer: PByte; AByteCount: Integer);
    function GetRate: Integer;
    function Statistics: TGreedMixerStatistics;
    property Rate: Integer read GetRate;
  end;

  /// <summary>
  ///   IGreedSoundDevice (what BASS did) as a mixer in memory: an effect is a WAV file (PCM, 8 or 16 bit, one or
  ///   two channels, any rate) that plays once with its volume and pan; the song is a module that the decoder
  ///   plays in a loop. Render gives the next samples (16 bit stereo at the rate of the mixer): the PCM output of
  ///   the program calls it from its thread while the game starts and moves the sounds from its own, so the list
  ///   of what plays is behind a lock. The pan is linear as in BASS: the side away from the sound gets quieter and
  ///   the other stays. The samples are taken at the nearest position, without a filter
  /// </summary>
  TGreedPcmMixer = class(TInterfacedObject, IGreedSoundDevice, IGreedPcmRenderer)
  strict private
    type
      /// <summary>The song that plays, as the mixer sees it</summary>
      ISong = interface(IGreedMusicChannel)
        function GetRenderer: IGreedSongRenderer;
        function GetVolume: Single;
        function IsStopped: Boolean;
      end;

      /// <summary>An effect that plays: the voice of Libs\AudioMix, which is also the channel the game holds</summary>
      TEffectVoice = class(TPcmNearestRateVoice, IGreedEffectChannel)
      end;

      TSong = class(TInterfacedObject, IGreedMusicChannel, ISong)
      strict private
        FRenderer: IGreedSongRenderer;
        FVolume: Single;
        FStopped: Boolean;
      public
        constructor Create(const ARenderer: IGreedSongRenderer; AVolume: Single);
        procedure SetVolume(AVolume: Single);
        procedure Stop;
        function GetRenderer: IGreedSongRenderer;
        function GetVolume: Single;
        function IsStopped: Boolean;
      end;
  strict private
    FRate: Integer;
    FDecoder: IGreedSongDecoder;
    FLog: ILog;
    FLock: TCriticalSection;
    FVoices: TPcmVoiceList;
    FSong: ISong;
    FSums: TArray<Integer>;
    FSongSamples: TArray<SmallInt>;
    FStatistics: TGreedMixerStatistics;
    FReady: Boolean;
  public
    /// <summary>ADecoder may be nil: then there is no music. ALog gets the warnings of the WAV reader</summary>
    constructor Create(ARate: Integer; const ADecoder: IGreedSongDecoder; const ALog: ILog);
    destructor Destroy; override;
    function Initialize: Boolean;
    procedure Shutdown;
    function StartEffect(const AWave: TBytes): IGreedEffectChannel;
    function StartMusic(const AModule: TBytes; AVolume: Single): IGreedMusicChannel;
    /// <summary>
    ///   Fills AByteCount bytes (a multiple of 4) of ABuffer with the next samples: the song and the effects that
    ///   play, silence where there is nothing
    /// </summary>
    procedure Render(ABuffer: PByte; AByteCount: Integer);
    function GetRate: Integer;
    function Statistics: TGreedMixerStatistics;
  end;

implementation

uses
  System.Math, DelphiDoom.Audio.Types, DelphiDoom.Audio.WaveParser;

const
  WAVE_FORMAT_PCM = 1;

{ TGreedPcmMixer.TSong }

constructor TGreedPcmMixer.TSong.Create(const ARenderer: IGreedSongRenderer; AVolume: Single);
begin
  inherited Create;
  FRenderer := ARenderer;
  SetVolume(AVolume);
end;

procedure TGreedPcmMixer.TSong.SetVolume(AVolume: Single);
begin
  FVolume := Min(Max(AVolume, 0), 1);
end;

procedure TGreedPcmMixer.TSong.Stop;
begin
  FStopped := True;
end;

function TGreedPcmMixer.TSong.GetRenderer: IGreedSongRenderer;
begin
  Result := FRenderer;
end;

function TGreedPcmMixer.TSong.GetVolume: Single;
begin
  Result := FVolume;
end;

function TGreedPcmMixer.TSong.IsStopped: Boolean;
begin
  Result := FStopped;
end;

{ TGreedPcmMixer }

constructor TGreedPcmMixer.Create(ARate: Integer; const ADecoder: IGreedSongDecoder; const ALog: ILog);
begin
  inherited Create;
  if ARate <= 0 then
    raise EArgumentOutOfRangeException.Create('ARate');
  if not Assigned(ALog) then
    raise EArgumentNilException.Create('ALog');
  FRate := ARate;
  FDecoder := ADecoder;
  FLog := ALog;
  FLock := TCriticalSection.Create;
  FVoices := TPcmVoiceList.Create;
end;

destructor TGreedPcmMixer.Destroy;
begin
  FVoices.Free;
  FLock.Free;
  inherited Destroy;
end;

function TGreedPcmMixer.Initialize: Boolean;
begin
  FReady := True;
  Result := True;
end;

procedure TGreedPcmMixer.Shutdown;
begin
  FLock.Enter;
  try
    FVoices.Clear;
    FSong := nil;
    FReady := False;
  finally
    FLock.Leave;
  end;
end;

function TGreedPcmMixer.StartEffect(const AWave: TBytes): IGreedEffectChannel;
var
  LChunks: TSfxWaveChunks;
  LFrameBytes: Integer;
  LAccepted: Boolean;
  LVoice: TEffectVoice;
begin
  Result := nil;
  if not FReady or (Length(AWave) = 0) then
    Exit;
  LAccepted := False;
  LChunks := Default(TSfxWaveChunks);
  // the lumps of the game are WAV files; the parser would take any other bytes for a DMX sound
  if TSfxWaveParser.IsRiff(@AWave[0], Length(AWave)) then
  begin
    TSfxWaveParser.ParseLump(@AWave[0], Length(AWave), 'greed', FLog, LChunks);
    LAccepted := LChunks.FormatFound and LChunks.DataFound and (LChunks.Format.Tag = WAVE_FORMAT_PCM) and
      (LChunks.Format.Channels in [1, 2]) and ((LChunks.Format.BitsPerSample = 8) or
      (LChunks.Format.BitsPerSample = 16)) and (LChunks.Format.SamplesPerSecond > 0) and
      (LChunks.DataOffset >= 0) and (LChunks.DataLength > 0) and
      (Int64(LChunks.DataOffset) + LChunks.DataLength <= Length(AWave));
  end;
  FLock.Enter;
  try
    if not LAccepted then
    begin
      Inc(FStatistics.EffectsRejected);
      Exit;
    end;
    LFrameBytes := LChunks.Format.Channels * (LChunks.Format.BitsPerSample div 8);
    LVoice := TEffectVoice.Create(AWave, LChunks.DataOffset, LChunks.DataLength div LFrameBytes, LChunks.Format.Channels,
      LChunks.Format.BitsPerSample, Integer(LChunks.Format.SamplesPerSecond), FRate);
    FVoices.Add(LVoice);
    Result := LVoice;
    Inc(FStatistics.EffectsStarted);
  finally
    FLock.Leave;
  end;
end;

function TGreedPcmMixer.StartMusic(const AModule: TBytes; AVolume: Single): IGreedMusicChannel;
var
  LRenderer: IGreedSongRenderer;
  LSong: ISong;
begin
  Result := nil;
  if not FReady or (Length(AModule) = 0) then
    Exit;
  LRenderer := nil;
  if Assigned(FDecoder) then
    LRenderer := FDecoder.Open(AModule, FRate);
  FLock.Enter;
  try
    if not Assigned(LRenderer) then
    begin
      Inc(FStatistics.SongsRejected);
      Exit;
    end;
    LSong := TSong.Create(LRenderer, AVolume);
    FSong := LSong;
    Result := LSong;
    Inc(FStatistics.SongsStarted);
  finally
    FLock.Leave;
  end;
end;

procedure TGreedPcmMixer.Render(ABuffer: PByte; AByteCount: Integer);
var
  LFrames, LIndex, LValue, LGain: Integer;
  LSong: ISong;
  LOutput: PSmallInt;
  LMusic: Boolean;
begin
  LFrames := AByteCount div 4;
  if LFrames <= 0 then
    Exit;
  FLock.Enter;
  try
    if Length(FSums) < LFrames * 2 then
    begin
      SetLength(FSums, LFrames * 2);
      SetLength(FSongSamples, LFrames * 2);
    end;
    FillChar(FSums[0], LFrames * 2 * SizeOf(Integer), 0);
    LSong := FSong;
    if Assigned(LSong) and LSong.IsStopped then
    begin
      FSong := nil;
      LSong := nil;
    end;
    if Assigned(LSong) then
    begin
      LSong.GetRenderer.Render(FSongSamples, LFrames);
      LGain := Round(LSong.GetVolume * 256);
      for LIndex := 0 to LFrames - 1 do
      begin
        LMusic := (FSongSamples[LIndex * 2] <> 0) or (FSongSamples[LIndex * 2 + 1] <> 0);
        if LMusic then
          Inc(FStatistics.FramesWithMusic);
        FSums[LIndex * 2] := (FSongSamples[LIndex * 2] * LGain) div 256;
        FSums[LIndex * 2 + 1] := (FSongSamples[LIndex * 2 + 1] * LGain) div 256;
      end;
    end;
    // the order does not matter: the sums are wide and are cut once, below
    Inc(FStatistics.EffectsEnded, FVoices.MixAll(@FSums[0], LFrames));
    LOutput := PSmallInt(ABuffer);
    for LIndex := 0 to LFrames * 2 - 1 do
    begin
      LValue := FSums[LIndex];
      if (LValue > High(SmallInt)) or (LValue < Low(SmallInt)) then
      begin
        Inc(FStatistics.ClippedSamples);
        LValue := EnsureRange(LValue, Low(SmallInt), High(SmallInt));
      end;
      if Abs(LValue) > FStatistics.Peak then
        FStatistics.Peak := Min(Abs(LValue), High(SmallInt));
      LOutput^ := SmallInt(LValue);
      Inc(LOutput);
    end;
    for LIndex := 0 to LFrames - 1 do
      if (FSums[LIndex * 2] <> 0) or (FSums[LIndex * 2 + 1] <> 0) then
        Inc(FStatistics.FramesWithSound);
    Inc(FStatistics.FramesRendered, LFrames);
  finally
    FLock.Leave;
  end;
end;

function TGreedPcmMixer.GetRate: Integer;
begin
  Result := FRate;
end;

function TGreedPcmMixer.Statistics: TGreedMixerStatistics;
begin
  FLock.Enter;
  try
    Result := FStatistics;
    Result.ActiveEffects := FVoices.Count;
    Result.SongPlaying := Assigned(FSong);
  finally
    FLock.Leave;
  end;
end;

end.
