{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom strategy library - events that nobody listens to           }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomStrategy.NullEvents;

interface

uses
  DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.Craft, DelphiDoom.XcomSave.Ufo, DelphiDoom.XcomSave.Target,
  DelphiDoom.XcomSave.MissionSite, DelphiDoom.XcomSave.AlienBase, DelphiDoom.XcomSave.Waypoint,
  DelphiDoom.XcomSave.BaseFacility, DelphiDoom.XcomStrategy.Types, DelphiDoom.XcomStrategy.Events.Intf;

type
  /// <summary>
  ///   The screen that shows no popups: nothing is done with the events (the waypoint of CraftNeedsOrders is
  ///   freed). A base class for a listener that cares only about some of them
  /// </summary>
  TXcomNullGeoscapeEvents = class(TInterfacedObject, IXcomGeoscapeEvents)
  public
    procedure GameLost; virtual;
    procedure UfoDetected(const AUfo: TXcomUfo; AHyperDetected: Boolean); virtual;
    procedure UfoLost(const AUfo: TXcomUfo); virtual;
    procedure MissionDetected(const ASite: TXcomMissionSite); virtual;
    procedure BaseAttacked(const ABase: TXcomBase; const AUfo: TXcomUfo); virtual;
    procedure CraftNeedsOrders(const ACraft: TXcomCraft; const AWaypoint: TXcomWaypoint); virtual;
    procedure DogfightRequested(const ACraft: TXcomCraft; const AUfo: TXcomUfo); virtual;
    procedure DogfightImpossible(const ACraft: TXcomCraft; const AReason: string); virtual;
    procedure LandingPossible(const ACraft: TXcomCraft; const ATarget: TXcomTarget); virtual;
    procedure CraftPatrolling(const ACraft: TXcomCraft); virtual;
    procedure LowFuel(const ACraft: TXcomCraft); virtual;
    procedure CraftShortage(const ABase: TXcomBase; const ACraft: TXcomCraft; const AItem: string;
      ARearming: Boolean); virtual;
    procedure ItemsArriving; virtual;
    procedure ProductionFinished(const ABase: TXcomBase; const AProductionName: string;
      AProgress: TXcomProductionProgress); virtual;
    procedure FacilityBuilt(const ABase: TXcomBase; const AFacility: TXcomBaseFacility); virtual;
    procedure ResearchFinished(const ABase: TXcomBase; const AResearchName: string); virtual;
    procedure ResearchCompleted(const ABase: TXcomBase; const AOutcome: TXcomResearchOutcome); virtual;
    procedure StorageExceeded(const ABase: TXcomBase); virtual;
    procedure AlienBaseDiscovered(const ABase: TXcomAlienBase); virtual;
    procedure AutosaveDue(AIronman: Boolean); virtual;
    procedure MonthlyReport(APsiTraining: Boolean); virtual;
  end;

implementation

{ TXcomNullGeoscapeEvents }

procedure TXcomNullGeoscapeEvents.GameLost;
begin
end;

procedure TXcomNullGeoscapeEvents.UfoDetected(const AUfo: TXcomUfo; AHyperDetected: Boolean);
begin
end;

procedure TXcomNullGeoscapeEvents.UfoLost(const AUfo: TXcomUfo);
begin
end;

procedure TXcomNullGeoscapeEvents.MissionDetected(const ASite: TXcomMissionSite);
begin
end;

procedure TXcomNullGeoscapeEvents.BaseAttacked(const ABase: TXcomBase; const AUfo: TXcomUfo);
begin
end;

procedure TXcomNullGeoscapeEvents.CraftNeedsOrders(const ACraft: TXcomCraft; const AWaypoint: TXcomWaypoint);
begin
  AWaypoint.Free;
end;

procedure TXcomNullGeoscapeEvents.DogfightRequested(const ACraft: TXcomCraft; const AUfo: TXcomUfo);
begin
end;

procedure TXcomNullGeoscapeEvents.DogfightImpossible(const ACraft: TXcomCraft; const AReason: string);
begin
end;

procedure TXcomNullGeoscapeEvents.LandingPossible(const ACraft: TXcomCraft; const ATarget: TXcomTarget);
begin
end;

procedure TXcomNullGeoscapeEvents.CraftPatrolling(const ACraft: TXcomCraft);
begin
end;

procedure TXcomNullGeoscapeEvents.LowFuel(const ACraft: TXcomCraft);
begin
end;

procedure TXcomNullGeoscapeEvents.CraftShortage(const ABase: TXcomBase; const ACraft: TXcomCraft;
  const AItem: string; ARearming: Boolean);
begin
end;

procedure TXcomNullGeoscapeEvents.ItemsArriving;
begin
end;

procedure TXcomNullGeoscapeEvents.ProductionFinished(const ABase: TXcomBase; const AProductionName: string;
  AProgress: TXcomProductionProgress);
begin
end;

procedure TXcomNullGeoscapeEvents.FacilityBuilt(const ABase: TXcomBase; const AFacility: TXcomBaseFacility);
begin
end;

procedure TXcomNullGeoscapeEvents.ResearchCompleted(const ABase: TXcomBase; const AOutcome: TXcomResearchOutcome);
begin
end;

procedure TXcomNullGeoscapeEvents.ResearchFinished(const ABase: TXcomBase; const AResearchName: string);
begin
end;

procedure TXcomNullGeoscapeEvents.StorageExceeded(const ABase: TXcomBase);
begin
end;

procedure TXcomNullGeoscapeEvents.AlienBaseDiscovered(const ABase: TXcomAlienBase);
begin
end;

procedure TXcomNullGeoscapeEvents.AutosaveDue(AIronman: Boolean);
begin
end;

procedure TXcomNullGeoscapeEvents.MonthlyReport(APsiTraining: Boolean);
begin
end;

end.
