{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the ide library - TIdeUndoHistory                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Ide.UndoHistory;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Ide.UndoHistory;

type
  [TestFixture]
  [Category('ide')]
  TTestIdeUndoHistory = class(TObject)
  strict private
    FHistory: TIdeUndoHistory;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeEssereVuotoAllInizio;
    [Test]
    procedure DovrebbeTornareAlloStatoSalvato;
    [Test]
    procedure DovrebbeRifareLoStatoDisfatto;
    [Test]
    procedure DovrebbeCancellareIlRifareDopoUnNuovoSalvataggio;
    [Test]
    procedure DovrebbeTenereSoloGliUltimiCentoStati;
    [Test]
    procedure DovrebbeDareLoStatoCorrenteSeNonCeNullaDaDisfare;
    [Test]
    procedure DovrebbeSvuotareTutto;
  end;

implementation

{ TTestIdeUndoHistory }

procedure TTestIdeUndoHistory.Setup;
begin
  FHistory := TIdeUndoHistory.Create(100);
end;

procedure TTestIdeUndoHistory.TearDown;
begin
  FHistory.Free;
end;

procedure TTestIdeUndoHistory.DovrebbeEssereVuotoAllInizio;
begin
  Assert.IsFalse(FHistory.CanUndo);
  Assert.IsFalse(FHistory.CanRedo);
end;

procedure TTestIdeUndoHistory.DovrebbeTornareAlloStatoSalvato;
begin
  FHistory.Save('one');
  Assert.IsTrue(FHistory.CanUndo);
  Assert.AreEqual('one', string(FHistory.Undo('two')));
  Assert.IsFalse(FHistory.CanUndo);
  Assert.IsTrue(FHistory.CanRedo);
end;

procedure TTestIdeUndoHistory.DovrebbeRifareLoStatoDisfatto;
begin
  FHistory.Save('one');
  FHistory.Undo('two');
  Assert.AreEqual('two', string(FHistory.Redo('one')));
  Assert.IsTrue(FHistory.CanUndo);
  Assert.IsFalse(FHistory.CanRedo);
end;

procedure TTestIdeUndoHistory.DovrebbeCancellareIlRifareDopoUnNuovoSalvataggio;
begin
  FHistory.Save('one');
  FHistory.Undo('two');
  FHistory.Save('three');
  Assert.IsFalse(FHistory.CanRedo);
end;

procedure TTestIdeUndoHistory.DovrebbeTenereSoloGliUltimiCentoStati;
var
  LIndex: Integer;
  LCount: Integer;
  LCurrent: AnsiString;
begin
  for LIndex := 1 to 150 do
    FHistory.Save(AnsiString(IntToStr(LIndex)));
  LCount := 0;
  LCurrent := 'now';
  while FHistory.CanUndo do
  begin
    LCurrent := FHistory.Undo(LCurrent);
    Inc(LCount);
  end;
  Assert.AreEqual(100, LCount);
  // the oldest 50 were dropped
  Assert.AreEqual('51', string(LCurrent));
end;

procedure TTestIdeUndoHistory.DovrebbeDareLoStatoCorrenteSeNonCeNullaDaDisfare;
begin
  Assert.AreEqual('now', string(FHistory.Undo('now')));
  Assert.AreEqual('now', string(FHistory.Redo('now')));
  Assert.IsFalse(FHistory.CanRedo);
end;

procedure TTestIdeUndoHistory.DovrebbeSvuotareTutto;
begin
  FHistory.Save('one');
  FHistory.Undo('two');
  FHistory.Clear;
  Assert.IsFalse(FHistory.CanUndo);
  Assert.IsFalse(FHistory.CanRedo);
end;

end.
