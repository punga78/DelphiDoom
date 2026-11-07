{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the ide library - TIdeParameterHints                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Ide.ParameterHints;

interface

uses
  DUnitX.TestFramework,
  DelphiDoom.Ide.ParameterHints;

type
  [TestFixture]
  [Category('ide')]
  TTestIdeParameterHints = class(TObject)
  strict private
    FHints: TIdeParameterHints;
    function IsIdent(const AChar: Char): Boolean;
    function Find(const ALine: string; const ACaret: Integer; out AName: string;
      out AIndex: Integer; out AParameters: string): Boolean;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareIParametriTraVirgolette;
    [Test]
    procedure DovrebbeDireNessunParametroPerUnaFunzioneSenzaParametri;
    [Test]
    procedure DovrebbeTrovareIlNomeSenzaMaiuscole;
    [Test]
    procedure DovrebbeConoscereLeFunzioniDegliActorConESenzaPrefisso;
    [Test]
    procedure DovrebbeRifareLaListaDaCapo;
    [Test]
    procedure DovrebbeTrovareLaChiamataEIlNumeroDelParametro;
    [Test]
    procedure DovrebbeSaltareLeParentesiGiaChiuse;
    [Test]
    procedure DovrebbeNonTrovareNullaPerUnNomeSconosciuto;
    [Test]
    procedure DovrebbeNonTrovareNullaFuoriDalleParentesi;
    [Test]
    procedure DovrebbeCercareOltreUnaParentesiSenzaNomeConosciuto;
    [Test]
    procedure DovrebbeNonTrovareNullaSeIlTestoEVuoto;
  end;

implementation

uses
  System.SysUtils,
  System.Character,
  DelphiDoom.Ide.Types;

{ TTestIdeParameterHints }

procedure TTestIdeParameterHints.Setup;
var
  LUnits: TArray<TIdeUnitDeclarations>;
begin
  FHints := TIdeParameterHints.Create;
  SetLength(LUnits, 1);
  LUnits[0].UnitName := 'PS_FIXED';
  LUnits[0].Declarations := TArray<string>.Create(
    'function FixedMul(const a, b: fixed_t): fixed_t;',
    'procedure Stop;',
    'procedure Say(const s: string; const n: Integer);');
  FHints.Rebuild(LUnits, TArray<string>.Create('A_Look()', 'A_Chase(speed: Integer)'));
end;

procedure TTestIdeParameterHints.TearDown;
begin
  FHints.Free;
end;

function TTestIdeParameterHints.IsIdent(const AChar: Char): Boolean;
begin
  Result := (AChar = '_') or AChar.IsLetterOrDigit;
end;

function TTestIdeParameterHints.Find(const ALine: string; const ACaret: Integer; out AName: string;
  out AIndex: Integer; out AParameters: string): Boolean;
begin
  Result := FHints.TryFindCall(ALine, ACaret,
    function(AChar: Char): Boolean
    begin
      Result := IsIdent(AChar);
    end, AName, AIndex, AParameters);
end;

procedure TTestIdeParameterHints.DovrebbeDareIParametriTraVirgolette;
var
  LParameters: string;
begin
  Assert.IsTrue(FHints.TryGetParameters('FixedMul', LParameters));
  Assert.AreEqual('"const a,"," b: fixed_t"', LParameters);
  Assert.IsTrue(FHints.TryGetParameters('say', LParameters));
  Assert.AreEqual('"const s: string,"," const n: Integer"', LParameters);
end;

procedure TTestIdeParameterHints.DovrebbeDireNessunParametroPerUnaFunzioneSenzaParametri;
var
  LParameters: string;
begin
  Assert.IsTrue(FHints.TryGetParameters('Stop', LParameters));
  Assert.AreEqual('** No parameters expected', LParameters);
  Assert.IsTrue(FHints.TryGetParameters('A_Look', LParameters));
  Assert.AreEqual('** No parameters expected', LParameters);
end;

procedure TTestIdeParameterHints.DovrebbeTrovareIlNomeSenzaMaiuscole;
var
  LParameters: string;
begin
  Assert.IsTrue(FHints.TryGetParameters('fixedmul', LParameters));
  Assert.IsFalse(FHints.TryGetParameters('Missing', LParameters));
  Assert.AreEqual('', LParameters);
end;

procedure TTestIdeParameterHints.DovrebbeConoscereLeFunzioniDegliActorConESenzaPrefisso;
var
  LParameters: string;
begin
  Assert.IsTrue(FHints.TryGetParameters('A_Chase', LParameters));
  Assert.AreEqual('"speed: Integer"', LParameters);
  Assert.IsTrue(FHints.TryGetParameters('Chase', LParameters));
  Assert.AreEqual('"speed: Integer"', LParameters);
end;

procedure TTestIdeParameterHints.DovrebbeRifareLaListaDaCapo;
var
  LParameters: string;
begin
  FHints.Rebuild(nil, nil);
  Assert.AreEqual(0, FHints.Count);
  Assert.IsFalse(FHints.TryGetParameters('FixedMul', LParameters));
end;

procedure TTestIdeParameterHints.DovrebbeTrovareLaChiamataEIlNumeroDelParametro;
var
  LName, LParameters: string;
  LIndex: Integer;
  LLine: string;
begin
  LLine := '  FixedMul(a, b';
  Assert.IsTrue(Find(LLine, Length(LLine) + 1, LName, LIndex, LParameters));
  Assert.AreEqual('FIXEDMUL', LName);
  Assert.AreEqual(1, LIndex);
  Assert.AreEqual('"const a,"," b: fixed_t"', LParameters);
  LLine := '  FixedMul(';
  Assert.IsTrue(Find(LLine, Length(LLine) + 1, LName, LIndex, LParameters));
  Assert.AreEqual(0, LIndex);
end;

procedure TTestIdeParameterHints.DovrebbeSaltareLeParentesiGiaChiuse;
var
  LName, LParameters: string;
  LIndex: Integer;
  LLine: string;
begin
  LLine := 'Say(FixedMul(1, 2), ';
  Assert.IsTrue(Find(LLine, Length(LLine) + 1, LName, LIndex, LParameters));
  Assert.AreEqual('SAY', LName);
  Assert.AreEqual(1, LIndex);
end;

procedure TTestIdeParameterHints.DovrebbeNonTrovareNullaPerUnNomeSconosciuto;
var
  LName, LParameters: string;
  LIndex: Integer;
  LLine: string;
begin
  LLine := 'Unknown(1, ';
  Assert.IsFalse(Find(LLine, Length(LLine) + 1, LName, LIndex, LParameters));
  Assert.AreEqual('', LParameters);
end;

procedure TTestIdeParameterHints.DovrebbeNonTrovareNullaFuoriDalleParentesi;
var
  LName, LParameters: string;
  LIndex: Integer;
  LLine: string;
begin
  LLine := 'FixedMul(1, 2) + 3';
  Assert.IsFalse(Find(LLine, Length(LLine) + 1, LName, LIndex, LParameters));
end;

procedure TTestIdeParameterHints.DovrebbeCercareOltreUnaParentesiSenzaNomeConosciuto;
var
  LName, LParameters: string;
  LIndex: Integer;
  LLine: string;
begin
  // the inner bracket belongs to a name that is not known: the search goes on to the outer one
  LLine := 'Say(Unknown(1), ';
  Assert.IsTrue(Find(LLine, Length(LLine) + 1, LName, LIndex, LParameters));
  Assert.AreEqual('SAY', LName);
end;

procedure TTestIdeParameterHints.DovrebbeNonTrovareNullaSeIlTestoEVuoto;
var
  LName, LParameters: string;
  LIndex: Integer;
begin
  Assert.IsFalse(Find('', 1, LName, LIndex, LParameters));
end;

end.
