{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - the sound cache of Doom 3                       }
{                                                                              }
{  Port of idSoundCache::FindSound and idSoundSample::Load, GetNewTimeStamp    }
{  and MakeDefault (sound\snd_cache.cpp), without OpenAL (no hardware          }
{  buffers, no amplitude data) and without the 22 kHz downsampling             }
{  (s_force22kHz, off by default).                                             }
{  Based on the Doom 3 GPL Source Code (id Software). This unit is derived     }
{  from it and is therefore available under the GNU General Public License,    }
{  version 3, with the additional terms of the Doom 3 Source Code License      }
{  (see Reference\doom3\README.txt and Libs\IdLib\README.md); the repository   }
{  as a whole is GPL v2 or later. Copyright (C) 1999-2011 id Software LLC.     }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.SoundSample.Cache;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Logging.Intf, DelphiDoom.Audio.WaveFile.Types,
  DelphiDoom.Audio.WaveFile.Intf, DelphiDoom.Audio.SoundSample.Types;

type
  /// <summary>
  ///   The sounds that were asked for by name: <c>FindSound</c> canonicalizes the name (backslashes to slashes,
  ///   lower case), loads the sound the first time (a sound that is not there, is not mono or stereo, not 16 bit or
  ///   not 11025, 22050 or 44100 Hz gets a warning and the default sound, a sine wave of 64 samples a period) and
  ///   gives the same object for the same name afterwards. The cache owns the samples. Not thread safe
  /// </summary>
  TSoundSampleCache = class
  strict private
    FFileSystem: IWaveFileSystem;
    FOggDecoder: IWaveOggDecoder;
    FLog: ILog;
    FSamples: TObjectList<TSoundSample>;
    FRealTimeDecoding: Boolean;
    function Load(const AName: string): TSoundSample;
    function MakeDefault(const AName: string): TSoundSample;
    procedure Warn(const AText: string);
  public
    /// <summary>The decoder and the log are optional (no OGG files; no warnings)</summary>
    constructor Create(const AFileSystem: IWaveFileSystem; const AOggDecoder: IWaveOggDecoder = nil;
      const ALog: ILog = nil);
    destructor Destroy; override;
    /// <summary>idSoundCache::FindSound: the sample of a name, loaded on first use</summary>
    function FindSound(const AName: string): TSoundSample;
    /// <summary>idSoundCache::GetNumObjects: the samples in the cache</summary>
    function Count: Integer;
    /// <summary>ReloadSounds: forgets every sample (they are loaded again when asked for)</summary>
    procedure Clear;
    /// <summary>s_realTimeDecoding: OGG files are left encoded</summary>
    property RealTimeDecoding: Boolean read FRealTimeDecoding write FRealTimeDecoding;
  end;

implementation

uses
  DelphiDoom.Audio.WaveFile;

{ TSoundSampleCache }

constructor TSoundSampleCache.Create(const AFileSystem: IWaveFileSystem; const AOggDecoder: IWaveOggDecoder;
  const ALog: ILog);
begin
  inherited Create;
  FFileSystem := AFileSystem;
  FOggDecoder := AOggDecoder;
  FLog := ALog;
  FSamples := TObjectList<TSoundSample>.Create(True);
end;

destructor TSoundSampleCache.Destroy;
begin
  FSamples.Free;
  inherited Destroy;
end;

procedure TSoundSampleCache.Warn(const AText: string);
begin
  if Assigned(FLog) then
    FLog.Warning(AText);
end;

function TSoundSampleCache.Count: Integer;
begin
  Result := FSamples.Count;
end;

procedure TSoundSampleCache.Clear;
begin
  FSamples.Clear;
end;

function TSoundSampleCache.MakeDefault(const AName: string): TSoundSample;
var
  LFormat: TWaveFormat;
  LData: TBytes;
  LIndex: Integer;
  LAngle: Single;
  LValue: Single;
  LSample: SmallInt;
