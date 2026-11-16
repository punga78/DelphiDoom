{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - weapon jump (rocket jump) reachabilities          }
{                                                                              }
{  Port of AAS_Reachability_WeaponJump of be_aas_reach.c: towards the areas    }
{  that are flagged AREA_WEAPONJUMP, from an area that is lower. The BFG jump  }
{  of the original is disabled (its loop runs once). Based on the Quake III    }
{  Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software,   }
{  Inc. This unit is derived from the Quake III Arena source code and is       }
{  therefore available under the GNU General Public License, version 2 or (at  }
{  your option) any later version.                                             }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Reach.WeaponJump;

{$Q-}
{$R+}

interface

uses
  DelphiDoom.Aas.Reach.Part;

type
  /// <summary>Rocket jump reachabilities between two areas</summary>
  TAasReachWeaponJump = class(TAasReachPart)
  public
    /// <summary>AAS_Reachability_WeaponJump: True if a reachability from the first area to the second was made</summary>
    function Calculate(const AArea1, AArea2: Integer): Boolean;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.MathCore.Types, DelphiDoom.Aas.Types, DelphiDoom.Aas.Move.Types,
  DelphiDoom.Aas.VectorMath, DelphiDoom.Aas.Reach.Types, DelphiDoom.Aas.Reach.Vectors;

const
  CTenthFloat: Single = 0.100000001490116119384765625;

{ TAasReachWeaponJump }

function TAasReachWeaponJump.Calculate(const AArea1, AArea2: Integer): Boolean;
var
  LIndex, LFace2Num: Integer;
  LArea1, LArea2: TAasArea;
  LFace2: TAasFace;
  LAreaStart, LFaceCenter, LStart, LEnd, LDir, LCmdMove, LVelocity: TVec3;
  LTrace: TAasTrace;
  LMove: TAasClientMove;
  LLink: PAasLinkedReach;
  LSpeed, LZVel, LLimit: Single;
begin
  if not Context.AreaGrounded(AArea1) or Context.AreaSwim(AArea1) then
    Exit(False);
  if not Context.AreaGrounded(AArea2) then
    Exit(False);
  // only weapon jump towards areas with an interesting item
  if (Context.AreaSettings[AArea2].AreaFlags and AREA_WEAPONJUMP) = 0 then
    Exit(False);
  LArea1 := Context.Areas[AArea1];
  LArea2 := Context.Areas[AArea2];
  // do not weapon jump towards way lower areas
  if LArea2.Maxs[2] < LArea1.Mins[2] then
    Exit(False);
  LStart := LArea1.Center;
  LEnd := LStart;
  LEnd[2] := LEnd[2] - 1000;
  LTrace := Context.Tracer.TraceClientBBox(LStart, LEnd, PRESENCE_CROUCH, -1);
  if LTrace.StartSolid then
    Exit(False);
  LAreaStart := LTrace.EndPos;
  for LIndex := 0 to LArea2.NumFaces - 1 do
  begin
    LFace2Num := Context.FaceIndex[LArea2.FirstFace + LIndex];
    LFace2 := Context.FaceTable[Abs(LFace2Num)];
    // if it is not a ground face
    if (LFace2.FaceFlags and FACE_GROUND) = 0 then
      Continue;
    // AAS_FaceCenter(face2num): the original passes the number with its sign and a negative one reads the memory before
    // the faces (a zero face in the tool): the center is not a number, no comparison is true and nothing is made
    if LFace2Num < 0 then
      Continue;
    Context.Geometry.FaceCenter(LFace2Num, LFaceCenter);
    // only go higher up with weapon jumps
    LLimit := LAreaStart[2] + 64;
    if LFaceCenter[2] < LLimit then
      Continue;
    // the rocket jump z velocity
    LZVel := Context.Movement.RocketJumpZVelocity(LAreaStart);
    // the horizontal speed for the jump: if it cannot be calculated no reachability is created
    if Context.Movement.HorizontalVelocityForJump(LZVel, LAreaStart, LFaceCenter, LSpeed) and (LSpeed < 300) then
    begin
      // the direction towards the face center
      TAasVectorMath.Subtract(LFaceCenter, LAreaStart, LDir);
      LDir[2] := 0;
      TAasVectorMath.Normalize(LDir);
      // the command movement
      TAasReachVectors.Scale(LDir, LSpeed, LCmdMove);
      LVelocity[0] := 0;
      LVelocity[1] := 0;
      LVelocity[2] := LZVel;
      Context.Movement.PredictClientMovement(LMove, -1, LAreaStart, PRESENCE_NORMAL, True, LVelocity, LCmdMove, 30, 30,
        CTenthFloat, SE_ENTERWATER or SE_ENTERSLIME or SE_ENTERLAVA or SE_HITGROUNDDAMAGE or SE_TOUCHJUMPPAD or
        SE_HITGROUND or SE_HITGROUNDAREA, AArea2, False);
      // if the prediction time was enough: do not enter slime or lava and do not fall from too high
      if (LMove.Frames < 30) and ((LMove.StopEvent and (SE_ENTERSLIME or SE_ENTERLAVA or SE_HITGROUNDDAMAGE)) = 0) and
         ((LMove.StopEvent and (SE_HITGROUNDAREA or SE_TOUCHJUMPPAD)) <> 0) then
      begin
        LLink := Context.Heap.Allocate;
        if LLink = nil then
          Exit(False);
        LLink^.AreaNum := AArea2;
        LLink^.FaceNum := 0;
        LLink^.EdgeNum := 0;
        LLink^.Start := LAreaStart;
        LLink^.EndPoint := LFaceCenter;
        LLink^.TravelType := TRAVEL_ROCKETJUMP;
        LLink^.TravelTime := TAasReachVectors.ToTravelTime(Context.Settings.RsRocketJump);
        Context.Heap.Push(AArea1, LLink);
        Inc(Context.Counters^.RocketJump);
        Exit(True);
      end;
    end;
  end;
  Result := False;
end;

end.
