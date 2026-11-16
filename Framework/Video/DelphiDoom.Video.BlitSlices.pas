{******************************************************************************}
{                                                                              }
{  DelphiDoom: video library - the slices of a frame for the blit threads       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Video.BlitSlices;

interface

type
  /// <summary>A range of pixels of the frame, both ends included in the old convention of i_video</summary>
  TVideoBlitSlice = record
    Start: Integer;
    Finish: Integer;
  end;

  /// <summary>
  ///   Splits the 8 bit to 32 bit conversion of a frame between the blit threads. Cold: it runs
  ///   once per frame and only computes the bounds; the conversion loops stay in i_video
  /// </summary>
  TVideoBlitSlices = class sealed
  public
    /// <summary>How many slices to use for a machine with the given number of processors (2, 3, 4 or 8)</summary>
    class function SliceCount(const ACpuCount: Integer): Integer; static;
    /// <summary>
    ///   The slice AIndex (0-based) of ACount: it ends at (AIndex + 1) * ATotal div ACount cleared of
    ///   the two low bits (the last one at ATotal - 1) and starts one pixel after the previous one
    /// </summary>
    class function Slice(const ATotal, ACount, AIndex: Integer): TVideoBlitSlice; static;
  end;

implementation

{ TVideoBlitSlices }

class function TVideoBlitSlices.SliceCount(const ACpuCount: Integer): Integer;
begin
  if ACpuCount <= 2 then
    Result := 2
  else if ACpuCount <= 4 then
    Result := 3
  else if ACpuCount <= 6 then
    Result := 4
  else
    Result := 8;
end;

class function TVideoBlitSlices.Slice(const ATotal, ACount, AIndex: Integer): TVideoBlitSlice;
begin
  if AIndex = 0 then
    Result.Start := 0
  else
    Result.Start := ((AIndex * ATotal div ACount) and not 3) + 1;
  if AIndex = ACount - 1 then
    Result.Finish := ATotal - 1
  else
    Result.Finish := ((AIndex + 1) * ATotal div ACount) and not 3;
end;

end.
