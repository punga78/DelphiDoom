{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the heads-up display library - the scrolling text      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Hud.ScrollingText;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Hud.ScrollingText, DelphiDoom.Tests.Hud.Fakes;

type
  [TestFixture]
  [Category('hud')]
  TTestHudScrollingText = class(TObject)
  private
    FWorld: TFakeHudWorld;
    FWorldRef: IInterface;
    FWindow: THudScrollingText;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeRifiutareUnEchoMancante;
    [Test]
    procedure DovrebbeRifiutareUnNumeroDiRigheNonValido;
    [Test]
    procedure DovrebbeMettereLeRigheUnaSopraLAltra;
    [Test]
    procedure DovrebbeGirareNellAnello;
    [Test]
    procedure DovrebbeScrivereUnMessaggioInUnaRigaNuova;
    [Test]
    procedure DovrebbeCopiareIMessaggiAllEco;
    [Test]
    procedure DovrebbeScrivereSottoAlMessaggioGiaPresente;
    [Test]
    procedure DovrebbeTogliereLeRighePiuVecchieSeSonoTroppe;
    [Test]
    procedure DovrebbeLeggereLeRigheDallaPiuNuova;
    [Test]
    procedure DovrebbeRisegnareTutteLeRigheQuandoSparisce;
    [Test]
    procedure DovrebbeNonRisegnareSeEraGiaNascosta;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Hud.Types, DelphiDoom.Hud.TextLine;

{ TTestHudScrollingText }

procedure TTestHudScrollingText.Setup;
begin
  FWorld := TFakeHudWorld.Create;
  FWorldRef := FWorld;
  FWindow := THudScrollingText.Create(FWorld);
  FWindow.Initialize(0, 10, 3, 9, 33);
end;

procedure TTestHudScrollingText.TearDown;
begin
  FWindow.Free;
  FWorldRef := nil;
end;

procedure TTestHudScrollingText.DovrebbeRifiutareUnEchoMancante;
begin
  Assert.WillRaise(
    procedure
    begin
      THudScrollingText.Create(nil);
    end,
    EArgumentNilException);
end;

procedure TTestHudScrollingText.DovrebbeRifiutareUnNumeroDiRigheNonValido;
begin
  Assert.WillRaise(
    procedure
    begin
      FWindow.Initialize(0, 0, 0, 9, 33);
    end,
    EHudException);
  Assert.WillRaise(
    procedure
    begin
      FWindow.Initialize(0, 0, HUD_MAX_LINES + 1, 9, 33);
    end,
    EHudException);
end;

procedure TTestHudScrollingText.DovrebbeMettereLeRigheUnaSopraLAltra;
begin
  Assert.AreEqual(3, FWindow.Height);
  Assert.AreEqual(10, FWindow.Lines[0].Y);
  Assert.AreEqual(1, FWindow.Lines[1].Y);
  Assert.AreEqual(-8, FWindow.Lines[2].Y);
  Assert.AreEqual(33, FWindow.Lines[2].StartChar);
  Assert.AreEqual(0, FWindow.CurrentLine);
end;

procedure TTestHudScrollingText.DovrebbeGirareNellAnello;
begin
  FWindow.AddLine;
  Assert.AreEqual(1, FWindow.CurrentLine);
  FWindow.AddLine;
  FWindow.AddLine;
  Assert.AreEqual(0, FWindow.CurrentLine);
  Assert.AreEqual(HUD_UPDATE_PASSES, FWindow.Lines[2].NeedsUpdate);
end;

procedure TTestHudScrollingText.DovrebbeScrivereUnMessaggioInUnaRigaNuova;
begin
  FWindow.AddMessage('Bob: ', 'hello');
  FWindow.AddMessage('Ann: ', 'hi');
  Assert.AreEqual('Bob: hello', string(FWindow.Lines[1].Text));
  Assert.AreEqual('Ann: hi', string(FWindow.Lines[2].Text));
  Assert.AreEqual(2, FWindow.CurrentLine);
end;

procedure TTestHudScrollingText.DovrebbeCopiareIMessaggiAllEco;
begin
  FWindow.AddMessage('Bob: ', 'hello');
  FWindow.AddMessageBelow('', 'second');
  Assert.AreEqual('Bob: hello'#13#10'second'#13#10, FWorld.EchoLog);
end;

procedure TTestHudScrollingText.DovrebbeScrivereSottoAlMessaggioGiaPresente;
begin
  FWindow.AddMessageBelow('', 'first');
  FWindow.AddMessageBelow('', 'second');
  Assert.AreEqual('first'#13#10'second', string(FWindow.Current.Text));
  Assert.AreEqual(2, FWindow.Current.CountRows);
  Assert.AreEqual(0, FWindow.CurrentLine);
end;

procedure TTestHudScrollingText.DovrebbeTogliereLeRighePiuVecchieSeSonoTroppe;
var
  LIndex: Integer;
begin
  for LIndex := 1 to HUD_MAX_LINE_ROWS + 2 do
    FWindow.AddMessageBelow('', 'm' + IntToStr(LIndex));
  Assert.IsTrue(FWindow.Current.CountRows <= HUD_MAX_LINE_ROWS);
  Assert.AreEqual('m6', Copy(string(FWindow.Current.Text), Length(string(FWindow.Current.Text)) - 1, 2));
  Assert.IsFalse(Pos('m1', string(FWindow.Current.Text)) > 0);
end;

procedure TTestHudScrollingText.DovrebbeLeggereLeRigheDallaPiuNuova;
begin
  FWindow.AddMessage('', 'a');
  FWindow.AddMessage('', 'b');
  Assert.AreEqual('b', string(FWindow.LineBack(0).Text));
  Assert.AreEqual('a', string(FWindow.LineBack(1).Text));
  // two steps back from slot 2 is slot 0, one more wraps to the last slot
  Assert.AreSame(FWindow.Lines[0], FWindow.LineBack(2));
  FWindow.AddMessage('', 'c');
  Assert.AreSame(FWindow.Lines[0], FWindow.LineBack(0));
  Assert.AreSame(FWindow.Lines[2], FWindow.LineBack(1));
end;

procedure TTestHudScrollingText.DovrebbeRisegnareTutteLeRigheQuandoSparisce;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 2 do
    while FWindow.Lines[LIndex].NeedsUpdate > 0 do
      FWindow.Lines[LIndex].ConsumePass;
  FWindow.PrepareErase(False);
  for LIndex := 0 to 2 do
    Assert.AreEqual(HUD_UPDATE_PASSES, FWindow.Lines[LIndex].NeedsUpdate);
end;

procedure TTestHudScrollingText.DovrebbeNonRisegnareSeEraGiaNascosta;
var
  LIndex: Integer;
begin
  FWindow.PrepareErase(False);
  for LIndex := 0 to 2 do
    while FWindow.Lines[LIndex].NeedsUpdate > 0 do
      FWindow.Lines[LIndex].ConsumePass;
  FWindow.PrepareErase(False);
  Assert.AreEqual(0, FWindow.Lines[0].NeedsUpdate);
  FWindow.PrepareErase(True);
  FWindow.PrepareErase(False);
  Assert.AreEqual(HUD_UPDATE_PASSES, FWindow.Lines[0].NeedsUpdate);
end;

end.
