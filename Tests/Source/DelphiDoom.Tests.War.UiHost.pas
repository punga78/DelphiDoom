{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - input, events of the window, sprites }
{  from the archive and the images of the fonts                                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.UiHost;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.GameHost.Types, DelphiDoom.War.Graphics.Types,
  DelphiDoom.War.Graphics.Intf, DelphiDoom.War.Ui.Types, DelphiDoom.War.Ui.Intf, DelphiDoom.War.Ui.Game,
  DelphiDoom.War.Ui.EventAdapter, DelphiDoom.Tests.War.UiFakes;

type
  /// <summary>
  ///   The input of the game, the adapter of the events of Libs\GameHost, the sprites made from the records of an archive
  ///   (a fake of it) and the PNG of a font. No window, no DATA.WAR
  /// </summary>
  [TestFixture]
  [Category('war')]
  TTestWarUiHost = class(TObject)
  private
    FGame: TWarUiGame;
    FAdapter: TWarUiEventAdapter;
    FAdapterRef: IInterface;
    function KeyEvent(AKind: TGameHostEventKind; AVirtualKey: Integer; ACharacter: Cardinal;
      AModifiers: TGameHostModifiers): TGameHostEvent;
    function MouseEvent(AKind: TGameHostEventKind; AButton: TGameHostMouseButton; AX, AY: Integer): TGameHostEvent;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeSegnareLeTransizioniPerUnSoloFotogramma;
    [Test]
    procedure DovrebbeNonSegnareUnaTransizioneSeLoStatoNonCambia;
    [Test]
    procedure DovrebbeTroncareLaPosizioneDelMouseAlNumeroIntero;
    [Test]
    procedure DovrebbeAzzerareTuttoQuandoLaFinestraPerdeIlFuoco;
    [Test]
    procedure DovrebbeTradurreIlMouseDellaFinestra;
    [Test]
    procedure DovrebbeIgnorareIlPulsanteCentraleEImovimentiDellaRotella;
    [Test]
    procedure DovrebbeTradurreITastiVirtualiDiWindows;
    [Test]
    procedure DovrebbeLeggereShiftCtrlEAltDaiModificatoriEnonDalTasto;
    [Test]
    procedure DovrebbeMandareIlCarattereDelTastoAlPannelloDeiTrucchi;
    [Test]
    procedure DovrebbeChiedereLUscitaQuandoLaFinestraSiChiude;
    [Test]
    procedure DovrebbeIgnorareUnTastoCheIlGiocoNonUsa;
    [Test]
    procedure DovrebbeFareLoSpriteDiUnImmagineDiUnCursoreEDiUnoSpriteDelloArchivio;
    [Test]
    procedure DovrebbeRifiutareUnRecordCheNonESprite;
    [Test]
    procedure DovrebbeLeggereIlPuntoCaldoDiUnCursore;
    [Test]
    procedure DovrebbeLeggereUnPngDiUnFontComeRgba;
    [Test]
    procedure DovrebbeFareUnaTexturaVuotaFinoAlPrimoAggiornamentoDiUnoSprite;
  end;

implementation

uses
  System.Classes, DelphiDoom.Png.Client, DelphiDoom.Png.Intf, DelphiDoom.Png.Engine, DelphiDoom.Zlib.Provider,
  DelphiDoom.War.Types, DelphiDoom.War.Intf, DelphiDoom.War.Factory, DelphiDoom.War.Render.Types,
  DelphiDoom.War.Ui.Input, DelphiDoom.War.Ui.SpriteLoader, DelphiDoom.War.Ui.FontImageLoader,
  DelphiDoom.War.Ui.SceneBase;

type
  /// <summary>An IWarGraphics with one record of each kind (the other calls are not used by the interface)</summary>
  TFakeGraphics = class(TInterfacedObject, IWarGraphics)
  public
    function GetPalette(AIndex: Integer): TBytes;
    function ComposePalette(AIndex1, AIndex2: Integer): TBytes;
    function GetImage(AIndex: Integer): TWarImage;
    function GetSprite(AIndex: Integer): TWarSprite;
    function GetCursor(AIndex: Integer): TWarCursor;
    function GetTiles(AIndex: Integer): TWarTiles;
    function GetTileset(AIndex: Integer): TWarTileset;
  end;

{ TFakeGraphics }

function TFakeGraphics.GetPalette(AIndex: Integer): TBytes;
begin
  Result := nil;
end;

function TFakeGraphics.ComposePalette(AIndex1, AIndex2: Integer): TBytes;
begin
  Result := nil;
end;

function TFakeGraphics.GetImage(AIndex: Integer): TWarImage;
begin
  Result.Width := 2;
  Result.Height := 1;
  Result.Pixels := [1, 2, 3, 255, 4, 5, 6, 255];
end;

function TFakeGraphics.GetSprite(AIndex: Integer): TWarSprite;
begin
  Result.FrameWidth := 1;
  Result.FrameHeight := 1;
  SetLength(Result.Frames, 2);
  Result.Frames[0].Width := 1;
  Result.Frames[0].Height := 1;
  Result.Frames[0].Pixels := [9, 9, 9, 255];
  Result.Frames[1].Width := 1;
  Result.Frames[1].Height := 1;
  Result.Frames[1].Pixels := [7, 7, 7, 255];
end;

function TFakeGraphics.GetCursor(AIndex: Integer): TWarCursor;
begin
  Result.HotX := 5;
  Result.HotY := 6;
  Result.Width := 1;
  Result.Height := 1;
  Result.Pixels := [8, 8, 8, 255];
end;

function TFakeGraphics.GetTiles(AIndex: Integer): TWarTiles;
begin
  Result := Default(TWarTiles);
end;

function TFakeGraphics.GetTileset(AIndex: Integer): TWarTileset;
begin
  Result := Default(TWarTileset);
end;

{ TTestWarUiHost }

procedure TTestWarUiHost.Setup;
begin
  FGame := TFakeUiRig.CreateGame(TFakeUiSprites.Create, nil, nil, False);
  FAdapter := TWarUiEventAdapter.Create(FGame);
  FAdapterRef := FAdapter;
end;

procedure TTestWarUiHost.TearDown;
begin
  FAdapterRef := nil;
  FreeAndNil(FGame);
end;

function TTestWarUiHost.KeyEvent(AKind: TGameHostEventKind; AVirtualKey: Integer; ACharacter: Cardinal;
  AModifiers: TGameHostModifiers): TGameHostEvent;
begin
  Result := TGameHostEvent.Make(AKind);
  Result.VirtualKey := AVirtualKey;
  Result.Character := ACharacter;
  Result.Modifiers := AModifiers;
end;

function TTestWarUiHost.MouseEvent(AKind: TGameHostEventKind; AButton: TGameHostMouseButton; AX, AY: Integer):
  TGameHostEvent;
begin
  Result := TGameHostEvent.Make(AKind);
  Result.Button := AButton;
  Result.X := AX;
  Result.Y := AY;
end;

procedure TTestWarUiHost.DovrebbeSegnareLeTransizioniPerUnSoloFotogramma;
begin
  FGame.Input.SetButton(wmbLeft, True);
  Assert.IsTrue(FGame.Input.IsButtonHeld(wmbLeft));
  Assert.IsTrue(FGame.Input.IsButtonJustPressed(wmbLeft));
  FGame.Input.BeginFrame;
  Assert.IsTrue(FGame.Input.IsButtonHeld(wmbLeft));
  Assert.IsFalse(FGame.Input.IsButtonJustPressed(wmbLeft));
  FGame.Input.SetButton(wmbLeft, False);
  Assert.IsTrue(FGame.Input.IsButtonJustReleased(wmbLeft));
  FGame.Input.SetKey(wkA, True);
  Assert.IsTrue(FGame.Input.IsKeyJustPressed(wkA));
  Assert.IsTrue(FGame.Input.IsKeyHeld(wkA));
  FGame.Input.SetKey(wkA, False);
  Assert.IsTrue(FGame.Input.IsKeyJustReleased(wkA));
  FGame.Input.BeginFrame;
  Assert.IsFalse(FGame.Input.IsKeyJustReleased(wkA));
  Assert.IsFalse(FGame.Input.IsButtonJustReleased(wmbLeft));
end;

procedure TTestWarUiHost.DovrebbeNonSegnareUnaTransizioneSeLoStatoNonCambia;
begin
  FGame.Input.SetButton(wmbRight, False);
  Assert.IsFalse(FGame.Input.IsButtonJustReleased(wmbRight));
  FGame.Input.SetKey(wkB, True);
  FGame.Input.BeginFrame;
  FGame.Input.SetKey(wkB, True);
  Assert.IsFalse(FGame.Input.IsKeyJustPressed(wkB), 'il tasto gia'' premuto non e'' una novita''');
end;

procedure TTestWarUiHost.DovrebbeTroncareLaPosizioneDelMouseAlNumeroIntero;
begin
  FGame.Input.SetPosition(10.9, -0.5);
  Assert.AreEqual(10, RoundInt(FGame.Input.PositionX));
  Assert.AreEqual(-1, RoundInt(FGame.Input.PositionY));
end;

procedure TTestWarUiHost.DovrebbeAzzerareTuttoQuandoLaFinestraPerdeIlFuoco;
var
  LEvent: TGameHostEvent;
begin
  FGame.Input.SetButton(wmbLeft, True);
  FGame.Input.SetKey(wkA, True);
  LEvent := TGameHostEvent.Make(hekActive);
  LEvent.Focused := True;
  FAdapter.Post(LEvent);
  Assert.IsTrue(FGame.Input.IsKeyHeld(wkA), 'il fuoco c''e'': non cambia nulla');
  LEvent.Focused := False;
  FAdapter.Post(LEvent);
  Assert.IsFalse(FGame.Input.IsKeyHeld(wkA));
  Assert.IsFalse(FGame.Input.IsButtonHeld(wmbLeft));
  Assert.IsFalse(FGame.Input.IsButtonJustPressed(wmbLeft));
  FGame.Input.SetKey(wkA, True);
  LEvent.Focused := True;
  LEvent.Minimized := True;
  FAdapter.Post(LEvent);
  Assert.IsFalse(FGame.Input.IsKeyHeld(wkA), 'ridotta a icona');
end;

procedure TTestWarUiHost.DovrebbeTradurreIlMouseDellaFinestra;
begin
  FAdapter.Post(MouseEvent(hekMouseMotion, hmbNone, 40, 50));
  Assert.AreEqual(40, RoundInt(FGame.Input.PositionX));
  FAdapter.Post(MouseEvent(hekMouseDown, hmbLeft, 41, 51));
  Assert.IsTrue(FGame.Input.IsButtonJustPressed(wmbLeft));
  Assert.AreEqual(41, RoundInt(FGame.Input.PositionX), 'anche il clic porta la posizione');
  FAdapter.Post(MouseEvent(hekMouseUp, hmbLeft, 41, 51));
  Assert.IsTrue(FGame.Input.IsButtonJustReleased(wmbLeft));
  FAdapter.Post(MouseEvent(hekMouseDown, hmbRight, 1, 2));
  Assert.IsTrue(FGame.Input.IsButtonHeld(wmbRight));
end;

procedure TTestWarUiHost.DovrebbeIgnorareIlPulsanteCentraleEImovimentiDellaRotella;
begin
  FAdapter.Post(MouseEvent(hekMouseDown, hmbMiddle, 1, 2));
  Assert.IsFalse(FGame.Input.IsButtonHeld(wmbLeft));
  Assert.IsFalse(FGame.Input.IsButtonHeld(wmbRight));
  FAdapter.Post(TGameHostEvent.Make(hekMouseWheel));
  FAdapter.Post(TGameHostEvent.Make(hekResize));
  Assert.AreEqual(1, RoundInt(FGame.Input.PositionX), 'la posizione e'' quella del clic');
end;

procedure TTestWarUiHost.DovrebbeTradurreITastiVirtualiDiWindows;
begin
  Assert.AreEqual(Ord(wkSpace), Ord(TWarUiEventAdapter.VirtualKeyToKey($20)));
  Assert.AreEqual(Ord(wk5), Ord(TWarUiEventAdapter.VirtualKeyToKey($35)));
  Assert.AreEqual(Ord(wk5), Ord(TWarUiEventAdapter.VirtualKeyToKey($65)), 'tastierino');
  Assert.AreEqual(Ord(wkQ), Ord(TWarUiEventAdapter.VirtualKeyToKey($51)));
  Assert.AreEqual(Ord(wkF10), Ord(TWarUiEventAdapter.VirtualKeyToKey($79)));
  Assert.AreEqual(Ord(wkEnter), Ord(TWarUiEventAdapter.VirtualKeyToKey($0D)));
  Assert.AreEqual(Ord(wkEsc), Ord(TWarUiEventAdapter.VirtualKeyToKey($1B)));
  Assert.AreEqual(Ord(wkLeft), Ord(TWarUiEventAdapter.VirtualKeyToKey($25)));
  Assert.AreEqual(Ord(wkHome), Ord(TWarUiEventAdapter.VirtualKeyToKey($24)));
  Assert.AreEqual(Ord(wkEnd), Ord(TWarUiEventAdapter.VirtualKeyToKey($23)));
  Assert.AreEqual(Ord(wkPageUp), Ord(TWarUiEventAdapter.VirtualKeyToKey($21)));
  Assert.AreEqual(Ord(wkPageDown), Ord(TWarUiEventAdapter.VirtualKeyToKey($22)));
  Assert.AreEqual(Ord(wkInsert), Ord(TWarUiEventAdapter.VirtualKeyToKey($2D)));
  Assert.AreEqual(Ord(wkDelete), Ord(TWarUiEventAdapter.VirtualKeyToKey($2E)));
  Assert.AreEqual(Ord(wkAsterisk), Ord(TWarUiEventAdapter.VirtualKeyToKey($6A)));
  Assert.AreEqual(Ord(wkPlus), Ord(TWarUiEventAdapter.VirtualKeyToKey($6B)));
  Assert.AreEqual(Ord(wkMinus), Ord(TWarUiEventAdapter.VirtualKeyToKey($6D)));
  Assert.AreEqual(Ord(wkPeriod), Ord(TWarUiEventAdapter.VirtualKeyToKey($BE)));
  Assert.AreEqual(Ord(wkSlash), Ord(TWarUiEventAdapter.VirtualKeyToKey($BF)));
  Assert.AreEqual(Ord(wkComma), Ord(TWarUiEventAdapter.VirtualKeyToKey($BC)));
  Assert.AreEqual(Ord(wkApostrophe), Ord(TWarUiEventAdapter.VirtualKeyToKey($DE)));
  Assert.AreEqual(Ord(wkSemicolon), Ord(TWarUiEventAdapter.VirtualKeyToKey($BA)));
  Assert.AreEqual(Ord(wkEqual), Ord(TWarUiEventAdapter.VirtualKeyToKey($BB)));
  Assert.AreEqual(Ord(wkLeftBracket), Ord(TWarUiEventAdapter.VirtualKeyToKey($DB)));
  Assert.AreEqual(Ord(wkBackslash), Ord(TWarUiEventAdapter.VirtualKeyToKey($DC)));
  Assert.AreEqual(Ord(wkRightBracket), Ord(TWarUiEventAdapter.VirtualKeyToKey($DD)));
  Assert.AreEqual(Ord(wkGraveAccent), Ord(TWarUiEventAdapter.VirtualKeyToKey($C0)));
  Assert.AreEqual(Ord(wkTab), Ord(TWarUiEventAdapter.VirtualKeyToKey($09)));
  Assert.AreEqual(Ord(wkBackspace), Ord(TWarUiEventAdapter.VirtualKeyToKey($08)));
  Assert.AreEqual(Ord(wkRight), Ord(TWarUiEventAdapter.VirtualKeyToKey($27)));
  Assert.AreEqual(Ord(wkDown), Ord(TWarUiEventAdapter.VirtualKeyToKey($28)));
  Assert.AreEqual(Ord(wkUp), Ord(TWarUiEventAdapter.VirtualKeyToKey($26)));
end;

procedure TTestWarUiHost.DovrebbeLeggereShiftCtrlEAltDaiModificatoriEnonDalTasto;
begin
  // the key of Shift goes down but the modifiers say it is not held: it is not
  FAdapter.Post(KeyEvent(hekKeyDown, $10, 0, []));
  Assert.IsFalse(FGame.Input.IsKeyHeld(wkShift));
  FAdapter.Post(KeyEvent(hekKeyDown, $A0, 0, [hmShift]));
  Assert.IsTrue(FGame.Input.IsKeyHeld(wkShift));
  FAdapter.Post(KeyEvent(hekKeyDown, $11, 0, [hmControl]));
  Assert.IsTrue(FGame.Input.IsKeyHeld(wkCtrl));
  FAdapter.Post(KeyEvent(hekKeyDown, $12, 0, [hmAlt]));
  Assert.IsTrue(FGame.Input.IsKeyHeld(wkAlt));
  FAdapter.Post(KeyEvent(hekKeyUp, $11, 0, []));
  Assert.IsFalse(FGame.Input.IsKeyHeld(wkCtrl));
end;

procedure TTestWarUiHost.DovrebbeMandareIlCarattereDelTastoAlPannelloDeiTrucchi;
var
  LPanelText: AnsiString;
begin
  FGame.Manager.SetNextScene(FGame.Scenes.CreateMainMenu, 0);
  FGame.Manager.RunFrame(1 / 60);
  FGame.Input.BeginFrame;
  FAdapter.Post(KeyEvent(hekKeyDown, $0D, 0, []));
  FAdapter.Post(KeyEvent(hekKeyUp, $0D, 0, []));
  FGame.Manager.RunFrame(1 / 60);
  FAdapter.Post(KeyEvent(hekKeyDown, $41, Ord('a'), []));
  FAdapter.Post(KeyEvent(hekKeyDown, $0D, 13, []));
  FAdapter.Post(KeyEvent(hekKeyDown, $42, 200, []));
  LPanelText := (FGame.Manager.Scene as TWarSceneBase).CheatsPanel.Text;
  Assert.AreEqual<AnsiString>('a', LPanelText, 'solo i caratteri da 32 a 126');
end;

procedure TTestWarUiHost.DovrebbeChiedereLUscitaQuandoLaFinestraSiChiude;
begin
  FAdapter.Post(TGameHostEvent.Make(hekQuit));
  Assert.IsTrue(FGame.Manager.QuitRequested);
end;

procedure TTestWarUiHost.DovrebbeIgnorareUnTastoCheIlGiocoNonUsa;
begin
  FAdapter.Post(KeyEvent(hekKeyDown, $5B, 0, []));
  Assert.IsFalse(FGame.Input.IsKeyHeld(wkNone));
  Assert.AreEqual(Ord(wkNone), Ord(TWarUiEventAdapter.VirtualKeyToKey($5B)));
end;

procedure TTestWarUiHost.DovrebbeFareLoSpriteDiUnImmagineDiUnCursoreEDiUnoSpriteDelloArchivio;
var
  LCatalog: IWarCatalog;
  LLoader: IWarUiSprites;
  LSprite: IWarUiSprite;
begin
  LCatalog := TWarFactory.CreateCatalog;
  LLoader := TWarUiSpriteLoader.Create(TFakeGraphics.Create, LCatalog);
  LSprite := LLoader.CreateSprite(216);
  Assert.AreEqual(2, LSprite.FrameWidth);
  Assert.AreEqual(1, LSprite.FrameCount);
  Assert.AreEqual<Integer>(8, Length(LSprite.Texture.Pixels), 'un''immagine ha gia'' i pixel');
  Assert.AreEqual(1, Integer(LSprite.Texture.Pixels[0]));
  LSprite := LLoader.CreateSprite(263);
  Assert.AreEqual(1, LSprite.FrameWidth);
  Assert.AreEqual(8, Integer(LSprite.Texture.Pixels[0]), 'anche un cursore');
  LSprite := LLoader.CreateSprite(428);
  Assert.AreEqual(2, LSprite.FrameCount);
  Assert.AreEqual(0, Integer(LSprite.Texture.Pixels[0]), 'uno sprite parte vuoto');
  LSprite.UpdateImage(1);
  Assert.AreEqual(7, Integer(LSprite.Texture.Pixels[0]));
  Assert.AreEqual(0, LSprite.GetFrame(0).Dx);
end;

procedure TTestWarUiHost.DovrebbeRifiutareUnRecordCheNonESprite;
var
  LLoader: IWarUiSprites;
begin
  LLoader := TWarUiSpriteLoader.Create(TFakeGraphics.Create, TWarFactory.CreateCatalog);
  // the record 191 is a palette
  try
    LLoader.CreateSprite(191);
  except
    on E: EWarException do
      Exit;
  end;
  Assert.Fail('Un record che non e'' immagine, sprite o cursore non e'' uno sprite');
end;

procedure TTestWarUiHost.DovrebbeLeggereIlPuntoCaldoDiUnCursore;
var
  LLoader: IWarUiSprites;
  LX: Integer;
  LY: Integer;
begin
  LLoader := TWarUiSpriteLoader.Create(TFakeGraphics.Create, TWarFactory.CreateCatalog);
  LLoader.CursorHotspot(263, LX, LY);
  Assert.AreEqual(5, LX);
  Assert.AreEqual(6, LY);
end;

procedure TTestWarUiHost.DovrebbeLeggereUnPngDiUnFontComeRgba;
var
  LPixels: TBytes;
  LPng: TBytes;
  LClient: TPngClient;
  LImage: TWarImage;
begin
  // 2 x 1 pixels, B G R A: blue and half transparent red
  LPixels := [255, 0, 0, 255, 0, 0, 255, 128];
  LClient := TPngClient.Create(TPngEngine.Create(TZlibProvider.Zlib));
  try
    LPng := LClient.Encode(LPixels, 2, 1);
    LImage := TWarFontImageLoader.LoadBytes(LPng, LClient);
  finally
    LClient.Free;
  end;
  Assert.AreEqual(2, Integer(LImage.Width));
  Assert.AreEqual(1, Integer(LImage.Height));
  // R G B A
  Assert.AreEqual(0, Integer(LImage.Pixels[0]));
  Assert.AreEqual(255, Integer(LImage.Pixels[2]), 'il blu');
  Assert.AreEqual(255, Integer(LImage.Pixels[4]), 'il rosso');
  Assert.AreEqual(128, Integer(LImage.Pixels[7]), 'l''alfa resta com''e''');
end;

procedure TTestWarUiHost.DovrebbeFareUnaTexturaVuotaFinoAlPrimoAggiornamentoDiUnoSprite;
var
  LSprites: IWarUiSprites;
  LSprite: IWarUiSprite;
begin
  LSprites := TFakeUiSprites.Create;
  LSprite := LSprites.CreateSprite(1000);
  Assert.AreEqual<Integer>(16 * 16 * 4, Length(LSprite.Texture.Pixels));
  Assert.AreEqual(0, Integer(LSprite.Texture.Pixels[3]));
  Assert.AreEqual(3, LSprite.FrameCount);
  try
    LSprite.UpdateImage(3);
  except
    on E: EWarException do
      Exit;
  end;
  Assert.Fail('Un fotogramma che non c''e'' non si carica');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestWarUiHost);

end.
