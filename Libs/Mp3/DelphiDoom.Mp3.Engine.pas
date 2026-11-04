{******************************************************************************}
{                                                                              }
{  DelphiDoom: mp3 - implementation of IMp3 on top of the decoder               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Mp3.Engine;

interface

uses
  DelphiDoom.Mp3.Intf;

type
  /// <summary>
  ///   Factory of decoders. It keeps no state, so one instance can create
  ///   decoders for several threads (each decoder is used by one thread at a
  ///   time, see IMp3Decoder)
  /// </summary>
  TMp3Engine = class(TInterfacedObject, IMp3)
  public
    function GetVersion: PAnsiChar; stdcall;
    function CreateDecoder(AChannels, AVolume: Integer;
      out ADecoder: IMp3Decoder): Integer; stdcall;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Mp3.Decoder;

{ TMp3Engine }

function TMp3Engine.GetVersion: PAnsiChar;
begin
  Result := DDMP3_VERSION_TEXT;
end;

function TMp3Engine.CreateDecoder(AChannels, AVolume: Integer;
  out ADecoder: IMp3Decoder): Integer;
begin
  ADecoder := nil;
  try
    ADecoder := TMp3Decoder.Create(AChannels, AVolume);
    Result := MP3_OK;
  except
    on E: Exception do
    begin
      ADecoder := nil;
      Result := EMp3Exception.CodeOf(E);
    end;
  end;
end;

end.
