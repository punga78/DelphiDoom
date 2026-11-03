{******************************************************************************}
{                                                                              }
{  DelphiDoom: PNG - implementation of IPng on top of the decoder and encoder  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Png.Engine;

interface

uses
  DelphiDoom.Zlib.Intf, DelphiDoom.Png.Intf;

type
  /// <summary>
  ///   Stateless implementation of IPng: every call uses its own decoder or
  ///   encoder, so one instance can be used by several threads (if the IZlib
  ///   can). No exception leaves a method: it is turned into a result code
  /// </summary>
  /// <remarks>
  ///   The compression is done by the IZlib given to the constructor; this
  ///   class (and the DLL it lives in) contains no zlib code
  /// </remarks>
  TPngEngine = class(TInterfacedObject, IPng)
  private
    FZlib: IZlib;
    class function ResultOfException(AException: TObject): Integer; static;
  public
    constructor Create(const AZlib: IZlib);

    function GetVersion: PAnsiChar; stdcall;
    function GetInfo(ASource: Pointer; ASourceSize: Cardinal;
      out AInfo: TPngInfo): Integer; stdcall;
    function Decode(ASource: Pointer; ASourceSize: Cardinal; ADest: Pointer;
      ADestSize: Cardinal; out AInfo: TPngInfo): Integer; stdcall;
    function DecodeIndexed(ASource: Pointer; ASourceSize: Cardinal;
      APixels: Pointer; APixelsSize: Cardinal; APalette: Pointer;
      out AInfo: TPngInfo): Integer; stdcall;
    function EncodeBound(AWidth, AHeight, AFormat: Integer): Cardinal; stdcall;
    function Encode(APixels: Pointer; AWidth, AHeight, AFormat, AStride,
      ALevel: Integer; ADest: Pointer; var ADestSize: Cardinal): Integer; stdcall;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Png.Decoder, DelphiDoom.Png.Encoder;

const
  PNG_ENGINE_VERSION: PAnsiChar = 'DDPng 1.0';

{ TPngEngine }

constructor TPngEngine.Create(const AZlib: IZlib);
begin
  inherited Create;
  if not Assigned(AZlib) then
    raise EArgumentNilException.Create('AZlib');
  FZlib := AZlib;
end;

class function TPngEngine.ResultOfException(AException: TObject): Integer;
begin
  if AException is EPngException then
    Result := EPngException(AException).Code
  else if AException is EOutOfMemory then
    Result := DDPNG_ERR_MEMORY
  else
    Result := DDPNG_ERR_INTERNAL;
end;

function TPngEngine.GetVersion: PAnsiChar;
begin
  Result := PNG_ENGINE_VERSION;
end;

function TPngEngine.GetInfo(ASource: Pointer; ASourceSize: Cardinal;
  out AInfo: TPngInfo): Integer;
var
  LDecoder: TPngDecoder;
begin
  FillChar(AInfo, SizeOf(AInfo), 0);
  if (ASource = nil) or (ASourceSize = 0) then
    Exit(DDPNG_ERR_INVALID_ARGUMENT);

  try
    LDecoder := TPngDecoder.Create(FZlib);
    try
      AInfo := LDecoder.ReadInfo(ASource, ASourceSize);
      Result := DDPNG_OK;
    finally
      LDecoder.Free;
    end;
  except
    on E: Exception do
    begin
      FillChar(AInfo, SizeOf(AInfo), 0);
      Result := ResultOfException(E);
    end;
  end;
end;

function TPngEngine.Decode(ASource: Pointer; ASourceSize: Cardinal;
  ADest: Pointer; ADestSize: Cardinal; out AInfo: TPngInfo): Integer;
var
  LDecoder: TPngDecoder;
begin
  FillChar(AInfo, SizeOf(AInfo), 0);
  if (ASource = nil) or (ASourceSize = 0) or (ADest = nil) then
    Exit(DDPNG_ERR_INVALID_ARGUMENT);

  try
    LDecoder := TPngDecoder.Create(FZlib);
    try
      // The information first: it stays valid if the decoding fails, so the
      // caller can size the buffer after a DDPNG_ERR_BUFFER_TOO_SMALL
      AInfo := LDecoder.ReadInfo(ASource, ASourceSize);
      LDecoder.DecodeBgra(ASource, ASourceSize, ADest, ADestSize);
      Result := DDPNG_OK;
    finally
      LDecoder.Free;
    end;
  except
    on E: Exception do
      Result := ResultOfException(E);
  end;
end;

function TPngEngine.DecodeIndexed(ASource: Pointer; ASourceSize: Cardinal;
  APixels: Pointer; APixelsSize: Cardinal; APalette: Pointer;
  out AInfo: TPngInfo): Integer;
var
  LDecoder: TPngDecoder;
begin
  FillChar(AInfo, SizeOf(AInfo), 0);
  if (ASource = nil) or (ASourceSize = 0) or (APixels = nil) or
     (APalette = nil) then
    Exit(DDPNG_ERR_INVALID_ARGUMENT);

  try
    LDecoder := TPngDecoder.Create(FZlib);
    try
      AInfo := LDecoder.ReadInfo(ASource, ASourceSize);
      LDecoder.DecodeIndexed(ASource, ASourceSize, APixels, APixelsSize,
        APalette);
      Result := DDPNG_OK;
    finally
      LDecoder.Free;
    end;
  except
    on E: Exception do
      Result := ResultOfException(E);
  end;
end;

function TPngEngine.EncodeBound(AWidth, AHeight, AFormat: Integer): Cardinal;
var
  LEncoder: TPngEncoder;
begin
  try
    LEncoder := TPngEncoder.Create(FZlib);
    try
      Result := LEncoder.Bound(AWidth, AHeight, AFormat);
    finally
      LEncoder.Free;
    end;
  except
    // No error code in the result: 0 means "cannot encode"
    Result := 0;
  end;
end;

function TPngEngine.Encode(APixels: Pointer; AWidth, AHeight, AFormat, AStride,
  ALevel: Integer; ADest: Pointer; var ADestSize: Cardinal): Integer;
var
  LEncoder: TPngEncoder;
begin
  try
    LEncoder := TPngEncoder.Create(FZlib);
    try
      LEncoder.Encode(APixels, AWidth, AHeight, AFormat, AStride, ALevel,
        ADest, ADestSize);
      Result := DDPNG_OK;
    finally
      LEncoder.Free;
    end;
  except
    on E: Exception do
      Result := ResultOfException(E);
  end;
end;

end.
