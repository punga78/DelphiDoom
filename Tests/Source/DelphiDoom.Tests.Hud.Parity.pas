{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the heads-up display library - parity with the old code}
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Hud.Parity;

// The old code (DelphiDoom.Tests.Hud.Legacy, a copy of hu_lib.pas and hu_stuff.pas at commit
// 138347fd) and the new one run in the same program on the same random inputs; after every
// step the whole state is compared. A difference stops the test and says the seed and the step.

interface

uses
  DUnitX.TestFramework, DelphiDoom.Hud.Types, DelphiDoom.Hud.Intf, DelphiDoom.Hud.View,
  DelphiDoom.Hud.HeadsUp, DelphiDoom.Tests.Hud.Fakes;

type
  [TestFixture]
  [Category('hud')]
  TTestHudParity = class(TObject)
  private
    FWorld: TFakeHudWorld;
    FWorldRef: IInterface;
    FHeadsUpRef: IHeadsUp;
    FView: IHudView;
    FHeadsUp: THeadsUp;
    procedure MakeWorlds(const AFrench: Boolean);
    function LegacyText(const ALine: Pointer): string;
    function LegacyStext: string;
    function NewStext: string;
    function LegacySnapshot: string;
    function NewSnapshot: string;
    function NewParams(const ATitle: string): THudStartParams;
    procedure StartBoth(const ATitle: string);
    procedure Stimulus(var AKeyLog: string);
    procedure RunScenario(const ASeed: Integer; const ASteps: Integer);
    procedure FontWidths(const AFont: array of Pointer; out AWidths: THudFontWidths);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeSeguireIlVecchioCodiceInDuecentoScenariCasuali;
    [Test]
    procedure DovrebbeDareLeStesseTabelleDiTasti;
    [Test]
    procedure DovrebbeTradurreITastiComeIlVecchioCodice;
    [Test]
    procedure DovrebbeContareGliFotogrammiAlSecondoComeIlVecchioCodice;
    [Test]
    procedure DovrebbeScrivereGliStessiGlifiDelleLinee;
    [Test]
    procedure DovrebbeScrivereGliStessiGlifiDelTestoACapo;
    [Test]
    procedure DovrebbeScrivereGliStessiGlifiDelTestoDelleStatistiche;
    [Test]
    procedure DovrebbeSeguireLaFinestraDiTestoDelVecchioCodice;
    [Test]
    procedure DovrebbeScegliereGliStessiTitoli;
    [Test]
    procedure DovrebbeScegliereLoStessoMirino;
    [Test]
    procedure DovrebbeScrivereLoStessoTempoDelLivello;
  end;

implementation

uses
  System.SysUtils, d_delphi, DelphiDoom.Hud.TextLine, DelphiDoom.Hud.ScrollingText,
  DelphiDoom.Hud.Layout, DelphiDoom.Hud.TextLayout, DelphiDoom.Hud.KeyTables,
  DelphiDoom.Hud.MapTitle, DelphiDoom.Hud.Crosshair, DelphiDoom.Hud.LevelTime,
  DelphiDoom.Hud.FpsCounter, DelphiDoom.Hud.Factory, DelphiDoom.Hud.MessageBar,
  DelphiDoom.Hud.Chat, DelphiDoom.Tests.Hud.Legacy;

{ TTestHudParity }

procedure TTestHudParity.Setup;
begin
  Legacy_MakeFonts([6, 5, 8, 4, 7, 9, 3]);
end;

procedure TTestHudParity.TearDown;
begin
  FHeadsUp := nil;
  FView := nil;
  FHeadsUpRef := nil;
  FWorldRef := nil;
end;

procedure TTestHudParity.MakeWorlds(const AFrench: Boolean);
var
  LIndex: Integer;
