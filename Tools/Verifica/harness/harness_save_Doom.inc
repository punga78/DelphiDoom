// TEMPORARY HARNESS: included at the end of the implementation of g_game.pas (Doom and Heretic)

procedure HarnessSaveProc(const ABaseName: string; ASlot: integer);
begin
  G_DoSaveGameInFile(ABaseName + '.dsg');
end;

procedure HarnessLoadProc(const AArgument: string);
begin
  G_LoadGame(AArgument);
end;

procedure HarnessSaveCheck;
begin
  HarnessTick(gametic, leveltime, HarnessSaveProc, HarnessLoadProc);
end;
