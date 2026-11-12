{$I xGreed.inc}
program WorldGolden;
// Issue #175: plays one map of Greed with the ORIGINAL game of xGreed (raven.pas, utils.pas, spawn.pas, sprites.pas,
// event.pas, constant.pas, the renderer, display.pas, d_font.pas, d_video.pas, menu.pas, intro.pas, d_disk.pas, net.pas
// as they are) and writes the fingerprints of the whole world, one line every some turns of PlayLoop. Stubs: the
// window and the video (i_video, i_windows), the timer thread (timer), the keyboard and the mouse (d_ints: the
// commands come from a seed), the sound (modplay: written in the fingerprint) and the films (playfli).
// The start is LoadData and startup of intro.pas with nointro, without the configuration file.
// Usage: WorldGolden <folder of GREED.BLO> <map> <seed> <turns> <output> [every] [dump turn] [dump file] [all]
// The lines are appended to the output file.
uses
  SysUtils,
  Classes,
  g_delphi,
  constant,
  d_disk,
  d_font,
  display,
  protos_h,
  r_public_h,
  d_ints,
  d_misc,
  d_video,
  intro,
  i_windows,
  modplay,
  raven,
  r_public,
  utils,
  harness_world;

// LoadMiscData of intro.pas, which is not in its interface: the same lines
procedure HarnessLoadMiscData;
var
  i: integer;
begin
  font1 := CA_CacheLump(CA_GetNamedNum('FONT1'));
  font2 := CA_CacheLump(CA_GetNamedNum('FONT2'));
  font3 := CA_CacheLump(CA_GetNamedNum('FONT3'));
  statusbar[0] := CA_CacheLump(CA_GetNamedNum('STATBAR1'));
  statusbar[1] := CA_CacheLump(CA_GetNamedNum('STATBAR2'));
  statusbar[2] := CA_CacheLump(CA_GetNamedNum('STATBAR3'));
  statusbar[3] := CA_CacheLump(CA_GetNamedNum('STATBAR4'));
  for i := 0 to 9 do
    heart[i] := CA_CacheLump(CA_GetNamedNum('HEART') + i);
  backdrop := malloc(256 * 256);
  for i := 0 to 255 do
    backdroplookup[i] := @backdrop[256 * i];
end;

var
  folder, output, work: string;
  map, seed, episode, i: integer;
  old: TStringList;

begin
  try
    folder := ParamStr(1);
    map := StrToInt(ParamStr(2));
    seed := StrToInt(ParamStr(3));
    HarnessFrames := StrToInt(ParamStr(4));
    output := ParamStr(5);
    if ParamCount >= 6 then
      HarnessEvery := StrToInt(ParamStr(6));
    if ParamCount >= 8 then
    begin
      HarnessDumpFrame := StrToInt(ParamStr(7));
      HarnessDumpFile := ParamStr(8);
    end;
    HarnessAllFrames := ParamCount >= 9;
    HarnessMap := map;
    HarnessSeed := seed;
    HarnessOutput := TStringList.Create;
    HarnessStart(seed);

    // the episode of the map, as the command line of the original would say (-game1, -game2, -game3)
    if map >= 16 then
      episode := 3
    else if map >= 8 then
      episode := 2
    else
      episode := 1;
    GAME1 := episode = 1;
    GAME2 := episode = 2;
    GAME3 := episode = 3;

    // LoadData of intro.pas
    nointro := true;
    nobriefing := true;
    InitDefaults;
    lowresolution := true;
    MAXSCROLL := MAXSCROLL1 div 2;
    BACKDROPHEIGHT := BACKDROPHEIGHT1 div 2;
    SCROLLRATE := SCROLLRATE1 div 2;
    // the archive is opened by its name in the current folder; what the game writes goes to the folder of the work
    work := GetCurrentDir;
    SetCurrentDir(folder);
    CA_InitFile('GREED.BLO');
    SetCurrentDir(work);
    InitSound;
    INT_Setup;
    RF_PreloadGraphics;
    RF_Startup;
    HarnessLoadMiscData;
    VI_Init;

    // startup of intro.pas with nointro
    rndofs := seed;
    newplayer(map, 0, 2);
    try
      maingame;
    except
      // after PlayLoop maingame saves the configuration (M_SaveDefaults) in a file whose name was never set,
      // because the configuration was not loaded: the game is over by then
      on EFCreateError do
        ;
    end;
    // a game that ended inside a turn (the last map) has not written its last state
    if quitgame then
      HarnessNextFrame;

    old := TStringList.Create;
    if FileExists(output) then
      old.LoadFromFile(output);
    for i := 0 to HarnessOutput.Count - 1 do
      old.Add(HarnessOutput[i]);
    old.SaveToFile(output);
    old.Free;
  except
    on E: Exception do
    begin
      Writeln(ErrOutput, E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.
