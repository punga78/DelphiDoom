{******************************************************************************}
{                                                                              }
{  DelphiDoom: JPEG - images whose components are red, green and blue          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Derived from libjpeg 6b by the Independent JPEG Group                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Jpeg.RgbConverter;

interface

uses
  DelphiDoom.Jpeg.ColorConverter;

type
  /// <summary>
  ///   Three components that are already the colors: they are interleaved
  ///   in the order of the stream (null_convert). This is not the order of
  ///   the images that were in YCbCr, which come out as blue, green, red
  /// </summary>
  TJpegRgbConverter = class(TInterfacedObject, IJpegColorConverter)
  public
    procedure ConvertRow(const ARows: array of PByte; AOutput: PByte; AWidth: Integer);
    function OutputComponents: Integer;
  end;

implementation

{$POINTERMATH ON}

{ TJpegRgbConverter }

procedure TJpegRgbConverter.ConvertRow(const ARows: array of PByte;
  AOutput: PByte; AWidth: Integer);
var
  LComponent: Integer;
  LColumn: Integer;
  LInput: PByte;
begin
  for LComponent := 0 to 2 do
  begin
    LInput := ARows[LComponent];
    for LColumn := 0 to AWidth - 1 do
      AOutput[LColumn * 3 + LComponent] := LInput[LColumn];
  end;
end;

function TJpegRgbConverter.OutputComponents: Integer;
begin
  Result := 3;
end;

end.
