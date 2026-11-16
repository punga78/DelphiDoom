{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - swim reachabilities                               }
{                                                                              }
{  Port of AAS_Reachability_Swim of be_aas_reach.c. Based on the Quake III     }
{  Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software,   }
{  Inc. This unit is derived from the Quake III Arena source code and is       }
{  therefore available under the GNU General Public License, version 2 or (at  }
{  your option) any later version.                                             }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Reach.Swim;

{$Q-}
{$R+}

interface

uses
  DelphiDoom.Aas.Reach.Part;

type
  /// <summary>Swim reachabilities between adjacent areas of liquid</summary>
  TAasReachSwim = class(TAasReachPart)
  public
    /// <summary>AAS_Reachability_Swim: True if a reachability from the first area to the second was made</summary>
    function Calculate(const AArea1, AArea2: Integer): Boolean;
  end;

implementation

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Aas.Types, DelphiDoom.Aas.Move.Types, DelphiDoom.Aas.Reach.Types,
  DelphiDoom.Aas.Reach.Vectors;

{ TAasReachSwim }

function TAasReachSwim.Calculate(const AArea1, AArea2: Integer): Boolean;
var
  LIndex, LOther, LFace1Num, LFace2Num, LSide1: Integer;
  LArea1, LArea2: TAasArea;
  LLink: PAasLinkedReach;
  LPlane: TAasPlane;
  LStart: TVec3;
  LLimit: Single;
begin
  if not Context.AreaSwim(AArea1) or not Context.AreaSwim(AArea2) then
    Exit(False);
  // if the second area is crouch only
  if Context.AreaCrouch(AArea2) then
    Exit(False);
  LArea1 := Context.Areas[AArea1];
  LArea2 := Context.Areas[AArea2];
  // if the areas are not near enough
  for LIndex := 0 to 2 do
  begin
    LLimit := LArea2.Maxs[LIndex] + 10;
    if LArea1.Mins[LIndex] > LLimit then
      Exit(False);
    LLimit := LArea2.Mins[LIndex] - 10;
    if LArea1.Maxs[LIndex] < LLimit then
      Exit(False);
  end;
  // find a shared face and create a reachability link
  for LIndex := 0 to LArea1.NumFaces - 1 do
  begin
    LFace1Num := Context.FaceIndex[LArea1.FirstFace + LIndex];
    LSide1 := Ord(LFace1Num < 0);
    LFace1Num := Abs(LFace1Num);
    for LOther := 0 to LArea2.NumFaces - 1 do
    begin
      LFace2Num := Abs(Context.FaceIndex[LArea2.FirstFace + LOther]);
      if LFace1Num <> LFace2Num then
        Continue;
      Context.Geometry.FaceCenter(LFace1Num, LStart);
      if (Context.World.PointContents(LStart) and (BSP_CONTENTS_LAVA or BSP_CONTENTS_SLIME or BSP_CONTENTS_WATER)) = 0 then
        Continue;
      LLink := Context.Heap.Allocate;
      if LLink = nil then
        Exit(False);
      LLink^.AreaNum := AArea2;
      LLink^.FaceNum := LFace1Num;
      LLink^.EdgeNum := 0;
      LLink^.Start := LStart;
      LPlane := Context.Planes[Context.FaceTable[LFace1Num].PlaneNum xor LSide1];
      TAasReachVectors.MultiplyAdd(LLink^.Start, -INSIDEUNITS, LPlane.Normal, LLink^.EndPoint);
      LLink^.TravelType := TRAVEL_SWIM;
      LLink^.TravelTime := 1;
      // if the volume of the area is rather small
      if Context.Geometry.AreaVolume(AArea2) < 800 then
        LLink^.TravelTime := LLink^.TravelTime + 200;
      Context.Heap.Push(AArea1, LLink);
      Inc(Context.Counters^.Swim);
      Exit(True);
    end;
  end;
  Result := False;
end;

end.
