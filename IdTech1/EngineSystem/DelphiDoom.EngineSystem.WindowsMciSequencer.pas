{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine system library - the MCI sequencer of Windows            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.EngineSystem.WindowsMciSequencer;

// The mciSendCommand calls of i_midi_legacy.pas (issue #185), one method for each command.

interface

uses
  DelphiDoom.EngineSystem.Intf;

type
  /// <summary>The commands of the "sequencer" device of MCI</summary>
  TWindowsMciSequencer = class(TInterfacedObject, IMciSequencer)
  public
    function Open(const AFileName: string; out ADeviceId: Cardinal): Cardinal;
    function QueryMapperPort(ADeviceId: Cardinal; out AIsMapper: Boolean): Cardinal;
    function Play(ADeviceId: Cardinal; ANotifyWindow: NativeUInt): Cardinal;
    function SeekToStart(ADeviceId: Cardinal; ANotifyWindow: NativeUInt): Cardinal;
    procedure Stop(ADeviceId: Cardinal);
    procedure Close(ADeviceId: Cardinal);
    procedure Pause(ADeviceId: Cardinal);
    procedure Resume(ADeviceId: Cardinal);
  end;

implementation

uses
  Winapi.Windows, Winapi.MMSystem;

const
  SEQUENCER_DEVICE = 'sequencer';

{ TWindowsMciSequencer }

function TWindowsMciSequencer.Open(const AFileName: string; out ADeviceId: Cardinal): Cardinal;
var
  LParameters: MCI_OPEN_PARMS;
begin
  ADeviceId := 0;
  // MCI attempts to choose the MIDI mapper as the output port
  ZeroMemory(@LParameters, SizeOf(LParameters));
  LParameters.lpstrDeviceType := PChar(SEQUENCER_DEVICE);
  LParameters.lpstrElementName := PChar(AFileName);
  Result := mciSendCommand(0, MCI_OPEN, MCI_OPEN_TYPE or MCI_OPEN_ELEMENT,
    DWORD_PTR(@LParameters));
  if Result = 0 then
    ADeviceId := LParameters.wDeviceID;
end;

function TWindowsMciSequencer.QueryMapperPort(ADeviceId: Cardinal;
  out AIsMapper: Boolean): Cardinal;
var
  LParameters: MCI_STATUS_PARMS;
begin
  AIsMapper := False;
  ZeroMemory(@LParameters, SizeOf(LParameters));
  LParameters.dwItem := MCI_SEQ_STATUS_PORT;
  Result := mciSendCommand(ADeviceId, MCI_STATUS, MCI_STATUS_ITEM, DWORD_PTR(@LParameters));
  if Result = 0 then
    AIsMapper := LOWORD(LParameters.dwReturn) = WORD(MIDI_MAPPER);
end;

function TWindowsMciSequencer.Play(ADeviceId: Cardinal; ANotifyWindow: NativeUInt): Cardinal;
var
  LParameters: MCI_PLAY_PARMS;
begin
  ZeroMemory(@LParameters, SizeOf(LParameters));
  LParameters.dwCallback := ANotifyWindow;
  Result := mciSendCommand(ADeviceId, MCI_PLAY, MCI_NOTIFY, DWORD_PTR(@LParameters));
end;

function TWindowsMciSequencer.SeekToStart(ADeviceId: Cardinal;
  ANotifyWindow: NativeUInt): Cardinal;
var
  LParameters: MCI_SEEK_PARMS;
begin
  ZeroMemory(@LParameters, SizeOf(LParameters));
  LParameters.dwCallback := ANotifyWindow;
  Result := mciSendCommand(ADeviceId, MCI_SEEK, MCI_NOTIFY or MCI_SEEK_TO_START,
    DWORD_PTR(@LParameters));
end;

procedure TWindowsMciSequencer.Stop(ADeviceId: Cardinal);
begin
  mciSendCommand(ADeviceId, MCI_STOP, 0, 0);
end;

procedure TWindowsMciSequencer.Close(ADeviceId: Cardinal);
begin
  mciSendCommand(ADeviceId, MCI_CLOSE, 0, 0);
end;

procedure TWindowsMciSequencer.Pause(ADeviceId: Cardinal);
begin
  mciSendCommand(ADeviceId, MCI_PAUSE, 0, 0);
end;

procedure TWindowsMciSequencer.Resume(ADeviceId: Cardinal);
begin
  mciSendCommand(ADeviceId, MCI_RESUME, 0, 0);
end;

end.
