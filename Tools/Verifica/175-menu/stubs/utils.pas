unit utils;
// stub of the harness: the calls of the menu to the game in the trace
interface
uses g_delphi, r_public_h;
var
  primaries: array[0..3] of integer;
  secondaries: array[0..13] of integer;
  pcount: array[0..1] of integer;
  scount: array[0..6] of integer;
procedure ChangeViewSize(const MakeLarger: boolean);
procedure SaveGame(const n: integer);
procedure LoadGame(const n: integer);
procedure newplayer(const map: integer; chartype: integer; const difficulty: integer);
implementation
uses raven, harness_menu, DelphiDoom.Tests.Greed.MenuScenarios;
procedure ChangeViewSize(const MakeLarger: boolean);
begin
  if MakeLarger then inc(currentViewSize) else dec(currentViewSize);
end;
procedure SaveGame(const n: integer);
begin
  HTrace.Add(MENU_TRACE_SAVE_GAME); HTrace.Add(n);
end;
procedure LoadGame(const n: integer);
begin
  HTrace.Add(MENU_TRACE_LOAD_GAME); HTrace.Add(n);
end;
procedure newplayer(const map: integer; chartype: integer; const difficulty: integer);
begin
  HTrace.Add(MENU_TRACE_NEW_GAME); HTrace.Add(map); HTrace.Add(chartype); HTrace.Add(difficulty);
end;
end.
