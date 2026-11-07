{******************************************************************************}
{                                                                              }
{  DelphiDoom: Texture library - decoder of materials                          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Port of t_material.pas                                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Texture.Decoder.Material;

interface

uses
  System.SysUtils, DelphiDoom.Texture.Types, DelphiDoom.Texture.Image,
  DelphiDoom.Texture.Intf;

type
  /// <summary>
  ///   Reads a material (the extension is '.MATERIAL'): a text with lines "name=value"; the
  ///   value of "texture" is the name of another external texture, the value of "alpha" (it is
  ///   optional) the name of one whose gray scale becomes the alpha channel of the first.
  ///   The result is a 32 bit image with the pixels and the external alpha of the texture
  /// </summary>
  /// <remarks>
  ///   Differences from the old code: a texture with a palette is converted to 32 bit before
  ///   it is copied (the old one copied 4 bytes for each pixel out of a buffer of 1); the
  ///   texture is released also when the alpha is missing
  /// </remarks>
  TTextureMaterialDecoder = class(TInterfacedObject, ITextureDecoder)
  strict private
    FResolver: ITextureResolver;
    function GetExtension: string;
    class function ValueOf(const ASource: TBytes; const AName: string): string; static;
  public
    constructor Create(const AResolver: ITextureResolver);
    function Decode(const ASource: TBytes; const AImage: TTextureImage): Boolean;
  end;

implementation

uses
  DelphiDoom.Texture.Alpha;

{ TTextureMaterialDecoder }

constructor TTextureMaterialDecoder.Create(const AResolver: ITextureResolver);
begin
  inherited Create;
  if not Assigned(AResolver) then
    raise EArgumentNilException.Create('AResolver');
  FResolver := AResolver;
end;

function TTextureMaterialDecoder.GetExtension: string;
begin
  Result := '.MATERIAL';
end;

// The value of the first line that begins with "AName=" (the case counts); the text ends at
// a zero byte, the lines at a line feed or a carriage return
class function TTextureMaterialDecoder.ValueOf(const ASource: TBytes; const AName: string): string;
var
  LStart, LEnd: Integer;
  LLine: string;
  LCheck: string;
begin
  Result := '';
  LCheck := AName + '=';
  LStart := 0;
  while (LStart < Length(ASource)) and (ASource[LStart] <> 0) do
  begin
    LEnd := LStart;
    while (LEnd < Length(ASource)) and not (ASource[LEnd] in [0, 10, 13]) do
      Inc(LEnd);
    LLine := '';
    if LEnd > LStart then
      LLine := TEncoding.ANSI.GetString(ASource, LStart, LEnd - LStart);
    if (Length(LLine) >= Length(LCheck)) and (Copy(LLine, 1, Length(LCheck)) = LCheck) then
      Exit(Copy(LLine, Length(AName) + 2, MaxInt));
    LStart := LEnd;
    if (LStart < Length(ASource)) and (ASource[LStart] = 13) then
      Inc(LStart);
    if (LStart < Length(ASource)) and (ASource[LStart] = 10) then
      Inc(LStart);
  end;
end;

function TTextureMaterialDecoder.Decode(const ASource: TBytes; const AImage: TTextureImage): Boolean;
var
  LTextureName, LAlphaName: string;
  LTexture, LAlpha: TTextureImage;
begin
  Result := False;
  LTextureName := ValueOf(ASource, 'texture');
  LAlphaName := ValueOf(ASource, 'alpha');
  if LTextureName = '' then
    Exit;
  LTexture := FResolver.Load(LTextureName);
  if LTexture = nil then
    Exit;
  try
    if LAlphaName <> '' then
    begin
      LAlpha := FResolver.Load(LAlphaName);
      if LAlpha = nil then
        Exit;
      try
        LTexture.ConvertTo32bit;
        TTextureAlpha.SetChannelFromImage(LTexture, LAlpha);
      finally
        LAlpha.Free;
      end;
    end;
    LTexture.ConvertTo32bit;
    AImage.SetBytesPerPixel(4);
    AImage.SetWidth(LTexture.Width);
    AImage.SetHeight(LTexture.Height);
    if (not AImage.HasPixels) or (Length(AImage.Pixels) <> Length(LTexture.Pixels)) then
      Exit;
    Move(LTexture.Pixels[0], AImage.Pixels[0], Length(LTexture.Pixels));
    AImage.ExternalAlphaPresent := LTexture.ExternalAlphaPresent;
    Result := True;
  finally
    LTexture.Free;
  end;
end;

end.
