{******************************************************************************}
{                                                                              }
{  DD_Tools: the export of a picture to a file                                  }
{  Copyright (C) 2021-2022 by Jim Valavanis (original ENDEDIT)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tools.Win.ImageExporter;

interface

uses
  System.SysUtils,
  DelphiDoom.EndoomEditor.Intf;

type
  /// <summary>
  ///   Writes the picture as PNG, JPEG or BMP according to the extension of the name (PNG when it has none of
  ///   them, BMP for .bmp: what the export of ENDEDIT did with the other extensions)
  /// </summary>
  TVclEndoomImageExporter = class(TInterfacedObject, IEndoomEditorImageExporter)
  public
    function Export(const AFileName: string; const APixels: TArray<Cardinal>; AWidth, AHeight: Integer): Boolean;
  end;

implementation

uses
  System.Classes,
  Vcl.Graphics, Vcl.Imaging.pngimage, Vcl.Imaging.jpeg,
  DelphiDoom.Tools.Win.Bitmaps;

{ TVclEndoomImageExporter }

function TVclEndoomImageExporter.Export(const AFileName: string; const APixels: TArray<Cardinal>; AWidth,
  AHeight: Integer): Boolean;
var
  LBitmap: TBitmap;
  LExtension: string;
  LPng: TPngImage;
  LJpeg: TJPEGImage;
begin
  Result := False;
  if (AWidth < 1) or (AHeight < 1) or (Length(APixels) <> AWidth * AHeight) then
    Exit;
  LExtension := LowerCase(ExtractFileExt(AFileName));
  LBitmap := TToolsBitmapPixels.ToBitmap(APixels, AWidth, AHeight);
  try
    try
      if (LExtension = '.jpg') or (LExtension = '.jpeg') then
      begin
        LJpeg := TJPEGImage.Create;
        try
          LJpeg.Assign(LBitmap);
          LJpeg.SaveToFile(AFileName);
        finally
          LJpeg.Free;
        end;
      end
      else if LExtension = '.bmp' then
        LBitmap.SaveToFile(AFileName)
      else
      begin
        LPng := TPngImage.Create;
        try
          LPng.Assign(LBitmap);
          LPng.SaveToFile(AFileName);
        finally
          LPng.Free;
        end;
      end;
      Result := True;
    except
      on EInOutError do
        Result := False;
      on EFCreateError do
        Result := False;
      on EFOpenError do
        Result := False;
    end;
  finally
    LBitmap.Free;
  end;
end;

end.
