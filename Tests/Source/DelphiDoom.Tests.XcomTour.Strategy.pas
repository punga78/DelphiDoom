{******************************************************************************}
{                                                                              }
{  DelphiDoom: the tour of the strategic game of OpenXcom (every button of     }
{  the geoscape and of the basescape, on the game the program composes)        }
{                                                                              }
{  This program is free software; you can redistribute it and/or modify it     }
{  under the terms of the GNU General Public License, version 3 or later.      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomTour.Strategy;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Tests.Xcom.Skip, DelphiDoom.Tests.XcomTour.World;

type
  /// <summary>
  ///   What a player does in the strategic game, with the clicks in the pixels of the 640 x 400 window: the tests do
  ///   nothing when the data of the game is not there
  /// </summary>
  [TestFixture]
  [Category('xcom-tour')]
  TTestXcomTourStrategy = class(TObject)
  strict private
    FWorld: TXcomTourWorld;
    function Ready: Boolean;
    procedure OpenBases;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeArrivareAlGeoscapeConLaPrimaBase;
    [TestCase('informazioni', '154,TXcomBaseInfoState')]
    [TestCase('soldati', '180,TXcomSoldiersState')]
    [TestCase('velivoli', '206,TXcomCraftsState')]
    [TestCase('strutture', '232,TXcomBuildFacilitiesState')]
    [TestCase('ricerca', '258,TXcomResearchState')]
    [TestCase('produzione', '284,TXcomManufactureState')]
    [TestCase('trasferimenti', '310,TXcomTransferBaseState')]
    [TestCase('acquisti', '336,TXcomPurchaseState')]
    [TestCase('vendite', '362,TXcomSellState')]
    procedure DovrebbeAprireEChiudereLaSchermataDelBasescape(AY: Integer; const AExpected: string);
    [Test]
    procedure DovrebbeTornareAlGeoscapeDalBasescape;
    [Test]
    procedure DovrebbePosareUnaStruttura;
    [Test]
    procedure DovrebbeAssegnareGliScienziatiAUnaRicerca;
    [Test]
    procedure DovrebbeComprareScienziati;
    [Test]
    procedure DovrebbeVendereUnOggetto;
    [Test]
    procedure DovrebbeCostruireUnaSecondaBaseConLAscensore;
    [TestCase('intercetta', '10,TXcomInterceptState')]
    [TestCase('grafici', '58,TXcomGraphsState')]
    [TestCase('opzioni', '106,TXcomPauseState')]
    [TestCase('finanziamenti', '130,TXcomFundingState')]
    procedure DovrebbeAprireEChiudereLaSchermataDelGeoscape(AY: Integer; const AExpected: string);
    [Test]
    procedure DovrebbeAprireLeSchermateDiUnVelivolo;
    [Test]
    procedure DovrebbeAprireLeSchermateDiUnSoldato;
    [Test]
    procedure DovrebbeAprireLeSchermateDelleInformazioniDellaBase;
    [Test]
    procedure DovrebbeSalvareECaricareLaPartita;
    [Test]
    procedure DovrebbeArrivareAlRapportoMensile;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.XcomEngine.Types;

const
  GEOSCAPE = 'TXcomGeoscapeState';
  BASESCAPE = 'TXcomBasescapeState';

procedure TTestXcomTourStrategy.Setup;
begin
  FWorld := TXcomTourWorld.Create;
end;

procedure TTestXcomTourStrategy.TearDown;
begin
  FWorld.Free;
end;

function TTestXcomTourStrategy.Ready: Boolean;
begin
  Result := FWorld.HasData;
  if Result then
    FWorld.StartNewGame
  else
    TXcomTestSkip.Ignore('i dati di TFTD non ci sono');
end;

procedure TTestXcomTourStrategy.OpenBases;
begin
  FWorld.Click(TOUR_GEO_BUTTON_X, TOUR_BASES_Y);
  Assert.AreEqual(BASESCAPE, FWorld.Top);
end;

procedure TTestXcomTourStrategy.DovrebbeArrivareAlGeoscapeConLaPrimaBase;
begin
  if not Ready then
    Exit;
  Assert.AreEqual(GEOSCAPE, FWorld.Top);
  Assert.AreEqual(1, FWorld.Save.Bases.Count);
  Assert.IsTrue(FWorld.FirstBase.Facilities.Count > 1, 'la prima base ha le sue strutture');
end;

procedure TTestXcomTourStrategy.DovrebbeAprireEChiudereLaSchermataDelBasescape(AY: Integer; const AExpected: string);
begin
  if not Ready then
    Exit;
  OpenBases;
  FWorld.Click(TOUR_BASE_BUTTON_X, AY);
  Assert.AreEqual(AExpected, FWorld.Top);
  FWorld.Key(XCOM_KEY_ESCAPE);
  Assert.AreEqual(BASESCAPE, FWorld.Top, 'Esc torna alla base');
end;

procedure TTestXcomTourStrategy.DovrebbeTornareAlGeoscapeDalBasescape;
begin
  if not Ready then
    Exit;
  OpenBases;
  FWorld.Click(TOUR_BASE_BUTTON_X, 388);
  Assert.AreEqual(GEOSCAPE, FWorld.Top);
end;

procedure TTestXcomTourStrategy.DovrebbePosareUnaStruttura;
var
  LFacilities: Integer;
  LFunds: Int64;
begin
  if not Ready then
    Exit;
  OpenBases;
  LFacilities := FWorld.FirstBase.Facilities.Count;
  LFunds := FWorld.Save.Funds;
  FWorld.Click(TOUR_BASE_BUTTON_X, TOUR_FACILITIES_Y);
  // Living Quarters, then the free square next to the ones of the base
  FWorld.Click(470, 136);
  Assert.AreEqual('TXcomPlaceFacilityState', FWorld.Top);
  FWorld.Click(288, 176);
  Assert.AreEqual(LFacilities + 1, FWorld.FirstBase.Facilities.Count);
  Assert.AreEqual(LFunds - 400000, FWorld.Save.Funds);
  Assert.AreEqual('TXcomBuildFacilitiesState', FWorld.Top, 'si torna alla lista delle strutture');
end;

procedure TTestXcomTourStrategy.DovrebbeAssegnareGliScienziatiAUnaRicerca;
var
  LScientists: Integer;
begin
  if not Ready then
    Exit;
  OpenBases;
  LScientists := FWorld.FirstBase.Scientists;
  FWorld.Click(TOUR_BASE_BUTTON_X, TOUR_RESEARCH_Y);
  FWorld.Click(160, 368);
  Assert.AreEqual('TXcomNewResearchListState', FWorld.Top);
  FWorld.Click(300, 140);
  Assert.AreEqual('TXcomResearchInfoState', FWorld.Top);
  FWorld.Click(402, 213);
  FWorld.Click(402, 213);
  FWorld.Click(428, 306);
  Assert.AreEqual(1, FWorld.FirstBase.Research.Count);
  Assert.AreEqual(LScientists - 2, FWorld.FirstBase.Scientists);
end;

procedure TTestXcomTourStrategy.DovrebbeComprareScienziati;
var
  LFunds: Int64;
  LTransfers: Integer;
begin
  if not Ready then
    Exit;
  OpenBases;
  LFunds := FWorld.Save.Funds;
  LTransfers := FWorld.FirstBase.Transfers.Count;
  FWorld.Click(TOUR_BASE_BUTTON_X, TOUR_PURCHASE_Y);
  FWorld.Click(480, 132);
  FWorld.Click(480, 132);
  FWorld.Click(160, 368);
  Assert.AreEqual(LFunds - 120000, FWorld.Save.Funds);
  Assert.AreEqual(LTransfers + 1, FWorld.FirstBase.Transfers.Count);
  Assert.AreEqual(BASESCAPE, FWorld.Top);
end;

procedure TTestXcomTourStrategy.DovrebbeVendereUnOggetto;
var
  LFunds: Int64;
begin
  if not Ready then
    Exit;
  OpenBases;
  LFunds := FWorld.Save.Funds;
  FWorld.Click(TOUR_BASE_BUTTON_X, TOUR_SELL_Y);
  // one Dart Gun
  FWorld.Click(390, 292);
  FWorld.Click(160, 368);
  Assert.AreEqual(LFunds + 600, FWorld.Save.Funds);
  Assert.AreEqual(BASESCAPE, FWorld.Top);
end;

procedure TTestXcomTourStrategy.DovrebbeCostruireUnaSecondaBaseConLAscensore;
begin
  if not Ready then
    Exit;
  OpenBases;
  FWorld.Click(TOUR_BASE_BUTTON_X, TOUR_NEW_BASE_Y);
  Assert.AreEqual('TXcomBuildNewBaseState', FWorld.Top);
  FWorld.Click(200, 150);
  Assert.AreEqual('TXcomConfirmNewBaseState', FWorld.Top);
  FWorld.Key(XCOM_KEY_RETURN);
  Assert.AreEqual('TXcomBaseNameState', FWorld.Top);
  FWorld.TypeText('cd');
  FWorld.Key(XCOM_KEY_RETURN);
  Assert.AreEqual('TXcomPlaceLiftState', FWorld.Top, 'la base nuova chiede dove va l''ascensore');
  FWorld.Click(160, 176);
  Assert.AreEqual(2, FWorld.Save.Bases.Count);
  Assert.AreEqual(1, FWorld.Save.Bases[1].Facilities.Count, 'la base nuova ha l''ascensore');
  Assert.AreEqual(BASESCAPE, FWorld.Top);
end;

procedure TTestXcomTourStrategy.DovrebbeAprireEChiudereLaSchermataDelGeoscape(AY: Integer; const AExpected: string);
begin
  if not Ready then
    Exit;
  FWorld.Click(TOUR_GEO_BUTTON_X, AY);
  Assert.AreEqual(AExpected, FWorld.Top);
  FWorld.Key(XCOM_KEY_ESCAPE);
  Assert.AreEqual(GEOSCAPE, FWorld.Top, 'Esc torna al geoscape');
end;

procedure TTestXcomTourStrategy.DovrebbeAprireLeSchermateDiUnVelivolo;
begin
  if not Ready then
    Exit;
  OpenBases;
  FWorld.Click(TOUR_BASE_BUTTON_X, TOUR_CRAFTS_Y);
  FWorld.Click(100, 122);
  Assert.AreEqual('TXcomCraftInfoState', FWorld.Top);
  FWorld.Click(90, 208);
  Assert.AreEqual('TXcomCraftSoldiersState', FWorld.Top);
  // the first soldier leaves the craft
  FWorld.Click(100, 88);
  FWorld.Key(XCOM_KEY_ESCAPE);
  FWorld.Click(90, 256);
  Assert.AreEqual('TXcomCraftEquipmentState', FWorld.Top);
  FWorld.Key(XCOM_KEY_ESCAPE);
  FWorld.Click(90, 304);
  Assert.AreEqual('TXcomCraftArmorState', FWorld.Top);
  FWorld.Click(100, 88);
  Assert.AreEqual('TXcomSoldierArmorState', FWorld.Top);
  FWorld.Key(XCOM_KEY_ESCAPE);
  FWorld.Key(XCOM_KEY_ESCAPE);
  Assert.AreEqual('TXcomCraftInfoState', FWorld.Top);
end;

procedure TTestXcomTourStrategy.DovrebbeAprireLeSchermateDiUnSoldato;
begin
  if not Ready then
    Exit;
  OpenBases;
  FWorld.Click(TOUR_BASE_BUTTON_X, TOUR_SOLDIERS_Y);
  FWorld.Click(100, 90);
  Assert.AreEqual('TXcomSoldierInfoState', FWorld.Top);
  FWorld.Click(573, 110);
  Assert.AreEqual('TXcomSoldierDiaryOverviewState', FWorld.Top);
  FWorld.Key(XCOM_KEY_ESCAPE);
  FWorld.Click(573, 80);
  Assert.AreEqual('TXcomSackSoldierState', FWorld.Top);
  FWorld.Key(XCOM_KEY_ESCAPE);
  FWorld.Key(XCOM_KEY_ESCAPE);
  Assert.AreEqual('TXcomSoldiersState', FWorld.Top);
  // the memorial and the statistics of the game
  FWorld.Click(124, 368);
  Assert.AreEqual('TXcomSoldierMemorialState', FWorld.Top);
  FWorld.Click(160, 368);
  Assert.AreEqual('TXcomStatisticsState', FWorld.Top);
  FWorld.Key(XCOM_KEY_RETURN);
  Assert.AreEqual('TXcomSoldierMemorialState', FWorld.Top, 'a partita in corso OK chiude le statistiche');
end;

procedure TTestXcomTourStrategy.DovrebbeAprireLeSchermateDelleInformazioniDellaBase;
begin
  if not Ready then
    Exit;
  OpenBases;
  FWorld.Click(TOUR_BASE_BUTTON_X, TOUR_BASE_INFO_Y);
  FWorld.Click(173, 373);
  Assert.AreEqual('TXcomTransfersState', FWorld.Top);
  FWorld.Key(XCOM_KEY_ESCAPE);
  FWorld.Click(344, 373);
  Assert.AreEqual('TXcomStoresState', FWorld.Top);
  FWorld.Key(XCOM_KEY_ESCAPE);
  FWorld.Click(527, 373);
  Assert.AreEqual('TXcomMonthlyCostsState', FWorld.Top);
  FWorld.Key(XCOM_KEY_ESCAPE);
  Assert.AreEqual('TXcomBaseInfoState', FWorld.Top);
end;

procedure TTestXcomTourStrategy.DovrebbeSalvareECaricareLaPartita;
var
  LFile: string;
begin
  if not Ready then
    Exit;
  FWorld.Click(TOUR_GEO_BUTTON_X, TOUR_OPTIONS_Y);
  FWorld.Click(256, 166);
  Assert.AreEqual('TXcomListSaveState', FWorld.Top);
  FWorld.Click(107, 93);
  FWorld.TypeText('uno');
  FWorld.Key(XCOM_KEY_RETURN);
  FWorld.Wait(1000);
  LFile := TPath.Combine(FWorld.UserFolder, 'xcom2\uno.sav');
  Assert.IsTrue(TFile.Exists(LFile), 'il salvataggio e'' nella cartella del giocatore');
  Assert.AreEqual(GEOSCAPE, FWorld.Top);
  FWorld.Click(TOUR_GEO_BUTTON_X, TOUR_OPTIONS_Y);
  FWorld.Click(256, 122);
  Assert.AreEqual('TXcomListLoadState', FWorld.Top);
  FWorld.Click(60, 93);
  FWorld.Wait(2000);
  Assert.AreEqual(GEOSCAPE, FWorld.Top);
  Assert.AreEqual(1, FWorld.Save.Bases.Count);
end;

procedure TTestXcomTourStrategy.DovrebbeArrivareAlRapportoMensile;
var
  LTurn: Integer;
  LReached: Boolean;
begin
  if not Ready then
    Exit;
  LReached := False;
  for LTurn := 1 to 60 do
  begin
    // 1 Day
    FWorld.Click(608, 293);
    FWorld.Wait(1500);
    if FWorld.Top = 'TXcomMonthlyReportState' then
    begin
      LReached := True;
      Break;
    end;
    // a popup of the month (a UFO, a site, a craft low on fuel): closed, the time goes on
    if FWorld.Top <> GEOSCAPE then
      FWorld.Key(XCOM_KEY_ESCAPE);
  end;
  Assert.IsTrue(LReached, 'il mese finisce col rapporto');
  Assert.AreEqual(2, FWorld.Save.Time.Month);
  FWorld.Key(XCOM_KEY_RETURN);
  Assert.AreNotEqual('TXcomMonthlyReportState', FWorld.Top, 'OK chiude il rapporto');
end;

end.
