{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine system library - the legacy MIDI player                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.EngineSystem.LegacyMidiPlayer;

// Port of i_midi_legacy.pas (issue #185): the songs go through the MCI sequencer of Windows, which
// tells a hidden window when a song ends. The sequencer and the window are given by the caller,
// so that the whole sequence of commands can be tried without a sound card.

interface

uses
  System.SysUtils, DelphiDoom.Logging.Intf, DelphiDoom.EngineSystem.Types,
  DelphiDoom.EngineSystem.Intf, DelphiDoom.EngineSystem.MidiPlaylist;

type
  /// <summary>
  ///   The MIDI player of snd_uselegacymidiplayer = 1: a play list, one song at a time, and the
  ///   next one (or the same again, if it is the only one) when the sequencer says that it ended
  /// </summary>
  TLegacyMidiPlayer = class(TInterfacedObject, ILegacyMidiPlayer)
  strict private
    FSequencer: IMciSequencer;
    FWindows: IMidiNotifyWindow;
    FLog: ILog;
    FPlaylist: TMidiPlaylist;
    FDeviceId: Cardinal;
    FWindow: NativeUInt;
    FCurrentMidi: string;
    function PlayFile(const AFileName: string; ACheckMapper: Boolean): Cardinal;
    function RestartFile: Cardinal;
    procedure StopPlaying;
    procedure HandleNotify(ASuccessful: Boolean);
  public
    /// <summary>EArgumentNilException if one of the three is nil</summary>
    constructor Create(const ASequencer: IMciSequencer; const AWindows: IMidiNotifyWindow;
      const ALog: ILog);
    destructor Destroy; override;
    procedure Initialize;
    procedure ShutDown;
    procedure AddFile(const AFileName: string);
    procedure ClearPlayList;
    procedure Play(AIndex: Integer);
    procedure Stop;
    procedure Pause;
    procedure Resume;
    procedure SetVolume(ALevel: Integer);
    procedure Process;
  end;

const
  /// <summary>Written (without a line break) when the song cannot be played on the MIDI mapper</summary>
  LEGACY_MIDI_NO_MAPPER = 'MIDI mapper unavailable';

implementation

{ TLegacyMidiPlayer }

constructor TLegacyMidiPlayer.Create(const ASequencer: IMciSequencer;
  const AWindows: IMidiNotifyWindow; const ALog: ILog);
begin
  inherited Create;
  if not Assigned(ASequencer) then
    raise EArgumentNilException.CreateFmt(SNullPointerArgument, ['ASequencer']);
  if not Assigned(AWindows) then
    raise EArgumentNilException.CreateFmt(SNullPointerArgument, ['AWindows']);
  if not Assigned(ALog) then
    raise EArgumentNilException.CreateFmt(SNullPointerArgument, ['ALog']);
  FSequencer := ASequencer;
  FWindows := AWindows;
  FLog := ALog;
  FPlaylist := TMidiPlaylist.Create;
end;

destructor TLegacyMidiPlayer.Destroy;
begin
  FPlaylist.Free;
  inherited Destroy;
end;

// playMIDIFile of the old code: it returns as soon as playback begins; the window is told when it ends
function TLegacyMidiPlayer.PlayFile(const AFileName: string; ACheckMapper: Boolean): Cardinal;
var
  LDevice: Cardinal;
  LIsMapper: Boolean;
  LChecked: Boolean;
begin
  // MCI attempts to choose the MIDI mapper as the output port
  Result := FSequencer.Open(AFileName, LDevice);
  // failed to open the device: it is not closed, the error goes back
  if Result <> 0 then
    Exit;

  FDeviceId := LDevice;
  LChecked := True;
  if ACheckMapper then
  begin
    Result := FSequencer.QueryMapperPort(FDeviceId, LIsMapper);
    if Result <> 0 then
    begin
      FSequencer.Close(FDeviceId);
      LChecked := False;
    end
    else if not LIsMapper then
    begin
      // the output port is not the MIDI mapper: the device stays open and nothing plays
      FLog.Info(LEGACY_MIDI_NO_MAPPER);
      LChecked := False;
    end;
  end;

  if LChecked then
  begin
    Result := FSequencer.Play(FDeviceId, FWindow);
    if Result > 0 then
      FSequencer.Close(FDeviceId)
    else
      FCurrentMidi := TMidiPlaylist.Normalize(AFileName);
  end;
end;

// restartMIDIFile of the old code
function TLegacyMidiPlayer.RestartFile: Cardinal;
begin
  Result := FSequencer.SeekToStart(FDeviceId, FWindow);
  if Result > 0 then
    FSequencer.Close(FDeviceId)
  else
  begin
    Result := FSequencer.Play(FDeviceId, FWindow);
    if Result > 0 then
      FSequencer.Close(FDeviceId);
  end;
end;

procedure TLegacyMidiPlayer.StopPlaying;
begin
  FSequencer.Stop(FDeviceId);
  FSequencer.Close(FDeviceId);
  FCurrentMidi := '';
end;

// The window procedure of the old code, on MM_MCINOTIFY
procedure TLegacyMidiPlayer.HandleNotify(ASuccessful: Boolean);
var
  LNewMidi: string;
begin
  if ASuccessful and (FPlaylist.Count > 0) then
  begin
    LNewMidi := TMidiPlaylist.Normalize(FPlaylist.Advance);
    if LNewMidi = FCurrentMidi then
      RestartFile
    else
    begin
      StopPlaying;
      PlayFile(LNewMidi, False);
    end;
  end;
end;

procedure TLegacyMidiPlayer.Initialize;
begin
  FWindow := 0;
  FPlaylist.Reset;
end;

procedure TLegacyMidiPlayer.ShutDown;
begin
  StopPlaying;
  FPlaylist.Clear;
end;

procedure TLegacyMidiPlayer.AddFile(const AFileName: string);
begin
  FPlaylist.Add(AFileName);
end;

procedure TLegacyMidiPlayer.ClearPlayList;
begin
  FPlaylist.Clear;
end;

procedure TLegacyMidiPlayer.Play(AIndex: Integer);
begin
  Stop;
  if FWindow = 0 then
    FWindow := FWindows.Open(HandleNotify);

  if FPlaylist.Select(AIndex) then
    PlayFile(FPlaylist.CurrentName, True)
  else
    // the message of the old code, even if the problem is the index
    FLog.Info(LEGACY_MIDI_NO_MAPPER);
end;

procedure TLegacyMidiPlayer.Stop;
begin
  if FWindow <> 0 then
  begin
    StopPlaying;
    FWindows.Close(FWindow);
    FWindow := 0;
  end;
end;

procedure TLegacyMidiPlayer.Pause;
begin
  FSequencer.Pause(FDeviceId);
end;

procedure TLegacyMidiPlayer.Resume;
begin
  FSequencer.Resume(FDeviceId);
end;

procedure TLegacyMidiPlayer.SetVolume(ALevel: Integer);
begin
  // the legacy player never changed the volume
end;

procedure TLegacyMidiPlayer.Process;
begin
  // the sequencer plays by itself
end;

end.
