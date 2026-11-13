{******************************************************************************}
{                                                                              }
{  DelphiDoom: Xcom32 - the screens that the buttons of the geoscape and of    }
{  the basescape open (part of the composition root: it knows the classes)      }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.GeoscapeNavigator;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.State, DelphiDoom.XcomGeoscape.Globe, DelphiDoom.XcomGeoscape.Navigator.Intf,
  DelphiDoom.XcomGeoscape.BaseNavigator.Intf, DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.BaseFacility,
  DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomGeoscape.Control.Intf, DelphiDoom.XcomMenu.OptionsNavigator.Intf;

type
  /// <summary>
  ///   Opens the screens that exist (the bases screen from the geoscape); the others do nothing yet. It is the
  ///   navigator of both the geoscape and the basescape; it does not own the host
  /// </summary>
  TXcomGameNavigator = class(TInterfacedObject, IXcomGeoscapeNavigator, IXcomBasescapeNavigator,
    IXcomGeoscapeAware)
  strict private
    FHost: TXcomStateHost;
    FControl: IXcomGeoscapeControl;
    FOptionsNavigator: IXcomOptionsNavigator;
  public
    /// <param name="AOptionsNavigator">Makes the screens of the options of the pause menu (nil: Game Options does nothing)</param>
    constructor Create(AHost: TXcomStateHost; const AOptionsNavigator: IXcomOptionsNavigator = nil);
    procedure AttachGeoscape(const AControl: IXcomGeoscapeControl);
    procedure OpenBases(AGlobe: TXcomGlobe);
    procedure OpenPlaceLift(ABase: TXcomBase; AGlobe: TXcomGlobe; AFirst: Boolean);
    procedure OpenGraphs;
    procedure OpenUfopaedia;
    procedure OpenOptions;
    procedure OpenFunding;
    procedure OpenBase(ABase: TXcomBase; AGlobe: TXcomGlobe);
    procedure OpenBaseScreen(AScreen: TXcomBaseScreen; ABase: TXcomBase);
    procedure Open(AScreen: TXcomBaseScreen; ABase: TXcomBase; AFacility: TXcomBaseFacility;
      AParent: TXcomState = nil);
  end;

implementation

uses
  DelphiDoom.XcomMenu.PauseState, DelphiDoom.XcomMenu.OptionsTypes, DelphiDoom.XcomMenu.CutsceneState,
  DelphiDoom.XcomGeoscape.Strategy,DelphiDoom.XcomBasescape.BasescapeState, DelphiDoom.XcomBasescape.SoldiersState,
  DelphiDoom.XcomBasescape.CraftsState, DelphiDoom.XcomBasescape.BaseInfoState,
  DelphiDoom.XcomBasescape.PlaceLiftState, DelphiDoom.XcomBasescape.BuildFacilitiesState,
  DelphiDoom.XcomBasescape.DismantleFacilityState, DelphiDoom.XcomBasescape.ResearchState, DelphiDoom.XcomBasescape.ManufactureState, DelphiDoom.XcomGeoscape.BuildNewBaseState,
  DelphiDoom.XcomGeoscape.FundingState, DelphiDoom.XcomBasescape.PurchaseState,DelphiDoom.XcomBasescape.SellState, DelphiDoom.XcomBasescape.TransferBaseState,
  DelphiDoom.XcomBasescape.CraftInfoState, DelphiDoom.XcomGeoscape.GraphsState,
  DelphiDoom.XcomBasescape.PsiTrainingState, DelphiDoom.XcomBasescape.AllocatePsiTrainingState,
  DelphiDoom.XcomBasescape.StatisticsState, DelphiDoom.XcomUfopaedia.Factory;

constructor TXcomGameNavigator.Create(AHost: TXcomStateHost; const AOptionsNavigator: IXcomOptionsNavigator);
begin
  inherited Create;
  FHost := AHost;
  FOptionsNavigator := AOptionsNavigator;
end;

procedure TXcomGameNavigator.AttachGeoscape(const AControl: IXcomGeoscapeControl);
begin
  FControl := AControl;
end;

procedure TXcomGameNavigator.OpenPlaceLift(ABase: TXcomBase; AGlobe: TXcomGlobe; AFirst: Boolean);
begin
  FHost.PushState(TXcomPlaceLiftState.Create(FHost, ABase, AGlobe, Self, AFirst));
end;

procedure TXcomGameNavigator.OpenBases(AGlobe: TXcomGlobe);
var
  LSave: TXcomSavedGame;
