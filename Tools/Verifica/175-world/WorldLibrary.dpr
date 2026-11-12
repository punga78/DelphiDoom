program WorldLibrary;
// Issue #175: the same game of WorldGolden.dpr played by TGreedGame of Libs\Greed, with the same lines. It is what
// the test DelphiDoom.Tests.Greed.WorldParity does (the same runner), as a program: Compila.ps1 -Libreria compares
// its lines with the ones of the original and says the first that differs.
// Usage: WorldLibrary <folder of GREED.BLO> <map> <seed> <turns> <output> [every] [dump turn] [dump file] [all]
{$APPTYPE CONSOLE}
uses
  System.SysUtils,
  System.Classes,
  DelphiDoom.Tests.Greed.WorldRunner;

var
  LRunner: TLibraryWorldRunner;
  LLines, LOld: TStringList;
  LEvery: Integer;

begin
  try
    LEvery := 35;
    if ParamCount >= 6 then
      LEvery := StrToInt(ParamStr(6));
    LRunner := TLibraryWorldRunner.Create(ParamStr(1));
    LLines := TStringList.Create;
    LOld := TStringList.Create;
    try
      if ParamCount >= 8 then
      begin
        LRunner.DumpFrame := StrToInt(ParamStr(7));
        LRunner.DumpFile := ParamStr(8);
      end;
      LRunner.AllFrames := ParamCount >= 9;
      LRunner.Play(StrToInt(ParamStr(2)), StrToInt(ParamStr(3)), StrToInt(ParamStr(4)), LEvery, LLines);
      if FileExists(ParamStr(5)) then
        LOld.LoadFromFile(ParamStr(5));
      LOld.AddStrings(LLines);
      LOld.SaveToFile(ParamStr(5));
    finally
      LOld.Free;
      LLines.Free;
      LRunner.Free;
    end;
  except
    on E: Exception do
    begin
      Writeln(ErrOutput, E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.
