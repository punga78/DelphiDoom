{******************************************************************************}
{                                                                              }
{  DelphiDoom: video library - stretching of rows and buffers                   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Video.Stretch;

interface

type
  PVideoByteRow = ^TVideoByteRow;
  TVideoByteRow = packed array[0..MaxInt div 2 - 1] of Byte;

  PVideoLongWordRow = ^TVideoLongWordRow;
  TVideoLongWordRow = packed array[0..MaxInt div 8 - 1] of LongWord;

  /// <summary>
  ///   The hot kernels of the stretching of v_video (intermission and status bar of the wide
  ///   screens, scaling of full screen pictures). Static functions on plain pointers, no
  ///   interfaces and no allocation: the loops are the ones that were in v_video, called once
  ///   per row (or per buffer), never per pixel
  /// </summary>
  TVideoStretch = class sealed
  public
    /// <summary>
    ///   How much of a 4:3 picture is narrower than a screen of the given size, in percent
    ///   (0 or less when the screen is not wider than 4:3)
    /// </summary>
    class function WidePercentage(const AWidth, AHeight: Integer): Integer; static;
    /// <summary>
    ///   Fills ABuffer[AStart..AStop] with the row ASource stretched on AStop - AStart + 1 pixels
    ///   (nearest pixel, the index clamped to the row)
    /// </summary>
    class procedure StretchRow8(const ASource, ABuffer: PVideoByteRow; const AWidth, AStart, AStop: Integer); static;
    /// <summary>As StretchRow8 on 32 bit pixels</summary>
    class procedure StretchRow32(const ASource, ABuffer: PVideoLongWordRow; const AWidth, AStart, AStop: Integer); static;
    /// <summary>As StretchRow32, with the alpha of the pixels forced to opaque</summary>
    class procedure StretchRow32Opaque(const ASource, ABuffer: PVideoLongWordRow; const AWidth, AStart, AStop: Integer); static;
    /// <summary>
    ///   Nearest pixel scaling of an 8 bit picture of ASourceWidth x ASourceHeight to a buffer of
    ///   ADestWidth x ADestHeight (16.16 fixed point steps)
    /// </summary>
    class procedure ScaleNearest8(const ASource, ADestination: PVideoByteRow;
      const ASourceWidth, ASourceHeight, ADestWidth, ADestHeight: Integer); static;
  end;

implementation

{ TVideoStretch }

class function TVideoStretch.WidePercentage(const AWidth, AHeight: Integer): Integer;
begin
  Result := Round((1 - (4 / 3) / (AWidth / AHeight)) * 100);
end;

class procedure TVideoStretch.StretchRow8(const ASource, ABuffer: PVideoByteRow;
  const AWidth, AStart, AStop: Integer);
var
  LIndex: Integer;
  LSource: Integer;
begin
  for LIndex := AStart to AStop do
  begin
    LSource := AWidth * (LIndex - AStart) div (AStop - AStart + 1);
    if LSource < 0 then
      LSource := 0
    else if LSource > AWidth - 1 then
      LSource := AWidth - 1;
    ABuffer[LIndex] := ASource[LSource];
  end;
end;

class procedure TVideoStretch.StretchRow32(const ASource, ABuffer: PVideoLongWordRow;
  const AWidth, AStart, AStop: Integer);
var
  LIndex: Integer;
  LSource: Integer;
begin
  for LIndex := AStart to AStop do
  begin
    LSource := AWidth * (LIndex - AStart) div (AStop - AStart + 1);
    if LSource < 0 then
      LSource := 0
    else if LSource > AWidth - 1 then
      LSource := AWidth - 1;
    ABuffer[LIndex] := ASource[LSource];
  end;
end;

class procedure TVideoStretch.StretchRow32Opaque(const ASource, ABuffer: PVideoLongWordRow;
  const AWidth, AStart, AStop: Integer);
var
  LIndex: Integer;
  LSource: Integer;
begin
  for LIndex := AStart to AStop do
  begin
    LSource := AWidth * (LIndex - AStart) div (AStop - AStart + 1);
    if LSource < 0 then
      LSource := 0
    else if LSource > AWidth - 1 then
      LSource := AWidth - 1;
    ABuffer[LIndex] := $FF000000 or ASource[LSource];
  end;
end;

class procedure TVideoStretch.ScaleNearest8(const ASource, ADestination: PVideoByteRow;
  const ASourceWidth, ASourceHeight, ADestWidth, ADestHeight: Integer);
var
  LStepX: Integer;
  LStepY: Integer;
  LSourceX: Integer;
  LSourceY: Integer;
  LX: Integer;
  LY: Integer;
  LRow: PVideoByteRow;
  LDestination: PVideoByteRow;
begin
  LStepX := (ASourceWidth shl 16) div ADestWidth;
  LStepY := (ASourceHeight shl 16) div ADestHeight;
  LDestination := ADestination;
  LSourceY := 0;
  for LY := 0 to ADestHeight - 1 do
  begin
    LRow := @ASource[(LSourceY shr 16) * ASourceWidth];
    LSourceX := 0;
    for LX := 0 to ADestWidth - 1 do
    begin
      LDestination[LX] := LRow[LSourceX shr 16];
      LSourceX := LSourceX + LStepX;
    end;
    LDestination := @LDestination[ADestWidth];
    LSourceY := LSourceY + LStepY;
  end;
end;

end.
