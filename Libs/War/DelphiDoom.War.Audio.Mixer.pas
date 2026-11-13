{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - mixer of the effects                              }
{                                                                              }
{  Port of audioDataCallback and wa_createAudio* of war_audio.c, war1          }
{  (acoto87/war1), (c) 2019 Alejandro Coto Gutierrez, zlib License (see        }
{  Libs\War\LICENSE-war1.txt). This is an altered version, not the original.   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Audio.Mixer;

interface

uses
  System.SysUtils, System.SyncObjs, DelphiDoom.War.Audio.Types, DelphiDoom.War.Audio.Intf, DelphiDoom.War.Audio.WaveVoice,
  DelphiDoom.AudioMix.Intf, DelphiDoom.AudioMix.VoiceList;

type
  /// <summary>
  ///   The voices that play now. Called by two threads (the game starts and stops voices, the audio output mixes):
  ///   every method takes the lock of the list of voices (TPcmVoiceList of Libs\AudioMix, which holds the voices, the
  ///   handles and the order). The voices of the original are entities of the world, removed by the main
  ///   thread when the audio thread says so; here a finished voice is removed by Mix itself. What is of the game
  ///   (the viewport, the volume, the attenuation of a voice that has a place) stays here
  /// </summary>
  TWarSoundMixer = class(TInterfacedObject, IWarSoundMixer)
  strict private
    type
      /// <summary>One sound that plays: the voice of the samples and where it is on the map</summary>
      TVoice = class(TInterfacedObject, IPcmVoice)
      strict private
        FOwner: TWarSoundMixer;
      public
        Wave: TWarWaveVoice;
        Positional: Boolean;
        X, Y: Single;
        constructor Create(AOwner: TWarSoundMixer);
        destructor Destroy; override;
        function Mix(ADestination: Pointer; ACount: Integer): Boolean;
      end;
  strict private
    FLibrary: IWarAudioLibrary;
    FVoices: TPcmVoiceList;
    FViewportX, FViewportY, FViewportWidth, FViewportHeight: Single;
    FVolume: Single;
    FEnabled: Boolean;
    FSilenced: Boolean;
    function Start(ASoundIndex: Integer; ALoop, APositional: Boolean; AX, AY: Single): Integer;
    function VolumeOf(AVoice: TVoice): Single;
  public
    constructor Create(const ALibrary: IWarAudioLibrary);
    destructor Destroy; override;
    function Play(ASoundIndex: Integer; ALoop: Boolean): Integer;
    function PlayAt(ASoundIndex: Integer; AX, AY: Single; ALoop: Boolean): Integer;
    procedure Stop(AHandle: Integer);
    procedure StopAll;
    procedure SetViewport(AX, AY, AWidth, AHeight: Single);
    procedure SetVolume(AVolume: Single; AEnabled: Boolean);
    procedure SetSilenced(ASilenced: Boolean);
    procedure Mix(ABuffer: PSmallInt; ASampleCount: Integer);
    function ActiveVoices: Integer;
  end;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.War.Audio.Attenuation;

{ TWarSoundMixer.TVoice }

constructor TWarSoundMixer.TVoice.Create(AOwner: TWarSoundMixer);
begin
  inherited Create;
  FOwner := AOwner;
end;

destructor TWarSoundMixer.TVoice.Destroy;
begin
  Wave.Free;
  inherited;
end;

function TWarSoundMixer.TVoice.Mix(ADestination: Pointer; ACount: Integer): Boolean;
begin
  // called by the list with the lock taken, so the state of the mixer cannot change under it
  Result := Wave.Mix(PSmallInt(ADestination), ACount, FOwner.VolumeOf(Self));
end;

{ TWarSoundMixer }

constructor TWarSoundMixer.Create(const ALibrary: IWarAudioLibrary);
begin
  inherited Create;
  if not Assigned(ALibrary) then
    raise EWarException.Create('The audio library of the mixer is nil');
  FLibrary := ALibrary;
  FVoices := TPcmVoiceList.Create;
  // wa_initAudio: musicVolume and soundVolume are 1 and both enabled
  FVolume := 1;
  FEnabled := True;
end;

destructor TWarSoundMixer.Destroy;
begin
  FVoices.Free;
  inherited;
end;

function TWarSoundMixer.Start(ASoundIndex: Integer; ALoop, APositional: Boolean; AX, AY: Single): Integer;
var
  LVoice: TVoice;
  LSound: TWarPcmBuffer;
begin
  // decoded outside the lock: it can take a while the first time
  LSound := FLibrary.GetSound(ASoundIndex);
  LVoice := TVoice.Create(Self);
  LVoice.Wave := TWarWaveVoice.Create(LSound.Data, ALoop);
  LVoice.Positional := APositional;
  LVoice.X := AX;
  LVoice.Y := AY;
  Result := FVoices.Add(LVoice);
end;

function TWarSoundMixer.Play(ASoundIndex: Integer; ALoop: Boolean): Integer;
begin
  Result := Start(ASoundIndex, ALoop, False, 0, 0);
end;

function TWarSoundMixer.PlayAt(ASoundIndex: Integer; AX, AY: Single; ALoop: Boolean): Integer;
begin
  Result := Start(ASoundIndex, ALoop, True, AX, AY);
end;

procedure TWarSoundMixer.Stop(AHandle: Integer);
begin
  FVoices.Remove(AHandle);
end;

procedure TWarSoundMixer.StopAll;
begin
  FVoices.Clear;
end;

procedure TWarSoundMixer.SetViewport(AX, AY, AWidth, AHeight: Single);
begin
  FVoices.Lock.Enter;
  try
    FViewportX := AX;
    FViewportY := AY;
    FViewportWidth := AWidth;
    FViewportHeight := AHeight;
  finally
    FVoices.Lock.Leave;
  end;
end;

procedure TWarSoundMixer.SetVolume(AVolume: Single; AEnabled: Boolean);
begin
  FVoices.Lock.Enter;
  try
    // CLAMP(volume, 0, 1) of wg_setMusicVolume
    if AVolume < 0 then
      AVolume := 0
    else if AVolume > 1 then
      AVolume := 1;
    FVolume := AVolume;
    FEnabled := AEnabled;
  finally
    FVoices.Lock.Leave;
  end;
end;

procedure TWarSoundMixer.SetSilenced(ASilenced: Boolean);
begin
  FVoices.Lock.Enter;
  try
    FSilenced := ASilenced;
  finally
    FVoices.Lock.Leave;
  end;
end;

function TWarSoundMixer.VolumeOf(AVoice: TVoice): Single;
var
  LSoundVolume: Single;
begin
  if FEnabled then
    LSoundVolume := FVolume
  else
    LSoundVolume := 0;
  Result := LSoundVolume;
  if AVoice.Positional then
    // the original gives a voice outside the viewport 0.75 * (...) whatever the sound volume, so a muted sound
    // is still heard from afar: here the factor scales the sound volume (the same where the volume is 1)
    Result := LSoundVolume * TWarSoundAttenuation.Factor(FViewportX, FViewportY, FViewportWidth, FViewportHeight,
      AVoice.X, AVoice.Y);
end;

procedure TWarSoundMixer.Mix(ABuffer: PSmallInt; ASampleCount: Integer);
begin
  FVoices.Lock.Enter;
  try
    if FSilenced or (ASampleCount <= 0) then
      Exit;
    // in the order they were started: the sum saturates, so the order is part of the result
    FVoices.MixAll(ABuffer, ASampleCount);
  finally
    FVoices.Lock.Leave;
  end;
end;

function TWarSoundMixer.ActiveVoices: Integer;
begin
  Result := FVoices.Count;
end;

end.
