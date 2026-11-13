{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - writing "interAreaPortals" of .proc          }
{                                                                              }
{  Port of WriteOutputPortals (output.cpp of dmap), Doom 3 GPL Source Code.    }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Proc.PortalWriter;

interface

uses
  DelphiDoom.MapFile.TextWriter, DelphiDoom.MapFile.Proc.ProcFile;

type
  TProcPortalWriter = class
  public
    class procedure Write(const AOutput: TMapTextWriter; const AFile: TProcFile); static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Geometry.Vec3, DelphiDoom.MapFile.Proc.Portal,
  DelphiDoom.MapFile.Proc.MatrixWriter;

{ TProcPortalWriter }

class procedure TProcPortalWriter.Write(const AOutput: TMapTextWriter; const AFile: TProcFile);
var
  LIndex, LPointIndex: Integer;
  LPortal: TProcPortal;
  LPoint: TGeoVec3;
begin
  AOutput.Add(AnsiString(Format('interAreaPortals { /* numAreas = */ %d /* numIAP = */ %d'#10#10,
    [AFile.NumAreas, AFile.Portals.Count])));
  AOutput.Add('/* interAreaPortal format is: numPoints positiveSideArea negativeSideArea ( point) ... */'#10);
  for LIndex := 0 to AFile.Portals.Count - 1 do
  begin
    LPortal := AFile.Portals[LIndex];
    AOutput.Add(AnsiString(Format('/* iap %d */ %d %d %d ', [LIndex, LPortal.NumPoints,
      LPortal.PositiveArea, LPortal.NegativeArea])));
    for LPointIndex := 0 to LPortal.NumPoints - 1 do
    begin
      LPoint := LPortal.Points[LPointIndex];
      TProcMatrixWriter.Write1DMatrix(AOutput, [LPoint.X, LPoint.Y, LPoint.Z]);
    end;
    AOutput.Add(#10);
  end;
  AOutput.Add('}'#10#10);
end;

end.
