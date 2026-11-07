{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the ide library - TIdeCsv                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Ide.Csv;

interface

uses
  DUnitX.TestFramework,
  DelphiDoom.Ide.Csv;

type
  [TestFixture]
  [Category('ide')]
  TTestIdeCsv = class(TObject)
  public
    [Test]
    procedure DovrebbeTagliareLeCellePerPuntoEVirgola;
    [Test]
    procedure DovrebbeTogliereLeVirgolette;
    [Test]
    procedure DovrebbeLasciareLeVirgoletteSeNonSonoAEntrambeLeEstremita;
    [Test]
    procedure DovrebbeTenereUnaCellaVuotaInMezzoMaNonInFondo;
    [Test]
    procedure DovrebbeDareLaColonnaPerNomeSenzaMaiuscole;
    [Test]
    procedure DovrebbeDareCellaVuotaPerUnaRigaCorta;
    [Test]
    procedure DovrebbeDareListaVuotaPerUnaColonnaCheNonCe;
    [Test]
    procedure DovrebbeDareListaVuotaSenzaRighe;
    [Test]
    procedure DovrebbeScrivereIMultipliDiFracUnit;
    [Test]
    procedure DovrebbeLasciareInvariatoCioCheNonEUnMultiplo;
  end;

implementation

{ TTestIdeCsv }

procedure TTestIdeCsv.DovrebbeTagliareLeCellePerPuntoEVirgola;
var
  LCells: TArray<string>;
begin
  LCells := TIdeCsv.ParseLine('a;b;c');
  Assert.AreEqual(3, Length(LCells));
  Assert.AreEqual('b', LCells[1]);
end;

procedure TTestIdeCsv.DovrebbeTogliereLeVirgolette;
begin
  Assert.AreEqual('S_NULL', TIdeCsv.ParseLine('"S_NULL";"0"')[0]);
end;

procedure TTestIdeCsv.DovrebbeLasciareLeVirgoletteSeNonSonoAEntrambeLeEstremita;
begin
  Assert.AreEqual('"half', TIdeCsv.ParseLine('"half;x')[0]);
  Assert.AreEqual('"', TIdeCsv.ParseLine('";x')[0]);
end;

procedure TTestIdeCsv.DovrebbeTenereUnaCellaVuotaInMezzoMaNonInFondo;
begin
  Assert.AreEqual(3, Length(TIdeCsv.ParseLine('a;;c')));
  // the old reader dropped the last cell when it was empty
  Assert.AreEqual(2, Length(TIdeCsv.ParseLine('a;b;')));
  Assert.AreEqual(2, Length(TIdeCsv.ParseLine('a;b;""')));
end;

procedure TTestIdeCsv.DovrebbeDareLaColonnaPerNomeSenzaMaiuscole;
var
  LColumn: TArray<string>;
begin
  LColumn := TIdeCsv.Column(TArray<string>.Create('"Name";"Id"', '"A";"1"', '"B";"2"'), 'id');
  Assert.AreEqual(2, Length(LColumn));
  Assert.AreEqual('1', LColumn[0]);
  Assert.AreEqual('2', LColumn[1]);
end;

procedure TTestIdeCsv.DovrebbeDareCellaVuotaPerUnaRigaCorta;
var
  LColumn: TArray<string>;
begin
  LColumn := TIdeCsv.Column(TArray<string>.Create('Name;Id', 'A'), 'Id');
  Assert.AreEqual(1, Length(LColumn));
  Assert.AreEqual('', LColumn[0]);
end;

procedure TTestIdeCsv.DovrebbeDareListaVuotaPerUnaColonnaCheNonCe;
begin
  Assert.AreEqual(0, Length(TIdeCsv.Column(TArray<string>.Create('Name;Id', 'A;1'), 'Other')));
end;

procedure TTestIdeCsv.DovrebbeDareListaVuotaSenzaRighe;
begin
  Assert.AreEqual(0, Length(TIdeCsv.Column(nil, 'Id')));
end;

procedure TTestIdeCsv.DovrebbeScrivereIMultipliDiFracUnit;
begin
  Assert.AreEqual('FRACUNIT', TIdeCsv.ExpandFracUnit('65536'));
  Assert.AreEqual('2 * FRACUNIT', TIdeCsv.ExpandFracUnit('131072'));
  Assert.AreEqual('20 * FRACUNIT', TIdeCsv.ExpandFracUnit('1310720'));
end;

procedure TTestIdeCsv.DovrebbeLasciareInvariatoCioCheNonEUnMultiplo;
begin
  Assert.AreEqual('65537', TIdeCsv.ExpandFracUnit('65537'));
  Assert.AreEqual('0', TIdeCsv.ExpandFracUnit('0'));
  Assert.AreEqual('-65536', TIdeCsv.ExpandFracUnit('-65536'));
  Assert.AreEqual('+131072', TIdeCsv.ExpandFracUnit('+131072'));
  Assert.AreEqual('text', TIdeCsv.ExpandFracUnit('text'));
  Assert.AreEqual('', TIdeCsv.ExpandFracUnit(''));
end;

end.
