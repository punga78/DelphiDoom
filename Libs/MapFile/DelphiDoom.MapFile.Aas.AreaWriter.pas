{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - writing the areas of an .aas file            }
{                                                                              }
{  Port of the section areas of idAASFileLocal::Write, Reachability_Write and  }
{  Reachability_Special_Write (AASFile.cpp), Doom 3 GPL Source Code.           }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Aas.AreaWriter;

interface

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.MapFile.TextWriter, DelphiDoom.MapFile.Aas.AasFile,
  DelphiDoom.MapFile.Aas.Reachability;

type
  /// <summary>
  ///   Writes "areas": the reachabilities of an area in the order of its chain, which is the
  ///   order the reader gives back, so that a file read and written again lists them in the
  ///   opposite order, as it does with the original. Keys and values of a special reachability
  ///   are written between quotes without any escape
  /// </summary>
  TAasAreaWriter = class
  strict private
    class procedure AddVector(const AOutput: TMapTextWriter; const AValue: TGeoVec3); static;
    class procedure WriteReachability(const AOutput: TMapTextWriter; const AReach: TAasReachability); static;
    class procedure WriteSpecial(const AOutput: TMapTextWriter; const AReach: TAasReachability); static;
  public
    class procedure Write(const AOutput: TMapTextWriter; const AFile: TAasFile); static;
  end;

implementation

uses
  DelphiDoom.Scanner.IdDict, DelphiDoom.MapFile.Aas.Types, DelphiDoom.MapFile.Aas.Area;

{ TAasAreaWriter }

class procedure TAasAreaWriter.AddVector(const AOutput: TMapTextWriter; const AValue: TGeoVec3);
begin
  AOutput.Add('(');
  AOutput.AddFloat(AValue.X);
  AOutput.Add(' ');
  AOutput.AddFloat(AValue.Y);
  AOutput.Add(' ');
  AOutput.AddFloat(AValue.Z);
  AOutput.Add(')');
end;

class procedure TAasAreaWriter.WriteSpecial(const AOutput: TMapTextWriter; const AReach: TAasReachability);
var
  LIndex: Integer;
  LKeyValue: TIdKeyValue;
begin
  AOutput.Add(#10#9#9'{'#10);
  if Assigned(AReach.Special) then
    for LIndex := 0 to AReach.Special.GetNumKeyVals - 1 do
      if AReach.Special.TryGetKeyVal(LIndex, LKeyValue) then
        AOutput.Add(#9#9#9'"' + LKeyValue.Key + '" "' + LKeyValue.Value + '"'#10);
  AOutput.Add(#9#9'}'#10);
end;

class procedure TAasAreaWriter.WriteReachability(const AOutput: TMapTextWriter; const AReach: TAasReachability);
begin
  AOutput.Add(#9#9);
  AOutput.AddInteger(AReach.TravelType);
  AOutput.Add(' ');
  AOutput.AddInteger(AReach.ToAreaNum);
  AOutput.Add(' ');
  AddVector(AOutput, AReach.StartPoint);
  AOutput.Add(' ');
  AddVector(AOutput, AReach.EndPoint);
  AOutput.Add(' ');
  AOutput.AddInteger(AReach.EdgeNum);
  AOutput.Add(' ');
  AOutput.AddInteger(AReach.TravelTime);
  if AReach.TravelType = TFL_SPECIAL then
    WriteSpecial(AOutput, AReach);
  AOutput.Add(#10);
end;

class procedure TAasAreaWriter.Write(const AOutput: TMapTextWriter; const AFile: TAasFile);
var
  LIndex: Integer;
  LArea: TAasArea;
  LReach: TAasReachability;
begin
  AOutput.Add('areas ');
  AOutput.AddInteger(AFile.NumAreas);
  AOutput.Add(' {'#10);
  for LIndex := 0 to AFile.NumAreas - 1 do
  begin
    LArea := AFile.Areas[LIndex];
    AOutput.Add(#9);
    AOutput.AddInteger(LIndex);
    AOutput.Add(' ( ');
    AOutput.AddInteger(LArea.Flags);
    AOutput.Add(' ');
    AOutput.AddInteger(LArea.Contents);
    AOutput.Add(' ');
    AOutput.AddInteger(LArea.FirstFace);
    AOutput.Add(' ');
    AOutput.AddInteger(LArea.NumFaces);
    AOutput.Add(' ');
    AOutput.AddInteger(LArea.Cluster);
    AOutput.Add(' ');
    AOutput.AddInteger(LArea.ClusterAreaNum);
    AOutput.Add(' ) ');
    AOutput.AddInteger(LArea.Reach.Count);
    AOutput.Add(' {'#10);
    for LReach in LArea.Reach do
      WriteReachability(AOutput, LReach);
    AOutput.Add(#9'}'#10);
  end;
  AOutput.Add('}'#10);
end;

end.
