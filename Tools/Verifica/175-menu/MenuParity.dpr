program MenuParity;
{$APPTYPE CONSOLE}
// Harness fuori dal repository: confronta tic per tic il menu ORIGINALE di xGreed (menu.pas, con d_font.pas, d_video.pas
// e loadscreen di intro.pas) con TGreedMenu di Libs\Greed sugli stessi scenari
// (Tests\Source\DelphiDoom.Tests.Greed.MenuScenarios). L'originale blocca nei suoi cicli: la sua Wait e' uno stub che
// per ogni tic cattura lo schermo e la palette, applica i tasti dello scenario ed esegue il corpo di INT_TimerISR
// (stubs\d_ints.pas). Le righe del golden sono i valori dell'ORIGINALE.
// Uso: MenuParity <cartella con GREED.BLO | sintetico> <golden.txt | nessuno>
uses
  SysUtils, Classes, Generics.Collections,
  g_delphi, d_disk, d_ints, d_ints_h, protos_h, constant, r_public_h, r_render, i_video, d_video, d_font,
  raven, utils, modplay, intro, menu, harness_menu,
  DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf, DelphiDoom.Greed.SaveTypes, DelphiDoom.Greed.Factory,
  DelphiDoom.Greed.Canvas, DelphiDoom.Greed.Menu, DelphiDoom.Tests.Greed.MenuScenarios;

var
  Archive: IGreedArchive;
  Runner: TMenuLibraryRunner;
  Golden: TStringList;
  Outcome: TMenuOutcome;
  OriginalFrames, LibraryFrames: TList<Cardinal>;
  Different: Integer;
  Counts: array[0..3] of Integer;

procedure Capture;
begin
  Outcome.Pixels := MenuFnv(Outcome.Pixels, viewbuffer, 64000);
  Outcome.Palette := MenuFnv(Outcome.Palette, LastPalette, 768);
  OriginalFrames.Add(MenuFnv(MENU_FNV_START, viewbuffer, 64000));
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

function ReadFileBytes(const name: string): TBytes;
var
  s: TFileStream;
begin
  Result := nil;
  if not FileExists(name) then
    Exit;
  s := TFileStream.Create(name, fmOpenRead or fmShareDenyNone);
  try
    SetLength(Result, s.Size);
    if s.Size > 0 then
      s.ReadBuffer(Result[0], s.Size);
  finally
    s.Free;
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

procedure ResetOriginal(const sc: TMenuScenario);
var
  b: TBytes;
  name: string;
begin
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
  modplay.SC.animation := sc.Animation;
  modplay.SC.violence := sc.Violence;
  modplay.SC.musicvol := sc.MusicVol;
  modplay.SC.sfxvol := sc.SfxVol;
  modplay.SC.ambientlight := sc.AmbientLight;
  modplay.SC.screensize := sc.ScreenSize;
  modplay.SC.camdelay := sc.CamDelay;
  DEMO := sc.Demo;
  ASSASSINATOR := false;
  GAME1 := sc.Episode = 1;
  GAME2 := sc.Episode = 2;
  GAME3 := sc.Episode = 3;
  gameloaded := sc.GameLoaded;
  currentViewSize := sc.ScreenSize;
  changelight := 0;
  lighting := 0;
  quitgame := false;
  netmode := false;
  HarnessResetKeys;
  timecount := sc.StartTime;
  fontbasecolor := 0;
  font := nil;
  I_SetPalette(CA_CachePalette(CA_GetNamedNum('palette')));
  b := TMenuScenarios.Background(sc.BackgroundSeed);
  Move(b[0], viewbuffer, 64000);
  for name in TArray<string>.Create('SAVE1.DIR', 'SAVE2.DIR', 'SAVE3.DIR', 'SAVEGAME.DIR') do
    if FileExists(name) then
      DeleteFile(name);
  if sc.HasDirectory then
    WriteFileBytes(DirectoryName(sc), TMenuScenarios.DirectoryBytes(sc));
  HScenario := sc;
  HTics := 0;
  HNextKey := 0;
  HTrace.Clear;
  Outcome.Pixels := MENU_FNV_START;
  Outcome.Palette := MENU_FNV_START;
  OriginalFrames.Clear;
end;

function RunOriginal(const sc: TMenuScenario): TMenuOutcome;
var
  answer: boolean;
  i: integer;
