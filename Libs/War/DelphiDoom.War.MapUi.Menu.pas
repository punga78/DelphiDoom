{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the menus of the map                              }
{                                                                              }
{  Port of war1 (acoto87/war1), war_map_menu.c (wmm_*), (c) 2019 Alejandro      }
{  Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an     }
{  altered version, not the original.                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.MapUi.Menu;

{$R-}
{$Q-}

interface

uses
  System.SysUtils, DelphiDoom.War.Ui.Intf, DelphiDoom.War.MapUi.Types, DelphiDoom.War.MapUi.Intf;

type
  /// <summary>
  ///   The state of the menus of the map (map->menuState, map->playing and the settings of the map) and what the buttons of
  ///   those menus do (the wmm_* functions). The map plays while no menu is open: opening a menu stops it, closing the main
  ///   menu (Continue) starts it again. What leaves the map (restart, continue after the end, the main menu, quitting) is
  ///   the host's. Defects of the original kept: the volume of the options menu is the volume of the game times 100
  ///   truncated, so one that is not exact (35 percent is 0.35 in a float) shows one less; the Save button of the end of
  ///   a map does nothing (NOT_IMPLEMENTED prints a line)
  /// </summary>
  TWarMapMenu = class
  strict private
    // the host is the scene that owns this menu: a counted reference would keep the two alive for ever
    [weak] FHost: IWarMapMenuHost;
    FGameSettings: IWarGameSettings;
    FState: TWarMenuState;
    FPlaying: Boolean;
    FCurrent: TWarMapSettings;
    FPending: TWarMapSettings;
    procedure SetState(AState: TWarMenuState; APlaying: Boolean);
    function Stepped(AValue, AStep, AMinimum, AMaximum: Integer): Integer;
  public
    /// <summary>The game settings may be nil (the volumes stay as they are); the host is not owned</summary>
    constructor Create(const AHost: IWarMapMenuHost; const AGameSettings: IWarGameSettings);
    /// <summary>wmap_enterMap: the map plays, nothing is open and every speed is normal</summary>
    procedure Reset;
    /// <summary>wmm_showOrHideGameOverMenu</summary>
    procedure ShowGameOver(AShow: Boolean);
    /// <summary>wmm_showDemoEndMenu</summary>
    procedure ShowDemoEnd(AShow: Boolean);
    /// <summary>wmm_handleMenu</summary>
    procedure OpenMain;
    /// <summary>wmm_handleOptions: the volumes of the game become the settings, the settings are copied to be edited</summary>
    procedure OpenOptions;
    /// <summary>wmm_handleObjectives</summary>
    procedure OpenObjectives;
    /// <summary>wmm_handleRestart</summary>
    procedure OpenRestart;
    /// <summary>wmm_handleContinue</summary>
    procedure Resume;
    /// <summary>wmm_handleQuit</summary>
    procedure OpenQuit;
    /// <summary>
    ///   Back to the main menu: wmm_handleOptionsCancel, wmm_handleObjectivesMenu, wmm_handleRestartCancel and
    ///   wmm_handleQuitCancel
    /// </summary>
    procedure Back;
    /// <summary>wmm_handleGameSpeedDec</summary>
    procedure GameSpeedDown;
    /// <summary>wmm_handleGameSpeedInc</summary>
    procedure GameSpeedUp;
    /// <summary>wmm_handleMusicVolDec</summary>
    procedure MusicVolumeDown;
    /// <summary>wmm_handleMusicVolInc</summary>
    procedure MusicVolumeUp;
    /// <summary>wmm_handleSfxVolDec</summary>
    procedure SoundVolumeDown;
    /// <summary>wmm_handleSfxVolInc</summary>
    procedure SoundVolumeUp;
    /// <summary>wmm_handleMouseScrollSpeedDec</summary>
    procedure MouseScrollDown;
    /// <summary>wmm_handleMouseScrollSpeedInc</summary>
    procedure MouseScrollUp;
    /// <summary>wmm_handleKeyScrollSpeedDec</summary>
    procedure KeyScrollDown;
    /// <summary>wmm_handleKeyScrollSpeedInc</summary>
    procedure KeyScrollUp;
    /// <summary>wmm_handleOptionsOk: the settings that were edited are kept and the volumes of the game follow</summary>
    procedure ApplyOptions;
    /// <summary>wmm_handleRestartRestart</summary>
    procedure Restart;
    /// <summary>wmm_handleGameOverSave: not implemented in the original, nothing happens</summary>
    procedure SaveAfterGameOver;
    /// <summary>wmm_handleGameOverContinue and wmm_handleDemoEndMenu are the host's</summary>
    procedure ContinueAfterGameOver;
    /// <summary>wmm_handleQuitQuit</summary>
    procedure QuitGame;
    /// <summary>wmm_handleQuitMenu and wmm_handleDemoEndMenu</summary>
    procedure ReturnToMainMenu;
    /// <summary>The volume of the game as the options menu shows it: (s32)(volume * 100) with the product exact</summary>
    class function PercentOf(AVolume: Single): Integer; static;
    property State: TWarMenuState read FState;
    /// <summary>map->playing</summary>
    property Playing: Boolean read FPlaying write FPlaying;
    /// <summary>map->settings</summary>
    property Settings: TWarMapSettings read FCurrent write FCurrent;
    /// <summary>map->pendingSettings: what the options menu edits</summary>
    property Pending: TWarMapSettings read FPending;
  end;

implementation

{ TWarMapMenu }

constructor TWarMapMenu.Create(const AHost: IWarMapMenuHost; const AGameSettings: IWarGameSettings);
begin
  inherited Create;
  FHost := AHost;
  FGameSettings := AGameSettings;
  Reset;
end;

procedure TWarMapMenu.Reset;
begin
  FState := wmsNone;
  FPlaying := True;
  FCurrent := Default(TWarMapSettings);
  FCurrent.GameSpeed := WAR_SPEED_NORMAL;
  FCurrent.MouseScrollSpeed := WAR_SPEED_NORMAL;
  FCurrent.KeyScrollSpeed := WAR_SPEED_NORMAL;
  FPending := FCurrent;
end;

procedure TWarMapMenu.SetState(AState: TWarMenuState; APlaying: Boolean);
begin
  FState := AState;
  FPlaying := APlaying;
end;

function TWarMapMenu.Stepped(AValue, AStep, AMinimum, AMaximum: Integer): Integer;
begin
  Result := AValue + AStep;
  if Result < AMinimum then
    Result := AMinimum;
  if Result > AMaximum then
    Result := AMaximum;
end;

class function TWarMapMenu.PercentOf(AVolume: Single): Integer;
begin
  // the product in a Double is exact for a Single and 100: 0.35 as a float is 0.3499999940395355, so it is 34
  Result := Trunc(Double(AVolume) * 100);
end;

procedure TWarMapMenu.ShowGameOver(AShow: Boolean);
begin
  if AShow then
    SetState(wmsGameOver, False)
  else
    SetState(wmsNone, True);
end;

procedure TWarMapMenu.ShowDemoEnd(AShow: Boolean);
begin
  if AShow then
    SetState(wmsDemoEnd, False)
  else
    SetState(wmsNone, True);
end;

procedure TWarMapMenu.OpenMain;
begin
  SetState(wmsMain, False);
end;

procedure TWarMapMenu.OpenOptions;
begin
  if Assigned(FGameSettings) then
  begin
    FCurrent.MusicVolume := PercentOf(FGameSettings.MusicVolume);
    FCurrent.SoundVolume := PercentOf(FGameSettings.SoundVolume);
  end;
  FPending := FCurrent;
  SetState(wmsOptions, False);
end;

procedure TWarMapMenu.OpenObjectives;
begin
  SetState(wmsObjectives, False);
end;

procedure TWarMapMenu.OpenRestart;
begin
  SetState(wmsRestart, False);
end;

procedure TWarMapMenu.Resume;
begin
  SetState(wmsNone, True);
end;

procedure TWarMapMenu.OpenQuit;
begin
  SetState(wmsQuit, False);
end;

procedure TWarMapMenu.Back;
begin
  SetState(wmsMain, False);
end;

procedure TWarMapMenu.GameSpeedDown;
begin
  if FPending.GameSpeed > WAR_SPEED_SLOWEST then
    Dec(FPending.GameSpeed);
end;

procedure TWarMapMenu.GameSpeedUp;
begin
  if FPending.GameSpeed < WAR_SPEED_FASTEST then
    Inc(FPending.GameSpeed);
end;

procedure TWarMapMenu.MusicVolumeDown;
begin
  FPending.MusicVolume := Stepped(FPending.MusicVolume, -5, 0, 100);
end;

procedure TWarMapMenu.MusicVolumeUp;
begin
  FPending.MusicVolume := Stepped(FPending.MusicVolume, 5, 0, 100);
end;

procedure TWarMapMenu.SoundVolumeDown;
begin
  FPending.SoundVolume := Stepped(FPending.SoundVolume, -5, 0, 100);
end;

procedure TWarMapMenu.SoundVolumeUp;
begin
  FPending.SoundVolume := Stepped(FPending.SoundVolume, 5, 0, 100);
end;

procedure TWarMapMenu.MouseScrollDown;
begin
  if FPending.MouseScrollSpeed > WAR_SPEED_SLOWEST then
    Dec(FPending.MouseScrollSpeed);
end;

procedure TWarMapMenu.MouseScrollUp;
begin
  if FPending.MouseScrollSpeed < WAR_SPEED_FASTEST then
    Inc(FPending.MouseScrollSpeed);
end;

procedure TWarMapMenu.KeyScrollDown;
begin
  if FPending.KeyScrollSpeed > WAR_SPEED_SLOWEST then
    Dec(FPending.KeyScrollSpeed);
end;

procedure TWarMapMenu.KeyScrollUp;
begin
  if FPending.KeyScrollSpeed < WAR_SPEED_FASTEST then
    Inc(FPending.KeyScrollSpeed);
end;

procedure TWarMapMenu.ApplyOptions;
var
  LRatio: Single;
begin
  FCurrent := FPending;
  if Assigned(FGameSettings) then
  begin
    // (f32)volume / 100: the division is in a float
    LRatio := FCurrent.MusicVolume;
    LRatio := LRatio / 100;
    FGameSettings.SetMusicVolume(LRatio);
    LRatio := FCurrent.SoundVolume;
    LRatio := LRatio / 100;
    FGameSettings.SetSoundVolume(LRatio);
  end;
  SetState(wmsMain, False);
end;

procedure TWarMapMenu.Restart;
begin
  if Assigned(FHost) then
    FHost.RestartMap;
end;

procedure TWarMapMenu.SaveAfterGameOver;
begin
  // NOT_IMPLEMENTED() only writes a line to stderr: the original does nothing here
end;

procedure TWarMapMenu.ContinueAfterGameOver;
begin
  if Assigned(FHost) then
    FHost.ContinueAfterGameOver;
end;

procedure TWarMapMenu.QuitGame;
begin
  if Assigned(FHost) then
    FHost.QuitGame;
end;

procedure TWarMapMenu.ReturnToMainMenu;
begin
  if Assigned(FHost) then
    FHost.ReturnToMainMenu;
end;

end.
