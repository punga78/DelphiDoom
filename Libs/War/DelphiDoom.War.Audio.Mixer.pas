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
  System.SysUtils, System.Classes, System.SyncObjs, System.Generics.Collections, DelphiDoom.War.Audio.Types,
  DelphiDoom.War.Audio.Intf, DelphiDoom.War.Audio.WaveVoice;

type
  /// <summary>
  ///   The voices that play now. Called by two threads (the game starts and stops voices, the audio output mixes):
  ///   every method takes a lock. The voices of the original are entities of the world, removed by the main
  ///   thread when the audio thread says so; here a finished voice is removed by Mix itself
  /// </summary>
  TWarSoundMixer = class(TInterfacedObject, IWarSoundMixer)
  strict private
    type
      TVoice = class
        Handle: Integer;
        Wave: TWarWaveVoice;
        Positional: Boolean;
        X, Y: Single;
        destructor Destroy; override;
      end;
  strict private
    FLibrary: IWarAudioLibrary;
    FLock: TCriticalSection;
    FVoices: TObjectList<TVoice>;
    FNextHandle: Integer;
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

destructor TWarSoundMixer.TVoice.Destroy;
begin
  Wave.Free;
  inherited;
end;

{ TWarSoundMixer }

constructor TWarSoundMixer.Create(const ALibrary: IWarAudioLibrary);
begin
  inherited Create;
  if not Assigned(ALibrary) then
    raise EWarException.Create('The audio library of the mixer is nil');
  FLibrary := ALibrary;
  FLock := TCriticalSection.Create;
  FVoices := TObjectList<TVoice>.Create(True);
  FNextHandle := 1;
  // wa_initAudio: musicVolume and soundVolume are 1 and both enabled
  FVolume := 1;
  FEnabled := True;
end;

destructor TWarSoundMixer.Destroy;
begin
  FVoices.Free;
  FLock.Free;
  inherited;
end;

function TWarSoundMixer.Start(ASoundIndex: Integer; ALoop, APositional: Boolean; AX, AY: Single): Integer;
var
  LVoice: TVoice;
  LSound: TWarPcmBuffer;
begin
  // decoded outside the lock: it can take a while the first time
  LSound := FLibrary.GetSound(ASoundIndex);
  LVoice := TVoice.Create;
  LVoice.Wave := TWarWaveVoice.Create(LSound.Data, ALoop);
  LVoice.Positional := APositional;
  LVoice.X := AX;
  LVoice.Y := AY;
  FLock.Enter;
  try
    LVoice.Handle := FNextHandle;
    Inc(FNextHandle);
    FVoices.Add(LVoice);
    Result := LVoice.Handle;
  finally
    FLock.Leave;
  end;
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
var
  LIndex: Integer;
begin
  FLock.Enter;
  try
    for LIndex := FVoices.Count - 1 downto 0 do
      if FVoices[LIndex].Handle = AHandle then
        FVoices.Delete(LIndex);
  finally
    FLock.Leave;
  end;
end;

procedure TWarSoundMixer.StopAll;
begin
  FLock.Enter;
  try
    FVoices.Clear;
  finally
    FLock.Leave;
  end;
end;

procedure TWarSoundMixer.SetViewport(AX, AY, AWidth, AHeight: Single);
begin
  FLock.Enter;
  try
    FViewportX := AX;
    FViewportY := AY;
    FViewportWidth := AWidth;
    FViewportHeight := AHeight;
  finally
    FLock.Leave;
  end;
end;

procedure TWarSoundMixer.SetVolume(AVolume: Single; AEnabled: Boolean);
begin
  FLock.Enter;
  try
    // CLAMP(volume, 0, 1) of wg_setMusicVolume
    if AVolume < 0 then
      AVolume := 0
    else if AVolume > 1 then
      AVolume := 1;
    FVolume := AVolume;
    FEnabled := AEnabled;
  finally
    FLock.Leave;
  end;
end;

procedure TWarSoundMixer.SetSilenced(ASilenced: Boolean);
begin
  FLock.Enter;
  try
    FSilenced := ASilenced;
  finally
    FLock.Leave;
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
var
  LIndex: Integer;
  LVoice: TVoice;
begin
  FLock.Enter;
  try
    if FSilenced or (ASampleCount <= 0) then
      Exit;
    // in the order they were started: the sum saturates, so the order is part of the result
    LIndex := 0;
    while LIndex < FVoices.Count do
    begin
      LVoice := FVoices[LIndex];
      if LVoice.Wave.Mix(ABuffer, ASampleCount, VolumeOf(LVoice)) then
        FVoices.Delete(LIndex)
      else
        Inc(LIndex);
    end;
  finally
    FLock.Leave;
  end;
end;

function TWarSoundMixer.ActiveVoices: Integer;
begin
  FLock.Enter;
  try
    Result := FVoices.Count;
  finally
    FLock.Leave;
  end;
end;

end.