begin
  LSave := TXcomStrategy.SavedGame(FHost);
  if LSave.Bases.Count > 0 then
    FHost.PushState(TXcomBasescapeState.Create(FHost, LSave.Bases.First, AGlobe, Self));
end;

procedure TXcomGameNavigator.OpenBase(ABase: TXcomBase; AGlobe: TXcomGlobe);
begin
  FHost.PushState(TXcomBasescapeState.Create(FHost, ABase, AGlobe, Self));
end;

procedure TXcomGameNavigator.OpenBaseScreen(AScreen: TXcomBaseScreen; ABase: TXcomBase);
begin
  Open(AScreen, ABase, nil);
end;

procedure TXcomGameNavigator.OpenGraphs;
begin
  FHost.PushState(TXcomGraphsState.Create(FHost));
end;

procedure TXcomGameNavigator.OpenUfopaedia;
begin
  // Ufopaedia::open: one navigator for the whole visit (it keeps the article on the screen)
  TXcomUfopaediaFactory.CreateNavigator(FHost).Open;
end;

procedure TXcomGameNavigator.OpenOptions;
begin
  FHost.PushState(TXcomPauseState.Create(FHost, ooGeoscape, FOptionsNavigator));
end;

procedure TXcomGameNavigator.OpenFunding;
begin
  FHost.PushState(TXcomFundingState.Create(FHost));
end;

procedure TXcomGameNavigator.Open(AScreen: TXcomBaseScreen; ABase: TXcomBase; AFacility: TXcomBaseFacility;
  AParent: TXcomState);
var
  LCraftIndex: Integer;
  LHost: TXcomStateHost;
begin
  case AScreen of
    bsNewBase:
      if Assigned(FControl) then
      begin
        // BasescapeState::btnNewBaseClick: a new base (that the saved game does not have yet) and the site on the globe
        FHost.PopState;
        FHost.PushState(TXcomBuildNewBaseState.Create(FHost, TXcomBase.Create, FControl.Globe, False, FControl));
      end;
    bsResearch:
      FHost.PushState(TXcomResearchState.Create(FHost, ABase));
    bsManufacture:
      FHost.PushState(TXcomManufactureState.Create(FHost, ABase));
    bsFacilities:
      FHost.PushState(TXcomBuildFacilitiesState.Create(FHost, ABase, AParent));
    bsDismantle:
      if (AParent is TXcomBasescapeState) and Assigned(AFacility) then
        FHost.PushState(TXcomDismantleFacilityState.Create(FHost, ABase, TXcomBasescapeState(AParent).View,
          AFacility));
    bsBaseInfo:
      FHost.PushState(TXcomBaseInfoState.Create(FHost, ABase));
    bsSoldiers:
      FHost.PushState(TXcomSoldiersState.Create(FHost, ABase));
    bsPurchase:
      FHost.PushState(TXcomPurchaseState.Create(FHost, ABase));
    bsCraftInfo:
      if (AParent is TXcomBasescapeState) and Assigned(AFacility) and
        (TXcomBasescapeState(AParent).View.CraftOf(AFacility) <> nil) then
      begin
        LCraftIndex := ABase.Crafts.IndexOf(TXcomBasescapeState(AParent).View.CraftOf(AFacility));
        if LCraftIndex >= 0 then
          FHost.PushState(TXcomCraftInfoState.Create(FHost, ABase, LCraftIndex));
      end;
    bsSell:
      FHost.PushState(TXcomSellState.Create(FHost, ABase));
    bsTransfer:
      FHost.PushState(TXcomTransferBaseState.Create(FHost, ABase));
    bsCrafts:
      FHost.PushState(TXcomCraftsState.Create(FHost, ABase));
    bsPsiTraining:
      // without a base: the bases with laboratories, after the monthly report
      if Assigned(ABase) then
        FHost.PushState(TXcomAllocatePsiTrainingState.Create(FHost, ABase))
      else
        FHost.PushState(TXcomPsiTrainingState.Create(FHost));
    bsStatistics:
      begin
        // the end of the game (the only caller is the monthly report: the game is lost): the cutscene takes
        // itself away, leaves the statistics as the only state and plays over them
        LHost := FHost;
        FHost.PushState(TXcomCutsceneState.Create(FHost, XCOM_CUTSCENE_LOSE_GAME, nil,
          procedure
          begin
            LHost.SetState(TXcomStatisticsState.Create(LHost));
          end));
      end;
  end;
end;

end.
