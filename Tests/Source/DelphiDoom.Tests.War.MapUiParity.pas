{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the frames of the map                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.MapUiParity;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework;

type
  /// <summary>
  ///   ui.NAME.golden.txt is what the remake in C (src\war1.c whole and original, on the real SDL3.dll: Tools\Verifica\197)
  ///   writes for the script Tools\Verifica\197\scripts\NAME.script: "H n hash" for each frame, the hash being the FNV-1a
  ///   of the 320 x 200 x 4 bytes. Here the scripts enter a map (campaign, custom): the Delphi game must give the same
  ///   hash for EVERY frame. When one differs and the variable DELPHIDOOM_WAR_UI_DUMP is a folder, the trace of the drawing
  ///   calls and the pixels of the last frame are written there, to compare with the C (Confronta-Traccia.ps1, Confronta-Pixel.ps1)
  /// </summary>
  [TestFixture]
  [Category('war')]
  TTestWarMapUiParity = class(TObject)
  private
    procedure Dump(const AName: string; const ALines: TArray<string>);
  public
    [Test]
    [TestCase('Entrata nella mappa degli umani 1', 'map_enter')]
    [TestCase('Mappa ferma con il mouse al centro', 'map_still')]
    [TestCase('Scorrimento della camera', 'map_scroll')]
    [TestCase('Mappe degli orchi e degli umani', 'map_orc')]
    [TestCase('Selezione', 'map_select')]
    [TestCase('Ordini col clic destro', 'map_orders')]
    [TestCase('Partita lunga', 'map_long')]
    procedure DovrebbeDareGliStessiFotogrammiDelC(const AName: string);
  end;

implementation

uses
  DelphiDoom.War.Ui.Game, DelphiDoom.Tests.War.RealData, DelphiDoom.Tests.War.UiRig;

{ TTestWarMapUiParity }

procedure TTestWarMapUiParity.Dump(const AName: string; const ALines: TArray<string>);
var
  LFolder: string;
  LGame: TWarUiGame;
  LTrace: TStringList;
  LOutput: TStringList;
begin
  LFolder := GetEnvironmentVariable('DELPHIDOOM_WAR_UI_DUMP');
  if LFolder = '' then
    Exit;
  LGame := TWarUiRig.CreateRealMapGame;
  LTrace := TStringList.Create;
  try
    LOutput := TWarUiRig.RunScript(LGame, ['trace on'] + ALines + ['rgba ' + IncludeTrailingPathDelimiter(LFolder) + AName
      + '.delphi.rgba'], LTrace);
    LOutput.Free;
    LTrace.SaveToFile(IncludeTrailingPathDelimiter(LFolder) + AName + '.delphi.trace.txt');
  finally
    LTrace.Free;
    LGame.Free;
  end;
end;

procedure TTestWarMapUiParity.DovrebbeDareGliStessiFotogrammiDelC(const AName: string);
var
  LGame: TWarUiGame;
  LGolden: TStringList;
  LOutput: TStringList;
  LScript: TStringList;
  LLines: TArray<string>;
  LIndex: Integer;
  LDifferent: Integer;
  LFirst: string;
begin
  TWarRealData.RequireDataWar;
  LScript := TStringList.Create;
  LGolden := TStringList.Create;
  try
    LScript.LoadFromFile(TWarRealData.RepoPath('Tools\Verifica\197\scripts\' + AName + '.script'));
    LGolden.LoadFromFile(TWarRealData.GoldenPath('ui.' + AName + '.golden.txt'));
    SetLength(LLines, LScript.Count);
    for LIndex := 0 to LScript.Count - 1 do
      LLines[LIndex] := LScript[LIndex];
    LGame := TWarUiRig.CreateRealMapGame;
    try
      LOutput := TWarUiRig.RunScript(LGame, LLines, nil);
      try
        Assert.IsTrue(LGolden.Count > 0, 'Golden vuoto: ' + AName);
        Assert.AreEqual<Integer>(LGolden.Count, LOutput.Count, 'Numero di fotogrammi: ' + AName);
        LDifferent := 0;
        LFirst := '';
        for LIndex := 0 to LGolden.Count - 1 do
          if LGolden[LIndex] <> LOutput[LIndex] then
          begin
            Inc(LDifferent);
            if LFirst = '' then
              LFirst := Format('riga %d: C "%s", Delphi "%s"', [LIndex + 1, LGolden[LIndex], LOutput[LIndex]]);
          end;
        if LDifferent > 0 then
          Dump(AName, LLines);
        Assert.AreEqual(0, LDifferent, Format('Fotogrammi diversi in %s su %d; la prima: %s', [AName, LGolden.Count,
          LFirst]));
      finally
        LOutput.Free;
      end;
    finally
      LGame.Free;
    end;
  finally
    LGolden.Free;
    LScript.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestWarMapUiParity);

end.
