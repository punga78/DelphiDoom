{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the PNG images of the fonts                       }
{                                                                              }
{  Port of war1 (acoto87/war1), war_font.c (wfont_loadFontSprite), (c) 2019    }
{  Alejandro Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt).     }
{  This is an altered version, not the original.                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Ui.FontImageLoader;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Png.Client, DelphiDoom.War.Graphics.Types;

type
  /// <summary>
  ///   Reads a PNG file of a font (war1_font_1.png, war1_font_2.png: images made for the remake, not in DATA.WAR)
  ///   into RGBA bytes. stbi_load applies no gamma and keeps the alpha, and so does the decoder of Framework\Png
  /// </summary>
  TWarFontImageLoader = class
  public
    /// <summary>The image of the file; the decoder (the PNG client) is not owned. EPngException if the file is not a PNG</summary>
    class function Load(const APath: string; const AClient: TPngClient): TWarImage; static;
    /// <summary>The same from the bytes of a file</summary>
    class function LoadBytes(const ABytes: TBytes; const AClient: TPngClient): TWarImage; static;
  end;

implementation

{ TWarFontImageLoader }

class function TWarFontImageLoader.Load(const APath: string; const AClient: TPngClient): TWarImage;
var
  LStream: TFileStream;
  LBytes: TBytes;
begin
  LStream := TFileStream.Create(APath, fmOpenRead or fmShareDenyNone);
  try
    SetLength(LBytes, LStream.Size);
    if Length(LBytes) > 0 then
      LStream.ReadBuffer(LBytes[0], Length(LBytes));
  finally
    LStream.Free;
  end;
  Result := LoadBytes(LBytes, AClient);
end;

class function TWarFontImageLoader.LoadBytes(const ABytes: TBytes; const AClient: TPngClient): TWarImage;
var
  LDecoded: TPngImage;
  LIndex: Integer;
  LBlue: Byte;
begin
  LDecoded := AClient.Decode(ABytes);
  Result.Width := LDecoded.Info.Width;
  Result.Height := LDecoded.Info.Height;
  Result.Pixels := LDecoded.Pixels;
  // the decoder gives B, G, R, A
  for LIndex := 0 to Result.Width * Result.Height - 1 do
  begin
    LBlue := Result.Pixels[LIndex * 4];
    Result.Pixels[LIndex * 4] := Result.Pixels[LIndex * 4 + 2];
    Result.Pixels[LIndex * 4 + 2] := LBlue;
  end;
end;

end.
