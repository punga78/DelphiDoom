{******************************************************************************}
{                                                                              }
{  DelphiDoom: XMI/CMF - the class the engine uses in place of the library     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xmi.Client;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Xmi.Intf;

const
  // Largest song ConvertToMidi accepts, and largest MIDI file it grows to
  XMI_CLIENT_MAX_SOURCE_SIZE = 64 * 1024 * 1024;
  XMI_CLIENT_MAX_MIDI_SIZE = 256 * 1024 * 1024;

type
  /// <summary>
  ///   Stands for the XMI/CMF library in the rest of the engine: works with
  ///   TBytes and raises EXmiException instead of returning error codes
  /// </summary>
  /// <remarks>
  ///   Depends only on IXmi, so it works the same with the DLL (see
  ///   TXmiLoader) and with an engine linked in the executable, or with a
  ///   fake in the tests. Like IXmi, it must be used from one thread
  /// </remarks>
  TXmiClient = class
  private
    FXmi: IXmi;
  public
    constructor Create(const AXmi: IXmi);

    function DetectFormat(const ASource: TBytes): TXmiFormat; overload;
    function DetectFormat(ASource: Pointer; ASourceSize: Cardinal): TXmiFormat; overload;

    /// <summary>
    ///   True for the formats ConvertToMidi converts (XMI, CMF, SOP): the
    ///   same test as IsXMIMusicFile of the engine
    /// </summary>
    function IsXmiMusic(const ASource: TBytes): Boolean; overload;
    function IsXmiMusic(ASource: Pointer; ASourceSize: Cardinal): Boolean; overload;

    function TrackCount(const ASource: TBytes): Cardinal; overload;
    function TrackCount(ASource: Pointer; ASourceSize: Cardinal): Cardinal; overload;

    /// <summary>
    ///   Converts track ATrack of an XMI, CMF or SOP song into a standard
    ///   MIDI file
    /// </summary>
    function ConvertToMidi(const ASource: TBytes;
      ATrack: Cardinal = 0): TBytes; overload;
    function ConvertToMidi(ASource: Pointer; ASourceSize: Cardinal;
      ATrack: Cardinal = 0): TBytes; overload;

    /// <summary>
    ///   Converts track ATrack and writes the MIDI file; returns False
    ///   instead of raising if the song or the file cannot be converted
    /// </summary>
    function TryConvertToMidiFile(ASource: Pointer; ASourceSize, ATrack: Cardinal;
      const AFileName: string): Boolean;
  end;

implementation

const
  // First guess of the size of the MIDI file; if it is not enough the DLL
  // tells the exact size and the call is repeated once
  MIN_MIDI_CAPACITY = 4096;

{ TXmiClient }

constructor TXmiClient.Create(const AXmi: IXmi);
begin
  inherited Create;
  if not Assigned(AXmi) then
    raise EArgumentNilException.Create('AXmi');
  FXmi := AXmi;
end;

function TXmiClient.DetectFormat(const ASource: TBytes): TXmiFormat;
begin
  Result := DetectFormat(Pointer(ASource), Length(ASource));
end;

function TXmiClient.DetectFormat(ASource: Pointer;
  ASourceSize: Cardinal): TXmiFormat;
var
  LCode: Integer;
begin
  LCode := FXmi.DetectFormat(ASource, ASourceSize);
  if LCode < 0 then
    raise EXmiException.CreateCode(LCode);
  if LCode > Ord(High(TXmiFormat)) then
    Exit(TXmiFormat.Unknown);
  Result := TXmiFormat(LCode);
end;

function TXmiClient.IsXmiMusic(const ASource: TBytes): Boolean;
begin
  Result := IsXmiMusic(Pointer(ASource), Length(ASource));
end;

function TXmiClient.IsXmiMusic(ASource: Pointer; ASourceSize: Cardinal): Boolean;
begin
  Result := DetectFormat(ASource, ASourceSize) in
    [TXmiFormat.Xmi, TXmiFormat.Cmf, TXmiFormat.Sop];
end;

function TXmiClient.TrackCount(const ASource: TBytes): Cardinal;
begin
  Result := TrackCount(Pointer(ASource), Length(ASource));
end;

function TXmiClient.TrackCount(ASource: Pointer; ASourceSize: Cardinal): Cardinal;
var
  LCode: Integer;
begin
  LCode := FXmi.GetTrackCount(ASource, ASourceSize, Result);
  if LCode <> XMI_OK then
    raise EXmiException.CreateCode(LCode);
end;

function TXmiClient.ConvertToMidi(const ASource: TBytes;
  ATrack: Cardinal): TBytes;
begin
  Result := ConvertToMidi(Pointer(ASource), Length(ASource), ATrack);
end;

function TXmiClient.ConvertToMidi(ASource: Pointer; ASourceSize,
  ATrack: Cardinal): TBytes;
var
  LCapacity: Cardinal;
  LSize: Cardinal;
  LCode: Integer;
begin
  if ASourceSize > XMI_CLIENT_MAX_SOURCE_SIZE then
    raise EXmiException.CreateCode(XMI_ERROR_ARGUMENT);

  LCapacity := ASourceSize * 2 + MIN_MIDI_CAPACITY;
  repeat
    SetLength(Result, LCapacity);
    LSize := LCapacity;
    LCode := FXmi.ConvertToMidi(ASource, ASourceSize, ATrack, Pointer(Result),
      LSize);
    if LCode = XMI_OK then
    begin
      SetLength(Result, LSize);
      Exit;
    end;
    // Only a buffer that is too small is worth another attempt, with the
    // exact size the DLL reported
    if (LCode <> XMI_ERROR_BUFFER) or (LSize <= LCapacity) or
       (LSize > XMI_CLIENT_MAX_MIDI_SIZE) then
      raise EXmiException.CreateCode(LCode);
    LCapacity := LSize;
  until False;
end;

function TXmiClient.TryConvertToMidiFile(ASource: Pointer; ASourceSize,
  ATrack: Cardinal; const AFileName: string): Boolean;
var
  LMidi: TBytes;
  LFile: TFileStream;
begin
  try
    LMidi := ConvertToMidi(ASource, ASourceSize, ATrack);
    LFile := TFileStream.Create(AFileName, fmCreate);
    try
      LFile.WriteBuffer(LMidi[0], Length(LMidi));
    finally
      LFile.Free;
    end;
    Result := True;
  except
    on EXmiException do
      Result := False;
    on EStreamError do
      Result := False;
  end;
end;

end.
