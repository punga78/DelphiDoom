program IntroParity;
{$APPTYPE CONSOLE}
// Harness fuori dal repository: confronta tic per tic la schermata di avvio, il briefing di missione e i finali
// ORIGINALI di xGreed (dointro con MainIntro, DemoIntro, ShowPortrait, IntroCommand e DoIntroMenu di intro.pas;
// MissionBriefing, EndGame1, EndGame2 ed EndGame3 di utils.pas; con menu.pas, playfli.pas, d_font.pas e d_video.pas)
// con TGreedIntro, TGreedBriefing e TGreedEndGame di Libs\Greed sugli stessi scenari
// (Tests\Source\DelphiDoom.Tests.Greed.IntroScenarios). L'originale blocca nei suoi cicli: la sua Wait e' uno stub che
// per ogni tic cattura lo schermo e la palette, applica i tasti dello scenario ed esegue il corpo di INT_TimerISR
// (stubs\d_ints.pas). I filmati sono file veri nella cartella dei filmati (basedefault): li legge il playfli.pas
// originale. Le righe del golden sono i valori dell'ORIGINALE.
// Uso: IntroParity <cartella con GREED.BLO | sintetico> <golden.txt | nessuno>
uses
  SysUtils, Classes, Generics.Collections,
  g_delphi, d_disk, d_ints, d_ints_h, protos_h, constant, r_public_h, r_render, i_video, d_video, d_font, i_windows,
  raven, utils, modplay, intro, menu, harness_menu,
  DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf, DelphiDoom.Greed.Canvas, DelphiDoom.Tests.Greed.RealData,
  DelphiDoom.Tests.Greed.MenuScenarios, DelphiDoom.Tests.Greed.IntroScenarios;

var
  Given: IGreedArchive;
  Whole, Sparse: IGreedArchive;
  Runner: TIntroLibraryRunner;
  Golden: TStringList;
  Outcome: TMenuOutcome;
  OriginalFrames, LibraryFrames: TList<Cardinal>;
  Different: Integer;
  Totals: array[TIntroKind] of Integer;
  Tics, Screens: Integer;
  Reached: array[0..6] of Integer;
  Movies: string;

var
  FirstPixels: array[0..63999] of Byte;
  FirstPalette: array[0..767] of Byte;

procedure Capture;
begin
  if OriginalFrames.Count = 0 then
  begin
    Move(viewbuffer, FirstPixels, 64000);
    Move(LastPalette, FirstPalette, 768);
  end;
  // the same hash as the runner of the library (four bytes at a time)
  Outcome.Pixels := MenuFnv4(Outcome.Pixels, viewbuffer, 64000);
  Outcome.Palette := MenuFnv4(Outcome.Palette, LastPalette, 768);
  OriginalFrames.Add(MenuFnv4(MENU_FNV_START, viewbuffer, 64000));
end;

function DirectoryName(const sc: TMenuScenario): string;
begin
  case sc.Episode of
    2: Result := 'SAVE2.DIR';
    3: Result := 'SAVE3.DIR';
  else
    Result := 'SAVE1.DIR';
  end;
end;

procedure WriteFileBytes(const name: string; const b: TBytes);
var
  s: TFileStream;
begin
  s := TFileStream.Create(name, fmCreate);
  try
    if Length(b) > 0 then
      s.WriteBuffer(b[0], Length(b));
  finally
    s.Free;
  end;
end;

procedure ResetOriginal(const sc: TIntroScenario);
var
  b: TBytes;
  name: string;
  i: Integer;
  found: TSearchRec;
