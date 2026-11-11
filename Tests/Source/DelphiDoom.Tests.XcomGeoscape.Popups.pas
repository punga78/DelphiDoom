{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom geoscape library - the popups of the      }
{  events of the geoscape (with the fake game of the engine tests)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomGeoscape.Popups;

interface

uses
  System.SysUtils, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.XcomEngine.Types,
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.Widget, DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.Craft,
  DelphiDoom.XcomSave.Ufo, DelphiDoom.XcomMod.RuleCraft, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomGeoscape.Globe, DelphiDoom.XcomGeoscape.Control.Intf, DelphiDoom.XcomGeoscape.Simulation.Intf,
  DelphiDoom.XcomBasescape.Navigator.Intf, DelphiDoom.Tests.XcomEngine.World;

type
  /// <summary>Gives the tests the surfaces of a state (protected)</summary>
  TStateCracker = class(TXcomState);

  /// <summary>The geoscape as the popups see it: it counts what they ask and keeps the states they give</summary>
  TFakeControl = class(TInterfacedObject, IXcomGeoscapeControl)
  strict private
    FTimerResets: Integer;
    FPopups: TList<TXcomState>;
    FOpenedBase: TXcomBase;
    FOpenedScreen: TXcomBaseScreen;
  public
    constructor Create;
    destructor Destroy; override;
    procedure TimerReset;
    function Globe: TXcomGlobe;
    procedure Popup(AState: TXcomState);
    procedure OpenBase(ABase: TXcomBase);
    procedure OpenBaseScreen(AScreen: TXcomBaseScreen; ABase: TXcomBase);
    procedure PlaceLift(ABase: TXcomBase; AFirst: Boolean);
    function Screens: IXcomGeoscapeScreens;
    function Palette: PXcomColors;
    property TimerResets: Integer read FTimerResets;
    property Popups: TList<TXcomState> read FPopups;
    property OpenedBase: TXcomBase read FOpenedBase;
    property OpenedScreen: TXcomBaseScreen read FOpenedScreen;
  end;

  /// <summary>A simulation that counts its calls</summary>
  TFakeSimulation = class(TInterfacedObject, IXcomGeoscapeSimulation)
  strict private
    FCalls: string;
  public
    procedure Time5Seconds;
    procedure Time10Minutes;
    procedure Time30Minutes;
    procedure Time1Hour;
    procedure Time1Day;
    procedure Time1Month;
    procedure StartFirstMonth;
    property Calls: string read FCalls;
  end;

  [TestFixture]
  [Category('xcom-geoscape')]
  TTestXcomGeoscapePopups = class(TObject)
  strict private
    FWorld: TTestWorld;
    FControl: TFakeControl;
    FControlRef: IXcomGeoscapeControl;
    function FindButton(AState: TXcomState; AIndex: Integer): TXcomTextButton;
    procedure ClickButton(AButton: TXcomTextButton);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeAzzerareLaVelocitaDelTempoConOkECinqSecondi;
    [Test]
    procedure DovrebbeLasciareLaVelocitaDelTempoConOk;
    [Test]
    procedure DovrebbeAzzerareLaVelocitaDelTempoNellErroreDelVelivolo;
    [Test]
    procedure DovrebbeChiudereIlPopupDellUfoPerso;
    [Test]
    procedure DovrebbeChiudereLErroreDelCombattimentoSenzaMandareIlVelivoloAllaBase;
    [Test]
    procedure DovrebbeMostrareIlPopupDelCarburanteBasso;
    [Test]
    procedure DovrebbeMostrareLErroreDelloShortageConIlTestoDelRifornimento;
    [Test]
    procedure DovrebbeIgnorareGliEventiSenzaGeoscape;
    [Test]
    procedure DovrebbeUsareIlNomeDelBersaglioNelNome;
    [Test]
    procedure DovrebbeUsareIlNomeDiBaseSenzaNomePredefinito;
    [Test]
    procedure DovrebbeInoltrareIPassiDelTempoAllaSimulazioneInterna;
    [Test]
    procedure DovrebbeInoltrareIlGeoscapeAgliEventi;
  end;

implementation

uses
  DelphiDoom.XcomGeoscape.LowFuelState, DelphiDoom.XcomGeoscape.CraftErrorState,
  DelphiDoom.XcomGeoscape.UfoLostState, DelphiDoom.XcomGeoscape.DogfightErrorState,
  DelphiDoom.XcomGeoscape.PopupEvents, DelphiDoom.XcomGeoscape.PopupSimulation,
  DelphiDoom.XcomGeoscape.TargetNames, DelphiDoom.XcomStrategy.Events.Intf;

{ TFakeControl }

constructor TFakeControl.Create;
begin
  inherited Create;
  FPopups := TList<TXcomState>.Create;
end;

destructor TFakeControl.Destroy;
var
  LState: TXcomState;
begin
  for LState in FPopups do
    LState.Free;
  FPopups.Free;
  inherited Destroy;
end;

procedure TFakeControl.TimerReset;
begin
  Inc(FTimerResets);
end;

function TFakeControl.Globe: TXcomGlobe;
begin
  Result := nil;
end;

procedure TFakeControl.Popup(AState: TXcomState);
begin
  FPopups.Add(AState);
end;

procedure TFakeControl.OpenBase(ABase: TXcomBase);
begin
  FOpenedBase := ABase;
end;

procedure TFakeControl.OpenBaseScreen(AScreen: TXcomBaseScreen; ABase: TXcomBase);
begin
  FOpenedScreen := AScreen;
  FOpenedBase := ABase;
end;

procedure TFakeControl.PlaceLift(ABase: TXcomBase; AFirst: Boolean);
begin
end;

function TFakeControl.Screens: IXcomGeoscapeScreens;
begin
  Result := nil;
end;

function TFakeControl.Palette: PXcomColors;
begin
  Result := nil;
end;

{ TFakeSimulation }

procedure TFakeSimulation.Time5Seconds;
begin
  FCalls := FCalls + '5s,';
end;

procedure TFakeSimulation.Time10Minutes;
begin
  FCalls := FCalls + '10m,';
end;

procedure TFakeSimulation.Time30Minutes;
begin
  FCalls := FCalls + '30m,';
end;

procedure TFakeSimulation.Time1Hour;
begin
  FCalls := FCalls + '1h,';
end;

procedure TFakeSimulation.Time1Day;
begin
  FCalls := FCalls + '1d,';
end;

procedure TFakeSimulation.Time1Month;
begin
  FCalls := FCalls + '1mo,';
end;

procedure TFakeSimulation.StartFirstMonth;
begin
  FCalls := FCalls + 'first,';
end;

{ TTestXcomGeoscapePopups }

procedure TTestXcomGeoscapePopups.Setup;
begin
  FWorld := TTestWorld.Create;
  FControl := TFakeControl.Create;
  FControlRef := FControl;
end;

procedure TTestXcomGeoscapePopups.TearDown;
begin
  FControlRef := nil;
  FWorld.Free;
end;

function TTestXcomGeoscapePopups.FindButton(AState: TXcomState; AIndex: Integer): TXcomTextButton;
var
  LWidget: TXcomWidget;
  LCount: Integer;
begin
  LCount := 0;
  for LWidget in TStateCracker(AState).Surfaces do
    if LWidget is TXcomTextButton then
    begin
      if LCount = AIndex then
        Exit(TXcomTextButton(LWidget));
      Inc(LCount);
    end;
  Result := nil;
end;

procedure TTestXcomGeoscapePopups.ClickButton(AButton: TXcomTextButton);
begin
  // the window of a popup shows its surfaces when it has opened
  FWorld.Wait(400);
  // the display is 640 x 400: twice the size of the screen of the game
  FWorld.Click((AButton.X + AButton.Width div 2) * 2, (AButton.Y + AButton.Height div 2) * 2);
end;

procedure TTestXcomGeoscapePopups.DovrebbeAzzerareLaVelocitaDelTempoConOkECinqSecondi;
var
  LState: TXcomState;
begin
  LState := TXcomLowFuelState.Create(FWorld.Game, 'Triton-1', FControlRef);
  FWorld.Game.PushState(LState);
  ClickButton(FindButton(LState, 1));
  Assert.AreEqual(1, FControl.TimerResets);
  Assert.IsFalse(FWorld.Game.IsState(LState), 'il popup si chiude');
end;

procedure TTestXcomGeoscapePopups.DovrebbeLasciareLaVelocitaDelTempoConOk;
var
  LState: TXcomState;
begin
  LState := TXcomLowFuelState.Create(FWorld.Game, 'Triton-1', FControlRef);
  FWorld.Game.PushState(LState);
  ClickButton(FindButton(LState, 0));
  Assert.AreEqual(0, FControl.TimerResets);
  Assert.IsFalse(FWorld.Game.IsState(LState));
end;

procedure TTestXcomGeoscapePopups.DovrebbeAzzerareLaVelocitaDelTempoNellErroreDelVelivolo;
var
  LState: TXcomState;
begin
  LState := TXcomCraftErrorState.Create(FWorld.Game, FControlRef, 'no fuel');
  FWorld.Game.PushState(LState);
  ClickButton(FindButton(LState, 1));
  Assert.AreEqual(1, FControl.TimerResets);
  Assert.IsFalse(FWorld.Game.IsState(LState));
end;

procedure TTestXcomGeoscapePopups.DovrebbeChiudereIlPopupDellUfoPerso;
var
  LState: TXcomState;
begin
  LState := TXcomUfoLostState.Create(FWorld.Game, 'UFO-3');
  FWorld.Game.PushState(LState);
  ClickButton(FindButton(LState, 0));
  Assert.IsFalse(FWorld.Game.IsState(LState));
end;

procedure TTestXcomGeoscapePopups.DovrebbeChiudereLErroreDelCombattimentoSenzaMandareIlVelivoloAllaBase;
var
  LRules: TXcomRuleCraft;
  LCraft: TXcomCraft;
  LState: TXcomState;
begin
  LRules := TXcomRuleCraft.Create('STR_TRITON');
  try
    LCraft := TXcomCraft.Create(LRules, nil, 1);
    try
      LState := TXcomDogfightErrorState.Create(FWorld.Game, LCraft, 'Triton-1', 'too deep');
      FWorld.Game.PushState(LState);
      // the first button continues the pursuit
      ClickButton(FindButton(LState, 0));
      Assert.IsFalse(FWorld.Game.IsState(LState));
      Assert.IsNull(LCraft.Destination, 'il velivolo non ha ricevuto ordini');
    finally
      LCraft.Free;
    end;
  finally
    LRules.Free;
  end;
end;

procedure TTestXcomGeoscapePopups.DovrebbeMostrareIlPopupDelCarburanteBasso;
var
  LEvents: TXcomPopupGeoscapeEvents;
  LListener: IXcomGeoscapeEvents;
  LRules: TXcomRuleCraft;
  LCraft: TXcomCraft;
begin
  LEvents := TXcomPopupGeoscapeEvents.Create(FWorld.Game);
  LListener := LEvents;
  LRules := TXcomRuleCraft.Create('STR_TRITON');
  try
    LCraft := TXcomCraft.Create(LRules, nil, 1);
    try
      (LListener as IXcomGeoscapeAware).AttachGeoscape(FControlRef);
      LListener.LowFuel(LCraft);
      Assert.AreEqual(1, FControl.Popups.Count);
      Assert.IsTrue(FControl.Popups[0] is TXcomLowFuelState);
    finally
      LCraft.Free;
    end;
  finally
    LRules.Free;
  end;
end;

procedure TTestXcomGeoscapePopups.DovrebbeMostrareLErroreDelloShortageConIlTestoDelRifornimento;
var
  LListener: IXcomGeoscapeEvents;
  LRules: TXcomRuleCraft;
  LCraft: TXcomCraft;
  LBase: TXcomBase;
begin
  LListener := TXcomPopupGeoscapeEvents.Create(FWorld.Game);
  (LListener as IXcomGeoscapeAware).AttachGeoscape(FControlRef);
  LRules := TXcomRuleCraft.Create('STR_TRITON');
  LBase := TXcomBase.Create;
  try
    LBase.Name := 'Base 1';
    LCraft := TXcomCraft.Create(LRules, nil, 1);
    try
      LListener.CraftShortage(LBase, LCraft, 'STR_ZRBITE', True);
      LListener.CraftShortage(LBase, LCraft, 'STR_ZRBITE', False);
      Assert.AreEqual(2, FControl.Popups.Count);
      Assert.IsTrue(FControl.Popups[0] is TXcomCraftErrorState);
      Assert.IsTrue(FControl.Popups[1] is TXcomCraftErrorState);
    finally
      LCraft.Free;
    end;
  finally
    LBase.Free;
    LRules.Free;
  end;
end;

procedure TTestXcomGeoscapePopups.DovrebbeIgnorareGliEventiSenzaGeoscape;
var
  LListener: IXcomGeoscapeEvents;
  LRules: TXcomRuleCraft;
  LCraft: TXcomCraft;
begin
  LListener := TXcomPopupGeoscapeEvents.Create(FWorld.Game);
  LRules := TXcomRuleCraft.Create('STR_TRITON');
  try
    LCraft := TXcomCraft.Create(LRules, nil, 1);
    try
      LListener.LowFuel(LCraft);
      LListener.ItemsArriving;
      LListener.CraftPatrolling(LCraft);
      Assert.AreEqual(0, FControl.Popups.Count);
    finally
      LCraft.Free;
    end;
  finally
    LRules.Free;
  end;
end;

procedure TTestXcomGeoscapePopups.DovrebbeUsareIlNomeDelBersaglioNelNome;
var
  LRules: TXcomRuleCraft;
  LCraft: TXcomCraft;
begin
  LRules := TXcomRuleCraft.Create('STR_TRITON');
  try
    LCraft := TXcomCraft.Create(LRules, nil, 7);
    try
      LCraft.Name := 'Nautilus';
      Assert.AreEqual('Nautilus', TXcomTargetNames.Name(LCraft, FWorld.Game.Language));
      LCraft.Name := '';
      Assert.AreNotEqual('Nautilus', TXcomTargetNames.Name(LCraft, FWorld.Game.Language));
    finally
      LCraft.Free;
    end;
  finally
    LRules.Free;
  end;
end;

procedure TTestXcomGeoscapePopups.DovrebbeUsareIlNomeDiBaseSenzaNomePredefinito;
var
  LBase: TXcomBase;
begin
  LBase := TXcomBase.Create;
  try
    Assert.AreEqual('', TXcomTargetNames.Name(LBase, FWorld.Game.Language), 'una base senza nome non ha nome predefinito');
    LBase.Name := 'Base 2';
    Assert.AreEqual('Base 2', TXcomTargetNames.Name(LBase, FWorld.Game.Language));
  finally
    LBase.Free;
  end;
end;

procedure TTestXcomGeoscapePopups.DovrebbeInoltrareIPassiDelTempoAllaSimulazioneInterna;
var
  LInner: TFakeSimulation;
  LInnerRef: IXcomGeoscapeSimulation;
  LSimulation: IXcomGeoscapeSimulation;
begin
  LInner := TFakeSimulation.Create;
  LInnerRef := LInner;
  LSimulation := TXcomPopupSimulation.Create(LInnerRef, TXcomPopupGeoscapeEvents.Create(FWorld.Game));
  LSimulation.Time1Month;
  LSimulation.Time1Day;
  LSimulation.Time1Hour;
  LSimulation.Time30Minutes;
  LSimulation.Time10Minutes;
  LSimulation.Time5Seconds;
  LSimulation.StartFirstMonth;
  Assert.AreEqual('1mo,1d,1h,30m,10m,5s,first,', LInner.Calls);
end;

procedure TTestXcomGeoscapePopups.DovrebbeInoltrareIlGeoscapeAgliEventi;
var
  LSimulation: IXcomGeoscapeSimulation;
  LAware: IXcomGeoscapeAware;
begin
  LSimulation := TXcomPopupSimulation.Create(TFakeSimulation.Create,
    TXcomPopupGeoscapeEvents.Create(FWorld.Game));
  Assert.IsTrue(Supports(LSimulation, IXcomGeoscapeAware, LAware));
  LAware.AttachGeoscape(FControlRef);
  Assert.AreEqual(0, FControl.TimerResets, 'collegarsi non cambia il tempo');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomGeoscapePopups);

end.
