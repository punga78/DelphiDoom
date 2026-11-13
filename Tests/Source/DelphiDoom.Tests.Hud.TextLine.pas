{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the heads-up display library - a line of text          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Hud.TextLine;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Hud.TextLine;

type
  [TestFixture]
  [Category('hud')]
  TTestHudTextLine = class(TObject)
  private
    FLine: THudTextLine;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbePartireVuotaESegnataDaAggiornare;
    [Test]
    procedure DovrebbeTenerePostoEFontIniziale;
    [Test]
    procedure DovrebbeAggiungereECancellareCaratteri;
    [Test]
    procedure DovrebbeDareFalsoSeEPienaOVuota;
    [Test]
    procedure DovrebbeTroncareICaratteriAUnByte;
    [Test]
    procedure DovrebbeSostituireIlTesto;
    [Test]
    procedure DovrebbeContareLeRighe;
    [Test]
    procedure DovrebbeTogliereLaPrimaRigaConCrLf;
    [Test]
    procedure DovrebbeTogliereLaPrimaRigaConSoloLf;
    [Test]
    procedure DovrebbeTogliereLaPrimaRigaConSoloCr;
    [Test]
    procedure DovrebbeSvuotareSeCeUnaSolaRiga;
    [Test]
    procedure DovrebbeTenereLeRigheVuoteDopoLaPrima;
    [Test]
    procedure DovrebbeTagliareIlTestoSeCresceOltreLaLinea;
    [Test]
    procedure DovrebbeContareIPassiDiCancellazione;
    [Test]
    procedure DovrebbeRipartireConInitialize;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Hud.Types;

{ TTestHudTextLine }

procedure TTestHudTextLine.Setup;
begin
  FLine := THudTextLine.Create(5, 7, 33);
end;

procedure TTestHudTextLine.TearDown;
begin
  FLine.Free;
end;

procedure TTestHudTextLine.DovrebbePartireVuotaESegnataDaAggiornare;
begin
  Assert.AreEqual(0, FLine.Length);
  Assert.AreEqual(1, FLine.NeedsUpdate);
  Assert.AreEqual('', string(FLine.Text));
end;

procedure TTestHudTextLine.DovrebbeTenerePostoEFontIniziale;
begin
  Assert.AreEqual(5, FLine.X);
  Assert.AreEqual(7, FLine.Y);
  Assert.AreEqual(33, FLine.StartChar);
end;

procedure TTestHudTextLine.DovrebbeAggiungereECancellareCaratteri;
begin
  Assert.IsTrue(FLine.AddChar('A'));
  Assert.IsTrue(FLine.AddChar('b'));
  Assert.AreEqual('Ab', string(FLine.Text));
  Assert.AreEqual(HUD_UPDATE_PASSES, FLine.NeedsUpdate);
  Assert.IsTrue(FLine.CharAt(1) = 'b');
  Assert.IsTrue(FLine.DeleteChar);
  Assert.AreEqual('A', string(FLine.Text));
  FLine.Clear;
  Assert.AreEqual(0, FLine.Length);
  Assert.AreEqual(1, FLine.NeedsUpdate);
end;

procedure TTestHudTextLine.DovrebbeDareFalsoSeEPienaOVuota;
var
  LIndex: Integer;
begin
  Assert.IsFalse(FLine.DeleteChar);
  for LIndex := 1 to HUD_MAX_LINE_LENGTH do
    Assert.IsTrue(FLine.AddChar('x'));
  Assert.IsFalse(FLine.AddChar('y'));
  Assert.AreEqual(HUD_MAX_LINE_LENGTH, FLine.Length);
  FLine.AddText('zzz');
  Assert.AreEqual(HUD_MAX_LINE_LENGTH, FLine.Length);
end;

procedure TTestHudTextLine.DovrebbeTroncareICaratteriAUnByte;
begin
  FLine.AddChar(Char($1041));
  Assert.IsTrue(FLine.CharAt(0) = 'A');
end;

procedure TTestHudTextLine.DovrebbeSostituireIlTesto;
begin
  FLine.AddText('old text');
  FLine.Replace('new');
  Assert.AreEqual('new', string(FLine.Text));
  FLine.Replace('');
  Assert.AreEqual(0, FLine.Length);
end;

procedure TTestHudTextLine.DovrebbeContareLeRighe;
begin
  Assert.AreEqual(0, FLine.CountRows);
  FLine.AddText('one');
  Assert.AreEqual(1, FLine.CountRows);
  FLine.AddText(#13#10'two'#13#10'three');
  Assert.AreEqual(3, FLine.CountRows);
end;

procedure TTestHudTextLine.DovrebbeTogliereLaPrimaRigaConCrLf;
begin
  FLine.AddText('one'#13#10'two'#13#10'three');
  FLine.RemoveFirstRow;
  Assert.AreEqual('two'#13#10'three', string(FLine.Text));
  FLine.RemoveFirstRow;
  Assert.AreEqual('three', string(FLine.Text));
  Assert.AreEqual(HUD_UPDATE_PASSES, FLine.NeedsUpdate);
end;

procedure TTestHudTextLine.DovrebbeTogliereLaPrimaRigaConSoloLf;
begin
  FLine.AddText('one'#10'two');
  FLine.RemoveFirstRow;
  Assert.AreEqual('two', string(FLine.Text));
end;

procedure TTestHudTextLine.DovrebbeTogliereLaPrimaRigaConSoloCr;
begin
  FLine.AddText('one'#13'two'#13'three');
  FLine.RemoveFirstRow;
  Assert.AreEqual('two'#13#10'three', string(FLine.Text));
end;

procedure TTestHudTextLine.DovrebbeSvuotareSeCeUnaSolaRiga;
begin
  FLine.AddText('only');
  FLine.RemoveFirstRow;
  Assert.AreEqual(0, FLine.Length);
  FLine.RemoveFirstRow;
  Assert.AreEqual(0, FLine.Length);
end;

procedure TTestHudTextLine.DovrebbeTenereLeRigheVuoteDopoLaPrima;
begin
  FLine.AddText('one'#13#10#13#10'three');
  FLine.RemoveFirstRow;
  Assert.AreEqual(#13#10'three', string(FLine.Text));
end;

procedure TTestHudTextLine.DovrebbeTagliareIlTestoSeCresceOltreLaLinea;
var
  LIndex: Integer;
begin
  // a row of only line breaks grows when each break becomes #13#10
  for LIndex := 1 to HUD_MAX_LINE_LENGTH do
    FLine.AddChar(#10);
  FLine.RemoveFirstRow;
  Assert.IsTrue(FLine.Length <= HUD_MAX_LINE_LENGTH);
  Assert.IsTrue(FLine.Length > 0);
end;

procedure TTestHudTextLine.DovrebbeContareIPassiDiCancellazione;
begin
  FLine.AddChar('a');
  Assert.AreEqual(4, FLine.NeedsUpdate);
  FLine.ConsumePass;
  Assert.AreEqual(3, FLine.NeedsUpdate);
  FLine.ConsumePass;
  FLine.ConsumePass;
  FLine.ConsumePass;
  FLine.ConsumePass;
  Assert.AreEqual(0, FLine.NeedsUpdate);
  FLine.MarkChanged;
  Assert.AreEqual(4, FLine.NeedsUpdate);
end;

procedure TTestHudTextLine.DovrebbeRipartireConInitialize;
begin
  FLine.AddText('abc');
  FLine.Initialize(1, 2, 3);
  Assert.AreEqual(0, FLine.Length);
  Assert.AreEqual(1, FLine.X);
  Assert.AreEqual(2, FLine.Y);
  Assert.AreEqual(3, FLine.StartChar);
end;

end.
