{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRadixActorProperties                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Radix.ActorProperties;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.ActorDef.Types, DelphiDoom.Radix.ActorProperties;

type
  [TestFixture]
  [Category('radix')]
  TTestRadixActorProperties = class(TObject)
  strict private
    FProperties: TRadixActorProperties;
    FTable: IRadixActorTable;
    FExtra: IActorDefExtraProperties;
    /// <summary>Reads the words as the reader of the actors does; gives the words it did not know</summary>
    function ReadActor(const AName, AParent: string; const AWords: array of string): string;
    function Info(const AName: string): TRadixActorInfo;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeLeggereIlBloccoDiUnaSupercarica;
    [Test]
    procedure DovrebbeLeggereUnArmaConLeMunizioni;
    [Test]
    procedure DovrebbeLeggereIncEAddComeIncremento;
    [Test]
    procedure DovrebbeLeggereIPotenziamentiELaBombaAlPlasma;
    [Test]
    procedure DovrebbeLeggereLeArmiPerNumeroEInElenco;
    [Test]
    procedure DovrebbeLeggereIFlagConESenzaPrefisso;
    [Test]
    procedure DovrebbeTogliereUnFlagColMeno;
    [Test]
    procedure DovrebbeLasciareAlLettoreLeParoleCheNonConosce;
    [Test]
    procedure DovrebbeLeggereDannoDaContattoERaggioDiPattuglia;
    [Test]
    procedure DovrebbeEreditareDalGenitore;
    [Test]
    procedure DovrebbeNonRicordareUnAttoreSenzaNienteDiRadix;
    [Test]
    procedure DovrebbeCercareINomiSenzaDistinguereLeMaiuscole;
    [Test]
    procedure DovrebbeNonCambiareNienteSeDopoSetNonCeUnNumero;
    [Test]
    procedure DovrebbeDireCheUnBloccoVuotoNonDaNiente;
    [Test]
    procedure DovrebbeSostituireUnAttoreDefinitoDueVolte;
  end;

implementation

type
  TFakeCursor = class(TInterfacedObject, IActorDefTokenCursor)
  strict private
    FWords: TArray<string>;
    FIndex: Integer;
  public
    constructor Create(const AWords: array of string);
    function Current: string;
    function Next: Boolean;
    function AtEnd: Boolean;
  end;

{ TFakeCursor }

constructor TFakeCursor.Create(const AWords: array of string);
var
  LIndex: Integer;
begin
  inherited Create;
  SetLength(FWords, Length(AWords));
  for LIndex := 0 to High(AWords) do
    FWords[LIndex] := AWords[LIndex];
end;

function TFakeCursor.Current: string;
begin
  if FIndex < Length(FWords) then
    Result := FWords[FIndex]
  else
    Result := '';
end;

function TFakeCursor.Next: Boolean;
begin
  Inc(FIndex);
  Result := FIndex < Length(FWords);
end;

function TFakeCursor.AtEnd: Boolean;
begin
  Result := FIndex >= Length(FWords);
end;

{ TTestRadixActorProperties }

procedure TTestRadixActorProperties.Setup;
begin
  FProperties := TRadixActorProperties.Create(nil);
  FTable := FProperties;
  FExtra := FProperties;
end;

procedure TTestRadixActorProperties.TearDown;
begin
  FExtra := nil;
  FTable := nil;
  FProperties := nil;
end;

function TTestRadixActorProperties.ReadActor(const AName, AParent: string; const AWords: array of string): string;
var
  LCursorObject: TFakeCursor;
  LCursor: IActorDefTokenCursor;
begin
  Result := '';
  LCursorObject := TFakeCursor.Create(AWords);
  LCursor := LCursorObject;
  FExtra.BeginActor(AName, AParent);
  while not LCursorObject.AtEnd do
  begin
    if not FExtra.TryRead(UpperCase(LCursor.Current), LCursor) then
      Result := Result + LCursor.Current + ' ';
    LCursor.Next;
  end;
  Result := Trim(Result);
end;

function TTestRadixActorProperties.Info(const AName: string): TRadixActorInfo;
begin
  Assert.IsTrue(FTable.TryGet(AName, Result), AName + ' non ha niente di Radix');
end;

procedure TTestRadixActorProperties.DovrebbeLeggereIlBloccoDiUnaSupercarica;
var
  LInfo: TRadixActorInfo;
begin
  Assert.AreEqual('', ReadActor('MT_SUPERCHARGE', '', ['+CUSTOMPICKUP', '+MF3_EX_NOCRASH', 'INVENTORY',
    'ARMOR', 'SET', '100', 'SHIELD', 'SET', '100', 'ENERGY', 'SET', '100',
    'PICKUPMESSAGE', 'SUPERCHARGE!', 'PICKUPSOUND', 'radix/SndPowerUp']));
  LInfo := Info('MT_SUPERCHARGE');
  Assert.IsTrue(TRadixActorFlag.CustomPickup in LInfo.Flags);
  Assert.IsTrue(TRadixActorFlag.NoCrash in LInfo.Flags);
  Assert.AreEqual(100, LInfo.ArmorSet);
  Assert.AreEqual(100, LInfo.ShieldSet);
  Assert.AreEqual(100, LInfo.EnergySet);
  Assert.AreEqual(0, LInfo.ArmorInc);
  Assert.AreEqual('SUPERCHARGE!', LInfo.PickupMessage);
  Assert.AreEqual('radix/SndPowerUp', LInfo.PickupSound);
  Assert.IsTrue(LInfo.GivesSomething);
end;

procedure TTestRadixActorProperties.DovrebbeLeggereUnArmaConLeMunizioni;
var
  LInfo: TRadixActorInfo;
begin
  Assert.AreEqual('', ReadActor('MT_STANDARDEPC', '', ['INVENTORY', 'STANDARDEPC', 'AMMO', '200', '0', '0',
    '0', 'PICKUPMESSAGE', 'Standard EPC Acquired']));
  LInfo := Info('MT_STANDARDEPC');
  Assert.IsTrue(LInfo.WeaponInc[1]);
  Assert.IsFalse(LInfo.WeaponInc[0]);
  Assert.AreEqual(200, LInfo.AmmoInc[0]);
  Assert.AreEqual(0, LInfo.AmmoInc[3]);
  Assert.AreEqual(-1, LInfo.ArmorSet, 'non dato');
  Assert.AreEqual('Standard EPC Acquired', LInfo.PickupMessage);
end;

procedure TTestRadixActorProperties.DovrebbeLeggereIncEAddComeIncremento;
var
  LInfo: TRadixActorInfo;
begin
  ReadActor('A', '', ['ARMOR', 'INC', '25', 'SHIELD', 'add', '10', 'ENERGY', 'Inc', '5']);
  LInfo := Info('A');
  Assert.AreEqual(25, LInfo.ArmorInc);
  Assert.AreEqual(10, LInfo.ShieldInc);
  Assert.AreEqual(5, LInfo.EnergyInc);
  Assert.AreEqual(-1, LInfo.ShieldSet);
end;

procedure TTestRadixActorProperties.DovrebbeLeggereIPotenziamentiELaBombaAlPlasma;
var
  LInfo: TRadixActorInfo;
begin
  Assert.AreEqual('', ReadActor('P', '', ['RAPIDSHIELD', '3500', 'RAPIDENERGY', '3501', 'MANEUVERJETS', '3502',
    'NIGHTVISION', '3503', 'ALDS', '3504', 'PLASMABOMB', '1']));
  LInfo := Info('P');
  Assert.AreEqual(3500, LInfo.RapidShield);
  Assert.AreEqual(3501, LInfo.RapidEnergy);
  Assert.AreEqual(3502, LInfo.ManeuverJets);
  Assert.AreEqual(3503, LInfo.NightVision);
  Assert.AreEqual(3504, LInfo.Alds);
  Assert.AreEqual(1, LInfo.PlasmaBomb);
end;

procedure TTestRadixActorProperties.DovrebbeLeggereLeArmiPerNumeroEInElenco;
var
  LInfo: TRadixActorInfo;
begin
  ReadActor('W', '', ['WEAPON8', 'GRAVITYWAVE']);
  LInfo := Info('W');
  Assert.IsTrue(LInfo.WeaponInc[8]);
  Assert.IsTrue(LInfo.WeaponInc[6]);
  Assert.IsFalse(LInfo.WeaponInc[7]);

  Assert.AreEqual('', ReadActor('L', '', ['WEAPON', 'FALSE', 'TRUE', 'FALSE', 'FALSE', 'TRUE', 'FALSE', 'FALSE',
    'FALSE', 'FALSE']));
  LInfo := Info('L');
  Assert.IsTrue(LInfo.WeaponInc[1]);
  Assert.IsTrue(LInfo.WeaponInc[4]);
  Assert.IsFalse(LInfo.WeaponInc[0]);
  Assert.IsFalse(LInfo.WeaponInc[8]);
end;

procedure TTestRadixActorProperties.DovrebbeLeggereIFlagConESenzaPrefisso;
var
  LInfo: TRadixActorInfo;
begin
  Assert.AreEqual('', ReadActor('F', '', ['+THRUSKY', '+MF3_EX_DONTBLOCKSPECIES', '+MF3_EX_CANDAMAGEWALLS',
    '+MF3_EX_DAMAGEONPLAYERTOUCH', '+MF3_EX_USEALTDAMAGE', '+MF3_EX_BOBING', '+MF3_EX_PREVENTTHRYSKY',
    '+MF3_EX_LIMITPATROLRANGE', '+MF3_EX_CANSPAWNCHILDREN', '+customPickup'.ToUpper]));
  LInfo := Info('F');
  Assert.IsTrue(LInfo.Flags = [TRadixActorFlag.CustomPickup, TRadixActorFlag.ThruSky,
    TRadixActorFlag.DontBlockSpecies, TRadixActorFlag.CanDamageWalls, TRadixActorFlag.DamageOnPlayerTouch,
    TRadixActorFlag.UseAltDamage, TRadixActorFlag.Bobing, TRadixActorFlag.PreventThruSky,
    TRadixActorFlag.LimitPatrolRange, TRadixActorFlag.CanSpawnChildren]);
end;

procedure TTestRadixActorProperties.DovrebbeTogliereUnFlagColMeno;
begin
  ReadActor('F', '', ['+THRUSKY', '+MF3_EX_BOBING', '-THRUSKY']);
  Assert.IsTrue(Info('F').Flags = [TRadixActorFlag.Bobing]);
end;

procedure TTestRadixActorProperties.DovrebbeLasciareAlLettoreLeParoleCheNonConosce;
begin
  Assert.AreEqual('RADIUS 96 +MF_SOLID +FLOAT STATES',
    ReadActor('X', '', ['RADIUS', '96', '+MF_SOLID', '+FLOAT', 'TouchDamage', '4', 'STATES']));
  Assert.AreEqual(4, Info('X').TouchDamage);
end;

procedure TTestRadixActorProperties.DovrebbeLeggereDannoDaContattoERaggioDiPattuglia;
var
  LInfo: TRadixActorInfo;
begin
  ReadActor('E', '', ['TouchDamage', '5', 'AltDamage', '20', 'PatrolRange', '4096']);
  LInfo := Info('E');
  Assert.AreEqual(5, LInfo.TouchDamage);
  Assert.AreEqual(20, LInfo.AltDamage);
  Assert.AreEqual(4096, LInfo.PatrolRange);
  Assert.IsFalse(LInfo.GivesSomething);
end;

procedure TTestRadixActorProperties.DovrebbeEreditareDalGenitore;
var
  LInfo: TRadixActorInfo;
begin
  ReadActor('BASE', '', ['+CUSTOMPICKUP', 'AMMO', '250', '0', '0', '0', 'PICKUPSOUND', 'radix/SndPowerUp']);
  ReadActor('CHILD', 'base', ['AMMO', '500', '0', '0', '0']);
  LInfo := Info('CHILD');
  Assert.AreEqual(500, LInfo.AmmoInc[0]);
  Assert.IsTrue(TRadixActorFlag.CustomPickup in LInfo.Flags);
  Assert.AreEqual('radix/SndPowerUp', LInfo.PickupSound);
  Assert.AreEqual(250, Info('BASE').AmmoInc[0], 'il genitore non cambia');

  // the child without properties of its own has the ones of the parent
  ReadActor('TWIN', 'BASE', []);
  Assert.AreEqual(250, Info('TWIN').AmmoInc[0]);
end;

procedure TTestRadixActorProperties.DovrebbeNonRicordareUnAttoreSenzaNienteDiRadix;
var
  LInfo: TRadixActorInfo;
begin
  ReadActor('PLAIN', '', ['RADIUS', '16', 'HEIGHT', '10']);
  Assert.IsFalse(FTable.TryGet('PLAIN', LInfo));
  Assert.AreEqual(-1, LInfo.ArmorSet);
  Assert.AreEqual(0, FTable.Count);
end;

procedure TTestRadixActorProperties.DovrebbeCercareINomiSenzaDistinguereLeMaiuscole;
begin
  ReadActor('Mt_Mine', '', ['TOUCHDAMAGE', '9']);
  Assert.AreEqual(9, Info('MT_MINE').TouchDamage);
  Assert.AreEqual(9, Info(' mt_mine ').TouchDamage);
end;

procedure TTestRadixActorProperties.DovrebbeNonCambiareNienteSeDopoSetNonCeUnNumero;
var
  LInfo: TRadixActorInfo;
begin
  ReadActor('B', '', ['ARMOR', 'SET', 'tanto', 'SHIELD', 'PIU', '3', 'TOUCHDAMAGE', 'x']);
  LInfo := Info('B');
  Assert.AreEqual(-1, LInfo.ArmorSet);
  Assert.AreEqual(-1, LInfo.ShieldSet);
  Assert.AreEqual(0, LInfo.ShieldInc);
  Assert.AreEqual(0, LInfo.TouchDamage);
end;

procedure TTestRadixActorProperties.DovrebbeDireCheUnBloccoVuotoNonDaNiente;
begin
  ReadActor('EMPTY', '', ['+CUSTOMPICKUP', 'INVENTORY', 'PICKUPMESSAGE', 'niente']);
  Assert.IsFalse(Info('EMPTY').GivesSomething);
end;

procedure TTestRadixActorProperties.DovrebbeSostituireUnAttoreDefinitoDueVolte;
begin
  ReadActor('D', '', ['TOUCHDAMAGE', '1', 'PLASMABOMB', '2']);
  ReadActor('D', '', ['TOUCHDAMAGE', '7']);
  Assert.AreEqual(7, Info('D').TouchDamage);
  Assert.AreEqual(0, Info('D').PlasmaBomb);
  Assert.AreEqual(1, FTable.Count);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRadixActorProperties);

end.
