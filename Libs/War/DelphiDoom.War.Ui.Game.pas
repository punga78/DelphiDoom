{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the interface and the scenes, assembled           }
{                                                                              }
{  Port of war1 (acoto87/war1), what war_game.c (wg_initGame) puts together    }
{  for the scenes, (c) 2019 Alejandro Coto Gutierrez, zlib License (see        }
{  Libs\War\LICENSE-war1.txt). This is an altered version, not the original.   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Ui.Game;

interface

uses
  System.SysUtils, DelphiDoom.War.Ui.Intf, DelphiDoom.War.Ui.Input, DelphiDoom.War.Ui.Canvas, DelphiDoom.War.Ui.Imui,
  DelphiDoom.War.Ui.SceneManager, DelphiDoom.War.Ui.SceneFactory;

type
  /// <summary>
  ///   The pieces of the game of the scenes, made by TWarUiFactory and freed together: input, canvas, immediate
  ///   interface, the settings, the manager of the scenes and the maker of the scenes
  /// </summary>
  TWarUiGame = class
  strict private
    FInput: TWarUiInput;
    FInputRef: IWarUiInput;
    FCanvas: TWarUiCanvas;
    FImui: TWarImui;
    FSettings: IWarGameSettings;
    FManager: TWarSceneManager;
    FScenes: TWarSceneFactory;
  public
    constructor Create(const AInput: TWarUiInput; const ACanvas: TWarUiCanvas; const AImui: TWarImui;
      const ASettings: IWarGameSettings; const AManager: TWarSceneManager; const AScenes: TWarSceneFactory);
    destructor Destroy; override;
    property Input: TWarUiInput read FInput;
    property Canvas: TWarUiCanvas read FCanvas;
    property Imui: TWarImui read FImui;
    property Settings: IWarGameSettings read FSettings;
    property Manager: TWarSceneManager read FManager;
    property Scenes: TWarSceneFactory read FScenes;
  end;

implementation

{ TWarUiGame }

constructor TWarUiGame.Create(const AInput: TWarUiInput; const ACanvas: TWarUiCanvas; const AImui: TWarImui;
  const ASettings: IWarGameSettings; const AManager: TWarSceneManager; const AScenes: TWarSceneFactory);
begin
  inherited Create;
  FInput := AInput;
  // the input is counted by reference (the interface the imui and the scenes read): this keeps it alive
  FInputRef := AInput;
  FCanvas := ACanvas;
  FImui := AImui;
  FSettings := ASettings;
  FManager := AManager;
  FScenes := AScenes;
end;

destructor TWarUiGame.Destroy;
begin
  // the scene that runs is freed first: it holds services
  FManager.Free;
  FScenes.Free;
  FImui.Free;
  FCanvas.Free;
  FInputRef := nil;
  inherited Destroy;
end;

end.
