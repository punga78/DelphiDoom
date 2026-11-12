program FliParity;
{$APPTYPE CONSOLE}
// Harness fuori dal repository: confronta tic per tic i filmati FLI dell'ORIGINALE di xGreed (playfli.pas com'e': DoPlayFLI
// legge il filmato da un file) con TGreedFliPlayer di Libs\Greed sugli stessi filmati e tasti
// (Tests\Source\DelphiDoom.Tests.Greed.FliScenarios). La Wait dell'originale e' lo stub che per ogni tic cattura lo
// schermo e la palette, applica i tasti ed esegue il corpo di INT_TimerISR (stubs\d_ints.pas). Le righe del golden
// sono i valori dell'ORIGINALE.
// Uso: FliParity <cartella con i *.FLI del gioco | sintetico> <golden.txt | nessuno>
uses
  SysUtils, Classes, Generics.Collections,
  g_delphi, d_disk, d_ints, d_ints_h, protos_h, constant, r_public_h, r_render, i_video, d_video, d_font,
  raven, intro, playfli, harness_menu,
  DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf, DelphiDoom.Greed.Canvas, DelphiDoom.Tests.Greed.MenuScenarios,
  DelphiDoom.Tests.Greed.FliScenarios;

var
  Runner: TFliLibraryRunner;
  Golden: TStringList;
  Outcome: TFliOutcome;
  OriginalFrames, LibraryFrames: TList<Cardinal>;
  Different, Scenarios, TotalTics, TotalScreens: Integer;
  Work: string;

procedure Capture;
begin
  Outcome.Pixels := MenuFnv(Outcome.Pixels, viewbuffer, 64000);
  Outcome.Palette := MenuFnv(Outcome.Palette, LastPalette, 768);
  OriginalFrames.Add(MenuFnv(MENU_FNV_START, viewbuffer, 64000));
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

// AFiles: the movies are files of the game, played where they are; otherwise the bytes of the scenario are written
// in the work folder first
function RunOriginal(const scn: TFliScenario; const AFiles: TArray<string>; const AName: string): TFliOutcome;
var
  b, pal: TBytes;
  m: Integer;
  name: string;
  completed: boolean;
begin
  HarnessResetKeys;
  timecount := scn.StartTime;
  pal := TFliScenarios.StartPalette;
  I_SetPalette(@pal[0]);
  b := TMenuScenarios.Background(scn.BackgroundSeed);
  Move(b[0], viewbuffer, 64000);
  HScenario := Default(TMenuScenario);
  HScenario.Keys := scn.Keys;
  HScenario.MaxTics := scn.MaxTics;
  HTics := 0;
  HNextKey := 0;
  Outcome.Pixels := MENU_FNV_START;
  Outcome.Palette := MENU_FNV_START;
  OriginalFrames.Clear;
  completed := false;
  try
    for m := 0 to High(scn.Movies) do
    begin
      if Length(AFiles) > 0 then
        name := AFiles[m]
      else
      begin
        name := Work + '\' + AName + '_' + IntToStr(m) + '.FLI';
        WriteFileBytes(name, scn.Movies[m]);
      end;
      completed := DoPlayFLI(name, scn.Offsets[m]);
    end;
    Capture;
  except
    on EHarnessStop do
      ;
  end;
  Outcome.Tics := HTics;
  // currentfliframe is private in playfli.pas: the frame of the library is checked through the screens
  Outcome.Finish := TFliScenarios.FinishHash(Ord(completed), 0, timecount);
  Result := Outcome;
end;

procedure CompareOne(const scn: TFliScenario; const AFiles: TArray<string>; const AName: string);
var
  original, lib: TFliOutcome;
  i: Integer;
begin
  original := RunOriginal(scn, AFiles, AName);
  LibraryFrames.Clear;
  lib := Runner.Run(scn, LibraryFrames);
  Golden.Add(original.Line(AName));
  Inc(Scenarios);
  Inc(TotalTics, original.Tics);
  Inc(TotalScreens, OriginalFrames.Count);
  if original.Line(AName) <> lib.Line(AName) then
  begin
    Inc(Different);
    Writeln('DIFF original: ', original.Line(AName));
    Writeln('     library:  ', lib.Line(AName));
    if OriginalFrames.Count <> LibraryFrames.Count then
      Writeln(Format('     screens: original %d library %d', [OriginalFrames.Count, LibraryFrames.Count]));
    for i := 0 to OriginalFrames.Count - 1 do
      if (i >= LibraryFrames.Count) or (OriginalFrames[i] <> LibraryFrames[i]) then
      begin
        Writeln(Format('     the first screen that differs is the one before the tic %d', [i + 1]));
        Break;
      end;
  end;
end;

var
  k: Integer;
  name: string;
  bytes: TBytes;
  stream: TFileStream;
begin
  try
    if ParamCount < 2 then
    begin
      Writeln('uso: FliParity <cartella con i *.FLI | sintetico> <golden.txt | nessuno>');
      Halt(2);
    end;
    Work := ExtractFilePath(ParamStr(0)) + 'work';
    ForceDirectories(Work);
    SetCurrentDir(Work);
    CA_InitFromArchive(TMenuScenarios.SyntheticArchive);
    VI_Init;
    HCapture := Capture;
    OriginalFrames := TList<Cardinal>.Create;
    LibraryFrames := TList<Cardinal>.Create;
    Golden := TStringList.Create;
    Runner := TFliLibraryRunner.Create;
    if SameText(ParamStr(1), 'sintetico') then
    begin
      for k := 0 to FLI_SCENARIOS - 1 do
        CompareOne(TFliScenarios.Scenario(k), nil, IntToStr(k));
    end
    else
      for name in FliFiles(ParamStr(1)) do
      begin
        stream := TFileStream.Create(name, fmOpenRead or fmShareDenyNone);
        try
          SetLength(bytes, stream.Size);
          stream.ReadBuffer(bytes[0], stream.Size);
        finally
          stream.Free;
        end;
        CompareOne(TFliScenarios.FileScenario(bytes), TArray<string>.Create(name), UpperCase(ExtractFileName(name)));
      end;
    Writeln(Format('movies or scenarios %d, tics %d, screens compared %d, that differ %d', [Scenarios, TotalTics,
      TotalScreens, Different]));
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
