{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the heads-up display library - the heads-up display    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Hud.HeadsUp;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Hud.Types, DelphiDoom.Hud.Intf, DelphiDoom.Hud.View,
  DelphiDoom.Tests.Hud.Fakes;

type
  [TestFixture]
  [Category('hud')]
  TTestHudHeadsUp = class(TObject)
  private
    FWorld: TFakeHudWorld;
    FWorldRef: IInterface;
    FHeadsUp: IHeadsUp;
    FView: IHudView;
    function StartParams: THudStartParams;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbePartireSenzaNienteDaVedere;
    [Test]
    procedure DovrebbeFarPartireIlLivello;
    [Test]
    procedure DovrebbeSpegnereLeSpieAllInizioDelLivello;
    [Test]
    procedure DovrebbeMostrareIlMessaggioDelGiocatoreAlTic;
    [Test]
    procedure DovrebbeInoltrareITastiAllaChat;
    [Test]
    procedure DovrebbeDareICaratteriDellaChatDaMandare;
    [Test]
    procedure DovrebbeScegliereLaTastieraDellaLingua;
    [Test]
    procedure DovrebbeContareIFotogrammiAlSecondo;
    [Test]
    procedure DovrebbeScrivereIlTestoDeiFotogrammiAlTic;
    [Test]
    procedure DovrebbeScrivereIlTempoDelLivello;
    [Test]
    procedure DovrebbeSostituireIlTempoDelLivelloSenzaAccumulare;
    [Test]
    procedure DovrebbeDireSeLaChatEAperta;
    [Test]
    procedure DovrebbeLeggereLeImpostazioniAlTic;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Hud.Factory;

{ TTestHudHeadsUp }

procedure TTestHudHeadsUp.Setup;
begin
  FWorld := TFakeHudWorld.Create;
  FWorldRef := FWorld;
  FWorld.InGame[0] := True;
  FWorld.InGame[1] := True;
  THudFactory.CreateHeadsUp(DoomHudRules, FWorld, FWorld, FWorld, FWorld, FWorld, FWorld, FHeadsUp, FView);
end;

procedure TTestHudHeadsUp.TearDown;
begin
  FView := nil;
  FHeadsUp := nil;
  FWorldRef := nil;
end;

function TTestHudHeadsUp.StartParams: THudStartParams;
begin
  Result.MessageX := 0;
  Result.MessageY := 0;
  Result.MessageHeight := 1;
  Result.LineHeight := 9;
  Result.StartChar := 33;
  Result.TitleX := 2;
  Result.TitleY := 150;
  Result.LevelTimeX := 3;
  Result.LevelTimeY := 141;
  Result.InputX := 0;
  Result.InputY := 9;
  Result.Title := 'E1M1: Hangar';
end;

procedure TTestHudHeadsUp.DovrebbePartireSenzaNienteDaVedere;
begin
  Assert.IsFalse(FView.MessageVisible);
  Assert.IsFalse(FView.ChatVisible);
  Assert.AreEqual('', FView.FpsText);
  Assert.AreEqual(#0, FHeadsUp.DequeueChatChar);
end;

procedure TTestHudHeadsUp.DovrebbeFarPartireIlLivello;
begin
  FHeadsUp.Start(StartParams);
  Assert.IsTrue(FWorld.Attached);
  Assert.AreEqual('E1M1: Hangar', string(FView.Title.Text));
  Assert.AreEqual(2, FView.Title.X);
  Assert.AreEqual(150, FView.Title.Y);
  Assert.AreEqual(3, FView.LevelTime.X);
  Assert.AreEqual(141, FView.LevelTime.Y);
  Assert.AreEqual(9, FView.ChatLine.Line.Y);
  Assert.AreEqual(1, FView.MessageWindow.Height);
end;

procedure TTestHudHeadsUp.DovrebbeSpegnereLeSpieAllInizioDelLivello;
begin
  FWorld.ChatOn := True;
  FWorld.MessageForced := True;
  FHeadsUp.Start(StartParams);
  Assert.IsFalse(FWorld.ChatOn);
  Assert.IsFalse(FWorld.MessageForced);
  Assert.IsFalse(FView.MessageVisible);
end;

procedure TTestHudHeadsUp.DovrebbeMostrareIlMessaggioDelGiocatoreAlTic;
begin
  FHeadsUp.Start(StartParams);
  FWorld.PlayerMessage := 'Picked up a clip';
  FHeadsUp.Ticker;
  Assert.IsTrue(FView.MessageVisible);
  Assert.AreEqual('Picked up a clip', string(FView.MessageWindow.Current.Text));
  Assert.AreEqual('Picked up a clip'#13#10, FWorld.EchoLog);
end;

procedure TTestHudHeadsUp.DovrebbeInoltrareITastiAllaChat;
begin
  FHeadsUp.Start(StartParams);
  FWorld.NetGame := True;
  Assert.IsTrue(FHeadsUp.Responder(Ord('t'), True));
  Assert.IsTrue(FView.ChatVisible);
  Assert.IsTrue(FHeadsUp.Responder(Ord('g'), True));
  Assert.AreEqual('G', string(FView.ChatLine.Line.Text));
end;

procedure TTestHudHeadsUp.DovrebbeDareICaratteriDellaChatDaMandare;
begin
  FHeadsUp.Start(StartParams);
  FWorld.NetGame := True;
  FHeadsUp.Responder(Ord('t'), True);
  FHeadsUp.Responder(Ord('g'), True);
  Assert.AreEqual(#5, FHeadsUp.DequeueChatChar);
  Assert.AreEqual('G', FHeadsUp.DequeueChatChar);
  Assert.AreEqual(#0, FHeadsUp.DequeueChatChar);
end;

procedure TTestHudHeadsUp.DovrebbeScegliereLaTastieraDellaLingua;
var
  LTable: THudShiftTable;
begin
  FHeadsUp.Initialize;
  LTable := FHeadsUp.GetShiftTable;
  Assert.AreEqual('!', LTable[Ord('1')]);
  FWorld.French := True;
  FHeadsUp.Initialize;
  LTable := FHeadsUp.GetShiftTable;
  Assert.AreEqual('1', LTable[Ord('1')]);
end;

procedure TTestHudHeadsUp.DovrebbeContareIFotogrammiAlSecondo;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 127 do
    FHeadsUp.RecordFrameTime(LIndex * 2 * HUD_FRACUNIT);
  Assert.AreEqual(35 * 128 * HUD_FRACUNIT div (127 * 2 * HUD_FRACUNIT + 1), FHeadsUp.FramesPerSecond);
end;

procedure TTestHudHeadsUp.DovrebbeScrivereIlTestoDeiFotogrammiAlTic;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 127 do
    FHeadsUp.RecordFrameTime(LIndex * 2 * HUD_FRACUNIT);
  FHeadsUp.Ticker;
  Assert.AreEqual('17 fps', FView.FpsText);
end;

procedure TTestHudHeadsUp.DovrebbeScrivereIlTempoDelLivello;
begin
  FHeadsUp.Start(StartParams);
  FView.UpdateLevelTime((62 * 60 + 5) * 35);
  Assert.AreEqual('Time: 01:02:05', string(FView.LevelTime.Text));
end;

procedure TTestHudHeadsUp.DovrebbeSostituireIlTempoDelLivelloSenzaAccumulare;
begin
  FHeadsUp.Start(StartParams);
  FView.UpdateLevelTime(35);
  FView.UpdateLevelTime(70);
  Assert.AreEqual('Time: 00:00:02', string(FView.LevelTime.Text));
end;

procedure TTestHudHeadsUp.DovrebbeDireSeLaChatEAperta;
begin
  Assert.IsFalse(FView.ChatVisible);
  FWorld.ChatOn := True;
  Assert.IsTrue(FView.ChatVisible);
end;

procedure TTestHudHeadsUp.DovrebbeLeggereLeImpostazioniAlTic;
begin
  FHeadsUp.Start(StartParams);
  FWorld.MessagesShown := False;
  FWorld.PlayerMessage := 'quiet';
  FHeadsUp.Ticker;
  Assert.IsFalse(FView.MessageVisible);
  FWorld.MessagesShown := True;
  FHeadsUp.Ticker;
  Assert.IsTrue(FView.MessageVisible);
end;

end.
