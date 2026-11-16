{******************************************************************************}
{                                                                              }
{  DelphiDoom: racing library - the motion of a car                            }
{  Copyright (C) 1995 by Noriaworks                                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of SH_ExecuteDrivingCmd of speed_cars.pas                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Racing.Physics;

// Speeds, angles and forces are 16.16 fixed point and 32 bit integers that wrap as in the old
// code; the operations keep the types of the old ones (angles unsigned, some products Int64)
{$Q-}
{$R-}
// The mixed signed and unsigned operations are the ones of the old code: the results are the same only with the same types
{$WARN COMBINING_SIGNED_UNSIGNED OFF}

interface

uses
  DelphiDoom.Racing.Types, DelphiDoom.Racing.Intf;

type
  /// <summary>
  ///   The physics of a car in a tic: gears, push of the engine on the ground that the wheels
  ///   find, steering, drift and the momentum with which the game then moves the object. The
  ///   speed of the car is the distance travelled since the last tic
  /// </summary>
  /// <remarks>
  ///   The distance travelled by the tires is the one that the old code summed with the
  ///   precision of the floating point unit (Extended in Win32): it is a Double in the state of
  ///   the car and it only moves the wheels of the model, but it is the one value of the cars that
  ///   is not an integer, so a Win64 build can differ in the last bits of it
  /// </remarks>
  TRacingPhysics = class(TInterfacedObject, IRacingPhysics)
  strict private
    FRace: IRacingRaceState;
    FGround: IRacingGround;
    FGeometry: IRacingGeometry;
    FParticles: IRacingParticles;
    FSounds: IRacingCarSounds;
    FTrack: IRacingTrack;
  public
    constructor Create(const ARace: IRacingRaceState; const AGround: IRacingGround;
      const AGeometry: IRacingGeometry; const AParticles: IRacingParticles;
      const ASounds: IRacingCarSounds; const ATrack: IRacingTrack);
    procedure Execute(var ACar: TRacingCarState; const ACommand: TRacingDrivingCommand);
  end;

implementation

uses
  System.SysUtils, DelphiDoom.MathCore.Types, DelphiDoom.MathCore.FixedMath,
  DelphiDoom.MathCore.Trigonometry, DelphiDoom.Racing.CarData, DelphiDoom.Racing.Math,
  DelphiDoom.Racing.GearBox, DelphiDoom.Racing.Ground;

const
  TIRE_ANGLE_MAX = 20;
  MAX_SOUND_DISTANCE = 192 * FIXED_ONE;

{ TRacingPhysics }

constructor TRacingPhysics.Create(const ARace: IRacingRaceState; const AGround: IRacingGround;
  const AGeometry: IRacingGeometry; const AParticles: IRacingParticles;
  const ASounds: IRacingCarSounds; const ATrack: IRacingTrack);
begin
  inherited Create;
  if not Assigned(ARace) then
    raise EArgumentNilException.Create('ARace');
  if not Assigned(AGround) then
    raise EArgumentNilException.Create('AGround');
  if not Assigned(AGeometry) then
    raise EArgumentNilException.Create('AGeometry');
  if not Assigned(AParticles) then
    raise EArgumentNilException.Create('AParticles');
  if not Assigned(ASounds) then
    raise EArgumentNilException.Create('ASounds');
  if not Assigned(ATrack) then
    raise EArgumentNilException.Create('ATrack');
  FRace := ARace;
  FGround := AGround;
  FGeometry := AGeometry;
  FParticles := AParticles;
  FSounds := ASounds;
  FTrack := ATrack;
end;

procedure TRacingPhysics.Execute(var ACar: TRacingCarState; const ACommand: TRacingDrivingCommand);
var
  LEngineSpeed: TFixed;
  LActualSpeed: TFixed;
  LDeltaX, LDeltaY: TFixed;
  LAngle: TAngle;
  LTurn64: Int64;
  LSlip: Integer;
  LDelta: TFixed;
  LForce: TFixed;
  LDriftAngle: Int64;
begin
  if FRace.Status = TRacingStatus.Waiting then
    Exit;

  if ACar.GearTics > 0 then
  begin
    Dec(ACar.GearTics);
    if ACar.GearTics = 0 then
      ACar.Gear := ACar.DestinationGear;
  end
  else if ACar.NextGearTics > 0 then
    Dec(ACar.NextGearTics);

  // The actual speed is the distance from where the car was
  LDeltaX := ACar.X - ACar.OldX;
  LDeltaY := ACar.Y - ACar.OldY;
  LActualSpeed := TFixedMath.Sqrt(TFixedMath.Mul(LDeltaX, LDeltaX) + TFixedMath.Mul(LDeltaY, LDeltaY));

  LEngineSpeed := ACar.EngineSpeed;

  if ACommand.Accelerate = 0 then
    if LEngineSpeed > LActualSpeed then
      LEngineSpeed := LActualSpeed;

  FParticles.Check(ACar, LActualSpeed, LEngineSpeed);

  LSlip := FGround.SlipperFactorAt(ACar.X, ACar.Y);

  LForce := TFixedMath.Mul(ACommand.Accelerate, TRacingGearBox.AccelerationFactor(ACar)) -
    ACommand.Brake - ACommand.Decelerate;
  if ACommand.Accelerate < 0 then
    LEngineSpeed := TRacingMath.Clamp(
      LEngineSpeed + TRacingGround.SlipCalculation(LForce, LSlip),
      RACING_CAR_DATA[ACar.CarInfo].MaxReverseSpeed, RACING_CAR_DATA[ACar.CarInfo].MaxSpeed)
  else
    LEngineSpeed := TRacingMath.Clamp(
      LEngineSpeed + TRacingGround.SlipCalculation(LForce, LSlip),
      0, RACING_CAR_DATA[ACar.CarInfo].MaxSpeed);
  // The asphalt is the ground that holds best: on a worse one the engine loses some of its speed
  if LSlip < 224 then
    LEngineSpeed := (7 * LEngineSpeed + LEngineSpeed * LSlip div 255) div 8;

  if Abs(LEngineSpeed) > 0 then
  begin
    if LActualSpeed < Abs(LEngineSpeed) then
    begin
      LTurn64 := ACommand.Turn;
      LTurn64 := LTurn64 * LActualSpeed;
      LTurn64 := LTurn64 div Abs(LEngineSpeed);
      ACar.Angle := ACar.Angle + TRacingMath.Sign(LEngineSpeed) * (LTurn64 + ACommand.Turn) div 2;
    end
    else
      ACar.Angle := ACar.Angle + TRacingMath.Sign(LEngineSpeed) * ACommand.Turn;
  end;

  if ACommand.Turn <> 0 then
    ACar.TireAngle := ACar.TireAngle + ACommand.Turn div 2
  else if LActualSpeed > 0 then
  begin
    if LActualSpeed > RACING_CAR_DATA[ACar.CarInfo].MaxSpeed div 2 then
      LDelta := 2 * ANG1
    else
      LDelta := ANG1;
    if ACar.TireAngle < 0 then
      ACar.TireAngle := TRacingMath.Clamp(ACar.TireAngle + LDelta, -ANG1 * TIRE_ANGLE_MAX, 0)
    else if ACar.TireAngle > 0 then
      ACar.TireAngle := TRacingMath.Clamp(ACar.TireAngle - LDelta, 0, ANG1 * TIRE_ANGLE_MAX);
  end;
  ACar.TireAngle := TRacingMath.Clamp(ACar.TireAngle, -ANG1 * TIRE_ANGLE_MAX, ANG1 * TIRE_ANGLE_MAX);

  // The drift fades and follows the tires
  if ACar.DriftAngle <> 0 then
  begin
    LDriftAngle := ACar.DriftAngle;
    LDriftAngle := LDriftAngle * 15 div 16;
    ACar.DriftAngle := LDriftAngle;
  end;

  if ACar.TireAngle <> 0 then
    if LActualSpeed > 10 * RACING_KMH_TO_FIXED then
    begin
      LDriftAngle := ACar.TireAngle;
      LDriftAngle := LDriftAngle * (LActualSpeed div RACING_KMH_TO_FIXED) div
        (RACING_CAR_DATA[ACar.CarInfo].MaxSpeed div RACING_KMH_TO_FIXED);
      ACar.DriftAngle := ACar.DriftAngle + LDriftAngle div 16;
      if ACar.DriftAngle > ANG1 * (RACING_CAR_DATA[ACar.CarInfo].MaxDrift * LActualSpeed div
        RACING_CAR_DATA[ACar.CarInfo].MaxSpeed) then
        ACar.DriftAngle := ANG1 * (RACING_CAR_DATA[ACar.CarInfo].MaxDrift * LActualSpeed div
          RACING_CAR_DATA[ACar.CarInfo].MaxSpeed)
      else if ACar.DriftAngle < -ANG1 * (RACING_CAR_DATA[ACar.CarInfo].MaxDrift * LActualSpeed div
        RACING_CAR_DATA[ACar.CarInfo].MaxSpeed) then
        ACar.DriftAngle := -ANG1 * (RACING_CAR_DATA[ACar.CarInfo].MaxDrift * LActualSpeed div
          RACING_CAR_DATA[ACar.CarInfo].MaxSpeed);
    end;

  // The momentum that the game applies to the object
  LAngle := ACar.Angle shr ANGLETOFINESHIFT;
  if LActualSpeed < LEngineSpeed then
  begin
    ACar.MomentumX := LDeltaX div 2 + TFixedMath.Mul(LEngineSpeed, TTrigonometry.FineCosine(LAngle)) div 2;
    ACar.MomentumY := LDeltaY div 2 + TFixedMath.Mul(LEngineSpeed, TTrigonometry.FineSine(LAngle)) div 2;
  end
  else
  begin
    ACar.MomentumX := TFixedMath.Mul(LEngineSpeed, TTrigonometry.FineCosine(LAngle));
    ACar.MomentumY := TFixedMath.Mul(LEngineSpeed, TTrigonometry.FineSine(LAngle));
  end;

  ACar.EngineSpeed := LEngineSpeed;

  if RACING_CAR_DATA[ACar.CarInfo].CarType = TRacingCarType.Formula then // 2WD
  begin
    ACar.TireDistance[0] := ACar.TireDistance[0] + TRacingMath.Sign(LEngineSpeed) * LActualSpeed / FIXED_ONE;
    ACar.TireDistance[1] := ACar.TireDistance[1] + TRacingMath.Sign(LEngineSpeed) * LActualSpeed / FIXED_ONE;
  end
  else // 4WD
  begin
    ACar.TireDistance[0] := ACar.TireDistance[0] + LEngineSpeed / FIXED_ONE;
    ACar.TireDistance[1] := ACar.TireDistance[1] + LEngineSpeed / FIXED_ONE;
  end;
  ACar.TireDistance[2] := ACar.TireDistance[2] + LEngineSpeed / FIXED_ONE;
  ACar.TireDistance[3] := ACar.TireDistance[3] + LEngineSpeed / FIXED_ONE;

  ACar.CarTurn := ACommand.Turn;
  ACar.CarAccelerate := ACommand.Accelerate;
  ACar.CarDecelerate := ACommand.Decelerate;
  ACar.CarBrake := ACommand.Brake;

  TRacingGearBox.CalculateRpm(ACar);

  if FGeometry.ApproximateDistanceFromView(ACar.X, ACar.Y) < MAX_SOUND_DISTANCE then
  begin
    if not ACar.IsPlayer then
      FSounds.EngineSound(ACar, ACar.SoundCountdown);
    FSounds.BrakeSound(ACar);
  end;

  FTrack.Notify(ACar);
end;

end.
