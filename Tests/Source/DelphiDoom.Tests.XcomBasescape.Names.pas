{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom basescape library - the names of crafts  }
{  and the ranks that the screens of a base show                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomBasescape.Names;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.XcomMod.RuleCraft, DelphiDoom.XcomSave.Craft,
  DelphiDoom.XcomBasescape.Names, DelphiDoom.XcomMod.RuleSoldier, DelphiDoom.XcomSave.Soldier,
  DelphiDoom.XcomSave.Transfer, DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.BaseCapacity;

type
  [TestFixture]
  [Category('xcom-basescape')]
  TTestXcomBaseNames = class(TObject)
  public
    [Test]
    [TestCase('recluta', '0,STR_ROOKIE')]
    [TestCase('marinaio', '1,STR_SQUADDIE')]
    [TestCase('sergente', '2,STR_SERGEANT')]
    [TestCase('capitano', '3,STR_CAPTAIN')]
    [TestCase('colonnello', '4,STR_COLONEL')]
    [TestCase('comandante', '5,STR_COMMANDER')]
    procedure DovrebbeDareLaChiaveDelGrado(ARank: Integer; const AKey: string);
    [Test]
    procedure DovrebbeDareStringaVuotaPerUnGradoInesistente;
    [Test]
    procedure DovrebbeUsareIlNomeDelVelivoloSeCe;
    [Test]
    procedure DovrebbeUsareIlNomeDelSoldatoNelTrasferimento;
    [Test]
    procedure DovrebbeUsareIlNomeDelVelivoloNelTrasferimento;
    [Test]
    procedure DovrebbeContareISoldatiDiUnTipoConITrasferimenti;
  end;

implementation

{ TTestXcomBaseNames }

procedure TTestXcomBaseNames.DovrebbeDareLaChiaveDelGrado(ARank: Integer; const AKey: string);
begin
  Assert.AreEqual(AKey, TXcomBaseNames.RankKey(ARank));
end;

procedure TTestXcomBaseNames.DovrebbeDareStringaVuotaPerUnGradoInesistente;
begin
  Assert.AreEqual('', TXcomBaseNames.RankKey(-1), 'sotto');
  Assert.AreEqual('', TXcomBaseNames.RankKey(6), 'sopra');
end;

procedure TTestXcomBaseNames.DovrebbeUsareIlNomeDelVelivoloSeCe;
var
  LRules: TXcomRuleCraft;
  LCraft: TXcomCraft;
begin
  LRules := TXcomRuleCraft.Create('STR_TRITON');
  try
    LCraft := TXcomCraft.Create(LRules, nil, 3);
    try
      LCraft.Name := 'Nautilus';
      // with a custom name the language is not asked
      Assert.AreEqual('Nautilus', TXcomBaseNames.CraftName(LCraft, nil));
    finally
      LCraft.Free;
    end;
  finally
    LRules.Free;
  end;
end;

procedure TTestXcomBaseNames.DovrebbeUsareIlNomeDelSoldatoNelTrasferimento;
var
  LRules: TXcomRuleSoldier;
  LTransfer: TXcomTransfer;
begin
  LRules := TXcomRuleSoldier.Create('STR_SOLDIER');
  try
    LTransfer := TXcomTransfer.Create(12);
    try
      LTransfer.Soldier := TXcomSoldier.Create(LRules, nil, 0, nil);
      LTransfer.Soldier.Name := 'Ann';
      Assert.AreEqual('Ann', TXcomBaseNames.TransferName(LTransfer, nil));
    finally
      LTransfer.Free;
    end;
  finally
    LRules.Free;
  end;
end;

procedure TTestXcomBaseNames.DovrebbeUsareIlNomeDelVelivoloNelTrasferimento;
var
  LRules: TXcomRuleCraft;
  LTransfer: TXcomTransfer;
begin
  LRules := TXcomRuleCraft.Create('STR_TRITON');
  try
    LTransfer := TXcomTransfer.Create(12);
    try
      LTransfer.Craft := TXcomCraft.Create(LRules, nil, 3);
      LTransfer.Craft.Name := 'Nautilus';
      Assert.AreEqual('Nautilus', TXcomBaseNames.TransferName(LTransfer, nil));
    finally
      LTransfer.Free;
    end;
  finally
    LRules.Free;
  end;
end;

procedure TTestXcomBaseNames.DovrebbeContareISoldatiDiUnTipoConITrasferimenti;
var
  LRulesA, LRulesB: TXcomRuleSoldier;
  LBase: TXcomBase;
  LTransfer: TXcomTransfer;
  LCapacity: TXcomBaseCapacity;
begin
  LRulesA := TXcomRuleSoldier.Create('STR_A');
  LRulesB := TXcomRuleSoldier.Create('STR_B');
  LBase := TXcomBase.Create;
  LCapacity := TXcomBaseCapacity.Create(nil);
  try
    LBase.Soldiers.Add(TXcomSoldier.Create(LRulesA, nil, 0, nil));
    LBase.Soldiers.Add(TXcomSoldier.Create(LRulesA, nil, 0, nil));
    LBase.Soldiers.Add(TXcomSoldier.Create(LRulesB, nil, 0, nil));
    LTransfer := TXcomTransfer.Create(5);
    LTransfer.Soldier := TXcomSoldier.Create(LRulesA, nil, 0, nil);
    LBase.Transfers.Add(LTransfer);
    Assert.AreEqual(3, LCapacity.SoldierCount(LBase, 'STR_A'));
    Assert.AreEqual(1, LCapacity.SoldierCount(LBase, 'STR_B'));
    Assert.AreEqual(0, LCapacity.SoldierCount(LBase, 'STR_C'));
  finally
    LCapacity.Free;
    LBase.Free;
    LRulesB.Free;
    LRulesA.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomBaseNames);

end.
