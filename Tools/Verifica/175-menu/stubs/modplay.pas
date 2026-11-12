unit modplay;
// stub of the harness: SC is the settings record of the original; SetVolumes in the trace
interface
uses g_delphi, r_public_h, protos_h;
var
  SC: SoundCard;
procedure SoundEffect(const n: integer; const variation: integer; const x, y: fixed_t);
procedure SetVolumes(const amusic: integer; const afx: integer);
procedure UpdateSound;
procedure PlaySong(const aname: string; const pattern: integer);
procedure StopMusic;
implementation
uses harness_menu, DelphiDoom.Tests.Greed.MenuScenarios;
procedure SoundEffect(const n: integer; const variation: integer; const x, y: fixed_t); begin end;
procedure SetVolumes(const amusic: integer; const afx: integer);
begin
  HTrace.Add(MENU_TRACE_SET_VOLUMES); HTrace.Add(amusic); HTrace.Add(afx);
end;
// 22 and 23: INTRO_TRACE_UPDATE_SOUND and INTRO_TRACE_BEGIN_INTRO of the scenarios of the intro
procedure UpdateSound; begin HTrace.Add(22); end;
procedure PlaySong(const aname: string; const pattern: integer); begin HTrace.Add(23); end;
procedure StopMusic; begin end;
end.
