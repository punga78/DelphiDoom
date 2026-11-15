{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - composition root of the interface and the scenes  }
{                                                                              }
{  Port of war1 (acoto87/war1), war_imui.c, war_scenes.c, war_game.c,          }
{  (c) 2019 Alejandro Coto Gutierrez, zlib License (see                        }
{  Libs\War\LICENSE-war1.txt). This is an altered version, not the original.   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Ui.Factory;

interface

uses
  System.SysUtils, DelphiDoom.War.Intf, DelphiDoom.War.Graphics.Intf, DelphiDoom.War.Graphics.Types,
  DelphiDoom.War.Font.Intf, DelphiDoom.War.Campaign.Intf, DelphiDoom.War.Ui.Intf, DelphiDoom.War.Ui.Game;

type
  /// <summary>The only place that knows the concrete classes of the interface and the scenes</summary>
  TWarUiFactory = class
  public
    /// <summary>
    ///   The game of the scenes on a canvas of AWidth x AHeight pixels (320 x 200). The two images are the fonts. The
    ///   audio and the map launcher may be nil. The archive says whether the game is the demo
    /// </summary>
    class function CreateGame(const AArchive: IWarArchive; const ACatalog: IWarCatalog;
      const AGraphics: IWarGraphics; const AMetrics: IWarFontMetrics; const AFontImages: TArray<TWarImage>;
      const ACampaigns: IWarCampaigns; const AAudio: IWarSceneAudio; const AMapLauncher: IWarMapLauncher;
      AWidth, AHeight: Integer): TWarUiGame; static;
    /// <summary>The same on sprites that a fake gives (no archive)</summary>
    class function CreateGameOnSprites(const ASprites: IWarUiSprites; const AMetrics: IWarFontMetrics;
      const AFontImages: TArray<TWarImage>; const ACampaigns: IWarCampaigns; const AAudio: IWarSceneAudio;
      const AMapLauncher: IWarMapLauncher; AIsDemo: Boolean; AWidth, AHeight: Integer): TWarUiGame; static;
  end;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.War.Ui.Input, DelphiDoom.War.Ui.Canvas, DelphiDoom.War.Ui.Imui,
  DelphiDoom.War.Ui.SpriteLoader, DelphiDoom.War.Ui.GameSettings, DelphiDoom.War.Ui.SettingsCheatEffects,
  DelphiDoom.War.Ui.SceneBase, DelphiDoom.War.Ui.SceneManager, DelphiDoom.War.Ui.SceneFactory;

{ TWarUiFactory }

class function TWarUiFactory.CreateGame(const AArchive: IWarArchive; const ACatalog: IWarCatalog;
  const AGraphics: IWarGraphics; const AMetrics: IWarFontMetrics; const AFontImages: TArray<TWarImage>;
  const ACampaigns: IWarCampaigns; const AAudio: IWarSceneAudio; const AMapLauncher: IWarMapLauncher;
  AWidth, AHeight: Integer): TWarUiGame;
begin
  Result := CreateGameOnSprites(TWarUiSpriteLoader.Create(AGraphics, ACatalog), AMetrics, AFontImages, ACampaigns,
    AAudio, AMapLauncher, AArchive.FileType = wftDemo, AWidth, AHeight);
end;

class function TWarUiFactory.CreateGameOnSprites(const ASprites: IWarUiSprites; const AMetrics: IWarFontMetrics;
  const AFontImages: TArray<TWarImage>; const ACampaigns: IWarCampaigns; const AAudio: IWarSceneAudio;
  const AMapLauncher: IWarMapLauncher; AIsDemo: Boolean; AWidth, AHeight: Integer): TWarUiGame;
var
  LInput: TWarUiInput;
  LInputRef: IWarUiInput;
  LSettings: IWarGameSettings;
  LCanvas: TWarUiCanvas;
  LImui: TWarImui;
  LManager: TWarSceneManager;
  LScenes: TWarSceneFactory;
  LServices: TWarSceneServices;
begin
  LInput := TWarUiInput.Create;
  // the first reference counts: without it the object would be freed when a temporary reference goes
  LInputRef := LInput;
  LSettings := TWarGameSettings.Create;
  LCanvas := TWarUiCanvas.Create(AWidth, AHeight, AMetrics, AFontImages);
  try
    LImui := TWarImui.Create(LCanvas, LInputRef, ASprites, AAudio);
    try
      LManager := TWarSceneManager.Create(LSettings, LInput, LCanvas, LImui, AMapLauncher, AIsDemo, AWidth, AHeight);
      try
        LServices.Host := LManager;
        LServices.Input := LInputRef;
        LServices.Imui := LImui;
        LServices.Canvas := LCanvas;
        LServices.Audio := AAudio;
        LServices.Sprites := ASprites;
        LServices.Campaigns := ACampaigns;
        LServices.Effects := TWarSettingsCheatEffects.Create(LSettings, AAudio, AIsDemo);
        LServices.Scenes := nil;
        LScenes := TWarSceneFactory.Create(LServices);
        Result := TWarUiGame.Create(LInput, LCanvas, LImui, LSettings, LManager, LScenes);
      except
        LManager.Free;
        raise;
      end;
    except
      LImui.Free;
      raise;
    end;
  except
    LCanvas.Free;
    raise;
  end;
end;

end.
