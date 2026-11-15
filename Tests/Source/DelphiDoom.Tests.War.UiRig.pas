{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the game of the scenes on real data  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.UiRig;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.War.Intf, DelphiDoom.War.Graphics.Types, DelphiDoom.War.Ui.Game,
  DelphiDoom.War.Ui.Intf;

type
  /// <summary>
  ///   Makes the game of the scenes from the real DATA.WAR and the PNG of the fonts (the tests that need them are
  ///   ignored if they are not on this machine) and runs the scripts of Tools\Verifica\197 on it
  /// </summary>
  TWarUiRig = class
  public
    /// <summary>The game on the real data; the caller frees it. The audio may be nil</summary>
    class function CreateRealGame(const AAudio: IWarSceneAudio; const AMapLauncher: IWarMapLauncher): TWarUiGame; static;
    /// <summary>
    ///   The same with the maker of the maps of the game on the real data: one generator of random numbers for the game
    ///   (seed 1, the state of the harness of the C), the directions as the C built with gcc has them
    /// </summary>
    class function CreateRealMapGame: TWarUiGame; static;
    /// <summary>The two images of the fonts, from the PNG files</summary>
    class function LoadFontImages: TArray<TWarImage>; static;
    /// <summary>The lines "H n hash" (and the trace, if ATrace is not nil) that a script writes</summary>
    class function RunScript(const AGame: TWarUiGame; const ALines: TArray<string>; const ATrace: TStrings): TStringList;
      static;
  end;

implementation

uses
  DelphiDoom.Png.Provider, DelphiDoom.War.Factory, DelphiDoom.War.Campaign.Catalog, DelphiDoom.War.Ui.Factory,
  DelphiDoom.War.Ui.FontImageLoader, DelphiDoom.War.Ui.ScriptRunner, DelphiDoom.War.Graphics.Intf,
  DelphiDoom.War.Level.Factory, DelphiDoom.War.Map.Factory, DelphiDoom.War.Sound.SeededRandom,
  DelphiDoom.War.MapUi.Launcher, DelphiDoom.Tests.War.RealData;

{ TWarUiRig }

class function TWarUiRig.LoadFontImages: TArray<TWarImage>;
var
  LFont: Integer;
begin
  SetLength(Result, 2);
  for LFont := 0 to 1 do
    Result[LFont] := TWarFontImageLoader.Load(TWarRealData.RequireFont(LFont), TPngProvider.Client);
end;

class function TWarUiRig.CreateRealGame(const AAudio: IWarSceneAudio; const AMapLauncher: IWarMapLauncher): TWarUiGame;
var
  LCatalog: IWarCatalog;
  LArchive: IWarArchive;
begin
  LCatalog := TWarFactory.CreateCatalog;
  LArchive := TWarFactory.OpenFile(TWarRealData.RequireDataWar, LCatalog);
  Result := TWarUiFactory.CreateGame(LArchive, LCatalog, TWarFactory.CreateGraphics(LArchive, LCatalog),
    TWarFactory.CreateFontMetrics, LoadFontImages, TWarCampaigns.Create, AAudio, AMapLauncher, 320, 200);
end;

class function TWarUiRig.CreateRealMapGame: TWarUiGame;
var
  LCatalog: IWarCatalog;
  LArchive: IWarArchive;
  LGraphics: IWarGraphics;
  LLauncher: IWarMapLauncher;
begin
  LCatalog := TWarFactory.CreateCatalog;
  LArchive := TWarFactory.OpenFile(TWarRealData.RequireDataWar, LCatalog);
  LGraphics := TWarFactory.CreateGraphics(LArchive, LCatalog);
  LLauncher := TWarMapLauncher.Create(TWarLevelFactory.CreateLevelLoader(LArchive, LCatalog), LGraphics,
    TWarMapFactory.CreateUnitCatalog, TWarLevelFactory.CreateObjectives, TWarSeededRandom.Create(1), True);
  Result := TWarUiFactory.CreateGame(LArchive, LCatalog, LGraphics, TWarFactory.CreateFontMetrics, LoadFontImages,
    TWarCampaigns.Create, nil, LLauncher, 320, 200);
end;

class function TWarUiRig.RunScript(const AGame: TWarUiGame; const ALines: TArray<string>;
  const ATrace: TStrings): TStringList;
var
  LRunner: TWarUiScriptRunner;
begin
  Result := TStringList.Create;
  try
    LRunner := TWarUiScriptRunner.Create(AGame, Result, ATrace);
    try
      LRunner.Run(ALines);
    finally
      LRunner.Free;
    end;
  except
    Result.Free;
    raise;
  end;
end;

end.