begin
  ResetOriginal(sc);
  answer := false;
  if sc.Entry = meWait then
  begin
    StartWait;
    Capture;
    for i := 0 to High(sc.WaitSteps) do
    begin
      timecount := timecount + sc.WaitSteps[i];
      UpdateWait;
      Capture;
      Inc(HTics);
    end;
    EndWait;
    Capture;
  end
  else
    try
      case sc.Entry of
        meMenu: ShowMenu(sc.Level);
        meQuit: answer := ShowQuit(nil);
        mePause: ShowPause;
        meHelp: ShowHelp;
      end;
      Capture;
    except
      on EHarnessStop do
        ;
    end;
  Outcome.Tics := HTics;
  Outcome.Trace := HTrace.Hash;
  Outcome.Finish := TMenuScenarios.FinishHash(menulevel, menucursor, identity, saveposition, modplay.SC.musicvol, modplay.SC.sfxvol,
    Ord(modplay.SC.violence), Ord(modplay.SC.animation), modplay.SC.ambientlight, modplay.SC.screensize, modplay.SC.camdelay, currentViewSize, changelight,
    lighting, Ord(quitgame), Ord(answer), timecount, ReadFileBytes(DirectoryName(sc)));
  Result := Outcome;
end;

procedure RunAll;
var
  k, i: Integer;
  sc: TMenuScenario;
  original, lib: TMenuOutcome;
  line: string;
begin
  for k := 0 to MENU_SCENARIOS - 1 do
  begin
    sc := TMenuScenarios.Scenario(k);
    original := RunOriginal(sc);
    LibraryFrames.Clear;
    lib := Runner.Run(sc, LibraryFrames);
    line := original.Line(k);
    Golden.Add(line);
    Inc(Counts[0], original.Tics);
    Inc(Counts[1], OriginalFrames.Count);
    Inc(Counts[2], Runner.Host.NewGames + Runner.Host.LoadedGames + Runner.Host.SavedGames);
    if line <> lib.Line(k) then
    begin
      Inc(Different);
      Writeln('DIFF original: ', line);
      Writeln('     library:  ', lib.Line(k));
      if OriginalFrames.Count <> LibraryFrames.Count then
        Writeln(Format('     frames: original %d library %d', [OriginalFrames.Count, LibraryFrames.Count]));
      for i := 0 to OriginalFrames.Count - 1 do
        if (i >= LibraryFrames.Count) or (OriginalFrames[i] <> LibraryFrames[i]) then
        begin
          Writeln(Format('     the first screen that differs is the one before the tic %d', [i + 1]));
          Break;
        end;
    end;
  end;
end;

var
  work: string;
  State: TGreedMenuState;
  Level: Integer;
begin
  try
    if ParamCount < 2 then
    begin
      Writeln('uso: MenuParity <cartella con GREED.BLO | sintetico> <golden.txt | nessuno>');
      Halt(2);
    end;
    if SameText(ParamStr(1), 'sintetico') then
      Archive := TMenuScenarios.SyntheticArchive
    else
      Archive := TGreedFactory.OpenArchiveFile(IncludeTrailingPathDelimiter(ParamStr(1)) + 'GREED.BLO');
    // the original writes SAVEn.DIR in the current folder
    work := ExtractFilePath(ParamStr(0)) + 'work';
    ForceDirectories(work);
    SetCurrentDir(work);
    CA_InitFromArchive(Archive);
    VI_Init;
    HCapture := Capture;
    OriginalFrames := TList<Cardinal>.Create;
    LibraryFrames := TList<Cardinal>.Create;
    Golden := TStringList.Create;
    Runner := TMenuLibraryRunner.Create(Archive);
    RunAll;
    Writeln(Format('scenarios %d, tics %d, screens compared %d, games started/loaded/saved %d, scenarios that differ %d',
      [MENU_SCENARIOS, Counts[0], Counts[1], Counts[2], Different]));
    Write('states of the menu met:');
    for State := Low(TGreedMenuState) to High(TGreedMenuState) do
      if State in Runner.StatesSeen then
        Write(' ', Ord(State));
    Write('; levels:');
    for Level := 0 to GREED_MENU_LEVELS - 1 do
      if Level in Runner.LevelsSeen then
        Write(' ', Level);
    Writeln;
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
