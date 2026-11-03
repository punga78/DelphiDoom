{******************************************************************************}
{                                                                              }
{  DelphiDoom: XMI/CMF - adapter to XMILIB\xmi_core.pas                        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xmi.Native;

// xmi_core.pas is a VCL form (TXMICore) with global state: the adapter owns
// the only instance, serializes every use of it and hides it from the rest
// of the library. The units xmi_core, xmi_iff and xmi_consts come from the
// folder XMILIB; "uses d_delphi" of xmi_core is satisfied by Shim\d_delphi.pas.
// This unit has no dependency on the rest of the engine so that it can live
// inside a DLL.

interface

uses
  System.SysUtils;

{$SCOPEDENUMS ON}

type
  TXmiNativeFormat = (Unknown, Xmi, Cmf, Sop, Midi);

  TXmiNativeStatus = (Ok, UnknownFormat, BadData, TrackOutOfRange, OutOfMemory);

/// <summary>
///   Declares that the caller uses the converter: the hidden form is created
///   on demand and destroyed when the last user calls XmiNativeRelease
/// </summary>
procedure XmiNativeAcquire;

procedure XmiNativeRelease;

/// <summary>
///   Looks at the content of ASource. May raise an exception
/// </summary>
function XmiNativeDetectFormat(ASource: Pointer;
  ASourceSize: Integer): TXmiNativeFormat;

/// <summary>
///   Counts the tracks of an XMI, CMF or SOP buffer
/// </summary>
function XmiNativeCountTracks(ASource: Pointer; ASourceSize: Integer;
  out ATrackCount: Integer): TXmiNativeStatus;

/// <summary>
///   Converts track ATrack of an XMI, CMF or SOP buffer into a standard MIDI
///   file
/// </summary>
function XmiNativeConvertToMidi(ASource: Pointer; ASourceSize: Integer;
  ATrack: Integer; out AMidi: TBytes): TXmiNativeStatus;

implementation

uses
  System.Classes, System.SyncObjs, xmi_core;

const
  // Names of the containers as xmi_core.LoadMemory wants them
  CONTAINER_NAMES: array[TXmiNativeFormat] of string = (
    '', 'xmi', 'cmf', 'sop', 'smf');

  // Header of a standard MIDI file: 'MThd', length 6, ...
  MIDI_HEADER_SIZE = 14;
  MIDI_HEADER_TAG: array[0..3] of Byte = ($4D, $54, $68, $64);

  // Only the extension of this name matters to xmi_core: it selects the
  // output container (.mid = standard MIDI file)
  MIDI_TARGET_NAME = 'song.mid';

var
  GLock: TCriticalSection;
  GUsers: Integer;

function HasMidiHeader(ASource: Pointer; ASourceSize: Integer): Boolean;
var
  LBytes: PByte;
  LIndex: Integer;
begin
  Result := ASourceSize >= MIDI_HEADER_SIZE;
  if not Result then
    Exit;

  LBytes := PByte(ASource);
  for LIndex := 0 to High(MIDI_HEADER_TAG) do
  begin
    if LBytes^ <> MIDI_HEADER_TAG[LIndex] then
      Exit(False);
    Inc(LBytes);
  end;
end;

// The caller holds GLock
procedure EnsureCore;
begin
  if not Assigned(XMICore) then
    XMICore := TXMICore.Create(nil);
end;

// The caller holds GLock (or the process is shutting down)
procedure ReleaseCore;
begin
  if Assigned(XMICore) then
    FreeAndNil(XMICore);
  SetLength(TrackData, 0);
end;

// Clears what a previous song left in the globals of xmi_core: LoadMemory
// returns the old value of Opened when it does not recognize the data
// The caller holds GLock
procedure ResetCoreState;
begin
  Opened := False;
  Container := '';
  EventFormat := '';
  EventProfile := '';
  EventViewProfile := '';
  SetLength(TrackData, 0);
  // The log is a memo: without this it grows with every conversion
  XMICore.Log.Lines.Clear;
end;

// The caller holds GLock
function DetectFormatLocked(ASource: Pointer;
  ASourceSize: Integer): TXmiNativeFormat;
begin
  Result := TXmiNativeFormat.Unknown;
  if not Assigned(ASource) or (ASourceSize <= 0) then
    Exit;

  if HasMidiHeader(ASource, ASourceSize) then
    Exit(TXmiNativeFormat.Midi);

  EnsureCore;
  if XMICore.DetectXMIMemory(ASource, ASourceSize) then
    Result := TXmiNativeFormat.Xmi
  else if XMICore.DetectCMFMemory(ASource, ASourceSize) then
    Result := TXmiNativeFormat.Cmf
  else if XMICore.DetectSOPMemory(ASource, ASourceSize) then
    Result := TXmiNativeFormat.Sop;
end;

// Detects the format and loads the song into the globals of xmi_core
// The caller holds GLock
function LoadSource(ASource: Pointer; ASourceSize: Integer;
  out ATrackCount: Integer): TXmiNativeStatus;
var
  LFormat: TXmiNativeFormat;
begin
  ATrackCount := 0;
  LFormat := DetectFormatLocked(ASource, ASourceSize);
  if not (LFormat in [TXmiNativeFormat.Xmi, TXmiNativeFormat.Cmf,
    TXmiNativeFormat.Sop]) then
    Exit(TXmiNativeStatus.UnknownFormat);

  ResetCoreState;
  if not XMICore.LoadMemory(ASource, ASourceSize, CONTAINER_NAMES[LFormat]) then
    Exit(TXmiNativeStatus.BadData);

  ATrackCount := Length(TrackData);
  Result := TXmiNativeStatus.Ok;
end;

// Keeps only track ATrack, as xmi_lib.XMI_ConvertMemoryToFile does, without
// the grid of events the form would fill for the user interface
// The caller holds GLock
procedure KeepOnlyTrack(ATrack: Integer);
var
  LIndex: Integer;
begin
  for LIndex := Length(TrackData) - 1 downto 0 do
    if LIndex <> ATrack then
      XMICore.DelTrack(LIndex);

  // WriteMIDI of a type 0 song writes the track selected in the combo box
  XMICore.RefTrackList;
  XMICore.TrkCh.ItemIndex := 0;
end;

// The caller holds GLock
function ConvertLoadedSong(ATrack: Integer; out AMidi: TBytes): TXmiNativeStatus;
var
  LStream: TMemoryStream;
begin
  KeepOnlyTrack(ATrack);

  LStream := TMemoryStream.Create;
  try
    if not XMICore.SaveFileToStream(MIDI_TARGET_NAME, LStream) then
      Exit(TXmiNativeStatus.BadData);
    // A song without MIDI type produces only a truncated header
    if not HasMidiHeader(LStream.Memory, Integer(LStream.Size)) then
      Exit(TXmiNativeStatus.BadData);

    SetLength(AMidi, LStream.Size);
    Move(LStream.Memory^, Pointer(AMidi)^, LStream.Size);
    Result := TXmiNativeStatus.Ok;
  finally
    LStream.Free;
  end;
end;

procedure XmiNativeAcquire;
begin
  GLock.Enter;
  try
    Inc(GUsers);
  finally
    GLock.Leave;
  end;
end;

procedure XmiNativeRelease;
begin
  GLock.Enter;
  try
    if GUsers > 0 then
      Dec(GUsers);
    if GUsers = 0 then
      ReleaseCore;
  finally
    GLock.Leave;
  end;
end;

function XmiNativeDetectFormat(ASource: Pointer;
  ASourceSize: Integer): TXmiNativeFormat;
begin
  GLock.Enter;
  try
    Result := DetectFormatLocked(ASource, ASourceSize);
  finally
    GLock.Leave;
  end;
end;

function XmiNativeCountTracks(ASource: Pointer; ASourceSize: Integer;
  out ATrackCount: Integer): TXmiNativeStatus;
begin
  ATrackCount := 0;
  GLock.Enter;
  try
    try
      Result := LoadSource(ASource, ASourceSize, ATrackCount);
    except
      on EOutOfMemory do
        Result := TXmiNativeStatus.OutOfMemory;
      // The parsers of xmi_core raise on truncated or inconsistent data
      on Exception do
        Result := TXmiNativeStatus.BadData;
    end;
  finally
    GLock.Leave;
  end;
end;

function XmiNativeConvertToMidi(ASource: Pointer; ASourceSize: Integer;
  ATrack: Integer; out AMidi: TBytes): TXmiNativeStatus;
var
  LTrackCount: Integer;
begin
  AMidi := nil;
  GLock.Enter;
  try
    try
      Result := LoadSource(ASource, ASourceSize, LTrackCount);
      if Result <> TXmiNativeStatus.Ok then
        Exit;
      if (ATrack < 0) or (ATrack >= LTrackCount) then
        Exit(TXmiNativeStatus.TrackOutOfRange);

      Result := ConvertLoadedSong(ATrack, AMidi);
    except
      on EOutOfMemory do
        Result := TXmiNativeStatus.OutOfMemory;
      // The converters of xmi_core raise on inconsistent events
      on Exception do
        Result := TXmiNativeStatus.BadData;
    end;
  finally
    GLock.Leave;
  end;
end;

initialization
  GLock := TCriticalSection.Create;

finalization
  // The form is normally gone already (last XmiNativeRelease); this covers
  // callers that used the functions without Acquire
  ReleaseCore;
  FreeAndNil(GLock);

end.
