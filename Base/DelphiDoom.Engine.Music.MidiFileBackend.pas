{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - music backend of the MIDI files (played with MCI)       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Music.MidiFileBackend;

interface

uses
  DelphiDoom.Audio.Types,
  DelphiDoom.Platform.Intf,
  DelphiDoom.Engine.Music.BackendBase;

type
  /// <summary>
  ///   A standard MIDI file is written to a temporary file and played from there. It plays at
  ///   once when it is registered. Starting it closes the midi stream of the MUS songs
  /// </summary>
  TMidiFileMusicBackend = class(TEngineMusicBackendBase)
  strict private
    FTempFiles: ITempFiles;
  protected
    /// <summary>A new temporary file for a song, deleted when the engine shuts down</summary>
    function NewSongFile: string;
    /// <summary>Plays a file; false if the file could not be made</summary>
    procedure PlayFile(const AFileName: string);
  public
    /// <summary>ATempFiles gives the file a song is written to</summary>
    constructor Create(const ATempFiles: ITempFiles);
    procedure Initialize; override;
    procedure Shutdown; override;
    function Register(AData: Pointer; ASize: Integer;
      out AContext: NativeInt): TMusicRegisterResult; override;
    procedure Stop(AContext: NativeInt); override;
    procedure Pause(AContext: NativeInt); override;
    procedure Resume(AContext: NativeInt); override;
    procedure SetVolume(AVolume: Integer); override;
    procedure Process; override;
    procedure PrepareForNewSong; override;
  end;

implementation

uses
  System.SysUtils,
  d_delphi,
  m_base,
  i_system,
  i_midi,
  i_music,
  s_sound;

{ TMidiFileMusicBackend }

constructor TMidiFileMusicBackend.Create(const ATempFiles: ITempFiles);
begin
  inherited Create;
  if not Assigned(ATempFiles) then
    raise EArgumentNilException.Create('TMidiFileMusicBackend.Create(): ATempFiles is nil');
  FTempFiles := ATempFiles;
end;

function TMidiFileMusicBackend.NewSongFile: string;
begin
  Result := FTempFiles.NewTempFile(_GAME + '.mid');
end;

procedure TMidiFileMusicBackend.Initialize;
begin
  I_InitMidi;
end;

procedure TMidiFileMusicBackend.Shutdown;
begin
  I_StopMidi;
  I_ShutDownMidi;
end;

procedure TMidiFileMusicBackend.PlayFile(const AFileName: string);
begin
  I_PlayMidi(AFileName);
  I_SetMusicVolumeMidi(snd_MusicVolume);
end;

function TMidiFileMusicBackend.Register(AData: Pointer; ASize: Integer;
  out AContext: NativeInt): TMusicRegisterResult;
var
  LFileName: string;
  LFile: file;
  LDone: boolean;
begin
  AContext := 0;
  if not ((ASize > 4) and (PLongWord(AData)^ = MThd)) then
  begin
    Result := TMusicRegisterResult.NotRecognized;
    Exit;
  end;

  I_StopMus;

  LFileName := NewSongFile;

  LDone := fopen(LFile, LFileName, fCreate);
  if LDone then
  begin
    {$I-}
    BlockWrite(LFile, AData^, ASize);
    close(LFile);
    {$I+}
    LDone := IOResult = 0;
  end;

  if not LDone then
  begin
    I_Warning('I_RegisterSong(): Could not initialize MCI'#13#10);
    Result := TMusicRegisterResult.Failed;
    Exit;
  end;

  PlayFile(LFileName);
  Result := TMusicRegisterResult.Registered;
end;

procedure TMidiFileMusicBackend.Stop(AContext: NativeInt);
begin
  I_StopMidi;
end;

procedure TMidiFileMusicBackend.Pause(AContext: NativeInt);
begin
  I_PauseMidi;
end;

procedure TMidiFileMusicBackend.Resume(AContext: NativeInt);
begin
  I_ResumeMidi;
end;

procedure TMidiFileMusicBackend.SetVolume(AVolume: Integer);
begin
  I_SetMusicVolumeMidi(AVolume);
end;

procedure TMidiFileMusicBackend.Process;
begin
  I_ProcessMidi;
end;

procedure TMidiFileMusicBackend.PrepareForNewSong;
begin
  I_StopMidi;
end;

end.
