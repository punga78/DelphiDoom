{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the parity library - the comparison of two logs        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Parity.LogComparer;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Parity.LogComparer,
  DelphiDoom.Parity.Types;

type
  [TestFixture]
  [Category('parity')]
  TTestParityLogComparer = class(TObject)
  public
    [Test]
    procedure DueLogUgualiDovrebberoDareUguale;
    [Test]
    procedure DueLogVuotiDovrebberoDareUguale;
    [Test]
    procedure DovrebbeIgnorareLeRigheDiCommento;
    [Test]
    procedure DovrebbeDareLaPrimaRigaDiversa;
    [Test]
    procedure DovrebbeDireIlTicDellaRigaDiversa;
    [Test]
    procedure PerLeRigheDelloStatoDovrebbeDireQualiImpronteCambiano;
    [Test]
    procedure PerLeRigheDelloStatoDovrebbeDireIlTotaleSeCambiaSoloQuello;
    [Test]
    procedure PerLeRigheDelFotogrammaDovrebbeDireQualeImprontaCambia;
    [Test]
    procedure PerLeRigheDiDettaglioDovrebbeDireCategoriaIndiceECampo;
    [Test]
    procedure UnLogPiuCortoDovrebbeEssereUnaDifferenza;
    [Test]
    procedure UnLogPiuLungoDovrebbeEssereUnaDifferenza;
    [Test]
    procedure IlNumeroDiRigaDovrebbeContareICommenti;
    [Test]
    procedure DescribeDovrebbeDireUgualeSenzaDifferenze;
    [Test]
    procedure DescribeDovrebbeDireDoveSiDifferenzia;
  end;

implementation

function Lines(const ALines: array of string): TArray<string>;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(ALines));
  for LIndex := 0 to High(ALines) do
    Result[LIndex] := ALines[LIndex];
end;

procedure TTestParityLogComparer.DueLogUgualiDovrebberoDareUguale;
begin
  Assert.IsFalse(TParityLogComparer.Compare(Lines(['T 1 aa mobj=1', 'T 2 bb mobj=2']),
    Lines(['T 1 aa mobj=1', 'T 2 bb mobj=2'])).Found);
end;

procedure TTestParityLogComparer.DueLogVuotiDovrebberoDareUguale;
begin
  Assert.IsFalse(TParityLogComparer.Compare(nil, nil).Found);
end;

procedure TTestParityLogComparer.DovrebbeIgnorareLeRigheDiCommento;
begin
  Assert.IsFalse(TParityLogComparer.Compare(Lines(['# header A', 'T 1 aa x=1']),
    Lines(['T 1 aa x=1', '# the end'])).Found);
end;

procedure TTestParityLogComparer.DovrebbeDareLaPrimaRigaDiversa;
var
  LDifference: TParityDifference;
begin
  LDifference := TParityLogComparer.Compare(Lines(['T 1 aa x=1', 'T 2 bb x=2', 'T 3 cc x=3']),
    Lines(['T 1 aa x=1', 'T 2 bb x=9', 'T 3 zz x=4']));
  Assert.IsTrue(LDifference.Found);
  Assert.AreEqual(2, LDifference.LineNumber);
  Assert.AreEqual('T 2 bb x=2', LDifference.Expected);
  Assert.AreEqual('T 2 bb x=9', LDifference.Actual);
end;

procedure TTestParityLogComparer.DovrebbeDireIlTicDellaRigaDiversa;
begin
  Assert.AreEqual(2, TParityLogComparer.Compare(Lines(['T 1 aa x=1', 'T 2 bb x=2']),
    Lines(['T 1 aa x=1', 'T 2 bb x=9'])).Tic);
end;

procedure TTestParityLogComparer.PerLeRigheDelloStatoDovrebbeDireQualiImpronteCambiano;
var
  LDifference: TParityDifference;
begin
  LDifference := TParityLogComparer.Compare(Lines(['T 5 aa mobj=11 sector=22 lt=5 rnd=9']),
    Lines(['T 5 bb mobj=11 sector=99 lt=5 rnd=10']));
  Assert.AreEqual('total,sector,rnd', LDifference.Differing);
end;

procedure TTestParityLogComparer.PerLeRigheDelloStatoDovrebbeDireIlTotaleSeCambiaSoloQuello;
var
  LDifference: TParityDifference;
begin
  LDifference := TParityLogComparer.Compare(Lines(['T 5 aa mobj=11 lt=5']),
    Lines(['T 5 bb mobj=11 lt=5']));
  Assert.AreEqual('total', LDifference.Differing);
end;

procedure TTestParityLogComparer.PerLeRigheDelFotogrammaDovrebbeDireQualeImprontaCambia;
var
  LDifference: TParityDifference;
begin
  LDifference := TParityLogComparer.Compare(Lines(['F 9 f1 v1 h1']), Lines(['F 9 f2 v2 h1']));
  Assert.AreEqual('full,view', LDifference.Differing);
  LDifference := TParityLogComparer.Compare(Lines(['F 9 f1 v1 h1']), Lines(['F 9 f2 v1 h2']));
  Assert.AreEqual('full,hud', LDifference.Differing);
end;

procedure TTestParityLogComparer.PerLeRigheDiDettaglioDovrebbeDireCategoriaIndiceECampo;
var
  LDifference: TParityDifference;
begin
  LDifference := TParityLogComparer.Compare(Lines(['D 5 mobj 12 momz -8']),
    Lines(['D 5 mobj 12 momz -9']));
  Assert.AreEqual('mobj 12 momz', LDifference.Differing);
  Assert.AreEqual(5, LDifference.Tic);
end;

procedure TTestParityLogComparer.UnLogPiuCortoDovrebbeEssereUnaDifferenza;
var
  LDifference: TParityDifference;
begin
  LDifference := TParityLogComparer.Compare(Lines(['T 1 aa x=1', 'T 2 bb x=2']), Lines(['T 1 aa x=1']));
  Assert.IsTrue(LDifference.Found);
  Assert.AreEqual(2, LDifference.Tic);
  Assert.AreEqual('(end of the log)', LDifference.Actual);
end;

procedure TTestParityLogComparer.UnLogPiuLungoDovrebbeEssereUnaDifferenza;
var
  LDifference: TParityDifference;
begin
  LDifference := TParityLogComparer.Compare(Lines(['T 1 aa x=1']), Lines(['T 1 aa x=1', 'T 2 bb x=2']));
  Assert.IsTrue(LDifference.Found);
  Assert.AreEqual(2, LDifference.Tic);
  Assert.AreEqual('(end of the log)', LDifference.Expected);
end;

procedure TTestParityLogComparer.IlNumeroDiRigaDovrebbeContareICommenti;
var
  LDifference: TParityDifference;
begin
  LDifference := TParityLogComparer.Compare(Lines(['# a', '# b', 'T 1 aa x=1']), Lines(['# a', '# b', 'T 1 aa x=2']));
  Assert.AreEqual(3, LDifference.LineNumber);
end;

procedure TTestParityLogComparer.DescribeDovrebbeDireUgualeSenzaDifferenze;
begin
  Assert.AreEqual('EQUAL', TParityLogComparer.Compare(nil, nil).Describe);
end;

procedure TTestParityLogComparer.DescribeDovrebbeDireDoveSiDifferenzia;
var
  LText: string;
begin
  LText := TParityLogComparer.Compare(Lines(['T 4 aa x=1']), Lines(['T 4 aa x=2'])).Describe;
  Assert.IsTrue(LText.StartsWith('DIFFERENT at line 1 (tic 4)'), LText);
  Assert.IsTrue(LText.Contains('x'), LText);
end;

end.