begin
  // the new code
  FHeadsUp := nil;
  FView := nil;
  FHeadsUpRef := nil;
  FWorldRef := nil;
  FWorld := TFakeHudWorld.Create;
  FWorldRef := FWorld;
  THudFactory.CreateHeadsUp(DoomHudRules, FWorld, FWorld, FWorld, FWorld, FWorld, FWorld, FHeadsUpRef, FView);
  FHeadsUp := FHeadsUpRef as THeadsUp;
  FWorld.TalkToSelf[1] := HUSTR_TALKTOSELF1;
  FWorld.TalkToSelf[2] := HUSTR_TALKTOSELF2;
  FWorld.TalkToSelf[3] := HUSTR_TALKTOSELF3;
  FWorld.TalkToSelf[4] := HUSTR_TALKTOSELF4;
  FWorld.TalkToSelf[5] := HUSTR_TALKTOSELF5;
  FWorld.QueueFull := HUSTR_MSGU;
  FWorld.French := AFrench;
  // the old code: the same world
  if AFrench then
    language := french
  else
    language := english;
  netgame := False;
  consoleplayer := 0;
  gamemode := commercial;
  showMessages := 1;
  for LIndex := 0 to MAXPLAYERS - 1 do
  begin
    playeringame[LIndex] := False;
    chat_dest[LIndex] := #0;
    players[LIndex]._message := '';
    players[LIndex].cmd.chatchar := 0;
    destination_keys[LIndex] := FWorld.DestinationKeys[LIndex];
    player_names[LIndex] := FWorld.Names[LIndex];
  end;
  for LIndex := 0 to 9 do
    chat_macros[LIndex] := FWorld.Macros[LIndex];
  plr := nil;
  chat_on := False;
  message_on := False;
  message_dontfuckwithme := False;
  message_nottobefuckedwith := False;
  message_counter := 0;
  m_fps := '';
  fps_ticker := 0;
  LegacyDrawLog := '';
  LegacyEchoLog := '';
  LegacySounds := '';
  LegacyFracTime := 0;
  Legacy_ResetState;
  Legacy_Init;
  FHeadsUp.Initialize;
end;

function TTestHudParity.NewParams(const ATitle: string): THudStartParams;
begin
  Result.MessageX := HU_MSGX;
  Result.MessageY := HU_MSGY;
  Result.MessageHeight := HU_MSGHEIGHT;
  Result.LineHeight := hu_font[0].height + 1;
  Result.StartChar := Ord(HU_FONTSTART);
  Result.TitleX := 0;
  Result.TitleY := 167 - hu_font[0].height;
  Result.LevelTimeX := 0;
  Result.LevelTimeY := 167 - 2 * hu_font[0].height;
  Result.InputX := HU_MSGX;
  Result.InputY := HU_MSGY + HU_MSGHEIGHT * (hu_font[0].height + 1);
  Result.Title := ATitle;
end;

procedure TTestHudParity.StartBoth(const ATitle: string);
begin
  Legacy_Start(ATitle);
  FHeadsUp.Start(NewParams(ATitle));
end;

function TTestHudParity.LegacyText(const ALine: Pointer): string;
var
  LLine: Phu_textline_t;
  LIndex: Integer;
begin
  LLine := ALine;
  Result := IntToStr(LLine.len) + '[';
  for LIndex := 0 to LLine.len - 1 do
    Result := Result + Char(Ord(LLine.line[LIndex]));
  Result := Result + ']' + IntToStr(LLine.needsupdate);
end;

function TTestHudParity.LegacyStext: string;
var
  LIndex: Integer;
begin
  Result := IntToStr(w_message.height) + '/' + IntToStr(w_message.curline) + ':';
  for LIndex := 0 to w_message.height - 1 do
    Result := Result + LegacyText(@w_message.lines[LIndex]) + ';';
end;

function NewLine(const ALine: THudTextLine): string;
var
  LIndex: Integer;
begin
  Result := IntToStr(ALine.Length) + '[';
  for LIndex := 0 to ALine.Length - 1 do
    Result := Result + Char(Ord(ALine.CharAt(LIndex)));
  Result := Result + ']' + IntToStr(ALine.NeedsUpdate);
end;

function NewWindow(const AWindow: THudScrollingText): string;
var
  LIndex: Integer;
begin
  Result := IntToStr(AWindow.Height) + '/' + IntToStr(AWindow.CurrentLine) + ':';
  for LIndex := 0 to AWindow.Height - 1 do
    Result := Result + NewLine(AWindow.Lines[LIndex]) + ';';
