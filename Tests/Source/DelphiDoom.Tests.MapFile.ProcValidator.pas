{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the map file library - the references of a .proc file  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MapFile.ProcValidator;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.MapFile.Proc.ProcFile;

type
  [TestFixture]
  [Category('MapFile')]
  TTestProcFileValidator = class
  strict private
    function Problems(const AText: AnsiString): TArray<string>;
  public
    [Test]
    procedure DovrebbeNonTrovareProblemiInUnFileCoerente;
    [Test]
    procedure DovrebbeSegnalareUnIndiceOltreIVertici;
    [Test]
    procedure DovrebbeSegnalareUnIndiceNegativo;
    [Test]
    procedure DovrebbeSegnalareIndiciCheNonSonoTriangoli;
    [Test]
    procedure DovrebbeSegnalareUnIndiceOltreIVerticiDellOmbra;
    [Test]
    procedure DovrebbeSegnalareIConteggiDellOmbraOltreGliIndici;
    [Test]
    procedure DovrebbeSegnalareUnPortaleConDuePunti;
    [Test]
    procedure DovrebbeSegnalareUnFiglioDiUnNodoCheNonEsiste;
    [Test]
    procedure DovrebbeSegnalareUnFiglioArea;
    [Test]
    procedure DovrebbeAccettareLeAreeSenzaLaSezioneDeiPortali;
    [Test]
    procedure DovrebbeSegnalareTuttiIProblemi;
  end;

implementation

uses
  DelphiDoom.MapFile.Proc.Validator, DelphiDoom.MapFile.Proc.Factory, DelphiDoom.Tests.IdLib.Fakes,
  DelphiDoom.Tests.MapFile.ProcSample;

const
  HEAD = 'mapProcFile003'#10;
  SURFACE_HEAD = 'model { "m" 1 { "mat" 3 %d ';
  TRIANGLE = '( 0 0 0 0 0 0 0 1 ) ( 1 0 0 0 0 0 0 1 ) ( 0 1 0 0 0 0 0 1 ) ';

{ TTestProcFileValidator }

function TTestProcFileValidator.Problems(const AText: AnsiString): TArray<string>;
var
  LFile: TProcFile;
begin
  LFile := TProcFileFactory.CreateReader(TIdLibMemoryFileSystem.Create).ParseText(AText, 'x');
  try
    Result := TProcFileValidator.Check(LFile);
  finally
    LFile.Free;
  end;
end;

procedure TTestProcFileValidator.DovrebbeNonTrovareProblemiInUnFileCoerente;
begin
  Assert.AreEqual(0, Integer(Length(Problems(TProcSample.Full))));
end;

procedure TTestProcFileValidator.DovrebbeSegnalareUnIndiceOltreIVertici;
var
  LList: TArray<string>;
begin
  LList := Problems(HEAD + AnsiString(Format(SURFACE_HEAD, [3])) + TRIANGLE + '0 1 3 } }'#10);
  Assert.AreEqual(1, Integer(Length(LList)));
  Assert.AreEqual('model "m", surface 0: index 3 is not in 0..2', LList[0]);
end;

procedure TTestProcFileValidator.DovrebbeSegnalareUnIndiceNegativo;
begin
  Assert.AreEqual(1, Integer(Length(Problems(HEAD + AnsiString(Format(SURFACE_HEAD, [3])) + TRIANGLE + '0 1 -1 } }'#10))));
end;

procedure TTestProcFileValidator.DovrebbeSegnalareIndiciCheNonSonoTriangoli;
var
  LList: TArray<string>;
begin
  LList := Problems(HEAD + AnsiString(Format(SURFACE_HEAD, [4])) + TRIANGLE + '0 1 2 0 } }'#10);
  Assert.AreEqual(1, Integer(Length(LList)));
  Assert.IsTrue(Pos('4 indexes are not a whole number of triangles', LList[0]) > 0);
end;

procedure TTestProcFileValidator.DovrebbeSegnalareUnIndiceOltreIVerticiDellOmbra;
var
  LList: TArray<string>;
begin
  LList := Problems(HEAD + 'shadowModel { "s" 3 3 3 3 0 ( 0 0 0 ) ( 1 0 0 ) ( 0 1 0 ) 0 1 7 }'#10);
  Assert.AreEqual(1, Integer(Length(LList)));
  Assert.AreEqual('shadowModel "s": index 7 is not in 0..2', LList[0]);
end;

procedure TTestProcFileValidator.DovrebbeSegnalareIConteggiDellOmbraOltreGliIndici;
var
  LList: TArray<string>;
begin
  LList := Problems(HEAD + 'shadowModel { "s" 3 9 -1 3 0 ( 0 0 0 ) ( 1 0 0 ) ( 0 1 0 ) 0 1 2 }'#10);
  Assert.AreEqual(2, Integer(Length(LList)));
  Assert.IsTrue(Pos('noCaps is 9', LList[0]) > 0);
  Assert.IsTrue(Pos('noFrontCaps is -1', LList[1]) > 0);
end;

procedure TTestProcFileValidator.DovrebbeSegnalareUnPortaleConDuePunti;
var
  LList: TArray<string>;
begin
  LList := Problems(HEAD + 'interAreaPortals { 2 1 2 0 1 ( 0 0 0 ) ( 0 1 0 ) }'#10);
  Assert.AreEqual(1, Integer(Length(LList)));
  Assert.AreEqual('portal 0 has 2 points, at least 3 are needed', LList[0]);
end;

procedure TTestProcFileValidator.DovrebbeSegnalareUnFiglioDiUnNodoCheNonEsiste;
var
  LList: TArray<string>;
begin
  LList := Problems(HEAD + 'nodes { 1 ( 1 0 0 0 ) 5 0 }'#10);
  Assert.AreEqual(1, Integer(Length(LList)));
  Assert.IsTrue(Pos('node 0: child 5', LList[0]) > 0);
end;

procedure TTestProcFileValidator.DovrebbeSegnalareUnFiglioArea;
var
  LList: TArray<string>;
begin
  // two areas: -1 and -2 are areas 0 and 1, -3 is area 2 which does not exist
  LList := Problems(HEAD + 'interAreaPortals { 2 0 }'#10 + 'nodes { 1 ( 1 0 0 0 ) -2 -3 }'#10);
  Assert.AreEqual(1, Integer(Length(LList)));
  Assert.IsTrue(Pos('child -3', LList[0]) > 0);
end;

procedure TTestProcFileValidator.DovrebbeAccettareLeAreeSenzaLaSezioneDeiPortali;
begin
  // without the portals nothing is known about the number of areas
  Assert.AreEqual(0, Integer(Length(Problems(HEAD + 'nodes { 1 ( 1 0 0 0 ) -9 0 }'#10))));
end;

procedure TTestProcFileValidator.DovrebbeSegnalareTuttiIProblemi;
begin
  Assert.AreEqual(2, Integer(Length(Problems(HEAD + AnsiString(Format(SURFACE_HEAD, [4])) + TRIANGLE + '0 1 2 9 } }'#10))));
end;

end.
