{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - Quake III player models, the swing of an    }
{  angle towards its destination                                               }
{                                                                              }
{  Port of CG_SwingAngles of cgame\cg_players.c. Based on the Quake III Arena  }
{  GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software, Inc.    }
{  This unit is derived from the Quake III Arena source code and is therefore  }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Q3Player.AngleSwinger;

{$Q-}
{$R-}

interface

type
  /// <summary>The legs and the torso do not follow the view at once: they swing towards it</summary>
  TQ3AngleSwinger = class
  public
    /// <summary>
    ///   CG_SwingAngles: the angle moves towards ADestination once it is more than ASwingTolerance
    ///   away, faster the further it is, and never stays more than AClampTolerance away. AFrameTime
    ///   is cg.frametime in milliseconds.
    /// </summary>
    class procedure Swing(const ADestination, ASwingTolerance, AClampTolerance, ASpeed: Single;
      const AFrameTime: Integer; var AAngle: Single; var ASwinging: Boolean); static;
  end;

implementation

uses
  DelphiDoom.Models.Q3Player.FloatMath;

class procedure TQ3AngleSwinger.Swing(const ADestination, ASwingTolerance, AClampTolerance, ASpeed: Single;
  const AFrameTime: Integer; var AAngle: Single; var ASwinging: Boolean);
var
  LSwing, LMove, LScale, LStep: Single;
begin
  if not ASwinging then
  begin
    // see if a swing should be started
    LSwing := TQ3FloatMath.AngleSubtract(AAngle, ADestination);
    if (LSwing > ASwingTolerance) or (LSwing < -ASwingTolerance) then
      ASwinging := True;
  end;

  if not ASwinging then
    Exit;

  // modify the speed depending on the delta so it doesn't seem so linear
  LSwing := TQ3FloatMath.AngleSubtract(ADestination, AAngle);
  LScale := Abs(LSwing);
  if Double(LScale) < Double(ASwingTolerance) * 0.5 then
    LScale := 0.5
  else if LScale < ASwingTolerance then
    LScale := 1.0
  else
    LScale := 2.0;

  // swing towards the destination angle
  if LSwing >= 0 then
  begin
    LStep := AFrameTime;
    LMove := LStep * LScale;
    LMove := LMove * ASpeed;
    if LMove >= LSwing then
    begin
      LMove := LSwing;
      ASwinging := False;
    end;
    LStep := AAngle + LMove;
    AAngle := TQ3FloatMath.AngleMod(LStep);
  end
  else if LSwing < 0 then
  begin
    LStep := AFrameTime;
    LMove := LStep * LScale;
    LMove := LMove * -ASpeed;
    if LMove <= LSwing then
    begin
      LMove := LSwing;
      ASwinging := False;
    end;
    LStep := AAngle + LMove;
    AAngle := TQ3FloatMath.AngleMod(LStep);
  end;

  // clamp to no more than tolerance
  LSwing := TQ3FloatMath.AngleSubtract(ADestination, AAngle);
  if LSwing > AClampTolerance then
  begin
    LStep := AClampTolerance - 1;
    LStep := ADestination - LStep;
    AAngle := TQ3FloatMath.AngleMod(LStep);
  end
  else if LSwing < -AClampTolerance then
  begin
    LStep := AClampTolerance - 1;
    LStep := ADestination + LStep;
    AAngle := TQ3FloatMath.AngleMod(LStep);
  end;
end;

end.