end;

function TTestHudParity.NewStext: string;
begin
  Result := NewWindow(FView.MessageWindow);
end;

function TTestHudParity.LegacySnapshot: string;
var
  LIndex: Integer;
begin
  Result := Format('chat=%d msg=%d forced=%d locked=%d counter=%d|', [Ord(chat_on), Ord(message_on),
    Ord(message_dontfuckwithme), Ord(message_nottobefuckedwith), message_counter]);
  Result := Result + 'pm=' + players[consoleplayer]._message + '|' + LegacyStext + '|chat:' +
    LegacyText(@w_chat.line) + '|';
  for LIndex := 0 to MAXPLAYERS - 1 do
    Result := Result + 'b' + IntToStr(LIndex) + '=' + LegacyText(@w_inputbuffer[LIndex].line) + ',' +
      IntToStr(Ord(chat_dest[LIndex])) + ';';
  Result := Result + '|snd=' + LegacySounds + '|echo=' + LegacyEchoLog + '|fps=' + m_fps;
end;

function TTestHudParity.NewSnapshot: string;
var
  LIndex: Integer;
  LSounds: string;
begin
  Result := Format('chat=%d msg=%d forced=%d locked=%d counter=%d|', [Ord(FWorld.ChatOn),
    Ord(FHeadsUp.Bar.Visible), Ord(FWorld.MessageForced), Ord(FHeadsUp.Bar.Locked),
    FHeadsUp.Bar.Counter]);
  Result := Result + 'pm=' + FWorld.PlayerMessage + '|' + NewStext + '|chat:' +
    NewLine(FView.ChatLine.Line) + '|';
  for LIndex := 0 to MAXPLAYERS - 1 do
    Result := Result + 'b' + IntToStr(LIndex) + '=' + NewLine(FHeadsUp.Chat.Buffer(LIndex).Line) + ',' +
      IntToStr(FHeadsUp.Chat.Destination(LIndex)) + ';';
  // the old log writes the number of the sound of Doom 2 (radio, 1) for each sound
  LSounds := '';
  for LIndex := 1 to FWorld.Sounds do
    LSounds := LSounds + '1;';
  Result := Result + '|snd=' + LSounds + '|echo=' + FWorld.EchoLog + '|fps=' + FView.FpsText;
end;

procedure TTestHudParity.Stimulus(var AKeyLog: string);
const
  KEYS: array[0..31] of Integer = (Ord('t'), 13, 27, 127, Ord('a'), Ord('b'), Ord('c'), Ord('d'),
    Ord('h'), Ord('E'), Ord('z'), Ord('1'), Ord('0'), Ord('9'), Ord(','), Ord(';'), Ord(' '), Ord('_'),
    Ord('{'), Ord('A'), Ord('q'), Ord('m'), Ord('w'), Ord('5'), $B6, $B8, $B6, $B8, 1, 5, 50, 100);
var
  LKey: Integer;
  LDown: Boolean;
  LText: string;
  LEvent: Tevent_t;
  LLegacyResult: Boolean;
  LNewResult: Boolean;
  LIndex: Integer;
  LValue: Integer;
