{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom strategy library - the crafts while the time goes on       }
{  (the craft part of GeoscapeState::time5Seconds, time10Minutes, time30-      }
{  Minutes and time1Hour)                                                      }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomStrategy.CraftTracker;

interface

uses
  System.SysUtils, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.Random, DelphiDoom.XcomMod.UfoTrajectory,
  DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.Craft, DelphiDoom.XcomSave.Ufo,
  DelphiDoom.XcomSave.Soldier, DelphiDoom.XcomSave.Target, DelphiDoom.XcomSave.Waypoint, DelphiDoom.XcomSave.MissionSite,
  DelphiDoom.XcomSave.AlienBase, DelphiDoom.XcomSave.Country, DelphiDoom.XcomSave.Region,
  DelphiDoom.XcomStrategy.Events.Intf, DelphiDoom.XcomStrategy.Geography, DelphiDoom.XcomStrategy.LandMap.Intf,
  DelphiDoom.XcomStrategy.BaseCrafts;

type
  /// <summary>
  ///   What the crafts of the bases do as the time goes on: the destroyed ones are lost with their crew, the
  ///   ones that follow a UFO lose it or engage it, the ones that reached their target report, they burn fuel,
  ///   find alien bases, are repaired, rearmed and refuelled. The dogfight itself is the screen's (not ported):
  ///   the screen is told with DogfightRequested
  /// </summary>
  TXcomCraftTracker = class
  strict private
    FGame: TXcomSavedGame;
    FRuleset: TXcomRuleset;
    FRandom: IXcomRandom;
    FLand: IXcomLandMap;
    FEvents: IXcomGeoscapeEvents;
    FDogfights: Integer;
    procedure LoseCraft(const ABase: TXcomBase; const ACraft: TXcomCraft);
    procedure FollowUfo(const ACraft: TXcomCraft; const AUfo: TXcomUfo);
    procedure ReachTarget(const ACraft: TXcomCraft);
    procedure ReachUfo(const ACraft: TXcomCraft; const AUfo: TXcomUfo);
  public
    constructor Create(const AGame: TXcomSavedGame; const ARuleset: TXcomRuleset; const ARandom: IXcomRandom;
      const ALand: IXcomLandMap; const AEvents: IXcomGeoscapeEvents);
    /// <summary>The craft loop of time5Seconds</summary>
    procedure Move;
    /// <summary>The craft loop of time10Minutes: fuel, low fuel and the alien bases that a patrol finds</summary>
    procedure BurnFuel;
    /// <summary>The craft part of time30Minutes: the crafts that are refuelling take fuel from the storage</summary>
    procedure Refuel;
    /// <summary>The craft part of time1Hour: repairs and rearming</summary>
    procedure RepairAndRearm;
    /// <summary>The dogfights that the screen was asked to start (they are never finished here)</summary>
    property DogfightsRequested: Integer read FDogfights;
  end;

implementation

{ TXcomCraftTracker }

constructor TXcomCraftTracker.Create(const AGame: TXcomSavedGame; const ARuleset: TXcomRuleset;
  const ARandom: IXcomRandom; const ALand: IXcomLandMap; const AEvents: IXcomGeoscapeEvents);
begin
  inherited Create;
  FGame := AGame;
  FRuleset := ARuleset;
  FRandom := ARandom;
  FLand := ALand;
  FEvents := AEvents;
end;

procedure TXcomCraftTracker.LoseCraft(const ABase: TXcomBase; const ACraft: TXcomCraft);
var
  LCountry: TXcomCountry;
  LRegion: TXcomRegion;
  LIndex: Integer;
  LSoldier: TXcomSoldier;
  LLost: TXcomCraft;
