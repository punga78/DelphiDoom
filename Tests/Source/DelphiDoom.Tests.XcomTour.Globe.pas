{******************************************************************************}
{                                                                              }
{  DelphiDoom: the targets of the globe of the geoscape of OpenXcom (a craft   }
{  in flight, a base, a waypoint, an alien base), the rotation of the globe    }
{  and the popups of the workshop, on the game the program composes            }
{                                                                              }
{  This program is free software; you can redistribute it and/or modify it     }
{  under the terms of the GNU General Public License, version 3 or later.      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomTour.Globe;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.XcomSave.Craft, DelphiDoom.Tests.XcomTour.World;

type
  /// <summary>
  ///   A new game whose second craft (BARRACUDA-1) is sent to a point of the globe. The tests are ignored when the
  ///   data of the game is not there
  /// </summary>
  [TestFixture]
  [Category('xcom-tour')]
  TTestXcomTourGlobe = class(TObject)
  strict private
    FWorld: TXcomTourWorld;
    function Ready: Boolean;
    function Craft: TXcomCraft;
    /// <summary>BARRACUDA-1 leaves the base for a waypoint; the time stays at five seconds</summary>
    procedure SendCraft;
    /// <summary>Clicks the craft in flight on the globe and chooses it among the targets under the mouse</summary>
    procedure OpenCraftInFlight;
    /// <summary>Lets the days pass until the state on top is of the class (closing the other popups with Esc)</summary>
    function RunUntil(const AClass: string; ASpeedY, ATurns: Integer): Boolean;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeRichiamareAllaBaseUnVelivoloInVolo;
    [Test]
    procedure DovrebbeMettereInPattugliaUnVelivoloInVolo;
    [Test]
    procedure DovrebbeDareUnNuovoBersaglioAUnVelivoloInVolo;
    [Test]
    procedure DovrebbeLasciareIlVelivoloSullaSuaRottaConCancel;
    [Test]
    procedure DovrebbeAprireLIntercettazioneDallaBaseSulGlobo;
    [Test]
    procedure DovrebbeMostrareIlPuntoDiRottaEMandarciUnAltroVelivolo;
    [TestCase('su', '555,336,0,-1')]
    [TestCase('giu', '555,386,0,1')]
    [TestCase('sinistra', '530,362,-1,0')]
    [TestCase('destra', '578,362,1,0')]
    procedure DovrebbeRuotareIlGloboFinoAlRilascioDellaFreccia(AX, AY, ALongitude, ALatitude: Integer);
    [Test]
    procedure DovrebbeRuotareEIngrandireIlGloboNellaSceltaDellaBaseNuova;
    [Test]
    procedure DovrebbeCentrareIlGloboSullaBaseAlienaScoperta;
    [Test]
    procedure DovrebbeAnnunciareLaProduzioneFinitaEAprireLOfficina;
    [Test]
    procedure DovrebbeAnnunciareLaRicercaCheServePerUnArma;
  end;

implementation

uses
  System.Math, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomSave.Production,
  DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomGeoscape.GeoscapeState, DelphiDoom.XcomGeoscape.AlienBaseState,
  DelphiDoom.XcomGeoscape.ResearchRequiredState;

const
  GEOSCAPE = 'TXcomGeoscapeState';
  CRAFT_STATE = 'TXcomGeoscapeCraftState';
  SPEED_1_HOUR_Y = 293;

procedure TTestXcomTourGlobe.Setup;
begin
  FWorld := TXcomTourWorld.Create;
end;

procedure TTestXcomTourGlobe.TearDown;
begin
  FWorld.Free;
end;

function TTestXcomTourGlobe.Ready: Boolean;
begin
  Result := FWorld.HasData;
  if Result then
    FWorld.StartNewGame
  else
    Assert.Pass('i dati di TFTD non ci sono');
end;

function TTestXcomTourGlobe.Craft: TXcomCraft;
begin
  Result := FWorld.FirstBase.Crafts[1];
end;

procedure TTestXcomTourGlobe.SendCraft;
begin
  FWorld.Click(TOUR_GEO_BUTTON_X, TOUR_INTERCEPT_Y);
  FWorld.ClickRow('BARRACUDA-1', 100);
  Assert.AreEqual('TXcomSelectDestinationState', FWorld.Top);
  FWorld.Click(300, 150);
  FWorld.Key(XCOM_KEY_RETURN);
  Assert.AreEqual(GEOSCAPE, FWorld.Top);
  FWorld.Wait(1000);
  Assert.AreEqual('STR_OUT', Craft.Status);
  Assert.IsNotNull(Craft.Destination);
end;

procedure TTestXcomTourGlobe.OpenCraftInFlight;
var
  LX, LY: Integer;
begin
  FWorld.TargetPoint(Craft, LX, LY);
  FWorld.Click(LX, LY);
  // near its base the craft shares the point with it
  if FWorld.Top = 'TXcomMultipleTargetsState' then
    FWorld.ClickButton('BARRACUDA-1');
  Assert.AreEqual(CRAFT_STATE, FWorld.Top);
end;

function TTestXcomTourGlobe.RunUntil(const AClass: string; ASpeedY, ATurns: Integer): Boolean;
var
  LTurn: Integer;
begin
  for LTurn := 1 to ATurns do
  begin
    FWorld.Click(608, ASpeedY);
    FWorld.Wait(1500);
    if FWorld.Top = AClass then
      Exit(True);
    if FWorld.Top <> GEOSCAPE then
      FWorld.Key(XCOM_KEY_ESCAPE);
  end;
  Result := False;
end;

procedure TTestXcomTourGlobe.DovrebbeRichiamareAllaBaseUnVelivoloInVolo;
begin
  if not Ready then
    Exit;
  SendCraft;
  OpenCraftInFlight;
  FWorld.ClickButton('RETURN TO BASE');
  Assert.AreEqual(GEOSCAPE, FWorld.Top);
  // the base is a moment away: the craft is back and refuels
  Assert.AreEqual('STR_REFUELLING', Craft.Status, 'il velivolo richiamato rientra alla base');
  Assert.AreEqual(0, FWorld.Save.Waypoints.Count, 'il punto di rotta che nessuno segue sparisce');
end;

procedure TTestXcomTourGlobe.DovrebbeMettereInPattugliaUnVelivoloInVolo;
begin
  if not Ready then
    Exit;
  SendCraft;
  OpenCraftInFlight;
  FWorld.ClickButton('PATROL');
  Assert.AreEqual(GEOSCAPE, FWorld.Top);
  Assert.IsNull(Craft.Destination, 'in pattuglia il velivolo non ha una destinazione');
  Assert.AreEqual('STR_OUT', Craft.Status);
end;

procedure TTestXcomTourGlobe.DovrebbeDareUnNuovoBersaglioAUnVelivoloInVolo;
var
  LOld: TObject;
begin
  if not Ready then
    Exit;
  SendCraft;
  LOld := Craft.Destination;
  OpenCraftInFlight;
  FWorld.ClickButton('SELECT NEW TARGET');
  Assert.AreEqual('TXcomSelectDestinationState', FWorld.Top);
  FWorld.Click(120, 260);
  Assert.AreEqual('TXcomConfirmDestinationState', FWorld.Top);
  FWorld.Key(XCOM_KEY_RETURN);
  Assert.AreEqual(GEOSCAPE, FWorld.Top);
  Assert.IsNotNull(Craft.Destination);
  Assert.AreNotSame(LOld, Craft.Destination, 'il velivolo ha un punto di rotta nuovo');
end;

procedure TTestXcomTourGlobe.DovrebbeLasciareIlVelivoloSullaSuaRottaConCancel;
var
  LOld: TObject;
begin
  if not Ready then
    Exit;
  SendCraft;
  LOld := Craft.Destination;
  OpenCraftInFlight;
  Assert.IsTrue(FWorld.Shows('BARRACUDA-1'), 'la finestra ha il nome del velivolo: ' + FWorld.Describe);
  FWorld.ClickButton('CANCEL');
  Assert.AreEqual(GEOSCAPE, FWorld.Top);
  Assert.AreSame(LOld, Craft.Destination);
end;

procedure TTestXcomTourGlobe.DovrebbeAprireLIntercettazioneDallaBaseSulGlobo;
var
  LX, LY: Integer;
begin
  if not Ready then
    Exit;
  FWorld.TargetPoint(FWorld.FirstBase, LX, LY);
  FWorld.Click(LX, LY);
  Assert.AreEqual('TXcomInterceptState', FWorld.Top, 'un clic sulla base elenca i suoi velivoli');
  Assert.IsTrue(FWorld.FindRow('BARRACUDA-2', LY) >= 0);
  FWorld.ClickButton('Cancel');
  Assert.AreEqual(GEOSCAPE, FWorld.Top);
end;

procedure TTestXcomTourGlobe.DovrebbeMostrareIlPuntoDiRottaEMandarciUnAltroVelivolo;
var
  LX, LY: Integer;
begin
  if not Ready then
    Exit;
  SendCraft;
  Assert.AreEqual(1, FWorld.Save.Waypoints.Count);
  FWorld.TargetPoint(FWorld.Save.Waypoints[0], LX, LY);
  FWorld.Click(LX, LY);
  Assert.AreEqual('TXcomTargetInfoState', FWorld.Top, 'un clic sul punto di rotta dice chi ci sta andando');
  Assert.IsTrue(FWorld.Shows('BARRACUDA-1'), FWorld.Describe);
  FWorld.ClickButton('INTERCEPT');
  Assert.AreEqual('TXcomInterceptState', FWorld.Top);
  FWorld.ClickRow('BARRACUDA-2', 100);
  Assert.AreEqual('TXcomConfirmDestinationState', FWorld.Top, 'il secondo velivolo va allo stesso punto');
  FWorld.Key(XCOM_KEY_RETURN);
  FWorld.Wait(500);
  Assert.AreSame(FWorld.Save.Waypoints[0], FWorld.FirstBase.Crafts[2].Destination);
end;

procedure TTestXcomTourGlobe.DovrebbeRuotareIlGloboFinoAlRilascioDellaFreccia(AX, AY, ALongitude, ALatitude: Integer);
var
  LLongitude, LLatitude: Double;
begin
  if not Ready then
    Exit;
  LLongitude := FWorld.Globe.CenterLongitude;
  LLatitude := FWorld.Globe.CenterLatitude;
  FWorld.Press(AX, AY);
  FWorld.Wait(300);
  if ALongitude <> 0 then
    Assert.AreEqual(ALongitude, Integer(Sign(FWorld.Globe.CenterLongitude - LLongitude)), 'il globo gira in longitudine')
  else
    Assert.AreEqual(ALatitude, Integer(Sign(FWorld.Globe.CenterLatitude - LLatitude)), 'il globo gira in latitudine');
  FWorld.Release(AX, AY);
  LLongitude := FWorld.Globe.CenterLongitude;
  LLatitude := FWorld.Globe.CenterLatitude;
  FWorld.Wait(300);
  Assert.AreEqual(LLongitude, FWorld.Globe.CenterLongitude, 1E-9, 'al rilascio il globo si ferma');
  Assert.AreEqual(LLatitude, FWorld.Globe.CenterLatitude, 1E-9);
end;

procedure TTestXcomTourGlobe.DovrebbeRuotareEIngrandireIlGloboNellaSceltaDellaBaseNuova;
var
  LGlobe: TXcomGeoscapeState;
  LLongitude, LLatitude: Double;
  LZoom: Integer;
begin
  if not Ready then
    Exit;
  LGlobe := FWorld.Game.TopState as TXcomGeoscapeState;
  FWorld.Click(TOUR_GEO_BUTTON_X, TOUR_BASES_Y);
  FWorld.Click(TOUR_BASE_BUTTON_X, TOUR_NEW_BASE_Y);
  Assert.AreEqual('TXcomBuildNewBaseState', FWorld.Top);
  LLongitude := LGlobe.Globe.CenterLongitude;
  LLatitude := LGlobe.Globe.CenterLatitude;
  LZoom := LGlobe.Globe.Zoom;
  // the same arrows of the geoscape, under the window of the new base
  FWorld.Press(578, 362);
  FWorld.Wait(300);
  FWorld.Release(578, 362);
  Assert.AreNotEqual(LLongitude, LGlobe.Globe.CenterLongitude, 1E-9, 'la freccia a destra gira il globo');
  LLongitude := LGlobe.Globe.CenterLongitude;
  FWorld.Press(530, 362);
  FWorld.Wait(300);
  FWorld.Release(530, 362);
  Assert.AreNotEqual(LLongitude, LGlobe.Globe.CenterLongitude, 1E-9, 'e quella a sinistra');
  FWorld.Press(555, 336);
  FWorld.Wait(300);
  FWorld.Release(555, 336);
  Assert.AreNotEqual(LLatitude, LGlobe.Globe.CenterLatitude, 1E-9, 'la freccia in su');
  LLatitude := LGlobe.Globe.CenterLatitude;
  FWorld.Press(555, 386);
  FWorld.Wait(300);
  FWorld.Release(555, 386);
  Assert.AreNotEqual(LLatitude, LGlobe.Globe.CenterLatitude, 1E-9, 'e quella in giu''');
  FWorld.Click(613, 335);
  Assert.AreEqual(LZoom + 1, LGlobe.Globe.Zoom, 'lo zoom avvicina');
  FWorld.Click(613, 381);
  Assert.AreEqual(LZoom, LGlobe.Globe.Zoom, 'e allontana');
  Assert.AreEqual('TXcomBuildNewBaseState', FWorld.Top);
  FWorld.ClickButton('Cancel');
  Assert.AreEqual(GEOSCAPE, FWorld.Top, 'Cancel torna al geoscape');
end;

procedure TTestXcomTourGlobe.DovrebbeCentrareIlGloboSullaBaseAlienaScoperta;
var
  LGeoscape: TXcomGeoscapeState;
begin
  if not (FWorld.HasData and FWorld.LoadMission('alienbase')) then
  begin
    Assert.Pass('i dati di TFTD o il salvataggio non ci sono');
    Exit;
  end;
  if FWorld.Top <> GEOSCAPE then
    FWorld.Key(XCOM_KEY_ESCAPE);
  Assert.AreEqual(GEOSCAPE, FWorld.Top);
  Assert.IsTrue(FWorld.Save.AlienBases.Count > 0, 'il salvataggio ha una base aliena');
  LGeoscape := FWorld.Game.TopState as TXcomGeoscapeState;
  // far from the base, then the popup of the discovery
  LGeoscape.Globe.Center(FWorld.Save.AlienBases[0].Longitude + 1.5, 0);
  LGeoscape.Control.Popup(TXcomAlienBaseState.Create(FWorld.Game, FWorld.Save.AlienBases[0], LGeoscape.Control));
  FWorld.Wait(500);
  Assert.AreEqual('TXcomAlienBaseState', FWorld.Top);
  FWorld.ClickButton('OK');
  Assert.AreEqual(GEOSCAPE, FWorld.Top);
  Assert.AreEqual(FWorld.Save.AlienBases[0].Longitude, LGeoscape.Globe.CenterLongitude, 1E-6,
    'OK porta il globo sulla base aliena');
  Assert.AreEqual(FWorld.Save.AlienBases[0].Latitude, LGeoscape.Globe.CenterLatitude, 1E-6);
end;

procedure TTestXcomTourGlobe.DovrebbeAnnunciareLaProduzioneFinitaEAprireLOfficina;
var
  LRuleset: TXcomRuleset;
  LProduction: TXcomProduction;
  LRequired: string;
  LPistols: Integer;
begin
  if not Ready then
    Exit;
  // one Gauss Pistol with every technician of the base, one hour from the end
  LRuleset := TXcomStrategy.Ruleset(FWorld.Game);
  for LRequired in LRuleset.Manufacture.Find('STR_GAUSS_PISTOL').Requirements do
    FWorld.Save.Discovered.Add(LRuleset.Research.Find(LRequired));
  LPistols := FWorld.FirstBase.StorageItems.GetItem('STR_GAUSS_PISTOL');
  LProduction := TXcomProduction.Create(LRuleset.Manufacture.Find('STR_GAUSS_PISTOL'), 1);
  LProduction.AssignedEngineers := FWorld.FirstBase.Engineers;
  FWorld.FirstBase.Engineers := 0;
  LProduction.TimeSpent := LProduction.Rules.ManufactureTime - LProduction.AssignedEngineers;
  FWorld.FirstBase.AddProduction(LProduction);
  Assert.IsTrue(RunUntil('TXcomProductionCompleteState', SPEED_1_HOUR_Y, 10), 'la produzione finisce');
  Assert.IsTrue(FWorld.Shows('Gauss Pistol'), FWorld.Describe);
  Assert.AreEqual(LPistols + 1, FWorld.FirstBase.StorageItems.GetItem('STR_GAUSS_PISTOL'), 'il prodotto e'' in magazzino');
  Assert.AreEqual(0, FWorld.FirstBase.Productions.Count);
  Assert.IsTrue(FWorld.FirstBase.Engineers > 0, 'i tecnici tornano liberi');
  // the second button goes to the workshop of the base
  FWorld.Click(396, 308);
  Assert.AreEqual('TXcomManufactureState', FWorld.Top, FWorld.Describe);
end;

procedure TTestXcomTourGlobe.DovrebbeAnnunciareLaRicercaCheServePerUnArma;
begin
  if not Ready then
    Exit;
  // what the end of a research shows when the weapon it gives has a clip that is still to be researched
  FWorld.Game.PushState(TXcomResearchRequiredState.Create(FWorld.Game, 'STR_SONIC_PISTOL', 'STR_PISTOL_POWER_CLIP'));
  FWorld.Wait(500);
  Assert.AreEqual('TXcomResearchRequiredState', FWorld.Top);
  Assert.IsTrue(FWorld.Shows('Sonic Pistol') and FWorld.Shows('Pistol Power Clip'),
    'il messaggio nomina l''arma e il caricatore: ' + FWorld.Describe);
  FWorld.ClickButton('OK');
  Assert.AreEqual(GEOSCAPE, FWorld.Top);
end;

end.
