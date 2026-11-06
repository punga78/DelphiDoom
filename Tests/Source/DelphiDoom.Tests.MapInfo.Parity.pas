{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the UMAPINFO library - parity with the old parser     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MapInfo.Parity;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections, DUnitX.TestFramework;

type
  /// <summary>
  ///   The files *.golden.txt in Tests\Data\MapInfo were written by the old p_umapinfo.pas,
  ///   compiled for Doom, Heretic and Strife and linked with stubs of the engine units, on the
  ///   texts of cases.txt: for each case the warnings, the calls on the episodes and every
  ///   field of the default and of the final maps. The library has to write the same dump (the
  ///   intertexts are cut as the old record cut them: see OldInterText in the corpus)
  /// </summary>
  [TestFixture]
  [Category('mapinfo')]
  TTestMapInfoParity = class(TObject)
  private
    function DataPath(const AFileName: string): string;
    class procedure SplitCases(ALines: TStringList; ACases: TDictionary<string, TStringList>;
      ANames: TList<string>); static;
  public
    [Test]
    [TestCase('doom', 'Doom')]
    [TestCase('heretic', 'Heretic')]
    [TestCase('strife', 'Strife')]
    procedure TestSameDumpAsTheOldParser(const AGame: string);
  end;

implementation

uses
  DelphiDoom.Tests.MapInfo.Corpus;

{ TTestMapInfoParity }

function TTestMapInfoParity.DataPath(const AFileName: string): string;
begin
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\Tests\Data\MapInfo\' + AFileName));
end;

class procedure TTestMapInfoParity.SplitCases(ALines: TStringList;
  ACases: TDictionary<string, TStringList>; ANames: TList<string>);
var
  LIndex: Integer;
  LCurrent: TStringList;
begin
  LCurrent := nil;
  for LIndex := 0 to ALines.Count - 1 do
  begin
    if Copy(ALines[LIndex], 1, 4) = '=== ' then
    begin
      LCurrent := TStringList.Create;
      ACases.Add(Copy(ALines[LIndex], 5, MaxInt), LCurrent);
      ANames.Add(Copy(ALines[LIndex], 5, MaxInt));
    end;
    if Assigned(LCurrent) then
      LCurrent.Add(ALines[LIndex]);
  end;
end;

procedure TTestMapInfoParity.TestSameDumpAsTheOldParser(const AGame: string);
var
  LGame: TMapInfoGame;
  LCorpus: TMapInfoCorpus;
  LActualLines: TStringList;
  LGoldenLines: TStringList;
  LActual: TDictionary<string, TStringList>;
  LGolden: TDictionary<string, TStringList>;
  LActualNames: TList<string>;
  LGoldenNames: TList<string>;
  LName: string;
  LMismatches: string;
  LFirstDetail: string;
  LActualLine: string;
  LCount: Integer;
  LLine: Integer;
  LPair: TPair<string, TStringList>;
begin
  if AGame = 'Doom' then
    LGame := TMapInfoGame.Doom
  else if AGame = 'Heretic' then
    LGame := TMapInfoGame.Heretic
  else
    LGame := TMapInfoGame.Strife;

  LCorpus := TMapInfoCorpus.Create(DataPath('cases.txt'));
  LGoldenLines := TMapInfoCorpus.LoadLines(DataPath(LowerCase(AGame) + '.golden.txt'));
  LActualLines := LCorpus.Dump(LGame);
  LActual := TDictionary<string, TStringList>.Create;
  LGolden := TDictionary<string, TStringList>.Create;
  LActualNames := TList<string>.Create;
  LGoldenNames := TList<string>.Create;
  try
    SplitCases(LActualLines, LActual, LActualNames);
    SplitCases(LGoldenLines, LGolden, LGoldenNames);
    Assert.IsTrue(LGoldenNames.Count > 50, 'the golden file has the cases');
    Assert.AreEqual(LGoldenNames.Count, LActualNames.Count, 'the number of cases');

    LMismatches := '';
    LFirstDetail := '';
    LCount := 0;
    for LName in LGoldenNames do
    begin
      if not LActual.ContainsKey(LName) then
        LActual.Add(LName, TStringList.Create);
      if LActual[LName].Text <> LGolden[LName].Text then
      begin
        Inc(LCount);
        LMismatches := LMismatches + ' ' + LName;
        if LFirstDetail = '' then
          for LLine := 0 to LGolden[LName].Count - 1 do
            if (LLine >= LActual[LName].Count) or (LActual[LName][LLine] <> LGolden[LName][LLine]) then
            begin
              if LLine < LActual[LName].Count then
                LActualLine := LActual[LName][LLine]
              else
                LActualLine := '(missing)';
              LFirstDetail := Format('%s, line %d: expected [%s] but got [%s]', [LName, LLine,
                LGolden[LName][LLine], LActualLine]);
              Break;
            end;
      end;
    end;
    Assert.AreEqual(0, LCount, 'cases that differ from the old parser:' + LMismatches + '; ' + LFirstDetail);
  finally
    for LPair in LActual do
      LPair.Value.Free;
    for LPair in LGolden do
      LPair.Value.Free;
    LGoldenNames.Free;
    LActualNames.Free;
    LGolden.Free;
    LActual.Free;
    LGoldenLines.Free;
    LActualLines.Free;
    LCorpus.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMapInfoParity);

end.
