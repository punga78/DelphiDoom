{******************************************************************************}
{                                                                              }
{  DelphiDoom: JPEG - the class the engine uses in place of the library        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Jpeg.Client;

interface

uses
  System.SysUtils, DelphiDoom.Jpeg.Intf;

type
  /// <summary>
  ///   A decoded image: Pixels holds Height rows of Width * Components bytes
  ///   (see TJpegInfo for the order of the color components)
  /// </summary>
  TJpegImage = record
    Width: Integer;
    Height: Integer;
    Components: Integer;
    Pixels: TBytes;
  end;

  /// <summary>
  ///   Stands for the JPEG library in the rest of the engine: works with
  ///   TBytes and raises EJpegException instead of returning error codes
  /// </summary>
  /// <remarks>
  ///   Depends only on IJpeg, so it works the same with the DLL (see
  ///   TJpegLoader) and with an engine linked in the executable, or with a
  ///   fake in the tests
  /// </remarks>
  TJpegClient = class
  private
    FJpeg: IJpeg;
    class procedure Check(ACode: Integer); static;
  public
    constructor Create(const AJpeg: IJpeg);

    function Version: string;

    /// <summary>
    ///   Size and format of a JPEG stream, without decoding it
    /// </summary>
    function GetInfo(const ASource: TBytes): TJpegInfo; overload;
    function GetInfo(ASource: Pointer; ASourceSize: Cardinal): TJpegInfo; overload;

    function Decode(const ASource: TBytes): TJpegImage; overload;
    function Decode(ASource: Pointer; ASourceSize: Cardinal): TJpegImage; overload;

    /// <summary>
    ///   Encodes AWidth * AHeight pixels of AComponents bytes each (1 or 3, in
    ///   B, G, R order) into a baseline JPEG stream
    /// </summary>
    function Encode(const APixels: TBytes; AWidth, AHeight, AComponents: Integer;
      AQuality: Integer = DDJPEG_DEFAULT_QUALITY): TBytes; overload;
    function Encode(APixels: Pointer; AWidth, AHeight, AComponents: Integer;
      AQuality: Integer = DDJPEG_DEFAULT_QUALITY): TBytes; overload;
  end;

implementation

{ TJpegClient }

constructor TJpegClient.Create(const AJpeg: IJpeg);
begin
  inherited Create;
  if not Assigned(AJpeg) then
    raise EArgumentNilException.Create('AJpeg');
  FJpeg := AJpeg;
end;

class procedure TJpegClient.Check(ACode: Integer);
begin
  if ACode <> DDJPEG_OK then
    raise EJpegException.CreateCode(ACode);
end;

function TJpegClient.Version: string;
begin
  Result := string(AnsiString(FJpeg.GetVersion));
end;

function TJpegClient.GetInfo(const ASource: TBytes): TJpegInfo;
begin
  Result := GetInfo(Pointer(ASource), Length(ASource));
end;

function TJpegClient.GetInfo(ASource: Pointer; ASourceSize: Cardinal): TJpegInfo;
begin
  Check(FJpeg.GetInfo(ASource, ASourceSize, Result));
end;

function TJpegClient.Decode(const ASource: TBytes): TJpegImage;
begin
  Result := Decode(Pointer(ASource), Length(ASource));
end;

function TJpegClient.Decode(ASource: Pointer; ASourceSize: Cardinal): TJpegImage;
var
  LInfo: TJpegInfo;
  LSize: Int64;
begin
  LInfo := GetInfo(ASource, ASourceSize);

  LSize := Int64(LInfo.Width) * LInfo.Height * LInfo.Components;
  if LSize > High(Integer) then
    raise EJpegException.CreateCode(DDJPEG_ERR_MEMORY);

  Result.Pixels := nil;
  SetLength(Result.Pixels, Integer(LSize));
  Check(FJpeg.Decode(ASource, ASourceSize, Pointer(Result.Pixels),
    Cardinal(LSize), LInfo));

  Result.Width := LInfo.Width;
  Result.Height := LInfo.Height;
  Result.Components := LInfo.Components;
end;

function TJpegClient.Encode(const APixels: TBytes; AWidth, AHeight,
  AComponents, AQuality: Integer): TBytes;
begin
  if Int64(Length(APixels)) < Int64(AWidth) * AHeight * AComponents then
    raise EJpegException.CreateCode(DDJPEG_ERR_INVALID_ARGUMENT);

  Result := Encode(Pointer(APixels), AWidth, AHeight, AComponents, AQuality);
end;

function TJpegClient.Encode(APixels: Pointer; AWidth, AHeight, AComponents,
  AQuality: Integer): TBytes;
var
  LBound: Cardinal;
  LCapacity: Int64;
  LSize: Cardinal;
  LCode: Integer;
begin
  LBound := FJpeg.EncodeBound(AWidth, AHeight, AComponents);
  if LBound = 0 then
    raise EJpegException.CreateCode(DDJPEG_ERR_INVALID_ARGUMENT);
  if LBound > Cardinal(High(Integer)) then
    LBound := Cardinal(High(Integer));

  // Start from a size that is enough for most images (the bound is a worst
  // case that can be many times larger) and grow it if the encoder fills it
  LCapacity := Int64(AWidth) * AHeight * AComponents div 2 + 4096;
  if LCapacity > LBound then
    LCapacity := LBound;

  repeat
    Result := nil;
    SetLength(Result, Integer(LCapacity));
    LSize := Cardinal(LCapacity);
    LCode := FJpeg.Encode(APixels, AWidth, AHeight, AComponents, AQuality,
      Pointer(Result), LSize);
    if LCode = DDJPEG_OK then
    begin
      SetLength(Result, Integer(LSize));
      Exit;
    end;

    // Only a full buffer is worth another attempt with a larger one
    if (LCode <> DDJPEG_ERR_BUFFER_TOO_SMALL) or (LCapacity >= LBound) then
      raise EJpegException.CreateCode(LCode);

    LCapacity := LCapacity * 2;
    if LCapacity > LBound then
      LCapacity := LBound;
  until False;
end;

end.
