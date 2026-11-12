{******************************************************************************}
{                                                                              }
{  DelphiDoom: parity library - the automatic pilot                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Parity.Pilot;

interface

uses
  DelphiDoom.Parity.Intf,
  DelphiDoom.Parity.Random,
  DelphiDoom.Parity.Types;

type
  /// <summary>
  ///   A player that moves without looking: it runs for some tics, curves, strafes, turns on the spot, backs off,
  ///   fires, presses the use button (every few tics, so doors and switches that it meets work) and changes
  ///   weapon, in segments of random length; when the position does not change it is stuck against a wall and
  ///   turns away. When the player is dead it presses use (the level starts again). The numbers come from a
  ///   generator of its own, so the same seed and the same positions always give the same commands. The turns
  ///   are multiples of 256, which a demo keeps exactly (it records the high byte of the angle)
  /// </summary>
  TParityPilot = class(TInterfacedObject, IParityPilot)
  strict private
    type
      TBehavior = (pbRun, pbCurveLeft, pbCurveRight, pbStrafe, pbTurnOnSpot, pbBackOff, pbStandAndFire);
  strict private
    FRandom: TParityRandom;
    FTics: Integer;
    FBehavior: TBehavior;
    FTicsLeft: Integer;
    FFire: Boolean;
    FUsing: Boolean;
    FSpeed: Integer;
    FDirection: Integer;
    FTurnSpeed: Integer;
    FEscapeLeft: Integer;
    FEscapeDirection: Integer;
    FLastX: Integer;
    FLastY: Integer;
    FStillTics: Integer;
    FHasLastPosition: Boolean;
    procedure ChooseSegment;
    procedure CheckStuck(const AView: TParityPilotView);
  public
    /// <summary>ATics: how many tics the pilot plays (IsFinished is true from that tic on)</summary>
    constructor Create(ASeed: Cardinal; ATics: Integer);
    destructor Destroy; override;
    function NextCommand(const AView: TParityPilotView): TParityPilotCommand;
    function IsFinished(ATic: Integer): Boolean;
  end;

implementation

const
  // fixed point 16.16: less than 4 units in 12 tics while running means that a wall is in the way
  STUCK_DISTANCE = 4 * 65536;
  STUCK_TICS = 12;
  ESCAPE_MIN_TICS = 8;
  ESCAPE_MAX_TICS = 26;
  USE_PERIOD = 6;
  TURN_UNIT = 256;
  MAX_TURN_STEPS = 5;

{ TParityPilot }

constructor TParityPilot.Create(ASeed: Cardinal; ATics: Integer);
begin
  inherited Create;
  FRandom := TParityRandom.Create(ASeed);
  FTics := ATics;
  FDirection := 1;
  FSpeed := 50;
  ChooseSegment;
end;

destructor TParityPilot.Destroy;
begin
  FRandom.Free;
  inherited Destroy;
end;

procedure TParityPilot.ChooseSegment;
var
  LChoice: Integer;
begin
  LChoice := FRandom.NextBelow(100);
  // runs are the most useful: they are what crosses the level
  if LChoice < 38 then
    FBehavior := pbRun
  else if LChoice < 52 then
    FBehavior := pbCurveLeft
  else if LChoice < 66 then
    FBehavior := pbCurveRight
  else if LChoice < 78 then
    FBehavior := pbStrafe
  else if LChoice < 88 then
    FBehavior := pbTurnOnSpot
  else if LChoice < 94 then
    FBehavior := pbBackOff
  else
    FBehavior := pbStandAndFire;
  FTicsLeft := FRandom.NextBetween(6, 40);
  FFire := FRandom.NextBelow(100) < 35;
  FUsing := FRandom.NextBelow(100) < 60;
  if FRandom.NextBelow(100) < 70 then
    FSpeed := 50
  else
    FSpeed := 25;
  if FRandom.NextBelow(2) = 0 then
    FDirection := 1
  else
    FDirection := -1;
  FTurnSpeed := FRandom.NextBetween(1, MAX_TURN_STEPS) * TURN_UNIT;
end;

procedure TParityPilot.CheckStuck(const AView: TParityPilotView);
var
  LDistance: Int64;
begin
  if not FHasLastPosition then
  begin
    FLastX := AView.X;
    FLastY := AView.Y;
    FHasLastPosition := True;
    Exit;
  end;
  Inc(FStillTics);
  if FStillTics >= STUCK_TICS then
  begin
    LDistance := Abs(Int64(AView.X) - FLastX) + Abs(Int64(AView.Y) - FLastY);
    if (LDistance < STUCK_DISTANCE) and (FBehavior in [pbRun, pbCurveLeft, pbCurveRight, pbStrafe]) then
    begin
      // 8..26 tics of full turn: from about 55 to 180 degrees
      FEscapeLeft := FRandom.NextBetween(ESCAPE_MIN_TICS, ESCAPE_MAX_TICS);
      if FRandom.NextBelow(2) = 0 then
        FEscapeDirection := 1
      else
        FEscapeDirection := -1;
    end;
    FLastX := AView.X;
    FLastY := AView.Y;
    FStillTics := 0;
  end;
end;

function TParityPilot.NextCommand(const AView: TParityPilotView): TParityPilotCommand;
begin
  Result := Default(TParityPilotCommand);
  if not AView.Alive then
  begin
    // use brings the player back to life; fire and walk meanwhile do no harm
    Result.Use := (AView.Tic mod USE_PERIOD) = 0;
    FHasLastPosition := False;
    FStillTics := 0;
    Exit;
  end;

  CheckStuck(AView);
  if FEscapeLeft > 0 then
  begin
    Dec(FEscapeLeft);
    Result.Turn := FEscapeDirection * MAX_TURN_STEPS * TURN_UNIT;
    Result.Use := (AView.Tic mod USE_PERIOD) = 0;
    Exit;
  end;

  if FTicsLeft <= 0 then
  begin
    ChooseSegment;
    // a new look at the weapons now and then
    if FRandom.NextBelow(100) < 12 then
      Result.Weapon := FRandom.NextBetween(1, 7);
  end;
  Dec(FTicsLeft);

  case FBehavior of
    pbRun:
      Result.Forward := FSpeed;
    pbCurveLeft:
      begin
        Result.Forward := FSpeed;
        Result.Turn := FTurnSpeed;
      end;
    pbCurveRight:
      begin
        Result.Forward := FSpeed;
        Result.Turn := -FTurnSpeed;
      end;
    pbStrafe:
      begin
        Result.Forward := 25;
        Result.Side := FDirection * 40;
      end;
    pbTurnOnSpot:
      Result.Turn := FDirection * FTurnSpeed;
    pbBackOff:
      begin
        Result.Forward := -25;
        Result.Side := FDirection * 24;
      end;
    pbStandAndFire:
      Result.Fire := True;
  end;
  if FFire then
    Result.Fire := True;
  if FUsing and ((AView.Tic mod USE_PERIOD) = 0) then
    Result.Use := True;
end;

function TParityPilot.IsFinished(ATic: Integer): Boolean;
begin
  Result := ATic >= FTics;
end;

end.
