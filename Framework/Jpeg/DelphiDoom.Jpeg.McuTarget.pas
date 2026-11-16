{******************************************************************************}
{                                                                              }
{  DelphiDoom: JPEG - where the blocks of a MCU go                             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Jpeg.McuTarget;

interface

uses
  DelphiDoom.Jpeg.EntropyDecoder;

type
  /// <summary>
  ///   What the scan does with the blocks of a MCU: it asks for the blocks
  ///   to decode into, and tells when they are decoded. An image in one scan
  ///   turns each MCU into samples at once; an image in many scans keeps the
  ///   coefficients of all the blocks
  /// </summary>
  IJpegMcuTarget = interface
    ['{7A3F5E90-1D48-4C27-8B6A-92E04D1F6B35}']

    /// <summary>
    ///   Sets in ABlocks the blocks of the MCU that is at a row and a column
    ///   of the MCUs of the scan
    /// </summary>
    procedure BeginMcu(AMcuRow, AMcuColumn: Integer; var ABlocks: TJpegBlockPointers);

    /// <summary>
    ///   The blocks of the MCU were decoded
    /// </summary>
    procedure EndMcu(AMcuRow, AMcuColumn: Integer);
  end;

implementation

end.
