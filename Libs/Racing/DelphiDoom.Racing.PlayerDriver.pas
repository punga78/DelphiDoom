{******************************************************************************}
{                                                                              }
{  DelphiDoom: racing library - the driver that a person controls              }
{  Copyright (C) 1995 by Noriaworks                                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of SH_BuildDrivingCmdPlayer and SH_StorePlayerLapTimes of              }
{  speed_cars.pas                                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Racing.PlayerDriver;

// Speeds, angles and forces are 16.16 fixed point and 32 bit integers that wrap as in the old code
{$Q-}
{$R-}
// The mixed signed and unsigned operations are the ones of the old code: the results are the same only with the same types
{$WARN COMBINING_SIGNED_UNSIGNED OFF}

interface

uses
  DelphiDoom.Racing.Types, DelphiDoom.Racing.Intf;

type
  /// <summary>
  ///   Turns what a person asks (steering, forward or back, gear buttons) into the command of
  ///   the car; at the end of the race the computer drives. It also tells the game when a lap is
  ///   completed, with the times of the laps
  /// </summary>
  TRacingPlayerDriver = class(TInterfacedObject, IRacingPlayerDriver)
  strict private
    FRace: IRacingRaceState;
    FTrack: IRacingTrack;
    FComputerDriver: IRacingDriver;
    FEvents: IRacingPlayerEvents;
    function StoreLapTimes(const ACar: TRacingCarState): TRacingScore;
  public
    constructor Create(const ARace: IRacingRaceState; const ATrack: IRacingTrack;
      const AComputerDriver: IRacingDriver; const AEvents: IRacingPlayerEvents);
    procedure BuildCommand(var ACar: TRacingCarState; var APlayer: TRacingPlayerState;
      const AInput: TRacingPlayerInput; out ACommand: TRacingDrivingCommand);
  end;

implementation

uses
  System.SysUtils, DelphiDoom.MathCore.Types, DelphiDoom.Racing.CarData, DelphiDoom.Racing.GearBox,
  DelphiDoom.Racing.Math;

const
  MAX_SPEED_TURN_DECREASE = 40;

{ TRacingPlayerDriver }

constructor TRacingPlayerDriver.Create(const ARace: IRacingRaceState; const ATrack: IRacingTrack;
  const AComputerDriver: IRacingDriver; const AEvents: IRacingPlayerEvents);
begin
  inherited Create;
  if not Assigned(ARace) then
    raise EArgumentNilException.Create('ARace');
  if not Assigned(ATrack) then
    raise EArgumentNilException.Create('ATrack');
  if not Assigned(AComputerDriver) then
    raise EArgumentNilException.Create('AComputerDriver');
  if not Assigned(AEvents) then
    raise EArgumentNilException.Create('AEvents');
  FRace := ARace;
  FTrack := ATrack;
  FComputerDriver := AComputerDriver;
  FEvents := AEvents;
end;

function TRacingPlayerDriver.StoreLapTimes(const ACar: TRacingCarState): TRacingScore;
var
  LIndex: Integer;
  LTimes: TRacingLapTimes;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Episode := FRace.Episode;
  Result.Map := FRace.Map;
  Result.CarInfo := ACar.CarInfo;
  Result.RacePosition := ACar.RacePosition;
  Result.NumLaps := FRace.NumLaps;
  FTrack.GetLapTimes(ACar, LTimes);
  Result.TotalTime := 0;
  for LIndex := 0 to Result.NumLaps - 1 do
  begin
    Result.LapTimes[LIndex] := LTimes[LIndex];
    Result.TotalTime := Result.TotalTime + LTimes[LIndex];
  end;
end;

procedure TRacingPlayerDriver.BuildCommand(var ACar: TRacingCarState; var APlayer: TRacingPlayerState;
  const AInput: TRacingPlayerInput; out ACommand: TRacingDrivingCommand);
var
  LTurnLimit: Integer;
  LSpeedTurnDecrease: TFixed;
  LPathId: Integer;
  LScore: TRacingScore;
begin
  FillChar(ACommand, SizeOf(ACommand), 0);
  if FRace.Status = TRacingStatus.Waiting then
    Exit;

  if TRacingMath.IsInRange(ACar.LapsCompleted, 1, FRace.NumLaps) then
    if not APlayer.LapRecordChecked[ACar.LapsCompleted - 1] then
    begin
      APlayer.LapRecordChecked[ACar.LapsCompleted - 1] := True;
      FEvents.LapCompleted(StoreLapTimes(ACar));
    end;

  // The race is over: the computer drives
  if ACar.LapsCompleted >= FRace.NumLaps then
  begin
    LScore := StoreLapTimes(ACar);
    FEvents.ScoreChanged(LScore);
    FComputerDriver.BuildCommand(ACar, ACommand);
    Exit;
  end;

  LPathId := FTrack.GetPath(FTrack.GetNextPath(ACar.X, ACar.Y)).Id;
  if LPathId <> ACar.CurrentPath then
  begin
    ACar.PreviousPath := ACar.CurrentPath;
    ACar.CurrentPath := LPathId;
  end;

  LSpeedTurnDecrease := TRacingMath.Minimum(
    ((ACar.EngineSpeed div RACING_KMH_TO_FIXED) div 8) * FIXED_ONE, MAX_SPEED_TURN_DECREASE * FIXED_ONE);

  ACommand.Turn := AInput.AngleTurn * FIXED_ONE;
  LTurnLimit := RACING_CAR_DATA[ACar.CarInfo].TurnSpeed - 150 * FIXED_ONE - LSpeedTurnDecrease;
  if LTurnLimit < 128 * FIXED_ONE then
    LTurnLimit := 128 * FIXED_ONE;
  if ACommand.Turn < -LTurnLimit then
    ACommand.Turn := -LTurnLimit
  else if ACommand.Turn > LTurnLimit then
    ACommand.Turn := LTurnLimit;

  if AInput.ForwardMove > 0 then
  begin
    // Gear select
    if ACar.Gear = -1 then
      TRacingGearBox.SetGear(ACar, 1)
    else
    begin
      if FRace.TransmissionType = RACING_TRANSMISSION_AUTOMATIC then
        TRacingGearBox.AutomaticGearBox(ACar)
      else
        TRacingGearBox.ManualGearBox(ACar, AInput.Buttons);
    end;

    ACommand.Brake := 0;
    ACommand.Decelerate := 0;
    ACommand.Accelerate := RACING_CAR_DATA[ACar.CarInfo].BaseAcceleration;
  end
  else if AInput.ForwardMove < 0 then
  begin
    if ACar.EngineSpeed <= 0 then
    begin
      // Reverse gear
      TRacingGearBox.SetGear(ACar, -1);

      ACommand.Brake := 0;
      ACommand.Decelerate := 0;
      ACommand.Accelerate := -RACING_CAR_DATA[ACar.CarInfo].BaseAcceleration div 6;
    end
    else
    begin
      // Gear select
      if FRace.TransmissionType = RACING_TRANSMISSION_AUTOMATIC then
        TRacingGearBox.AutomaticGearBox(ACar)
      else
        TRacingGearBox.ManualGearBox(ACar, AInput.Buttons);

      ACommand.Brake := RACING_CAR_DATA[ACar.CarInfo].BaseDeceleration div 4;
      ACommand.Decelerate := 0;
      ACommand.Accelerate := 0;
    end;
  end
  else
  begin
    if ACar.EngineSpeed > 0 then
    begin
      ACommand.Decelerate := RACING_CAR_DATA[ACar.CarInfo].BaseDeceleration div 32;
      ACommand.Brake := 0;
      ACommand.Accelerate := 0;
    end
    else
    begin
      ACommand.Decelerate := 0;
      ACommand.Brake := 0;
      ACommand.Accelerate := 0;
    end;
    if ACar.EngineSpeed = 0 then
      TRacingGearBox.SetGear(ACar, 0);
  end;
end;

end.
