{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom strategy library - the UFOs while the time goes on         }
{  (the UFO part of GeoscapeState::time5Seconds and time30Minutes)             }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomStrategy.UfoTracker;

interface

uses
  System.SysUtils, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.Random, DelphiDoom.XcomMod.UfoTrajectory,
  DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.Craft, DelphiDoom.XcomSave.Ufo,
  DelphiDoom.XcomSave.MissionSite, DelphiDoom.XcomSave.AlienMission, DelphiDoom.XcomStrategy.Events.Intf,
  DelphiDoom.XcomStrategy.Geography, DelphiDoom.XcomStrategy.BaseRadar, DelphiDoom.XcomStrategy.UfoWaypointHandler;

type
  /// <summary>
  ///   Moves the UFOs, lands them and makes them lift off, expires the crashed ones, takes the destroyed ones
  ///   off the game, gives the points of their flight and decides which of them the radars see
  /// </summary>
  TXcomUfoTracker = class
  strict private
    FGame: TXcomSavedGame;
    FRandom: IXcomRandom;
    FHandler: TXcomUfoWaypointHandler;
    FRadar: TXcomBaseRadar;
    FEvents: IXcomGeoscapeEvents;
    procedure DetectUnseen(const AUfo: TXcomUfo);
    procedure CheckSeen(const AUfo: TXcomUfo);
  public
    constructor Create(const AGame: TXcomSavedGame; const ARandom: IXcomRandom;
      const AHandler: TXcomUfoWaypointHandler; const ARadar: TXcomBaseRadar; const AEvents: IXcomGeoscapeEvents);
    /// <summary>
    ///   The UFO loop of time5Seconds: false when the rest of the step must not run (a UFO that was destroyed on
    ///   arriving, or that reached a base: the battle is not ported, the screen is told)
    /// </summary>
    function Move: Boolean;
    /// <summary>The UFOs that were destroyed are taken off the game (and freed)</summary>
    procedure RemoveDestroyed;
    /// <summary>expireCrashedUfo: a crashed UFO loses half an hour, then it is destroyed</summary>
    procedure ExpireCrashed;
    /// <summary>
    ///   The UFO loop of time30Minutes: the points of a UFO that flies or is on the ground go to the region and
    ///   the country below it, then the radars of the bases and of the crafts that are out see it or lose it
    /// </summary>
    procedure ScoreAndDetect;
  end;

implementation

{ TXcomUfoTracker }

constructor TXcomUfoTracker.Create(const AGame: TXcomSavedGame; const ARandom: IXcomRandom;
  const AHandler: TXcomUfoWaypointHandler; const ARadar: TXcomBaseRadar; const AEvents: IXcomGeoscapeEvents);
begin
  inherited Create;
  FGame := AGame;
  FRandom := ARandom;
  FHandler := AHandler;
  FRadar := ARadar;
  FEvents := AEvents;
end;

function TXcomUfoTracker.Move: Boolean;
var
  LIndex, LSites: Integer;
  LUfo: TXcomUfo;
  LMission: TXcomAlienMission;
  LDetected: Boolean;
  LSite: TXcomMissionSite;
  LBase: TXcomBase;
begin
  Result := True;
  for LIndex := 0 to FGame.Ufos.Count - 1 do
  begin
    LUfo := FGame.Ufos[LIndex];
    case LUfo.Status of
      TXcomUfo.STATUS_FLYING:
        begin
          LUfo.Think;
          if LUfo.ReachedDestination then
          begin
            LSites := FGame.MissionSites.Count;
            LMission := LUfo.Mission;
            LDetected := LUfo.Detected;
            FHandler.UfoReachedWaypoint(LMission, LUfo, FGame);
            if (LDetected <> LUfo.Detected) and (LUfo.Followers.Count > 0) then
              if not ((LUfo.Trajectory.Id = TXcomUfoTrajectory.RETALIATION_ASSAULT_RUN) and
                (LUfo.Status = TXcomUfo.STATUS_LANDED)) then
                FEvents.UfoLost(LUfo);
            if LSites < FGame.MissionSites.Count then
            begin
              LSite := FGame.MissionSites.Last;
              LSite.Detected := True;
              FEvents.MissionDetected(LSite);
            end;
            if LUfo.Status = TXcomUfo.STATUS_DESTROYED then
              Exit(False);
            if LUfo.Destination is TXcomBase then
            begin
              // the UFO attacks a base: the next wave waits and, whatever happens in the defense (the battle is the
              // screen's, not ported), the UFO has finished its duty (handleBaseDefense)
              LMission.SetWaveCountdown(Cardinal(30 * (FRandom.Generate(0, 400) + 48)));
              LBase := TXcomBase(LUfo.Destination);
              LUfo.SetDestination(nil);
              FEvents.BaseAttacked(LBase, LUfo);
              LUfo.Status := TXcomUfo.STATUS_DESTROYED;
              Exit(False);
            end;
          end;
        end;
      TXcomUfo.STATUS_LANDED:
        begin
          LUfo.Think;
          if LUfo.SecondsRemaining = 0 then
          begin
            LMission := LUfo.Mission;
            LDetected := LUfo.Detected;
            FHandler.UfoLifting(LMission, LUfo, FGame);
            if (LDetected <> LUfo.Detected) and (LUfo.Followers.Count > 0) then
              FEvents.UfoLost(LUfo);
          end;
        end;
      TXcomUfo.STATUS_CRASHED:
        begin
          LUfo.Think;
          if LUfo.SecondsRemaining = 0 then
          begin
            LUfo.Detected := False;
            LUfo.Status := TXcomUfo.STATUS_DESTROYED;
          end;
        end;
    end;
  end;
