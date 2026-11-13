{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - the result of a trace through an .aas file   }
{                                                                              }
{  Port of aasTrace_t (AASFile.h), Doom 3 GPL Source Code.                     }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Aas.Trace;

interface

uses
  DelphiDoom.Geometry.Vec3;

type
  /// <summary>
  ///   The parameters and the answer of a trace (aasTrace_t). Make a new one with
  ///   <c>TAasTrace.Init</c>: a record on the stack is not cleared. The arrays of the original are
  ///   pointers that may be nil: here an array shorter than <c>MaxAreas</c> simply stores no more
  ///   than it can
  /// </summary>
  TAasTrace = record
    // parameters
    /// <summary>Areas with these AREA_ flags block the trace</summary>
    Flags: Integer;
    /// <summary>Areas with these TFL_ flags block the trace</summary>
    TravelFlags: Integer;
    /// <summary>How many areas to report (the original: size of the areas array)</summary>
    MaxAreas: Integer;
    /// <summary>Trace out of solid if the trace starts in solid</summary>
    GetOutOfSolid: Boolean;
    // output
    /// <summary>Fraction of the trace completed</summary>
    Fraction: Single;
    EndPos: TGeoVec3;
    /// <summary>The plane that was hit</summary>
    PlaneNum: Integer;
    /// <summary>The last area the trace went through</summary>
    LastAreaNum: Integer;
    /// <summary>The area that could not be entered (0: solid)</summary>
    BlockingAreaNum: Integer;
    NumAreas: Integer;
    /// <summary>The areas the trace went through (up to MaxAreas)</summary>
    Areas: TArray<Integer>;
    /// <summary>The points where the trace entered each new area</summary>
    Points: TArray<TGeoVec3>;
    /// <summary>The state of the constructor of aasTrace_s: nothing blocks, nothing is stored</summary>
    class function Init: TAasTrace; static;
  end;

implementation

{ TAasTrace }

class function TAasTrace.Init: TAasTrace;
begin
  Result.Flags := 0;
  Result.TravelFlags := 0;
  Result.MaxAreas := 0;
  Result.GetOutOfSolid := False;
  Result.Fraction := 0;
  Result.EndPos := TGeoVec3.Origin;
  Result.PlaneNum := 0;
  Result.LastAreaNum := 0;
  Result.BlockingAreaNum := 0;
  Result.NumAreas := 0;
  Result.Areas := nil;
  Result.Points := nil;
end;

end.