begin
  if Assigned(Given) then
    CA_InitFromArchive(Given)
  else if sc.Sparse then
    CA_InitFromArchive(Sparse)
  else
    CA_InitFromArchive(Whole);
  CA_FlushAll;
  font1 := CA_CacheLump(CA_GetNamedNum('FONT1'));
  menulevel := 0;
  menucursor := 0;
  menucurloc := 0;
  menumaincursor := 0;
  identity := 0;
  waitanim := 0;
  saveposition := 0;
  menutimedelay := 0;
  quitmenu := false;
  menuexecute := false;
  downlevel := false;
  goright := false;
  goleft := false;
  waiting := false;
  FillChar(savedir, SizeOf(savedir), 0);
  FillChar(modplay.SC, SizeOf(modplay.SC), 0);
  modplay.SC.animation := sc.Base.Animation;
  modplay.SC.violence := sc.Base.Violence;
  modplay.SC.musicvol := sc.Base.MusicVol;
  modplay.SC.sfxvol := sc.Base.SfxVol;
  modplay.SC.ambientlight := sc.Base.AmbientLight;
  modplay.SC.screensize := sc.Base.ScreenSize;
  modplay.SC.camdelay := sc.Base.CamDelay;
  DEMO := sc.Base.Demo;
  ASSASSINATOR := sc.Assassinator;
  GAME1 := sc.Base.Episode = 1;
  GAME2 := sc.Base.Episode = 2;
  GAME3 := sc.Base.Episode = 3;
  gameloaded := false;
  currentViewSize := sc.Base.ScreenSize;
  changelight := 0;
  lighting := 0;
  quitgame := false;
  netmode := false;
  nobriefing := false;
  nointro := false;
  redo := sc.Redo;
  activatemenu := false;
  nextchar := false;
  FillChar(colors, SizeOf(colors), 0);
  HarnessResetKeys;
  timecount := sc.Base.StartTime;
  fontbasecolor := 0;
  // EndGame1..3 print without choosing a font: in the game the font is the one that the play left in font
  if sc.Kind = ikEndGame then
    font := font1
  else
    font := nil;
  I_SetPalette(CA_CachePalette(CA_GetNamedNum('palette')));
  b := TMenuScenarios.Background(sc.Base.BackgroundSeed);
  Move(b[0], viewbuffer, 64000);
  for name in TArray<string>.Create('SAVE1.DIR', 'SAVE2.DIR', 'SAVE3.DIR', 'SAVEGAME.DIR') do
    if FileExists(name) then
      DeleteFile(name);
  if sc.Base.HasDirectory then
    WriteFileBytes(DirectoryName(sc.Base), TMenuScenarios.DirectoryBytes(sc.Base));
  // the help of the Assassinator edition is a file of the game folder (the current folder)
  if FileExists('help.dat') then
    DeleteFile('help.dat');
  if sc.Assassinator then
    WriteFileBytes('help.dat', TIntroScenarios.HelpData);
  // the movies of the scenario are the only ones in the folder
  if FindFirst(Movies + '*.FLI', faAnyFile, found) = 0 then
  begin
    repeat
      DeleteFile(Movies + found.Name);
    until FindNext(found) <> 0;
    FindClose(found);
  end;
  for i := 0 to High(sc.MovieNames) do
    WriteFileBytes(Movies + sc.MovieNames[i], sc.MovieBytes[i]);
  // the player of the original: the stats of the level just left
  FillChar(player, SizeOf(player), 0);
  FillChar(primaries, SizeOf(primaries), 0);
  FillChar(secondaries, SizeOf(secondaries), 0);
  FillChar(pcount, SizeOf(pcount), 0);
  FillChar(scount, SizeOf(scount), 0);
  player.primaries[0] := sc.Stats.PrimariesTaken;
  pcount[0] := sc.Stats.PrimariesTotal;
  player.secondaries[0] := sc.Stats.SecondariesTaken;
  scount[0] := sc.Stats.SecondariesTotal;
  player.score := sc.Stats.Score;
  player.bodycount := sc.Stats.BodyCount;
  levelscore := 0;
  HIntroMode := sc.Kind = ikIntro;
  HScenario := sc.Base;
  HTics := 0;
  HNextKey := 0;
  HTrace.Clear;
  Outcome.Pixels := MENU_FNV_START;
  Outcome.Palette := MENU_FNV_START;
  OriginalFrames.Clear;
end;

function RunOriginal(const sc: TIntroScenario): TMenuOutcome;
begin
  ResetOriginal(sc);
  try
    case sc.Kind of
      ikIntro: dointro;
      ikBriefing: MissionBriefing(sc.Map);
      ikEndGame:
        case sc.Map of
          1: EndGame1;
          2: EndGame2;
        else
          EndGame3;
        end;
    end;
    Capture;
  except
    on EHarnessStop do
      ;
  end;
  Outcome.Tics := HTics;
  Outcome.Trace := HTrace.Hash;
  Outcome.Finish := IntroFinishHash(Ord(quitgame), Ord(gameloaded), timecount);
  Result := Outcome;
end;

// the first screen of a scenario: how many pixels and palette bytes differ
procedure ShowFirst(const sc: TIntroScenario);
var
  n, first, k: Integer;
begin
  Runner.Prepare(sc);
  case sc.Kind of
    ikIntro: Runner.Intro.Start(sc.Redo);
    ikBriefing: Runner.Briefing.Start(sc.Map, sc.Stats);
    ikEndGame: Runner.EndGame.Start(sc.Map);
  end;
  n := 0;
  first := -1;
  for k := 0 to 63999 do
    if FirstPixels[k] <> Runner.Canvas.Pixels[k] then
    begin
      Inc(n);
      if first < 0 then
        first := k;
    end;
  if first >= 0 then
    Writeln(Format('  first screen: %d pixels differ, the first at %d (original %d, library %d)', [n, first,
      FirstPixels[first], Runner.Canvas.Pixels[first]]));
  n := 0;
  for k := 0 to 767 do
    if FirstPalette[k] <> Runner.Display.Palette[k] then
      Inc(n);
  Writeln(Format('  first screen: %d palette bytes differ', [n]));
