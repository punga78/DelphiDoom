{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Gui library - the variables of a window            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Gui.WinVars;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('GuiWindow')]
  TTestGuiWinVars = class
  public
    [Test]
    procedure BoolLeggeUnTestoComeAtoi;
    [Test]
    procedure IntLeggeLaParteIntera;
    [Test]
    procedure IntXValeZeroComeLoriginale;
    [Test]
    procedure FloatDaTestoEInTestoConSeiDecimali;
    [Test]
    procedure StrXEUnoSeNonVuota;
    [Test]
    procedure Vec4AccettaVirgoleESpazi;
    [Test]
    procedure Vec4ConPiuPocheCifreTieneLeAltre;
    [Test]
    procedure Vec4InTestoSenzaZeriFinali;
    [Test]
    procedure RettangoloXYWH;
    [Test]
    procedure Vec2eVec3DaTesto;
    [Test]
    procedure InitConGuiLegaIlDizionario;
    [Test]
    procedure ScrivereUnaVariabileLegataAggiornaIlDizionario;
    [Test]
    procedure UpdateLeggeIlDizionario;
    [Test]
    procedure InitSenzaPrefissoImpostaIlValore;
    [Test]
    procedure InitConNomeCortoNonLega;
    [Test]
    procedure IlNomeConAsteriscoSiRisolveNelDizionario;
    [Test]
    procedure AssignVarCopiaValoreENome;
    [Test]
    procedure StrLengthLeggeIlDizionarioSeLegata;
    [Test]
    procedure RettangoloIsEqualConfrontaTuttiICampi;
    [Test]
    procedure RettangoloContieneUnPunto;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Scanner.IdDict, DelphiDoom.IdLib.Math.Vec2, DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.IdLib.Math.Vec4, DelphiDoom.Gui.Rectangle, DelphiDoom.Gui.WinVar.Base, DelphiDoom.Gui.WinVar.Bool,
  DelphiDoom.Gui.WinVar.Int, DelphiDoom.Gui.WinVar.Float, DelphiDoom.Gui.WinVar.Str,
  DelphiDoom.Gui.WinVar.Background, DelphiDoom.Gui.WinVar.Vec2, DelphiDoom.Gui.WinVar.Vec3,
  DelphiDoom.Gui.WinVar.Vec4, DelphiDoom.Gui.WinVar.Rectangle;

procedure TTestGuiWinVars.BoolLeggeUnTestoComeAtoi;
var
  LVar: TGuiWinBool;
begin
  LVar := TGuiWinBool.Create;
  try
    LVar.SetFromText('2');
    Assert.IsTrue(LVar.Value);
    Assert.AreEqual('1', string(LVar.AsText));
    Assert.AreEqual(Single(1.0), LVar.X);
    LVar.SetFromText('0');
    Assert.IsFalse(LVar.Value);
    LVar.SetFromText('abc');
    Assert.IsFalse(LVar.Value);
    Assert.AreEqual(Single(0.0), LVar.X);
  finally
    LVar.Free;
  end;
end;

procedure TTestGuiWinVars.IntLeggeLaParteIntera;
var
  LVar: TGuiWinInt;
begin
  LVar := TGuiWinInt.Create;
  try
    LVar.SetFromText('12x');
    Assert.AreEqual(12, LVar.Value);
    Assert.AreEqual('12', string(LVar.AsText));
    LVar.SetFromText('-7');
    Assert.AreEqual(-7, LVar.Value);
  finally
    LVar.Free;
  end;
end;

procedure TTestGuiWinVars.IntXValeZeroComeLoriginale;
var
  LVar: TGuiWinInt;
begin
  LVar := TGuiWinInt.Create;
  try
    LVar.Value := 5;
    Assert.AreEqual(Single(0.0), LVar.X);
  finally
    LVar.Free;
  end;
end;

procedure TTestGuiWinVars.FloatDaTestoEInTestoConSeiDecimali;
var
  LVar: TGuiWinFloat;
begin
  LVar := TGuiWinFloat.Create;
  try
    LVar.SetFromText('2.5');
    Assert.AreEqual(Single(2.5), LVar.Value);
    Assert.AreEqual('2.500000', string(LVar.AsText));
    Assert.AreEqual(Single(2.5), LVar.X);
  finally
    LVar.Free;
  end;
end;

procedure TTestGuiWinVars.StrXEUnoSeNonVuota;
var
  LVar: TGuiWinStr;
begin
  LVar := TGuiWinStr.Create;
  try
    Assert.AreEqual(Single(0.0), LVar.X);
    LVar.SetFromText('ciao');
    Assert.AreEqual(Single(1.0), LVar.X);
    Assert.AreEqual('ciao', string(LVar.AsText));
    Assert.AreEqual(4, LVar.Length);
  finally
    LVar.Free;
  end;