begin
  case Random(14) of
    0, 1, 2, 3:
    begin
      // a tic (the most common)
      HU_Ticker;
      FHeadsUp.Ticker;
    end;
    4, 5, 6, 7:
    begin
      LKey := KEYS[Random(Length(KEYS))];
      LDown := Random(5) > 0;
      if LDown then
        LEvent._type := ev_keydown
      else
        LEvent._type := ev_keyup;
      LEvent.data1 := LKey;
      LLegacyResult := HU_Responder(@LEvent);
      LNewResult := FHeadsUp.Responder(LKey, LDown);
      AKeyLog := AKeyLog + Format('[%d,%d:%d,%d]', [LKey, Ord(LDown), Ord(LLegacyResult), Ord(LNewResult)]);
      Assert.AreEqual(LLegacyResult, LNewResult, 'the result of the key ' + IntToStr(LKey));
    end;
    8:
    begin
      // the game or the menu puts a message for the player
      LText := 'msg' + IntToStr(Random(1000));
      if Random(3) = 0 then
        LText := LText + ' with a long text that goes on and on';
      players[consoleplayer]._message := LText;
      FWorld.PlayerMessage := LText;
      if Random(4) = 0 then
      begin
        message_dontfuckwithme := True;
        FWorld.MessageForced := True;
      end;
    end;
    9:
    begin
      // a character from another player, or a destination
      LIndex := Random(MAXPLAYERS);
      case Random(4) of
        0: LValue := 1 + Random(6);
        1: LValue := 13;
        2: LValue := Ord('a') + Random(26);
      else
        LValue := 32 + Random(64);
      end;
      players[LIndex].cmd.chatchar := LValue;
      FWorld.ChatChars[LIndex] := LValue;
    end;
    10:
    begin
      // who plays and what the network is
      LIndex := Random(MAXPLAYERS);
      playeringame[LIndex] := Random(4) > 0;
      FWorld.InGame[LIndex] := playeringame[LIndex];
      if Random(6) = 0 then
      begin
        netgame := not netgame;
        FWorld.NetGame := netgame;
      end;
      if Random(8) = 0 then
      begin
        showMessages := 1 - showMessages;
        FWorld.MessagesShown := showMessages <> 0;
      end;
      if Random(10) = 0 then
      begin
        if language = french then
          language := english
        else
          language := french;
        FWorld.French := language = french;
      end;
    end;
    11:
      // g_game takes the characters to send
      Assert.AreEqual(Ord(HU_dequeueChatChar), Ord(FHeadsUp.DequeueChatChar), 'the character to send');
    12:
      // a new level
      if Random(3) = 0 then
        StartBoth('E' + IntToStr(Random(5)) + 'M' + IntToStr(Random(9)));
  else
    begin
      // a frame: the clock moves
      LegacyFracTime := LegacyFracTime + Random(5 * FRACUNIT div 2);
      HU_DoFPSStuff;
      FHeadsUp.RecordFrameTime(LegacyFracTime);
    end;
  end;
end;

procedure TTestHudParity.RunScenario(const ASeed: Integer; const ASteps: Integer);
var
  LStep: Integer;
  LKeyLog: string;
  LOld: string;
  LNew: string;
  LIndex: Integer;
begin
  RandSeed := ASeed;
  MakeWorlds(Random(4) = 0);
  consoleplayer := Random(MAXPLAYERS);
  FWorld.Console := consoleplayer;
  for LIndex := 0 to MAXPLAYERS - 1 do
  begin
    playeringame[LIndex] := Random(5) > 0;
    FWorld.InGame[LIndex] := playeringame[LIndex];
  end;
  netgame := Random(4) > 0;
  FWorld.NetGame := netgame;
  // the first frame: the old counter reads before the start of its history otherwise
  HU_DoFPSStuff;
  FHeadsUp.RecordFrameTime(0);
  StartBoth('E1M1');
  LKeyLog := '';
  for LStep := 1 to ASteps do
  begin
    Stimulus(LKeyLog);
    LOld := LegacySnapshot;
    LNew := NewSnapshot;
    if LOld <> LNew then
      Assert.Fail(Format('seed %d, step %d, keys %s'#13#10'old: %s'#13#10'new: %s',
        [ASeed, LStep, LKeyLog, LOld, LNew]));
  end;
end;

procedure TTestHudParity.DovrebbeSeguireIlVecchioCodiceInDuecentoScenariCasuali;
var
  LSeed: Integer;
begin
  for LSeed := 1 to 200 do
    RunScenario(LSeed, 400);
end;

procedure TTestHudParity.DovrebbeDareLeStesseTabelleDiTasti;
var
  LFrench: Boolean;
  LTable: THudShiftTable;
  LIndex: Integer;
begin
  for LFrench in [False, True] do
  begin
    if LFrench then
      language := french
    else
      language := english;
    Legacy_Init;
    LTable := THudKeyTables.ShiftTransform(LFrench);
    for LIndex := 0 to 127 do
      Assert.AreEqual(Ord(shiftxform[LIndex]), Ord(LTable[LIndex]),
        Format('french=%d index=%d', [Ord(LFrench), LIndex]));
  end;
