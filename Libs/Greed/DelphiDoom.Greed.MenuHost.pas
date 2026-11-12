{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the game as the menu sees it                     }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): the calls of menu.pas to    }
{  utils.pas, raven.pas and m_defs.pas                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.MenuHost;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Settings.Intf, DelphiDoom.Greed.Game, DelphiDoom.Greed.Menu.Intf,
  DelphiDoom.Greed.Application.Intf;

type
  /// <summary>
  ///   IGreedMenuHost on a TGreedGame: a new game, a saved game loaded or written, the light, the size of the view
  ///   and the settings that the game reads (violence, the delay of the rear camera), saved when the menu closes
  /// </summary>
  TGreedMenuHost = class(TInterfacedObject, IGreedMenuHost)
  strict private
    FGame: TGreedGame;
    FSettings: IGreedSettings;
    FStore: IGreedSettingsStore;
    FViewSize: IGreedViewSize;
  public
    /// <summary>AGame is not owned. EArgumentNilException if one is nil (AViewSize may be: no status bar)</summary>
    constructor Create(AGame: TGreedGame; const ASettings: IGreedSettings; const AStore: IGreedSettingsStore;
      const AViewSize: IGreedViewSize);
    function GameLoaded: Boolean;
    procedure NewGame(AMap, ACharacter, ADifficulty: Integer);
    procedure LoadGame(ASlot: Integer);
    procedure SaveGame(ASlot: Integer);
    procedure QuitGame;
    procedure AmbientLightChanged(ALight: Integer);
    procedure ApplyViewSize(ASize: Integer);
    procedure SaveSettings;
    procedure ResetControls;
  end;

implementation

const
  SETTING_VIOLENCE = 'violence';
  SETTING_CAMERA_DELAY = 'camdelay';

{ TGreedMenuHost }

constructor TGreedMenuHost.Create(AGame: TGreedGame; const ASettings: IGreedSettings;
  const AStore: IGreedSettingsStore; const AViewSize: IGreedViewSize);
begin
  inherited Create;
  if not Assigned(AGame) then
    raise EArgumentNilException.Create('AGame');
  if not Assigned(ASettings) then
    raise EArgumentNilException.Create('ASettings');
  if not Assigned(AStore) then
    raise EArgumentNilException.Create('AStore');
  FGame := AGame;
  FSettings := ASettings;
  FStore := AStore;
  FViewSize := AViewSize;
end;

function TGreedMenuHost.GameLoaded: Boolean;
begin
  Result := FGame.State.GameLoaded;
end;

procedure TGreedMenuHost.NewGame(AMap, ACharacter, ADifficulty: Integer);
begin
  // newplayer: the game starts over with a briefing, so the menu that asked for it goes on after the screens
  FGame.NewGame(AMap, ACharacter, ADifficulty);
end;

procedure TGreedMenuHost.LoadGame(ASlot: Integer);
begin
  FGame.LoadGame(ASlot);
end;

procedure TGreedMenuHost.SaveGame(ASlot: Integer);
begin
  FGame.SaveGame(ASlot);
end;

procedure TGreedMenuHost.QuitGame;
begin
  FGame.State.QuitGame := True;
end;

procedure TGreedMenuHost.AmbientLightChanged(ALight: Integer);
begin
  FGame.AmbientLight := ALight;
end;

procedure TGreedMenuHost.ApplyViewSize(ASize: Integer);
begin
  if Assigned(FViewSize) then
    FViewSize.SetSize(ASize);
end;

procedure TGreedMenuHost.SaveSettings;
begin
  // what the menu changed and the game reads at once, then M_SaveDefaults
  FGame.Violence := FSettings.GetBoolean(SETTING_VIOLENCE);
  FGame.CameraDelay := FSettings.GetInteger(SETTING_CAMERA_DELAY);
  FStore.Save(FSettings);
end;

procedure TGreedMenuHost.ResetControls;
begin
  FGame.State.TurnRate := 0;
  FGame.State.MoveRate := 0;
  FGame.State.FallRate := 0;
  FGame.State.StrafRate := 0;
end;

end.
