{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the dynamic lights library - parity with the old code }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.DynLights.Parity;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections, DUnitX.TestFramework;

type
  /// <summary>
  ///   The files *.golden.txt in Tests\Data\DynLights were written by the old r_dynlights.pas,
  ///   compiled for the OpenGL and for the software renderer and linked with stubs of the engine
  ///   units, on the texts of cases.txt: for each case the output and the warnings, the lights
  ///   with every field (floats as their bits), the states they were bound to and the animation
  ///   of every light at the given tics. The library has to write the same dump
  /// </summary>
  [TestFixture]
  [Category('dynlights')]
  TTestDynLightsParity = class(TObject)
  private
    function DataPath(const AFileName: string): string;
    class procedure SplitCases(ALines: TStringList; ACases: TDictionary<string, TStringList>;
      ANames: TList<string>); static;
  public
    [Test]
    [TestCase('opengl', 'opengl,128')]
    [TestCase('software', 'software,1')]
    procedure TestSameDumpAsTheOldCode(const AName: string; ACoefficient: Integer);
  end;

implementation

uses
  DelphiDoom.Tests.DynLights.Corpus;

{ TTestDynLightsParity }

function TTestDynLightsParity.DataPath(const AFileName: string): string;
begin
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\Tests\Data\DynLights\' + AFileName));
end;

class procedure TTestDynLightsParity.SplitCases(ALines: TStringList;
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

procedure TTestDynLightsParity.TestSameDumpAsTheOldCode(const AName: string; ACoefficient: Integer);
var
  LCorpus: TDynLightCorpus;
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
  LCorpus := TDynLightCorpus.Create(DataPath('cases.txt'));
  LGoldenLines := TDynLightCorpus.LoadLines(DataPath(AName + '.golden.txt'));
  LActualLines := LCorpus.Dump(ACoefficient);
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
    Assert.AreEqual(0, LCount, 'cases that differ from the old code:' + LMismatches + '; ' + LFirstDetail);
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
  TDUnitX.RegisterTestFixture(TTestDynLightsParity);

end.
