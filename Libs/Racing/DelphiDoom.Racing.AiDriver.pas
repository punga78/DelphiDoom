{******************************************************************************}
{                                                                              }
{  DelphiDoom: racing library - the driver of the computer                     }
{  Copyright (C) 1995 by Noriaworks                                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of SH_BuildDrivingCmdAI of speed_cars.pas                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Racing.AiDriver;

// Speeds, angles and forces are 16.16 fixed point and 32 bit integers that wrap as in the old
// code; the angles are unsigned and the divisions by a signed factor are Int64 as in the old code
{$Q-}
{$R-}
// The mixed signed and unsigned operations are the ones of the old code: the results are the same only with the same types
{$WARN COMBINING_SIGNED_UNSIGNED OFF}

interface

uses
  DelphiDoom.Racing.Types, DelphiDoom.Racing.Intf;

type
  /// <summary>
  ///   Drives a car of the computer along the path of the track: steers towards the next point
  ///   and brakes or pushes to the speed of the point. The skill of the game changes how hard
  ///   the cars push and how sharply they steer
  /// </summary>
  TRacingAiDriver = class(TInterfacedObject, IRacingDriver)
  strict private
    FRace: IRacingRaceState;
    FTrack: IRacingTrack;
    FGeometry: IRacingGeometry;
  public
    constructor Create(const ARace: IRacingRaceState; const ATrack: IRacingTrack;
      const AGeometry: IRacingGeometry);
    procedure BuildCommand(var ACar: TRacingCarState; out ACommand: TRacingDrivingCommand);
  end;

implementation

uses
  System.SysUtils, DelphiDoom.MathCore.Types, DelphiDoom.MathCore.FixedMath,
  DelphiDoom.Racing.CarData, DelphiDoom.Racing.GearBox, DelphiDoom.Racing.Math;

const
  // The factors of the accelerator and of the steering for each skill (a factor of 65536 is 1)
  ACCELERATOR_FACTOR: array[TRacingSkill] of TFixed = (57344, 59392, 61440, 63488, 65536);
  TURN_FACTOR: array[TRacingSkill] of TFixed = (63488, 64512, 65536, 66560, 67584);

{ TRacingAiDriver }

constructor TRacingAiDriver.Create(const ARace: IRacingRaceState; const ATrack: IRacingTrack;
  const AGeometry: IRacingGeometry);
begin
  inherited Create;
  if not Assigned(ARace) then
    raise EArgumentNilException.Create('ARace');
  if not Assigned(ATrack) then
    raise EArgumentNilException.Create('ATrack');
  if not Assigned(AGeometry) then
    raise EArgumentNilException.Create('AGeometry');
  FRace := ARace;
  FTrack := ATrack;
  FGeometry := AGeometry;
end;

procedure TRacingAiDriver.BuildCommand(var ACar: TRacingCarState; out ACommand: TRacingDrivingCommand);
var
  LActualSpeed: TFixed;
  LCurrentX, LCurrentY, LDestX, LDestY: Integer;
  LDeltaX, LDeltaY: TFixed;
  LDestAngle: TAngle;
  LDestSpeed: TFixed;
  LDifference, LMaxAcceleration: TFixed;
  LMaxTurn: TAngle;
  LDecelerationStep: TFixed;
  LPathId: Integer;
  LPath: PRacingPath;
begin
  FillChar(ACommand, SizeOf(ACommand), 0);
  if FRace.Status = TRacingStatus.Waiting then
    Exit;

  TRacingGearBox.AutomaticGearBox(ACar);

  // The current speed
  LDeltaX := ACar.X - ACar.OldX;
  LDeltaY := ACar.Y - ACar.OldY;
  LActualSpeed := TRacingMath.Distance(LDeltaX, LDeltaY);

  // The next point to go to
  LPathId := FTrack.GetPath(FTrack.GetNextPath(ACar.X, ACar.Y)).Id;
  if LPathId <> ACar.CurrentPath then
  begin
    ACar.PreviousPath := ACar.CurrentPath;
    ACar.CurrentPath := LPathId;
  end;

  LCurrentX := ACar.X;
  LCurrentY := ACar.Y;
  LPath := FTrack.GetPath(ACar.CurrentPath);
  LDestX := LPath.X;
  LDestY := LPath.Y;
  LDestSpeed := LPath.Speed * RACING_KMH_TO_FIXED;
  // On the point: the next one is the target
  if (LDestX = LCurrentX) and (LDestY = LCurrentY) then
  begin
    LPath := FTrack.GetPath(LPath.Next);
    LDestX := LPath.X;
    LDestY := LPath.Y;
  end;

  // Turns the car to the angle of the target
  LDestAngle := FGeometry.PointToAngle(LDestX, LDestY, LCurrentX, LCurrentY) - ACar.Angle;
  LMaxTurn := (RACING_CAR_DATA[ACar.CarInfo].TurnSpeed div TURN_FACTOR[FRace.Skill]) * FIXED_ONE;
  if LDestAngle < ANG180 - LMaxTurn then
    ACommand.Turn := -LMaxTurn
  else if LDestAngle > ANG180 + LMaxTurn then
    ACommand.Turn := LMaxTurn
  else
    ACommand.Turn := 0;

  // The speed
  ACommand.Accelerate := 0;
  ACommand.Decelerate := 0;
  ACommand.Brake := 0;
  if LActualSpeed > LDestSpeed then // Braking
  begin
    LDifference := LActualSpeed - LDestSpeed;
    LDecelerationStep := LDifference div (RACING_TICKS_PER_SECOND div 2);
    if LDecelerationStep < RACING_CAR_DATA[ACar.CarInfo].BaseDeceleration then
      ACommand.Brake := LDecelerationStep
    else if LDifference > RACING_CAR_DATA[ACar.CarInfo].BaseDeceleration then
      ACommand.Brake := RACING_CAR_DATA[ACar.CarInfo].BaseDeceleration
    else
      ACommand.Brake := LDifference;
  end
  else if LActualSpeed < LDestSpeed then // Accelerating
  begin
    LDifference := LDestSpeed - LActualSpeed;
    LMaxAcceleration := TFixedMath.Mul(RACING_CAR_DATA[ACar.CarInfo].BaseAcceleration,
      ACCELERATOR_FACTOR[FRace.Skill]);
    if LDifference > LMaxAcceleration then
      ACommand.Accelerate := LMaxAcceleration
    else
      ACommand.Accelerate := LDifference;
  end;
end;

end.
