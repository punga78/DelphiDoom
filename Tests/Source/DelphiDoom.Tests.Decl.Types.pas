{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the declaration manager - table and skin               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Decl.Types;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Decl.Intf, DelphiDoom.Decl.Types, DelphiDoom.Decl.Skin,
  DelphiDoom.Tests.Decl.Support;

type
  [TestFixture]
  [Category('Decl')]
  TTestDeclTable = class
  strict private
    FKit: TDeclKit;
    function Table(const ABody: AnsiString): IInterface;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeInterpolareFraDueValori;
    [Test]
    procedure DovrebbeSaltareAlValoreConSnap;
    [Test]
    procedure DovrebbeRipeterePerDefaultFuoriDaZeroUno;
    [Test]
    procedure DovrebbeFermarsiAgliEstremiConClamp;
    [Test]
    procedure DovrebbeRipeterePerDefaultIndiciNegativi;
    [Test]
    procedure DovrebbeDareUnoSeHaPocoValori;
    [Test]
    procedure DovrebbeAggiungereInCodaIlPrimoValore;
    [Test]
    procedure DovrebbeUsareLaDefinizioneDiDefaultSeNonNumerico;
    [Test]
    procedure DovrebbeUsareLaDefinizioneDiDefaultSeMancaLaVirgola;
    [Test]
    procedure DovrebbeUsareLaDefinizioneDiDefaultConUnaParolaSconosciuta;
    [Test]
    procedure DovrebbeLasciareVuotaUnaTabellaSenzaValori;
  end;

  [TestFixture]
  [Category('Decl')]
  TTestDeclSkin = class
  strict private
    FKit: TDeclKit;
    function Skin(const AName: AnsiString): IDeclSkin;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeLeggereModelliEMappature;
    [Test]
    procedure DovrebbeSostituireUnMateriale;
    [Test]
    procedure DovrebbeUsareIlJollyDopoLeMappatureSpecifiche;
    [Test]
    procedure DovrebbeLasciareStareUnMaterialeNonMappato;
    [Test]
    procedure DovrebbeLasciareStareUnMaterialeNonDisegnato;
    [Test]
    procedure DovrebbeRestituireNilPerNil;
    [Test]
    procedure DovrebbeDareStringaVuotaPerUnModelloFuoriLimite;
    [Test]
    procedure DovrebbeUsareLaDefinizioneDiDefaultSeFinisceTroppoPresto;
    [Test]
    procedure DovrebbeGenerareUnaSkinImplicitaPerUnMateriale;
    [Test]
    procedure DovrebbeCrearePerDefaultUnaSkinSenzaMateriale;
  end;

implementation

uses
  DelphiDoom.Decl.Table;

const
  EPSILON = 0.00001;

{ TTestDeclTable }

procedure TTestDeclTable.Setup;
begin
  FKit := TDeclKit.Create;
  FKit.Start(True, False);
end;

procedure TTestDeclTable.TearDown;
begin
  FreeAndNil(FKit);
end;

function TTestDeclTable.Table(const ABody: AnsiString): IInterface;
begin
  FKit.Source.Add('defs/t.def', 'table t ' + ABody);
  FKit.Manager.GetRegistry.RegisterDeclFolder('defs', '.def', DECL_TABLE);
  Result := FKit.Manager.FindType(DECL_TABLE, 't');
end;

procedure TTestDeclTable.DovrebbeInterpolareFraDueValori;
var
  LTable: IDeclTable;
begin
  Assert.IsTrue(Supports(Table('{ { 0, 1, 0, 1 } }'), IDeclTable, LTable));
  // 4 values + the copy of the first: domain 4; a position of 0.125 is half way through the first step
  Assert.AreEqual(Single(0.5), LTable.TableLookup(0.125), EPSILON);
  Assert.AreEqual(Single(1.0), LTable.TableLookup(0.25), EPSILON);
  Assert.AreEqual(Single(0.5), LTable.TableLookup(0.375), EPSILON);
  Assert.AreEqual(Single(0.0), LTable.TableLookup(0.5), EPSILON);
end;

procedure TTestDeclTable.DovrebbeSaltareAlValoreConSnap;
var
  LTable: IDeclTable;
begin
  Assert.IsTrue(Supports(Table('{ snap { 0, 1, 2, 3 } }'), IDeclTable, LTable));
  Assert.IsTrue(LTable.GetSnap);
  Assert.AreEqual(Single(1.0), LTable.TableLookup(0.3), EPSILON);
  Assert.AreEqual(Single(3.0), LTable.TableLookup(0.9), EPSILON);
end;

procedure TTestDeclTable.DovrebbeRipeterePerDefaultFuoriDaZeroUno;
var
  LTable: IDeclTable;
begin
  Assert.IsTrue(Supports(Table('{ snap { 0, 1, 2, 3 } }'), IDeclTable, LTable));
  Assert.AreEqual(Single(1.0), LTable.TableLookup(1.3), EPSILON);
  Assert.AreEqual(Single(0.0), LTable.TableLookup(1.0), EPSILON);
end;

procedure TTestDeclTable.DovrebbeFermarsiAgliEstremiConClamp;
var
  LTable: IDeclTable;
begin
  Assert.IsTrue(Supports(Table('{ clamp { 0, 10, 20, 30 } }'), IDeclTable, LTable));
  Assert.IsTrue(LTable.GetClamp);
  Assert.AreEqual(Single(0.0), LTable.TableLookup(-5), EPSILON);
  Assert.AreEqual(Single(30.0), LTable.TableLookup(5), EPSILON);
  Assert.AreEqual(Single(15.0), LTable.TableLookup(0.5), EPSILON);
end;

procedure TTestDeclTable.DovrebbeRipeterePerDefaultIndiciNegativi;
var
  LTable: IDeclTable;
begin
  Assert.IsTrue(Supports(Table('{ snap { 0, 1, 2, 3 } }'), IDeclTable, LTable));
  Assert.AreEqual(Single(3.0), LTable.TableLookup(-0.1), EPSILON);
end;

procedure TTestDeclTable.DovrebbeDareUnoSeHaPocoValori;
var
  LTable: IDeclTable;
begin
  Assert.IsTrue(Supports(Table('{ { 7 } }'), IDeclTable, LTable));
  Assert.AreEqual(Single(1.0), LTable.TableLookup(0.5), EPSILON);
  Assert.IsTrue(Supports(FKit.Manager.FindType(DECL_TABLE, 'two'), IDeclTable, LTable));
  Assert.AreEqual(Single(1.0), LTable.TableLookup(0.5), EPSILON);
end;

procedure TTestDeclTable.DovrebbeAggiungereInCodaIlPrimoValore;
var
  LTable: IDeclTable;
begin
  Assert.IsTrue(Supports(Table('{ { 4, 5, 6 } }'), IDeclTable, LTable));
  Assert.AreEqual(4, LTable.GetNumValues);
  Assert.AreEqual(Single(4.0), LTable.GetValue(3), EPSILON);
end;

procedure TTestDeclTable.DovrebbeUsareLaDefinizioneDiDefaultSeNonNumerico;
var
  LDecl: IDecl;
begin
  LDecl := FKit.Manager.FindType(DECL_TABLE, 'x');
  Assert.IsNotNull(LDecl);
  FKit.Source.Add('defs/t.def', 'table bad { { 1, two } }');
  FKit.Manager.GetRegistry.RegisterDeclFolder('defs', '.def', DECL_TABLE);
  LDecl := FKit.Manager.FindType(DECL_TABLE, 'bad');
  Assert.IsTrue(LDecl.GetState = dsDefaulted);
end;

procedure TTestDeclTable.DovrebbeUsareLaDefinizioneDiDefaultSeMancaLaVirgola;
var
  LDecl: IDecl;
begin
  FKit.Source.Add('defs/t.def', 'table bad { { 1 2 } }');
  FKit.Manager.GetRegistry.RegisterDeclFolder('defs', '.def', DECL_TABLE);
  LDecl := FKit.Manager.FindType(DECL_TABLE, 'bad');
  Assert.IsTrue(LDecl.GetState = dsDefaulted);
  Assert.IsTrue(Pos('expected comma or brace', FKit.LogText) > 0, FKit.LogText);
end;

procedure TTestDeclTable.DovrebbeUsareLaDefinizioneDiDefaultConUnaParolaSconosciuta;
var
  LDecl: IDecl;
begin
  FKit.Source.Add('defs/t.def', 'table bad { wobble { 1 } }');
  FKit.Manager.GetRegistry.RegisterDeclFolder('defs', '.def', DECL_TABLE);
  LDecl := FKit.Manager.FindType(DECL_TABLE, 'bad');
  Assert.IsTrue(LDecl.GetState = dsDefaulted);
  Assert.IsTrue(Pos('unknown token ''wobble''', FKit.LogText) > 0, FKit.LogText);
end;

procedure TTestDeclTable.DovrebbeLasciareVuotaUnaTabellaSenzaValori;
var
  LTable: IDeclTable;
begin
  Assert.IsTrue(Supports(Table('{ snap }'), IDeclTable, LTable));
  Assert.AreEqual(0, LTable.GetNumValues);
  Assert.AreEqual(Single(1.0), LTable.TableLookup(0.2), EPSILON);
end;

{ TTestDeclSkin }

procedure TTestDeclSkin.Setup;
begin
  FKit := TDeclKit.Create;
  FKit.Source.Add('skins/a.skin',
    'skin s1 { model "models/a.md5mesh" model "b" "mat/one" "mat/uno" "mat/two" "mat/due" "*" "mat/any" }'#10 +
    'skin s2 { "*" "mat/all" }'#10 +
    'skin s3 { "mat/x" "mat/y" }');
  FKit.Start;
end;

procedure TTestDeclSkin.TearDown;
begin
  FreeAndNil(FKit);
end;

function TTestDeclSkin.Skin(const AName: AnsiString): IDeclSkin;
begin
  Assert.IsTrue(Supports(FKit.Manager.FindType(DECL_SKIN, AName), IDeclSkin, Result));
end;

procedure TTestDeclSkin.DovrebbeLeggereModelliEMappature;
var
  LSkin: IDeclSkin;
begin
  LSkin := Skin('s1');
  Assert.AreEqual(2, LSkin.GetNumModelAssociations);
  Assert.AreEqual('models/a.md5mesh', string(LSkin.GetAssociatedModel(0)));
  Assert.AreEqual('b', string(LSkin.GetAssociatedModel(1)));
  Assert.AreEqual(3, LSkin.GetNumMappings);
  Assert.AreEqual('mat/one', string(LSkin.GetMappingFrom(0).GetName));
  Assert.AreEqual('mat/uno', string(LSkin.GetMappingTo(0).GetName));
  Assert.IsFalse(Assigned(LSkin.GetMappingFrom(2)));
  Assert.AreEqual('mat/any', string(LSkin.GetMappingTo(2).GetName));
end;

procedure TTestDeclSkin.DovrebbeSostituireUnMateriale;
var
  LSkin: IDeclSkin;
  LMaterial: IDecl;
begin
  LSkin := Skin('s1');
  LMaterial := FKit.Manager.FindType(DECL_MATERIAL, 'mat/two');
  Assert.AreEqual('mat/due', string(LSkin.RemapShaderBySkin(LMaterial).GetName));
end;

procedure TTestDeclSkin.DovrebbeUsareIlJollyDopoLeMappatureSpecifiche;
var
  LSkin: IDeclSkin;
begin
  LSkin := Skin('s1');
  Assert.AreEqual('mat/any', string(LSkin.RemapShaderBySkin(FKit.Manager.FindType(DECL_MATERIAL, 'mat/other')).GetName));
  Assert.AreEqual('mat/all', string(Skin('s2').RemapShaderBySkin(FKit.Manager.FindType(DECL_MATERIAL, 'mat/one')).GetName));
end;

procedure TTestDeclSkin.DovrebbeLasciareStareUnMaterialeNonMappato;
var
  LMaterial: IDecl;
begin
  LMaterial := FKit.Manager.FindType(DECL_MATERIAL, 'mat/untouched');
  Assert.IsTrue(Skin('s3').RemapShaderBySkin(LMaterial) = LMaterial);
end;

procedure TTestDeclSkin.DovrebbeLasciareStareUnMaterialeNonDisegnato;
var
  LMaterial: IDecl;
begin
  LMaterial := FKit.Manager.FindType(DECL_MATERIAL, 'mat/one');
  Assert.IsTrue(Skin('s1').RemapShaderBySkin(LMaterial, False) = LMaterial);
end;

procedure TTestDeclSkin.DovrebbeRestituireNilPerNil;
begin
  Assert.IsFalse(Assigned(Skin('s1').RemapShaderBySkin(nil)));
end;

procedure TTestDeclSkin.DovrebbeDareStringaVuotaPerUnModelloFuoriLimite;
begin
  Assert.AreEqual('', string(Skin('s1').GetAssociatedModel(2)));
  Assert.AreEqual('', string(Skin('s1').GetAssociatedModel(-1)));
end;

procedure TTestDeclSkin.DovrebbeUsareLaDefinizioneDiDefaultSeFinisceTroppoPresto;
var
  LSkin: IDeclSkin;
begin
  // a text that ends after the first name of a pair (only a SetText can make it: the loader balances braces)
  // is defaulted to { "*" "_default" }
  FKit.Manager.FindType(DECL_SKIN, 's4').SetText('skin s4 { "mat/x"');
  FKit.Manager.FindType(DECL_SKIN, 's4').Invalidate;
  FKit.Manager.FindType(DECL_SKIN, 's4');
  LSkin := Skin('s4');
  Assert.IsTrue(FKit.Manager.FindType(DECL_SKIN, 's4').GetState = dsDefaulted);
  Assert.AreEqual(1, LSkin.GetNumMappings);
  Assert.AreEqual('_default', string(LSkin.GetMappingTo(0).GetName));
  Assert.IsTrue(Pos('Unexpected end of file', FKit.LogText) > 0);
end;

procedure TTestDeclSkin.DovrebbeGenerareUnaSkinImplicitaPerUnMateriale;
var
  LSkin: IDeclSkin;
  LDecl: IDecl;
begin
  FKit.Manager.FindType(DECL_MATERIAL, 'textures/wall');
  LDecl := FKit.Manager.FindType(DECL_SKIN, 'textures/wall');
  Assert.IsTrue(Supports(LDecl, IDeclSkin, LSkin));
  Assert.IsTrue(LDecl.GetState = dsParsed);
  Assert.AreEqual(1, LSkin.GetNumMappings);
  Assert.AreEqual('textures/wall', string(LSkin.GetMappingTo(0).GetName) + '');
end;

procedure TTestDeclSkin.DovrebbeCrearePerDefaultUnaSkinSenzaMateriale;
var
  LDecl: IDecl;
begin
  LDecl := FKit.Manager.FindType(DECL_SKIN, 'textures/none');
  Assert.IsTrue(LDecl.GetState = dsDefaulted);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDeclTable);
  TDUnitX.RegisterTestFixture(TTestDeclSkin);

end.
