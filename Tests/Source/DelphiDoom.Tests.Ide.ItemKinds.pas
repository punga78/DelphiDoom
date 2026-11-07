{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the ide library - TIdeItemKinds and TIdeGames          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Ide.ItemKinds;

interface

uses
  DUnitX.TestFramework,
  DelphiDoom.Ide.Types,
  DelphiDoom.Ide.ItemKinds,
  DelphiDoom.Ide.Games;

type
  [TestFixture]
  [Category('ide')]
  TTestIdeItemKinds = class(TObject)
  public
    [Test]
    procedure DovrebbeFareAndataERitornoPerOgniTipo;
    [Test]
    procedure DovrebbeDareNessunoPerUnaParolaSconosciuta;
    [Test]
    procedure DovrebbeDistinguereLeMaiuscole;
    [Test]
    procedure DovrebbeNormalizzareIlNomeDelGioco;
    [Test]
    procedure DovrebbeRiconoscereISeiGiochi;
    [Test]
    procedure DovrebbeDareLaRigaDelMenuDeiGiochi;
  end;

implementation

{ TTestIdeItemKinds }

procedure TTestIdeItemKinds.DovrebbeFareAndataERitornoPerOgniTipo;
var
  LKind: TIdeItemKind;
begin
  for LKind := Low(TIdeItemKind) to High(TIdeItemKind) do
    Assert.AreEqual(Ord(LKind), Ord(TIdeItemKinds.FromText(TIdeItemKinds.ToText(LKind))));
  Assert.AreEqual('compiledscript', TIdeItemKinds.ToText(ikCompiledScript));
  Assert.AreEqual('none', TIdeItemKinds.ToText(ikNone));
end;

procedure TTestIdeItemKinds.DovrebbeDareNessunoPerUnaParolaSconosciuta;
begin
  Assert.AreEqual(Ord(ikNone), Ord(TIdeItemKinds.FromText('')));
  Assert.AreEqual(Ord(ikNone), Ord(TIdeItemKinds.FromText('texture')));
end;

procedure TTestIdeItemKinds.DovrebbeDistinguereLeMaiuscole;
begin
  // the project file is written by the ide in lower case; the old reader was case sensitive here
  Assert.AreEqual(Ord(ikNone), Ord(TIdeItemKinds.FromText('Script')));
end;

procedure TTestIdeItemKinds.DovrebbeNormalizzareIlNomeDelGioco;
begin
  Assert.AreEqual('heretic', TIdeGames.Normalize('  Heretic '));
end;

procedure TTestIdeItemKinds.DovrebbeRiconoscereISeiGiochi;
begin
  Assert.IsTrue(TIdeGames.IsKnown('Doom'));
  Assert.IsTrue(TIdeGames.IsKnown('heretic'));
  Assert.IsTrue(TIdeGames.IsKnown(' HEXEN'));
  Assert.IsTrue(TIdeGames.IsKnown('strife'));
  Assert.IsTrue(TIdeGames.IsKnown('radix'));
  Assert.IsTrue(TIdeGames.IsKnown('mars'));
  Assert.IsFalse(TIdeGames.IsKnown('mars3d'));
  Assert.IsFalse(TIdeGames.IsKnown('quake'));
  Assert.IsFalse(TIdeGames.IsKnown(''));
end;

procedure TTestIdeItemKinds.DovrebbeDareLaRigaDelMenuDeiGiochi;
begin
  Assert.AreEqual(0, TIdeGames.BoxIndex('doom'));
  Assert.AreEqual(1, TIdeGames.BoxIndex('heretic'));
  Assert.AreEqual(2, TIdeGames.BoxIndex('hexen'));
  Assert.AreEqual(3, TIdeGames.BoxIndex('strife'));
  Assert.AreEqual(0, TIdeGames.BoxIndex('radix'));
  Assert.AreEqual(0, TIdeGames.BoxIndex(''));
end;

end.