end;

procedure TTestHudParity.DovrebbeTradurreITastiComeIlVecchioCodice;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 127 do
    Assert.AreEqual(Ord(ForeignTranslation(Char(LIndex))),
      Ord(THudKeyTables.ForeignTranslation(Char(LIndex))), IntToStr(LIndex));
  // from 128 the old code read past its table (it compared with #128, that Delphi reads as the
  // euro sign): the new code leaves the character as it is
  for LIndex := 128 to 400 do
    Assert.AreEqual(LIndex, Integer(Ord(THudKeyTables.ForeignTranslation(Char(LIndex)))), IntToStr(LIndex));
end;

procedure TTestHudParity.DovrebbeContareGliFotogrammiAlSecondoComeIlVecchioCodice;
var
  LCounter: THudFpsCounter;
  LIndex: Integer;
begin
  language := english;
  Legacy_Init;
  LCounter := THudFpsCounter.Create(TICRATE, FPSSIZE2);
  try
    RandSeed := 77;
    LegacyFracTime := 0;
    for LIndex := 1 to 6000 do
    begin
      case Random(4) of
        0: LegacyFracTime := LegacyFracTime + Random(100);
        1: LegacyFracTime := LegacyFracTime + Random(FRACUNIT);
        2: LegacyFracTime := LegacyFracTime + Random(FRACUNIT * 3);
      else
        LegacyFracTime := LegacyFracTime + Random(5000);
      end;
      HU_DoFPSStuff;
      LCounter.AddFrame(LegacyFracTime);
      Assert.AreEqual(HU_FPS, LCounter.FramesPerSecond, 'frame ' + IntToStr(LIndex));
    end;
  finally
    LCounter.Free;
  end;
end;

procedure TTestHudParity.FontWidths(const AFont: array of Pointer; out AWidths: THudFontWidths);
var
  LIndex: Integer;
begin
  AWidths.Count := Length(AFont);
  for LIndex := 0 to High(AFont) do
    AWidths.Width[LIndex] := Ppatch_t(AFont[LIndex]).width;
end;

procedure TTestHudParity.DovrebbeScrivereGliStessiGlifiDelleLinee;
var
  LRun: Integer;
  LText: string;
  LLegacy: hu_textline_t;
  LLine: THudTextLine;
  LLayout: THudLayout;
  LWidths: THudFontWidths;
  LPointers: array[0..HU_FONTSIZE - 1] of Pointer;
  LCursor: Boolean;
  LX, LY, LIndex, LLength: Integer;
  LExpected: string;
  LActual: string;
  LGlyphs: TArray<THudGlyph>;
begin
  RandSeed := 5;
  LLayout := THudLayout.Create;
  try
    for LRun := 1 to 600 do
    begin
      // another font every time: widths from 1 to 12
      Legacy_MakeFonts([1 + Random(12), 1 + Random(12), 1 + Random(12), 1 + Random(12)]);
      for LIndex := 0 to HU_FONTSIZE - 1 do
        LPointers[LIndex] := hu_font[LIndex];
      FontWidths(LPointers, LWidths);
      LX := Random(300);
      LY := Random(200);
      LLength := Random(3) * Random(HUD_MAX_LINE_LENGTH + 1);
      LText := '';
      for LIndex := 1 to LLength do
        case Random(12) of
          0: LText := LText + #10;
          1: LText := LText + #13;
          2, 3: LText := LText + ' ';
          4: LText := LText + Char(Random(128));
        else
          LText := LText + Char(33 + Random(70));
        end;
      LCursor := Random(2) = 0;

      HUlib_initTextLine(@LLegacy, LX, LY, @hu_font, Ord(HU_FONTSTART));
      for LIndex := 1 to Length(LText) do
        HUlib_addCharToTextLine(@LLegacy, LText[LIndex]);
      LegacyDrawLog := '';
      HUlib_drawTextLine(@LLegacy, LCursor);
      LExpected := LegacyDrawLog;

      LLine := THudTextLine.Create(LX, LY, Ord(HU_FONTSTART));
      try
        LLine.AddText(LText);
        THudTextLayout.Line(LLine, LWidths, 320, Ord('_'), LCursor, LLayout);
        LActual := '';
        LGlyphs := LLayout.Glyphs;
        for LIndex := 0 to LLayout.Count - 1 do
          LActual := LActual + Format('%d,%d,%d,1,0;', [LGlyphs[LIndex].X, LGlyphs[LIndex].Y,
            LGlyphs[LIndex].Index + 1]);
        if LLayout.CursorFits then
          LActual := LActual + Format('%d,%d,%d,1,0;', [LLayout.CursorX, LLayout.CursorY,
            Ord('_') - Ord(HU_FONTSTART) + 1]);
      finally
        LLine.Free;
      end;
      Assert.AreEqual(LExpected, LActual, 'run ' + IntToStr(LRun));
    end;
  finally
    LLayout.Free;
  end;