end;

procedure TTestGuiWinVars.Vec4AccettaVirgoleESpazi;
var
  LVar: TGuiWinVec4;
begin
  LVar := TGuiWinVec4.Create;
  try
    LVar.SetFromText('1,2,3,4');
    Assert.AreEqual(Single(3.0), LVar.Value.Z);
    LVar.SetFromText('5 6 7 8');
    Assert.AreEqual(Single(8.0), LVar.Value.W);
    Assert.AreEqual(Single(5.0), LVar.X);
  finally
    LVar.Free;
  end;
end;

procedure TTestGuiWinVars.Vec4ConPiuPocheCifreTieneLeAltre;
var
  LVar: TGuiWinVec4;
begin
  LVar := TGuiWinVec4.Create;
  try
    LVar.SetFromText('1 2 3 4');
    LVar.SetFromText('9 8');
    Assert.AreEqual(Single(9.0), LVar.Value.X);
    Assert.AreEqual(Single(8.0), LVar.Value.Y);
    Assert.AreEqual(Single(3.0), LVar.Value.Z);
    Assert.AreEqual(Single(4.0), LVar.Value.W);
  finally
    LVar.Free;
  end;
end;

procedure TTestGuiWinVars.Vec4InTestoSenzaZeriFinali;
var
  LVar: TGuiWinVec4;
begin
  LVar := TGuiWinVec4.Create;
  try
    LVar.SetFromText('1 2.5 3 4');
    Assert.AreEqual('1 2.5 3 4', string(LVar.AsText));
    LVar.Zero;
    Assert.AreEqual('0 0 0 0', string(LVar.AsText));
  finally
    LVar.Free;
  end;
end;

procedure TTestGuiWinVars.RettangoloXYWH;
var
  LVar: TGuiWinRectangle;
begin
  LVar := TGuiWinRectangle.Create;
  try
    LVar.SetFromText('10 20 30 40');
    Assert.AreEqual(Single(30.0), LVar.Value.W);
    Assert.AreEqual(Single(40.0), LVar.Value.H);
    Assert.AreEqual(Single(40.0), LVar.Value.Right);
    Assert.AreEqual(Single(60.0), LVar.Value.Bottom);
    Assert.AreEqual('10 20 30 40', string(LVar.AsText));
    LVar.SetFromText('1,2,3,4');
    Assert.AreEqual(Single(3.0), LVar.Value.W);
  finally
    LVar.Free;
  end;
end;

procedure TTestGuiWinVars.Vec2eVec3DaTesto;
var
  LVec2: TGuiWinVec2;
  LVec3: TGuiWinVec3;
begin
  LVec2 := TGuiWinVec2.Create;
  LVec3 := TGuiWinVec3.Create;
  try
    LVec2.SetFromText('1,2');
    Assert.AreEqual(Single(2.0), LVec2.Value.Y);
    Assert.AreEqual('1 2', string(LVec2.AsText));
    LVec3.SetFromText('1 2 3');
    Assert.AreEqual(Single(3.0), LVec3.Value.Z);
    Assert.AreEqual(Single(1.0), LVec3.X);
  finally
    LVec3.Free;
    LVec2.Free;
  end;
end;

procedure TTestGuiWinVars.InitConGuiLegaIlDizionario;
var
  LDict: TIdDict;
  LVar: TGuiWinFloat;
begin
  LDict := TIdDict.Create;
  LVar := TGuiWinFloat.Create;
  try
    LDict.SetFloat('speed', 7.0);
    Assert.IsTrue(LVar.Init('gui::speed', LDict));
    Assert.IsTrue(LVar.NeedsUpdate);
    Assert.AreEqual('speed', string(LVar.GetName));
    Assert.AreEqual(Single(7.0), LVar.Value);
  finally
    LVar.Free;
    LDict.Free;
  end;
end;

procedure TTestGuiWinVars.ScrivereUnaVariabileLegataAggiornaIlDizionario;
var
  LDict: TIdDict;
  LVar: TGuiWinInt;
begin
  LDict := TIdDict.Create;
  LVar := TGuiWinInt.Create;
  try
    LVar.Init('gui::count', LDict);
    LVar.Value := 12;
    Assert.AreEqual(12, LDict.GetInt('count'));
    LVar.SetFromText('30');
    Assert.AreEqual(30, LDict.GetInt('count'));
  finally
    LVar.Free;
    LDict.Free;
  end;
end;

procedure TTestGuiWinVars.UpdateLeggeIlDizionario;
var
  LDict: TIdDict;
  LVar: TGuiWinStr;
begin
  LDict := TIdDict.Create;
  LVar := TGuiWinStr.Create;
  try
    LVar.Init('gui::title', LDict);
    LDict.SetValue('title', 'nuovo');
    LVar.Update;
    Assert.AreEqual('nuovo', string(LVar.AsText));
  finally
    LVar.Free;
    LDict.Free;
  end;
