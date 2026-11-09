{******************************************************************************}
{                                                                              }
{  DelphiDoom: OpenGL call recorder - sizes of pixels and of client arrays     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.OpenGl.Recorder.PixelFormats;

interface

type
  /// <summary>
  ///   Sizes of the pixel formats and data types of OpenGL 1.x, so that the recorder knows how many
  ///   bytes a pointer argument points to. Anything it does not know (packed types, bitmaps,
  ///   compressed formats) has size 0: the recorder then writes only that the pointer was not nil.
  /// </summary>
  TGlPixelFormats = class sealed
  public
    /// <summary>The bytes of one element of a GL data type (byte, short, int, float, double), 0 if it is not one of them</summary>
    class function TypeSize(const AType: Cardinal): Integer; static;
    /// <summary>The number of components of a pixel format (RGBA is 4), 0 if the format is unknown</summary>
    class function ComponentCount(const AFormat: Cardinal): Integer; static;
    /// <summary>
    ///   The bytes of one row of pixels (ARowBytes, without padding) and the distance between two rows
    ///   with the unpack alignment AAlignment (AStride); false if the format or the type is not known.
    /// </summary>
    class function MeasureRow(const AWidth: Integer; const AFormat, AType: Cardinal; const AAlignment: Integer;
      out ARowBytes, AStride: Int64): Boolean; static;
  end;

implementation

{ TGlPixelFormats }

class function TGlPixelFormats.TypeSize(const AType: Cardinal): Integer;
begin
  case AType of
    $1400, $1401: Result := 1;  // GL_BYTE, GL_UNSIGNED_BYTE
    $1402, $1403: Result := 2;  // GL_SHORT, GL_UNSIGNED_SHORT
    $1404, $1405: Result := 4;  // GL_INT, GL_UNSIGNED_INT
    $1406: Result := 4;         // GL_FLOAT
    $140A: Result := 8;         // GL_DOUBLE
  else
    Result := 0;
  end;
end;

class function TGlPixelFormats.ComponentCount(const AFormat: Cardinal): Integer;
begin
  case AFormat of
    $1900, $1901, $1902,        // COLOR_INDEX, STENCIL_INDEX, DEPTH_COMPONENT
    $1903, $1904, $1905,        // RED, GREEN, BLUE
    $1906, $1909: Result := 1;  // ALPHA, LUMINANCE
    $190A: Result := 2;         // LUMINANCE_ALPHA
    $1907, $80E0: Result := 3;  // RGB, BGR
    $1908, $80E1: Result := 4;  // RGBA, BGRA
  else
    Result := 0;
  end;
end;

class function TGlPixelFormats.MeasureRow(const AWidth: Integer; const AFormat, AType: Cardinal;
  const AAlignment: Integer; out ARowBytes, AStride: Int64): Boolean;
var
  LPixelBytes: Int64;
  LAlignment: Int64;
begin
  ARowBytes := 0;
  AStride := 0;
  Result := False;
  if (AWidth < 0) or (AWidth > 65536) then
    Exit;
  LPixelBytes := Int64(ComponentCount(AFormat)) * TypeSize(AType);
  if LPixelBytes = 0 then
    Exit;
  ARowBytes := LPixelBytes * AWidth;
  LAlignment := AAlignment;
  if LAlignment < 1 then
    LAlignment := 1;
  // the distance between the rows is the row rounded up to the alignment
  AStride := ((ARowBytes + LAlignment - 1) div LAlignment) * LAlignment;
  Result := True;
end;

end.
