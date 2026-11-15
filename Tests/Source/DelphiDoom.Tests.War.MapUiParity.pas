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
    [TestCase('Pausa', 'map_pause')]
    [TestCase('Addestrare con i bottoni di un edificio', 'map_cmd_train')]
    [TestCase('Costruire con il contadino', 'map_cmd_build')]
    [TestCase('Ordini dai bottoni e dai tasti', 'map_cmd_orders')]
    [TestCase('Municipio, fucina, chiesa e caserma', 'map_cmd_town')]
    [TestCase('Altri comandi: raccogli, ripara, guarigione, minimap, muro, cursori', 'map_cmd_extra')]
    [TestCase('Cursori con la mira sulla mappa', 'map_cursors')]
    [TestCase('Due eserciti: colpi, frecce, morti', 'map_war_melee')]
    [TestCase('Assedio: pietre, esplosioni, fuoco e crollo', 'map_war_siege')]
    [TestCase('Incantesimi degli umani', 'map_spells')]
    [TestCase('Incantesimi degli orchi', 'map_spells_orc')]
    [TestCase('Menu F10: opzioni, obiettivi, ricomincia', 'map_menu')]
    [TestCase('Menu F10: uscire, Menu torna al menu principale', 'map_menu_quit')]
    [TestCase('Menu F10: ricomincia la mappa con le velocita'' di prima', 'map_menu_restart')]
    [TestCase('Trucchi sulla mappa: pannello, effetti, volumi, modi di modifica', 'map_cheats')]
    [TestCase('Vittoria: menu della fine e briefing della mappa dopo', 'map_gameover_win')]
    [TestCase('Sconfitta: Ok e briefing della stessa mappa', 'map_gameover_lose')]
    [TestCase('Fine della demo: Ides of march e ultima mappa', 'map_demo_end')]
    [TestCase('Salto di mappa con Human e Orc', 'map_skip')]
    [TestCase('Dal menu principale a una partita personalizzata e al suo menu F10', 'map_custom_menu')]
    [TestCase('Partita personalizzata sulla palude e sconfitta', 'map_custom_swamp')]
    [TestCase('Partita personalizzata sulla foresta e ricomincia', 'map_custom_forest')]
    [TestCase('Disegno di debug: griglie e caselle che non si passano', 'map_debug')]
    [TestCase('Modi con un clic: aggiungi unita'', pioggia di fuoco, nube, risuscita', 'map_edit')]
    [TestCase('Modi che cambiano il terreno: alberi, muri, strade, rovine', 'map_edit_terrain')]
    [TestCase('Disegno di debug delle unita'' e delle animazioni', 'map_debug_units')]
    [TestCase('Disegno di debug dei testi: riquadri dei glifi e contorni', 'map_debug_font')]
    [TestCase('Disegno di debug delle unita'' vicine e delle celle della griglia', 'map_debug_near')]
    [TestCase('Disegno di debug dei proiettili: riquadri e righe', 'map_debug_projectiles')]
    [TestCase('Disegno di debug del campo di flusso: frecce', 'map_debug_flow')]
    [TestCase('Disegno di debug dell''evitamento: frecce della velocita''', 'map_debug_rvo')]
    procedure DovrebbeDareGliStessiFotogrammiDelC(const AName: string);
    /// <summary>
    ///   Not a test of the suite: with DELPHIDOOM_WAR_RUNSCRIPT (a script) and DELPHIDOOM_WAR_RUNSCRIPT_OUT set it writes the
    ///   hashes of a script, to compare with the C while a difference is looked for; without them it does nothing
    /// </summary>
    [Test]
    procedure DovrebbeScrivereLeImprontedelloScriptDiProva;
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

procedure TTestWarMapUiParity.DovrebbeScrivereLeImprontedelloScriptDiProva;
var
  LGame: TWarUiGame;
  LScript: TStringList;
  LOutput: TStringList;
  LLines: TArray<string>;
  LIndex: Integer;
begin
  if (GetEnvironmentVariable('DELPHIDOOM_WAR_RUNSCRIPT') = '') or
    (GetEnvironmentVariable('DELPHIDOOM_WAR_RUNSCRIPT_OUT') = '') then
    Exit;
  TWarRealData.RequireDataWar;
  LScript := TStringList.Create;
  try
    LScript.LoadFromFile(GetEnvironmentVariable('DELPHIDOOM_WAR_RUNSCRIPT'));
    SetLength(LLines, LScript.Count);
    for LIndex := 0 to LScript.Count - 1 do
      LLines[LIndex] := LScript[LIndex];
    LGame := TWarUiRig.CreateRealMapGame;
    try
      LOutput := TWarUiRig.RunScript(LGame, LLines, nil);
      try
        LOutput.SaveToFile(GetEnvironmentVariable('DELPHIDOOM_WAR_RUNSCRIPT_OUT'));
      finally
        LOutput.Free;
      end;
    finally
      LGame.Free;
    end;
  finally
    LScript.Free;
  end;
  Assert.Pass;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestWarMapUiParity);

end.
