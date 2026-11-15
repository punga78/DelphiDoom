{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - a saved game on the real data        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.AppSessionReal;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.GameHost.Types, DelphiDoom.War.Ui.Intf,
  DelphiDoom.War.App.SessionTypes, DelphiDoom.War.App.Session;

type
  /// <summary>
  ///   The game of the scenes on the real DATA.WAR, played with the events of a window and saved: the game that is
  ///   loaded must draw the same pictures as the one that was saved, now and after more frames. They are ignored
  ///   without DATA.WAR and the fonts of the remake
  /// </summary>
  [TestFixture]
  [Category('war')]
  TTestWarAppSessionReal = class(TObject)
  strict private
    function NewSession(ARace, AMission: Byte): TWarSession;
    function Hash(const ASession: TWarSession): Cardinal;
    function Mouse(AKind: TGameHostEventKind; AX, AY: Integer; AButton: TGameHostMouseButton): TGameHostEvent;
    function Key(AKind: TGameHostEventKind; AKey: Integer): TGameHostEvent;
    procedure Run(const ASession: TWarSession; ACount: Integer);
    procedure PlayAMission(const ASession: TWarSession);
  public
    [Test]
    procedure DovrebbeRifareLaMappaCaricandoUnGiocoConIClicDelGiocatore;
    [Test]
    procedure DovrebbeRifareIlMenuDalTitoloCaricandoUnGioco;
    [Test]
    procedure DovrebbeChiedereDiSalvareEDiCaricareDalMenuF10;
    [Test]
    procedure DovrebbeChiedereDiCaricareDalMenuPrincipale;
    [Test]
    procedure DovrebbeDareIlGiocoDelloStessoSeme;
  end;

implementation

uses
  DelphiDoom.War.Intf, DelphiDoom.War.Graphics.Intf, DelphiDoom.War.Factory, DelphiDoom.War.Campaign.Catalog, DelphiDoom.War.Ui.Factory,
  DelphiDoom.War.Level.Factory, DelphiDoom.War.Map.Factory, DelphiDoom.War.Sound.SeededRandom,
  DelphiDoom.War.MapUi.Launcher, DelphiDoom.War.Ui.Game, DelphiDoom.War.App.UiSessionGame,
  DelphiDoom.Tests.War.RealData, DelphiDoom.Tests.War.UiRig;

const
  VK_F10_KEY = $79;

{ TTestWarAppSessionReal }

function TTestWarAppSessionReal.NewSession(ARace, AMission: Byte): TWarSession;
var
  LStart: TWarSessionStart;
  LData: string;
  LSize: Cardinal;
  LStream: TFileStream;
begin
  LData := TWarRealData.RequireDataWar;
  TWarRealData.RequireFont(0);
  LStream := TFileStream.Create(LData, fmOpenRead or fmShareDenyNone);
  try
    LSize := Cardinal(LStream.Size);
  finally
    LStream.Free;
  end;
  LStart := Default(TWarSessionStart);
  LStart.Seed := 1;
  LStart.Race := ARace;
  LStart.Mission := AMission;
  Result := TWarSession.Create(
    function(const AStart: TWarSessionStart; const ARequests: IWarSessionRequests): IWarSessionGame
    var
      LCatalog: IWarCatalog;
      LArchive: IWarArchive;
      LGraphics: IWarGraphics;
      LLauncher: IWarMapLauncher;
      LGame: TWarUiGame;
    begin
      LCatalog := TWarFactory.CreateCatalog;
      LArchive := TWarFactory.OpenFile(LData, LCatalog);
      LGraphics := TWarFactory.CreateGraphics(LArchive, LCatalog);
      LLauncher := TWarMapLauncher.Create(TWarLevelFactory.CreateLevelLoader(LArchive, LCatalog), LGraphics,
        TWarMapFactory.CreateUnitCatalog, TWarLevelFactory.CreateObjectives, TWarSeededRandom.Create(AStart.Seed), True);
      LGame := TWarUiFactory.CreateGame(LArchive, LCatalog, LGraphics, TWarFactory.CreateFontMetrics,
        TWarUiRig.LoadFontImages, TWarCampaigns.Create, nil, LLauncher, 320, 200, ARequests);
      Result := TWarUiSessionGame.Create(LGame, AStart, TWarCampaigns.Create, 320, 200);
    end, LStart, LSize, nil, nil);
end;

function TTestWarAppSessionReal.Hash(const ASession: TWarSession): Cardinal;
var
  LPixels: TArray<Byte>;
  LIndex: Integer;
begin
  LPixels := ASession.Game.Pixels;
  Result := $811C9DC5;
  for LIndex := 0 to High(LPixels) do
    Result := (Result xor LPixels[LIndex]) * 16777619;
end;

function TTestWarAppSessionReal.Mouse(AKind: TGameHostEventKind; AX, AY: Integer;
  AButton: TGameHostMouseButton): TGameHostEvent;
begin
  Result := TGameHostEvent.Make(AKind);
  Result.X := AX;
  Result.Y := AY;
  Result.Button := AButton;
end;

function TTestWarAppSessionReal.Key(AKind: TGameHostEventKind; AKey: Integer): TGameHostEvent;
begin
  Result := TGameHostEvent.Make(AKind);
  Result.VirtualKey := AKey;
end;

procedure TTestWarAppSessionReal.Run(const ASession: TWarSession; ACount: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 1 to ACount do
    ASession.RunFrame(Single(1) / Single(60));
end;

procedure TTestWarAppSessionReal.PlayAMission(const ASession: TWarSession);
begin
  ASession.Post(Mouse(hekMouseMotion, 160, 100, hmbNone));
  Run(ASession, 40);
  // select what is under the mouse, then give an order with the right button
  ASession.Post(Mouse(hekMouseDown, 160, 100, hmbLeft));
  Run(ASession, 3);
  ASession.Post(Mouse(hekMouseUp, 160, 100, hmbLeft));
  Run(ASession, 20);
  ASession.Post(Mouse(hekMouseMotion, 200, 80, hmbNone));
  ASession.Post(Mouse(hekMouseDown, 200, 80, hmbRight));
  Run(ASession, 3);
  ASession.Post(Mouse(hekMouseUp, 200, 80, hmbRight));
  Run(ASession, 120);
end;

procedure TTestWarAppSessionReal.DovrebbeRifareLaMappaCaricandoUnGiocoConIClicDelGiocatore;
var
  LPlayed: TWarSession;
  LLoaded: TWarSession;
  LBefore: Cardinal;
begin
  LPlayed := NewSession(1, 1);
  try
    PlayAMission(LPlayed);
    LBefore := Hash(LPlayed);
    LLoaded := NewSession(1, 1);
    try
      LLoaded.Load(LPlayed.Save);
      Assert.AreEqual(LPlayed.FrameCount, LLoaded.FrameCount);
      Assert.AreEqual<Cardinal>(LBefore, Hash(LLoaded), 'la stessa pittura al fotogramma salvato');
      // the games go on alike
      Run(LPlayed, 90);
      Run(LLoaded, 90);
      Assert.AreEqual<Cardinal>(Hash(LPlayed), Hash(LLoaded), 'la stessa pittura dopo altri fotogrammi');
      Assert.AreNotEqual<Cardinal>(LBefore, Hash(LPlayed), 'il gioco e'' andato avanti');
    finally
      LLoaded.Free;
    end;
  finally
    LPlayed.Free;
  end;
end;

procedure TTestWarAppSessionReal.DovrebbeRifareIlMenuDalTitoloCaricandoUnGioco;
var
  LPlayed: TWarSession;
  LLoaded: TWarSession;
begin
  LPlayed := NewSession(0, 0);
  try
    LPlayed.Post(Mouse(hekMouseMotion, 160, 60, hmbNone));
    Run(LPlayed, 450);
    LLoaded := NewSession(0, 0);
    try
      LLoaded.Load(LPlayed.Save);
      Assert.AreEqual<Cardinal>(Hash(LPlayed), Hash(LLoaded));
    finally
      LLoaded.Free;
    end;
  finally
    LPlayed.Free;
  end;
end;

procedure TTestWarAppSessionReal.DovrebbeChiedereDiSalvareEDiCaricareDalMenuF10;
var
  LSession: TWarSession;
begin
  LSession := NewSession(1, 1);
  try
    LSession.Post(Mouse(hekMouseMotion, 160, 100, hmbNone));
    Run(LSession, 40);
    LSession.Post(Key(hekKeyDown, VK_F10_KEY));
    Run(LSession, 2);
    LSession.Post(Key(hekKeyUp, VK_F10_KEY));
    Run(LSession, 3);
    Assert.IsFalse(LSession.RequestsObject.TakeSave, 'il menu non ha ancora chiesto nulla');
    // S is the key of the button Save, L of the button Load
    LSession.Post(Key(hekKeyDown, Ord('S')));
    Run(LSession, 2);
    LSession.Post(Key(hekKeyUp, Ord('S')));
    Run(LSession, 3);
    Assert.IsTrue(LSession.RequestsObject.TakeSave);
    LSession.Post(Key(hekKeyDown, Ord('L')));
    Run(LSession, 2);
    LSession.Post(Key(hekKeyUp, Ord('L')));
    Run(LSession, 3);
    Assert.IsTrue(LSession.RequestsObject.TakeLoad);
  finally
    LSession.Free;
  end;
end;

procedure TTestWarAppSessionReal.DovrebbeChiedereDiCaricareDalMenuPrincipale;
var
  LSession: TWarSession;
begin
  LSession := NewSession(0, 0);
  try
    LSession.Post(Mouse(hekMouseMotion, 160, 60, hmbNone));
    // the logo lasts 260 frames and the menu follows
    Run(LSession, 450);
    Assert.IsFalse(LSession.RequestsObject.TakeLoad);
    LSession.Post(Key(hekKeyDown, Ord('L')));
    Run(LSession, 2);
    LSession.Post(Key(hekKeyUp, Ord('L')));
    Run(LSession, 3);
    Assert.IsTrue(LSession.RequestsObject.TakeLoad, 'il bottone Load existing game');
  finally
    LSession.Free;
  end;
end;

procedure TTestWarAppSessionReal.DovrebbeDareIlGiocoDelloStessoSeme;
var
  LFirst: TWarSession;
  LSecond: TWarSession;
begin
  LFirst := NewSession(2, 1);
  try
    PlayAMission(LFirst);
    LSecond := NewSession(2, 1);
    try
      PlayAMission(LSecond);
      Assert.AreEqual<Cardinal>(Hash(LFirst), Hash(LSecond));
    finally
      LSecond.Free;
    end;
  finally
    LFirst.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestWarAppSessionReal);

end.
