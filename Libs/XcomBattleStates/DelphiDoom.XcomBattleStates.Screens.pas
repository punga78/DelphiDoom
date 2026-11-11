{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape states library - the screens of the battle      }
{  made with the classes of the library                                         }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattleStates.Screens;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.State, DelphiDoom.XcomBattle.Model, DelphiDoom.XcomBattle.Action,
  DelphiDoom.XcomBattleStates.Screens.Intf, DelphiDoom.XcomBattleStates.BattlescapeState,
  DelphiDoom.XcomBattleStates.ActionMenuState, DelphiDoom.XcomBattleStates.PrimeGrenadeState;

type
  /// <summary>Makes the debriefing screen of the battle of a battlescape state (the saved game is changed there)</summary>
  TXcomBattleDebriefing = reference to function(AParent: TXcomState): TXcomState;

  /// <summary>Makes the pause menu of the battle (PauseState(OPT_BATTLESCAPE))</summary>
  TXcomBattleOptionsScreen = reference to function(AParent: TXcomState): TXcomState;

  /// <summary>
  ///   IXcomBattleScreens with the states of this library; AParent is always the TXcomBattlescapeState that asks.
  ///   A screen that is not ported gives nil. The debriefing and the pause menu belong to other libraries: the
  ///   program gives the two functions (nil: no screen)
  /// </summary>
  TXcomBattleScreens = class(TInterfacedObject, IXcomBattleScreens)
  strict private
    FDebriefing: TXcomBattleDebriefing;
    FOptions: TXcomBattleOptionsScreen;
  public
    constructor Create(const ADebriefing: TXcomBattleDebriefing = nil;
      const AOptions: TXcomBattleOptionsScreen = nil);
    function ActionMenu(AParent: TXcomState; const AAction: TXcomBattleAction; AX, AY: Integer): TXcomState;
    function PrimeGrenade(AParent: TXcomState; const AAction: TXcomBattleAction; AInInventoryView: Boolean;
      const AGrenade: TXcomBattleItem): TXcomState;
    function Medikit(AParent: TXcomState; const ATarget: TXcomBattleUnit; const AAction: TXcomBattleAction)
      : TXcomState;
    function Scanner(AParent: TXcomState; const AAction: TXcomBattleAction): TXcomState;
    function UnitInfo(AParent: TXcomState; const AUnit: TXcomBattleUnit; AFromInventory, AMindProbe: Boolean)
      : TXcomState;
    function Inventory(AParent: TXcomState; ATimeUnits: Boolean): TXcomState;
    function MiniMap(AParent: TXcomState): TXcomState;
    function Options(AParent: TXcomState): TXcomState;
    function AbortMission(AParent: TXcomState): TXcomState;
    function NextTurn(AParent: TXcomState): TXcomState;
    function Infobox(AParent: TXcomState; const AMessage: string): TXcomState;
    function InfoboxOk(AParent: TXcomState; const AMessage: string): TXcomState;
    function Debriefing(AParent: TXcomState): TXcomState;
  end;

implementation

constructor TXcomBattleScreens.Create(const ADebriefing: TXcomBattleDebriefing;
  const AOptions: TXcomBattleOptionsScreen);
begin
  inherited Create;
  FDebriefing := ADebriefing;
  FOptions := AOptions;
end;

function TXcomBattleScreens.ActionMenu(AParent: TXcomState; const AAction: TXcomBattleAction; AX,
  AY: Integer): TXcomState;
begin
  Result := TXcomActionMenuState.Create(AParent.Host, AParent as TXcomBattlescapeState, AAction, AX, AY);
end;

function TXcomBattleScreens.PrimeGrenade(AParent: TXcomState; const AAction: TXcomBattleAction;
  AInInventoryView: Boolean; const AGrenade: TXcomBattleItem): TXcomState;
begin
  Result := TXcomPrimeGrenadeState.Create(AParent.Host, AParent as TXcomBattlescapeState, AAction, AInInventoryView,
    AGrenade);
end;

function TXcomBattleScreens.Medikit(AParent: TXcomState; const ATarget: TXcomBattleUnit;
  const AAction: TXcomBattleAction): TXcomState;
begin
  Result := nil;
end;

function TXcomBattleScreens.Scanner(AParent: TXcomState; const AAction: TXcomBattleAction): TXcomState;
begin
  Result := nil;
end;

function TXcomBattleScreens.UnitInfo(AParent: TXcomState; const AUnit: TXcomBattleUnit; AFromInventory,
  AMindProbe: Boolean): TXcomState;
begin
  Result := nil;
end;

function TXcomBattleScreens.Inventory(AParent: TXcomState; ATimeUnits: Boolean): TXcomState;
begin
  Result := nil;
end;

function TXcomBattleScreens.MiniMap(AParent: TXcomState): TXcomState;
begin
  Result := nil;
end;

function TXcomBattleScreens.Options(AParent: TXcomState): TXcomState;
begin
  Result := nil;
  if Assigned(FOptions) then
    Result := FOptions(AParent);
end;

function TXcomBattleScreens.AbortMission(AParent: TXcomState): TXcomState;
begin
  Result := nil;
end;

function TXcomBattleScreens.NextTurn(AParent: TXcomState): TXcomState;
begin
  Result := nil;
end;

function TXcomBattleScreens.Infobox(AParent: TXcomState; const AMessage: string): TXcomState;
begin
  Result := nil;
end;

function TXcomBattleScreens.InfoboxOk(AParent: TXcomState; const AMessage: string): TXcomState;
begin
  Result := nil;
end;

function TXcomBattleScreens.Debriefing(AParent: TXcomState): TXcomState;
begin
  Result := nil;
  if Assigned(FDebriefing) then
    Result := FDebriefing(AParent);
end;

end.
