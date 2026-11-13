{******************************************************************************}
{                                                                              }
{  DelphiDoom: cinematic library - the contract of the JPEG decoder of a frame }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Cinematic.Jpeg.Intf;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   What the RoQ decoder asks of a JPEG library for the chunk <c>ROQ_QUAD_JPEG</c> (Doom 3,
  ///   <c>JPEGBlit</c>): the image of the chunk as RGB bytes. Small on purpose, so that the library
  ///   does not depend on the JPEG decoder (<c>TRoqJpegDecoder</c> is the one that uses
  ///   <c>Libs\Jpeg</c>) and the tests can give a fake
  /// </summary>
  IRoqJpegDecoder = interface
    ['{6D3B91F4-0A58-4E27-B6C3-18F7A2D54E09}']
    /// <summary>
    ///   Decodes a JPEG stream to RGB (three bytes per pixel, rows from the top). Data that are not a
    ///   valid JPEG are an <c>ERoqInvalidDataException</c>
    /// </summary>
    function Decode(const AData: TBytes; out AWidth, AHeight: Integer): TBytes;
  end;

implementation

end.
