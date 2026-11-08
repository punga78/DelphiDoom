{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the fire flicker                                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Thinkers.LightFireFlicker;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.MathCore.Intf, DelphiDoom.Thinkers.Light.Intf,
  DelphiDoom.Tests.Thinkers.Fakes;

type
  [TestFixture]
  [Category('thinkers')]
  TTestThinkersLightFireFlicker = class(TObject)
  private
    FWorld: TFakeLightWorld;
    procedure CheckSameAsOldCode(AStrife: Boolean; ASeed, ALevel: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbePrendereIValoriIniziali;
    [Test]
    procedure DovrebbePrendereIValoriInizialiDiStrife;
    [Test]
    procedure DovrebbeAspettareFinoAllaFineDelConteggio;
    [Test]
    procedure DovrebbeNonScendereSottoIlMinimo;
    [Test]
    procedure DovrebbeDareGliStessiLivelliDelVecchioCodiceInDoom;
    [Test]
    procedure DovrebbeDareGliStessiLivelliDelVecchioCodiceInStrife;
    [Test]
    procedure DovrebbeTroncareA16BitComeIlVecchioCodice;
  end;

implementation

uses
  DelphiDoom.Thinkers.Light.FireFlicker, DelphiDoom.Thinkers.Light.FlickerRules.Standard,
  DelphiDoom.Thinkers.Light.FlickerRules.Strife, DelphiDoom.Tests.Thinkers.OldLights;

{ TTestThinkersLightFireFlicker }

procedure TTestThinkersLightFireFlicker.Setup;
begin
  FWorld := TFakeLightWorld.Create;
end;

procedure TTestThinkersLightFireFlicker.TearDown;
begin
  FreeAndNil(FWorld);
end;

procedure TTestThinkersLightFireFlicker.DovrebbePrendereIValoriIniziali;
var
  LSector: TFakeLightSector;
  LMax, LMin, LCount: Integer;
begin
  LSector := FWorld.AddWithNeighbors(160, [96, NO_NEIGHBOR, 120]);
  TLightFireFlicker.Initialize(LSector, TLightStandardFlickerRules.Create, LMax, LMin, LCount);
  Assert.AreEqual(160, LMax, 'maximum');
  Assert.AreEqual(96 + 16, LMin, 'minimum: the darkest neighbor plus 16');
  Assert.AreEqual(4, LCount, 'count');
end;

procedure TTestThinkersLightFireFlicker.DovrebbePrendereIValoriInizialiDiStrife;
var
  LSector: TFakeLightSector;
  LMax, LMin, LCount: Integer;
begin
  LSector := FWorld.AddWithNeighbors(160, [96, 120]);
  TLightFireFlicker.Initialize(LSector, TLightStrifeFlickerRules.Create, LMax, LMin, LCount);
  Assert.AreEqual(160, LMax, 'maximum');
  Assert.AreEqual(160 - 32, LMin, 'minimum');
  Assert.AreEqual(2, LCount, 'count');
end;

procedure TTestThinkersLightFireFlicker.DovrebbeAspettareFinoAllaFineDelConteggio;
var
  LLevel: SmallInt;
  LCount: Integer;
  LRandom: IGameRandom;
  LRules: ILightFlickerRules;
begin
  LRandom := CreateTestRandom(10);
  LRules := TLightStandardFlickerRules.Create;
  LLevel := 150;
  LCount := 3;
  TLightFireFlicker.Tick(LCount, LLevel, 100, 160, LRules, LRandom);
  Assert.AreEqual(2, LCount, 'one tic less');
  Assert.AreEqual(150, Integer(LLevel), 'the light did not change');
  Assert.AreEqual(10, LRandom.PlayIndex, 'no random number was used');
end;

procedure TTestThinkersLightFireFlicker.DovrebbeNonScendereSottoIlMinimo;
var
  LLevel: SmallInt;
  LCount: Integer;
  LIndex: Integer;
  LRules: ILightFlickerRules;
  LRandom: IGameRandom;
begin
  LRandom := CreateTestRandom(0);
  LRules := TLightStandardFlickerRules.Create;
  LLevel := 160;
  LCount := 1;
  for LIndex := 1 to 500 do
  begin
    TLightFireFlicker.Tick(LCount, LLevel, 150, 160, LRules, LRandom);
    Assert.IsTrue((LLevel >= 150) and (LLevel <= 160), 'level ' + IntToStr(LLevel));
  end;
end;

procedure TTestThinkersLightFireFlicker.CheckSameAsOldCode(AStrife: Boolean; ASeed, ALevel: Integer);
var
  LOldSector: TFakeLightSector;
  LNewSector: TFakeLightSector;
  LOld: TOldFireFlicker;
  LMax, LMin, LCount, LTic: Integer;
  LOldRandom: IGameRandom;
  LNewRandom: IGameRandom;
  LRules: ILightFlickerRules;
begin
  LOldSector := FWorld.AddWithNeighbors(ALevel, [ALevel - 64, ALevel - 30, NO_NEIGHBOR, ALevel + 20]);
  LNewSector := FWorld.AddWithNeighbors(ALevel, [ALevel - 64, ALevel - 30, NO_NEIGHBOR, ALevel + 20]);
  LOldRandom := CreateTestRandom(ASeed);
  LNewRandom := CreateTestRandom(ASeed);
  if AStrife then
    LRules := TLightStrifeFlickerRules.Create
  else
    LRules := TLightStandardFlickerRules.Create;

  OldSpawnFireFlicker(LOld, LOldSector, AStrife);
  TLightFireFlicker.Initialize(LNewSector, LRules, LMax, LMin, LCount);
  Assert.AreEqual(LOld.MaxLight, LMax, 'maximum');
  Assert.AreEqual(LOld.MinLight, LMin, 'minimum');
  Assert.AreEqual(LOld.Count, LCount, 'count');

  for LTic := 1 to 4000 do
  begin
    OldTickFireFlicker(LOld, LOldRandom, AStrife);
    TLightFireFlicker.Tick(LCount, LNewSector.Level, LMin, LMax, LRules, LNewRandom);
    Assert.AreEqual(Integer(LOldSector.Level), Integer(LNewSector.Level), Format('level at tic %d', [LTic]));
    Assert.AreEqual(LOld.Count, LCount, Format('count at tic %d', [LTic]));
    Assert.AreEqual(LOldRandom.PlayIndex, LNewRandom.PlayIndex, Format('random at tic %d', [LTic]));
  end;
end;

procedure TTestThinkersLightFireFlicker.DovrebbeDareGliStessiLivelliDelVecchioCodiceInDoom;
var
  LSeed: Integer;
begin
  for LSeed := 0 to 7 do
    CheckSameAsOldCode(False, LSeed * 31, 120 + LSeed * 16);
end;

procedure TTestThinkersLightFireFlicker.DovrebbeDareGliStessiLivelliDelVecchioCodiceInStrife;
var
  LSeed: Integer;
begin
  for LSeed := 0 to 7 do
    CheckSameAsOldCode(True, LSeed * 29, 100 + LSeed * 20);
end;

procedure TTestThinkersLightFireFlicker.DovrebbeTroncareA16BitComeIlVecchioCodice;
var
  LLevel: SmallInt;
  LCount: Integer;
  LRandom: IGameRandom;
  LMaximum: Integer;
begin
  // a maximum that does not fit in 16 bit is cut as the sector always did
  LMaximum := 70000;
  LRandom := CreateTestRandom(0);
  LLevel := 0;
  LCount := 1;
  TLightFireFlicker.Tick(LCount, LLevel, -100000, LMaximum, TLightStandardFlickerRules.Create, LRandom);
  Assert.IsTrue((LLevel = SmallInt(LMaximum)) or (LLevel = SmallInt(LMaximum - 16)) or
    (LLevel = SmallInt(LMaximum - 32)) or (LLevel = SmallInt(LMaximum - 48)),
    'level ' + IntToStr(LLevel));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestThinkersLightFireFlicker);

end.