begin
  LCountry := TXcomGeography.LocateCountry(FGame, ACraft.Longitude, ACraft.Latitude);
  if Assigned(LCountry) then
    LCountry.AddActivityXcom(-ACraft.Rules.Score);
  LRegion := TXcomGeography.LocateRegion(FGame, ACraft.Longitude, ACraft.Latitude);
  if Assigned(LRegion) then
    LRegion.AddActivityXcom(-ACraft.Rules.Score);
  if ACraft.Rules.Soldiers > 0 then
  begin
    LIndex := 0;
    while LIndex < ABase.Soldiers.Count do
    begin
      LSoldier := ABase.Soldiers[LIndex];
      if LSoldier.Craft = ACraft then
        TXcomGeography.KillSoldier(FGame, LSoldier)
      else
        Inc(LIndex);
    end;
  end;
  LLost := TXcomBaseCrafts.Remove(ABase, ACraft, False, FRuleset);
  LLost.Free;
end;

procedure TXcomCraftTracker.FollowUfo(const ACraft: TXcomCraft; const AUfo: TXcomUfo);
var
  LWaypoint: TXcomWaypoint;
begin
  if not AUfo.Detected then
  begin
    if (AUfo.Trajectory.Id = TXcomUfoTrajectory.RETALIATION_ASSAULT_RUN) and
      ((AUfo.Status = TXcomUfo.STATUS_LANDED) or (AUfo.Status = TXcomUfo.STATUS_DESTROYED)) then
      ACraft.ReturnToBase
    else
    begin
      // the UFO is not seen any more: the player gives new orders at the place where it was
      LWaypoint := TXcomWaypoint.Create;
      LWaypoint.SetLongitude(AUfo.Longitude);
      LWaypoint.SetLatitude(AUfo.Latitude);
      LWaypoint.Id := AUfo.Id;
      ACraft.SetDestination(nil);
      FEvents.CraftNeedsOrders(ACraft, LWaypoint);
    end;
  end;
  if (AUfo.Status = TXcomUfo.STATUS_LANDED) and ACraft.InDogfight then
    ACraft.InDogfight := False
  else if AUfo.Status = TXcomUfo.STATUS_DESTROYED then
    ACraft.ReturnToBase;
end;

procedure TXcomCraftTracker.ReachUfo(const ACraft: TXcomCraft; const AUfo: TXcomUfo);
begin
  case AUfo.Status of
    TXcomUfo.STATUS_FLYING:
      begin
        // at most four dogfights at the same time
        if FDogfights >= 4 then
          Exit;
        if not ACraft.InDogfight and (AUfo.Speed <= ACraft.Rules.MaxSpeed) then
        begin
          // DogfightState sets the craft in a dogfight
          ACraft.InDogfight := True;
          Inc(FDogfights);
          FEvents.DogfightRequested(ACraft, AUfo);
          if (ACraft.Rules.MaxAltitude > -1) and (AUfo.AltitudeInt > ACraft.Rules.MaxAltitude) then
            FEvents.DogfightImpossible(ACraft, 'STR_UNABLE_TO_ENGAGE_DEPTH')
          else if (ACraft.Rules.MaxAltitude > -1) and not FLand.InsideLand(ACraft.Longitude, ACraft.Latitude) then
            FEvents.DogfightImpossible(ACraft, 'STR_UNABLE_TO_ENGAGE_AIRBORNE');
        end;
      end;
    TXcomUfo.STATUS_LANDED, TXcomUfo.STATUS_CRASHED, TXcomUfo.STATUS_DESTROYED:
      begin
        // DESTROYED: just before expiration
        if (ACraft.NumSoldiers(TXcomBase(ACraft.Base).Soldiers) > 0) or (ACraft.NumVehicles > 0) then
        begin
          if not ACraft.InDogfight then
            FEvents.LandingPossible(ACraft, AUfo);
        end
        else if AUfo.Status <> TXcomUfo.STATUS_LANDED then
          ACraft.ReturnToBase;
      end;
  end;
end;

procedure TXcomCraftTracker.ReachTarget(const ACraft: TXcomCraft);
var
  LDestination: TXcomTarget;
  LCarries: Boolean;
