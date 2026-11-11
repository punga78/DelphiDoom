{******************************************************************************}
{                                                                              }
{  DelphiDoom: the quantities of the transfers, of the sales and of the        }
{  purchases of the basescape of OpenXcom (arrows, limits of the base), on     }
{  the game the program composes                                               }
{                                                                              }
{  This program is free software; you can redistribute it and/or modify it     }
{  under the terms of the GNU General Public License, version 3 or later.      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomTour.Trade;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.XcomSave.Base, DelphiDoom.Tests.XcomTour.World;

type
  /// <summary>
  ///   The saved game with two bases of Tests\Data\XcomSave\variants: the first base has three soldiers, three
  ///   crafts, ten scientists and ten technicians. In the three lists the first arrow of a row adds, the second one
  ///   takes away. The tests are ignored when the data of the game is not there
  /// </summary>
  [TestFixture]
  [Category('xcom-tour')]
  TTestXcomTourTrade = class(TObject)
  strict private
    FWorld: TXcomTourWorld;
    function Ready: Boolean;
    function Source: TXcomBase;
    function Destination: TXcomBase;
    procedure OpenTransfer;
    procedure OpenBaseScreen(AY: Integer; const AExpected: string);
    /// <summary>Clicks the arrow that adds (AAdd) or takes away one of the row</summary>
    procedure Arrow(const ARow: string; AAdd: Boolean; AButton: Integer = 1);
    /// <summary>Holds the arrow of the row down for a time</summary>
    procedure HoldArrow(const ARow: string; AAdd: Boolean; AMilliseconds: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeTrasferirePersonaleVelivoloEOggetti;
    [Test]
    procedure DovrebbeCambiareLeQuantitaDelTrasferimentoConFrecceERotella;
    [Test]
    procedure DovrebbeRifiutareIlTrasferimentoSenzaAlloggi;
    [Test]
    procedure DovrebbeRifiutareIlTrasferimentoSenzaHangar;
    [Test]
    procedure DovrebbeRifiutareIlTrasferimentoSenzaMagazzino;
    [Test]
    procedure DovrebbeVenderePersonaleVelivoloEOggetti;
    [Test]
    procedure DovrebbeCambiareLeQuantitaDellaVenditaConFrecceERotella;
    [Test]
    procedure DovrebbeComprarePersonaleEOggetti;
    [Test]
    procedure DovrebbeRifiutareGliAcquistiOltreILimitiDellaBase;
    [Test]
    procedure DovrebbeFiltrareGliAcquistiPerCategoria;
  end;

implementation

uses
  DelphiDoom.XcomEngine.Types, DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomMod.Ruleset,
  DelphiDoom.XcomSave.Soldier, DelphiDoom.XcomSave.Craft, DelphiDoom.XcomSave.Transfer;

const
  BASESCAPE = 'TXcomBasescapeState';
  ERROR = 'TXcomErrorMessageState';

procedure TTestXcomTourTrade.Setup;
begin
  FWorld := TXcomTourWorld.Create;
end;

procedure TTestXcomTourTrade.TearDown;
begin
  FWorld.Free;
end;

function TTestXcomTourTrade.Ready: Boolean;
begin
  Result := FWorld.HasData and FWorld.LoadVariant('save02_twobases');
  if not Result then
    Assert.Pass('i dati di TFTD o il salvataggio non ci sono');
end;

function TTestXcomTourTrade.Source: TXcomBase;
begin
  Result := FWorld.Save.Bases[0];
end;

function TTestXcomTourTrade.Destination: TXcomBase;
begin
  Result := FWorld.Save.Bases[1];
end;

procedure TTestXcomTourTrade.OpenBaseScreen(AY: Integer; const AExpected: string);
begin
  FWorld.Click(TOUR_GEO_BUTTON_X, TOUR_BASES_Y);
  Assert.AreEqual(BASESCAPE, FWorld.Top);
  FWorld.Click(TOUR_BASE_BUTTON_X, AY);
  Assert.AreEqual(AExpected, FWorld.Top);
end;

procedure TTestXcomTourTrade.OpenTransfer;
begin
  OpenBaseScreen(TOUR_TRANSFER_Y, 'TXcomTransferBaseState');
  FWorld.ClickRow(Destination.Name, 150);
  Assert.AreEqual('TXcomTransferItemsState', FWorld.Top);
end;

procedure TTestXcomTourTrade.Arrow(const ARow: string; AAdd: Boolean; AButton: Integer);
begin
  FWorld.ClickRow(ARow, FWorld.RowArrowX(not AAdd), AButton);
end;

procedure TTestXcomTourTrade.HoldArrow(const ARow: string; AAdd: Boolean; AMilliseconds: Integer);
var
  LY: Integer;
begin
  Assert.IsTrue(FWorld.FindRow(ARow, LY) >= 0, 'la riga ' + ARow);
  FWorld.Press(FWorld.RowArrowX(not AAdd), LY);
  FWorld.Wait(AMilliseconds);
  FWorld.Release(FWorld.RowArrowX(not AAdd), LY);
end;

procedure TTestXcomTourTrade.DovrebbeTrasferirePersonaleVelivoloEOggetti;
var
  LSoldier: TXcomSoldier;
  LCraft: TXcomCraft;
  LTransfer: TXcomTransfer;
  LScientists, LGuns, LSoldiers, LCrafts, LSent: Integer;
  LFunds: Int64;
begin
  if not Ready then
    Exit;
  LSoldier := Source.Soldiers[0];
  LCraft := Source.Crafts[2];
  LScientists := Source.Scientists;
  LGuns := Source.StorageItems.GetItem('STR_DART_PISTOL');
  LSoldiers := Source.Soldiers.Count;
  LCrafts := Source.Crafts.Count;
  LFunds := FWorld.Save.Funds;
  OpenTransfer;
  Arrow(LSoldier.Name, True);
  Arrow('BARRACUDA-2', True);
  Arrow('Scientist', True);
  Arrow('Scientist', True);
  Arrow('Dart Gun', True);
  Assert.AreEqual('2', FWorld.RowCell('Scientist', 2), 'la quantita'' da trasferire');
  Assert.AreEqual(IntToStr(LScientists - 2), FWorld.RowCell('Scientist', 1), 'quella che resta');
  FWorld.ClickButton('Transfer');
  Assert.AreEqual('TXcomTransferConfirmState', FWorld.Top);
  FWorld.Key(XCOM_KEY_RETURN);
  Assert.AreEqual(BASESCAPE, FWorld.Top, 'la conferma torna alla base');
  Assert.AreEqual(LSoldiers - 1, Source.Soldiers.Count, 'il soldato lascia la base');
  Assert.AreEqual(LCrafts - 1, Source.Crafts.Count, 'il velivolo lascia la base');
  Assert.AreEqual(LScientists - 2, Source.Scientists);
  Assert.AreEqual(LGuns - 1, Source.StorageItems.GetItem('STR_DART_PISTOL'));
  Assert.IsTrue(FWorld.Save.Funds < LFunds, 'il trasferimento si paga');
  LSent := 0;
  for LTransfer in Destination.Transfers do
  begin
    if LTransfer.Soldier = LSoldier then
      Inc(LSent);
    if LTransfer.Craft = LCraft then
      Inc(LSent);
    if LTransfer.Scientists = 2 then
      Inc(LSent);
  end;
  Assert.AreEqual(3, LSent, 'soldato, velivolo e scienziati sono in viaggio verso l''altra base');
end;

procedure TTestXcomTourTrade.DovrebbeCambiareLeQuantitaDelTrasferimentoConFrecceERotella;
var
  LY: Integer;
begin
  if not Ready then
    Exit;
  FWorld.Game.Options.ChangeValueByMouseWheel := 2;
  OpenTransfer;
  HoldArrow('Technician', True, 1000);
  Assert.IsTrue(StrToInt(FWorld.RowCell('Technician', 2)) > 5, 'la freccia tenuta premuta aggiunge col tempo: ' +
    FWorld.RowCell('Technician', 2));
  HoldArrow('Technician', False, 3000);
  Assert.AreEqual('0', FWorld.RowCell('Technician', 2), 'e toglie');
  Arrow('Technician', True, XCOM_BUTTON_RIGHT);
  Assert.AreEqual('0', FWorld.RowCell('Technician', 1), 'il tasto destro li manda tutti');
  Arrow('Technician', False);
  Assert.AreEqual('1', FWorld.RowCell('Technician', 1));
  Arrow('Technician', False, XCOM_BUTTON_RIGHT);
  Assert.AreEqual('0', FWorld.RowCell('Technician', 2), 'e li tiene tutti');
  // the wheel over the arrows
  Assert.IsTrue(FWorld.FindRow('Technician', LY) >= 0);
  FWorld.Press(FWorld.RowArrowX(False), LY, XCOM_BUTTON_WHEELUP);
  FWorld.Release(FWorld.RowArrowX(False), LY, XCOM_BUTTON_WHEELUP);
  Assert.AreEqual('2', FWorld.RowCell('Technician', 2), 'la rotella in su aggiunge');
  FWorld.Press(FWorld.RowArrowX(False), LY, XCOM_BUTTON_WHEELDOWN);
  FWorld.Release(FWorld.RowArrowX(False), LY, XCOM_BUTTON_WHEELDOWN);
  Assert.AreEqual('0', FWorld.RowCell('Technician', 2), 'la rotella in giu'' toglie');
  // nothing chosen: Transfer has nothing to confirm
  Arrow('BARRACUDA-1', True);
  Arrow('BARRACUDA-1', False);
  Arrow('Dart Gun', True);
  Arrow('Dart Gun', False);
  Assert.AreEqual('0', FWorld.RowCell('Dart Gun', 2));
  FWorld.ClickButton('Cancel');
  Assert.AreEqual(BASESCAPE, FWorld.Top, 'Cancel chiude anche la scelta della base');
  Assert.AreEqual(0, Destination.Transfers.Count, 'e non trasferisce nulla');
end;

procedure TTestXcomTourTrade.DovrebbeRifiutareIlTrasferimentoSenzaAlloggi;
begin
  if not Ready then
    Exit;
  // the other base is full of people
  Destination.Scientists := 10000;
  OpenTransfer;
  Arrow('Scientist', True);
  Assert.AreEqual(ERROR, FWorld.Top, 'senza alloggi liberi il personale non parte');
  FWorld.ClickButton('OK');
  Assert.AreEqual('0', FWorld.RowCell('Scientist', 2));
  Arrow(Source.Soldiers[0].Name, True);
  Assert.AreEqual(ERROR, FWorld.Top, 'nemmeno un soldato');
  FWorld.ClickButton('OK');
  Arrow('TRITON-1', True);
  Assert.AreEqual(ERROR, FWorld.Top, 'ne'' un velivolo col suo equipaggio');
end;

procedure TTestXcomTourTrade.DovrebbeRifiutareIlTrasferimentoSenzaHangar;
var
  LIndex: Integer;
  LRuleset: TXcomRuleset;
begin
  if not Ready then
    Exit;
  // the other base loses its hangars
  LRuleset := TXcomStrategy.Ruleset(FWorld.Game);
  for LIndex := Destination.Facilities.Count - 1 downto 0 do
    if LRuleset.Facilities.Find(Destination.Facilities[LIndex].Rules.FacilityType).Crafts > 0 then
      Destination.Facilities.Delete(LIndex);
  OpenTransfer;
  Arrow('BARRACUDA-1', True);
  Assert.AreEqual(ERROR, FWorld.Top, 'senza hangar liberi il velivolo non parte');
  FWorld.ClickButton('OK');
  Assert.AreEqual('TXcomTransferItemsState', FWorld.Top);
end;

procedure TTestXcomTourTrade.DovrebbeRifiutareIlTrasferimentoSenzaMagazzino;
begin
  if not Ready then
    Exit;
  Destination.StorageItems.AddItem('STR_DART_PISTOL', 100000);
  OpenTransfer;
  Arrow('Dart Gun', True);
  Assert.AreEqual(ERROR, FWorld.Top, 'senza spazio in magazzino gli oggetti non partono');
  FWorld.ClickButton('OK');
  Assert.AreEqual('0', FWorld.RowCell('Dart Gun', 2));
end;

procedure TTestXcomTourTrade.DovrebbeVenderePersonaleVelivoloEOggetti;
var
  LSoldier: string;
  LScientists, LGuns, LSoldiers, LCrafts: Integer;
  LFunds: Int64;
begin
  if not Ready then
    Exit;
  // a soldier that is not on a craft can be sacked from the list of the sales
  Source.Soldiers[0].Craft := nil;
  LSoldier := Source.Soldiers[0].Name;
  LScientists := Source.Scientists;
  LGuns := Source.StorageItems.GetItem('STR_DART_PISTOL');
  LSoldiers := Source.Soldiers.Count;
  LCrafts := Source.Crafts.Count;
  LFunds := FWorld.Save.Funds;
  OpenBaseScreen(TOUR_SELL_Y, 'TXcomSellState');
  Arrow(LSoldier, True);
  Arrow('BARRACUDA-2', True);
  Arrow('Scientist', True);
  Arrow('Technician', True);
  Arrow('Dart Gun', True);
  Arrow('Dart Gun', True);
  FWorld.ClickButton('Sell/Sack');
  Assert.AreEqual(BASESCAPE, FWorld.Top);
  Assert.AreEqual(LSoldiers - 1, Source.Soldiers.Count, 'il soldato e'' licenziato');
  Assert.AreEqual(LCrafts - 1, Source.Crafts.Count, 'il velivolo e'' venduto');
  Assert.AreEqual(LScientists - 1, Source.Scientists);
  Assert.AreEqual(LGuns - 2, Source.StorageItems.GetItem('STR_DART_PISTOL'));
  Assert.IsTrue(FWorld.Save.Funds > LFunds, 'la vendita porta fondi');
end;

procedure TTestXcomTourTrade.DovrebbeCambiareLeQuantitaDellaVenditaConFrecceERotella;
var
  LY: Integer;
  LFunds: Int64;
begin
  if not Ready then
    Exit;
  FWorld.Game.Options.ChangeValueByMouseWheel := 2;
  LFunds := FWorld.Save.Funds;
  OpenBaseScreen(TOUR_SELL_Y, 'TXcomSellState');
  HoldArrow('Technician', True, 1000);
  Assert.IsTrue(StrToInt(FWorld.RowCell('Technician', 2)) > 5, 'la freccia tenuta premuta aggiunge col tempo');
  HoldArrow('Technician', False, 3000);
  Assert.AreEqual('0', FWorld.RowCell('Technician', 2));
  Arrow('Technician', True, XCOM_BUTTON_RIGHT);
  Assert.AreEqual('0', FWorld.RowCell('Technician', 1), 'il tasto destro li vende tutti');
  Arrow('Technician', False, XCOM_BUTTON_RIGHT);
  Assert.AreEqual('0', FWorld.RowCell('Technician', 2));
  Assert.IsTrue(FWorld.FindRow('Technician', LY) >= 0);
  FWorld.Press(FWorld.RowArrowX(False), LY, XCOM_BUTTON_WHEELUP);
  FWorld.Release(FWorld.RowArrowX(False), LY, XCOM_BUTTON_WHEELUP);
  Assert.AreEqual('2', FWorld.RowCell('Technician', 2), 'la rotella in su aggiunge');
  FWorld.Press(FWorld.RowArrowX(False), LY, XCOM_BUTTON_WHEELDOWN);
  FWorld.Release(FWorld.RowArrowX(False), LY, XCOM_BUTTON_WHEELDOWN);
  Assert.AreEqual('0', FWorld.RowCell('Technician', 2));
  FWorld.ClickButton('Cancel');
  Assert.AreEqual(BASESCAPE, FWorld.Top);
  Assert.AreEqual(LFunds, FWorld.Save.Funds, 'Cancel non vende nulla');
end;

procedure TTestXcomTourTrade.DovrebbeComprarePersonaleEOggetti;
var
  LTransfer: TXcomTransfer;
  LFunds: Int64;
  LSoldiers, LEngineers: Integer;
begin
  if not Ready then
    Exit;
  FWorld.Game.Options.ChangeValueByMouseWheel := 2;
  LFunds := FWorld.Save.Funds;
  OpenBaseScreen(TOUR_PURCHASE_Y, 'TXcomPurchaseState');
  Arrow('Aquanaut', True);
  Arrow('Technician', True);
  Arrow('Technician', True);
  Arrow('Technician', False);
  HoldArrow('Dart Gun', True, 1000);
  Assert.IsTrue(StrToInt(FWorld.RowCell('Dart Gun', 3)) > 5, 'la freccia tenuta premuta aggiunge col tempo');
  HoldArrow('Dart Gun', False, 3000);
  Assert.AreEqual('0', FWorld.RowCell('Dart Gun', 3));
  Arrow('Dart Gun', True);
  FWorld.ClickButton('OK');
  Assert.AreEqual(BASESCAPE, FWorld.Top);
  Assert.IsTrue(FWorld.Save.Funds < LFunds, 'gli acquisti si pagano');
  LSoldiers := 0;
  LEngineers := 0;
  for LTransfer in Source.Transfers do
  begin
    if Assigned(LTransfer.Soldier) then
      Inc(LSoldiers);
    Inc(LEngineers, LTransfer.Engineers);
  end;
  Assert.AreEqual(1, LSoldiers, 'un soldato nuovo e'' in viaggio');
  Assert.AreEqual(1, LEngineers, 'e un tecnico');
end;

procedure TTestXcomTourTrade.DovrebbeRifiutareGliAcquistiOltreILimitiDellaBase;
begin
  if not Ready then
    Exit;
  // the base has its three hangars taken
  OpenBaseScreen(TOUR_PURCHASE_Y, 'TXcomPurchaseState');
  Arrow('BARRACUDA', True);
  Assert.AreEqual(ERROR, FWorld.Top, 'senza hangar liberi il velivolo non si compra: ' + FWorld.Describe);
  FWorld.ClickButton('OK');
  FWorld.ClickButton('Cancel');
  FWorld.Key(XCOM_KEY_ESCAPE);
  // and then it is full of people and of things
  Source.Scientists := 10000;
  Source.StorageItems.AddItem('STR_DART_PISTOL', 100000);
  OpenBaseScreen(TOUR_PURCHASE_Y, 'TXcomPurchaseState');
  Arrow('Scientist', True);
  Assert.AreEqual(ERROR, FWorld.Top, 'senza alloggi liberi il personale non si compra');
  FWorld.ClickButton('OK');
  Arrow('Dart Gun', True);
  Assert.AreEqual(ERROR, FWorld.Top, 'senza spazio in magazzino gli oggetti non si comprano');
  FWorld.ClickButton('OK');
  Assert.AreEqual('0', FWorld.RowCell('Dart Gun', 3));
end;

procedure TTestXcomTourTrade.DovrebbeFiltrareGliAcquistiPerCategoria;
var
  LY: Integer;
begin
  if not Ready then
    Exit;
  OpenBaseScreen(TOUR_PURCHASE_Y, 'TXcomPurchaseState');
  Assert.IsTrue(FWorld.FindRow('Scientist', LY) >= 0);
  FWorld.ChooseCombo('Craft & Armament');
  Assert.IsTrue(FWorld.FindRow('BARRACUDA', LY) >= 0, 'i velivoli restano: ' + FWorld.Describe);
  Assert.AreEqual(-1, FWorld.FindRow('Scientist', LY), 'il personale no');
end;

end.
