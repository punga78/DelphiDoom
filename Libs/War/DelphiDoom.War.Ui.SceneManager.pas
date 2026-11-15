{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the scene that is running and its transitions     }
{                                                                              }
{  Port of war1 (acoto87/war1), war_game.c (wg_beginFrame, wg_setNextScene,    }
{  wg_setNextMap, wg_updateGame, wg_renderGame, wg_beginInputFrame), (c) 2019  }
{  Alejandro Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt).     }
{  This is an altered version, not the original.                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Ui.SceneManager;

{$R-}
{$Q-}

interface

uses
  System.SysUtils, System.Generics.Defaults, DelphiDoom.War.Ui.Types, DelphiDoom.War.Ui.Intf, DelphiDoom.War.Ui.Input,
  DelphiDoom.War.Ui.Canvas, DelphiDoom.War.Ui.Imui;

type
  /// <summary>
  ///   The loop of the game for the scenes: time, pause (Ctrl+P), the change of scene after the pause of its transition
  ///   (nothing is drawn but black while it lasts, and the cursor is not drawn either) and the order of the frame:
  ///   imui_begin, the scene, imui_end. Not counted by reference (the scenes hold it as their host and the owner frees it).
  ///   Defects of the original kept: a map requested together with a scene is entered after it, the request of the
  ///   scene is not cancelled; time is a Double that adds the Single delta of each frame
  /// </summary>
  TWarSceneManager = class(TSingletonImplementation, IWarSceneHost)
  strict private
    type
      TMapRequestKind = (mrkNone, mrkCampaign, mrkCustom);
  strict private
    FSettings: IWarGameSettings;
    FInput: TWarUiInput;
    FCanvas: TWarUiCanvas;
    FImui: TWarImui;
    FMapLauncher: IWarMapLauncher;
    FScene: IWarScene;
    FNextScene: IWarScene;
    FMapKind: TMapRequestKind;
    FMapType: Integer;
    FMapIndex: Integer;
    FPlayerRace: Integer;
    FEnemyRace: Integer;
    FRealTime: Double;
    FRealDeltaTime: Single;
    FGameTime: Double;
    FGameDeltaTime: Single;
    FTransitionEndRealTime: Double;
    FFrameCount: Integer;
    FPaused: Boolean;
    FIsDemo: Boolean;
    FQuitRequested: Boolean;
    FTextInputActive: Boolean;
    FOriginalWidth: Integer;
    FOriginalHeight: Integer;
    procedure LeaveCurrent;
  public
    /// <summary>The scenes are released first: they hold this manager (not counted) as their host</summary>
    destructor Destroy; override;
    /// <summary>The input, canvas and imui are not owned. The map launcher may be nil: a map is then an empty screen</summary>
    constructor Create(const ASettings: IWarGameSettings; const AInput: TWarUiInput; const ACanvas: TWarUiCanvas;
      const AImui: TWarImui; const AMapLauncher: IWarMapLauncher; AIsDemo: Boolean; AOriginalWidth,
      AOriginalHeight: Integer);
    /// <summary>
    ///   wg_beginFrame with the time of the frame: the real time moves, the time of the game moves unless the game is
    ///   paused
    /// </summary>
    procedure BeginFrame(ADeltaTime: Single);
    /// <summary>wg_updateGame</summary>
    procedure UpdateGame;
    /// <summary>wg_renderGame</summary>
    procedure RenderGame;
    /// <summary>The end of a frame: the count of frames goes on</summary>
    procedure EndFrame;
    /// <summary>One whole frame: BeginFrame, UpdateGame, RenderGame, EndFrame (the input of the frame is cleared by BeginInputFrame, after)</summary>
    procedure RunFrame(ADeltaTime: Single);
    /// <summary>wg_beginInputFrame</summary>
    procedure BeginInputFrame;
    /// <summary>The characters typed, to the scene that is running (SDL_EVENT_TEXT_INPUT)</summary>
    procedure HandleTextInput(const AText: AnsiString);
    /// <summary>wg_setNextScene as a first scene: the transition has the delay given</summary>
    procedure SetNextScene(const AScene: IWarScene; ATransitionDelay: Single);
    procedure SetNextCampaignMap(AMapType: Integer; ATransitionDelay: Single);
    procedure SetNextCustomMap(AMapIndex, APlayerRace, AEnemyRace: Integer; ATransitionDelay: Single);
    procedure SetTextInputActive(AActive: Boolean);
    procedure RequestQuit;
    function GetRealTime: Double;
    function GetRealDeltaTime: Single;
    function GetGlobalSpeed: Single;
    function GetOriginalWidth: Integer;
    function GetOriginalHeight: Integer;
    function GetIsDemo: Boolean;
    property Scene: IWarScene read FScene;
    property RealTime: Double read GetRealTime;
    property GameTime: Double read FGameTime;
    property GameDeltaTime: Single read FGameDeltaTime;
    property FrameCount: Integer read FFrameCount;
    property Paused: Boolean read FPaused;
    property QuitRequested: Boolean read FQuitRequested;
    property TextInputActive: Boolean read FTextInputActive;
    property TransitionEndRealTime: Double read FTransitionEndRealTime;
  end;

implementation

{ TWarSceneManager }

constructor TWarSceneManager.Create(const ASettings: IWarGameSettings; const AInput: TWarUiInput;
  const ACanvas: TWarUiCanvas; const AImui: TWarImui; const AMapLauncher: IWarMapLauncher; AIsDemo: Boolean;
  AOriginalWidth, AOriginalHeight: Integer);
begin
  inherited Create;
  FSettings := ASettings;
  FInput := AInput;
  FCanvas := ACanvas;
  FImui := AImui;
  FMapLauncher := AMapLauncher;
  FIsDemo := AIsDemo;
  FOriginalWidth := AOriginalWidth;
  FOriginalHeight := AOriginalHeight;
end;

destructor TWarSceneManager.Destroy;
begin
  FScene := nil;
  FNextScene := nil;
  inherited Destroy;
end;

function TWarSceneManager.GetRealTime: Double;
begin
  Result := FRealTime;
end;

function TWarSceneManager.GetRealDeltaTime: Single;
begin
  Result := FRealDeltaTime;
end;

function TWarSceneManager.GetGlobalSpeed: Single;
begin
  Result := FSettings.GlobalSpeed;
end;

function TWarSceneManager.GetOriginalWidth: Integer;
begin
  Result := FOriginalWidth;
end;

function TWarSceneManager.GetOriginalHeight: Integer;
begin
  Result := FOriginalHeight;
end;

function TWarSceneManager.GetIsDemo: Boolean;
begin
  Result := FIsDemo;
end;

procedure TWarSceneManager.SetTextInputActive(AActive: Boolean);
begin
  FTextInputActive := AActive;
end;

procedure TWarSceneManager.RequestQuit;
begin
  FQuitRequested := True;
end;

procedure TWarSceneManager.SetNextScene(const AScene: IWarScene; ATransitionDelay: Single);
begin
  FNextScene := AScene;
  FTransitionEndRealTime := FRealTime + ATransitionDelay;
end;

procedure TWarSceneManager.SetNextCampaignMap(AMapType: Integer; ATransitionDelay: Single);
begin
  FMapKind := mrkCampaign;
  FMapType := AMapType;
  FTransitionEndRealTime := FRealTime + ATransitionDelay;
end;

procedure TWarSceneManager.SetNextCustomMap(AMapIndex, APlayerRace, AEnemyRace: Integer; ATransitionDelay: Single);
begin
  FMapKind := mrkCustom;
  FMapIndex := AMapIndex;
  FPlayerRace := APlayerRace;
  FEnemyRace := AEnemyRace;
  FTransitionEndRealTime := FRealTime + ATransitionDelay;
end;

procedure TWarSceneManager.BeginFrame(ADeltaTime: Single);
begin
  FRealDeltaTime := ADeltaTime;
  FRealTime := FRealTime + FRealDeltaTime;
  if FPaused then
    FGameDeltaTime := 0
  else
  begin
    FGameDeltaTime := FRealDeltaTime * FSettings.GlobalSpeed;
    FGameTime := FGameTime + FGameDeltaTime;
  end;
end;

procedure TWarSceneManager.LeaveCurrent;
begin
  if Assigned(FScene) then
    FScene.Leave;
  FScene := nil;
end;

procedure TWarSceneManager.UpdateGame;
begin
  if FInput.IsKeyHeld(wkCtrl) and (not FInput.IsKeyHeld(wkShift)) and FInput.IsKeyJustReleased(wkP) then
    FPaused := not FPaused;
  if FPaused then
    Exit;
  if Assigned(FNextScene) then
  begin
    FSettings.AudioEnabled := False;
    LeaveCurrent;
    FScene := FNextScene;
    FNextScene := nil;
    FScene.Enter;
    FSettings.AudioEnabled := True;
  end
  else if FMapKind <> mrkNone then
  begin
    FSettings.AudioEnabled := False;
    LeaveCurrent;
    if Assigned(FMapLauncher) then
    begin
      if FMapKind = mrkCampaign then
        FScene := FMapLauncher.CreateCampaignMap(FMapType)
      else
        FScene := FMapLauncher.CreateCustomMap(FMapIndex, FPlayerRace, FEnemyRace);
      FScene.Enter;
    end;
    FMapKind := mrkNone;
    FSettings.AudioEnabled := True;
  end;
  if FRealTime < FTransitionEndRealTime then
    Exit;
  if Assigned(FScene) then
    FScene.Update;
end;

procedure TWarSceneManager.RenderGame;
begin
  FCanvas.Clear;
  // nothing is drawn while it is changing, not even the cursor
  if FRealTime < FTransitionEndRealTime then
    Exit;
  FCanvas.ResetTransform;
  FImui.GameFrame := FFrameCount;
  FImui.Start;
  if Assigned(FScene) then
    FScene.Render;
  FImui.Finish;
end;

procedure TWarSceneManager.EndFrame;
begin
  Inc(FFrameCount);
end;

procedure TWarSceneManager.RunFrame(ADeltaTime: Single);
begin
  BeginFrame(ADeltaTime);
  UpdateGame;
  RenderGame;
  EndFrame;
end;

procedure TWarSceneManager.BeginInputFrame;
begin
  FInput.BeginFrame;
end;

procedure TWarSceneManager.HandleTextInput(const AText: AnsiString);
begin
  if Assigned(FScene) then
    FScene.HandleTextInput(AText);
end;

end.
