// TEMPORARY HARNESS: included at the end of the implementation of Hexen\g_game.pas
// A Hexen savegame is a slot: the real path (ga_savegame -> G_DoSaveGame -> SV_SaveGame) writes the
// files hex<slot>00.hxs, hex<slot><map>.hxs ... under HEXNDATA. -hload takes the slot number.

procedure HarnessSaveProc(const ABaseName: string; ASlot: integer);
begin
  savegameslot := ASlot;
  savedescription := 'harness';
  gameaction := ga_savegame;
end;

procedure HarnessLoadProc(const AArgument: string);
begin
  G_LoadGame(HarnessToInteger(AArgument));
end;

procedure HarnessSaveCheck;
begin
  HarnessTick(gametic, leveltime, HarnessSaveProc, HarnessLoadProc);
end;
