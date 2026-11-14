{******************************************************************************}
{                                                                              }
{  Speed32: Speed Haste (Noriaworks 1995), the source port GLSpeed of Jim      }
{  Valavanis, in the class system of DelphiDoom. For now a program that        }
{  translates SPEEDH.JCL in memory, lists what it makes and runs a race of     }
{  cars of the computer on one of its tracks with the racing library: no       }
{  window and no engine yet (the game itself is the S5 of the issue 168)       }
{                                                                              }
{  Usage:  Speed32 [-jcl <file or folder>] [-list] [-level <1..8>] [-laps <n>] }
{                  [-cars <n>] [-tics <n>]                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program Speed32;

{$APPTYPE CONSOLE}

{$R 'Speed32_Icon.res' 'Speed32_Icon.rc'}

uses
  System.SysUtils,
  DelphiDoom.CommandLine.Intf,
  DelphiDoom.CommandLine.ProgramFactory,
  System.Classes,
  System.IOUtils,
  DelphiDoom.Logging.Intf,
  DelphiDoom.GameData.Intf,
  DelphiDoom.Speed.Types in '..\Libs\Speed\DelphiDoom.Speed.Types.pas',
  DelphiDoom.Speed.Intf in '..\Libs\Speed\DelphiDoom.Speed.Intf.pas',
  DelphiDoom.Speed.RaceSimulation in 'DelphiDoom.Speed.RaceSimulation.pas',
  DelphiDoom.Speed.Composition in 'DelphiDoom.Speed.Composition.pas';

procedure ShowUsage;
begin
  Writeln('Speed32 [-jcl <file or folder>] [-list] [-level <1..8>] [-laps <n>] [-cars <n>] [-tics <n>]');
  Writeln('  -jcl    SPEEDH.JCL, or the folder that has it (default the current folder, then bin\Speed)');
  Writeln('  -list   write the lumps of the translated WAD and the models, and stop');
  Writeln('  -level  the track of the race, E1M1 to E1M8 (default 1)');
  Writeln('  -laps   the laps of the race (default 2)');
  Writeln('  -cars   the cars of the grid (default 8, the starting positions of the track limit it)');
  Writeln('  -tics   the longest race in tics, 35 tics are one second (default 20000)');
end;

function FindJcl(const AArgument: string): string;
var
  LCandidates: TArray<string>;
  LCandidate: string;
begin
  if AArgument <> '' then
  begin
    if TDirectory.Exists(AArgument) then
      Exit(TPath.Combine(AArgument, 'SPEEDH.JCL'));
    Exit(AArgument);
  end;
  LCandidates := ['SPEEDH.JCL', 'bin\Speed\SPEEDH.JCL', '..\bin\Speed\SPEEDH.JCL'];
  for LCandidate in LCandidates do
    if TFile.Exists(LCandidate) then
      Exit(LCandidate);
  Result := 'SPEEDH.JCL';
end;

var
  LJcl: string;
  LList: Boolean;
  LIndex: Integer;
  LArgument: string;
  LCursor: ICommandLineCursor;
  LOptions: TSpeedRaceOptions;
  LWad: IGameWadComposer;
  LLog: ILog;
  LLines: TStringList;
  LPakEntries: TArray<TSpeedPakEntry>;
  LSimulation: TSpeedRaceSimulation;

begin
  try
    LJcl := '';
    LList := False;
    LOptions.Level := 1;
    LOptions.Laps := 2;
    LOptions.CarCount := 8;
    LOptions.MaxTics := 20000;
    LCursor := TProgramCommandLineFactory.CreateCursor(TProgramCommandLineFactory.CreateProcessCommandLine);
    while LCursor.Next(LArgument) do
    begin
      if (LArgument = '-jcl') and (LCursor.Remaining >= 1) then
        LJcl := LCursor.Value
      else if LArgument = '-list' then
        LList := True
      else if (LArgument = '-level') and (LCursor.Remaining >= 1) then
        LOptions.Level := StrToInt(LCursor.Value)
      else if (LArgument = '-laps') and (LCursor.Remaining >= 1) then
        LOptions.Laps := StrToInt(LCursor.Value)
      else if (LArgument = '-cars') and (LCursor.Remaining >= 1) then
        LOptions.CarCount := StrToInt(LCursor.Value)
      else if (LArgument = '-tics') and (LCursor.Remaining >= 1) then
        LOptions.MaxTics := StrToInt(LCursor.Value)
      else
      begin
        ShowUsage;
        Halt(1);
      end;
    end;
    LJcl := FindJcl(LJcl);
    Writeln('Translating ', LJcl, ' ...');
    LLog := TSpeedComposition.CreateConsoleLog;
    LWad := TSpeedComposition.TranslateGame(LJcl, LLog, LPakEntries);
    Writeln(LWad.Count, ' lumps, ', Length(LPakEntries), ' models');
    if LList then
    begin
      for LIndex := 0 to LWad.Count - 1 do
        Writeln(Format('%5d %-8s %d', [LIndex, LWad.LumpNames[LIndex], Length(LWad.LumpData[LIndex])]));
      for LIndex := 0 to High(LPakEntries) do
        Writeln(Format('model %-24s at %d, %d bytes', [LPakEntries[LIndex].Name, LPakEntries[LIndex].Position,
          LPakEntries[LIndex].Size]));
      Exit;
    end;
    LLines := TStringList.Create;
    LSimulation := TSpeedComposition.CreateRaceSimulation(LWad);
    try
      if not LSimulation.Run(LOptions, LLines) then
        ExitCode := 2;
      Writeln(LLines.Text);
    finally
      LSimulation.Free;
      LLines.Free;
    end;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
