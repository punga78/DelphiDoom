{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the yaml library - the emitter                         }
{  (examples written by hand; the corpora of the parity tests do the rest)     }
{  Port of yaml-cpp 0.7.0 (MIT, Jesse Beder): see Libs\Yaml\README.md          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Yaml.Emitter;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Yaml.Types,
  DelphiDoom.Yaml.Intf;

type
  [TestFixture]
  [Category('yaml')]
  TTestYamlEmitter = class(TObject)
  strict private
    FEmitter: IYamlEmitter;
    function Out: string;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeScrivereUnaMappaConUnaSequenza;
    [Test]
    procedure DovrebbeScrivereInFlussoQuandoSiChiede;
    [Test]
    procedure DovrebbeScrivereUnaMappaVuotaEUnaSequenzaVuotaInFlusso;
    [Test]
    procedure DovrebbeCitareLeStringheCheNonSonoSemplici;
    [Test]
    procedure DovrebbeScrivereIlTestoSuPiuRigheComeLetterale;
    [Test]
    procedure DovrebbeScrivereGliInteriInBaseDiversa;
    [Test]
    procedure DovrebbeScrivereIDecimaliConLaPrecisioneChiesta;
    [Test]
    procedure DovrebbeScrivereAncoreAliasETag;
    [Test]
    procedure DovrebbeScrivereICommentiEIDocumenti;
    [Test]
    procedure DovrebbeScrivereIlBinarioInBase64;
    [Test]
    procedure DovrebbeEscapareIlNonAsciiSeLoSiChiede;
    [Test]
    procedure DovrebbeRestareInErroreDopoUnaChiusuraSenzaApertura;
    [Test]
    procedure DovrebbeSegnalareUnAncoraNonValida;
    [Test]
    procedure DovrebbeScrivereUnNodoCaricatoComeLOriginale;
    [Test]
    procedure DovrebbeDareLeStesseImpostazioniGlobaliDiYamlCpp;
  end;

implementation

uses
  System.Math,
  DelphiDoom.Yaml.Factory;

const
  Backslash = '\';

function TTestYamlEmitter.Out: string;
begin
  Result := YamlTextToString(FEmitter.Text);
end;

procedure TTestYamlEmitter.Setup;
begin
  FEmitter := TYamlFactory.CreateEmitter;
end;

procedure TTestYamlEmitter.DovrebbeScrivereUnaMappaConUnaSequenza;
begin
  FEmitter.Manip(ymBeginMap);
  FEmitter.Manip(ymKey);
  FEmitter.WriteString('name');
  FEmitter.Manip(ymValue);
  FEmitter.WriteString('Rifle');
  FEmitter.Manip(ymKey);
  FEmitter.WriteString('tags');
  FEmitter.Manip(ymValue);
  FEmitter.Manip(ymBeginSeq);
  FEmitter.WriteInteger(1);
  FEmitter.WriteBool(True);
  FEmitter.WriteNull;
  FEmitter.Manip(ymEndSeq);
  FEmitter.Manip(ymEndMap);
  Assert.IsTrue(FEmitter.Good);
  Assert.AreEqual('name: Rifle'#10'tags:'#10'  - 1'#10'  - true'#10'  - ~', Out);
  Assert.AreEqual(Integer(Length(Out)), FEmitter.Size);
end;

procedure TTestYamlEmitter.DovrebbeScrivereInFlussoQuandoSiChiede;
begin
  FEmitter.Manip(ymFlow);
  FEmitter.Manip(ymBeginSeq);
  FEmitter.WriteInteger(1);
  FEmitter.WriteString('a b');
  FEmitter.Manip(ymEndSeq);
  Assert.AreEqual('[1, a b]', Out);
end;

procedure TTestYamlEmitter.DovrebbeScrivereUnaMappaVuotaEUnaSequenzaVuotaInFlusso;
begin
  FEmitter.Manip(ymBeginSeq);
  FEmitter.Manip(ymBeginMap);
  FEmitter.Manip(ymEndMap);
  FEmitter.Manip(ymBeginSeq);
  FEmitter.Manip(ymEndSeq);
  FEmitter.Manip(ymEndSeq);
  Assert.AreEqual('- {}'#10'-'#10'  []', Out);
end;

procedure TTestYamlEmitter.DovrebbeCitareLeStringheCheNonSonoSemplici;
begin
  FEmitter.Manip(ymBeginSeq);
  FEmitter.WriteString('');
  FEmitter.WriteString('null');
  FEmitter.WriteString('a: b');
  FEmitter.WriteString('# c');
  FEmitter.WriteString(' lead');
  FEmitter.WriteString('x'#10'y');
  FEmitter.WriteString('plain text');
  FEmitter.Manip(ymEndSeq);
  Assert.AreEqual('- ""'#10'- "null"'#10'- "a: b"'#10'- "# c"'#10'- " lead"'#10'- "x\ny"'#10'- plain text', Out);
end;

procedure TTestYamlEmitter.DovrebbeScrivereIlTestoSuPiuRigheComeLetterale;
begin
  FEmitter.Manip(ymLiteral);
  FEmitter.WriteString('one'#10'two');
  Assert.AreEqual('|'#10'  one'#10'  two', Out);
end;

procedure TTestYamlEmitter.DovrebbeScrivereGliInteriInBaseDiversa;
begin
  FEmitter.SetIntBase(ymHex);
  FEmitter.Manip(ymBeginSeq);
  FEmitter.WriteInteger(255);
  FEmitter.WriteInteger(-1);
  FEmitter.WriteSmallInt(-1);
  FEmitter.WriteInt64(-1);
  FEmitter.Manip(ymEndSeq);
  Assert.AreEqual('- 0xff'#10'- 0xffffffff'#10'- 0xffff'#10'- 0xffffffffffffffff', Out);
  FEmitter := TYamlFactory.CreateEmitter;
  FEmitter.Manip(ymOct);
  FEmitter.WriteInteger(8);
  Assert.AreEqual('010', Out);
end;

procedure TTestYamlEmitter.DovrebbeScrivereIDecimaliConLaPrecisioneChiesta;
begin
  FEmitter.Manip(ymBeginSeq);
  FEmitter.WriteDouble(0.1);
  FEmitter.WriteSingle(0.1);
  FEmitter.WriteDouble(Infinity);
  FEmitter.Manip(ymEndSeq);
  Assert.AreEqual('- 0.10000000000000001'#10'- 0.100000001'#10'- .inf', Out);
  FEmitter := TYamlFactory.CreateEmitter;
  FEmitter.SetDoublePrecision(3);
  FEmitter.WriteDouble(3.14159);
  Assert.AreEqual('3.14', Out);
  Assert.IsFalse(FEmitter.SetDoublePrecision(18), 'oltre le 17 cifre non si puo''');
end;

procedure TTestYamlEmitter.DovrebbeScrivereAncoreAliasETag;
begin
  FEmitter.Manip(ymBeginSeq);
  FEmitter.WriteAnchor('x');
  FEmitter.WriteString('one');
  FEmitter.WriteAlias('x');
  FEmitter.WriteTag(etVerbatim, '', 'tag:yaml.org,2002:str');
  FEmitter.WriteString('two');
  FEmitter.WriteTag(etNamedHandle, '', 'binary');
  FEmitter.WriteString('three');
  FEmitter.Manip(ymEndSeq);
  Assert.IsTrue(FEmitter.Good);
  Assert.AreEqual('- &x one'#10'- *x'#10'- !<tag:yaml.org,2002:str> two'#10'- !!binary three', Out);
end;

procedure TTestYamlEmitter.DovrebbeScrivereICommentiEIDocumenti;
begin
  FEmitter.Manip(ymBeginDoc);
  FEmitter.WriteComment('top');
  FEmitter.Manip(ymBeginMap);
  FEmitter.Manip(ymKey);
  FEmitter.WriteString('a');
  FEmitter.Manip(ymValue);
  FEmitter.WriteInteger(1);
  FEmitter.WriteComment('after');
  FEmitter.Manip(ymEndMap);
  FEmitter.Manip(ymEndDoc);
  Assert.IsTrue(FEmitter.Good);
  Assert.AreEqual('---'#10'# top'#10'a: 1  # after'#10'...'#10, Out);
end;

procedure TTestYamlEmitter.DovrebbeScrivereIlBinarioInBase64;
var
  LData: TBytes;
begin
  SetLength(LData, 3);
  LData[0] := 1;
  LData[1] := 2;
  LData[2] := 3;
  FEmitter.WriteBinary(LData);
  Assert.AreEqual('!!binary "AQID"', Out);
end;

procedure TTestYamlEmitter.DovrebbeEscapareIlNonAsciiSeLoSiChiede;
begin
  FEmitter.SetOutputCharset(ymEscapeNonAscii);
  FEmitter.WriteString(YamlBytes([$C3, $A9, $E6, $97, $A5, $F0, $9F, $98, $80]));
  // (the escapes are built from a backslash: a u escape in the source text is easy to lose)
  Assert.AreEqual('"' + Backslash + 'xe9' + Backslash + 'u65e5' + Backslash + 'U0001f600"', Out);
  FEmitter := TYamlFactory.CreateEmitter;
  FEmitter.SetOutputCharset(ymEscapeAsJson);
  // the JSON style only changes how the escapes are written: a control character is \u0001, not \x01
  FEmitter.WriteString(YamlBytes([1]));
  Assert.AreEqual('"' + Backslash + 'u0001"', Out);
end;

procedure TTestYamlEmitter.DovrebbeRestareInErroreDopoUnaChiusuraSenzaApertura;
begin
  FEmitter.Manip(ymEndSeq);
  Assert.IsFalse(FEmitter.Good);
  Assert.AreEqual('unexpected end sequence token', YamlTextToString(FEmitter.LastError));
  FEmitter.WriteString('x');
  Assert.AreEqual('', Out, 'dopo un errore non si scrive piu''');
end;

procedure TTestYamlEmitter.DovrebbeSegnalareUnAncoraNonValida;
begin
  FEmitter.WriteAnchor('bad anchor');
  Assert.IsFalse(FEmitter.Good);
  Assert.AreEqual('invalid anchor', YamlTextToString(FEmitter.LastError));
end;

procedure TTestYamlEmitter.DovrebbeScrivereUnNodoCaricatoComeLOriginale;
var
  LNode: IYamlNode;
begin
  LNode := TYamlFactory.CreateParser.Load('a: [1, 2]'#10'b:'#10'  c: d'#10);
  FEmitter.WriteNode(LNode);
  Assert.AreEqual('a: [1, 2]'#10'b:'#10'  c: d', Out);
  Assert.AreEqual(Out, YamlTextToString(TYamlFactory.Dump(LNode)));
end;

procedure TTestYamlEmitter.DovrebbeDareLeStesseImpostazioniGlobaliDiYamlCpp;
begin
  Assert.IsFalse(FEmitter.SetIndent(1));
  Assert.IsTrue(FEmitter.SetIndent(4));
  Assert.IsFalse(FEmitter.SetPreCommentIndent(0));
  Assert.IsTrue(FEmitter.SetBoolFormat(ymYesNoBool));
  Assert.IsFalse(FEmitter.SetBoolFormat(ymFlow));
  Assert.IsTrue(FEmitter.SetMapFormat(ymLongKey));
  Assert.IsFalse(FEmitter.SetSeqFormat(ymLongKey));
  Assert.IsFalse(FEmitter.SetNullFormat(ymHex));
  FEmitter.Manip(ymBeginSeq);
  FEmitter.WriteBool(True);
  FEmitter.WriteNull;
  FEmitter.Manip(ymBeginSeq);
  FEmitter.WriteInteger(1);
  FEmitter.Manip(ymEndSeq);
  FEmitter.Manip(ymEndSeq);
  Assert.AreEqual('-   yes'#10'-   ~'#10'-'#10'    -   1', Out);
end;

end.
