{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the declaration manager - entityDef                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Decl.EntityDef;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Decl.Intf, DelphiDoom.Decl.Types, DelphiDoom.Scanner.IdDict,
  DelphiDoom.Tests.Decl.Support;

type
  [TestFixture]
  [Category('Decl')]
  TTestDeclEntityDef = class
  strict private
    FKit: TDeclKit;
    function Dict(const AName: AnsiString): TIdDict;
    procedure Load(const AText: AnsiString);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeLeggereLeCoppie;
    [Test]
    procedure DovrebbeImpostareClassname;
    [Test]
    procedure DovrebbeSegnalareUnaChiaveRipetutaEPrendereLUltima;
    [Test]
    procedure DovrebbeEreditareLeChiaviMancanti;
    [Test]
    procedure DovrebbeNonSovrascrivereLeChiaviProprie;
    [Test]
    procedure DovrebbeEreditareAcatena;
    [Test]
    procedure DovrebbeEreditareDaPiuDiUna;
    [Test]
    procedure DovrebbeSegnalareUnaEreditaSconosciuta;
    [Test]
    procedure DovrebbeFermarsiSuUnCicloDiEredita;
    [Test]
    procedure DovrebbeFermarsiSuUnaEreditaDiSeStessa;
    [Test]
    procedure DovrebbeUsareLaDefinizioneDiDefaultSeLaChiaveNonEUnaStringa;
    [Test]
    procedure DovrebbeUsareLaDefinizioneDiDefaultSeMancaUnValore;
    [Test]
    procedure DovrebbeLeggereLaMapDefComeUnaEntityDef;
    [Test]
    procedure DovrebbeStampareLeCoppie;
    [Test]
    procedure DovrebbeLeggereDiNuovoDopoUnRicaricamento;
    [Test]
    procedure DovrebbeEreditareDaUnaDefinizioneDefault;
  end;

implementation

uses
  DelphiDoom.Decl.EntityDef;

{ TTestDeclEntityDef }

procedure TTestDeclEntityDef.Setup;
begin
  FKit := TDeclKit.Create;
end;

procedure TTestDeclEntityDef.TearDown;
begin
  FreeAndNil(FKit);
end;

procedure TTestDeclEntityDef.Load(const AText: AnsiString);
begin
  FKit.Source.Add('def/test.def', AText);
  FKit.Start(True, False);
  FKit.Manager.GetRegistry.RegisterDeclFolder('def', '.def', DECL_ENTITYDEF);
end;

function TTestDeclEntityDef.Dict(const AName: AnsiString): TIdDict;
var
  LDef: IDeclEntityDef;
begin
  Assert.IsTrue(Supports(FKit.Manager.FindType(DECL_ENTITYDEF, AName), IDeclEntityDef, LDef));
  Result := LDef.GetDict;
end;

procedure TTestDeclEntityDef.DovrebbeLeggereLeCoppie;
var
  LDict: TIdDict;
begin
  Load('entityDef monster { "health" "100" "Model" "imp" }');
  LDict := Dict('monster');
  Assert.AreEqual('100', string(LDict.GetString('health')));
  Assert.AreEqual('imp', string(LDict.GetString('model')));
  Assert.AreEqual(3, LDict.GetNumKeyVals);
end;

procedure TTestDeclEntityDef.DovrebbeImpostareClassname;
begin
  Load('entityDef Monster_Imp { }');
  Assert.AreEqual('monster_imp', string(Dict('MONSTER_IMP').GetString('classname')));
end;

procedure TTestDeclEntityDef.DovrebbeSegnalareUnaChiaveRipetutaEPrendereLUltima;
begin
  Load('entityDef m { "a" "1" "A" "2" }');
  Assert.AreEqual('2', string(Dict('m').GetString('a')));
  Assert.IsTrue(Pos('''A'' already defined', FKit.LogText) > 0, FKit.LogText);
end;

procedure TTestDeclEntityDef.DovrebbeEreditareLeChiaviMancanti;
var
  LDict: TIdDict;
begin
  Load('entityDef base { "health" "50" "model" "base_model" }'#10 +
    'entityDef child { "inherit" "base" "health" "75" }');
  LDict := Dict('child');
  Assert.AreEqual('75', string(LDict.GetString('health')));
  Assert.AreEqual('base_model', string(LDict.GetString('model')));
  Assert.AreEqual('child', string(LDict.GetString('classname')));
  Assert.AreEqual(-1, LDict.MatchPrefix('inherit'));
end;

procedure TTestDeclEntityDef.DovrebbeNonSovrascrivereLeChiaviProprie;
begin
  Load('entityDef base { "a" "base" }'#10'entityDef child { "a" "mine" "inherit" "base" }');
  Assert.AreEqual('mine', string(Dict('child').GetString('a')));
end;

procedure TTestDeclEntityDef.DovrebbeEreditareAcatena;
var
  LDict: TIdDict;
begin
  Load('entityDef c { "inherit" "b" "z" "c" }'#10 +
    'entityDef b { "inherit" "a" "y" "b" "z" "b" }'#10 +
    'entityDef a { "x" "a" "y" "a" "z" "a" }');
  LDict := Dict('c');
  Assert.AreEqual('a', string(LDict.GetString('x')));
  Assert.AreEqual('b', string(LDict.GetString('y')));
  Assert.AreEqual('c', string(LDict.GetString('z')));
  Assert.AreEqual('c', string(LDict.GetString('classname')));
end;

procedure TTestDeclEntityDef.DovrebbeEreditareDaPiuDiUna;
var
  LDict: TIdDict;
begin
  Load('entityDef one { "k" "1" "only1" "x" }'#10'entityDef two { "k" "2" "only2" "y" }'#10 +
    'entityDef both { "inherit" "one" "inherit2" "two" }');
  LDict := Dict('both');
  // the keys are copied in the order the inherit keys were found: the first one wins a conflict
  Assert.AreEqual('1', string(LDict.GetString('k')));
  Assert.AreEqual('x', string(LDict.GetString('only1')));
  Assert.AreEqual('y', string(LDict.GetString('only2')));
end;

procedure TTestDeclEntityDef.DovrebbeSegnalareUnaEreditaSconosciuta;
begin
  Load('entityDef child { "inherit" "nobody" "a" "1" }');
  Assert.AreEqual('1', string(Dict('child').GetString('a')));
  Assert.IsTrue(Pos('Unknown entityDef ''nobody'' inherited by ''child''', FKit.LogText) > 0, FKit.LogText);
  // an unknown inherit does not create a decl
  Assert.IsFalse(Assigned(FKit.Manager.FindType(DECL_ENTITYDEF, 'nobody', False)));
end;

procedure TTestDeclEntityDef.DovrebbeFermarsiSuUnCicloDiEredita;
var
  LA, LB: TIdDict;
begin
  Load('entityDef a { "inherit" "b" "ka" "a" }'#10'entityDef b { "inherit" "a" "kb" "b" }');
  LA := Dict('a');
  LB := Dict('b');
  // a is being parsed when b asks for it: b gets the keys a had at that point
  Assert.AreEqual('a', string(LA.GetString('ka')));
  Assert.AreEqual('b', string(LA.GetString('kb')));
  Assert.AreEqual('b', string(LB.GetString('kb')));
  Assert.AreEqual('a', string(LB.GetString('ka')));
end;

procedure TTestDeclEntityDef.DovrebbeFermarsiSuUnaEreditaDiSeStessa;
begin
  Load('entityDef a { "inherit" "a" "k" "v" }');
  Assert.AreEqual('v', string(Dict('a').GetString('k')));
  Assert.AreEqual(-1, Dict('a').MatchPrefix('inherit'));
end;

procedure TTestDeclEntityDef.DovrebbeUsareLaDefinizioneDiDefaultSeLaChiaveNonEUnaStringa;
var
  LDecl: IDecl;
begin
  Load('entityDef bad { key "value" }');
  LDecl := FKit.Manager.FindType(DECL_ENTITYDEF, 'bad');
  Assert.IsTrue(LDecl.GetState = dsDefaulted);
  Assert.AreEqual('1', string(Dict('bad').GetString('DEFAULTED')));
  Assert.IsTrue(Pos('Expected quoted string, but found ''key''', FKit.LogText) > 0, FKit.LogText);
end;

procedure TTestDeclEntityDef.DovrebbeUsareLaDefinizioneDiDefaultSeMancaUnValore;
begin
  Load('entityDef bad { "key" }');
  // the closing brace is taken as the value, then the text ends: the key keeps "}" as its value
  Assert.IsTrue(FKit.Manager.FindType(DECL_ENTITYDEF, 'bad').GetState = dsParsed);
  Assert.AreEqual('}', string(Dict('bad').GetString('key')));
end;

procedure TTestDeclEntityDef.DovrebbeLeggereLaMapDefComeUnaEntityDef;
var
  LDef: IDeclEntityDef;
begin
  FKit.Source.Add('def/test.def', 'mapDef maps/level1 { "name" "First" }');
  FKit.Start(True, False);
  FKit.Manager.GetRegistry.RegisterDeclFolder('def', '.def', DECL_ENTITYDEF);
  Assert.IsTrue(Supports(FKit.Manager.FindType(DECL_MAPDEF, 'maps/level1'), IDeclEntityDef, LDef));
  Assert.AreEqual('First', string(LDef.GetDict.GetString('name')));
  Assert.AreEqual('maps/level1', string(LDef.GetDict.GetString('classname')));
end;

procedure TTestDeclEntityDef.DovrebbeStampareLeCoppie;
begin
  Load('entityDef m { "a" "1" }');
  Dict('m');
  FKit.Lines.Clear;
  FKit.Manager.PrintType(DECL_ENTITYDEF, 'm');
  Assert.IsTrue(Pos('entityDef m:', FKit.LogText) > 0, FKit.LogText);
  Assert.IsTrue(Pos('Parsed.', FKit.LogText) > 0, FKit.LogText);
  Assert.IsTrue(Pos('a', FKit.LogText) > 0);
end;

procedure TTestDeclEntityDef.DovrebbeLeggereDiNuovoDopoUnRicaricamento;
begin
  Load('entityDef m { "a" "1" "b" "2" }');
  Assert.AreEqual('2', string(Dict('m').GetString('b')));
  FKit.Source.Add('def/test.def', 'entityDef m { "a" "9" }');
  FKit.Manager.Reload(False);
  Assert.AreEqual('9', string(Dict('m').GetString('a')));
  // the data is freed before every parse: the old key is gone
  Assert.AreEqual('', string(Dict('m').GetString('b')));
end;

procedure TTestDeclEntityDef.DovrebbeEreditareDaUnaDefinizioneDefault;
begin
  // the parent is not found: FindType(.., False) does not make a default, so nothing is inherited
  // and the key is dropped: only "classname" is left
  Load('entityDef child { "inherit" "parent" }');
  Assert.AreEqual(1, Dict('child').GetNumKeyVals);
  Assert.AreEqual(0, FKit.Manager.GetNumDecls(DECL_ENTITYDEF) - 1);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDeclEntityDef);

end.
