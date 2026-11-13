{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - Quake III player models, the angles of      }
{  legs, torso and head                                                        }
{                                                                              }
{  Port of CG_PlayerAngles and CG_AddPainTwitch of cgame\cg_players.c, the     }
{  part that computes axes. Based on the Quake III Arena GPL Source Code (id   }
{  Software). Copyright (C) 1999-2005 Id Software, Inc. This unit is derived   }
{  from the Quake III Arena source code and is therefore available under the   }
{  GNU General Public License, version 2 or (at your option) any later         }
{  version.                                                                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Q3Player.PlayerAngles;

{$Q-}
{$R-}

interface

uses
  System.SysUtils,
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.Models.Q3Player.Types,
  DelphiDoom.Models.Q3Player.Intf;

type
  /// <summary>
  ///   Handles separate torso motion: the legs pivot on the direction of the movement, the head
  ///   looks exactly at the view, the torso takes a quarter of the movement offset and three
  ///   quarters of the pitch; each is given relative to the one below it (head to torso, torso to
  ///   legs). The yaw of legs and torso and the pitch of the torso swing, so the state is the
  ///   player entity's.
  /// </summary>
  TQ3PlayerAngles = class(TInterfacedObject, IQ3PlayerAngles)
  strict private
    FConfig: IQ3AnimationConfig;
    FSwingSpeed: Single;
    procedure AddPainTwitch(const APlayer: TQ3PlayerEntity; const ATime: Integer; var ATorsoAngles: TIdVec3);
  public
    /// <summary>ASwingSpeed is cg_swingSpeed (0.3)</summary>
    constructor Create(const AConfig: IQ3AnimationConfig; const ASwingSpeed: Single = 0.3);
    procedure Compute(const AInput: TQ3PlayerAngleInput; var APlayer: TQ3PlayerEntity;
      out ALegs, ATorso, AHead: TQ3Axis);
  end;

implementation

uses
  DelphiDoom.MathCore.Patch.VertexMath,
  DelphiDoom.Models.Q3Player.AngleSwinger,
  DelphiDoom.Models.Q3Player.FloatMath;

const
  // static int movementOffsets[8]
  MOVEMENT_OFFSETS: array[0..7] of Integer = (0, 22, 45, -22, 0, 22, -45, -22);

constructor TQ3PlayerAngles.Create(const AConfig: IQ3AnimationConfig; const ASwingSpeed: Single);
begin
  inherited Create;
  FConfig := AConfig;
  FSwingSpeed := ASwingSpeed;
end;

procedure TQ3PlayerAngles.AddPainTwitch(const APlayer: TQ3PlayerEntity; const ATime: Integer;
  var ATorsoAngles: TIdVec3);
var
  LElapsed: Integer;
  LValue, LFactor, LDelta: Single;
begin
  LElapsed := ATime - APlayer.PainTime;
  if LElapsed >= Q3_PAIN_TWITCH_TIME then
    Exit;

  // f = 1.0 - (float)t / PAIN_TWITCH_TIME
  LValue := LElapsed;
  LValue := LValue / Q3_PAIN_TWITCH_TIME;
  LFactor := Single(1.0 - Double(LValue));
  LDelta := 20 * LFactor;
  if APlayer.PainDirection <> 0 then
    ATorsoAngles.Z := ATorsoAngles.Z + LDelta
  else
    ATorsoAngles.Z := ATorsoAngles.Z - LDelta;
end;

procedure TQ3PlayerAngles.Compute(const AInput: TQ3PlayerAngleInput; var APlayer: TQ3PlayerEntity;
  out ALegs, ATorso, AHead: TQ3Axis);
var
  LLegsAngles, LTorsoAngles, LHeadAngles: TIdVec3;
  LDest, LSpeed, LSide, LSum: Single;
  LDirection: Integer;
  LVelocity: TIdVec3;
  LAxis: TQ3Axis;
begin
  LHeadAngles := AInput.LerpAngles;
  LHeadAngles.Y := TQ3FloatMath.AngleMod(LHeadAngles.Y);
  LLegsAngles.Zero;
  LTorsoAngles.Zero;

  // --------- yaw -------------

  // allow yaw to drift a bit
  if ((AInput.LegsAnim and not Q3_ANIM_TOGGLEBIT) <> Q3_LEGS_IDLE)
    or ((AInput.TorsoAnim and not Q3_ANIM_TOGGLEBIT) <> Q3_TORSO_STAND) then
  begin
    // if not standing still, always point all in the same direction
    APlayer.Torso.Yawing := True; // always center
    APlayer.Torso.Pitching := True; // always center
    APlayer.Legs.Yawing := True; // always center
  end;

  // adjust legs for movement dir
  if AInput.Dead then
    // don't let dead bodies twitch
    LDirection := 0
  else
  begin
    LDirection := TQ3FloatMath.ToInt(Double(AInput.MovementDirection));
    if (LDirection < 0) or (LDirection > 7) then
      raise EQ3PlayerException.CreateAtLine(SQ3BadMovementAngle, 0);
  end;
  // headAngles[YAW] + movementOffsets[dir] is a float sum; 0.25 * offset is a double product
  LLegsAngles.Y := LHeadAngles.Y + MOVEMENT_OFFSETS[LDirection];
  LTorsoAngles.Y := Single(Double(LHeadAngles.Y) + 0.25 * MOVEMENT_OFFSETS[LDirection]);

  // torso
  TQ3AngleSwinger.Swing(LTorsoAngles.Y, 25, 90, FSwingSpeed, AInput.FrameTime,
    APlayer.Torso.YawAngle, APlayer.Torso.Yawing);
  TQ3AngleSwinger.Swing(LLegsAngles.Y, 40, 90, FSwingSpeed, AInput.FrameTime,
    APlayer.Legs.YawAngle, APlayer.Legs.Yawing);

  LTorsoAngles.Y := APlayer.Torso.YawAngle;
  LLegsAngles.Y := APlayer.Legs.YawAngle;

  // --------- pitch -------------

  // only show a fraction of the pitch angle in the torso
  if LHeadAngles.X > 180 then
  begin
    LDest := -360 + LHeadAngles.X;
    LDest := LDest * Single(0.75);
  end
  else
    LDest := LHeadAngles.X * Single(0.75);
  TQ3AngleSwinger.Swing(LDest, 15, 30, Single(0.1), AInput.FrameTime,
    APlayer.Torso.PitchAngle, APlayer.Torso.Pitching);
  LTorsoAngles.X := APlayer.Torso.PitchAngle;

  if FConfig.FixedTorso then
    LTorsoAngles.X := 0;

  // --------- roll -------------

  // lean towards the direction of travel
  LVelocity := AInput.Velocity;
  LSpeed := TPatchVertexMath.Normalize(LVelocity);
  if LSpeed <> 0 then
  begin
    LSpeed := LSpeed * Single(0.05);

    TQ3FloatMath.AnglesToAxis(LLegsAngles, LAxis);
    LSum := TQ3FloatMath.Dot(LVelocity, LAxis[1]);
    LSide := LSpeed * LSum;
    LLegsAngles.Z := LLegsAngles.Z - LSide;

    LSum := TQ3FloatMath.Dot(LVelocity, LAxis[0]);
    LSide := LSpeed * LSum;
    LLegsAngles.X := LLegsAngles.X + LSide;
  end;

  if FConfig.FixedLegs then
  begin
    LLegsAngles.Y := LTorsoAngles.Y;
    LLegsAngles.X := 0;
    LLegsAngles.Z := 0;
  end;

  // pain twitch
  AddPainTwitch(APlayer, AInput.Time, LTorsoAngles);

  // pull the angles back out of the hierarchial chain
  LHeadAngles := TQ3FloatMath.AnglesSubtract(LHeadAngles, LTorsoAngles);
  LTorsoAngles := TQ3FloatMath.AnglesSubtract(LTorsoAngles, LLegsAngles);
  TQ3FloatMath.AnglesToAxis(LLegsAngles, ALegs);
  TQ3FloatMath.AnglesToAxis(LTorsoAngles, ATorso);
  TQ3FloatMath.AnglesToAxis(LHeadAngles, AHead);
end;

end.
