{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Sndfile library - a fake engine and sound          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Sndfile.FakeSound;

interface

uses
  DelphiDoom.Sndfile.Intf;

type
  /// <summary>
  ///   A sound that says it has Info.Frames frames and really gives
  ///   RealFrames of them, every sample the same value
  /// </summary>
  TFakeSoundFile = class(TInterfacedObject, ISoundFile)
  strict private
    FInfo: TSoundFileInfo;
    FRealFrames: Int64;
    FValue: Double;
    FPosition: Int64;
    function Take(AFrames: Int64): Int64;
  public
    constructor Create(const AInfo: TSoundFileInfo; ARealFrames: Int64; AValue: Double);
    function GetInfo(out AInfo: TSoundFileInfo): Integer; stdcall;
    function ReadShort(ABuffer: Pointer; AFrames: Int64; out AFramesRead: Int64): Integer; stdcall;
    function ReadInt(ABuffer: Pointer; AFrames: Int64; out AFramesRead: Int64): Integer; stdcall;
    function ReadDouble(ABuffer: Pointer; AFrames: Int64; out AFramesRead: Int64): Integer; stdcall;
    function Seek(AFrame: Int64; AWhence: Integer; out APosition: Int64): Integer; stdcall;
    function GetErrorText: PAnsiChar; stdcall;
  end;

  /// <summary>An engine whose every sound is a TFakeSoundFile made from the fields</summary>
  TFakeSndfile = class(TInterfacedObject, ISndfile)
  strict private
    FInfo: TSoundFileInfo;
    FRealFrames: Int64;
    FValue: Double;
  public
    constructor Create(const AInfo: TSoundFileInfo; ARealFrames: Int64; AValue: Double);
    function GetVersion: PAnsiChar; stdcall;
    function OpenMemory(ASource: Pointer; ASourceSize: Cardinal;
      out ASoundFile: ISoundFile): Integer; stdcall;
  end;

implementation

{ TFakeSoundFile }

constructor TFakeSoundFile.Create(const AInfo: TSoundFileInfo; ARealFrames: Int64;
  AValue: Double);
begin
  inherited Create;
  FInfo := AInfo;
  FRealFrames := ARealFrames;
  FValue := AValue;
end;

function TFakeSoundFile.Take(AFrames: Int64): Int64;
begin
  Result := FRealFrames - FPosition;
  if Result > AFrames then
    Result := AFrames;
  if Result < 0 then
    Result := 0;
  Inc(FPosition, Result);
end;

function TFakeSoundFile.GetInfo(out AInfo: TSoundFileInfo): Integer;
begin
  AInfo := FInfo;
  Result := SNDFILE_OK;
end;

function TFakeSoundFile.ReadShort(ABuffer: Pointer; AFrames: Int64;
  out AFramesRead: Int64): Integer;
var
  LIndex: Integer;
begin
  AFramesRead := Take(AFrames);
  for LIndex := 0 to Integer(AFramesRead) * FInfo.Channels - 1 do
    PSmallInt(PByte(ABuffer) + LIndex * SizeOf(SmallInt))^ := SmallInt(Round(FValue * 32767));
  Result := SNDFILE_OK;
end;

function TFakeSoundFile.ReadInt(ABuffer: Pointer; AFrames: Int64;
  out AFramesRead: Int64): Integer;
begin
  AFramesRead := 0;
  Result := SNDFILE_ERR_UNEXPECTED;
end;

function TFakeSoundFile.ReadDouble(ABuffer: Pointer; AFrames: Int64;
  out AFramesRead: Int64): Integer;
var
  LIndex: Integer;
begin
  AFramesRead := Take(AFrames);
  for LIndex := 0 to Integer(AFramesRead) * FInfo.Channels - 1 do
    PDouble(PByte(ABuffer) + LIndex * SizeOf(Double))^ := FValue;
  Result := SNDFILE_OK;
end;

function TFakeSoundFile.Seek(AFrame: Int64; AWhence: Integer;
  out APosition: Int64): Integer;
begin
  FPosition := AFrame;
  APosition := FPosition;
  Result := SNDFILE_OK;
end;

function TFakeSoundFile.GetErrorText: PAnsiChar;
begin
  Result := '';
end;

{ TFakeSndfile }

constructor TFakeSndfile.Create(const AInfo: TSoundFileInfo; ARealFrames: Int64;
  AValue: Double);
begin
  inherited Create;
  FInfo := AInfo;
  FRealFrames := ARealFrames;
  FValue := AValue;
end;

function TFakeSndfile.GetVersion: PAnsiChar;
begin
  Result := 'fake';
end;

function TFakeSndfile.OpenMemory(ASource: Pointer; ASourceSize: Cardinal;
  out ASoundFile: ISoundFile): Integer;
begin
  ASoundFile := TFakeSoundFile.Create(FInfo, FRealFrames, FValue);
  Result := SNDFILE_OK;
end;

end.
