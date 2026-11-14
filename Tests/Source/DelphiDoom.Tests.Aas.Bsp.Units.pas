{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the AAS library - the entities of the BSP and the       }
{  numbers of the C library                                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Aas.Bsp.Units;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.MathCore.Types, DelphiDoom.BotAi.Import.Intf,
  DelphiDoom.Aas.Bsp.Intf, DelphiDoom.Tests.Aas.Support;

type
  [TestFixture]
  [Category('Aas')]
  TTestAasCNumbers = class
  public
    [Test]
    procedure DovrebbeLeggereUnDecimaleComeAtof;
    [Test]
    procedure DovrebbeDareZeroSeIlTestoNonIniziaConUnNumero;
    [Test]
    procedure DovrebbeLeggereUnIntero;
    [Test]
    procedure DovrebbeTroncareUnInteroTroppoGrande;
    [Test]
    procedure DovrebbeLeggereUnVettoreConMenoDiTreNumeri;
  end;

  [TestFixture]
  [Category('Aas')]
  TTestAasBspEntities = class
  strict private
    FImport: TFakeImport;
    FImportIntf: IBotImport;
    function Parse(const AText: AnsiString): IAasBspEntities;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeLeggereLeEntitaESaltareLaZero;
    [Test]
    procedure DovrebbeDareIlValoreDellaChiave;
    [Test]
    procedure DovrebbeDareIlSecondoValoreDiUnaChiaveRipetuta;
    [Test]
    procedure DovrebbeTagliareIlValoreAllaDimensione;
    [Test]
    procedure DovrebbeDareFalsoPerUnaChiaveChePuoNonEsserci;
    [Test]
    procedure DovrebbeRifiutareUnaEntitaFuoriIntervallo;
    [Test]
    procedure DovrebbeLeggereVettoriRealiEInteri;
    [Test]
    procedure DovrebbeSaltareICommenti;
    [Test]
    procedure DovrebbeSvuotareTuttoSeMancaLaParentesiChiusa;
    [Test]
    procedure DovrebbeSvuotareTuttoSeUnaChiaveNonEUnaStringa;
    [Test]
    procedure DovrebbeSvuotareTuttoSeIlValoreManca;
    [Test]
    procedure DovrebbeSvuotareTuttoSeIlTestoNonInizia;
    [Test]
    procedure DovrebbeFermarsiAlMassimoDelleEntita;
    [Test]
    procedure DovrebbeFinireUnaStringaSenzaChiusuraComeFineDelTesto;
  end;

implementation

uses
  DelphiDoom.BotAi.Types, DelphiDoom.Aas.Bsp.CNumbers, DelphiDoom.Aas.Bsp.Entities;

{ TTestAasCNumbers }

procedure TTestAasCNumbers.DovrebbeLeggereUnDecimaleComeAtof;
begin
  Assert.AreEqual(1.5, TAasCNumbers.AtoF('  1.5abc'), 0.0);
  Assert.AreEqual(-0.25, TAasCNumbers.AtoF('-.25'), 0.0);
  Assert.AreEqual(1000.0, TAasCNumbers.AtoF('1e3'), 0.0);
  Assert.AreEqual(2.0, TAasCNumbers.AtoF('2e'), 0.0);
  Assert.AreEqual(2.0, TAasCNumbers.AtoF('2e+'), 0.0);
  Assert.AreEqual(5.0, TAasCNumbers.AtoF('+5.'), 0.0);
end;

procedure TTestAasCNumbers.DovrebbeDareZeroSeIlTestoNonIniziaConUnNumero;
begin
  Assert.AreEqual(0.0, TAasCNumbers.AtoF('abc'), 0.0);
  Assert.AreEqual(0.0, TAasCNumbers.AtoF(''), 0.0);
  Assert.AreEqual(0.0, TAasCNumbers.AtoF('-'), 0.0);
  Assert.AreEqual(0, TAasCNumbers.AtoI('x7'));
end;

procedure TTestAasCNumbers.DovrebbeLeggereUnIntero;
begin
  Assert.AreEqual(42, TAasCNumbers.AtoI(' 42 '));
  Assert.AreEqual(-7, TAasCNumbers.AtoI('-7.9'));
  Assert.AreEqual(3, TAasCNumbers.AtoI('+3'));
end;

procedure TTestAasCNumbers.DovrebbeTroncareUnInteroTroppoGrande;
begin
  // 4294967297 does not fit: the original wraps
  Assert.AreEqual(1, TAasCNumbers.AtoI('4294967297'));
end;

procedure TTestAasCNumbers.DovrebbeLeggereUnVettoreConMenoDiTreNumeri;
var
  LVector: TVec3;
begin
  LVector := TAasCNumbers.ScanVector('1 2.5');
  Assert.AreEqual(Double(1), Double(LVector[0]), 0.0);
  Assert.AreEqual(Double(2.5), Double(LVector[1]), 0.0);
  Assert.AreEqual(Double(0), Double(LVector[2]), 0.0);
  LVector := TAasCNumbers.ScanVector('0 0 -64');
  Assert.AreEqual(Double(-64), Double(LVector[2]), 0.0);
end;

{ TTestAasBspEntities }

procedure TTestAasBspEntities.Setup;
begin
  FImport := TFakeImport.Create;
  FImportIntf := FImport;
end;

procedure TTestAasBspEntities.TearDown;
begin
  FImportIntf := nil;
end;

function TTestAasBspEntities.Parse(const AText: AnsiString): IAasBspEntities;
begin
  Result := TAasBspEntities.Create(FImportIntf, AText);
end;

procedure TTestAasBspEntities.DovrebbeLeggereLeEntitaESaltareLaZero;
var
  LEntities: IAasBspEntities;
begin
  LEntities := Parse('{ "classname" "worldspawn" } { "classname" "item_health" "origin" "1 2 3" }');
  Assert.AreEqual(3, LEntities.Count);
  Assert.AreEqual(1, LEntities.NextEntity(0));
  Assert.AreEqual(2, LEntities.NextEntity(1));
  Assert.AreEqual(0, LEntities.NextEntity(2));
  Assert.AreEqual(0, LEntities.NextEntity(-5));
end;

procedure TTestAasBspEntities.DovrebbeDareIlValoreDellaChiave;
var
  LValue: AnsiString;
begin
  Assert.IsTrue(Parse('{ "a" "b" "c" "d e" }').ValueForKey(1, 'c', LValue));
  Assert.AreEqual('d e', string(LValue));
end;

procedure TTestAasBspEntities.DovrebbeDareIlSecondoValoreDiUnaChiaveRipetuta;
var
  LValue: AnsiString;
begin
  Assert.IsTrue(Parse('{ "k" "first" "k" "second" }').ValueForKey(1, 'k', LValue));
  Assert.AreEqual('second', string(LValue));
end;

procedure TTestAasBspEntities.DovrebbeTagliareIlValoreAllaDimensione;
var
  LValue: AnsiString;
begin
  Assert.IsTrue(Parse('{ "k" "abcdef" }').ValueForKey(1, 'k', LValue, 4));
  Assert.AreEqual('abc', string(LValue));
end;

procedure TTestAasBspEntities.DovrebbeDareFalsoPerUnaChiaveChePuoNonEsserci;
var
  LValue: AnsiString;
begin
  Assert.IsFalse(Parse('{ "k" "v" }').ValueForKey(1, 'x', LValue));
  Assert.AreEqual('', string(LValue));
end;

procedure TTestAasBspEntities.DovrebbeRifiutareUnaEntitaFuoriIntervallo;
var
  LEntities: IAasBspEntities;
  LValue: AnsiString;
begin
  LEntities := Parse('{ "k" "v" }');
  Assert.IsFalse(LEntities.EntityInRange(0));
  Assert.IsFalse(LEntities.EntityInRange(2));
  Assert.IsFalse(LEntities.ValueForKey(2, 'k', LValue));
  Assert.IsTrue(LEntities.EntityInRange(1));
  Assert.AreEqual(3, FImport.Count);
end;

procedure TTestAasBspEntities.DovrebbeLeggereVettoriRealiEInteri;
var
  LEntities: IAasBspEntities;
  LVector: TVec3;
  LFloat: Single;
  LInteger: Integer;
begin
  LEntities := Parse('{ "origin" "10 -20.5 30" "wait" "2.5" "count" "7" }');
  Assert.IsTrue(LEntities.VectorForKey(1, 'origin', LVector));
  Assert.AreEqual(Double(-20.5), Double(LVector[1]), 0.0);
  Assert.IsTrue(LEntities.FloatForKey(1, 'wait', LFloat));
  Assert.AreEqual(Double(2.5), Double(LFloat), 0.0);
  Assert.IsTrue(LEntities.IntForKey(1, 'count', LInteger));
  Assert.AreEqual(7, LInteger);
  Assert.IsFalse(LEntities.VectorForKey(1, 'none', LVector));
  Assert.AreEqual(Double(0), Double(LVector[0]), 0.0);
  Assert.IsFalse(LEntities.FloatForKey(1, 'none', LFloat));
  Assert.IsFalse(LEntities.IntForKey(1, 'none', LInteger));
  Assert.AreEqual(0, LInteger);
end;

procedure TTestAasBspEntities.DovrebbeSaltareICommenti;
var
  LValue: AnsiString;
begin
  Assert.IsTrue(Parse('// one'#10'{ /* two */ "k" "v" // three'#10'}').ValueForKey(1, 'k', LValue));
  Assert.AreEqual('v', string(LValue));
end;

procedure TTestAasBspEntities.DovrebbeSvuotareTuttoSeMancaLaParentesiChiusa;
begin
  Assert.AreEqual(0, Parse('{ "k" "v" ').Count);
  Assert.AreEqual(PRT_ERROR, FImport.Level(0));
end;

procedure TTestAasBspEntities.DovrebbeSvuotareTuttoSeUnaChiaveNonEUnaStringa;
begin
  Assert.AreEqual(0, Parse('{ "a" "b" key "v" }').Count);
end;

procedure TTestAasBspEntities.DovrebbeSvuotareTuttoSeIlValoreManca;
begin
  Assert.AreEqual(0, Parse('{ "a" }').Count);
  Assert.AreEqual(0, Parse('{ "a" "b" "c" }').Count);
end;

procedure TTestAasBspEntities.DovrebbeSvuotareTuttoSeIlTestoNonInizia;
begin
  Assert.AreEqual(0, Parse('"k" "v"').Count);
  Assert.AreEqual(0, Parse('x').Count);
end;

procedure TTestAasBspEntities.DovrebbeFermarsiAlMassimoDelleEntita;
var
  LText: AnsiString;
  LIndex: Integer;
  LEntities: IAasBspEntities;
begin
  LText := '';
  for LIndex := 1 to 2100 do
    LText := LText + '{ "k" "v" }';
  LEntities := Parse(LText);
  Assert.AreEqual(AAS_MAX_BSP_ENTITIES, LEntities.Count);
  Assert.AreEqual(1, FImport.Count);
end;

procedure TTestAasBspEntities.DovrebbeFinireUnaStringaSenzaChiusuraComeFineDelTesto;
begin
  Assert.AreEqual(0, Parse('{ "k" "v').Count);
  Assert.AreEqual(0, Parse('{ "k" "a'#10'b" }').Count);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAasCNumbers);
  TDUnitX.RegisterTestFixture(TTestAasBspEntities);

end.