begin
  LFormat := Default(TWaveFormat);
  LFormat.Channels := 1;
  LFormat.BitsPerSample := 16;
  LFormat.SamplesPerSecond := 44100;
  SetLength(LData, SOUND_MIXBUFFER_SAMPLES * 2 * SizeOf(SmallInt));
  for LIndex := 0 to SOUND_MIXBUFFER_SAMPLES - 1 do
  begin
    // v = sin(idMath::PI * 2 * i / 64); sample = v * 0x4000, each operation in single precision
    LAngle := Single(3.14159265358979323846);
    LAngle := LAngle * 2;
    LAngle := LAngle * LIndex;
    LAngle := LAngle / 64;
    LValue := Sin(Double(LAngle));
    LValue := LValue * $4000;
    LSample := SmallInt(Trunc(LValue));
    // ncd[i * 2 + 0] and ncd[i * 2 + 1] are the same sample
    PSmallInt(@LData[LIndex * 4])^ := LSample;
    PSmallInt(@LData[LIndex * 4 + 2])^ := LSample;
  end;
  Result := TSoundSample.Create(AName, LFormat, SOUND_MIXBUFFER_SAMPLES * 2,
    SOUND_MIXBUFFER_SAMPLES * 2 * SizeOf(SmallInt), LData, True);
end;

function TSoundSampleCache.Load(const AName: string): TSoundSample;
var
  LFile: TWaveFile;
  LFormat: TWaveFormat;
  LData: TBytes;
  LRead: Integer;
  LOggName: string;
  LFound: Boolean;
begin
  // GetNewTimeStamp: the file, then the file with the extension .ogg
  LFound := FFileSystem.FileLength(AName) <> -1;
  if not LFound then
  begin
    LOggName := TWaveFile.OggName(AName);
    LFound := FFileSystem.FileLength(LOggName) <> -1;
  end;
  if not LFound then
  begin
    Warn(Format('Couldn''t load sound ''%s'' using default', [AName]));
    Exit(MakeDefault(AName));
  end;
  LFile := TWaveFile.Create(FFileSystem, FOggDecoder);
  try
    LFile.RealTimeDecoding := FRealTimeDecoding;
    if LFile.Open(AName, LFormat) = -1 then
    begin
      Warn(Format('Couldn''t load sound ''%s'' using default', [AName]));
      Exit(MakeDefault(AName));
    end;
    if (LFormat.Channels <> 1) and (LFormat.Channels <> 2) then
    begin
      Warn(Format('idSoundSample: %s has %d channels, using default', [AName, LFormat.Channels]));
      Exit(MakeDefault(AName));
    end;
    if LFormat.BitsPerSample <> 16 then
    begin
      Warn(Format('idSoundSample: %s is %dbits, expected 16bits using default', [AName, LFormat.BitsPerSample]));
      Exit(MakeDefault(AName));
    end;
    if (LFormat.SamplesPerSecond <> 44100) and (LFormat.SamplesPerSecond <> 22050) and
      (LFormat.SamplesPerSecond <> 11025) then
    begin
      Warn(Format('idSoundCache: %s is %dHz, expected 11025, 22050 or 44100 Hz. Using default',
        [AName, LFormat.SamplesPerSecond]));
      Exit(MakeDefault(AName));
    end;
    SetLength(LData, LFile.MemorySize);
    LRead := 0;
    if Length(LData) > 0 then
      LFile.Read(@LData[0], Length(LData), LRead);
    // a file shorter than its header says gives fewer bytes: the rest is zero, as the memory of the cache
    Result := TSoundSample.Create(AName, LFormat, LFile.OutputSize, LFile.MemorySize, LData, False);
  finally
    LFile.Free;
  end;
end;

function TSoundSampleCache.FindSound(const AName: string): TSoundSample;
var
  LName: string;
  LSample: TSoundSample;
begin
  LName := LowerCase(StringReplace(AName, '\', '/', [rfReplaceAll]));
  for LSample in FSamples do
    if LSample.Name = LName then
      Exit(LSample);
  Result := Load(LName);
  FSamples.Add(Result);
end;

end.
