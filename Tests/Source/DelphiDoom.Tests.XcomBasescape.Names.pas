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
  DelphiDoom.XcomBasescape.Names;

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

initialization
  TDUnitX.RegisterTestFixture(TTestXcomBaseNames);

end.
