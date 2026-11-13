{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the ide library - TIdeRowSorter and TIdeOutline        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Ide.RowSorter;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('ide')]
  TTestIdeRowSorter = class(TObject)
  public
    [Test]
    procedure DovrebbeOrdinarePerDidascaliaSenzaMaiuscole;
    [Test]
    procedure DovrebbeOrdinarePerColonnaDeiValori;
    [Test]
    procedure DovrebbeConfrontareComeNumeriSoloSeVuoleIlConfrontoNumerico;
    [Test]
    procedure DovrebbeLeggereEsadecimaliEDecimali;
    [Test]
    procedure DovrebbeTenereLOrdineDelleRigheUguali;
    [Test]
    procedure DovrebbeLasciareIlTagDelleRighe;
    [Test]
    procedure DovrebbeOrdinareIRamiPrincipaliComeUnAlberoDiWindows;
    [Test]
    procedure DovrebbeLasciareInAlberoOgniFiglioAlSuoPadre;
    [Test]
    procedure DovrebbeScrivereLeRigheConDueSpaziPerLivello;
  end;

implementation

uses
  DelphiDoom.Ide.Types,
  DelphiDoom.Ide.RowSorter,
  DelphiDoom.Ide.Outline;

function MakeRow(const ACaption, AValue: string; const ATag: Integer): TIdeRow;
begin
  Result.Caption := ACaption;
  Result.Values := TArray<string>.Create(AValue);
  Result.Tag := ATag;
end;

{ TTestIdeRowSorter }

procedure TTestIdeRowSorter.DovrebbeOrdinarePerDidascaliaSenzaMaiuscole;
var
  LRows: TArray<TIdeRow>;
begin
  LRows := TArray<TIdeRow>.Create(MakeRow('b', '1', 0), MakeRow('A', '2', 1), MakeRow('c', '3', 2));
  TIdeRowSorter.Sort(LRows, 0, ccText);
  Assert.AreEqual('A', LRows[0].Caption);
  Assert.AreEqual('b', LRows[1].Caption);
  Assert.AreEqual('c', LRows[2].Caption);
end;

procedure TTestIdeRowSorter.DovrebbeOrdinarePerColonnaDeiValori;
var
  LRows: TArray<TIdeRow>;
begin
  LRows := TArray<TIdeRow>.Create(MakeRow('a', 'z', 0), MakeRow('b', 'x', 1), MakeRow('c', 'y', 2));
  TIdeRowSorter.Sort(LRows, 1, ccText);
  Assert.AreEqual('b', LRows[0].Caption);
  Assert.AreEqual('c', LRows[1].Caption);
  Assert.AreEqual('a', LRows[2].Caption);
end;

procedure TTestIdeRowSorter.DovrebbeConfrontareComeNumeriSoloSeVuoleIlConfrontoNumerico;
var
  LRows: TArray<TIdeRow>;
begin
  LRows := TArray<TIdeRow>.Create(MakeRow('a', '10', 0), MakeRow('b', '9', 1));
  TIdeRowSorter.Sort(LRows, 1, ccNumbers);
  Assert.AreEqual('b', LRows[0].Caption);
  TIdeRowSorter.Sort(LRows, 1, ccText);
  Assert.AreEqual('a', LRows[0].Caption);
end;

procedure TTestIdeRowSorter.DovrebbeLeggereEsadecimaliEDecimali;
var
  LRows: TArray<TIdeRow>;
begin
  // "$20" is not a number for the old Val on a floating point variable: it is text, and a text
  // goes before the numbers
  LRows := TArray<TIdeRow>.Create(MakeRow('a', '31', 0), MakeRow('b', '$20', 1), MakeRow('c', '1.5', 2));
  TIdeRowSorter.Sort(LRows, 1, ccNumbers);
  Assert.AreEqual('b', LRows[0].Caption);
  Assert.AreEqual('c', LRows[1].Caption);
  Assert.AreEqual('a', LRows[2].Caption);
end;

procedure TTestIdeRowSorter.DovrebbeTenereLOrdineDelleRigheUguali;
var
  LRows: TArray<TIdeRow>;
  LIndex: Integer;
begin
  SetLength(LRows, 50);
  for LIndex := 0 to 49 do
    LRows[LIndex] := MakeRow('x' + Chr(Ord('a') + LIndex mod 26), '1', LIndex);
  TIdeRowSorter.Sort(LRows, 1, ccNumbers);
  for LIndex := 0 to 49 do
    Assert.AreEqual(LIndex, LRows[LIndex].Tag);
end;

procedure TTestIdeRowSorter.DovrebbeLasciareIlTagDelleRighe;
var
  LRows: TArray<TIdeRow>;
begin
  LRows := TArray<TIdeRow>.Create(MakeRow('b', '1', 7), MakeRow('a', '2', 3));
  TIdeRowSorter.Sort(LRows, 0, ccText);
  Assert.AreEqual(3, LRows[0].Tag);
  Assert.AreEqual(7, LRows[1].Tag);
end;

procedure TTestIdeRowSorter.DovrebbeOrdinareIRamiPrincipaliComeUnAlberoDiWindows;
var
  LOutline: TIdeOutline;
begin
  LOutline := TIdeOutline.Create;
  try
    LOutline.AddRoot('banana');
    LOutline.AddRoot('Apple');
    LOutline.AddRoot('cherry');
    LOutline.SortRoots;
    Assert.AreEqual('Apple', LOutline.Roots[0].Text);
    Assert.AreEqual('banana', LOutline.Roots[1].Text);
    Assert.AreEqual('cherry', LOutline.Roots[2].Text);
  finally
    LOutline.Free;
  end;
end;

procedure TTestIdeRowSorter.DovrebbeLasciareInAlberoOgniFiglioAlSuoPadre;
var
  LOutline: TIdeOutline;
begin
  LOutline := TIdeOutline.Create;
  try
    LOutline.AddRoot('b').AddChild('z');
    LOutline.AddRoot('a').AddChild('y');
    LOutline.Roots[0].AddChild('x');
    LOutline.SortRoots;
    Assert.AreEqual('a', LOutline.Roots[0].Text);
    Assert.AreEqual(1, LOutline.Roots[0].Children.Count);
    Assert.AreEqual(2, LOutline.Roots[1].Children.Count);
    Assert.AreEqual('z', LOutline.Roots[1].Children[0].Text);
  finally
    LOutline.Free;
  end;
end;

procedure TTestIdeRowSorter.DovrebbeScrivereLeRigheConDueSpaziPerLivello;
var
  LOutline: TIdeOutline;
  LLines: TArray<string>;
begin
  LOutline := TIdeOutline.Create;
  try
    LOutline.AddRoot('root').AddChild('child').AddChild('leaf');
    LLines := LOutline.ToLines;
    Assert.AreEqual<Integer>(3, Length(LLines));
    Assert.AreEqual('root', LLines[0]);
    Assert.AreEqual('  child', LLines[1]);
    Assert.AreEqual('    leaf', LLines[2]);
  finally
    LOutline.Free;
  end;
end;

end.