begin
  LDestination := ACraft.Destination;
  LCarries := (ACraft.NumSoldiers(TXcomBase(ACraft.Base).Soldiers) > 0) or (ACraft.NumVehicles > 0);
  if LDestination is TXcomUfo then
    ReachUfo(ACraft, TXcomUfo(LDestination))
  else if LDestination is TXcomWaypoint then
  begin
    FEvents.CraftPatrolling(ACraft);
    ACraft.SetDestination(nil);
  end
  else if LDestination is TXcomMissionSite then
  begin
    if LCarries then
      FEvents.LandingPossible(ACraft, LDestination)
    else
      ACraft.ReturnToBase;
  end
  else if LDestination is TXcomAlienBase then
  begin
    if TXcomAlienBase(LDestination).Discovered then
    begin
      if LCarries then
        FEvents.LandingPossible(ACraft, LDestination)
      else
        ACraft.ReturnToBase;
    end;
  end;
end;

procedure TXcomCraftTracker.Move;
var
  LBase: TXcomBase;
  LIndex: Integer;
  LCraft: TXcomCraft;
begin
  for LBase in FGame.Bases do
  begin
    LIndex := 0;
    while LIndex < LBase.Crafts.Count do
    begin
      LCraft := LBase.Crafts[LIndex];
      if LCraft.IsDestroyed then
      begin
        LoseCraft(LBase, LCraft);
        Continue;
      end;
      if Assigned(LCraft.Destination) then
      begin
        if LCraft.Destination is TXcomUfo then
          FollowUfo(LCraft, TXcomUfo(LCraft.Destination))
        else if LCraft.InDogfight then
          LCraft.InDogfight := False;
      end;
      LCraft.Think;
      if LCraft.ReachedDestination then
      begin
        // too many dogfights: the craft waits (the C++ skips it with the next index)
        if (LCraft.Destination is TXcomUfo) and (TXcomUfo(LCraft.Destination).Status = TXcomUfo.STATUS_FLYING) and
          (FDogfights >= 4) then
        begin
          Inc(LIndex);
          Continue;
        end;
        ReachTarget(LCraft);
      end;
      Inc(LIndex);
    end;
  end;
end;

procedure TXcomCraftTracker.BurnFuel;
var
  LBase: TXcomBase;
  LCraft: TXcomCraft;
  LAlienBase: TXcomAlienBase;
  LRange, LDistance: Double;
begin
  for LBase in FGame.Bases do
    for LCraft in LBase.Crafts do
    begin
      if LCraft.Status <> 'STR_OUT' then
        Continue;
      LCraft.ConsumeFuel;
      if not LCraft.LowFuel and (LCraft.Fuel <= LCraft.FuelLimit(LCraft.Base)) then
      begin
        LCraft.LowFuel := True;
        LCraft.ReturnToBase;
        FEvents.LowFuel(LCraft);
      end;
      if not Assigned(LCraft.Destination) then
      begin
        LRange := TXcomGeography.Nautical(LCraft.Rules.SightRange);
        for LAlienBase in FGame.AlienBases do
        begin
          LDistance := LCraft.Distance(LAlienBase);
          if LDistance <= LRange then
            // the chance falls with the distance; the roll is made even for a base that is known
            if (FRandom.Generate(0, 99) < Trunc(50 - (LDistance / LRange) * 50)) and not LAlienBase.Discovered then
              LAlienBase.Discovered := True;
        end;
      end;
    end;
end;

procedure TXcomCraftTracker.Refuel;
var
  LBase: TXcomBase;
  LCraft: TXcomCraft;
  LItem: string;
begin
  for LBase in FGame.Bases do
    for LCraft in LBase.Crafts do
      if LCraft.Status = 'STR_REFUELLING' then
      begin
        LItem := LCraft.Refuel(LBase.StorageItems);
        if LItem <> '' then
          FEvents.CraftShortage(LBase, LCraft, LItem, False);
      end;
end;

procedure TXcomCraftTracker.RepairAndRearm;
var
  LBase: TXcomBase;
  LCraft: TXcomCraft;
  LItem: string;
begin
  for LBase in FGame.Bases do
    for LCraft in LBase.Crafts do
    begin
      if LCraft.Status = 'STR_REPAIRS' then
        LCraft.Repair
      else if LCraft.Status = 'STR_REARMING' then
      begin
        LItem := LCraft.Rearm(LBase.StorageItems, FRuleset);
        if LItem <> '' then
          FEvents.CraftShortage(LBase, LCraft, LItem, True);
      end;
    end;
end;

end.
