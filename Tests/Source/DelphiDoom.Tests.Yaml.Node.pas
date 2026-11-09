{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the yaml library - the node handle                     }
{  (the behaviours of YAML::Node that the parity corpus does not reach: it     }
{  only loads)                                                                 }
{  Port of yaml-cpp 0.7.0 (MIT, Jesse Beder): see Libs\Yaml\README.md          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Yaml.Node;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Yaml.Types,
  DelphiDoom.Yaml.Intf;

type
  [TestFixture]
  [Category('yaml')]
  TTestYamlNode = class(TObject)
  strict private
    function Load(const AText: string): IYamlNode;
  public
    [Test]
    procedure DovrebbeTrovareIValoriPerChiave;
    [Test]
    procedure DovrebbeDareUnNodoNonValidoPerUnaChiaveMancanteConIlSuoNome;
    [Test]
    procedure DovrebbeCreareUnaVoceNonDefinitaFinoAllAssegnazione;
    [Test]
    procedure DovrebbeTrasformareUnaSequenzaInMappaConUnaChiaveDiTesto;
    [Test]
    procedure DovrebbeAggiungereElementiAUnaSequenza;
    [Test]
    procedure DovrebbeIndicizzareUnaSequenzaECrescere;
    [Test]
    procedure DovrebbeRimuovereUnaChiaveEUnIndice;
    [Test]
    procedure DovrebbeDareLoStessoNodoPerAncoraEAlias;
    [Test]
    procedure DovrebbeCaricareEClonareUnDocumentoCheContieSeStesso;
    [Test]
    procedure DovrebbeClonareSenzaCondividereIDati;
    [Test]
    procedure DovrebbeAssegnareUnNodoPerRiferimento;
    [Test]
    procedure DovrebbeUsareIValoriDiDefaultSoloSeLaConversioneFallisce;
    [Test]
    procedure DovrebbeDareNullPerUnNodoNullComeStringa;
    [Test]
    procedure DovrebbeSollevareUnaEccezioneSuUnaConversioneImpossibile;
    [Test]
    procedure DovrebbeSollevareUnaEccezioneSuUnoScalareIndicizzato;
    [Test]
    procedure DovrebbeDareLaPosizioneDeiNodiLetti;
    [Test]
    procedure DovrebbeInserireCoppieSenzaCercareLaChiave;
    [Test]
    procedure DovrebbeSaltareLeCoppieNonDefiniteNellIterazione;
    [Test]
    procedure DovrebbeUnireLaMemoriaDeiNodiAggiunti;
  end;

implementation

uses
  DelphiDoom.Yaml.Factory;

function TTestYamlNode.Load(const AText: string): IYamlNode;
begin
  Result := TYamlFactory.CreateParser.Load(YamlStringToText(AText));
end;

procedure TTestYamlNode.DovrebbeTrovareIValoriPerChiave;
var
  LNode: IYamlNode;
begin
  LNode := Load('name: Rifle'#10'cost: 12'#10'tags: [a, b]'#10);
  Assert.IsTrue(LNode.IsMap);
  Assert.AreEqual(3, LNode.Size);
  Assert.AreEqual('Rifle', LNode.Find('name').ScalarString);
  Assert.AreEqual(12, LNode.Find('cost').AsInteger);
  Assert.AreEqual(2, LNode.Find('tags').Size);
  Assert.IsTrue(LNode.Find('tags').IsSequence);
  Assert.AreEqual('b', LNode.Find('tags').Find(1).ScalarString);
end;

procedure TTestYamlNode.DovrebbeDareUnNodoNonValidoPerUnaChiaveMancanteConIlSuoNome;
var
  LMissing: IYamlNode;
  LCaught: Boolean;
begin
  LMissing := Load('a: 1').Find('zzz');
  Assert.IsFalse(LMissing.IsDefined);
  LCaught := False;
  try
    LMissing.AsInteger;
  except
    on E: EYamlInvalidNode do
    begin
      LCaught := True;
      Assert.AreEqual('invalid node; first invalid key: "zzz"', YamlTextToString(E.Msg));
    end;
  end;
  Assert.IsTrue(LCaught);
  Assert.AreEqual(7, LMissing.AsInteger(7), 'con un valore di default non ci sono eccezioni');
end;

procedure TTestYamlNode.DovrebbeCreareUnaVoceNonDefinitaFinoAllAssegnazione;
var
  LNode, LChild: IYamlNode;
begin
  LNode := Load('a: 1');
  LChild := LNode.Child('b');
  Assert.IsFalse(LChild.IsDefined, 'la voce nuova non e'' definita');
  Assert.AreEqual(1, LNode.Size, 'e non conta');
  LChild.AssignScalar('2');
  Assert.IsTrue(LChild.IsDefined);
  Assert.AreEqual(2, LNode.Size, 'ora si');
  Assert.AreEqual(2, LNode.Find('b').AsInteger);
end;

procedure TTestYamlNode.DovrebbeTrasformareUnaSequenzaInMappaConUnaChiaveDiTesto;
var
  LNode: IYamlNode;
begin
  LNode := Load('[x, y]');
  LNode.Child('k').AssignScalar('v');
  Assert.IsTrue(LNode.IsMap);
  Assert.AreEqual('x', LNode.Find('0').ScalarString);
  Assert.AreEqual('y', LNode.Find('1').ScalarString);
  Assert.AreEqual('v', LNode.Find('k').ScalarString);
end;

procedure TTestYamlNode.DovrebbeAggiungereElementiAUnaSequenza;
var
  LNode: IYamlNode;
begin
  LNode := TYamlFactory.CreateNode;
  LNode.Add('one');
  LNode.Add(TYamlFactory.CreateScalar('two'));
  Assert.IsTrue(LNode.IsSequence);
  Assert.AreEqual(2, LNode.Size);
  Assert.AreEqual('two', LNode.Items[1].ScalarString);
  Assert.AreEqual('- one'#10'- two', YamlTextToString(TYamlFactory.Dump(LNode)));
end;

procedure TTestYamlNode.DovrebbeIndicizzareUnaSequenzaECrescere;
var
  LNode: IYamlNode;
begin
  LNode := Load('[a]');
  LNode.Child(1).AssignScalar('b');
  Assert.AreEqual(2, LNode.Size);
  Assert.IsFalse(LNode.Find(5).IsDefined, 'un indice oltre la fine');
  Assert.IsTrue(LNode.IsSequence);
end;

procedure TTestYamlNode.DovrebbeRimuovereUnaChiaveEUnIndice;
var
  LMap, LSeq: IYamlNode;
begin
  LMap := Load('a: 1'#10'b: 2'#10);
  Assert.IsTrue(LMap.Remove('a'));
  Assert.IsFalse(LMap.Remove('a'));
  Assert.AreEqual(1, LMap.Size);
  LSeq := Load('[x, y, z]');
  Assert.IsTrue(LSeq.Remove(1));
  Assert.AreEqual(2, LSeq.Size);
  Assert.AreEqual('z', LSeq.Items[1].ScalarString);
  Assert.IsFalse(LSeq.Remove(9));
end;

procedure TTestYamlNode.DovrebbeDareLoStessoNodoPerAncoraEAlias;
var
  LNode: IYamlNode;
begin
  LNode := Load('first: &a {x: 1}'#10'second: *a'#10);
  Assert.IsTrue(LNode.Find('first').SameNode(LNode.Find('second')));
  LNode.Find('second').Child('x').AssignScalar('9');
  Assert.AreEqual(9, LNode.Find('first').Find('x').AsInteger, 'una modifica si vede da tutti e due');
  Assert.AreEqual('first: &1 {x: 9}'#10'second: *1', YamlTextToString(TYamlFactory.Dump(LNode)));
end;

procedure TTestYamlNode.DovrebbeCaricareEClonareUnDocumentoCheContieSeStesso;
var
  LNode, LCopy: IYamlNode;
  LText: string;
begin
  LNode := Load('&a [*a, 1]');
  Assert.IsTrue(LNode.IsSequence);
  Assert.AreEqual(2, LNode.Size);
  Assert.IsTrue(LNode.Items[0].SameNode(LNode), 'l''elemento e'' il nodo stesso');
  LText := YamlTextToString(TYamlFactory.Dump(LNode));
  Assert.AreEqual('&1 [*1, 1]', LText);
  LCopy := TYamlFactory.Clone(LNode);
  Assert.IsTrue(LCopy.Items[0].SameNode(LCopy));
  Assert.IsFalse(LCopy.SameNode(LNode));
end;

procedure TTestYamlNode.DovrebbeClonareSenzaCondividereIDati;
var
  LNode, LCopy: IYamlNode;
begin
  LNode := Load('a: [1, 2]');
  LCopy := TYamlFactory.Clone(LNode);
  LCopy.Find('a').Add('3');
  Assert.AreEqual(2, LNode.Find('a').Size);
  Assert.AreEqual(3, LCopy.Find('a').Size);
end;

procedure TTestYamlNode.DovrebbeAssegnareUnNodoPerRiferimento;
var
  LA, LB: IYamlNode;
begin
  LA := Load('a: 1');
  LB := Load('b: 2');
  LA.Child('copy').Assign(LB);
  Assert.IsTrue(LA.Find('copy').SameNode(LB));
  LB.Child('c').AssignScalar('3');
  Assert.AreEqual(3, LA.Find('copy').Find('c').AsInteger);
end;

procedure TTestYamlNode.DovrebbeUsareIValoriDiDefaultSoloSeLaConversioneFallisce;
var
  LNode: IYamlNode;
begin
  LNode := Load('a: 5'#10'b: abc'#10'c: [1]'#10);
  Assert.AreEqual(5, LNode.Find('a').AsInteger(99));
  Assert.AreEqual(99, LNode.Find('b').AsInteger(99));
  Assert.AreEqual(99, LNode.Find('c').AsInteger(99));
  Assert.AreEqual(99, LNode.Find('zz').AsInteger(99));
  Assert.IsTrue(LNode.Find('a').AsBoolean(True));
  Assert.AreEqual(2.5, LNode.Find('b').AsDouble(2.5), 0);
  Assert.AreEqual('fallback', YamlTextToString(LNode.Find('c').AsString('fallback')));
end;

procedure TTestYamlNode.DovrebbeDareNullPerUnNodoNullComeStringa;
var
  LNode: IYamlNode;
begin
  LNode := Load('a: ~'#10);
  Assert.IsTrue(LNode.Find('a').IsNull);
  Assert.AreEqual('null', YamlTextToString(LNode.Find('a').AsString));
  Assert.AreEqual('null', YamlTextToString(LNode.Find('a').AsString('x')), 'anche con il default');
end;

procedure TTestYamlNode.DovrebbeSollevareUnaEccezioneSuUnaConversioneImpossibile;
var
  LNode: IYamlNode;
begin
  LNode := Load('a: abc'#10'b: 3000000000'#10);
  Assert.WillRaise(procedure begin LNode.Find('a').AsInteger end, EYamlBadConversion);
  Assert.WillRaise(procedure begin LNode.Find('b').AsInteger end, EYamlBadConversion);
  Assert.AreEqual(Int64(3000000000), LNode.Find('b').AsInt64);
  Assert.WillRaise(procedure begin LNode.AsString end, EYamlBadConversion);
end;

procedure TTestYamlNode.DovrebbeSollevareUnaEccezioneSuUnoScalareIndicizzato;
var
  LNode: IYamlNode;
  LMessage: string;
begin
  LNode := Load('a: abc'#10);
  LMessage := '';
  try
    LNode.Find('a').Find('x');
  except
    on E: EYamlBadSubscript do
      LMessage := E.Message;
  end;
  Assert.AreEqual('yaml-cpp: error at line 1, column 4: operator[] call on a scalar (key: "x")', LMessage);
end;

procedure TTestYamlNode.DovrebbeDareLaPosizioneDeiNodiLetti;
var
  LNode: IYamlNode;
begin
  LNode := Load('a: 1'#10'bb:'#10'  - x'#10);
  Assert.AreEqual(0, LNode.Mark.Line);
  Assert.AreEqual(2, LNode.Find('bb').Mark.Line, 'il nodo comincia dove comincia il suo primo elemento');
  Assert.AreEqual(2, LNode.Find('bb').Items[0].Mark.Line);
  Assert.AreEqual(4, LNode.Find('bb').Items[0].Mark.Column);
  Assert.IsTrue(TYamlFactory.CreateNode.Mark.IsNull);
end;

procedure TTestYamlNode.DovrebbeInserireCoppieSenzaCercareLaChiave;
var
  LNode: IYamlNode;
begin
  LNode := TYamlFactory.CreateNode(ntMap);
  LNode.ForceInsert('k', '1');
  LNode.ForceInsert('k', '2');
  Assert.AreEqual(2, LNode.Size);
  Assert.AreEqual(1, LNode.Find('k').AsInteger, 'la ricerca trova la prima');
end;

procedure TTestYamlNode.DovrebbeSaltareLeCoppieNonDefiniteNellIterazione;
var
  LNode: IYamlNode;
begin
  LNode := Load('a: 1');
  LNode.Child('pending');
  Assert.AreEqual(1, Integer(Length(LNode.Pairs)));
  LNode.Child('pending').AssignScalar('x');
  Assert.AreEqual(2, Integer(Length(LNode.Pairs)));
end;

procedure TTestYamlNode.DovrebbeUnireLaMemoriaDeiNodiAggiunti;
var
  LRoot, LChild: IYamlNode;
begin
  LRoot := TYamlFactory.CreateNode(ntSequence);
  LChild := TYamlFactory.CreateNode(ntMap);
  LChild.Child('k').AssignScalar('v');
  LRoot.Add(LChild);
  // the child handle and the root share the memory: dropping the child handle keeps the node alive
  LChild := nil;
  Assert.AreEqual('v', LRoot.Items[0].Find('k').ScalarString);
end;

end.