end;

procedure TTestHudParity.DovrebbeScrivereGliStessiGlifiDelTestoACapo;
var
  LRun: Integer;
  LText: string;
  LLayout: THudLayout;
  LWidths: THudFontWidths;
  LPointers: array[0..HU_FONTSIZE - 1] of Pointer;
  LX, LY, LIndex, LLength, LScreen: Integer;
  LExpected: string;
  LActual: string;
  LGlyphs: TArray<THudGlyph>;
begin
  RandSeed := 6;
  LLayout := THudLayout.Create;
  try
    for LRun := 1 to 600 do
    begin
      Legacy_MakeFonts([1 + Random(12), 1 + Random(12), 1 + Random(12), 1 + Random(12), 1 + Random(12)]);
      for LIndex := 0 to HU_FONTSIZE - 1 do
        LPointers[LIndex] := yfont[LIndex];
      FontWidths(LPointers, LWidths);
      LX := Random(200);
      LY := Random(150);
      LScreen := Random(2);
      LLength := Random(200);
      LText := '';
      for LIndex := 1 to LLength do
        case Random(10) of
          0: LText := LText + #10;
          1: LText := LText + #13;
          2, 3: LText := LText + ' ';
          4: LText := LText + '_';
          5: LText := LText + Char(Random(256));
        else
          LText := LText + Char(33 + Random(90));
        end;
      LegacyDrawLog := '';
      HUlib_drawYellowText(LX, LY, LText, LScreen);
      LExpected := LegacyDrawLog;

      THudTextLayout.Wrapped(LText, LX, LY, LWidths, Ord(HU_FONTSTART), 12, 320 - 20, LLayout);
      LActual := '';
      LGlyphs := LLayout.Glyphs;
      for LIndex := 0 to LLayout.Count - 1 do
        LActual := LActual + Format('%d,%d,%d,%d,0;', [LGlyphs[LIndex].X, LGlyphs[LIndex].Y,
          100 + LGlyphs[LIndex].Index, Ord(LScreen = SCN_FG)]);
      Assert.AreEqual(LExpected, LActual, 'run ' + IntToStr(LRun));
    end;
  finally
    LLayout.Free;
  end;
end;

procedure TTestHudParity.DovrebbeScrivereGliStessiGlifiDelTestoDelleStatistiche;
var
  LRun: Integer;
  LText: string;
  LLayout: THudLayout;
  LWidths: THudFontWidths;
  LPointers: array[0..HU_FONTSIZE - 1] of Pointer;
  LX, LY, LIndex, LLength: Integer;
  LHighlight: Boolean;
  LExpected: string;
  LActual: string;
  LGlyphs: TArray<THudGlyph>;
  LPosition: menupos_t;
