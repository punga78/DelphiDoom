{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the ide library - TIdeProjectFormat                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Ide.ProjectFormat;

interface

uses
  DUnitX.TestFramework,
  DelphiDoom.Ide.Types,
  DelphiDoom.Ide.ProjectFormat;

type
  [TestFixture]
  [Category('ide')]
  TTestIdeProjectFormat = class(TObject)
  public
    [Test]
    procedure DovrebbeLeggereIlGiocoEGliElementiInOrdine;
    [Test]
    procedure DovrebbeDareNienteSeMancaLaVersione;
    [Test]
    procedure DovrebbeDareNienteSeLaVersioneEDiversa;
    [Test]
    procedure DovrebbeAccettareLaParolaVersionConQualsiasiMaiuscola;
    [Test]
    procedure DovrebbeDareNienteSeIlTestoEVuoto;
    [Test]
    procedure DovrebbeMettereIGiochiInMinuscolo;
    [Test]
    procedure DovrebbeTrattareUnaRigaVuotaComeElementoDiTipoNessuno;
    [Test]
    procedure DovrebbeAccettareFineRigaCrLfELf;
    [Test]
    procedure DovrebbeScrivereLeRigheConCrLfInFondo;
    [Test]
    procedure DovrebbeRileggereQuelloCheScrive;
  end;

implementation

{ TTestIdeProjectFormat }

procedure TTestIdeProjectFormat.DovrebbeLeggereIlGiocoEGliElementiInOrdine;
var
  LLines: TArray<TIdeProjectDirective>;
begin
  LLines := TIdeProjectFormat.Parse('version|1.0'#13#10'game|hexen'#13#10'script|a.ddscript'#13#10'actor|b.txt'#13#10);
  Assert.AreEqual<Integer>(3, Length(LLines));
  Assert.IsTrue(LLines[0].IsGame);
  Assert.AreEqual('hexen', LLines[0].Value);
  Assert.IsFalse(LLines[1].IsGame);
  Assert.AreEqual(Ord(ikScript), Ord(LLines[1].Kind));
  Assert.AreEqual('a.ddscript', LLines[1].Value);
  Assert.AreEqual(Ord(ikActor), Ord(LLines[2].Kind));
  Assert.AreEqual('b.txt', LLines[2].Value);
end;

procedure TTestIdeProjectFormat.DovrebbeDareNienteSeMancaLaVersione;
begin
  Assert.AreEqual<Integer>(0, Length(TIdeProjectFormat.Parse('game|doom'#13#10'script|a.ddscript'#13#10)));
end;

procedure TTestIdeProjectFormat.DovrebbeDareNienteSeLaVersioneEDiversa;
begin
  Assert.AreEqual<Integer>(0, Length(TIdeProjectFormat.Parse('version|0.9'#13#10'script|a.ddscript'#13#10)));
  Assert.AreEqual<Integer>(0, Length(TIdeProjectFormat.Parse('version|1.00'#13#10'script|a.ddscript'#13#10)));
end;

procedure TTestIdeProjectFormat.DovrebbeAccettareLaParolaVersionConQualsiasiMaiuscola;
begin
  Assert.AreEqual<Integer>(1, Length(TIdeProjectFormat.Parse('VERSION|1.0'#13#10'script|a.ddscript'#13#10)));
  Assert.AreEqual<Integer>(1, Length(TIdeProjectFormat.Parse(' Version | 1.0 '#13#10'script|a.ddscript'#13#10)));
end;

procedure TTestIdeProjectFormat.DovrebbeDareNienteSeIlTestoEVuoto;
begin
  Assert.AreEqual<Integer>(0, Length(TIdeProjectFormat.Parse('')));
end;

procedure TTestIdeProjectFormat.DovrebbeMettereIGiochiInMinuscolo;
var
  LLines: TArray<TIdeProjectDirective>;
begin
  LLines := TIdeProjectFormat.Parse('version|1.0'#13#10'GAME|Strife'#13#10);
  Assert.AreEqual('strife', LLines[0].Value);
end;

procedure TTestIdeProjectFormat.DovrebbeTrattareUnaRigaVuotaComeElementoDiTipoNessuno;
var
  LLines: TArray<TIdeProjectDirective>;
begin
  // a defect of the old reader, kept: a blank line is an item with no name
  LLines := TIdeProjectFormat.Parse('version|1.0'#13#10#13#10'script|a.ddscript'#13#10);
  Assert.AreEqual<Integer>(2, Length(LLines));
  Assert.AreEqual(Ord(ikNone), Ord(LLines[0].Kind));
  Assert.AreEqual('', LLines[0].Value);
end;

procedure TTestIdeProjectFormat.DovrebbeAccettareFineRigaCrLfELf;
begin
  Assert.AreEqual<Integer>(2, Length(TIdeProjectFormat.Parse('version|1.0'#10'game|doom'#10'script|a'#10)));
  Assert.AreEqual<Integer>(2, Length(TIdeProjectFormat.Parse('version|1.0'#13#10'game|doom'#13#10'script|a')));
end;

procedure TTestIdeProjectFormat.DovrebbeScrivereLeRigheConCrLfInFondo;
var
  LEntries: TArray<TIdeProjectEntry>;
begin
  SetLength(LEntries, 2);
  LEntries[0].Kind := ikScript;
  LEntries[0].RelativePath := 'a.ddscript';
  LEntries[1].Kind := ikCompiledScript;
  LEntries[1].RelativePath := 'sub\b.ddout';
  Assert.AreEqual('version|1.0'#13#10'game|heretic'#13#10'script|a.ddscript'#13#10'compiledscript|sub\b.ddout'#13#10,
    string(TIdeProjectFormat.Serialize('heretic', LEntries)));
  Assert.AreEqual('version|1.0'#13#10'game|doom'#13#10, string(TIdeProjectFormat.Serialize('doom', nil)));
end;

procedure TTestIdeProjectFormat.DovrebbeRileggereQuelloCheScrive;
var
  LEntries: TArray<TIdeProjectEntry>;
  LLines: TArray<TIdeProjectDirective>;
begin
  SetLength(LEntries, 1);
  LEntries[0].Kind := ikActor;
  LEntries[0].RelativePath := 'x.txt';
  LLines := TIdeProjectFormat.Parse(TIdeProjectFormat.Serialize('strife', LEntries));
  Assert.AreEqual<Integer>(2, Length(LLines));
  Assert.AreEqual('strife', LLines[0].Value);
  Assert.AreEqual('x.txt', LLines[1].Value);
end;

end.
