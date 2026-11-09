// Issue #168 (S4, Libs\Racing): writes Tests\Data\Racing\racing.golden.txt with the OLD code of Speed Haste.
//
//   RacingGolden.exe <output file>
//
// Build and run: Tools\Verifica\168\Racing\Run-Golden.ps1
program RacingGolden;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  DelphiDoom.Racing.Types,
  DelphiDoom.Tests.Racing.Scenarios,
  OldRacing,
  OldTarget;

var
  LLines: TStringList;
  LTarget: IRacingScenarioTarget;
begin
  try
    if ParamCount < 1 then
      raise Exception.Create('usage: RacingGolden <output file>');
    LLines := TStringList.Create;
    try
      LTarget := TOldRacingTarget.Create;
      TRacingScenarios.Run(LTarget, LLines);
      LLines.WriteBOM := False;
      LLines.SaveToFile(ParamStr(1), TEncoding.ASCII);
      Writeln(LLines.Count, ' lines written to ', ParamStr(1));
    finally
      LTarget := nil;
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