begin
  RandSeed := 7;
  LLayout := THudLayout.Create;
  try
    for LRun := 1 to 600 do
    begin
      Legacy_MakeFonts([1 + Random(12), 1 + Random(12), 1 + Random(12), 1 + Random(12), 1 + Random(12)]);
      for LIndex := 0 to HU_FONTSIZE - 1 do
        LPointers[LIndex] := hu_font[LIndex];
      FontWidths(LPointers, LWidths);
      LX := Random(300);
      LY := Random(190);
      LLength := Random(80);
      LText := '';
      for LIndex := 1 to LLength do
        case Random(12) of
          0: LText := LText + #10;
          1: LText := LText + #13;
          2, 3: LText := LText + ' ';
          4: LText := LText + Char(Random(256));
          5: LText := LText + Char(48 + Random(10));
          6: LText := LText + #0;
        else
          LText := LText + Char(33 + Random(90));
        end;
      LHighlight := Random(2) = 0;
      v_translation := nil;
      LegacyDrawLog := '';
      LPosition := HU_WriteText(LX, LY, LText, LHighlight);
      LExpected := LegacyDrawLog;

      if Length(LText) = 0 then
        LActual := ''
      else
      begin
        THudTextLayout.Highlighted(LText, LX, LY, LWidths, Ord(HU_FONTSTART), 12, 320, LHighlight, LLayout);
        LActual := '';
        LGlyphs := LLayout.Glyphs;
        for LIndex := 0 to LLayout.Count - 1 do
          LActual := LActual + Format('%d,%d,%d,1,%d;', [LGlyphs[LIndex].X, LGlyphs[LIndex].Y,
            LGlyphs[LIndex].Index + 1, Ord(LGlyphs[LIndex].Highlighted)]);
        Assert.AreEqual(LPosition.x, LLayout.EndX, 'end x, run ' + IntToStr(LRun));
        Assert.AreEqual(LPosition.y, LLayout.EndY, 'end y, run ' + IntToStr(LRun));
      end;
      Assert.AreEqual(LExpected, LActual, 'run ' + IntToStr(LRun));
    end;
  finally
    LLayout.Free;
  end;
end;

procedure TTestHudParity.DovrebbeSeguireLaFinestraDiTestoDelVecchioCodice;
var
  LRun: Integer;
  LStep: Integer;
  LHeight: Integer;
  LVisible: Boolean;
  LLegacy: hu_stext_t;
  LNew: THudScrollingText;
  LWorld: TFakeHudWorld;
  LWorldRef: IInterface;
  LPrefix: string;
  LMessage: string;
  LIndex: Integer;
  LOld: string;
  LActual: string;
begin
  RandSeed := 8;
  LWorld := TFakeHudWorld.Create;
  LWorldRef := LWorld;
  LNew := THudScrollingText.Create(LWorld);
  try
    for LRun := 1 to 150 do
    begin
      LHeight := 1 + Random(HU_MAXLINES);
      LVisible := True;
      LWorld.EchoLog := '';
      LegacyEchoLog := '';
      HUlib_initSText(@LLegacy, 3, 40, LHeight, @hu_font, Ord(HU_FONTSTART), @LVisible);
      LNew.Initialize(3, 40, LHeight, hu_font[0].height + 1, Ord(HU_FONTSTART));
      for LStep := 1 to 60 do
      begin
        LPrefix := '';
        LMessage := '';
        for LIndex := 1 to Random(8) do
          LPrefix := LPrefix + Char(65 + Random(26));
        for LIndex := 1 to Random(60) do
          case Random(10) of
            0: LMessage := LMessage + #13#10;
            1: LMessage := LMessage + #10;
            2: LMessage := LMessage + #13;
            3: LMessage := LMessage + ' ';
          else
            LMessage := LMessage + Char(33 + Random(90));
          end;
        case Random(7) of
          0:
          begin
            HUlib_addLineToSText(@LLegacy);
            LNew.AddLine;
          end;
          1:
          begin
            HUlib_removeLineFromSText(@LLegacy);
            LNew.RemoveRow;
          end;
          2, 3:
          begin
            HUlib_addMessageToSText(@LLegacy, LPrefix, LMessage);
            LNew.AddMessage(LPrefix, LMessage);
          end;
          4, 5:
          begin
            HUlib_addMessageToSText2(@LLegacy, LPrefix, LMessage);
            LNew.AddMessageBelow(LPrefix, LMessage);
          end;
        else
          begin
            // consume an erase pass as the erase does (that part is the drawing, here only the counts)
            LLegacy.lines[LLegacy.curline].needsupdate := 0;
            LNew.Current.ConsumePass;
            while LNew.Current.NeedsUpdate > 0 do
              LNew.Current.ConsumePass;
          end;
        end;
        LOld := IntToStr(LLegacy.height) + '/' + IntToStr(LLegacy.curline) + ':';
        for LIndex := 0 to LLegacy.height - 1 do
          LOld := LOld + LegacyText(@LLegacy.lines[LIndex]) + ';';
        LActual := NewWindow(LNew);
        Assert.AreEqual(LOld, LActual, Format('run %d, step %d', [LRun, LStep]));
        Assert.AreEqual(LegacyEchoLog, LWorld.EchoLog, Format('echo, run %d, step %d', [LRun, LStep]));
      end;
    end;
  finally
    LNew.Free;
    LWorldRef := nil;
  end;