end;

procedure RunAll;
var
  k, i: Integer;
  sc: TIntroScenario;
  original, lib: TMenuOutcome;
  line: string;
begin
  for k := 0 to INTRO_SCENARIOS - 1 do
  begin
    sc := TIntroScenarios.Scenario(k);
    try
      original := RunOriginal(sc);
    except
      on E: Exception do
      begin
        Writeln('the ORIGINAL stops in the scenario ', k, ' (kind ', Ord(sc.Kind), ', map ', sc.Map, '): ', E.Message);
        raise;
      end;
    end;
    LibraryFrames.Clear;
    try
      lib := Runner.Run(sc, LibraryFrames);
    except
      on E: Exception do
      begin
        Writeln('the LIBRARY stops in the scenario ', k, ' (kind ', Ord(sc.Kind), ', map ', sc.Map, '): ', E.Message);
        raise;
      end;
    end;
    line := original.Line(k);
    Golden.Add(line);
    // what the scenarios reach (the host of the library saw the same calls as the original: the trace is checked)
    Inc(Reached[0], Runner.Host.SoundUpdates);
    Inc(Reached[1], Runner.Host.EpisodesStarted);
    Inc(Reached[2], Length(Runner.Host.Songs));
    Inc(Reached[3], Ord(Runner.Host.Loaded));
    Inc(Reached[4], Ord(Runner.Host.QuitAsked));
    Inc(Reached[5], Ord(original.Tics < sc.Base.MaxTics));
    Inc(Reached[6], Length(sc.MovieNames));
    Inc(Totals[sc.Kind]);
    Inc(Tics, original.Tics);
    Inc(Screens, OriginalFrames.Count);
    if line <> lib.Line(k) then
    begin
      Inc(Different);
      Writeln('DIFF scenario ', k, ' (kind ', Ord(sc.Kind), ', map ', sc.Map, ')');
      Writeln('  original: ', line);
      Writeln('  library:  ', lib.Line(k));
      if OriginalFrames.Count <> LibraryFrames.Count then
        Writeln(Format('  screens: original %d library %d', [OriginalFrames.Count, LibraryFrames.Count]));
      for i := 0 to OriginalFrames.Count - 1 do
        if (i >= LibraryFrames.Count) or (OriginalFrames[i] <> LibraryFrames[i]) then
        begin
          Writeln(Format('  the first screen that differs is the one before the tic %d', [i + 1]));
          if i = 0 then
            ShowFirst(sc);
          Break;
        end;
    end;
  end;
end;

var
  work: string;
begin
  try
    if ParamCount < 2 then
    begin
      Writeln('uso: IntroParity <cartella con GREED.BLO | sintetico> <golden.txt | nessuno>');
      Halt(2);
    end;
    if SameText(ParamStr(1), 'sintetico') then
    begin
      Whole := TIntroScenarios.SyntheticArchive(False);
      Sparse := TIntroScenarios.SyntheticArchive(True);
      Given := nil;
    end
    else
    begin
      Given := TGreedRealData.OpenArchive(ParamStr(1));
      Whole := Given;
      Sparse := Given;
    end;
    // the original writes SAVEn.DIR in the current folder and looks for the movies in basedefault
    work := ExtractFilePath(ParamStr(0)) + 'work';
    ForceDirectories(work);
    SetCurrentDir(work);
    Movies := IncludeTrailingPathDelimiter(work) + 'movies\';
    ForceDirectories(Movies);
    basedefault := Movies;
    maindatapath := IncludeTrailingPathDelimiter(work) + 'nodata\';
    CA_InitFromArchive(Whole);
    VI_Init;
    HCapture := Capture;
    OriginalFrames := TList<Cardinal>.Create;
    LibraryFrames := TList<Cardinal>.Create;
    Golden := TStringList.Create;
    Runner := TIntroLibraryRunner.Create(Given);
    RunAll;
    Writeln(Format('scenarios %d (intro %d, briefing %d, endgame %d), tics %d, screens compared %d, scenarios that differ %d',
      [INTRO_SCENARIOS, Totals[ikIntro], Totals[ikBriefing], Totals[ikEndGame], Tics, Screens, Different]));
    Writeln(Format('reached: UpdateSound %d, episodes started %d, songs selected %d, games started or loaded %d, quit %d, ' +
      'scenarios that end before the last tic %d, movies given %d',
      [Reached[0], Reached[1], Reached[2], Reached[3], Reached[4], Reached[5], Reached[6]]));
    if not SameText(ParamStr(2), 'nessuno') then
    begin
      Golden.SaveToFile(ParamStr(2));
      Writeln('golden: ', ParamStr(2), ' (', Golden.Count, ' lines)');
    end;
    if Different > 0 then
      Halt(1);
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      Halt(3);
    end;
  end;
end.
