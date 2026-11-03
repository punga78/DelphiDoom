{******************************************************************************}
{                                                                              }
{  DelphiDoom: PNG - arranges the pixels of the caller for the encoder         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Png.PixelPacker;

interface

{$POINTERMATH ON}

type
  /// <summary>
  ///   Converts a row of the pixel layouts Encode accepts (DDPNG_FORMAT_*)
  ///   to the samples of a PNG scanline (8 bit gray, RGB or RGBA)
  /// </summary>
  TPngPixelPacker = class sealed
  public
    class function IsValidFormat(AFormat: Integer): Boolean; static;

    /// <summary>
    ///   Bytes of a pixel as the caller stores it
    /// </summary>
    class function SourceBytesPerPixel(AFormat: Integer): Integer; static;

    /// <summary>
    ///   Bytes of a pixel in the PNG scanline
    /// </summary>
    class function ScanlineBytesPerPixel(AFormat: Integer): Integer; static;

    /// <summary>
    ///   Color type (DDPNG_COLOR_*) of the PNG image written for the format
    /// </summary>
    class function ColorTypeOf(AFormat: Integer): Integer; static;

    /// <summary>
    ///   Writes into ADest the AWidth pixels of ASource as PNG samples
    /// </summary>
    class procedure PackRow(AFormat: Integer; ASource: PByte; AWidth: Integer;
      ADest: PByte); static;
  end;

implementation

uses
  DelphiDoom.Png.Intf;

{ TPngPixelPacker }

class function TPngPixelPacker.IsValidFormat(AFormat: Integer): Boolean;
begin
  Result := (AFormat >= DDPNG_FORMAT_BGRA) and (AFormat <= DDPNG_FORMAT_GRAY);
end;

class function TPngPixelPacker.SourceBytesPerPixel(AFormat: Integer): Integer;
begin
  case AFormat of
    DDPNG_FORMAT_BGRA, DDPNG_FORMAT_BGRX: Result := 4;
    DDPNG_FORMAT_BGR:                      Result := 3;
  else
    Result := 1;
  end;
end;

class function TPngPixelPacker.ScanlineBytesPerPixel(AFormat: Integer): Integer;
begin
  case AFormat of
    DDPNG_FORMAT_BGRA:                     Result := 4;
    DDPNG_FORMAT_BGRX, DDPNG_FORMAT_BGR:   Result := 3;
  else
    Result := 1;
  end;
end;

class function TPngPixelPacker.ColorTypeOf(AFormat: Integer): Integer;
begin
  case AFormat of
    DDPNG_FORMAT_BGRA:                     Result := DDPNG_COLOR_RGBA;
    DDPNG_FORMAT_BGRX, DDPNG_FORMAT_BGR:   Result := DDPNG_COLOR_RGB;
  else
    Result := DDPNG_COLOR_GRAY;
  end;
end;

class procedure TPngPixelPacker.PackRow(AFormat: Integer; ASource: PByte;
  AWidth: Integer; ADest: PByte);
var
  LIndex: Integer;
  LSource: PByte;
  LDest: PByte;
begin
  case AFormat of
    DDPNG_FORMAT_BGRA:
      for LIndex := 0 to AWidth - 1 do
      begin
        LSource := ASource + LIndex * 4;
        LDest := ADest + LIndex * 4;
        LDest[0] := LSource[2];
        LDest[1] := LSource[1];
        LDest[2] := LSource[0];
        LDest[3] := LSource[3];
      end;
    DDPNG_FORMAT_BGRX:
      for LIndex := 0 to AWidth - 1 do
      begin
        LSource := ASource + LIndex * 4;
        LDest := ADest + LIndex * 3;
        LDest[0] := LSource[2];
        LDest[1] := LSource[1];
        LDest[2] := LSource[0];
      end;
    DDPNG_FORMAT_BGR:
      for LIndex := 0 to AWidth - 1 do
      begin
        LSource := ASource + LIndex * 3;
        LDest := ADest + LIndex * 3;
        LDest[0] := LSource[2];
        LDest[1] := LSource[1];
        LDest[2] := LSource[0];
      end;
  else
    Move(ASource^, ADest^, AWidth);
  end;
end;

end.
