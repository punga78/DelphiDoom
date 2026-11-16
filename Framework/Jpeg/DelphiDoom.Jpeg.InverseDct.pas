{******************************************************************************}
{                                                                              }
{  DelphiDoom: JPEG - the contract of the inverse DCT                          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Jpeg.InverseDct;

interface

uses
  DelphiDoom.Jpeg.Types;

type
  /// <summary>
  ///   Turns a block of 64 coefficients into 8x8 samples. It also does the
  ///   dequantization, because the algorithms differ in the table that they
  ///   multiply by
  /// </summary>
  /// <remarks>
  ///   The decoder uses the accurate integer algorithm (TJpegSlowInverseDct).
  ///   A faster or a floating point one can be another class that implements
  ///   this interface
  /// </remarks>
  IJpegInverseDct = interface
    ['{4B7D2A19-6C35-4F8E-9A01-D3E55C7B0F62}']

    /// <summary>
    ///   Writes the 8x8 samples of the block into AOutput, a row after the
    ///   other at AStride bytes
    /// </summary>
    /// <param name="ACoefficients">The block, in natural order</param>
    /// <param name="AQuantization">The quantization table, in natural order</param>
    procedure Transform(const ACoefficients: TJpegBlock;
      const AQuantization: array of Integer; AOutput: PByte; AStride: NativeInt);
  end;

implementation

end.
