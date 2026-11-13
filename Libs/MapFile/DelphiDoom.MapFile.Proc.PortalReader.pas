{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - reading "interAreaPortals" of .proc          }
{                                                                              }
{  Port of idRenderWorldLocal::ParseInterAreaPortals (RenderWorld_load.cpp),   }
{  Doom 3 GPL Source Code.                                                     }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Proc.PortalReader;

interface

uses
  DelphiDoom.IdLib.Text.Lexer, DelphiDoom.MapFile.Proc.ProcFile;

type
  /// <summary>
  ///   Reads what follows the keyword "interAreaPortals": the number of areas, the number of
  ///   portals and, for each, the number of points, the two areas and the points as (x y z).
  ///   The areas of a portal must exist: the original indexes its array of areas with whatever
  ///   the file says, here a number out of range is an error
  /// </summary>
  TProcPortalReader = class
  public
    /// <summary>Sets <c>NumAreas</c> and <c>HasPortalSection</c> and adds the portals to the file</summary>
    class procedure Parse(const ALexer: TIdLexer; const AFile: TProcFile); static;
  end;

implementation

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.MapFile.Proc.Parse, DelphiDoom.MapFile.Proc.Portal;

resourcestring
  SBadNumAreas = 'R_ParseInterAreaPortals: bad numPortalAreas';
  SBadNumPortals = 'R_ParseInterAreaPortals: bad numInterAreaPortals';
  SBadNumPoints = 'R_ParseInterAreaPortals: bad numPoints';
  SBadAreaNumber = 'R_ParseInterAreaPortals: area %d is not in 0..%d';

{ TProcPortalReader }

class procedure TProcPortalReader.Parse(const ALexer: TIdLexer; const AFile: TProcFile);
var
  LPortalCount, LIndex, LPointIndex: Integer;
  LPortal: TProcPortal;
  LValues: array[0..2] of Single;
  LPoints: TArray<TGeoVec3>;
  LPositiveArea, LNegativeArea: Integer;
begin
  ALexer.ExpectTokenString('{');
  AFile.NumAreas := TProcParse.ReadCount(ALexer, SBadNumAreas);
  AFile.HasPortalSection := True;
  LPortalCount := TProcParse.ReadCount(ALexer, SBadNumPortals);
  for LIndex := 0 to LPortalCount - 1 do
  begin
    LPoints := nil;
    SetLength(LPoints, TProcParse.ReadCount(ALexer, SBadNumPoints));
    LPositiveArea := ALexer.ParseInt;
    LNegativeArea := ALexer.ParseInt;
    if (LPositiveArea < 0) or (LPositiveArea >= AFile.NumAreas) then
      ALexer.Error(SBadAreaNumber, [LPositiveArea, AFile.NumAreas - 1]);
    if (LNegativeArea < 0) or (LNegativeArea >= AFile.NumAreas) then
      ALexer.Error(SBadAreaNumber, [LNegativeArea, AFile.NumAreas - 1]);
    for LPointIndex := 0 to High(LPoints) do
    begin
      ALexer.Parse1DMatrix(3, LValues);
      LPoints[LPointIndex].X := LValues[0];
      LPoints[LPointIndex].Y := LValues[1];
      LPoints[LPointIndex].Z := LValues[2];
    end;
    LPortal := TProcPortal.Create;
    LPortal.PositiveArea := LPositiveArea;
    LPortal.NegativeArea := LNegativeArea;
    LPortal.Points := LPoints;
    AFile.Portals.Add(LPortal);
  end;
  ALexer.ExpectTokenString('}');
end;

end.