end;

procedure TXcomUfoTracker.RemoveDestroyed;
var
  LIndex: Integer;
begin
  LIndex := 0;
  while LIndex < FGame.Ufos.Count do
    if FGame.Ufos[LIndex].Status = TXcomUfo.STATUS_DESTROYED then
      FGame.Ufos.Delete(LIndex)
    else
      Inc(LIndex);
end;

procedure TXcomUfoTracker.ExpireCrashed;
var
  LUfo: TXcomUfo;
begin
  for LUfo in FGame.Ufos do
    if LUfo.Status = TXcomUfo.STATUS_CRASHED then
    begin
      if LUfo.SecondsRemaining >= 30 * 60 then
        LUfo.SecondsRemaining := LUfo.SecondsRemaining - 30 * 60
      else
        LUfo.Status := TXcomUfo.STATUS_DESTROYED;
    end;
end;

procedure TXcomUfoTracker.DetectUnseen(const AUfo: TXcomUfo);
var
  LDetected, LHyperDetected: Boolean;
  LBase: TXcomBase;
  LCraft: TXcomCraft;
  LBaseIndex: Integer;
begin
  LDetected := False;
  LHyperDetected := False;
  LBaseIndex := 0;
  while not LHyperDetected and (LBaseIndex < FGame.Bases.Count) do
  begin
    LBase := FGame.Bases[LBaseIndex];
    case FRadar.Detect(LBase, AUfo) of
      2:
        begin
          // hyper-wave decoder
          AUfo.HyperDetected := True;
          LHyperDetected := True;
          LDetected := True;
        end;
      1:
        // conventional radar
        LDetected := True;
    end;
    for LCraft in LBase.Crafts do
    begin
      if LDetected then
        Break;
      if (LCraft.Status = 'STR_OUT') and LCraft.Detect(AUfo, AUfo.Visibility, FRandom) then
      begin
        LDetected := True;
        Break;
      end;
    end;
    Inc(LBaseIndex);
  end;
  if LDetected then
  begin
    AUfo.Detected := True;
    FEvents.UfoDetected(AUfo, AUfo.HyperDetected);
  end;
end;

procedure TXcomUfoTracker.CheckSeen(const AUfo: TXcomUfo);
var
  LDetected, LHyperDetected: Boolean;
  LBase: TXcomBase;
  LCraft: TXcomCraft;
  LBaseIndex: Integer;
begin
  LDetected := False;
  LHyperDetected := False;
  LBaseIndex := 0;
  while not LHyperDetected and (LBaseIndex < FGame.Bases.Count) do
  begin
    LBase := FGame.Bases[LBaseIndex];
    case FRadar.InsideRadarRange(LBase, AUfo) of
      2:
        begin
          LDetected := True;
          LHyperDetected := True;
          AUfo.HyperDetected := True;
        end;
      1:
        begin
          LDetected := True;
          LHyperDetected := AUfo.HyperDetected;
        end;
    end;
    for LCraft in LBase.Crafts do
    begin
      if LDetected then
        Break;
      if (LCraft.Status = 'STR_OUT') and LCraft.InsideRadarRange(AUfo) then
      begin
        LDetected := True;
        LHyperDetected := AUfo.HyperDetected;
        Break;
      end;
    end;
    Inc(LBaseIndex);
  end;
  if not LDetected then
  begin
    AUfo.Detected := False;
    AUfo.HyperDetected := False;
    if AUfo.Followers.Count > 0 then
      FEvents.UfoLost(AUfo);
  end;
end;

procedure TXcomUfoTracker.ScoreAndDetect;
var
  LUfo: TXcomUfo;
  LPoints: Integer;
begin
  for LUfo in FGame.Ufos do
  begin
    // one point per UFO in flight per half hour
    LPoints := LUfo.Rules.MissionScore;
    case LUfo.Status of
      TXcomUfo.STATUS_LANDED, TXcomUfo.STATUS_FLYING:
        begin
          if LUfo.Status = TXcomUfo.STATUS_LANDED then
            LPoints := LPoints * 2;
          TXcomGeography.AddAlienActivity(FGame, LUfo.Longitude, LUfo.Latitude, LPoints);
          if not LUfo.Detected then
            DetectUnseen(LUfo)
          else
            CheckSeen(LUfo);
        end;
    end;
  end;
end;

end.
