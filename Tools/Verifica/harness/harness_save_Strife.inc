// TEMPORARY HARNESS: included at the end of the implementation of Strife\g_game.pas
// A Strife savegame is a directory: G_DoSaveGame(path) writes <path>\<gamemap> and <path>\current.
// -hload takes the path of the map file (e.g. hsave_lt_1000\2).

procedure HarnessDoSave(const APath: string);
begin
  G_DoSaveGame(APath);
end;

procedure HarnessSaveProc(const ABaseName: string; ASlot: integer);
begin
  HarnessSaveDirectory('h' + ABaseName, HarnessDoSave);
end;

procedure HarnessLoadProc(const AArgument: string);
begin
  loadpath := AArgument;
  gameaction := ga_loadgame;
end;

procedure HarnessSaveCheck;
begin
  HarnessTick(gametic, leveltime, HarnessSaveProc, HarnessLoadProc);
end;
