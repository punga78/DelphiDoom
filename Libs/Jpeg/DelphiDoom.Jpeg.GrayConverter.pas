{******************************************************************************}
{                                                                              }
{  DelphiDoom: JPEG - gray images                                              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Derived from libjpeg 6b by the Independent JPEG Group                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Jpeg.GrayConverter;

interface

uses
  DelphiDoom.Jpeg.ColorConverter;

type
  /// <summary>
  ///   One component, one byte per pixel: the samples are the pixels
  ///   (grayscale_convert)
  /// </summary>
  TJpegGrayConverter = class(TInterfacedObject, IJpegColorConverter)
  public
    procedure ConvertRow(const ARows: array of PByte; AOutput: PByte; AWidth: Integer);
    function OutputComponents: Integer;
  end;

implementation

{ TJpegGrayConverter }

procedure TJpegGrayConverter.ConvertRow(const ARows: array of PByte;
  AOutput: PByte; AWidth: Integer);
begin
  Move(ARows[0]^, AOutput^, AWidth);
end;

function TJpegGrayConverter.OutputComponents: Integer;
begin
  Result := 1;
end;

end.
