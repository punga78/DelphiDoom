{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - the software mixer of the sound effects          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.Mixer;
{$Q-}
{$R-}
// the voices add to 32 bit sums that are cut to 16 bits at the end

interface

uses
  System.SyncObjs,
  DelphiDoom.AudioMix.Intf,
  DelphiDoom.AudioMix.VoiceList,
  DelphiDoom.Audio.Types,
  DelphiDoom.Audio.Intf,
  DelphiDoom.Audio.Mixer.Intf;

type
  /// <summary>
  ///   The voices that play, summed in 32 bits and cut once to 16 bit stereo. The game starts and stops voices from
  ///   its thread, the audio output calls Render from its own: the list of the voices has the lock
  /// </summary>
  TSfxMixer = class(TInterfacedObject, ISfxMixer, ISfxVoiceScheduler)
  strict private
    FOutputRate: Integer;
    FVoices: TPcmVoiceList;
    // only the thread of the output uses it
    FSums: TArray<Integer>;
  public
    /// <param name="AOutputRate">Frames per second of the buffers given to Render</param>
    constructor Create(AOutputRate: Integer);
    destructor Destroy; override;
    function CreateVoice(const ASample: TSfxSample; out AVoice: IAudioVoice): Integer;
    procedure Render(ABuffer: PByte; AByteCount: Integer);
    procedure Clear;
    function GetLock: TCriticalSection;
    function Start(const AVoice: IPcmVoice): Integer;
    procedure Remove(AHandle: Integer);
    /// <summary>How many voices play now</summary>
    function ActiveVoiceCount: Integer;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.AudioMix.Saturation,
  DelphiDoom.Audio.Mixer.Voice;

{ TSfxMixer }

constructor TSfxMixer.Create(AOutputRate: Integer);
begin
  inherited Create;
  if AOutputRate <= 0 then
    raise EArgumentOutOfRangeException.Create('AOutputRate');
  FOutputRate := AOutputRate;
  FVoices := TPcmVoiceList.Create;
end;

destructor TSfxMixer.Destroy;
begin
  FVoices.Free;
  inherited Destroy;
end;

function TSfxMixer.CreateVoice(const ASample: TSfxSample; out AVoice: IAudioVoice): Integer;
begin
  AVoice := nil;
  if (ASample.Format.Tag <> 1) or not (ASample.Format.BitsPerSample in [8, 16]) or
     not (ASample.Format.Channels in [1, 2]) or (ASample.Format.SamplesPerSecond = 0) then
    Exit(SFX_MIXER_BAD_FORMAT);
  AVoice := TSfxMixerVoice.Create(Self, ASample.Format.Channels, Integer(ASample.Format.SamplesPerSecond),
    FOutputRate);
  Result := 0;
end;

procedure TSfxMixer.Render(ABuffer: PByte; AByteCount: Integer);
var
  LFrames: Integer;
  LIndex: Integer;
  LOutput: PSmallInt;
begin
  LFrames := AByteCount div 4;
  if Length(FSums) < LFrames * 2 then
    SetLength(FSums, LFrames * 2);
  if LFrames > 0 then
  begin
    FillChar(FSums[0], LFrames * 2 * SizeOf(Integer), 0);
    FVoices.MixAll(@FSums[0], LFrames);
  end;
  LOutput := PSmallInt(ABuffer);
  for LIndex := 0 to LFrames * 2 - 1 do
  begin
    LOutput^ := TPcmSaturation.Clamp(FSums[LIndex]);
    Inc(LOutput);
  end;
end;

procedure TSfxMixer.Clear;
begin
  FVoices.Clear;
end;

function TSfxMixer.GetLock: TCriticalSection;
begin
  Result := FVoices.Lock;
end;

function TSfxMixer.Start(const AVoice: IPcmVoice): Integer;
begin
  Result := FVoices.Add(AVoice);
end;

procedure TSfxMixer.Remove(AHandle: Integer);
begin
  FVoices.Remove(AHandle);
end;

function TSfxMixer.ActiveVoiceCount: Integer;
begin
  Result := FVoices.Count;
end;

end.
