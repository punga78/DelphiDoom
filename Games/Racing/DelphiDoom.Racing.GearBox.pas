{******************************************************************************}
{                                                                              }
{  DelphiDoom: racing library - the gears and the rpm of a car                 }
{  Copyright (C) 1995 by Noriaworks                                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of SH_SetGear, SH_AutoGearBox, SH_ManualGearBox, SH_CalcRPM and        }
{  SH_GearAccelerationFactor of speed_cars.pas                                 }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Racing.GearBox;

// Speeds are 16.16 fixed point: the products and the divisions wrap as in the old code
{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Racing.Types;

type
  /// <summary>
  ///   The gears of a car: the choice of the gear (automatic and manual), the change of gear
  ///   that takes a few tics, the push of the engine in each gear and the rpm. It has no state:
  ///   everything is in the state of the car
  /// </summary>
  TRacingGearBox = class
  public
    /// <summary>
    ///   The push of a gear (0..64) at a step of the speed (0..15, 16 is the top speed). The table
    ///   is read as the old code read it: as one block of rows, so the step 16 of a row is the step
    ///   0 of the next one; past the end of the table the push is 0 (the old code read what was
    ///   there in memory)
    /// </summary>
    class function Factor(AGear, AStep: Integer): Integer; static;
    /// <summary>Asks for a gear if no change is in progress (the old SH_SetGear)</summary>
    class procedure SetGear(var ACar: TRacingCarState; AGear: Integer); static;
    /// <summary>The automatic gearbox: goes up or down when the other gear pushes more (the old SH_AutoGearBox)</summary>
    class procedure AutomaticGearBox(var ACar: TRacingCarState); static;
    /// <summary>The manual gearbox, driven by the buttons of the player (the old SH_ManualGearBox)</summary>
    class procedure ManualGearBox(var ACar: TRacingCarState; AButtons: Integer); static;
    /// <summary>The rpm for the speed and the gear (the old SH_CalcRPM)</summary>
    class procedure CalculateRpm(var ACar: TRacingCarState); static;
    /// <summary>
    ///   How much of the acceleration of the car reaches the ground: 0 while the gear changes, the
    ///   whole in reverse, else the push of the gear for the speed (the old SH_GearAccelerationFactor)
    /// </summary>
    class function AccelerationFactor(const ACar: TRacingCarState): TFixed; static;
  end;

implementation

uses
  DelphiDoom.Racing.CarData, DelphiDoom.Racing.Math;

const
  // The rows are the gears -1 (reverse), 0 (neutral) and 1..6: the old GEAR_ACCEL_FACTORS
  FACTORS: array[0..(RACING_GEAR_COUNT + 2) * RACING_GEAR_FACTOR_COUNT - 1] of Byte = (
    64, 56, 32,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
    64, 64, 64, 32, 16,  1,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
    32, 48, 64, 64, 64, 32, 16,  1,  0,  0,  0,  0,  0,  0,  0,  0,
    16, 24, 32, 48, 64, 64, 64, 48, 32, 16,  2,  0,  0,  0,  0,  0,
    12, 16, 24, 32, 48, 64, 64, 64, 64, 48, 32, 16,  4,  0,  0,  0,
     8, 12, 16, 24, 32, 40, 48, 54, 64, 64, 64, 48, 32, 16,  8,  0,
     4,  6,  8, 12, 16, 24, 32, 40, 48, 56, 64, 64, 64, 48, 32, 16
  );

{ TRacingGearBox }

class function TRacingGearBox.Factor(AGear, AStep: Integer): Integer;
var
  LIndex: Integer;
begin
  LIndex := (AGear + 1) * RACING_GEAR_FACTOR_COUNT + AStep;
  if (LIndex < 0) or (LIndex > High(FACTORS)) then
    Result := 0
  else
    Result := FACTORS[LIndex];
end;

class procedure TRacingGearBox.SetGear(var ACar: TRacingCarState; AGear: Integer);
begin
  if AGear <> ACar.Gear then
    if ACar.NextGearTics = 0 then
    begin
      ACar.DestinationGear := AGear;
      ACar.GearTics := RACING_AUTO_GEAR_CHANGE_TICS;
      ACar.NextGearTics := RACING_AUTO_NEXT_GEAR_CHANGE_TICS;
    end;
end;

class procedure TRacingGearBox.AutomaticGearBox(var ACar: TRacingCarState);
var
  LStep: Integer;
  LBetterUp, LBetterDown: Boolean;
begin
  if ACar.EngineSpeed >= 0 then
    if ACar.NextGearTics = 0 then
    begin
      LStep := ACar.EngineSpeed div (RACING_CAR_DATA[ACar.CarInfo].MaxSpeed div RACING_GEAR_FACTOR_COUNT);

      LBetterUp := False;
      if ACar.Gear < RACING_GEAR_COUNT then
        LBetterUp := Factor(ACar.Gear, LStep) < Factor(ACar.Gear + 1, LStep);

      if LBetterUp then
      begin
        ACar.DestinationGear := ACar.Gear + 1;
        ACar.GearTics := RACING_AUTO_GEAR_CHANGE_TICS;
        ACar.NextGearTics := RACING_AUTO_NEXT_GEAR_CHANGE_TICS;
      end
      else
      begin
        LBetterDown := False;
        if ACar.Gear > 0 then
          LBetterDown := Factor(ACar.Gear, LStep) < Factor(ACar.Gear - 1, LStep);
        if LBetterDown then
        begin
          ACar.DestinationGear := ACar.Gear - 1;
          ACar.GearTics := RACING_AUTO_GEAR_CHANGE_TICS;
          ACar.NextGearTics := RACING_AUTO_NEXT_GEAR_CHANGE_TICS;
        end;
      end;
    end;
end;

class procedure TRacingGearBox.ManualGearBox(var ACar: TRacingCarState; AButtons: Integer);
var
  LStep: Integer;
begin
  if AButtons and RACING_BUTTON_GEAR_UP <> 0 then
  begin
    if ACar.Gear < RACING_GEAR_COUNT then
    begin
      ACar.DestinationGear := ACar.Gear + 1;
      ACar.GearTics := RACING_MANUAL_GEAR_CHANGE_TICS;
      ACar.NextGearTics := RACING_MANUAL_NEXT_GEAR_CHANGE_TICS;
    end;
  end
  else if AButtons and RACING_BUTTON_GEAR_DOWN <> 0 then
  begin
    if ACar.Gear > 1 then
    begin
      LStep := TRacingMath.Clamp(
        ACar.EngineSpeed div (RACING_CAR_DATA[ACar.CarInfo].MaxSpeed div RACING_GEAR_FACTOR_COUNT),
        0, RACING_GEAR_FACTOR_COUNT - 1);
      if Factor(ACar.Gear - 1, LStep) > 0 then
      begin
        ACar.DestinationGear := ACar.Gear - 1;
        ACar.GearTics := RACING_MANUAL_GEAR_CHANGE_TICS;
        ACar.NextGearTics := RACING_MANUAL_NEXT_GEAR_CHANGE_TICS;
      end;
    end;
  end;
end;

class procedure TRacingGearBox.CalculateRpm(var ACar: TRacingCarState);
var
  LStep, LIndex, LMaxGearSpeed, LNewRpm: Integer;
begin
  if (ACar.Gear = 0) or (ACar.GearTics > 0) then
  begin
    if ACar.Rpm > RACING_RPM_FADE then
      ACar.Rpm := ACar.Rpm - RACING_RPM_FADE
    else
      ACar.Rpm := 0;
    Exit;
  end;

  LStep := 0;
  for LIndex := 0 to RACING_GEAR_FACTOR_COUNT - 1 do
    if Factor(ACar.Gear, LIndex) <> 0 then
      LStep := LIndex
    else
      Break;

  LMaxGearSpeed := ((1 + LStep) * RACING_CAR_DATA[ACar.CarInfo].MaxSpeed) div RACING_GEAR_FACTOR_COUNT;
  if LMaxGearSpeed = 0 then
  begin
    if ACar.Rpm > RACING_RPM_FADE then
      ACar.Rpm := ACar.Rpm - RACING_RPM_FADE
    else
      ACar.Rpm := 0;
    Exit;
  end;

  LNewRpm := (Abs(ACar.EngineSpeed) div RACING_KMH_TO_FIXED) * RACING_MAX_RPM div
    (LMaxGearSpeed div RACING_KMH_TO_FIXED);
  if LNewRpm > RACING_MAX_RPM then
    LNewRpm := RACING_MAX_RPM;

  if ACar.Rpm > LNewRpm then
  begin
    ACar.Rpm := ACar.Rpm - RACING_RPM_FADE;
    if ACar.Rpm < LNewRpm then
      ACar.Rpm := LNewRpm;
  end
  else if ACar.Rpm < LNewRpm then
  begin
    ACar.Rpm := ACar.Rpm + RACING_RPM_FADE;
    if ACar.Rpm > LNewRpm then
      ACar.Rpm := LNewRpm;
  end;
end;

class function TRacingGearBox.AccelerationFactor(const ACar: TRacingCarState): TFixed;
var
  LStep: Integer;
begin
  if ACar.GearTics > 0 then
    Result := 0
  else if ACar.Gear < 0 then
    Result := FIXED_ONE
  else
  begin
    LStep := ACar.EngineSpeed div (RACING_CAR_DATA[ACar.CarInfo].MaxSpeed div RACING_GEAR_FACTOR_COUNT);
    Result := Factor(ACar.Gear, LStep) * RACING_GEAR_FACTOR_MULTIPLIER;
  end;
end;

end.
