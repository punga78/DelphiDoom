{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom saved game library - ItemContainer, Vehicle,  }
{  CraftWeapon, BaseFacility and Production (what the corpus cannot say)        }
{                                                                              }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomSave.Holdings;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Intf, DelphiDoom.Yaml.Factory,
  DelphiDoom.XcomMod.RuleManufacture, DelphiDoom.XcomSave.Types, DelphiDoom.XcomSave.ItemContainer,
  DelphiDoom.XcomSave.Vehicle, DelphiDoom.XcomSave.CraftWeapon, DelphiDoom.XcomSave.BaseFacility,
  DelphiDoom.XcomSave.Production, DelphiDoom.Tests.XcomSave.ObjectScenario;

type
  [TestFixture]
  [Category('xcom-save')]
  TTestXcomSaveHoldings = class(TObject)
  private
    function Load(const AText: string): IYamlNode;
  public
    [Test]
    procedure DovrebbeTenereIPezziInOrdineDiTipo;
    [Test]
    procedure DovrebbeLasciareIlContenutoSeIlNodoNonEUnaMappa;
    [Test]
    procedure DovrebbeLasciareIlContenutoSeUnaQuantitaNonEIntera;
    [Test]
    procedure DovrebbeLasciareIlContenutoSeLaChiaveMancaNelNodoPadre;
    [Test]
    procedure DovrebbeSalvareUnContenitoreVuotoComeMappaVuota;
    [Test]
    procedure DovrebbeDare255ComeMunizioniIllimitateDelVeicolo;
    [Test]
    procedure DovrebbeRifiutareRegoleMancanti;
    [Test]
    procedure DovrebbeLimitareLeMunizioniDellArmaDelVelivolo;
    [Test]
    procedure DovrebbeRicaricareConLeCartucceDisponibili;
    [Test]
    procedure DovrebbeContareUnGiornoInMenoPerCostruireUnaStruttura;
    [Test]
    procedure DovrebbeRendereInfinitaUnaProduzioneConQuantitaMassima;
    [Test]
    procedure DovrebbeDareTuttaLaQuantitaSeIlTempoDiProduzioneEZero;
  end;

implementation

{ TTestXcomSaveHoldings }

function TTestXcomSaveHoldings.Load(const AText: string): IYamlNode;
begin
  Result := TYamlFactory.CreateParser.Load(YamlStringToText(AText));
end;

procedure TTestXcomSaveHoldings.DovrebbeTenereIPezziInOrdineDiTipo;
var
  LContainer: TXcomItemContainer;
begin
  LContainer := TXcomItemContainer.Create;
  try
    LContainer.AddItem('B', 2);
    LContainer.AddItem('A', 3);
    LContainer.AddItem('B');
    Assert.AreEqual('A', LContainer.Contents.Key(0));
    Assert.AreEqual(3, LContainer.GetItem('B'));
    Assert.AreEqual(6, LContainer.TotalQuantity);
    LContainer.RemoveItem('B', 3);
    Assert.AreEqual(0, LContainer.GetItem('B'));
    Assert.AreEqual(1, LContainer.Contents.Count);
  finally
    LContainer.Free;
  end;
end;

procedure TTestXcomSaveHoldings.DovrebbeLasciareIlContenutoSeIlNodoNonEUnaMappa;
var
  LContainer: TXcomItemContainer;
begin
  LContainer := TXcomItemContainer.Create;
  try
    LContainer.AddItem('A');
    LContainer.Load(Load('[1, 2]'));
    Assert.AreEqual(1, LContainer.GetItem('A'));
  finally
    LContainer.Free;
  end;
end;

procedure TTestXcomSaveHoldings.DovrebbeLasciareIlContenutoSeLaChiaveMancaNelNodoPadre;
var
  LContainer: TXcomItemContainer;
begin
  // a craft of the starting base of UFO has no "items": node["items"].as<map>(fallback) keeps the contents
  LContainer := TXcomItemContainer.Create;
  try
    LContainer.AddItem('A');
    LContainer.Load(Load('type: STR_INTERCEPTOR').Find(YamlStringToText('items')));
    Assert.AreEqual(1, LContainer.GetItem('A'));
  finally
    LContainer.Free;
  end;
end;

procedure TTestXcomSaveHoldings.DovrebbeLasciareIlContenutoSeUnaQuantitaNonEIntera;
var
  LContainer: TXcomItemContainer;
  LNode: IYamlNode;
