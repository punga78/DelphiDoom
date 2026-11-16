{******************************************************************************}
{                                                                              }
{  DelphiDoom: JPEG - the contract of the horizontal upsampling of a row       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Jpeg.RowUpsampler;

interface

type
  /// <summary>
  ///   Widens a row of a component that has fewer samples across than the
  ///   image, to the width of the image. The rows are made taller by the
  ///   renderer (TJpegRowRenderer), which asks for a row once for every row
  ///   of the image that it is needed in
  /// </summary>
  IJpegRowUpsampler = interface
    ['{C1A83E54-72D9-4B0F-A6E8-5F13B9D4720A}']

    /// <summary>
    ///   Writes the widened row into AOutput, which has room for the width of
    ///   the image rounded up to a multiple of the largest horizontal sampling
    ///   factor
    /// </summary>
    /// <param name="ARow">The samples of the component in the row</param>
    /// <param name="ANeighbour">
    ///   The row of the component that comes before (for the first row of the
    ///   pair) or after (for the second) in the original; only the filters
    ///   that smooth in the vertical direction read it
    /// </param>
    procedure UpsampleRow(ARow, ANeighbour, AOutput: PByte);
  end;

implementation

end.
