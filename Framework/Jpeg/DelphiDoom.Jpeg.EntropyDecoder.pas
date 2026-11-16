{******************************************************************************}
{                                                                              }
{  DelphiDoom: JPEG - the contract of the decoders of the entropy coded data   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Jpeg.EntropyDecoder;

interface

uses
  DelphiDoom.Jpeg.Types;

type
  /// <summary>
  ///   Where the blocks of a MCU go: one pointer to a block of coefficients
  ///   for each block of the MCU, in the order of the scan
  /// </summary>
  TJpegBlockPointers = array[0..JPEG_MAX_BLOCKS_IN_MCU - 1] of PJpegBlock;

  /// <summary>
  ///   Decodes the coefficients of the MCUs of a scan from the bits of the
  ///   stream. There is one for the sequential (baseline) coding and one for
  ///   the progressive coding
  /// </summary>
  IJpegEntropyDecoder = interface
    ['{9E4C61D2-3A6B-4D0E-8F55-7B2C0E9A1C84}']

    /// <summary>
    ///   Starts the scan that the frame describes (tables, parameters,
    ///   restart interval)
    /// </summary>
    /// <exception cref="EJpegDecodeException">
    ///   A table is missing or not valid, or the parameters of the scan are
    ///   not valid
    /// </exception>
    procedure StartScan;

    /// <summary>
    ///   Decodes the next MCU into the blocks. A sequential scan writes the
    ///   coefficients that are not zero (the blocks must be zero), a
    ///   progressive scan adds to what the blocks have
    /// </summary>
    procedure DecodeMcu(const ABlocks: TJpegBlockPointers);
  end;

implementation

end.
