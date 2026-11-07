{******************************************************************************}
{                                                                              }
{  DelphiDoom: XMI/CMF - implementation of IXmi                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xmi.Engine;

interface

uses
  System.SysUtils, System.SyncObjs, DelphiDoom.Xmi.Intf;

type
  /// <summary>
  ///   Implementation of IXmi. Never lets an exception cross the interface:
  ///   every failure becomes an error code
  /// </summary>
  /// <remarks>
  ///   The converted MIDI is kept between the call that reports the size
  ///   needed (XMI_ERROR_BUFFER) and the call that receives it, so that the
  ///   two-phase protocol converts the song only once
  /// </remarks>
  TXmiEngine = class(TInterfacedObject, IXmi)
  private
    FLock: TCriticalSection;
    FPendingSource: TBytes;
    FPendingTrack: Cardinal;
    FPendingMidi: TBytes;
    class function IsUsableBuffer(ASource: Pointer;
      ASourceSize: Cardinal): Boolean; static;
    function IsPending(ASource: Pointer; ASourceSize, ATrack: Cardinal): Boolean;
    procedure KeepPending(ASource: Pointer; ASourceSize, ATrack: Cardinal;
      const AMidi: TBytes);
    procedure ClearPending;
    function ConvertLocked(ASource: Pointer; ASourceSize, ATrack: Cardinal;
      ADest: Pointer; var ADestSize: Cardinal): Integer;
  public
    constructor Create;
    destructor Destroy; override;

    function DetectFormat(ASource: Pointer; ASourceSize: Cardinal): Integer; stdcall;
    function GetTrackCount(ASource: Pointer; ASourceSize: Cardinal;
      out ATrackCount: Cardinal): Integer; stdcall;
    function ConvertToMidi(ASource: Pointer; ASourceSize: Cardinal;
      ATrack: Cardinal; ADest: Pointer; var ADestSize: Cardinal): Integer; stdcall;
  end;

implementation

uses
  DelphiDoom.Xmi.Midi.Types, DelphiDoom.Xmi.Converter;

const
  MAX_BUFFER_SIZE = Cardinal(High(Integer));

  // The code of the DLL for each answer of the converter
  STATUS_CODES: array[TXmiConversionStatus] of Integer = (XMI_OK, XMI_ERROR_FORMAT,
    XMI_ERROR_DATA, XMI_ERROR_TRACK, XMI_ERROR_MEMORY);

{ TXmiEngine }

constructor TXmiEngine.Create;
begin
  inherited Create;
  FLock := TCriticalSection.Create;
end;

destructor TXmiEngine.Destroy;
begin
  FreeAndNil(FLock);
  inherited;
end;

class function TXmiEngine.IsUsableBuffer(ASource: Pointer;
  ASourceSize: Cardinal): Boolean;
begin
  Result := Assigned(ASource) and (ASourceSize > 0) and
    (ASourceSize <= MAX_BUFFER_SIZE);
end;

function TXmiEngine.IsPending(ASource: Pointer; ASourceSize,
  ATrack: Cardinal): Boolean;
begin
  Result := (Length(FPendingMidi) > 0) and (FPendingTrack = ATrack) and
    (Cardinal(Length(FPendingSource)) = ASourceSize) and
    CompareMem(Pointer(FPendingSource), ASource, ASourceSize);
end;

procedure TXmiEngine.KeepPending(ASource: Pointer; ASourceSize,
  ATrack: Cardinal; const AMidi: TBytes);
begin
  SetLength(FPendingSource, ASourceSize);
  Move(ASource^, Pointer(FPendingSource)^, ASourceSize);
  FPendingTrack := ATrack;
  FPendingMidi := AMidi;
end;

procedure TXmiEngine.ClearPending;
begin
  FPendingSource := nil;
  FPendingMidi := nil;
end;

function TXmiEngine.DetectFormat(ASource: Pointer;
  ASourceSize: Cardinal): Integer;
begin
  if not IsUsableBuffer(ASource, ASourceSize) then
    Exit(Ord(TXmiFormat.Unknown));

  try
    Result := Ord(TXmiConverter.DetectFormat(ASource, Integer(ASourceSize)));
  except
    Result := XMI_ERROR_INTERNAL;
  end;
end;

function TXmiEngine.GetTrackCount(ASource: Pointer; ASourceSize: Cardinal;
  out ATrackCount: Cardinal): Integer;
var
  LCount: Integer;
begin
  ATrackCount := 0;
  if not IsUsableBuffer(ASource, ASourceSize) then
    Exit(XMI_ERROR_ARGUMENT);

  try
    Result := STATUS_CODES[TXmiConverter.CountTracks(ASource, Integer(ASourceSize), LCount)];
    if Result = XMI_OK then
      ATrackCount := Cardinal(LCount);
  except
    Result := XMI_ERROR_INTERNAL;
  end;
end;

function TXmiEngine.ConvertLocked(ASource: Pointer; ASourceSize,
  ATrack: Cardinal; ADest: Pointer; var ADestSize: Cardinal): Integer;
var
  LMidi: TBytes;
  LStatus: TXmiConversionStatus;
begin
  if not IsPending(ASource, ASourceSize, ATrack) then
  begin
    ClearPending;
    LStatus := TXmiConverter.ConvertToMidi(ASource, Integer(ASourceSize),
      Integer(ATrack), LMidi);
    if LStatus <> TXmiConversionStatus.Ok then
      Exit(STATUS_CODES[LStatus]);
    KeepPending(ASource, ASourceSize, ATrack, LMidi);
  end;

  if not Assigned(ADest) or (ADestSize < Cardinal(Length(FPendingMidi))) then
  begin
    ADestSize := Length(FPendingMidi);
    Exit(XMI_ERROR_BUFFER);
  end;

  Move(Pointer(FPendingMidi)^, ADest^, Length(FPendingMidi));
  ADestSize := Length(FPendingMidi);
  ClearPending;
  Result := XMI_OK;
end;

function TXmiEngine.ConvertToMidi(ASource: Pointer; ASourceSize,
  ATrack: Cardinal; ADest: Pointer; var ADestSize: Cardinal): Integer;
begin
  if not IsUsableBuffer(ASource, ASourceSize) then
    Exit(XMI_ERROR_ARGUMENT);
  if ATrack > MAX_BUFFER_SIZE then
    Exit(XMI_ERROR_TRACK);

  FLock.Enter;
  try
    try
      Result := ConvertLocked(ASource, ASourceSize, ATrack, ADest, ADestSize);
    except
      on EOutOfMemory do
        Result := XMI_ERROR_MEMORY;
      on Exception do
        Result := XMI_ERROR_INTERNAL;
    end;
  finally
    FLock.Leave;
  end;
end;

end.
