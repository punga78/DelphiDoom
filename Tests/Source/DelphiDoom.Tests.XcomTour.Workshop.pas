{******************************************************************************}
{                                                                              }
{  DelphiDoom: the screens of the manufacture of the basescape of OpenXcom,   }
{  on the game the program composes                                            }
{                                                                              }
{  This program is free software; you can redistribute it and/or modify it     }
{  under the terms of the GNU General Public License, version 3 or later.      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomTour.Workshop;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.XcomSave.Production, DelphiDoom.Tests.XcomTour.World;

type
  /// <summary>
  ///   The manufacture of a new game: a first base has technicians and a workshop but no product, until a research
  ///   unlocks one. The tests are ignored when the data of the game is not there
  /// </summary>
  [TestFixture]
  [Category('xcom-tour')]
  TTestXcomTourWorkshop = class(TObject)
  strict private
    FWorld: TXcomTourWorld;
    /// <summary>A new game; AResearched: every research is done, so every product can be made</summary>
    function Ready(AResearched: Boolean): Boolean;
    procedure OpenManufacture;
    /// <summary>From the geoscape to the screen of a new production of the product</summary>
    procedure StartProduction(const AProduct: string);
    function Production: TXcomProduction;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeElencareSoloIProdottiSbloccatiDallaRicerca;
    [Test]
    procedure DovrebbeAvviareUnaProduzioneConTecniciEUnita;
    [Test]
    procedure DovrebbeRipetereLaFrecciaTenutaPremuta;
    [Test]
    procedure DovrebbeAssegnareTuttiITecniciColTastoDestroEConLaRotella;
    [Test]
    procedure DovrebbeProdurreSenzaFineEVendere;
    [Test]
    procedure DovrebbeFermareUnaProduzioneERenderITecnici;
    [Test]
    procedure DovrebbeRifiutareUnVelivoloSenzaMaterialiOSenzaHangar;
    [Test]
    procedure DovrebbeFiltrareIProdottiPerCategoria;
  end;

implementation

uses
  DelphiDoom.XcomEngine.Types, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomGeoscape.Strategy;

const
  BASESCAPE = 'TXcomBasescapeState';
  INFO = 'TXcomManufactureInfoState';
  /// <summary>The arrows of TXcomManufactureInfoState in the pixels of the window</summary>
  ENGINEER_X = 277;
  UNIT_X = 581;
  ARROW_UP_Y = 242;
  ARROW_DOWN_Y = 286;

procedure TTestXcomTourWorkshop.Setup;
begin
  FWorld := TXcomTourWorld.Create;
end;

procedure TTestXcomTourWorkshop.TearDown;
begin
  FWorld.Free;
end;

function TTestXcomTourWorkshop.Ready(AResearched: Boolean): Boolean;
var
  LRuleset: TXcomRuleset;
  LIndex: Integer;
begin
  Result := FWorld.HasData;
  if not Result then
    Assert.Pass('i dati di TFTD non ci sono');
  FWorld.StartNewGame;
  if AResearched then
  begin
    LRuleset := TXcomStrategy.Ruleset(FWorld.Game);
    for LIndex := 0 to LRuleset.Research.Count - 1 do
      if not FWorld.Save.Discovered.Contains(LRuleset.Research.Rule(LIndex)) then
        FWorld.Save.Discovered.Add(LRuleset.Research.Rule(LIndex));
  end;
end;

procedure TTestXcomTourWorkshop.OpenManufacture;
begin
  FWorld.Click(TOUR_GEO_BUTTON_X, TOUR_BASES_Y);
  Assert.AreEqual(BASESCAPE, FWorld.Top);
  FWorld.Click(TOUR_BASE_BUTTON_X, TOUR_MANUFACTURE_Y);
  Assert.AreEqual('TXcomManufactureState', FWorld.Top);
end;

procedure TTestXcomTourWorkshop.StartProduction(const AProduct: string);
begin
  OpenManufacture;
  FWorld.ClickButton('New Production');
  Assert.AreEqual('TXcomNewManufactureListState', FWorld.Top);
  FWorld.ClickRow(AProduct, 100);
  Assert.AreEqual('TXcomManufactureStartState', FWorld.Top);
  FWorld.ClickButton('START PRODUCTION');
  Assert.AreEqual(INFO, FWorld.Top);
end;

function TTestXcomTourWorkshop.Production: TXcomProduction;
begin
  Assert.AreEqual(1, FWorld.FirstBase.Productions.Count, 'la base ha una produzione');
  Result := FWorld.FirstBase.Productions.First;
end;

procedure TTestXcomTourWorkshop.DovrebbeElencareSoloIProdottiSbloccatiDallaRicerca;
var
  LRuleset: TXcomRuleset;
  LRequired: string;
  LY: Integer;
begin
  if not Ready(False) then
    Exit;
  OpenManufacture;
  FWorld.ClickButton('New Production');
  Assert.AreEqual(-1, FWorld.FindRow('Gauss Pistol', LY), 'senza la ricerca il prodotto non c''e''');
  FWorld.ClickButton('OK');
  // the research that the product asks for is done
  LRuleset := TXcomStrategy.Ruleset(FWorld.Game);
  for LRequired in LRuleset.Manufacture.Find('STR_GAUSS_PISTOL').Requirements do
    FWorld.Save.Discovered.Add(LRuleset.Research.Find(LRequired));
  FWorld.ClickButton('New Production');
  Assert.IsTrue(FWorld.FindRow('Gauss Pistol', LY) >= 0, 'la ricerca sblocca il prodotto');
  Assert.AreEqual('Weapon', FWorld.RowCell('Gauss Pistol', 1));
end;

procedure TTestXcomTourWorkshop.DovrebbeAvviareUnaProduzioneConTecniciEUnita;
var
  LEngineers: Integer;
  LFunds: Int64;
  LY: Integer;
begin
  if not Ready(True) then
    Exit;
  LEngineers := FWorld.FirstBase.Engineers;
  LFunds := FWorld.Save.Funds;
  StartProduction('Gauss Pistol');
  FWorld.Click(ENGINEER_X, ARROW_UP_Y);
  FWorld.Click(ENGINEER_X, ARROW_UP_Y);
  FWorld.Click(ENGINEER_X, ARROW_UP_Y);
  FWorld.Click(ENGINEER_X, ARROW_DOWN_Y);
  FWorld.Click(UNIT_X, ARROW_UP_Y);
  FWorld.Click(UNIT_X, ARROW_UP_Y);
  FWorld.Click(UNIT_X, ARROW_DOWN_Y);
  FWorld.ClickButton('OK');
  Assert.AreEqual('TXcomNewManufactureListState', FWorld.Top, 'OK chiude anche la schermata dei requisiti');
  Assert.AreEqual(-1, FWorld.FindRow('Gauss Pistol', LY), 'un prodotto in produzione esce dalla lista');
  FWorld.ClickButton('OK');
  Assert.AreEqual(2, Production.AssignedEngineers);
  Assert.AreEqual(2, Production.AmountTotal);
  Assert.AreEqual(LEngineers - 2, FWorld.FirstBase.Engineers, 'i tecnici assegnati lasciano quelli liberi');
  Assert.IsTrue(FWorld.Save.Funds < LFunds, 'la prima unita'' e'' pagata all''avvio');
  Assert.AreEqual('2', FWorld.RowCell('Gauss Pistol', 1), 'la lista mostra i tecnici assegnati');
end;

procedure TTestXcomTourWorkshop.DovrebbeRipetereLaFrecciaTenutaPremuta;
var
  LEngineers: Integer;
begin
  if not Ready(True) then
    Exit;
  LEngineers := FWorld.FirstBase.Engineers;
  StartProduction('Gauss Pistol');
  FWorld.Press(ENGINEER_X, ARROW_UP_Y);
  FWorld.Wait(3000);
  FWorld.Release(ENGINEER_X, ARROW_UP_Y);
  Assert.AreEqual(LEngineers, Production.AssignedEngineers, 'la freccia tenuta premuta assegna tutti i tecnici');
  Assert.AreEqual(0, FWorld.FirstBase.Engineers);
  FWorld.Press(ENGINEER_X, ARROW_DOWN_Y);
  FWorld.Wait(3000);
  FWorld.Release(ENGINEER_X, ARROW_DOWN_Y);
  Assert.AreEqual(0, Production.AssignedEngineers, 'e quella in giu'' li toglie tutti');
  FWorld.Press(UNIT_X, ARROW_UP_Y);
  FWorld.Wait(1500);
  FWorld.Release(UNIT_X, ARROW_UP_Y);
  Assert.IsTrue(Production.AmountTotal > 3, Format('le unita'' salgono col tempo (%d)', [Production.AmountTotal]));
  FWorld.Press(UNIT_X, ARROW_DOWN_Y);
  FWorld.Wait(3000);
  FWorld.Release(UNIT_X, ARROW_DOWN_Y);
  Assert.AreEqual(1, Production.AmountTotal, 'una unita'' resta sempre');
end;

procedure TTestXcomTourWorkshop.DovrebbeAssegnareTuttiITecniciColTastoDestroEConLaRotella;
var
  LEngineers: Integer;
begin
  if not Ready(True) then
    Exit;
  LEngineers := FWorld.FirstBase.Engineers;
  // the wheel changes nothing until the option says by how much
  FWorld.Game.Options.ChangeValueByMouseWheel := 2;
  StartProduction('Gauss Pistol');
  FWorld.RightClick(ENGINEER_X, ARROW_UP_Y);
  Assert.AreEqual(LEngineers, Production.AssignedEngineers, 'il tasto destro assegna tutti i tecnici');
  FWorld.RightClick(ENGINEER_X, ARROW_DOWN_Y);
  Assert.AreEqual(0, Production.AssignedEngineers, 'e li toglie tutti');
  // the wheel over the left half changes the technicians, over the right half the units
  FWorld.Press(60, 180, XCOM_BUTTON_WHEELUP);
  FWorld.Release(60, 180, XCOM_BUTTON_WHEELUP);
  Assert.AreEqual(2, Production.AssignedEngineers, 'la rotella in su assegna tecnici');
  FWorld.Press(60, 180, XCOM_BUTTON_WHEELDOWN);
  FWorld.Release(60, 180, XCOM_BUTTON_WHEELDOWN);
  Assert.AreEqual(0, Production.AssignedEngineers, 'la rotella in giu'' li toglie');
  FWorld.Press(380, 180, XCOM_BUTTON_WHEELUP);
  FWorld.Release(380, 180, XCOM_BUTTON_WHEELUP);
  Assert.AreEqual(3, Production.AmountTotal, 'la rotella in su aggiunge unita''');
  FWorld.Press(380, 180, XCOM_BUTTON_WHEELDOWN);
  FWorld.Release(380, 180, XCOM_BUTTON_WHEELDOWN);
  Assert.AreEqual(1, Production.AmountTotal);
end;

procedure TTestXcomTourWorkshop.DovrebbeProdurreSenzaFineEVendere;
begin
  if not Ready(True) then
    Exit;
  StartProduction('Gauss Pistol');
  FWorld.RightClick(UNIT_X, ARROW_UP_Y);
  Assert.IsTrue(Production.InfiniteAmount, 'il tasto destro sulle unita'' produce senza fine');
  FWorld.Click(UNIT_X, ARROW_UP_Y);
  Assert.IsTrue(Production.InfiniteAmount, 'niente e'' piu'' di infinito');
  FWorld.Click(UNIT_X, ARROW_DOWN_Y);
  Assert.IsFalse(Production.InfiniteAmount, 'la freccia in giu'' torna a un numero');
  FWorld.RightClick(UNIT_X, ARROW_UP_Y);
  FWorld.ClickButton('SELL');
  FWorld.ClickButton('OK');
  Assert.IsTrue(Production.SellItems, 'le unita'' prodotte si vendono');
  Assert.IsTrue(Production.InfiniteAmount);
end;

procedure TTestXcomTourWorkshop.DovrebbeFermareUnaProduzioneERenderITecnici;
var
  LEngineers: Integer;
begin
  if not Ready(True) then
    Exit;
  LEngineers := FWorld.FirstBase.Engineers;
  StartProduction('Gauss Pistol');
  FWorld.Click(ENGINEER_X, ARROW_UP_Y);
  FWorld.ClickButton('OK');
  FWorld.ClickButton('OK');
  // the production in the list opens its screen again
  FWorld.ClickRow('Gauss Pistol', 100);
  Assert.AreEqual(INFO, FWorld.Top);
  FWorld.ClickButton('STOP PRODUCTION');
  Assert.AreEqual('TXcomManufactureState', FWorld.Top);
  Assert.AreEqual(0, FWorld.FirstBase.Productions.Count);
  Assert.AreEqual(LEngineers, FWorld.FirstBase.Engineers, 'i tecnici tornano liberi');
end;

procedure TTestXcomTourWorkshop.DovrebbeRifiutareUnVelivoloSenzaMaterialiOSenzaHangar;
begin
  if not Ready(True) then
    Exit;
  OpenManufacture;
  FWorld.ClickButton('New Production');
  FWorld.ClickRow('MANTA', 100);
  Assert.AreEqual('TXcomManufactureStartState', FWorld.Top);
  Assert.AreEqual('0', FWorld.RowCell('Aqua Plastics', 2), 'la base non ha i materiali');
  Assert.IsFalse(FWorld.HasButton('START PRODUCTION'), 'senza i materiali la produzione non parte');
  FWorld.ClickButton('CANCEL');
  FWorld.FirstBase.StorageItems.AddItem('STR_AQUA_PLASTICS', 65);
  FWorld.FirstBase.StorageItems.AddItem('STR_ION_BEAM_ACCELERATORS', 1);
  FWorld.FirstBase.StorageItems.AddItem('STR_MAGNETIC_NAVIGATION', 1);
  FWorld.ClickRow('MANTA', 100);
  Assert.AreEqual('65', FWorld.RowCell('Aqua Plastics', 2));
  FWorld.ClickButton('START PRODUCTION');
  Assert.AreEqual('TXcomErrorMessageState', FWorld.Top, 'la base non ha hangar liberi');
  Assert.AreEqual(0, FWorld.FirstBase.Productions.Count);
  FWorld.ClickButton('OK');
  FWorld.ClickButton('CANCEL');
  Assert.AreEqual('TXcomNewManufactureListState', FWorld.Top);
end;

procedure TTestXcomTourWorkshop.DovrebbeFiltrareIProdottiPerCategoria;
var
  LY: Integer;
begin
  if not Ready(True) then
    Exit;
  OpenManufacture;
  FWorld.ClickButton('New Production');
  // the combo box of the categories, then the tenth row of its list: "CRAFT"
  FWorld.Click(478, 108);
  FWorld.Click(400, 282);
  Assert.IsTrue(FWorld.FindRow('MANTA', LY) >= 0, 'i velivoli restano');
  Assert.AreEqual(-1, FWorld.FindRow('Gauss Pistol', LY), 'le armi no');
end;

end.
