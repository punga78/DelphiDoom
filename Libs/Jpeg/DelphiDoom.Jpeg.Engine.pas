{******************************************************************************}
{                                                                              }
{  DelphiDoom: JPEG - implementation of IJpeg on top of JPEGLIB                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Jpeg.Engine;

interface

uses
  DelphiDoom.Jpeg.Intf;

type
  /// <summary>
  ///   Stateless implementation of IJpeg: every call uses its own decoder or
  ///   encoder, so one instance can be used by several threads. No exception
  ///   leaves a method: it is turned into a result code
  /// </summary>
  TJpegEngine = class(TInterfacedObject, IJpeg)
  private
    class function ResultOfException(AException: TObject): Integer; static;
  public
    function GetVersion: PAnsiChar; stdcall;
    function GetInfo(ASource: Pointer; ASourceSize: Cardinal;
      out AInfo: TJpegInfo): Integer; stdcall;
    function Decode(ASource: Pointer; ASourceSize: Cardinal; ADest: Pointer;
      ADestSize: Cardinal; out AInfo: TJpegInfo): Integer; stdcall;
    function EncodeBound(AWidth, AHeight, AComponents: Integer): Cardinal; stdcall;
    function Encode(APixels: Pointer; AWidth, AHeight, AComponents,
      AQuality: Integer; ADest: Pointer; var ADestSize: Cardinal): Integer; stdcall;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Jpeg.Native, DelphiDoom.Jpeg.Encoder;

{ TJpegEngine }

class function TJpegEngine.ResultOfException(AException: TObject): Integer;
begin
  if AException is EOutOfMemory then
    Result := DDJPEG_ERR_MEMORY
  else
    Result := DDJPEG_ERR_INTERNAL;
end;

function TJpegEngine.GetVersion: PAnsiChar;
begin
  Result := JPEG_NATIVE_VERSION_TEXT;
end;

function TJpegEngine.GetInfo(ASource: Pointer; ASourceSize: Cardinal;
  out AInfo: TJpegInfo): Integer;
begin
  try
    Result := JpegReadInfo(ASource, ASourceSize, AInfo);
  except
    on E: Exception do
    begin
      FillChar(AInfo, SizeOf(AInfo), 0);
      Result := ResultOfException(E);
    end;
  end;
end;

function TJpegEngine.Decode(ASource: Pointer; ASourceSize: Cardinal;
  ADest: Pointer; ADestSize: Cardinal; out AInfo: TJpegInfo): Integer;
begin
  try
    Result := JpegDecode(ASource, ASourceSize, ADest, ADestSize, AInfo);
  except
    on E: Exception do
    begin
      FillChar(AInfo, SizeOf(AInfo), 0);
      Result := ResultOfException(E);
    end;
  end;
end;

function TJpegEngine.EncodeBound(AWidth, AHeight, AComponents: Integer): Cardinal;
begin
  Result := TJpegEncoder.Bound(AWidth, AHeight, AComponents);
end;

function TJpegEngine.Encode(APixels: Pointer; AWidth, AHeight, AComponents,
  AQuality: Integer; ADest: Pointer; var ADestSize: Cardinal): Integer;
var
  LEncoder: TJpegEncoder;
begin
  if (APixels = nil) or (ADest = nil) or
     not TJpegEncoder.IsValidFormat(AWidth, AHeight, AComponents) then
    Exit(DDJPEG_ERR_INVALID_ARGUMENT);

  try
    LEncoder := TJpegEncoder.Create(APixels, AWidth, AHeight, AComponents, AQuality);
    try
      Result := LEncoder.Encode(ADest, ADestSize);
    finally
      LEncoder.Free;
    end;
  except
    on E: Exception do
      Result := ResultOfException(E);
  end;
end;

end.
