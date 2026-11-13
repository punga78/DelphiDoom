{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the heads-up display library - the input line          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Hud.InputText;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Hud.InputText;

type
  [TestFixture]
  [Category('hud')]
  TTestHudInputText = class(TObject)
  private
    FInput: THudInputText;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeScrivereICaratteriStampabili;
    [Test]
    procedure DovrebbeIgnorareICaratteriFuoriDallaTabella;
    [Test]
    procedure DovrebbeCancellareConIlBackspace;
    [Test]
    procedure DovrebbeMangiareIlTastoInvioSenzaScrivere;
    [Test]
    procedure DovrebbeDareFalsoPerGliAltriTasti;
    [Test]
    procedure DovrebbeSvuotareLaRigaConReset;
    [Test]
    procedure DovrebbeRispettareIlMargineSinistro;
    [Test]
    procedure DovrebbeRisegnareQuandoDiventaNascosta;
    [Test]
    procedure DovrebbeRipartireConInitialize;
  end;

implementation

uses
  DelphiDoom.Hud.Types, DelphiDoom.Tests.Hud.Fakes;

{ TTestHudInputText }

procedure TTestHudInputText.Setup;
begin
  FInput := THudInputText.Create(DoomHudRules.Keys);
  FInput.Initialize(0, 9, 33);
end;

procedure TTestHudInputText.TearDown;
begin
  FInput.Free;
end;

procedure TTestHudInputText.DovrebbeScrivereICaratteriStampabili;
begin
  Assert.IsTrue(FInput.KeyIn(Ord('H')));
  Assert.IsTrue(FInput.KeyIn(Ord(' ')));
  Assert.IsTrue(FInput.KeyIn(Ord('_')));
  Assert.AreEqual('H _', string(FInput.Line.Text));
end;

procedure TTestHudInputText.DovrebbeIgnorareICaratteriFuoriDallaTabella;
begin
  // the lower case letters and the signs after the underscore are not typed (the caller
  // changes them to upper case before)
  Assert.IsFalse(FInput.KeyIn(Ord('a')));
  Assert.IsFalse(FInput.KeyIn(Ord('{')));
  Assert.IsFalse(FInput.KeyIn(1));
  Assert.AreEqual(0, FInput.Line.Length);
end;

procedure TTestHudInputText.DovrebbeCancellareConIlBackspace;
begin
  FInput.KeyIn(Ord('A'));
  FInput.KeyIn(Ord('B'));
  Assert.IsTrue(FInput.KeyIn(127));
  Assert.AreEqual('A', string(FInput.Line.Text));
  Assert.IsTrue(FInput.KeyIn(127));
  Assert.IsTrue(FInput.KeyIn(127));
  Assert.AreEqual(0, FInput.Line.Length);
end;

procedure TTestHudInputText.DovrebbeMangiareIlTastoInvioSenzaScrivere;
begin
  FInput.KeyIn(Ord('A'));
  Assert.IsTrue(FInput.KeyIn(13));
  Assert.AreEqual('A', string(FInput.Line.Text));
end;

procedure TTestHudInputText.DovrebbeDareFalsoPerGliAltriTasti;
begin
  Assert.IsFalse(FInput.KeyIn(27));
  Assert.IsFalse(FInput.KeyIn(200));
end;

procedure TTestHudInputText.DovrebbeSvuotareLaRigaConReset;
begin
  FInput.KeyIn(Ord('A'));
  FInput.Reset;
  Assert.AreEqual(0, FInput.Line.Length);
  Assert.AreEqual(0, FInput.LeftMargin);
end;

procedure TTestHudInputText.DovrebbeRispettareIlMargineSinistro;
begin
  // the margin is always zero in the game: the line can be emptied but not past the start
  FInput.DeleteChar;
  Assert.AreEqual(0, FInput.Line.Length);
  FInput.KeyIn(Ord('A'));
  FInput.DeleteChar;
  Assert.AreEqual(0, FInput.Line.Length);
end;

procedure TTestHudInputText.DovrebbeRisegnareQuandoDiventaNascosta;
begin
  while FInput.Line.NeedsUpdate > 0 do
    FInput.Line.ConsumePass;
  FInput.PrepareErase(True);
  Assert.AreEqual(0, FInput.Line.NeedsUpdate);
  FInput.PrepareErase(False);
  Assert.AreEqual(HUD_UPDATE_PASSES, FInput.Line.NeedsUpdate);
end;

procedure TTestHudInputText.DovrebbeRipartireConInitialize;
begin
  FInput.KeyIn(Ord('A'));
  FInput.Initialize(4, 5, 33);
  Assert.AreEqual(0, FInput.Line.Length);
  Assert.AreEqual(4, FInput.Line.X);
  Assert.AreEqual(5, FInput.Line.Y);
end;

end.
