{******************************************************************************}
{                                                                              }
{  DelphiDoom: texture library - R_LoadImage                                   }
{                                                                              }
{  Port of renderer\Image_files.cpp of the Doom 3 GPL Source Code (id          }
{  Software). Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.}
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or (at your       }
{  option) any later version, with the additional terms of the Doom 3 Source   }
{  Code License (Reference\doom3\COPYING.txt: preservation of legal notices    }
{  and trademarks, no use of the licensors' names for publicity, warranty      }
{  disclaimer). The repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Texture.IdImage.Loader;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Imaging.Rgba.Image, DelphiDoom.Texture.IdImage.Intf;

type
  /// <summary>
  ///   R_LoadImage: any of the images of Doom 3 into 32 bit RGBA. The files come from an injected source, the JPEG
  ///   decoder is injected too (<c>TIdImageJpegViaBitmap</c> makes one out of the JPEG converter of the engine).
  ///   <c>RoundDown</c> is the cvar <c>image_roundDown</c>: a side that is not a power of two goes to the power
  ///   below instead of above. Errors of a file that is there but is not an image of the kind its name says are
  ///   <c>ETextureException</c> (the original stops with common->Error).
  /// </summary>
  TIdImageLoader = class(TInterfacedObject, IIdImageLoader)
  strict private
    FSource: IIdImageSource;
    FJpeg: IIdImageJpegDecoder;
    FRoundDown: Boolean;
    function CanonicalName(const AName: string; out AExtension: AnsiString): AnsiString;
    function LoadFile(const AName: AnsiString; const AExtension: AnsiString; out AImage: TImagingRgbaImage;
      out ATimestamp: Int64): Boolean;
    function LoadJpeg(const AName: AnsiString; out AImage: TImagingRgbaImage; out ATimestamp: Int64): Boolean;
    function LoadTga(const AName: AnsiString; out AImage: TImagingRgbaImage; out ATimestamp: Int64): Boolean;
  public
    /// <summary>EArgumentNilException when the source is nil; the JPEG decoder may be nil (.jpg files are not read)</summary>
    constructor Create(const ASource: IIdImageSource; const AJpeg: IIdImageJpegDecoder = nil;
      const ARoundDown: Boolean = False);
    function Load(const AName: string; AMakePowerOf2: Boolean; out AImage: TImagingRgbaImage;
      out ATimestamp: Int64): Boolean;
    function Timestamp(const AName: string): Int64;
  end;

implementation

uses
  DelphiDoom.Imaging.Rgba.Sampler, DelphiDoom.Texture.IdImage.Bmp,
  DelphiDoom.Texture.IdImage.Pcx, DelphiDoom.Texture.Tga.IdReader;

/// <summary>idStr::DefaultFileExtension: appends the extension unless the last part of the path has one</summary>
function WithDefaultExtension(const AName, AExtension: AnsiString): AnsiString;
var
  LIndex: Integer;
begin
  for LIndex := Length(AName) downto 1 do
  begin
    if AName[LIndex] = '.' then
      Exit(AName);
    if (AName[LIndex] = '/') or (AName[LIndex] = '\') then
      Break;
  end;
  Result := AName + AExtension;
end;

/// <summary>idStr::StripFileExtension: cuts at the last dot</summary>
function WithoutExtension(const AName: AnsiString): AnsiString;
var
  LIndex: Integer;
begin
  for LIndex := Length(AName) downto 1 do
  begin
    if AName[LIndex] = '.' then
      Exit(Copy(AName, 1, LIndex - 1));
  end;
  Result := AName;
end;

/// <summary>idStr::ExtractFileExtension: what follows the last dot ('' when there is none or it is the first character)</summary>
function ExtensionOf(const AName: AnsiString): AnsiString;
var
  LPosition: Integer;
begin
  LPosition := Length(AName) - 1;
  while (LPosition > 0) and (AName[LPosition] <> '.') do
    Dec(LPosition);
  if LPosition <= 0 then
    Result := ''
  else
    Result := Copy(AName, LPosition + 1, MaxInt);
end;

function LowerAscii(const AName: AnsiString): AnsiString;
var
  LIndex: Integer;
begin
  Result := AName;
  for LIndex := 1 to Length(Result) do
  begin
    if Result[LIndex] in ['A'..'Z'] then
      Result[LIndex] := AnsiChar(Ord(Result[LIndex]) + 32);
  end;
end;
{ TIdImageLoader }

constructor TIdImageLoader.Create(const ASource: IIdImageSource; const AJpeg: IIdImageJpegDecoder;
  const ARoundDown: Boolean);
begin
  inherited Create;
  if not Assigned(ASource) then
    raise EArgumentNilException.Create('ASource');
  FSource := ASource;
  FJpeg := AJpeg;
  FRoundDown := ARoundDown;
end;

function TIdImageLoader.CanonicalName(const AName: string; out AExtension: AnsiString): AnsiString;
begin
  Result := WithDefaultExtension(AnsiString(AName), '.tga');
  AExtension := '';
  if Length(Result) < 5 then
    Exit;
  Result := LowerAscii(Result);
  AExtension := ExtensionOf(Result);
end;

function TIdImageLoader.LoadTga(const AName: AnsiString; out AImage: TImagingRgbaImage;
  out ATimestamp: Int64): Boolean;
var
  LBytes: TBytes;
begin
  AImage := Default(TImagingRgbaImage);
  Result := FSource.ReadFile(string(AName), LBytes, ATimestamp);
  if Result then
    AImage := TTgaIdReader.Read(LBytes);
  Result := Result and not AImage.IsEmpty;
end;

function TIdImageLoader.LoadJpeg(const AName: AnsiString; out AImage: TImagingRgbaImage;
  out ATimestamp: Int64): Boolean;
var
  LBytes: TBytes;
begin
  AImage := Default(TImagingRgbaImage);
  Result := FSource.ReadFile(string(AName), LBytes, ATimestamp);
  if Result and Assigned(FJpeg) then
    Result := FJpeg.Decode(LBytes, AImage)
  else
    Result := False;
  Result := Result and not AImage.IsEmpty;
end;

function TIdImageLoader.LoadFile(const AName: AnsiString; const AExtension: AnsiString;
  out AImage: TImagingRgbaImage; out ATimestamp: Int64): Boolean;
var
  LBytes: TBytes;
begin
  AImage := Default(TImagingRgbaImage);
  ATimestamp := ID_IMAGE_NO_TIMESTAMP;
  if AExtension = 'tga' then
  begin
    // try tga first
    Result := LoadTga(AName, AImage, ATimestamp);
    if (not Result) or (ATimestamp = ID_IMAGE_NO_TIMESTAMP) then
    begin
      Result := LoadJpeg(WithDefaultExtension(WithoutExtension(AName), '.jpg'), AImage, ATimestamp);
    end;
  end
  else if AExtension = 'pcx' then
  begin
    Result := FSource.ReadFile(string(AName), LBytes, ATimestamp) and TIdPcxReader.TryRead(LBytes, AImage);
  end
  else if AExtension = 'bmp' then
  begin
    Result := FSource.ReadFile(string(AName), LBytes, ATimestamp);
    if Result then
      AImage := TIdBmpReader.Read(LBytes, string(AName));
    Result := Result and not AImage.IsEmpty;
  end
  else if AExtension = 'jpg' then
    Result := LoadJpeg(AName, AImage, ATimestamp)
  else
    Result := False;
end;

function TIdImageLoader.Load(const AName: string; AMakePowerOf2: Boolean; out AImage: TImagingRgbaImage;
  out ATimestamp: Int64): Boolean;
var
  LName, LExtension: AnsiString;
  LScaledWidth, LScaledHeight: Integer;
begin
  AImage := Default(TImagingRgbaImage);
  ATimestamp := ID_IMAGE_NO_TIMESTAMP;
  Result := False;
  LName := CanonicalName(AName, LExtension);
  if LExtension = '' then
    Exit;
  if not LoadFile(LName, LExtension, AImage, ATimestamp) then
  begin
    AImage := Default(TImagingRgbaImage);
    Exit;
  end;
  // convert to exact power of 2 sizes
  if AMakePowerOf2 then
  begin
    LScaledWidth := 1;
    while LScaledWidth < AImage.Width do
      LScaledWidth := LScaledWidth shl 1;
    LScaledHeight := 1;
    while LScaledHeight < AImage.Height do
      LScaledHeight := LScaledHeight shl 1;
    if (LScaledWidth <> AImage.Width) or (LScaledHeight <> AImage.Height) then
    begin
      if FRoundDown and (LScaledWidth > AImage.Width) then
        LScaledWidth := LScaledWidth shr 1;
      if FRoundDown and (LScaledHeight > AImage.Height) then
        LScaledHeight := LScaledHeight shr 1;
      AImage := TImagingRgbaSampler.Resample(AImage, LScaledWidth, LScaledHeight);
    end;
  end;
  Result := True;
end;

function TIdImageLoader.Timestamp(const AName: string): Int64;
var
  LName, LExtension: AnsiString;
  LBytes: TBytes;
begin
  Result := ID_IMAGE_NO_TIMESTAMP;
  LName := CanonicalName(AName, LExtension);
  if LExtension = '' then
    Exit;
  if (LExtension = 'tga') or (LExtension = 'pcx') or (LExtension = 'bmp') or (LExtension = 'jpg') then
    FSource.ReadFile(string(LName), LBytes, Result);
  if (LExtension = 'tga') and (Result = ID_IMAGE_NO_TIMESTAMP) then
  begin
    FSource.ReadFile(string(WithDefaultExtension(WithoutExtension(LName), '.jpg')), LBytes, Result);
  end;
end;

end.