end;

procedure TTestHudParity.DovrebbeScegliereGliStessiTitoli;
var
  LNames: array[0..44] of string;
  LNames2: array[0..32] of string;
  LIndex: Integer;
  LEpisode: Integer;
  LMap: Integer;
begin
  for LIndex := 0 to 44 do
    LNames[LIndex] := 'name' + IntToStr(LIndex);
  for LIndex := 0 to 32 do
    LNames2[LIndex] := 'map' + IntToStr(LIndex);
  for LEpisode := -1 to 6 do
    for LMap := -2 to 12 do
    begin
      Assert.AreEqual(Legacy_Title(LNames, LEpisode, LMap), THudMapTitle.ForEpisode(LNames, LEpisode, LMap),
        Format('episode %d map %d', [LEpisode, LMap]));
      Assert.AreEqual(Legacy_Title2(LNames2, LMap), THudMapTitle.ForMap(LNames2, LMap),
        Format('map %d', [LMap]));
    end;
  for LMap := 0 to 40 do
    Assert.AreEqual(Legacy_Title2(LNames2, LMap), THudMapTitle.ForMap(LNames2, LMap), IntToStr(LMap));
end;

procedure TTestHudParity.DovrebbeScegliereLoStessoMirino;
var
  LRun: Integer;
  LHasTarget: Boolean;
  LFriend: Boolean;
  LTarget: THudCrosshairTarget;
  LLevelTime: Integer;
  LCrossTic: Integer;
  LLook: Integer;
  LWidth: Integer;
begin
  RandSeed := 9;
  for LRun := 1 to 5000 do
  begin
    LHasTarget := Random(3) > 0;
    LFriend := Random(3) = 0;
    LLevelTime := Random(200000);
    LCrossTic := Random(200000);
    if not LHasTarget then
      LTarget := THudCrosshairTarget.None
    else if LFriend then
      LTarget := THudCrosshairTarget.Friend
    else
      LTarget := THudCrosshairTarget.Enemy;
    Assert.AreEqual(Legacy_CrosshairIndex(LHasTarget, LFriend, LLevelTime, LCrossTic),
      THudCrosshair.PatchIndex(LTarget, LLevelTime, LCrossTic));
    LLook := Random(256);
    LWidth := 1 + Random(1920);
    Assert.AreEqual(Legacy_CrosshairOffset(LLook, LWidth), THudCrosshair.OffsetX(LLook, LWidth));
  end;
end;

procedure TTestHudParity.DovrebbeScrivereLoStessoTempoDelLivello;
var
  LRun: Integer;
  LLevelTime: Integer;
begin
  MakeWorlds(False);
  StartBoth('E1M1');
  RandSeed := 10;
  for LRun := 1 to 3000 do
  begin
    case Random(3) of
      0: LLevelTime := Random(35 * 60);
      1: LLevelTime := Random(35 * 3600 * 3);
    else
      LLevelTime := Random(35 * 3600 * 150);
    end;
    Legacy_UpdateLevelTime(LLevelTime);
    FView.UpdateLevelTime(LLevelTime);
    Assert.AreEqual(LegacyText(@w_leveltime), NewLine(FView.LevelTime), IntToStr(LLevelTime));
    Assert.AreEqual(THudLevelTime.Format(LLevelTime, TICRATE), string(FView.LevelTime.Text));
  end;
end;

end.
