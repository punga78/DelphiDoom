{******************************************************************************}
{                                                                              }
{  DelphiDoom: Texture library - TTextureDdsDecoder                            }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Texture.Decoder.Dds;

interface

uses
  System.SysUtils, DelphiDoom.Texture.Types, DelphiDoom.Texture.Image, DelphiDoom.Texture.Intf;

type
  /// <summary>
  ///   The decoder of the .DDS files for the external textures: the first level of the file as
  ///   an image of 4 bytes per pixel. It is not in TTextureFactory yet: the engine does not
  ///   look for DDS files, so adding it there would change what it loads
  /// </summary>
  TTextureDdsDecoder = class(TInterfacedObject, ITextureDecoder)
  strict private
    function GetExtension: string;
  public
    function Decode(const ASource: TBytes; const AImage: TTextureImage): Boolean;
  end;

implementation

uses
  DelphiDoom.Texture.Dds.Types, DelphiDoom.Texture.Dds.Reader;

{ TTextureDdsDecoder }

function TTextureDdsDecoder.GetExtension: string;
begin
  Result := '.DDS';
end;

function TTextureDdsDecoder.Decode(const ASource: TBytes; const AImage: TTextureImage): Boolean;
var
  LDds: TDdsImage;
  LBgra: TBytes;
  LIndex, LCount: Integer;
begin
  try
    LDds := TDdsReader.Read(ASource);
  except
    on EDdsException do
      Exit(False);
  end;
  LCount := LDds.Levels[0].Width * LDds.Levels[0].Height;
  SetLength(LBgra, LCount * 4);
  for LIndex := 0 to LCount - 1 do
  begin
    LBgra[LIndex * 4] := LDds.Levels[0].Pixels[LIndex * 4 + 2];
    LBgra[LIndex * 4 + 1] := LDds.Levels[0].Pixels[LIndex * 4 + 1];
    LBgra[LIndex * 4 + 2] := LDds.Levels[0].Pixels[LIndex * 4];
    LBgra[LIndex * 4 + 3] := LDds.Levels[0].Pixels[LIndex * 4 + 3];
  end;
  AImage.SetBytesPerPixel(4);
  AImage.SetWidth(LDds.Levels[0].Width);
  AImage.SetHeight(LDds.Levels[0].Height);
  AImage.PutPixels(0, 0, LCount, LBgra, 0, TEXTURE_FORMAT_32BIT);
  Result := AImage.HasPixels;
end;

end.
