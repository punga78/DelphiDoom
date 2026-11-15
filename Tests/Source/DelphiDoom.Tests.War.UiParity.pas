{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the frames of the scenes             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.UiParity;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework;

type
  /// <summary>
  ///   ui.NAME.golden.txt is what the remake in C (src\war1.c whole and original, on the real SDL3.dll: Tools\Verifica\197,
  ///   Registra-GoldenUi.ps1) writes for the script Tools\Verifica\197\scripts\NAME.script: "H n hash" for each frame,
  ///   the hash being the FNV-1a of the 320 x 200 x 4 bytes. The Delphi game must give the same hash for every frame
  /// </summary>
  [TestFixture]
  [Category('war')]
  TTestWarUiParity = class(TObject)
  private
    procedure CheckScript(const AName: string);
    procedure DumpTrace(const AName: string; const ALines: TArray<string>);
  public
    [Test]
    procedure DovrebbeDareGliStessiFotogrammiDelLogoDellaBlizzard;
    [Test]
    procedure DovrebbeDareGliStessiFotogrammiDelMenuPrincipale;
    [Test]
    procedure DovrebbeDareGliStessiFotogrammiDelMenuDellaCampagna;
    [Test]
    procedure DovrebbeDareGliStessiFotogrammiDellaPartitaPersonalizzata;
    [Test]
    procedure DovrebbeDareGliStessiFotogrammiDelBriefingDegliUmani;
    [Test]
    procedure DovrebbeDareGliStessiFotogrammiDelBriefingDegliOrchi;
    [Test]
    procedure DovrebbeDareGliStessiFotogrammiDelPannelloDeiTrucchi;
    [Test]
    procedure DovrebbeDareGliStessiFotogrammiDelCursoreAPiuPunti;
    [Test]
    procedure DovrebbeDareGliStessiFotogrammiInPausa;
  end;

implementation

uses
  DelphiDoom.War.Ui.Game, DelphiDoom.Tests.War.RealData, DelphiDoom.Tests.War.UiRig;

{ TTestWarUiParity }

procedure TTestWarUiParity.DumpTrace(const AName: string; const ALines: TArray<string>);
var
  LFolder: string;
  LGame: TWarUiGame;
  LTrace: TStringList;
  LOutput: TStringList;
begin
  // when a frame differs: the trace of the drawing calls of the whole script, to compare with the one of the C
  // (Tools\Verifica\197\Confronta-Traccia.ps1), in the folder of the variable DELPHIDOOM_WAR_UI_DUMP if it is set
  LFolder := GetEnvironmentVariable('DELPHIDOOM_WAR_UI_DUMP');
  if LFolder = '' then
    Exit;
  LGame := TWarUiRig.CreateRealGame(nil, nil);
  LTrace := TStringList.Create;
  try
    // and the pixels of the last frame, to compare with the ones of the C (Confronta-Pixel.ps1)
    LOutput := TWarUiRig.RunScript(LGame, ['trace on'] + ALines + ['rgba ' + IncludeTrailingPathDelimiter(LFolder) + AName
      + '.delphi.rgba'], LTrace);
    LOutput.Free;
    LTrace.SaveToFile(IncludeTrailingPathDelimiter(LFolder) + AName + '.delphi.trace.txt');
  finally
    LTrace.Free;
    LGame.Free;
  end;
end;

procedure TTestWarUiParity.CheckScript(const AName: string);
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
    LGame := TWarUiRig.CreateRealGame(nil, nil);
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
          DumpTrace(AName, LLines);
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

procedure TTestWarUiParity.DovrebbeDareGliStessiFotogrammiDelLogoDellaBlizzard;
begin
  CheckScript('blizzard');
end;

procedure TTestWarUiParity.DovrebbeDareGliStessiFotogrammiDelMenuPrincipale;
begin
  CheckScript('menu');
end;

procedure TTestWarUiParity.DovrebbeDareGliStessiFotogrammiDelMenuDellaCampagna;
begin
  CheckScript('singleplayer');
end;

procedure TTestWarUiParity.DovrebbeDareGliStessiFotogrammiDellaPartitaPersonalizzata;
begin
  CheckScript('customgame');
end;

procedure TTestWarUiParity.DovrebbeDareGliStessiFotogrammiDelBriefingDegliUmani;
begin
  CheckScript('briefing_human');
end;

procedure TTestWarUiParity.DovrebbeDareGliStessiFotogrammiDelBriefingDegliOrchi;
begin
  CheckScript('briefing_orc');
end;

procedure TTestWarUiParity.DovrebbeDareGliStessiFotogrammiDelPannelloDeiTrucchi;
begin
  CheckScript('cheats');
end;

procedure TTestWarUiParity.DovrebbeDareGliStessiFotogrammiDelCursoreAPiuPunti;
begin
  CheckScript('cursor');
end;

procedure TTestWarUiParity.DovrebbeDareGliStessiFotogrammiInPausa;
begin
  CheckScript('pause');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestWarUiParity);

end.
