{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the scene of the main menu                        }
{                                                                              }
{  Port of war1 (acoto87/war1), war_scene_menu.c, (c) 2019 Alejandro Coto      }
{  Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an altered  }
{  version, not the original.                                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Ui.SceneMainMenu;

interface

uses
  System.SysUtils, DelphiDoom.War.Level.Types, DelphiDoom.War.Campaign.Types, DelphiDoom.War.Text.Types,
  DelphiDoom.War.Ui.Types, DelphiDoom.War.Ui.Intf, DelphiDoom.War.Ui.SceneBase;

type
  /// <summary>
  ///   The main menu: three panels (the main one, the single player one and the custom game one), drawn with imui. The
  ///   buttons "Load existing game" and "Replay introduction" do nothing (as in the original). The main menu has no
  ///   update of its own: the cheat panel and the animations are updated. Defect of the original kept: with the cheat
  ///   panel open the hotkeys of the buttons still work (the original only turns them off in a map)
  /// </summary>
  TWarSceneMainMenu = class(TWarSceneBase)
  strict private
    FMenuPanel: TWarMenuPanel;
    FYourRace: TWarRace;
    FEnemyRace: TWarRace;
    FCustomMap: Integer;
    function RaceText(ARace: TWarRace): AnsiString;
    function MapText(AMap: Integer): AnsiString;
    function MenuButton(const AText: AnsiString; AX, AY: Single; AHotKey: TWarKey; ASmall: Boolean): TWarUiTextButtonArgs;
    function ArrowButton(AX, AY: Single; ARight: Boolean): TWarUiImageButtonArgs;
    procedure Caption(const AId, AText: AnsiString; AX, AY, AWidth: Single; AAlign: TWarTextAlignment);
    procedure RenderMain;
    procedure RenderSinglePlayer;
    procedure RenderCustomGame;
    procedure StartCampaign(ARace: TWarRace; AMapType: Integer);
  strict protected
    procedure DoEnter; override;
    procedure DoRender; override;
  public
    function GetSceneType: TWarSceneType; override;
    property MenuPanel: TWarMenuPanel read FMenuPanel;
    property YourRace: TWarRace read FYourRace;
    property EnemyRace: TWarRace read FEnemyRace;
    property CustomMap: Integer read FCustomMap;
  end;

implementation

{ TWarSceneMainMenu }

function TWarSceneMainMenu.GetSceneType: TWarSceneType;
begin
  Result := wstMainMenu;
end;

function TWarSceneMainMenu.RaceText(ARace: TWarRace): AnsiString;
begin
  case ARace of
    wraNeutral: Result := 'Random';
    wraHumans: Result := 'Human';
    wraOrcs: Result := 'Orc';
  else
    Result := '';
  end;
end;

function TWarSceneMainMenu.MapText(AMap: Integer): AnsiString;
const
  // 147..153 forest 1..7, 154..155 swamp 6, 7, 156..160 swamp 1..5, 161..167 dungeon 1..7, then the same with ".1"
  SWAMP_NUMBERS: array[0..6] of Integer = (6, 7, 1, 2, 3, 4, 5);
var
  LOffset: Integer;
  LSuffix: AnsiString;
begin
  Result := '';
  if (AMap < 147) or (AMap > 188) then
    Exit;
  LOffset := AMap - 147;
  LSuffix := '';
  if LOffset >= 21 then
  begin
    Dec(LOffset, 21);
    LSuffix := '.1';
  end;
  if LOffset < 7 then
    Result := AnsiString(Format('Forest %d', [LOffset + 1]))
  else if LOffset < 14 then
    Result := AnsiString(Format('Swamp %d', [SWAMP_NUMBERS[LOffset - 7]]))
  else
    Result := AnsiString(Format('Dungeon %d', [LOffset - 14 + 1]));
  Result := Result + LSuffix;
end;

function TWarSceneMainMenu.MenuButton(const AText: AnsiString; AX, AY: Single; AHotKey: TWarKey;
  ASmall: Boolean): TWarUiTextButtonArgs;
begin
  Result := TWarUiTextButtonArgs.Default;
  Result.FontIndex := 1;
  Result.Text := AText;
  if ASmall then
  begin
    Result.BackgroundNormal := 241;
    Result.BackgroundPressed := 242;
  end
  else
  begin
    Result.BackgroundNormal := 239;
    Result.BackgroundPressed := 240;
  end;
  Result.PositionX := AX;
  Result.PositionY := AY;
  Result.HotKey := AHotKey;
  Result.HighlightIndex := 0;
  Result.HighlightCount := 1;
end;

function TWarSceneMainMenu.ArrowButton(AX, AY: Single; ARight: Boolean): TWarUiImageButtonArgs;
begin
  Result := TWarUiImageButtonArgs.Default;
  if ARight then
  begin
    Result.BackgroundNormal := 246;
    Result.BackgroundPressed := 247;
  end
  else
  begin
    Result.BackgroundNormal := 244;
    Result.BackgroundPressed := 245;
  end;
  Result.PositionX := AX;
  Result.PositionY := AY;
end;

procedure TWarSceneMainMenu.Caption(const AId, AText: AnsiString; AX, AY, AWidth: Single; AAlign: TWarTextAlignment);
var
  LText: TWarUiTextArgs;
begin
  LText := TWarUiTextArgs.Default;
  LText.PositionX := AX;
  LText.PositionY := AY;
  LText.FontIndex := 1;
  LText.BoundingsX := AWidth;
  LText.BoundingsY := 12;
  LText.HorizontalAlign := AAlign;
  LText.VerticalAlign := wtaMiddle;
  LText.Text := AText;
  Services.Imui.Text(AId, LText);
end;

procedure TWarSceneMainMenu.StartCampaign(ARace: TWarRace; AMapType: Integer);
begin
  Services.Host.SetNextScene(Services.Scenes.CreateBriefing(ARace, AMapType), 1.0);
end;

procedure TWarSceneMainMenu.DoEnter;
begin
  FMenuPanel := wmpMain;
  Panel.Enable;
  if not Services.Host.IsDemo then
    if Assigned(Services.Audio) then
      Services.Audio.Play(WAR_AUDIO_MUSIC_00, True);
end;

procedure TWarSceneMainMenu.RenderMain;
begin
  if Services.Imui.TextButton('btnMenuSinglePlayer', MenuButton('Start a new game', 104, 85, wkS, False)) then
    FMenuPanel := wmpSinglePlayer; // wsc_handleMenuSinglePlayer
  // not implemented in the original: inert
  Services.Imui.TextButton('btnMenuLoad', MenuButton('Load existing game', 104, 105, wkL, False));
  Services.Imui.TextButton('btnMenuReplayIntro', MenuButton('Replay introduction', 104, 125, wkR, False));
  if Services.Imui.TextButton('btnMenuQuit', MenuButton('Quit', 104, 165, wkQ, False)) then
    Services.Host.RequestQuit;
end;

procedure TWarSceneMainMenu.RenderSinglePlayer;
begin
  if Services.Imui.TextButton('btnSinglePlayerOrc', MenuButton('Orc campaign', 104, 85, wkO, False)) then
    StartCampaign(wraOrcs, WAR_CAMPAIGN_ORCS_01);
  if Services.Imui.TextButton('btnSinglePlayerHuman', MenuButton('Human campaign', 104, 105, wkH, False)) then
    StartCampaign(wraHumans, WAR_CAMPAIGN_HUMANS_01);
  if Services.Imui.TextButton('btnCustomGame', MenuButton('Custom game', 104, 125, wkU, False)) then
  begin
    FMenuPanel := wmpCustomGame;
    FYourRace := wraHumans;
    FEnemyRace := wraOrcs;
    FCustomMap := 147;
  end;
  if Services.Imui.TextButton('btnSinglePlayerCancel', MenuButton('Cancel', 133, 165, wkC, True)) then
    FMenuPanel := wmpMain;
end;

procedure TWarSceneMainMenu.RenderCustomGame;
begin
  Caption('txtYourRaceLabel', 'Your race:', 40, 105, 100, wtaRight);
  Caption('txtEnemyRaceLabel', 'Enemy race:', 40, 125, 100, wtaRight);
  Caption('txtMapLabel', 'Map:', 40, 145, 100, wtaRight);
  Caption('txtYourRace', RaceText(FYourRace), 180, 105, 50, wtaCenter);
  Caption('txtEnemyRace', RaceText(FEnemyRace), 180, 125, 50, wtaCenter);
  Caption('txtMap', MapText(FCustomMap), 180, 145, 50, wtaCenter);
  if Services.Imui.ImageButton('btnYourRaceLeft', ArrowButton(160, 103, False)) then
    if FYourRace > wraNeutral then
      FYourRace := Pred(FYourRace);
  if Services.Imui.ImageButton('btnYourRaceRight', ArrowButton(235, 103, True)) then
    if FYourRace < wraOrcs then
      FYourRace := Succ(FYourRace);
  if Services.Imui.ImageButton('btnEnemyRaceLeft', ArrowButton(160, 123, False)) then
    if FEnemyRace > wraNeutral then
      FEnemyRace := Pred(FEnemyRace);
  if Services.Imui.ImageButton('btnEnemyRaceRight', ArrowButton(235, 123, True)) then
    if FEnemyRace < wraOrcs then
      FEnemyRace := Succ(FEnemyRace);
  if Services.Imui.ImageButton('btnMapLeft', ArrowButton(160, 143, False)) then
    if FCustomMap > 147 then
      Dec(FCustomMap);
  if Services.Imui.ImageButton('btnMapRight', ArrowButton(235, 143, True)) then
    if FCustomMap < 188 then
      Inc(FCustomMap);
  if Services.Imui.TextButton('btnCustomGameOk', MenuButton('Ok', 100, 165, wkO, True)) then
    Services.Host.SetNextCustomMap(FCustomMap, Ord(FYourRace), Ord(FEnemyRace), 1.0);
  if Services.Imui.TextButton('btnCustomGameCancel', MenuButton('Cancel', 180, 165, wkC, True)) then
    FMenuPanel := wmpSinglePlayer; // cancel goes back to the single player panel
end;

procedure TWarSceneMainMenu.DoRender;
var
  LBackground: TWarUiImageArgs;
begin
  LBackground := TWarUiImageArgs.Default;
  LBackground.SpriteRef := 261;
  Services.Imui.Image('imgMenuBackground', LBackground);
  case FMenuPanel of
    wmpMain: RenderMain;
    wmpSinglePlayer: RenderSinglePlayer;
    wmpCustomGame: RenderCustomGame;
  end;
end;

end.
