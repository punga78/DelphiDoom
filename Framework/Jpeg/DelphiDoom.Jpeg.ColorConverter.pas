{******************************************************************************}
{                                                                              }
{  DelphiDoom: JPEG - the contract of the conversion of the colors             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Jpeg.ColorConverter;

interface

type
  /// <summary>
  ///   Turns a row of samples of the components (all as wide as the image)
  ///   into a row of pixels
  /// </summary>
  IJpegColorConverter = interface
    ['{5D2E8B71-0C46-4A93-B7F0-E81A3C95D624}']

    /// <summary>
    ///   Converts AWidth pixels. ARows has one row of samples for each
    ///   component of the stream
    /// </summary>
    procedure ConvertRow(const ARows: array of PByte; AOutput: PByte; AWidth: Integer);

    /// <summary>Bytes of a pixel of the output</summary>
    function OutputComponents: Integer;
  end;

implementation

end.
