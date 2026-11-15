{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the immediate interface              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.UiImui;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.War.Ui.Types, DelphiDoom.War.Ui.Intf, DelphiDoom.War.Ui.Game,
  DelphiDoom.Tests.War.UiFakes;

type
  /// <summary>
  ///   imui on a fake of the sprites (solid colors): the state, the buttons, the hotkeys, the tooltip, the cursor and the
  ///   defects of the sprite cache of the original that are kept
  /// </summary>
  [TestFixture]
  [Category('war')]
  TTestWarUiImui = class(TObject)
  private
    FSprites: TFakeUiSprites;
    FSpritesRef: IWarUiSprites;
    FAudio: TFakeAudio;
    FAudioRef: IWarSceneAudio;
    FGame: TWarUiGame;
    function Pixel(AX, AY, AChannel: Integer): Integer;
    function MaxRed(AX, AY, AWidth, AHeight: Integer): Integer;
    procedure Frame(const AAction: TProc);
    function Button(AX, AY: Single; ANormal, APressed: Integer): TWarUiImageButtonArgs;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareLoStessoNumeroDiUnIdACaratteriDiversiELoStessoPerLoStessoId;
    [Test]
    procedure DovrebbeUsareIlFnv1aDellIdCome;
    [Test]
    procedure DovrebbeDisegnareUnImmagineAllaPosizioneEScalarla;
    [Test]
    procedure DovrebbeNonDisegnareUnImmagineDiUnRecordNonValido;
    [Test]
    procedure DovrebbeDisegnareUnFotogrammaDiUnoSpriteConIlSuoSpostamento;
    [Test]
    procedure DovrebbeDisegnareUnRettangoloEIlTesto;
    [Test]
    procedure DovrebbeRifiutareUnFontCheNonEsiste;
    [Test]
    procedure DovrebbeFarScattareUnBottoneAlRilascioSuDiLui;
    [Test]
    procedure DovrebbeNonFarScattareUnBottoneRilasciatoFuoriDaLui;
    [Test]
    procedure DovrebbeFarScattareUnBottoneConIlTastoRapidoSenzaSuono;
    [Test]
    procedure DovrebbeIgnorareIlTastoRapidoSeSpento;
    [Test]
    procedure DovrebbeDisegnareLoSfondoPremutoSoloMentreIlTastoELTenutoSuDiLui;
    [Test]
    procedure DovrebbeCentrareLIconaDelBottoneEAbbassarlaSeESPremuto;
    [Test]
    procedure DovrebbeUsareLaMisuraPredefinitaSenzaSfondo;
    [Test]
    procedure DovrebbeNonFareNullaPerUnBottoneNonInterattivo;
    [Test]
    procedure DovrebbeEvidenziareTuttaLEtichettaDelBottoneDiTestoSottoIlMouse;
    [Test]
    procedure DovrebbeTagliareIlTooltipA255CaratteriEDisegnarloSoloConUnaMappa;
    [Test]
    procedure DovrebbeDisegnareIlCostoDelTooltipConLeIcone;
    [Test]
    procedure DovrebbeDisegnareIlCursoreAlPuntoDelMouseMenoIlPuntoCaldo;
    [Test]
    procedure DovrebbeAzzerareLOggettoAttivoQuandoIlTastoSinistroESu;
    [Test]
    procedure DovrebbeTenereLoSpriteDellaCacheEControllareTuttiGliSpriteDiversi;
    [Test]
    procedure DovrebbeSostituireIlPrimoSpriteConIlNumeroPiuPiccoloQuandoLaCacheEPiena;
  end;

implementation

uses
  DelphiDoom.War.Render.Types, DelphiDoom.War.Text.Types, DelphiDoom.War.Types, DelphiDoom.War.Ui.Imui,
  DelphiDoom.War.Ui.Input;

{ TTestWarUiImui }

procedure TTestWarUiImui.Setup;
begin
  FSprites := TFakeUiSprites.Create;
  FSpritesRef := FSprites;
  FAudio := TFakeAudio.Create;
  FAudioRef := FAudio;
  FGame := TFakeUiRig.CreateGame(FSpritesRef, FAudioRef, nil, False);
  // the cursor away from what the tests look at (it is drawn last, over everything)
  FGame.Input.SetPosition(300, 190);
end;

procedure TTestWarUiImui.TearDown;
begin
  FreeAndNil(FGame);
  FAudioRef := nil;
  FSpritesRef := nil;
end;

function TTestWarUiImui.Pixel(AX, AY, AChannel: Integer): Integer;
begin
  Result := FGame.Canvas.Blitter.Pixels[(AY * 320 + AX) * 4 + AChannel];
end;

procedure TTestWarUiImui.Frame(const AAction: TProc);
begin
  FGame.Canvas.Clear;
  FGame.Canvas.ResetTransform;
  FGame.Imui.Start;
  AAction;
  FGame.Imui.Finish;
  FGame.Input.BeginFrame;
end;

function TTestWarUiImui.Button(AX, AY: Single; ANormal, APressed: Integer): TWarUiImageButtonArgs;
begin
  Result := TWarUiImageButtonArgs.Default;
  Result.PositionX := AX;
  Result.PositionY := AY;
  Result.BackgroundNormal := ANormal;
  Result.BackgroundPressed := APressed;
end;

procedure TTestWarUiImui.DovrebbeDareLoStessoNumeroDiUnIdACaratteriDiversiELoStessoPerLoStessoId;
begin
  Assert.AreEqual<Cardinal>(TWarImui.HashId('abc'), TWarImui.HashId('abc'));
  Assert.AreNotEqual<Cardinal>(TWarImui.HashId('abc'), TWarImui.HashId('abd'));
end;

procedure TTestWarUiImui.DovrebbeUsareIlFnv1aDellIdCome;
begin
  // FNV-1a of the empty string is the basis; of "a" the known value
  Assert.AreEqual<Cardinal>(2166136261, TWarImui.HashId(''));
  Assert.AreEqual<Cardinal>($E40C292C, TWarImui.HashId('a'));
end;

procedure TTestWarUiImui.DovrebbeDisegnareUnImmagineAllaPosizioneEScalarla;
var
  LArgs: TWarUiImageArgs;
begin
  LArgs := TWarUiImageArgs.Default;
  LArgs.SpriteRef := 5;
  LArgs.PositionX := 10;
  LArgs.PositionY := 20;
  LArgs.ScaleX := 2;
  LArgs.ScaleY := 2;
  Frame(procedure
    begin
      FGame.Imui.Image('img', LArgs);
    end);
  // 16 x 16 scaled by 2 from (10, 20): the position is translated before the scale
  Assert.AreEqual(5, Pixel(10, 20, 0), 'il primo pixel');
  Assert.AreEqual(5, Pixel(41, 51, 0), 'l''ultimo');
  Assert.AreEqual(0, Pixel(42, 52, 0), 'fuori');
end;

procedure TTestWarUiImui.DovrebbeNonDisegnareUnImmagineDiUnRecordNonValido;
var
  LArgs: TWarUiImageArgs;
begin
  LArgs := TWarUiImageArgs.Default;
  Frame(procedure
    begin
      FGame.Imui.Image('img', LArgs);
    end);
  Assert.AreEqual(0, FSprites.Created.Count - 1, 'solo il cursore');
end;

procedure TTestWarUiImui.DovrebbeDisegnareUnFotogrammaDiUnoSpriteConIlSuoSpostamento;
var
  LArgs: TWarUiImageArgs;
begin
  LArgs := TWarUiImageArgs.Default;
  LArgs.SpriteRef := 1000;
  LArgs.PositionX := 30;
  LArgs.PositionY := 30;
  Frame(procedure
    begin
      // the frame 2 has dx 4 and dy 2: the image goes 4 left and 2 up
      FGame.Imui.ImageFrame('f', LArgs, 2);
    end);
  Assert.AreEqual((1000 + 80) and 255, Pixel(26, 28, 0));
  Assert.AreEqual(0, Pixel(25, 28, 0));
  Assert.WillRaise(
    procedure
    begin
      Frame(procedure
        begin
          FGame.Imui.ImageFrame('f', LArgs, 3);
        end);
    end, EWarException);
end;

procedure TTestWarUiImui.DovrebbeDisegnareUnRettangoloEIlTesto;
var
  LRect: TWarUiRectArgs;
  LText: TWarUiTextArgs;
begin
  LRect := TWarUiRectArgs.Default;
  LRect.PositionX := 100;
  LRect.PositionY := 100;
  LRect.SizeX := 10;
  LRect.SizeY := 5;
  LRect.Color := WAR_COLOR_WHITE;
  LText := TWarUiTextArgs.Default;
  LText.Text := 'Hi';
  LText.FontIndex := 1;
  Frame(procedure
    begin
      FGame.Imui.Rect('r', LRect);
      FGame.Imui.Text('t', LText);
      LText.Multiline := True;
      LText.BoundingsX := 100;
      LText.BoundingsY := 50;
      FGame.Imui.Text('t2', LText);
    end);
  Assert.AreEqual(255, Pixel(100, 100, 0));
  Assert.AreEqual(255, Pixel(109, 104, 0));
  Assert.AreEqual(0, Pixel(110, 100, 0));
  // the text of the font (white and opaque in the fake) is at the top left, tinted by the color of the text
  Assert.AreEqual(Integer(WAR_FONT_NORMAL_COLOR.R), MaxRed(0, 0, 24, 12), 'il colore del testo');
end;

function TTestWarUiImui.MaxRed(AX, AY, AWidth, AHeight: Integer): Integer;
var
  LX: Integer;
  LY: Integer;
begin
  Result := 0;
  for LY := AY to AY + AHeight - 1 do
    for LX := AX to AX + AWidth - 1 do
      if Pixel(LX, LY, 0) > Result then
        Result := Pixel(LX, LY, 0);
end;

procedure TTestWarUiImui.DovrebbeRifiutareUnFontCheNonEsiste;
var
  LText: TWarUiTextArgs;
begin
  LText := TWarUiTextArgs.Default;
  LText.Text := 'x';
  LText.FontIndex := 2;
  Assert.WillRaise(
    procedure
    begin
      Frame(procedure
        begin
          FGame.Imui.Text('t', LText);
        end);
    end, EWarException);
end;

procedure TTestWarUiImui.DovrebbeFarScattareUnBottoneAlRilascioSuDiLui;
var
  LClicked: Boolean;
begin
  LClicked := False;
  FGame.Input.SetPosition(5, 5);
  FGame.Input.SetButton(wmbLeft, True);
  Frame(procedure
    begin
      LClicked := FGame.Imui.ImageButton('b', Button(0, 0, 7, 8));
    end);
  Assert.IsFalse(LClicked, 'premuto: non ancora');
  Assert.AreEqual<Cardinal>(TWarImui.HashId('b'), FGame.Imui.ActiveItem);
  FGame.Input.SetButton(wmbLeft, False);
  Frame(procedure
    begin
      LClicked := FGame.Imui.ImageButton('b', Button(0, 0, 7, 8));
    end);
  Assert.IsTrue(LClicked, 'rilasciato');
  Assert.AreEqual(1, FAudio.Played.Count);
  Assert.AreEqual(WAR_AUDIO_UI_CLICK, FAudio.Played[0]);
  Assert.AreEqual<Cardinal>(0, FGame.Imui.ActiveItem, 'azzerato con il tasto su');
end;

procedure TTestWarUiImui.DovrebbeNonFarScattareUnBottoneRilasciatoFuoriDaLui;
var
  LClicked: Boolean;
begin
  LClicked := False;
  FGame.Input.SetPosition(5, 5);
  FGame.Input.SetButton(wmbLeft, True);
  Frame(procedure
    begin
      FGame.Imui.ImageButton('b', Button(0, 0, 7, 8));
    end);
  FGame.Input.SetPosition(100, 100);
  FGame.Input.SetButton(wmbLeft, False);
  Frame(procedure
    begin
      LClicked := FGame.Imui.ImageButton('b', Button(0, 0, 7, 8));
    end);
  Assert.IsFalse(LClicked);
  Assert.AreEqual(0, FAudio.Played.Count);
end;

procedure TTestWarUiImui.DovrebbeFarScattareUnBottoneConIlTastoRapidoSenzaSuono;
var
  LClicked: Boolean;
  LArgs: TWarUiImageButtonArgs;
begin
  LClicked := False;
  LArgs := Button(0, 0, 7, 8);
  LArgs.HotKey := wkQ;
  FGame.Input.SetPosition(200, 150);
  FGame.Input.SetKey(wkQ, True);
  FGame.Input.SetKey(wkQ, False);
  Frame(procedure
    begin
      LClicked := FGame.Imui.ImageButton('b', LArgs);
    end);
  Assert.IsTrue(LClicked);
  Assert.AreEqual(0, FAudio.Played.Count, 'il tasto rapido non fa il suono');
end;

procedure TTestWarUiImui.DovrebbeIgnorareIlTastoRapidoSeSpento;
var
  LClicked: Boolean;
  LArgs: TWarUiImageButtonArgs;
begin
  LClicked := True;
  LArgs := Button(0, 0, 7, 8);
  LArgs.HotKey := wkQ;
  FGame.Input.SetKey(wkQ, True);
  FGame.Input.SetKey(wkQ, False);
  Frame(procedure
    begin
      FGame.Imui.HotkeysEnabled := False;
      LClicked := FGame.Imui.ImageButton('b', LArgs);
    end);
  Assert.IsFalse(LClicked);
end;

procedure TTestWarUiImui.DovrebbeDisegnareLoSfondoPremutoSoloMentreIlTastoELTenutoSuDiLui;
begin
  FGame.Input.SetPosition(5, 5);
  FGame.Input.SetButton(wmbLeft, True);
  Frame(procedure
    begin
      FGame.Imui.ImageButton('b', Button(0, 0, 7, 8));
    end);
  // the cursor (at 2, 1) covers the rest: the pixel looked at is to its left
  Assert.AreEqual(8, Pixel(1, 12, 0), 'premuto');
  FGame.Input.SetPosition(100, 100);
  Frame(procedure
    begin
      FGame.Imui.ImageButton('b', Button(0, 0, 7, 8));
    end);
  Assert.AreEqual(7, Pixel(1, 12, 0), 'tenuto ma fuori: normale');
end;

procedure TTestWarUiImui.DovrebbeCentrareLIconaDelBottoneEAbbassarlaSeESPremuto;
var
  LArgs: TWarUiImageButtonArgs;
begin
  FSprites.SetSize(1001, 4, 4);
  LArgs := Button(0, 0, 7, 8);
  LArgs.Foreground := 1001;
  LArgs.ForegroundFrameIndex := 1;
  Frame(procedure
    begin
      FGame.Imui.ImageButton('b', LArgs);
    end);
  // 16 x 16 button, 4 x 4 icon: at (6, 6)
  Assert.AreEqual((1001 + 40) and 255, Pixel(6, 6, 0));
  Assert.AreEqual(7, Pixel(5, 6, 0));
  FGame.Input.SetPosition(15, 15);
  FGame.Input.SetButton(wmbLeft, True);
  Frame(procedure
    begin
      FGame.Imui.ImageButton('b', LArgs);
    end);
  Assert.AreEqual((1001 + 40) and 255, Pixel(6, 7, 0), 'una riga piu'' in basso');
  Assert.AreEqual(8, Pixel(6, 6, 0), 'e lo sfondo e'' quello premuto');
end;

procedure TTestWarUiImui.DovrebbeUsareLaMisuraPredefinitaSenzaSfondo;
var
  LArgs: TWarUiImageButtonArgs;
  LText: TWarUiTextButtonArgs;
  LClicked: Boolean;
begin
  LArgs := TWarUiImageButtonArgs.Default;
  LText := TWarUiTextButtonArgs.Default;
  FGame.Input.SetPosition(15, 15);
  FGame.Input.SetButton(wmbLeft, True);
  Frame(procedure
    begin
      FGame.Imui.ImageButton('i', LArgs);
    end);
  FGame.Input.SetButton(wmbLeft, False);
  Frame(procedure
    begin
      LClicked := FGame.Imui.ImageButton('i', LArgs);
    end);
  // without a background the image button is 16 x 16 and the text button 64 x 16
  Assert.IsTrue(LClicked);
  FGame.Input.SetPosition(60, 10);
  FGame.Input.SetButton(wmbLeft, True);
  Frame(procedure
    begin
      FGame.Imui.TextButton('t', LText);
    end);
  FGame.Input.SetButton(wmbLeft, False);
  Frame(procedure
    begin
      LClicked := FGame.Imui.TextButton('t', LText);
    end);
  Assert.IsTrue(LClicked);
end;

procedure TTestWarUiImui.DovrebbeNonFareNullaPerUnBottoneNonInterattivo;
var
  LImage: TWarUiImageButtonArgs;
  LText: TWarUiTextButtonArgs;
begin
  LImage := Button(0, 0, 7, 8);
  LImage.Interactive := False;
  LText := TWarUiTextButtonArgs.Default;
  LText.Interactive := False;
  Frame(procedure
    begin
      Assert.IsFalse(FGame.Imui.ImageButton('i', LImage));
      Assert.IsFalse(FGame.Imui.TextButton('t', LText));
    end);
  Assert.AreEqual(0, Pixel(2, 2, 0));
  Assert.AreEqual(0, Pixel(8, 8, 0));
end;

procedure TTestWarUiImui.DovrebbeEvidenziareTuttaLEtichettaDelBottoneDiTestoSottoIlMouse;
var
  LArgs: TWarUiTextButtonArgs;
  LNormal: Integer;
  LHot: Integer;
begin
  LArgs := TWarUiTextButtonArgs.Default;
  LArgs.Text := 'Ok';
  LArgs.FontIndex := 1;
  LArgs.BackgroundNormal := 7;
  LArgs.BackgroundPressed := 8;
  FGame.Input.SetPosition(300, 190);
  Frame(procedure
    begin
      FGame.Imui.TextButton('t', LArgs);
    end);
  LNormal := Pixel(4, 3, 2);
  FGame.Input.SetPosition(3, 3);
  Frame(procedure
    begin
      FGame.Imui.TextButton('t', LArgs);
    end);
  LHot := Pixel(4, 3, 2);
  // the glyph is white in the fake: the tint is the color of the text, the normal one and the highlight one differ
  Assert.IsTrue(LNormal <> LHot, 'il colore del testo cambia sotto il mouse');
end;

procedure TTestWarUiImui.DovrebbeTagliareIlTooltipA255CaratteriEDisegnarloSoloConUnaMappa;
var
  LArgs: TWarUiImageButtonArgs;
  LText: AnsiString;
begin
  LText := AnsiString(StringOfChar('a', 300));
  LArgs := Button(0, 0, 7, 8);
  LArgs.Tooltip := LText;
  FGame.Input.SetPosition(2, 2);
  Frame(procedure
    begin
      FGame.Imui.ImageButton('b', LArgs);
      Assert.IsTrue(FGame.Imui.ShowTooltip);
      Assert.AreEqual(255, Length(FGame.Imui.TooltipText));
    end);
  Assert.AreEqual(0, Pixel(75, 194, 0), 'senza mappa non si disegna');
  FGame.Imui.SetMapPanel(True, 0, 188);
  Frame(procedure
    begin
      FGame.Imui.ImageButton('b', LArgs);
    end);
  Assert.IsTrue(Pixel(75, 195, 0) <> 0, 'con la mappa il testo e'' alla barra di stato');
end;

procedure TTestWarUiImui.DovrebbeDisegnareIlCostoDelTooltipConLeIcone;
var
  LArgs: TWarUiTextButtonArgs;
begin
  FSprites.SetSize(406, 4, 4);
  FSprites.SetSize(407, 4, 4);
  LArgs := TWarUiTextButtonArgs.Default;
  LArgs.BackgroundNormal := 7;
  LArgs.Tooltip := 'Build';
  LArgs.Gold := 100;
  LArgs.Wood := 50;
  FGame.Imui.SetMapPanel(True, 0, 150);
  FGame.Input.SetPosition(2, 2);
  Frame(procedure
    begin
      FGame.Imui.TextButton('b', LArgs);
    end);
  // the wood icon at (163, 3) and the gold one at (200, 5) of the panel
  Assert.AreEqual(406 and 255, Pixel(200, 155, 0), 'oro');
  Assert.AreEqual(407 and 255, Pixel(163, 153, 0), 'legno');
end;

procedure TTestWarUiImui.DovrebbeDisegnareIlCursoreAlPuntoDelMouseMenoIlPuntoCaldo;
begin
  FGame.Input.SetPosition(50, 60);
  Frame(procedure
    begin
      FGame.Imui.ChangeCursorType(300);
    end);
  Assert.AreEqual(300, FGame.Imui.CursorType);
  // the cursor 300 (16 x 16) goes at (50 - 3, 60 - 4)
  Assert.AreEqual(300 and 255, Pixel(47, 56, 0));
  Assert.AreEqual(0, Pixel(46, 56, 0));
  Frame(procedure
    begin
    end);
  Assert.AreEqual(WAR_CURSOR_ARROW, FGame.Imui.CursorType, 'Start rimette la freccia');
  Assert.AreEqual(263 and 255, Pixel(47, 56, 0));
end;

procedure TTestWarUiImui.DovrebbeAzzerareLOggettoAttivoQuandoIlTastoSinistroESu;
begin
  FGame.Input.SetPosition(2, 2);
  FGame.Input.SetButton(wmbLeft, True);
  Frame(procedure
    begin
      FGame.Imui.ImageButton('b', Button(0, 0, 7, 8));
    end);
  Assert.AreNotEqual<Cardinal>(0, FGame.Imui.ActiveItem);
  Assert.AreEqual<Cardinal>(TWarImui.HashId('b'), FGame.Imui.HotItem);
  Assert.IsTrue(FGame.Imui.IsMouseOverUi);
  FGame.Input.SetButton(wmbLeft, False);
  Frame(procedure
    begin
    end);
  Assert.AreEqual<Cardinal>(0, FGame.Imui.ActiveItem);
  Assert.IsFalse(FGame.Imui.IsMouseOverUi);
end;

procedure TTestWarUiImui.DovrebbeTenereLoSpriteDellaCacheEControllareTuttiGliSpriteDiversi;
var
  LCount: Integer;
begin
  Frame(procedure
    begin
      FGame.Imui.Image('a', TWarUiImageArgs.Default);
    end);
  LCount := FSprites.Created.Count;
  Frame(procedure
    var
      LArgs: TWarUiImageArgs;
    begin
      LArgs := TWarUiImageArgs.Default;
      LArgs.SpriteRef := 5;
      FGame.Imui.Image('a', LArgs);
      FGame.Imui.Image('a', LArgs);
    end);
  Assert.AreEqual(LCount + 1, FSprites.Created.Count, 'il record 5 una volta sola, anche in piu'' fotogrammi');
  Assert.AreEqual(2, FGame.Imui.SpriteCache.Count, 'il cursore e il record 5');
end;

procedure TTestWarUiImui.DovrebbeSostituireIlPrimoSpriteConIlNumeroPiuPiccoloQuandoLaCacheEPiena;
var
  LIndex: Integer;
  LArgs: TWarUiImageArgs;
begin
  FGame.Imui.GameFrame := 9;
  Frame(procedure
    begin
    end);
  for LIndex := 0 to 70 do
  begin
    LArgs := TWarUiImageArgs.Default;
    LArgs.SpriteRef := LIndex + 10;
    Frame(procedure
      begin
        FGame.Imui.Image('a', LArgs);
      end);
  end;
  Assert.AreEqual(64, FGame.Imui.SpriteCache.Count);
  // 1 (the cursor) + 63 images fill it; the next 8 evict. A hit does not update lastUsedFrame, so the first entry (the
  // cursor) goes first and it must be made again by the next imui_end, that evicts another one: more than 8 evictions
  Assert.IsTrue(FGame.Imui.SpriteCache.Evictions > 8);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestWarUiImui);

end.