end;

procedure TTestGuiWinVars.InitSenzaPrefissoImpostaIlValore;
var
  LDict: TIdDict;
  LVar: TGuiWinInt;
begin
  LDict := TIdDict.Create;
  LVar := TGuiWinInt.Create;
  try
    Assert.IsFalse(LVar.Init('42', LDict));
    Assert.AreEqual(42, LVar.Value);
    Assert.IsFalse(LVar.NeedsUpdate);
  finally
    LVar.Free;
    LDict.Free;
  end;
end;

procedure TTestGuiWinVars.InitConNomeCortoNonLega;
var
  LDict: TIdDict;
  LVar: TGuiWinStr;
begin
  LDict := TIdDict.Create;
  LVar := TGuiWinStr.Create;
  try
    // "gui::" has five characters: not more than five, so it is a value
    Assert.IsFalse(LVar.Init('gui::', LDict));
    Assert.AreEqual('gui::', string(LVar.AsText));
    // only "gui:" is compared, but five characters are stripped
    Assert.IsTrue(LVar.Init('gui:xabc', LDict));
    Assert.AreEqual('abc', string(LVar.GetName));
  finally
    LVar.Free;
    LDict.Free;
  end;
end;

procedure TTestGuiWinVars.IlNomeConAsteriscoSiRisolveNelDizionario;
var
  LDict: TIdDict;
  LVar: TGuiWinStr;
begin
  LDict := TIdDict.Create;
  LVar := TGuiWinStr.Create;
  try
    LDict.SetValue('indirect', 'real');
    LDict.SetValue('real', 'dato');
    LVar.SetGuiInfo(LDict, '*indirect');
    Assert.AreEqual('real', string(LVar.GetName));
    LVar.Update;
    Assert.AreEqual('dato', string(LVar.AsText));
  finally
    LVar.Free;
    LDict.Free;
  end;
end;

procedure TTestGuiWinVars.AssignVarCopiaValoreENome;
var
  LDict: TIdDict;
  LSource: TGuiWinVec4;
  LCopy: TGuiWinVec4;
begin
  LDict := TIdDict.Create;
  LSource := TGuiWinVec4.Create;
  LCopy := TGuiWinVec4.Create;
  try
    LSource.Init('gui::col', LDict);
    LSource.Value := TIdVec4.Create(1, 2, 3, 4);
    LCopy.AssignVar(LSource);
    Assert.AreEqual(Single(3.0), LCopy.Value.Z);
    Assert.AreEqual('col', string(LCopy.GetName));
    Assert.IsTrue(LCopy.NeedsUpdate);
  finally
    LCopy.Free;
    LSource.Free;
    LDict.Free;
  end;
end;

procedure TTestGuiWinVars.StrLengthLeggeIlDizionarioSeLegata;
var
  LDict: TIdDict;
  LVar: TGuiWinBackground;
begin
  LDict := TIdDict.Create;
  LVar := TGuiWinBackground.Create;
  try
    LVar.Init('gui::bg', LDict);
    LDict.SetValue('bg', 'guis/assets/x');
    Assert.AreEqual(13, LVar.Length);
    LDict.SetValue('bg', '^1ab');
    Assert.AreEqual(2, LVar.LengthWithoutColors);
    LVar.RemoveColors;
    Assert.AreEqual('ab', string(LVar.AsText));
  finally
    LVar.Free;
    LDict.Free;
  end;
end;

procedure TTestGuiWinVars.RettangoloIsEqualConfrontaTuttiICampi;
begin
  Assert.IsTrue(TGuiRectangle.Create(1, 2, 3, 4).IsEqual(TGuiRectangle.Create(1, 2, 3, 4)));
  Assert.IsFalse(TGuiRectangle.Create(1, 2, 3, 4).IsEqual(TGuiRectangle.Create(1, 2, 3, 5)));
  Assert.IsTrue(TGuiRectangle.FromVec4(TIdVec4.Create(1, 2, 3, 4)).IsEqual(TGuiRectangle.Create(1, 2, 3, 4)));
end;

procedure TTestGuiWinVars.RettangoloContieneUnPunto;
var
  LRect: TGuiRectangle;
begin
  LRect := TGuiRectangle.Create(10, 10, 20, 20);
  Assert.IsTrue(LRect.Contains(10, 10));
  Assert.IsTrue(LRect.Contains(30, 30));
  Assert.IsFalse(LRect.Contains(31, 20));
  Assert.IsFalse(TGuiRectangle.Create(5, 5, 0, 0).Contains(5, 5));
  LRect.Offset(5, -5);
  Assert.AreEqual(Single(15.0), LRect.X);
  Assert.AreEqual(Single(5.0), LRect.Y);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGuiWinVars);

end.
