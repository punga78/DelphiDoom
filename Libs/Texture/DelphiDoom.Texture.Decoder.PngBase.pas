{******************************************************************************}
{                                                                              }
{  DelphiDoom: Texture library - what the decoders of PNG files share          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Port of TPNGBaseTextureManager (t_png.pas)                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Texture.Decoder.PngBase;

interface

uses
  System.SysUtils, DelphiDoom.Texture.Types, DelphiDoom.Texture.Image,
  DelphiDoom.Texture.Intf, DelphiDoom.Logging.Intf;

type
  /// <summary>
  ///   The base of the two decoders of PNG files: it reads the file with the PNG reader and gives
  ///   a warning to the log when that fails; the colors it hands out are as $00RRGGBB
  /// </summary>
  TTexturePngDecoderBase = class abstract(TInterfacedObject, ITextureDecoder)
  strict private
    FExtension: string;
    FReader: ITexturePngReader;
    FLog: ILog;
    function GetExtension: string;
  protected
    /// <summary>The color of the tRNS chunk, 0 when the file has none</summary>
    class function TransparentColorOfFile(const AData: TTexturePngData): Cardinal; static;
    /// <summary>A decoded pixel as $00RRGGBB (not for the images with a palette)</summary>
    class function PixelAt(const AData: TTexturePngData; AColumn, ARow: Integer): Cardinal; static;
    /// <summary>A decoded pixel with its alpha</summary>
    class function RawPixelAt(const AData: TTexturePngData; AColumn, ARow: Integer): Cardinal; static;
    class function PaletteColorAt(const AData: TTexturePngData; AIndex: Integer): Cardinal; static;
    class function PaletteAlphaAt(const AData: TTexturePngData; AIndex: Integer): Byte; static;
    /// <summary>Puts the image together from the data that the reader gave</summary>
    function Apply(const AData: TTexturePngData; const AImage: TTextureImage): Boolean; virtual; abstract;
  public
    constructor Create(const AExtension: string; const AReader: ITexturePngReader;
      const ALog: ILog);
    function Decode(const ASource: TBytes; const AImage: TTextureImage): Boolean;
    /// <summary>The colors made only of 00 and FF bytes with at least two FF (magenta, cyan, yellow, white)</summary>
    class function IsCommonTransparentColor(AColor: Cardinal): Boolean; static;
    /// <summary>Exchanges the red and the blue byte of a color</summary>
    class function SwapRedBlue(AColor: Cardinal): Cardinal; static;
  end;

implementation

{ TTexturePngDecoderBase }

constructor TTexturePngDecoderBase.Create(const AExtension: string;
  const AReader: ITexturePngReader; const ALog: ILog);
begin
  inherited Create;
  if not Assigned(AReader) then
    raise EArgumentNilException.Create('AReader');
  if not Assigned(ALog) then
    raise EArgumentNilException.Create('ALog');
  FExtension := AExtension;
  FReader := AReader;
  FLog := ALog;
end;

function TTexturePngDecoderBase.GetExtension: string;
begin
  Result := FExtension;
end;

class function TTexturePngDecoderBase.IsCommonTransparentColor(AColor: Cardinal): Boolean;
var
  LIndex: Integer;
  LZeros, LFulls: Integer;
begin
  LZeros := 0;
  LFulls := 0;
  for LIndex := 0 to 2 do
  begin
    if Byte(AColor) = 0 then
      Inc(LZeros)
    else if Byte(AColor) = $FF then
      Inc(LFulls);
    AColor := AColor shr 8;
  end;
  Result := ((LZeros + LFulls) = 3) and (LFulls > 1);
end;

class function TTexturePngDecoderBase.SwapRedBlue(AColor: Cardinal): Cardinal;
begin
  Result := ((AColor shr 16) and $FF) or (AColor and $FF00) or ((AColor and $FF) shl 16);
end;

class function TTexturePngDecoderBase.RawPixelAt(const AData: TTexturePngData; AColumn,
  ARow: Integer): Cardinal;
begin
  Result := PCardinal(@AData.Pixels[(ARow * AData.Width + AColumn) * 4])^;
end;

class function TTexturePngDecoderBase.PixelAt(const AData: TTexturePngData; AColumn,
  ARow: Integer): Cardinal;
begin
  Result := RawPixelAt(AData, AColumn, ARow) and $FFFFFF;
end;

class function TTexturePngDecoderBase.PaletteColorAt(const AData: TTexturePngData;
  AIndex: Integer): Cardinal;
begin
  Result := PCardinal(@AData.Palette[AIndex * 4])^ and $FFFFFF;
end;

class function TTexturePngDecoderBase.PaletteAlphaAt(const AData: TTexturePngData;
  AIndex: Integer): Byte;
begin
  Result := AData.Palette[AIndex * 4 + 3];
end;

class function TTexturePngDecoderBase.TransparentColorOfFile(const AData: TTexturePngData): Cardinal;
begin
  if AData.HasTransparentColor then
    Result := AData.TransparentColor and $FFFFFF
  else
    Result := 0;
end;

function TTexturePngDecoderBase.Decode(const ASource: TBytes; const AImage: TTextureImage): Boolean;
var
  LData: TTexturePngData;
  LMessage: string;
  LNeeded: Integer;
begin
  LData := Default(TTexturePngData);
  if not FReader.Read(ASource, LData, LMessage) then
  begin
    FLog.Warning('TPNGTextureManager(): ' + LMessage + #13#10);
    Exit(False);
  end;
  if (LData.Width <= 0) or (LData.Height <= 0) or (LData.Width > TEXTURE_MAX_DIMENSION) or
     (LData.Height > TEXTURE_MAX_DIMENSION) then
    Exit(False);
  LNeeded := LData.Width * LData.Height;
  if not LData.Indexed then
    LNeeded := LNeeded * 4;
  if Length(LData.Pixels) < LNeeded then
    Exit(False);
  if LData.Indexed and (Length(LData.Palette) < TEXTURE_PALETTE_SIZE * 4) then
    Exit(False);
  Result := Apply(LData, AImage);
end;

end.
