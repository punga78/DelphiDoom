{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - player of the MIDI files on the midi stream             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Midi.SongPlayer;

interface

uses
  DelphiDoom.Logging.Intf,
  DelphiDoom.Midi.Intf,
  DelphiDoom.Engine.Midi.Intf,
  DelphiDoom.Engine.Midi.StreamPlayer;

type
  /// <summary>The midi device to use, asked every time a song starts (-mididevice)</summary>
  TMidiDeviceSelector = function: LongWord;

  /// <summary>
  ///   The old i_midi_new: reads the file, gets a sequencer for it and plays it with a
  ///   TEngineMidiStreamPlayer. It replaces the unit with its global player
  /// </summary>
  TEngineMidiSongPlayer = class(TInterfacedObject, IEngineMidiSongPlayer)
  strict private
    FSequencers: IMidiStreamSequencerFactory;
    FLog: ILog;
    FSelectDevice: TMidiDeviceSelector;
    FPlayer: TEngineMidiStreamPlayer;
    FMasterVolume: Integer;
  public
    /// <summary>EArgumentNilException if ASequencers, ALog or ASelectDevice is nil</summary>
    constructor Create(const ASequencers: IMidiStreamSequencerFactory; const ALog: ILog;
      ASelectDevice: TMidiDeviceSelector);
    destructor Destroy; override;
    procedure Play(const AFileName: string);
    procedure Stop;
    procedure Pause;
    procedure Resume;
    procedure Initialize;
    procedure ShutDown;
    procedure SetVolume(ALevel: Integer);
    procedure Process;
  end;

implementation

uses
  System.SysUtils,
  d_delphi,
  i_system,
  DelphiDoom.Midi.Volume;

constructor TEngineMidiSongPlayer.Create(const ASequencers: IMidiStreamSequencerFactory;
  const ALog: ILog; ASelectDevice: TMidiDeviceSelector);
begin
  inherited Create;
  if not Assigned(ASequencers) then
    raise EArgumentNilException.Create('ASequencers');
  if not Assigned(ALog) then
    raise EArgumentNilException.Create('ALog');
  if not Assigned(ASelectDevice) then
    raise EArgumentNilException.Create('ASelectDevice');
  FSequencers := ASequencers;
  FLog := ALog;
  FSelectDevice := ASelectDevice;
end;

destructor TEngineMidiSongPlayer.Destroy;
begin
  FreeAndNil(FPlayer);
  inherited Destroy;
end;

procedure TEngineMidiSongPlayer.Play(const AFileName: string);
var
  LFile: TFile;
  LData: TBytes;
  LSequencer: IMidiStreamSequencer;
begin
  FreeAndNil(FPlayer);

  LFile := TFile.Create(AFileName, fOpenReadOnly);
  try
    SetLength(LData, LFile.Size);
    if Length(LData) > 0 then
      LFile.Read(LData[0], Length(LData));
  finally
    LFile.Free;
  end;

  // a file that is not a MIDI file that can be read is a warning of the sequencer and no song
  LSequencer := FSequencers.CreateSequencer;
  if (Length(LData) = 0) or not LSequencer.Load(@LData[0], Length(LData)) then
  begin
    FLog.Warning(Format('I_PlayMidi(): %s is not a MIDI file that can be played'#13#10,
      [AFileName]));
    Exit;
  end;

  FPlayer := TEngineMidiStreamPlayer.Create(LSequencer, FSelectDevice());
  if not FPlayer.Load then
    I_Error('I_PlayMidi(): Can not setup stream buffer');
  FPlayer.Play(True);
end;

procedure TEngineMidiSongPlayer.Stop;
begin
  if Assigned(FPlayer) then
  begin
    FPlayer.Stop;
    FreeAndNil(FPlayer);
  end;
end;

procedure TEngineMidiSongPlayer.Pause;
begin
  if Assigned(FPlayer) then
    FPlayer.Pause;
end;

procedure TEngineMidiSongPlayer.Resume;
begin
  if Assigned(FPlayer) then
    FPlayer.Resume;
end;

procedure TEngineMidiSongPlayer.Initialize;
begin
  FPlayer := nil;
end;

procedure TEngineMidiSongPlayer.ShutDown;
begin
  FreeAndNil(FPlayer);
end;

procedure TEngineMidiSongPlayer.SetVolume(ALevel: Integer);
begin
  if Assigned(FPlayer) then
  begin
    FMasterVolume := TMidiVolume.PercentOfLevel(ALevel);
    FPlayer.SetMasterVolume(FMasterVolume);
  end;
end;

procedure TEngineMidiSongPlayer.Process;
begin
  if Assigned(FPlayer) then
    FPlayer.SetMasterVolume(FMasterVolume);
end;

end.
