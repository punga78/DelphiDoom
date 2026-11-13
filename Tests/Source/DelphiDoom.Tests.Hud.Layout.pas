{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the heads-up display library - the glyph list          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Hud.Layout;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Hud.Layout;

type
  [TestFixture]
  [Category('hud')]
  TTestHudLayout = class(TObject)
  private
    FLayout: THudLayout;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbePartireVuota;
    [Test]
    procedure DovrebbeAggiungereUnGlifo;
    [Test]
    procedure DovrebbeCrescereSenzaPerdereIGlifi;
    [Test]
    procedure DovrebbeDimenticareTuttoConReset;
  end;

implementation

{ TTestHudLayout }

procedure TTestHudLayout.Setup;
begin
  FLayout := THudLayout.Create;
end;

procedure TTestHudLayout.TearDown;
begin
  FLayout.Free;
end;

procedure TTestHudLayout.DovrebbePartireVuota;
begin
  Assert.AreEqual(0, FLayout.Count);
  Assert.IsFalse(FLayout.CursorFits);
end;

procedure TTestHudLayout.DovrebbeAggiungereUnGlifo;
begin
  FLayout.Add(5, 10, 20, True);
  Assert.AreEqual(1, FLayout.Count);
  Assert.AreEqual(5, FLayout.Glyphs[0].Index);
  Assert.AreEqual(10, FLayout.Glyphs[0].X);
  Assert.AreEqual(20, FLayout.Glyphs[0].Y);
  Assert.IsTrue(FLayout.Glyphs[0].Highlighted);
  FLayout.Add(6, 1, 2);
  Assert.IsFalse(FLayout.Glyphs[1].Highlighted);
end;

procedure TTestHudLayout.DovrebbeCrescereSenzaPerdereIGlifi;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 999 do
    FLayout.Add(LIndex, LIndex * 2, LIndex * 3);
  Assert.AreEqual(1000, FLayout.Count);
  Assert.AreEqual(999, FLayout.Glyphs[999].Index);
  Assert.AreEqual(500, FLayout.Glyphs[250].X);
  Assert.AreEqual(3, FLayout.Glyphs[1].Y);
end;

procedure TTestHudLayout.DovrebbeDimenticareTuttoConReset;
begin
  FLayout.Add(1, 2, 3);
  FLayout.CursorFits := True;
  FLayout.CursorX := 4;
  FLayout.CursorY := 5;
  FLayout.EndX := 6;
  FLayout.EndY := 7;
  FLayout.Reset;
  Assert.AreEqual(0, FLayout.Count);
  Assert.IsFalse(FLayout.CursorFits);
  Assert.AreEqual(0, FLayout.CursorX);
  Assert.AreEqual(0, FLayout.CursorY);
  Assert.AreEqual(0, FLayout.EndX);
  Assert.AreEqual(0, FLayout.EndY);
end;

end.
