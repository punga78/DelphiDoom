{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - what the scenes have in common                    }
{                                                                              }
{  Port of war1 (acoto87/war1), war_scenes.c (wsc_updateScene, wsc_renderScene,}
{  wsc_leaveScene), (c) 2019 Alejandro Coto Gutierrez, zlib License (see       }
{  Libs\War\LICENSE-war1.txt). This is an altered version, not the original.   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Ui.SceneBase;

interface

uses
  System.SysUtils, DelphiDoom.War.Campaign.Intf, DelphiDoom.War.Ui.Types, DelphiDoom.War.Ui.Intf,
  DelphiDoom.War.Ui.Canvas, DelphiDoom.War.Ui.Imui, DelphiDoom.War.Ui.Animations, DelphiDoom.War.Ui.CheatsPanel;

type
  /// <summary>
  ///   What a scene is given: the game that runs it, the input, the immediate interface and its canvas, the audio
  ///   (may be nil), the sprites for its animations, the table of the campaigns, the effects of the cheats and the
  ///   factory of the scenes it starts
  /// </summary>
  TWarSceneServices = record
    Host: IWarSceneHost;
    Input: IWarUiInput;
    Imui: TWarImui;
    Canvas: TWarUiCanvas;
    Audio: IWarSceneAudio;
    Sprites: IWarUiSprites;
    Campaigns: IWarCampaigns;
    Effects: IWarCheatEffects;
    Scenes: IWarSceneFactory;
  end;

  /// <summary>
  ///   The order of wsc_updateScene and wsc_renderScene. A scene with no update function of its own (the main menu)
  ///   updates the cheat panel and the animations; the others do what their update says and nothing else. The render is
  ///   the scene, the animations (the entity of the scene), the overlay of the scene and the cheat panel. The retained
  ///   entities of the interface (wui_updateUIButtons, wui_renderUIEntities) are empty in every scene: the scenes draw
  ///   with imui only
  /// </summary>
  TWarSceneBase = class(TInterfacedObject, IWarScene)
  strict private
    FServices: TWarSceneServices;
    FPanel: TWarCheatsPanel;
    FAnimations: TWarUiAnimations;
  strict protected
    procedure DoEnter; virtual;
    /// <summary>The default is wsc_updateScene without an update function: the cheat panel, then the animations</summary>
    procedure DoUpdate; virtual;
    procedure DoRender; virtual;
    procedure DoRenderOverlay; virtual;
    property Services: TWarSceneServices read FServices;
    property Panel: TWarCheatsPanel read FPanel;
    property Animations: TWarUiAnimations read FAnimations;
  public
    constructor Create(const AServices: TWarSceneServices);
    destructor Destroy; override;
    function GetSceneType: TWarSceneType; virtual; abstract;
    procedure Enter;
    procedure Update;
    procedure Render;
    procedure Leave; virtual;
    procedure HandleTextInput(const AText: AnsiString);
    /// <summary>The cheat panel of the scene (enabled only by the scenes that create it)</summary>
    property CheatsPanel: TWarCheatsPanel read FPanel;
    /// <summary>The animations of the scene</summary>
    property SceneAnimations: TWarUiAnimations read FAnimations;
  end;

implementation

{ TWarSceneBase }

constructor TWarSceneBase.Create(const AServices: TWarSceneServices);
begin
  inherited Create;
  FServices := AServices;
  FPanel := TWarCheatsPanel.Create(AServices.Host, AServices.Input, AServices.Imui, AServices.Canvas,
    AServices.Effects);
  FAnimations := TWarUiAnimations.Create;
end;

destructor TWarSceneBase.Destroy;
begin
  FAnimations.Free;
  FPanel.Free;
  inherited Destroy;
end;

procedure TWarSceneBase.DoEnter;
begin
end;

procedure TWarSceneBase.DoUpdate;
begin
  FPanel.Update;
  FAnimations.Update(True, FServices.Host.RealDeltaTime, FServices.Host.GlobalSpeed, 0);
end;

procedure TWarSceneBase.DoRender;
begin
end;

procedure TWarSceneBase.DoRenderOverlay;
begin
end;

procedure TWarSceneBase.Enter;
begin
  DoEnter;
end;

procedure TWarSceneBase.Update;
begin
  DoUpdate;
end;

procedure TWarSceneBase.Render;
begin
  DoRender;
  // the entity of the animations: wr_save, renderAnimation, wr_restore
  FServices.Canvas.Transform.Save;
  FAnimations.Render(FServices.Canvas.Transform);
  FServices.Canvas.Transform.Restore;
  DoRenderOverlay;
  FPanel.Render;
end;

procedure TWarSceneBase.Leave;
begin
end;

procedure TWarSceneBase.HandleTextInput(const AText: AnsiString);
begin
  FPanel.AppendTextInput(AText);
end;

end.
