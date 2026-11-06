{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - music backend of the MP3 files                          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Music.Mp3Backend;

interface

uses
  DelphiDoom.Audio.Types,
  DelphiDoom.Engine.Music.BackendBase;

type
  /// <summary>
  ///   The song is a mp3header_t (a magic number and the stream of the file), made by s_sound.
  ///   It plays at once when it is registered; the volume cannot be changed
  /// </summary>
  TMp3MusicBackend = class(TEngineMusicBackendBase)
  public
    procedure Initialize; override;
    procedure Shutdown; override;
    function Register(AData: Pointer; ASize: Integer;
      out AContext: NativeInt): TMusicRegisterResult; override;
    procedure Stop(AContext: NativeInt); override;
    procedure Pause(AContext: NativeInt); override;
    procedure Resume(AContext: NativeInt); override;
    procedure PrepareForNewSong; override;
  end;

implementation

uses
  i_mp3,
  i_music;

{ TMp3MusicBackend }

procedure TMp3MusicBackend.Initialize;
begin
  I_InitMP3;
end;

procedure TMp3MusicBackend.Shutdown;
begin
  I_ShutDownMP3;
end;

function TMp3MusicBackend.Register(AData: Pointer; ASize: Integer;
  out AContext: NativeInt): TMusicRegisterResult;
begin
  AContext := 0;
  if Pmp3header_t(AData).ID <> MP3MAGIC then
  begin
    Result := TMusicRegisterResult.NotRecognized;
    Exit;
  end;

  I_PlayMP3(Pmp3header_t(AData).Stream);
  Result := TMusicRegisterResult.Registered;
end;

procedure TMp3MusicBackend.Stop(AContext: NativeInt);
begin
  I_StopMP3;
end;

procedure TMp3MusicBackend.Pause(AContext: NativeInt);
begin
  I_PauseMP3;
end;

procedure TMp3MusicBackend.Resume(AContext: NativeInt);
begin
  I_ResumeMP3;
end;

procedure TMp3MusicBackend.PrepareForNewSong;
begin
  I_StopMP3;
end;

end.