begin
  LContainer := TXcomItemContainer.Create;
  try
    LContainer.AddItem('A');
    LNode := Load('X: 5' + #10 + 'Y: abc');
    Assert.WillRaise(
      procedure
      begin
        LContainer.Load(LNode);
      end, EYamlBadConversion);
    Assert.AreEqual(1, LContainer.GetItem('A'));
    Assert.AreEqual(0, LContainer.GetItem('X'));
  finally
    LContainer.Free;
  end;
end;

procedure TTestXcomSaveHoldings.DovrebbeSalvareUnContenitoreVuotoComeMappaVuota;
var
  LContainer: TXcomItemContainer;
  LEmitter: IYamlEmitter;
begin
  LContainer := TXcomItemContainer.Create;
  try
    LEmitter := TYamlFactory.CreateEmitter;
    LEmitter.WriteNode(LContainer.Save);
    Assert.AreEqual('{}', YamlTextToString(LEmitter.Text).Trim);
  finally
    LContainer.Free;
  end;
end;

procedure TTestXcomSaveHoldings.DovrebbeDare255ComeMunizioniIllimitateDelVeicolo;
var
  LVehicle: TXcomVehicle;
begin
  LVehicle := TXcomVehicle.Create(TXcomFakeTypeRule.Create('STR_TANK'), -1, 4);
  try
    Assert.AreEqual(255, LVehicle.Ammo);
    LVehicle.SetAmmo(3);
    Assert.AreEqual(255, LVehicle.Ammo);
  finally
    LVehicle.Free;
  end;
end;

procedure TTestXcomSaveHoldings.DovrebbeRifiutareRegoleMancanti;
begin
  Assert.WillRaise(
    procedure
    begin
      TXcomVehicle.Create(nil, 0, 1).Free;
    end, EXcomSaveException);
  Assert.WillRaise(
    procedure
    begin
      TXcomCraftWeapon.Create(nil, 0).Free;
    end, EXcomSaveException);
  Assert.WillRaise(
    procedure
    begin
      TXcomBaseFacility.Create(nil).Free;
    end, EXcomSaveException);
  Assert.WillRaise(
    procedure
    begin
      TXcomProduction.Create(nil, 1).Free;
    end, EXcomSaveException);
end;

procedure TTestXcomSaveHoldings.DovrebbeLimitareLeMunizioniDellArmaDelVelivolo;
var
  LWeapon: TXcomCraftWeapon;
begin
  LWeapon := TXcomCraftWeapon.Create(TXcomFakeTypeRule.Create('STR_CW', 10, 2), 4);
  try
    Assert.IsFalse(LWeapon.SetAmmo(-1));
    Assert.AreEqual(0, LWeapon.Ammo);
    Assert.IsTrue(LWeapon.SetAmmo(99));
    Assert.AreEqual(10, LWeapon.Ammo);
  finally
    LWeapon.Free;
  end;
end;

procedure TTestXcomSaveHoldings.DovrebbeRicaricareConLeCartucceDisponibili;
var
  LWeapon: TXcomCraftWeapon;
begin
  LWeapon := TXcomCraftWeapon.Create(TXcomFakeTypeRule.Create('STR_CW', 10, 6), 0);
  try
    // the rate lets 6 rounds in, the clips hold 2: three clips
    Assert.AreEqual(3, LWeapon.Rearm(100, 2));
    Assert.AreEqual(6, LWeapon.Ammo);
    Assert.IsTrue(LWeapon.Rearming);
    // only one clip is there
    Assert.AreEqual(1, LWeapon.Rearm(1, 2));
    Assert.AreEqual(8, LWeapon.Ammo);
    // no clip size: the whole rate and nothing used
    Assert.AreEqual(0, LWeapon.Rearm(0, 0));
    Assert.AreEqual(10, LWeapon.Ammo);
    Assert.IsFalse(LWeapon.Rearming);
  finally
    LWeapon.Free;
  end;
end;

procedure TTestXcomSaveHoldings.DovrebbeContareUnGiornoInMenoPerCostruireUnaStruttura;
var
  LFacility: TXcomBaseFacility;
begin
  LFacility := TXcomBaseFacility.Create(TXcomFakeTypeRule.Create('STR_FAC'));
  try
    Assert.AreEqual(-1, LFacility.X);
    LFacility.BuildTime := 2;
    LFacility.Build;
    Assert.AreEqual(1, LFacility.BuildTime);
  finally
    LFacility.Free;
  end;
end;

procedure TTestXcomSaveHoldings.DovrebbeRendereInfinitaUnaProduzioneConQuantitaMassima;
var
  LRules: TXcomRuleManufacture;
  LProduction: TXcomProduction;
begin
  LRules := TXcomRuleManufacture.Create('STR_X');
  try
    LProduction := TXcomProduction.Create(LRules, 1);
    try
      LProduction.Load(Load('amount: 2147483647'));
      Assert.AreEqual(999, LProduction.AmountTotal);
      Assert.IsTrue(LProduction.InfiniteAmount);
      Assert.IsTrue(LProduction.SellItems);
    finally
      LProduction.Free;
    end;
  finally
    LRules.Free;
  end;
end;

procedure TTestXcomSaveHoldings.DovrebbeDareTuttaLaQuantitaSeIlTempoDiProduzioneEZero;
var
  LRules: TXcomRuleManufacture;
  LProduction: TXcomProduction;
begin
  LRules := TXcomRuleManufacture.Create('STR_X');
  try
    LProduction := TXcomProduction.Create(LRules, 7);
    try
      LProduction.TimeSpent := 100;
      Assert.AreEqual(7, LProduction.AmountProduced);
      Assert.IsTrue(LProduction.HaveEnoughMoneyForOneMoreUnit(0));
    finally
      LProduction.Free;
    end;
  finally
    LRules.Free;
  end;
end;

end.
