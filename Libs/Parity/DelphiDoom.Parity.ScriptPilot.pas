{******************************************************************************}
{                                                                              }
{  DelphiDoom: parity library - the pilot that follows a script of commands    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Parity.ScriptPilot;

interface

uses
  DelphiDoom.Parity.Intf,
  DelphiDoom.Parity.Types;

type
  /// <summary>
  ///   A player that does what a script says (-autoscript), one step after the other: keys held for some tics,
  ///   or a point of the map to turn to and to reach, or a height to fly to, or the enemies in sight to fight
  ///   (hunt, heal, and goto with fight: turn to the nearest one, fire when it is in front, fly level with it,
  ///   move sideways). The steps that look at the player (goto, face, climb) end when the player is there; if
  ///   that does not happen within their timeout the script gives up and the pilot has finished, as it does
  ///   when the player dies or the steps are over; hunt and heal just end when their tics are over. The
  ///   steps save and load take no tic: they are asked with the command of the step that follows. It
  ///   has no random numbers: the same script and the same positions always give the same commands. The turns
  ///   are multiples of 256, which a demo keeps exactly
  /// </summary>
  TParityScriptPilot = class(TInterfacedObject, IParityPilot)
  public const
    /// <summary>The use key is pressed once every so many tics: a door needs the key to go up and down</summary>
    USE_PERIOD = 6;
    /// <summary>A goto pushes forward only when the point is less than this far from the nose (22.5 degrees)</summary>
    ALIGNED_ANGLE = 4096;
    /// <summary>How near a height is "there" (map units)</summary>
    HEIGHT_TOLERANCE = 8;
    /// <summary>A fight fires only when the enemy is less than this far from the nose (5.6 degrees)</summary>
    FIRE_ANGLE = 1024;
    /// <summary>A fight moves sideways, one way and then the other, to be a harder target</summary>
    FIGHT_STRAFE = 30;
    FIGHT_STRAFE_TICS = 16;
    /// <summary>A fight goes nearer to an enemy that is farther than FIGHT_FAR and backs off one nearer than FIGHT_NEAR</summary>
    FIGHT_FAR = 900;
    FIGHT_NEAR = 300;
    FIGHT_SPEED = 25;
    /// <summary>A hunt is over after so many tics in a row without an enemy near</summary>
    HUNT_QUIET_TICS = 20;
  strict private
    FSteps: TArray<TParityScriptStep>;
    FCurrent: Integer;
    FStepTics: Integer;
    FQuietTics: Integer;
    FEnemyRange: Integer;
    FFinished: Boolean;
    FWasAlive: Boolean;
    FAskSave: Boolean;
    FAskLoad: Boolean;
    FAskSlot: Integer;
    FReport: IParityLog;
    function StepCommand(const AView: TParityPilotView): TParityPilotCommand;
    class function TurnTo(const AView: TParityPilotView; AX, AY: Integer; out AOffAngle: Integer): Integer; static;
    class function HeightKeys(const AView: TParityPilotView; AZ: Integer;
      var ACommand: TParityPilotCommand): Boolean; static;
    function HoldCommand(const AStep: TParityScriptStep): TParityPilotCommand;
    function GotoCommand(const AStep: TParityScriptStep; const AView: TParityPilotView;
      out AReached: Boolean): TParityPilotCommand;
    function FightCommand(const AStep: TParityScriptStep; const AView: TParityPilotView;
      out ACommand: TParityPilotCommand): Boolean;
    procedure Note(const AStep: TParityScriptStep; const AView: TParityPilotView; const AWhat: string);
    procedure Finish(const AView: TParityPilotView; const AWhy: string);
    procedure Report(const ALine: string);
  public
    /// <summary>
    ///   AReport (may be nil): where the pilot writes a line when a step ends (tic and position of the player)
    ///   or gives up, when the player dies and when the script is over
    /// </summary>
    constructor Create(const ASteps: TArray<TParityScriptStep>; const AReport: IParityLog);
    function NextCommand(const AView: TParityPilotView): TParityPilotCommand;
    /// <summary>True from the tic after the last step, after a step that gave up or after the death of the player</summary>
    function IsFinished(ATic: Integer): Boolean;
    /// <summary>The largest range of the steps that fight; 0 for a script without them</summary>
    function EnemyRange: Integer;
  end;

implementation

uses
  System.Math,
  System.SysUtils,
  DelphiDoom.Parity.ScriptParser;

const
  FRACUNIT = 65536;
  STEP_NAMES: array[TParityScriptStepKind] of string = ('hold', 'goto', 'face', 'climb', 'hunt',
    'heal', 'save', 'load');

{ TParityScriptPilot }

constructor TParityScriptPilot.Create(const ASteps: TArray<TParityScriptStep>; const AReport: IParityLog);
var
  LStep: TParityScriptStep;
begin
  inherited Create;
  FSteps := Copy(ASteps);
  FReport := AReport;
  for LStep in FSteps do
    if LStep.Fight and (LStep.EnemyRange > FEnemyRange) then
      FEnemyRange := LStep.EnemyRange;
end;

function TParityScriptPilot.EnemyRange: Integer;
begin
  Result := FEnemyRange;
end;

function TParityScriptPilot.FightCommand(const AStep: TParityScriptStep; const AView: TParityPilotView;
  out ACommand: TParityPilotCommand): Boolean;
var
  LDeltaX: Int64;
  LDeltaY: Int64;
  LOffAngle: Integer;
begin
  ACommand := Default(TParityPilotCommand);
  if not (AStep.Fight and AView.HasEnemy) then
    Exit(False);
  LDeltaX := (Int64(AView.EnemyX) - AView.X) div FRACUNIT;
  LDeltaY := (Int64(AView.EnemyY) - AView.Y) div FRACUNIT;
  if LDeltaX * LDeltaX + LDeltaY * LDeltaY > Int64(AStep.EnemyRange) * AStep.EnemyRange then
    Exit(False);
  ACommand.Turn := TurnTo(AView, AView.EnemyX div FRACUNIT, AView.EnemyY div FRACUNIT, LOffAngle);
  ACommand.Fire := Abs(LOffAngle) <= FIRE_ANGLE;
  // near enough for the aim of the game to help, not so near that the enemy is touched
  if Abs(LOffAngle) <= ALIGNED_ANGLE then
  begin
    if LDeltaX * LDeltaX + LDeltaY * LDeltaY > FIGHT_FAR * FIGHT_FAR then
      ACommand.Forward := FIGHT_SPEED
    else if LDeltaX * LDeltaX + LDeltaY * LDeltaY < FIGHT_NEAR * FIGHT_NEAR then
      ACommand.Forward := -FIGHT_SPEED;
  end;
  if ((FStepTics div FIGHT_STRAFE_TICS) and 1) = 0 then
    ACommand.Side := FIGHT_STRAFE
  else
    ACommand.Side := -FIGHT_STRAFE;
  // level with the enemy: a shot that flies straight hits it
  HeightKeys(AView, AView.EnemyZ div FRACUNIT, ACommand);
  Result := True;
end;

procedure TParityScriptPilot.Report(const ALine: string);
begin
  if not Assigned(FReport) then
    Exit;
  FReport.WriteLine(ALine);
  // a game that is closed from outside must leave what the script did so far
  FReport.Flush;
end;

class function TParityScriptPilot.TurnTo(const AView: TParityPilotView; AX, AY: Integer;
  out AOffAngle: Integer): Integer;
var
  LDeltaX: Double;
  LDeltaY: Double;
  LWanted: Integer;
  LSteps: Integer;
begin
  LDeltaX := AX - AView.X / FRACUNIT;
  LDeltaY := AY - AView.Y / FRACUNIT;
  LWanted := Round(ArcTan2(LDeltaY, LDeltaX) * 32768 / Pi) and $FFFF;
  // the difference of two angles of 16 bits, with its sign: left is positive
  AOffAngle := SmallInt((LWanted - Integer(AView.Angle shr 16)) and $FFFF);
  LSteps := Round(AOffAngle / TParityScriptParser.TURN_UNIT);
  LSteps := EnsureRange(LSteps, -TParityScriptParser.MAX_TURN_STEPS, TParityScriptParser.MAX_TURN_STEPS);
  Result := LSteps * TParityScriptParser.TURN_UNIT;
end;

class function TParityScriptPilot.HeightKeys(const AView: TParityPilotView; AZ: Integer;
  var ACommand: TParityPilotCommand): Boolean;
var
  LDelta: Int64;
begin
  LDelta := Int64(AZ) * FRACUNIT - AView.Z;
  ACommand.Jump := LDelta > HEIGHT_TOLERANCE * FRACUNIT;
  ACommand.Crouch := LDelta < -HEIGHT_TOLERANCE * FRACUNIT;
  Result := not (ACommand.Jump or ACommand.Crouch);
end;

function TParityScriptPilot.HoldCommand(const AStep: TParityScriptStep): TParityPilotCommand;
begin
  Result := AStep.Command;
  // a key that stays down is one press for the game: use is pressed again and again, the weapon is asked once
  Result.Use := AStep.Command.Use and ((FStepTics mod USE_PERIOD) = 0);
  if FStepTics > 0 then
  begin
    Result.Weapon := 0;
    // one bomb for a step: the game fires one for every press
    Result.Bomb := False;
  end;
end;

function TParityScriptPilot.GotoCommand(const AStep: TParityScriptStep; const AView: TParityPilotView;
  out AReached: Boolean): TParityPilotCommand;
var
  LDeltaX: Int64;
  LDeltaY: Int64;
  LOffAngle: Integer;
begin
  Result := Default(TParityPilotCommand);
  LDeltaX := Int64(AStep.X) - AView.X div FRACUNIT;
  LDeltaY := Int64(AStep.Y) - AView.Y div FRACUNIT;
  AReached := LDeltaX * LDeltaX + LDeltaY * LDeltaY <= Int64(AStep.Radius) * AStep.Radius;
  if AReached then
    Exit;
  // an enemy near comes before the way
  if FightCommand(AStep, AView, Result) then
    Exit;
  Result.Turn := TurnTo(AView, AStep.X, AStep.Y, LOffAngle);
  // off the line the craft only turns: what it had of speed fades and it does not circle around the point
  if Abs(LOffAngle) <= ALIGNED_ANGLE then
    Result.Forward := AStep.Command.Forward;
  Result.Afterburner := AStep.Command.Afterburner;
  Result.Fire := AStep.Command.Fire;
  Result.Use := AStep.Command.Use and ((FStepTics mod USE_PERIOD) = 0);
  if AStep.HasZ then
    HeightKeys(AView, AStep.Z, Result);
end;

procedure TParityScriptPilot.Note(const AStep: TParityScriptStep; const AView: TParityPilotView;
  const AWhat: string);
begin
  Report(Format('line %d %s: %s at tic %d after %d tics, player at %d %d %d',
    [AStep.Line, STEP_NAMES[AStep.Kind], AWhat, AView.Tic, FStepTics, AView.X div FRACUNIT, AView.Y div FRACUNIT,
    AView.Z div FRACUNIT]));
end;

procedure TParityScriptPilot.Finish(const AView: TParityPilotView; const AWhy: string);
begin
  FFinished := True;
  Report(Format('%s at tic %d', [AWhy, AView.Tic]));
end;

function TParityScriptPilot.NextCommand(const AView: TParityPilotView): TParityPilotCommand;
begin
  Result := StepCommand(AView);
  if FAskSave or FAskLoad then
  begin
    Result.Save := FAskSave;
    Result.Load := FAskLoad;
    Result.Slot := FAskSlot;
    FAskSave := False;
    FAskLoad := False;
  end;
end;

function TParityScriptPilot.StepCommand(const AView: TParityPilotView): TParityPilotCommand;
var
  LStep: TParityScriptStep;
  LDone: Boolean;
  LOffAngle: Integer;
begin
  Result := Default(TParityPilotCommand);
  if FFinished then
    Exit;
  if not AView.Alive then
  begin
    // before the level there is no player yet; later it is a death, and the script was not written for it
    if FWasAlive then
    begin
      if FCurrent <= High(FSteps) then
        Note(FSteps[FCurrent], AView, 'THE PLAYER DIED');
      Finish(AView, 'script stopped');
    end;
    Exit;
  end;
  FWasAlive := True;

  while FCurrent <= High(FSteps) do
  begin
    LStep := FSteps[FCurrent];
    Result := Default(TParityPilotCommand);
    case LStep.Kind of
      skHold:
        begin
          LDone := FStepTics >= LStep.Tics;
          if not LDone then
            Result := HoldCommand(LStep);
        end;
      skGoto:
        Result := GotoCommand(LStep, AView, LDone);
      skFace:
        begin
          Result.Turn := TurnTo(AView, LStep.X, LStep.Y, LOffAngle);
          Result.Fire := LStep.Command.Fire;
          LDone := Result.Turn = 0;
        end;
      skHunt:
        begin
          if FightCommand(LStep, AView, Result) then
            FQuietTics := 0
          else
            Inc(FQuietTics);
          LDone := (FStepTics >= LStep.Tics) or (FQuietTics >= HUNT_QUIET_TICS);
          if LDone then
            Result := Default(TParityPilotCommand);
        end;
      skHeal:
        begin
          LDone := (FStepTics >= LStep.Tics) or (AView.Health >= LStep.Health);
          if not LDone then
            FightCommand(LStep, AView, Result);
        end;
      skSave, skLoad:
        begin
          // The step takes no tic of its own: what it asks goes with the command of the step after it
          // (the game saves or loads between two tics), so a script with a "save" flies as the same
          // script without it
          FAskSave := FAskSave or LStep.Command.Save;
          FAskLoad := FAskLoad or LStep.Command.Load;
          FAskSlot := LStep.Command.Slot;
          LDone := True;
        end;
    else
      LDone := HeightKeys(AView, LStep.Z, Result);
    end;

    if LDone then
    begin
      Note(LStep, AView, 'done');
      Inc(FCurrent);
      FStepTics := 0;
      FQuietTics := 0;
      Continue;
    end;
    if not (LStep.Kind in [skHold, skHunt, skHeal, skSave, skLoad]) and (FStepTics >= LStep.Tics) then
    begin
      Note(LStep, AView, 'GAVE UP');
      Finish(AView, 'script stopped');
      Exit(Default(TParityPilotCommand));
    end;
    Inc(FStepTics);
    Exit;
  end;

  Finish(AView, 'script complete');
  Result := Default(TParityPilotCommand);
end;

function TParityScriptPilot.IsFinished(ATic: Integer): Boolean;
begin
  Result := FFinished;
end;

end.
