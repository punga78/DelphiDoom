{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the game around the levels                        }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  GameLoop, HandleDeath, GameFinale and CheckKeys of kd_play.c; NewGame,       }
{  GameOver, StatusWindow and ResetGame of kd_demo.c; DebugKeys of kd_main.c    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.Game;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Keen.Types, DelphiDoom.Keen.GameTypes, DelphiDoom.Keen.InputTypes,
  DelphiDoom.Keen.UserTypes, DelphiDoom.Keen.Intf, DelphiDoom.Keen.UserIntf, DelphiDoom.Keen.PlayLoop,
  DelphiDoom.Keen.GameSaver;

const
  /// <summary>levelnames[] of kd_play.c: the 17 levels (0 is the world map), an empty name and the title page</summary>
  KEEN_LEVEL_NAMES: array[0..18] of AnsiString = ('The Land of Tuberia', 'Horseradish Hill', 'The Melon Mines',
    'Bridge Bottoms', 'Rhubarb Rapids', 'Parsnip Pass', 'Level 6', 'Spud City', 'Level 8', 'Apple Acres',
    'Grape Grove', 'Level 11', 'Brussels Sprout Bay', 'Level 13', 'Squash Swamp', 'Boobus'' Chamber',
    'Castle Tuberia', '', 'Title Page');

type
  /// <summary>
  ///   A game from its start to its end: the levels one after the other (the world map is the level 0), what
  ///   happens when Keen dies, the end of the story, the windows that the keys open in the middle of a level
  ///   (the status, the pause, the control panel, the cheats of F10) and the events that the actors raise.
  ///   The parts are given to it; the loop of the frames of a level is TKeenPlayLoop
  /// </summary>
  TKeenGame = class(TInterfacedObject, IKeenGame, IKeenGameEvents, IKeenGameHooks)
  strict private
    FPlay: IKeenPlayState;
    FPlayLoop: TKeenPlayLoop;
    FLevel: IKeenLevelSetup;
    FSaver: TKeenGameSaver;
    FPlayer: IKeenPlayerFunctions;
    FRefresh: IKeenRefresh;
    FTiming: IKeenRefreshTiming;
    FWindows: IKeenUserWindows;
    FVideo: IKeenBufferedVideo;
    FFader: IKeenFader;
    FInput: IKeenInput;
    FClock: IKeenClock;
    FSound: IKeenSoundManager;
    FState: IKeenUserState;
    FPanel: IKeenControlPanel;
    FScores: IKeenHighScores;
    FSingleStep: Boolean;
    FJumpCheat: Boolean;
    FGodMode: Boolean;
    function LevelName(AMap: Integer): AnsiString;
    procedure StatusWindow;
    procedure GameOver;
    procedure HandleDeath;
    procedure GameFinale;
    function DebugKeys: Boolean;
    procedure ShowAndAck(AWidth, AHeight: Integer; const AText: AnsiString);
  public
    /// <param name="APlay">gamestate, playstate and the map that is loaded</param>
    /// <param name="APlayLoop">The loop of the frames of a level (not owned)</param>
    /// <param name="ALevel">SetupGameLevel</param>
    /// <param name="ASaver">The game on a file (not owned)</param>
    /// <param name="APlayer">The score box and the death of Keen</param>
    /// <param name="ARefresh">The refresh manager, that also resets its timing</param>
    constructor Create(const APlay: IKeenPlayState; APlayLoop: TKeenPlayLoop; const ALevel: IKeenLevelSetup;
      ASaver: TKeenGameSaver; const APlayer: IKeenPlayerFunctions; const ARefresh: IKeenRefresh;
      const AWindows: IKeenUserWindows; const AFader: IKeenFader; const AInput: IKeenInput; const AClock: IKeenClock;
      const ASound: IKeenSoundManager; const AState: IKeenUserState; const APanel: IKeenControlPanel;
      const AScores: IKeenHighScores);
    // IKeenGame
    procedure NewGame;
    procedure GameLoop;
    // IKeenGameEvents
    procedure KillKeen;
    procedure PlaySound(ASound: Integer);
    procedure CheckKeys;
    function IsGameLoaded: Boolean;
    procedure BeginPlay;
    procedure ClearGodMode;
    function IsGodMode: Boolean;
    function IsJumpCheat: Boolean;
    procedure ShowNeedBombs;
    // IKeenGameHooks
    function LoadGame(AStream: TStream): Boolean;
    function SaveGame(AStream: TStream): Boolean;
    procedure ResetGame;
    /// <summary>singlestep of kd_main.c: the slow motion of the debug keys</summary>
    property SingleStep: Boolean read FSingleStep write FSingleStep;
  end;

implementation

uses
  DelphiDoom.Keen.AudioIds;

const
  // the scan codes of the debug keys (with F10) and of the keys of HandleDeath
  SC_G = $22;
  SC_I = $17;
  SC_J = $24;
  SC_P = $19;
  SC_S = $1F;
  SC_W = $11;

{ TKeenGame }

constructor TKeenGame.Create(const APlay: IKeenPlayState; APlayLoop: TKeenPlayLoop; const ALevel: IKeenLevelSetup;
  ASaver: TKeenGameSaver; const APlayer: IKeenPlayerFunctions; const ARefresh: IKeenRefresh;
  const AWindows: IKeenUserWindows; const AFader: IKeenFader; const AInput: IKeenInput; const AClock: IKeenClock;
  const ASound: IKeenSoundManager; const AState: IKeenUserState; const APanel: IKeenControlPanel;
  const AScores: IKeenHighScores);
begin
  inherited Create;
  if not Assigned(APlay) then
    raise EArgumentNilException.Create('APlay');
  if not Assigned(APlayLoop) then
    raise EArgumentNilException.Create('APlayLoop');
  if not Assigned(ALevel) then
    raise EArgumentNilException.Create('ALevel');
  if not Assigned(ASaver) then
    raise EArgumentNilException.Create('ASaver');
  if not Assigned(APlayer) then
    raise EArgumentNilException.Create('APlayer');
  if not Assigned(ARefresh) then
    raise EArgumentNilException.Create('ARefresh');
  if not Assigned(AWindows) then
    raise EArgumentNilException.Create('AWindows');
  if not Assigned(AFader) then
    raise EArgumentNilException.Create('AFader');
  if not Assigned(AInput) then
    raise EArgumentNilException.Create('AInput');
  if not Assigned(AClock) then
    raise EArgumentNilException.Create('AClock');
  if not Assigned(ASound) then
    raise EArgumentNilException.Create('ASound');
  if not Assigned(AState) then
    raise EArgumentNilException.Create('AState');
  if not Assigned(APanel) then
    raise EArgumentNilException.Create('APanel');
  if not Assigned(AScores) then
    raise EArgumentNilException.Create('AScores');
  FPlay := APlay;
  FPlayLoop := APlayLoop;
  FLevel := ALevel;
  FSaver := ASaver;
  FPlayer := APlayer;
  FRefresh := ARefresh;
  if not Supports(ARefresh, IKeenRefreshTiming, FTiming) then
    raise EArgumentException.Create('ARefresh');
  FWindows := AWindows;
  FVideo := AWindows.Video;
  FFader := AFader;
  FInput := AInput;
  FClock := AClock;
  FSound := ASound;
  FState := AState;
  FPanel := APanel;
  FScores := AScores;
end;

function TKeenGame.LevelName(AMap: Integer): AnsiString;
begin
  if (AMap >= Low(KEEN_LEVEL_NAMES)) and (AMap <= High(KEEN_LEVEL_NAMES)) then
    Result := KEEN_LEVEL_NAMES[AMap]
  else
    Result := '';
end;

procedure TKeenGame.NewGame;
var
  LState: PKeenGameState;
  LIndex: Integer;
begin
  LState := FPlay.GameState;
  LState^.WorldX := 0; // spawn Keen at the starting spot
  LState^.MapOn := 0;
  LState^.Score := 0;
  LState^.NextExtra := 20000;
  LState^.Lives := 3;
  LState^.FlowerPowers := 0;
  LState^.BoobusBombs := 0;
  for LIndex := 0 to KEEN_GAMELEVELS - 1 do
    LState^.LevelDone[LIndex] := False;
end;

procedure TKeenGame.ResetGame;
begin
  NewGame;
end;

function TKeenGame.LoadGame(AStream: TStream): Boolean;
begin
  Result := FSaver.Load(AStream);
end;

function TKeenGame.SaveGame(AStream: TStream): Boolean;
begin
  Result := FSaver.Save(AStream);
end;

procedure TKeenGame.KillKeen;
begin
  FPlayer.KillKeen;
end;

procedure TKeenGame.PlaySound(ASound: Integer);
begin
  FSound.PlaySound(ASound);
end;

function TKeenGame.IsGameLoaded: Boolean;
begin
  Result := FState.LoadedGame;
end;

procedure TKeenGame.BeginPlay;
begin
  FPlayer.FixScoreBox;
end;

procedure TKeenGame.ClearGodMode;
begin
  FGodMode := False;
end;

function TKeenGame.IsGodMode: Boolean;
begin
  Result := FGodMode;
end;

function TKeenGame.IsJumpCheat: Boolean;
begin
  Result := FJumpCheat;
end;

procedure TKeenGame.ShowNeedBombs;
begin
  FVideo.FixRefreshBuffer;
  FWindows.CenterWindow(26, 6);
  FWindows.PrintY := FWindows.PrintY + 8;
  FWindows.CPrint('You can''t possibly'#10'defeat King Boobus Tuber'#10'with less than 12 bombs!');
  FVideo.UpdateScreen;
  FInput.Ack;
  FRefresh.ForceRefresh;
end;

procedure TKeenGame.ShowAndAck(AWidth, AHeight: Integer; const AText: AnsiString);
begin
  FVideo.FixRefreshBuffer;
  FWindows.CenterWindow(AWidth, AHeight);
  FWindows.PrintCentered(AText);
  FVideo.UpdateScreen;
  FInput.Ack;
end;

procedure TKeenGame.StatusWindow;
var
  LWindow: TKeenWindowRec;
  LState: PKeenGameState;
  LX: Integer;
begin
  LState := FPlay.GameState;
  FWindows.CenterWindow(22, 7);
  FWindows.CPrint('Status Window');
  LWindow := FWindows.Window;
  Inc(LWindow.X, 8);
  Dec(LWindow.W, 8);
  Inc(LWindow.Y, 20);
  Dec(LWindow.H, 20);
  LWindow.PX := LWindow.X;
  LWindow.PY := LWindow.Y;
  FWindows.SetWindow(LWindow);
  // the lives
  FVideo.DrawTile8(FWindows.PrintX, FWindows.PrintY, 26);
  FVideo.DrawTile8(FWindows.PrintX + 8, FWindows.PrintY, 27);
  FWindows.PrintX := FWindows.PrintX + 24;
  FWindows.PrintUnsigned(Cardinal(LState^.Lives));
  FWindows.Print(#10);
  // the bombs
  FVideo.DrawTile8(FWindows.PrintX, FWindows.PrintY, 32);
  FVideo.DrawTile8(FWindows.PrintX + 8, FWindows.PrintY, 33);
  FVideo.DrawTile8(FWindows.PrintX, FWindows.PrintY + 8, 34);
  FVideo.DrawTile8(FWindows.PrintX + 8, FWindows.PrintY + 8, 35);
  FWindows.PrintX := FWindows.PrintX + 24;
  FWindows.PrintUnsigned(Cardinal(LState^.BoobusBombs));
  FWindows.Print(#10);
  // the right half: the points of the next extra life and the keys
  LWindow := FWindows.Window;
  Inc(LWindow.X, 50);
  Dec(LWindow.W, 50);
  LWindow.PX := LWindow.X;
  LWindow.PY := LWindow.Y;
  FWindows.SetWindow(LWindow);
  FVideo.FontColor := KEEN_F_FIRSTCOLOR;
  FWindows.Print('Next ');
  FVideo.FontColor := KEEN_F_BLACK;
  LX := FWindows.PrintX;
  FVideo.DrawTile8(FWindows.PrintX, FWindows.PrintY, 26);
  FVideo.DrawTile8(FWindows.PrintX + 8, FWindows.PrintY, 27);
  FWindows.PrintX := FWindows.PrintX + 24;
  FWindows.PrintUnsigned(Cardinal(LState^.NextExtra));
  FWindows.Print(#10);
  FWindows.PrintX := LX;
  FVideo.DrawTile8(FWindows.PrintX, FWindows.PrintY, 24);
  FVideo.DrawTile8(FWindows.PrintX + 8, FWindows.PrintY, 25);
  FWindows.PrintX := FWindows.PrintX + 24;
  FWindows.PrintUnsigned(Cardinal(LState^.Keys));
  FWindows.Print(#10);
  FVideo.UpdateScreen;
  FInput.Ack;
end;

procedure TKeenGame.GameOver;
begin
  FVideo.InitDoubleBuffer;
  FWindows.CenterWindow(16, 3);
  FWindows.PrintCentered('Game Over!');
  FVideo.UpdateScreen;
  FInput.ClearKeysDown;
  FInput.Ack;
end;

function TKeenGame.DebugKeys: Boolean;
var
  LText: AnsiString;
  LLevel: Integer;
  LInGame: Boolean;
begin
  Result := False;
  LInGame := FState.InGame;
  if FInput.IsKeyDown(SC_G) and LInGame then
  begin
    // god mode
    if FGodMode then
      ShowAndAck(12, 2, 'God mode OFF')
    else
      ShowAndAck(12, 2, 'God mode ON');
    FGodMode := not FGodMode;
    Result := True;
  end
  else if FInput.IsKeyDown(SC_I) then
  begin
    // item cheat
    FVideo.FixRefreshBuffer;
    FWindows.CenterWindow(12, 3);
    FWindows.PrintCentered('Free items!');
    FPlay.GameState^.BoobusBombs := 99;
    FPlay.GameState^.FlowerPowers := 99;
    FPlay.GameState^.Keys := 99;
    FVideo.UpdateScreen;
    FInput.Ack;
    Result := True;
  end
  else if FInput.IsKeyDown(SC_J) then
  begin
    // jump cheat
    FJumpCheat := not FJumpCheat;
    if FJumpCheat then
      ShowAndAck(18, 3, 'Jump cheat ON')
    else
      ShowAndAck(18, 3, 'Jump cheat OFF');
    Result := True;
  end
  else if FInput.IsKeyDown(SC_P) then
    // pause with no screen disruption
    FInput.Ack
  else if FInput.IsKeyDown(SC_S) and LInGame then
  begin
    // slow motion
    FSingleStep := not FSingleStep;
    if FSingleStep then
      ShowAndAck(18, 3, 'Slow motion ON')
    else
      ShowAndAck(18, 3, 'Slow motion OFF');
    Result := True;
  end
  else if FInput.IsKeyDown(SC_W) and LInGame then
  begin
    // warp to a level
    FVideo.FixRefreshBuffer;
    FWindows.CenterWindow(26, 3);
    FWindows.PrintY := FWindows.PrintY + 6;
    FWindows.Print('  Warp to which level(0-16):');
    FVideo.UpdateScreen;
    LText := '';
    if FWindows.LineInput(FVideo.Px, FVideo.Py, LText, '', True, 2, 0) then
    begin
      // atoi: a text that is not a number is 0
      LLevel := StrToIntDef(string(LText), 0);
      if (LLevel >= 0) and (LLevel <= 16) then
      begin
        FPlay.GameState^.MapOn := LLevel;
        FPlay.PlayState := keWarpToLevel;
      end;
    end;
    Result := True;
  end;
end;

procedure TKeenGame.CheckKeys;
var
  LScan: Byte;
begin
  // single step debug mode (in PlayLoop, after the refresh)
  if FSingleStep then
  begin
    FVideo.WaitVBL(14);
    FTiming.ResetTiming;
  end;
  // don't do anything with a faded screen
  if FFader.IsFaded then
    Exit;
  // space for the status screen
  if FInput.IsKeyDown(KEEN_SC_SPACE) then
  begin
    StatusWindow;
    FInput.ClearKeysDown;
    FRefresh.ForceRefresh;
    FTiming.ResetTiming;
  end;
  // the pause key cannot be checked as a scan code
  if FInput.Paused then
  begin
    FVideo.FixRefreshBuffer;
    FWindows.CenterWindow(8, 3);
    FWindows.PrintCentered('PAUSED');
    FVideo.UpdateScreen;
    FInput.Ack;
    FRefresh.ForceRefresh;
    FInput.Paused := False;
  end;
  // F1-F7 and escape enter the control panel
  LScan := FInput.LastScan;
  if ((LScan >= KEEN_SC_F1) and (LScan <= KEEN_SC_F7)) or (LScan = KEEN_SC_ESCAPE) then
  begin
    FVideo.FixRefreshBuffer;
    FWindows.CenterWindow(20, 8);
    FWindows.CPrint('Loading');
    FVideo.UpdateScreen;
    FPanel.Run;
    FInput.ClearKeysDown;
    if FState.RestartGame <> kgdContinue then
      FPlay.PlayState := keResetGame
    else if not FState.LoadedGame then
      FRefresh.ForceRefresh; // don't refresh if a new game is being loaded
    FTiming.ResetTiming;
  end;
  // F10 and a key: the debug keys
  if FInput.IsKeyDown(KEEN_SC_F10) and DebugKeys then
  begin
    FRefresh.ForceRefresh;
    FTiming.ResetTiming;
  end;
end;

procedure TKeenGame.HandleDeath;
var
  LState: PKeenGameState;
  LWindow: TKeenWindowRec;
  LTop: Integer;
  LBottom: Integer;
  LSelection: Integer;
  LY: Integer;
  LControl: TKeenControlInfo;
  LScan: Byte;

  procedure Bar(AColor: Integer);
  begin
    FVideo.Hlin(LWindow.X + 4, LWindow.X + LWindow.W - 4, LY, AColor);
    FVideo.Hlin(LWindow.X + 4, LWindow.X + LWindow.W - 4, LY + 1, AColor);
    FVideo.Hlin(LWindow.X + 4, LWindow.X + LWindow.W - 4, LY + 12, AColor);
    FVideo.Hlin(LWindow.X + 4, LWindow.X + LWindow.W - 4, LY + 13, AColor);
    FVideo.Vlin(LY + 1, LY + 11, LWindow.X + 4, AColor);
    FVideo.Vlin(LY + 1, LY + 11, LWindow.X + 5, AColor);
    FVideo.Vlin(LY + 1, LY + 11, LWindow.X + LWindow.W - 4, AColor);
    FVideo.Vlin(LY + 1, LY + 11, LWindow.X + LWindow.W - 5, AColor);
  end;

begin
  LState := FPlay.GameState;
  LState^.Keys := 0;
  Dec(LState^.BoobusBombs, LState^.BombsThisLevel);
  Dec(LState^.Lives);
  if LState^.Lives < 0 then
    Exit;
  FVideo.FixRefreshBuffer;
  FWindows.CenterWindow(20, 8);
  FWindows.PrintY := FWindows.PrintY + 4;
  FWindows.CPrint('You didn''t make it past');
  FWindows.CPrint(LevelName(FPlay.MapOn));
  FWindows.PrintY := FWindows.PrintY + 8;
  LTop := FWindows.PrintY - 2;
  FWindows.CPrint('Try Again');
  FWindows.PrintY := FWindows.PrintY + 4;
  LBottom := FWindows.PrintY - 2;
  FWindows.CPrint('Exit to Tuberia');
  LWindow := FWindows.Window;
  LSelection := 0;
  while True do
  begin
    if LSelection <> 0 then
      LY := LBottom
    else
      LY := LTop;
    // the select bar blinks between the two colors
    if ((FClock.TimeCount div 16) and 1) <> 0 then
      Bar(KEEN_SECONDCOLOR)
    else
      Bar(KEEN_FIRSTCOLOR);
    FVideo.UpdateScreen;
    Bar(KEEN_WHITE);
    LScan := FInput.LastScan;
    if LScan = KEEN_SC_ESCAPE then
    begin
      LState^.MapOn := 0; // exit to Tuberia
      FInput.ClearKeysDown;
      Exit;
    end;
    LControl := FInput.ReadControl(0);
    FPlay.Control := LControl;
    if LControl.Button0 or LControl.Button1 or (LScan = KEEN_SC_RETURN) or (LScan = KEEN_SC_SPACE) then
    begin
      if LSelection <> 0 then
        LState^.MapOn := 0;
      Exit;
    end;
    if (LControl.YAxis = -1) or (LScan = KEEN_SC_UPARROW) then
      LSelection := 0
    else if (LControl.YAxis = 1) or (LScan = KEEN_SC_DOWNARROW) then
      LSelection := 1;
  end;
end;

procedure TKeenGame.GameFinale;
begin
  FVideo.FixRefreshBuffer;
  // screen 1 of the finale (16 lines)
  FWindows.CenterWindow(30, 21);
  FWindows.PrintY := FWindows.PrintY + 4;
  FWindows.CPrint(
    'Yes!  Boobus Tuber''s hash-brown-'#10 +
    'like remains rained down from'#10 +
    'the skies as Commander Keen'#10 +
    'walked up to the Dream Machine.'#10 +
    'He analyzed all the complex'#10 +
    'controls and readouts on it, then'#10 +
    'pulled down a huge red lever'#10 +
    'marked "On/Off Switch."  The'#10 +
    'machine clanked and rattled,'#10 +
    'then went silent. He had freed'#10 +
    'all the children from their'#10 +
    'vegetable-enforced slavery!'#10 +
    'Everything around Keen wobbled'#10 +
    'in a disconcerting manner, his'#10 +
    'eyelids grew heavy, and he'#10 +
    'fell asleep....'#10);
  FVideo.UpdateScreen;
  FVideo.WaitVBL(60);
  FSound.WaitSoundDone;
  FInput.ClearKeysDown;
  FInput.Ack;
  // screen 2 (15 lines)
  FWindows.CenterWindow(30, 21);
  FWindows.PrintY := FWindows.PrintY + 9;
  FWindows.CPrint(
    'Billy woke up, looking around the'#10 +
    'room, the early morning sun'#10 +
    'shining in his face.  Nothing.'#10 +
    'No vegetables to be seen.  Was it'#10 +
    'all just a dream?'#10#10 +
    'Billy''s mom entered the room.'#10#10 +
    '"Good morning, dear. I heard some'#10 +
    'news on TV that you''d be'#10 +
    'interested in," she said, sitting'#10 +
    'by him on the bed.'#10#10 +
    '"What news?" Billy asked,'#10 +
    'still groggy.'#10#10);
  FVideo.UpdateScreen;
  FVideo.WaitVBL(60);
  FInput.ClearKeysDown;
  FInput.Ack;
  // screen 3 (12 lines)
  FWindows.CenterWindow(30, 21);
  FWindows.PrintY := FWindows.PrintY + 23;
  FWindows.CPrint(
    '"The President declared today'#10 +
    'National ''I Hate Broccoli'' Day.'#10 +
    'He said kids are allowed to pick'#10 +
    'one vegetable today, and they'#10 +
    'don''t have to eat it."'#10#10 +
    '"Aw, mom, I''m not afraid of any'#10 +
    'stupid vegetables," Billy said.'#10 +
    '"But if it''s okay with you, I''d'#10 +
    'rather not have any french fries'#10 +
    'for awhile."'#10#10 +
    'THE END');
  FVideo.UpdateScreen;
  FVideo.WaitVBL(60);
  FInput.ClearKeysDown;
  FInput.Ack;
end;

procedure TKeenGame.GameLoop;
var
  LState: PKeenGameState;
  LCities: Integer;
  LIndex: Integer;
  LMapOn: Integer;
  LFinished: Boolean;
begin
  LState := FPlay.GameState;
  LState^.Difficulty := Ord(FState.RestartGame);
  FState.RestartGame := kgdContinue;
  LFinished := False;
  while True do
  begin
    // startlevel
    if FState.LoadedGame then
    begin
      FState.LoadedGame := False;
      // the view on the player of the game that was loaded
      FFader.FadeOut;
      FLevel.HookFadeIn;
      FLevel.CenterViewOnPlayer;
    end
    else
    begin
      FVideo.FixRefreshBuffer;
      FWindows.CenterWindow(20, 8);
      FWindows.CPrint('Loading');
      FVideo.UpdateScreen;
      LState^.BombsThisLevel := 0;
      FLevel.SetupGameLevel(True);
    end;
    FState.InGame := True;
    try
      FPlayLoop.Run;
    finally
      FState.InGame := False;
    end;
    if FState.LoadedGame then
      Continue;
    LMapOn := FPlay.MapOn;
    case FPlay.PlayState of
      keWarpToLevel:
        Continue;
      keDied:
        HandleDeath;
      keLevelComplete:
        begin
          if LMapOn <> 0 then
            FSound.PlaySound(KEEN_SND_LEVELDONESND);
          // finished the level (entering a level from the world map "finishes" the map 0, as in the C)
          if (LMapOn >= 0) and (LMapOn < KEEN_GAMELEVELS) then
            LState^.LevelDone[LMapOn] := True;
          if LMapOn <> 0 then
            LState^.MapOn := 0;
        end;
      keResetGame:
        Exit;
      keVictorious:
        begin
          GameFinale;
          LFinished := True;
        end;
    end;
    if LFinished or not ((LState^.Lives > -1) and (FPlay.PlayState <> keVictorious)) then
      Break;
  end;
  if not LFinished then
    GameOver;
  LCities := 0;
  for LIndex := 1 to 16 do
    if LState^.LevelDone[LIndex] then
      Inc(LCities);
  FScores.Check(LState^.Score, LCities);
  FVideo.Video.ClearVideo(KEEN_FIRSTCOLOR);
end;

end.
