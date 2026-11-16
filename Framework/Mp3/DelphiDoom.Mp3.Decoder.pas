{******************************************************************************}
{                                                                              }
{  DelphiDoom: mp3 - implementation of IMp3Decoder                             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Mp3.Decoder;

interface

uses
  DelphiDoom.Mp3.Intf, DelphiDoom.Mp3.Native;

type
  /// <summary>
  ///   One decoding session. Every method catches the exceptions of the MPEG
  ///   code and returns them as result codes, because exceptions must not
  ///   cross the DLL boundary
  /// </summary>
  TMp3Decoder = class(TInterfacedObject, IMp3Decoder)
  private
    FNative: TMp3Native;
    FStagedSize: Integer;
    FStagedOffset: Integer;
    procedure DrainStaged(var ADestination: System.PByte; var ARoom: Cardinal;
      var AWritten: Cardinal);
  public
    constructor Create(AChannels, AVolume: Integer);
    destructor Destroy; override;

    function Feed(AData: Pointer; ASize: Cardinal): Integer; stdcall;
    function Decode(APcm: Pointer; APcmSize: Cardinal;
      out AWritten: Cardinal): Integer; stdcall;
    function GetFrequency: Cardinal; stdcall;
    function GetChannels: Cardinal; stdcall;
    function GetPendingSize: Cardinal; stdcall;
    function Reset: Integer; stdcall;
  end;

implementation

uses
  System.SysUtils;

{ TMp3Decoder }

constructor TMp3Decoder.Create(AChannels, AVolume: Integer);
begin
  inherited Create;
  FNative := TMp3Native.Create(AChannels, AVolume);
end;

destructor TMp3Decoder.Destroy;
begin
  FreeAndNil(FNative);
  inherited;
end;

procedure TMp3Decoder.DrainStaged(var ADestination: System.PByte; var ARoom: Cardinal;
  var AWritten: Cardinal);
var
  LCount: Integer;
begin
  LCount := FStagedSize - FStagedOffset;
  if LCount > 0 then
  begin
    if Cardinal(LCount) > ARoom then
      LCount := Integer(ARoom);
    Move((System.PByte(FNative.PcmData) + FStagedOffset)^, ADestination^, LCount);
    Inc(FStagedOffset, LCount);
    Inc(ADestination, LCount);
    Dec(ARoom, Cardinal(LCount));
    Inc(AWritten, Cardinal(LCount));
  end;
end;

function TMp3Decoder.Feed(AData: Pointer; ASize: Cardinal): Integer;
begin
  if ASize = 0 then
    Exit(MP3_OK);
  if not Assigned(AData) then
    Exit(MP3_ERROR_INVALID_ARGUMENT);

  try
    FNative.Feed(AData, ASize);
    Result := MP3_OK;
  except
    on E: Exception do
      Result := EMp3Exception.CodeOf(E);
  end;
end;

function TMp3Decoder.Decode(APcm: Pointer; APcmSize: Cardinal;
  out AWritten: Cardinal): Integer;
var
  LDestination: System.PByte;
  LRoom: Cardinal;
  LDone: Boolean;
begin
  AWritten := 0;
  if not Assigned(APcm) or (APcmSize < SizeOf(SmallInt)) then
    Exit(MP3_ERROR_INVALID_ARGUMENT);

  try
    LDestination := APcm;
    // Only whole 16 bit samples are written
    LRoom := APcmSize - (APcmSize mod SizeOf(SmallInt));
    Result := MP3_OK;
    LDone := False;

    while not LDone do
    begin
      DrainStaged(LDestination, LRoom, AWritten);

      if FStagedOffset < FStagedSize then
        // The output is full and part of the last frame is still staged
        LDone := True
      else if LRoom = 0 then
        LDone := True
      else
        case FNative.DecodeFrame of
          TMp3NativeStatus.FrameDecoded:
            begin
              FStagedSize := FNative.PcmByteCount;
              FStagedOffset := 0;
            end;
          TMp3NativeStatus.NoOutput:
            ; // Frame consumed without PCM: go on with the next one
          TMp3NativeStatus.NeedData:
            begin
              Result := MP3_NEED_DATA;
              LDone := True;
            end;
        end;
    end;
  except
    on E: Exception do
      Result := EMp3Exception.CodeOf(E);
  end;
end;

function TMp3Decoder.GetFrequency: Cardinal;
begin
  Result := FNative.Frequency;
end;

function TMp3Decoder.GetChannels: Cardinal;
begin
  Result := Cardinal(FNative.Channels);
end;

function TMp3Decoder.GetPendingSize: Cardinal;
begin
  Result := Cardinal(FNative.PendingBytes);
end;

function TMp3Decoder.Reset: Integer;
begin
  try
    FNative.Reset;
    FStagedSize := 0;
    FStagedOffset := 0;
    Result := MP3_OK;
  except
    on E: Exception do
      Result := EMp3Exception.CodeOf(E);
  end;
end;

end.
