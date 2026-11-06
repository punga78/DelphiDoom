{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - music backend of the midi stream (MUS)                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Music.MusBackend;

interface

uses
  DelphiDoom.Audio.Types,
  DelphiDoom.Engine.Music.BackendBase;

type
  /// <summary>
  ///   MUS songs and the MIDI files that are converted to MUS, played with the midi stream of
  ///   Windows. The song is the pointer that i_music gives; the song starts at Play
  /// </summary>
  TMusMusicBackend = class(TEngineMusicBackendBase)
  public
    procedure Initialize; override;
    procedure Shutdown; override;
    function Register(AData: Pointer; ASize: Integer;
      out AContext: NativeInt): TMusicRegisterResult; override;
    procedure Play(AContext: NativeInt; ALooping: Boolean); override;
    procedure Stop(AContext: NativeInt); override;
    procedure Pause(AContext: NativeInt); override;
    procedure Resume(AContext: NativeInt); override;
    procedure Unregister(AContext: NativeInt); override;
    procedure SetVolume(AVolume: Integer); override;
    procedure Process; override;
  end;

implementation

uses
  i_music;

{ TMusMusicBackend }

procedure TMusMusicBackend.Initialize;
begin
  I_InitMus;
end;

procedure TMusMusicBackend.Shutdown;
begin
  I_StopMus;
end;

function TMusMusicBackend.Register(AData: Pointer; ASize: Integer;
  out AContext: NativeInt): TMusicRegisterResult;
var
  LSong: Pointer;
begin
  Result := I_RegisterMus(AData, ASize, LSong);
  AContext := NativeInt(LSong);
end;

procedure TMusMusicBackend.Play(AContext: NativeInt; ALooping: Boolean);
begin
  I_PlayMus(Pointer(AContext));
end;

procedure TMusMusicBackend.Stop(AContext: NativeInt);
begin
  I_StopSongMus(Pointer(AContext));
end;

procedure TMusMusicBackend.Pause(AContext: NativeInt);
begin
  I_PauseSongMus(0);
end;

procedure TMusMusicBackend.Resume(AContext: NativeInt);
begin
  I_ResumeSongMus(0);
end;

procedure TMusMusicBackend.Unregister(AContext: NativeInt);
begin
  I_UnRegisterSongMus(Pointer(AContext));
end;

procedure TMusMusicBackend.SetVolume(AVolume: Integer);
begin
  I_SetMusicVolumeMus(AVolume);
end;

procedure TMusMusicBackend.Process;
begin
  I_ProcessMusicMus;
end;

end.
