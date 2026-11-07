{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - music backend of the XMI songs                          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Music.XmiBackend;

interface

uses
  DelphiDoom.Audio.Types,
  DelphiDoom.Engine.Music.MidiFileBackend;

type
  /// <summary>
  ///   XMI (and CMF) songs are converted to a MIDI file and played like one. The midi device
  ///   belongs to the backend of the MIDI files, so only the converter is started and released
  ///   here. In a DLL build there is no converter: nothing is recognized
  /// </summary>
  TXmiMusicBackend = class(TMidiFileMusicBackend)
  public
    procedure Initialize; override;
    procedure Shutdown; override;
    function Register(AData: Pointer; ASize: Integer;
      out AContext: NativeInt): TMusicRegisterResult; override;
  end;

implementation

uses
{$IFNDEF DLL}
  DelphiDoom.Xmi.Provider,
  m_base,
  i_system,
  i_music,
{$ENDIF}
  d_delphi;

{ TXmiMusicBackend }

procedure TXmiMusicBackend.Initialize;
begin
end;

procedure TXmiMusicBackend.Shutdown;
begin
{$IFNDEF DLL}
  TXmiProvider.Release;
{$ENDIF}
end;

function TXmiMusicBackend.Register(AData: Pointer; ASize: Integer;
  out AContext: NativeInt): TMusicRegisterResult;
{$IFNDEF DLL}
var
  LFileName: string;
{$ENDIF}
begin
  AContext := 0;
{$IFDEF DLL}
  Result := TMusicRegisterResult.NotRecognized;
{$ELSE}
  if not TXmiProvider.Client.IsXmiMusic(AData, ASize) then
  begin
    Result := TMusicRegisterResult.NotRecognized;
    Exit;
  end;

  I_StopMus;

  LFileName := NewSongFile;
  if not TXmiProvider.Client.TryConvertToMidiFile(AData, ASize, 0, LFileName) then
  begin
    I_Warning('I_RegisterSong(): Could not initialize MCI'#13#10);
    Result := TMusicRegisterResult.Failed;
    Exit;
  end;

  PlayFile(LFileName);
  Result := TMusicRegisterResult.Registered;
{$ENDIF}
end;

end.
