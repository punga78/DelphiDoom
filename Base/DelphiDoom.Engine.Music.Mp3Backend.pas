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
  DelphiDoom.Mp3.Intf,
  DelphiDoom.Audio.Mp3Player,
  DelphiDoom.Engine.Music.BackendBase;

type
  /// <summary>
  ///   The song is a mp3header_t (a magic number and the stream of the file), made by s_sound.
  ///   It plays at once when it is registered; the volume cannot be changed. Every song has a
  ///   new player over the IMp3 that the composition root gives (it was the facade i_mp3)
  /// </summary>
  TMp3MusicBackend = class(TEngineMusicBackendBase)
  private
    FMp3: IMp3;
    FPlayer: TMp3Player;
    procedure StopPlayer;
  public
    /// <summary>Raises EArgumentNilException if AMp3 is nil</summary>
    constructor Create(const AMp3: IMp3);
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
  System.SysUtils,
  d_delphi,
  i_music,
  sounds;

const
  SMp3IsNil = 'TMp3MusicBackend: the mp3 library is nil';

{ TMp3MusicBackend }

constructor TMp3MusicBackend.Create(const AMp3: IMp3);
begin
  inherited Create;
  if not Assigned(AMp3) then
    raise EArgumentNilException.Create(SMp3IsNil);
  FMp3 := AMp3;
end;

procedure TMp3MusicBackend.StopPlayer;
begin
  if FPlayer <> nil then
  begin
    FPlayer.Stop;
    FreeAndNil(FPlayer);
  end;
end;

procedure TMp3MusicBackend.Initialize;
begin
  FPlayer := TMp3Player.Create(FMp3);
end;

procedure TMp3MusicBackend.Shutdown;
begin
  StopPlayer;
  S_FreeMP3Streams;
end;

function TMp3MusicBackend.Register(AData: Pointer; ASize: Integer;
  out AContext: NativeInt): TMusicRegisterResult;
var
  LStream: TDStream;
  LBuffer: Pointer;
  LSize: Integer;
begin
  AContext := 0;
  if Pmp3header_t(AData).ID <> MP3MAGIC then
  begin
    Result := TMusicRegisterResult.NotRecognized;
    Exit;
  end;

  // a new player for every song, as before
  StopPlayer;
  FPlayer := TMp3Player.Create(FMp3);

  LStream := Pmp3header_t(AData).Stream;
  LSize := LStream.Size;
  LBuffer := malloc(LSize);
  try
    LStream.Seek(0, sFromBeginning);
    LStream.Read(LBuffer^, LSize);
    FPlayer.Play(LBuffer, LSize, True);
  finally
    memfree(LBuffer, LSize);
  end;
  Result := TMusicRegisterResult.Registered;
end;

procedure TMp3MusicBackend.Stop(AContext: NativeInt);
begin
  StopPlayer;
end;

procedure TMp3MusicBackend.Pause(AContext: NativeInt);
begin
  if FPlayer <> nil then
    FPlayer.Pause;
end;

procedure TMp3MusicBackend.Resume(AContext: NativeInt);
begin
  if FPlayer <> nil then
    FPlayer.Resume;
end;

procedure TMp3MusicBackend.PrepareForNewSong;
begin
  StopPlayer;
end;

end.
