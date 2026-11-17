{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRadixActorProperties - the fields of Rad-X of the     }
{  Thing blocks of DEHACKED and the four flags of the automap, of the missile  }
{  and of the blood                                                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Radix.ActorThingFields;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Logging.Intf, DelphiDoom.Logging.Recorder,
  DelphiDoom.ActorDef.Types, DelphiDoom.Dehacked.Types, DelphiDoom.Dehacked.Intf,
  DelphiDoom.Radix.ActorProperties;

type
  [TestFixture]
  [Category('radix')]
  TTestRadixActorThingFields = class(TObject)
  strict private
    FRecorder: TLogRecorder;
    FSink: ILogSink;
    FTable: IRadixActorTable;
    FFields: IDehackedExtraThingFields;
    FActors: IActorDefExtraProperties;
    function Thing(ANumber: Integer): TDehackedReference;
    function NewThing(const AName: string): TDehackedReference;
    function Warnings: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeConoscereTuttiICampiDiRadX;
    [Test]
    procedure DovrebbeLasciareAlLettoreUnCampoCheNonEDiRadX;
    [Test]
    procedure UnBloccoDiSoliZeriNonDovrebbeLasciareNiente;
    [Test]
    procedure DovrebbeTenereUnaCosaConNumeroPerNumeroDaZero;
    [Test]
    procedure DovrebbeTenereUnaCosaNuovaPerNome;
    [Test]
    procedure UnSetAZeroDovrebbeEssereNonDato;
    [Test]
    procedure DovrebbeLeggereMunizioniEArmiInElenco;
    [Test]
    procedure UnElencoDiLunghezzaSbagliataDovrebbeDareLAvvisoDiRadX;
    [Test]
    procedure DovrebbeLeggereMessaggioSuonoEPotenziamenti;
    [Test]
    procedure DovrebbeAggiungereAiCampiGiaLettiDellaStessaCosa;
    [Test]
    procedure DovrebbeLeggereIQuattroFlagNuoviDiActordef;
  end;

implementation

uses
  DelphiDoom.Logging.Types, DelphiDoom.Logging.Factory;

const
  CRLF = #13#10;
  ALL_FIELDS: array[0..18] of string = ('ARMOR INC', 'ENERGY INC', 'SHIELD INC', 'AMMO ADD', 'WEAPON ADD',
    'PICKUP MESSAGE', 'ARMOR SET', 'ENERGY SET', 'SHIELD SET', 'PICKUP SOUND', 'RAPID SHIELD', 'RAPID ENERGY',
    'MANEUVER JETS', 'NIGHT VISION', 'A.L.D.S.', 'PLASMA BOMB', 'TOUCH DAMAGE', 'PATROL RANGE',
    'MISSILE ALT DAMAGE');
  // the values that the dump of the tables of Rad-X writes for a thing that has nothing
  ZERO_VALUES: array[0..18] of string = ('0', '0', '0', '0, 0, 0, 0',
    'FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE', '', '0', '0', '0', '0', '0', '0', '0', '0',
    '0', '0', '0', '0', '0');

{ TTestRadixActorThingFields }

procedure TTestRadixActorThingFields.Setup;
var
  LProperties: TRadixActorProperties;
begin
  FRecorder := TLogRecorder.Create;
  FSink := FRecorder;
  LProperties := TRadixActorProperties.Create(TLogFactory.CreateLog(TArray<ILogSink>.Create(FSink), nil));
  FTable := LProperties;
  FFields := LProperties;
  FActors := LProperties;
end;

procedure TTestRadixActorThingFields.TearDown;
begin
  FActors := nil;
  FFields := nil;
  FTable := nil;
  FSink := nil;
  FRecorder := nil;
end;

function TTestRadixActorThingFields.Thing(ANumber: Integer): TDehackedReference;
begin
  Result := Default(TDehackedReference);
  Result.Number := ANumber;
end;

function TTestRadixActorThingFields.NewThing(const AName: string): TDehackedReference;
begin
  Result := Default(TDehackedReference);
  Result.Number := -1;
  Result.IsNew := True;
  Result.Name := AName;
end;

function TTestRadixActorThingFields.Warnings: string;
begin
  Result := StringReplace(FRecorder.TextOf(TLogChannel.Output), CRLF, '|', [rfReplaceAll]);
end;

procedure TTestRadixActorThingFields.DovrebbeConoscereTuttiICampiDiRadX;
var
  LIndex: Integer;
begin
  for LIndex := Low(ALL_FIELDS) to High(ALL_FIELDS) do
    Assert.IsTrue(FFields.TryRead(Thing(1), ALL_FIELDS[LIndex], ZERO_VALUES[LIndex]), ALL_FIELDS[LIndex]);
  Assert.AreEqual('', Warnings);
end;

procedure TTestRadixActorThingFields.DovrebbeLasciareAlLettoreUnCampoCheNonEDiRadX;
begin
  Assert.IsFalse(FFields.TryRead(Thing(1), 'NONEXISTENT', '3'));
  Assert.IsFalse(FFields.TryRead(Thing(1), 'SPEED', '3'));
end;

procedure TTestRadixActorThingFields.UnBloccoDiSoliZeriNonDovrebbeLasciareNiente;
var
  LIndex: Integer;
  LInfo: TRadixActorInfo;
begin
  for LIndex := Low(ALL_FIELDS) to High(ALL_FIELDS) do
    FFields.TryRead(Thing(1), ALL_FIELDS[LIndex], ZERO_VALUES[LIndex]);
  Assert.IsFalse(FTable.TryGetByNumber(0, LInfo));
  Assert.AreEqual(0, FTable.Count);
end;

procedure TTestRadixActorThingFields.DovrebbeTenereUnaCosaConNumeroPerNumeroDaZero;
var
  LInfo: TRadixActorInfo;
begin
  Assert.IsTrue(FFields.TryRead(Thing(140), 'ARMOR INC', '25'));
  Assert.IsTrue(FTable.TryGetByNumber(139, LInfo));
  Assert.AreEqual(25, LInfo.ArmorInc);
  Assert.AreEqual(-1, LInfo.ArmorSet);
  Assert.IsFalse(FTable.TryGetByNumber(140, LInfo));
end;

procedure TTestRadixActorThingFields.DovrebbeTenereUnaCosaNuovaPerNome;
var
  LInfo: TRadixActorInfo;
begin
  Assert.IsTrue(FFields.TryRead(NewThing('SUPERCHARGE'), 'ENERGY INC', '50'));
  Assert.IsTrue(FTable.TryGet('Supercharge', LInfo));
  Assert.AreEqual(50, LInfo.EnergyInc);
end;

procedure TTestRadixActorThingFields.UnSetAZeroDovrebbeEssereNonDato;
var
  LInfo: TRadixActorInfo;
begin
  FFields.TryRead(Thing(5), 'SHIELD SET', '200');
  FFields.TryRead(Thing(5), 'ARMOR SET', '0');
  FFields.TryRead(Thing(5), 'ENERGY SET', '0');
  Assert.IsTrue(FTable.TryGetByNumber(4, LInfo));
  Assert.AreEqual(200, LInfo.ShieldSet);
  Assert.AreEqual(-1, LInfo.ArmorSet);
  Assert.AreEqual(-1, LInfo.EnergySet);
end;

procedure TTestRadixActorThingFields.DovrebbeLeggereMunizioniEArmiInElenco;
var
  LInfo: TRadixActorInfo;
begin
  FFields.TryRead(Thing(2), 'AMMO ADD', '0, 5, 0, 12');
  FFields.TryRead(Thing(2), 'WEAPON ADD', 'FALSE, TRUE, FALSE, FALSE, FALSE, FALSE, YES, FALSE, 1');
  Assert.IsTrue(FTable.TryGetByNumber(1, LInfo));
  Assert.AreEqual(0, LInfo.AmmoInc[0]);
  Assert.AreEqual(5, LInfo.AmmoInc[1]);
  Assert.AreEqual(12, LInfo.AmmoInc[3]);
  Assert.IsFalse(LInfo.WeaponInc[0]);
  Assert.IsTrue(LInfo.WeaponInc[1]);
  Assert.IsTrue(LInfo.WeaponInc[6]);
  Assert.IsTrue(LInfo.WeaponInc[8]);
  Assert.AreEqual('', Warnings);
end;

procedure TTestRadixActorThingFields.UnElencoDiLunghezzaSbagliataDovrebbeDareLAvvisoDiRadX;
var
  LInfo: TRadixActorInfo;
begin
  Assert.IsTrue(FFields.TryRead(Thing(2), 'AMMO ADD', '1, 2, 3'));
  Assert.IsTrue(FFields.TryRead(Thing(2), 'WEAPON ADD', 'TRUE'));
  Assert.Contains(Warnings, 'Wrong ammo values = 1, 2, 3 (Count is = 3).');
  Assert.Contains(Warnings, 'Wrong weapon values = TRUE (Count is = 1).');
  Assert.IsFalse(FTable.TryGetByNumber(1, LInfo));
end;

procedure TTestRadixActorThingFields.DovrebbeLeggereMessaggioSuonoEPotenziamenti;
var
  LInfo: TRadixActorInfo;
begin
  FFields.TryRead(Thing(9), 'PICKUP MESSAGE', 'RAPID SHIELD REGENERATION');
  FFields.TryRead(Thing(9), 'PICKUP SOUND', 'RADIX/SNDPOWERUP');
  FFields.TryRead(Thing(9), 'RAPID SHIELD', '1050');
  FFields.TryRead(Thing(9), 'RAPID ENERGY', '2');
  FFields.TryRead(Thing(9), 'MANEUVER JETS', '3');
  FFields.TryRead(Thing(9), 'NIGHT VISION', '4');
  FFields.TryRead(Thing(9), 'A.L.D.S.', '5');
  FFields.TryRead(Thing(9), 'PLASMA BOMB', '6');
  FFields.TryRead(Thing(9), 'TOUCH DAMAGE', '7');
  FFields.TryRead(Thing(9), 'PATROL RANGE', '524288'); // a 16.16 distance: 8 map units
  FFields.TryRead(Thing(9), 'MISSILE ALT DAMAGE', '9');
  Assert.IsTrue(FTable.TryGetByNumber(8, LInfo));
  Assert.AreEqual('RAPID SHIELD REGENERATION', LInfo.PickupMessage);
  Assert.AreEqual('RADIX/SNDPOWERUP', LInfo.PickupSound);
  Assert.AreEqual(1050, LInfo.RapidShield);
  Assert.AreEqual(2, LInfo.RapidEnergy);
  Assert.AreEqual(3, LInfo.ManeuverJets);
  Assert.AreEqual(4, LInfo.NightVision);
  Assert.AreEqual(5, LInfo.Alds);
  Assert.AreEqual(6, LInfo.PlasmaBomb);
  Assert.AreEqual(7, LInfo.TouchDamage);
  Assert.AreEqual(8, LInfo.PatrolRange);
  Assert.AreEqual(9, LInfo.AltDamage);
  Assert.IsTrue(LInfo.GivesSomething);
end;

procedure TTestRadixActorThingFields.DovrebbeAggiungereAiCampiGiaLettiDellaStessaCosa;
var
  LInfo: TRadixActorInfo;
begin
  FFields.TryRead(Thing(3), 'ARMOR INC', '10');
  FFields.TryRead(Thing(3), 'ENERGY INC', '0');
  FFields.TryRead(Thing(3), 'SHIELD INC', '30');
  Assert.IsTrue(FTable.TryGetByNumber(2, LInfo));
  Assert.AreEqual(10, LInfo.ArmorInc);
  Assert.AreEqual(0, LInfo.EnergyInc);
  Assert.AreEqual(30, LInfo.ShieldInc);
end;

procedure TTestRadixActorThingFields.DovrebbeLeggereIQuattroFlagNuoviDiActordef;
var
  LInfo: TRadixActorInfo;
begin
  FActors.BeginActor('MT_TEST', '');
  Assert.IsTrue(FActors.TryRead('+MF3_EX_AMTELEPORTFOG', nil));
  Assert.IsTrue(FActors.TryRead('+MF3_EX_AMFORCEFIELD', nil));
  Assert.IsTrue(FActors.TryRead('+MF3_EX_NOADJUSTMISSILECEILING', nil));
  Assert.IsTrue(FActors.TryRead('+MF3_EX_ALIENBLOOD', nil));
  Assert.IsTrue(FTable.TryGet('MT_TEST', LInfo));
  Assert.IsTrue(LInfo.Flags = [TRadixActorFlag.AmTeleportFog, TRadixActorFlag.AmForceField,
    TRadixActorFlag.NoAdjustMissileCeiling, TRadixActorFlag.AlienBlood]);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRadixActorThingFields);

end.
