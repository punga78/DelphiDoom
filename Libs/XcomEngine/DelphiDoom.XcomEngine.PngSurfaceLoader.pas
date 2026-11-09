{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - loads the PNG pictures of the Language     }
{  folder (the fonts) into surfaces (Surface::loadImage)                        }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.PngSurfaceLoader;

interface

uses
  System.SysUtils, DelphiDoom.Xcom.Types, DelphiDoom.Png.Client, DelphiDoom.XcomSurface.Surface,
  DelphiDoom.XcomSurface.Intf, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.FileMap;

type
  /// <summary>
  ///   IXcomSurfaceLoader for 8 bit indexed PNG files found in the Language folder of the virtual files: the
  ///   surface takes the size and the palette of the picture. The PNG client is not owned
  /// </summary>
  TXcomPngSurfaceLoader = class(TInterfacedObject, IXcomSurfaceLoader)
  strict private
    FFiles: TXcomFileMap;
    FPng: TPngClient;
  public
    constructor Create(AFiles: TXcomFileMap; APng: TPngClient);
    function LoadImage(const AName: string; AWidth, AHeight: Integer): TXcomSurface;
  end;

implementation

constructor TXcomPngSurfaceLoader.Create(AFiles: TXcomFileMap; APng: TPngClient);
begin
  inherited Create;
  FFiles := AFiles;
  FPng := APng;
end;

function TXcomPngSurfaceLoader.LoadImage(const AName: string; AWidth, AHeight: Integer): TXcomSurface;
var
  LImage: TPngIndexedImage;
  LColors: array[0..255] of TXcomColor;
  LIndex: Integer;
begin
  LImage := FPng.DecodeIndexed(FFiles.ReadAll('Language/' + AName));
  Result := TXcomSurface.Create(LImage.Info.Width, LImage.Info.Height);
  try
    Move(LImage.Pixels[0], Result.PixelPointer(0, 0)^, LImage.Info.Width * LImage.Info.Height);
    // the palette of the library is B, G, R, A
    for LIndex := 0 to 255 do
    begin
      LColors[LIndex].Blue := LImage.Palette[LIndex * 4];
      LColors[LIndex].Green := LImage.Palette[LIndex * 4 + 1];
      LColors[LIndex].Red := LImage.Palette[LIndex * 4 + 2];
      LColors[LIndex].Alpha := LImage.Palette[LIndex * 4 + 3];
    end;
    Result.SetColors(LColors);
  except
    Result.Free;
    raise;
  end;
end;

end.
