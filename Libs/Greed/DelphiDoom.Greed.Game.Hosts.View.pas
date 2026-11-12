{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - what the parts of the game ask of the screen,    }
{  of the music and of the loading of a map                                     }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): the calls of raven.pas,     }
{  utils.pas and event.pas to display.pas, menu.pas, modplay.pas and playfli    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Game.Hosts.View;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Level.Intf, DelphiDoom.Greed.Events.Intf,
  DelphiDoom.Greed.MapSession.Intf, DelphiDoom.Greed.Game.Parts;

type
  /// <summary>
  ///   The hosts of the items, of the level, of the secret codes, of the life of a map and of the events: what they
  ///   ask goes to the view of the game (IGreedGameView: status bar, screens, films), to the pictures of the weapon,
  ///   to the music, to the renderer (the tables of the light, the sky) and to the session that loads a map. The
  ///   object does not own the parts: it finds them in the TGreedGameParts of its game
  /// </summary>
  TGreedGameViewHost = class(TInterfacedObject, IGreedItemHost, IGreedLevelHost, IGreedCheatHost,
    IGreedMapSessionHost, IGreedEventHost)
  strict private
    FParts: TGreedGameParts;
    function GetSystemClock: Cardinal;
    function IGreedMapSessionHost.GetClock = GetSystemClock;
    procedure EngineWasReset;
    procedure IGreedMapSessionHost.ResetMouse = EngineWasReset;
  public
    /// <summary>EArgumentNilException if AParts is nil</summary>
    constructor Create(AParts: TGreedGameParts);
    // IGreedItemHost
    procedure RefreshInventory;
    procedure RefreshAmmo;
    procedure LoadWeapon(AWeapon: Integer);
    function GetWeaponPictureHeight: Integer;
    procedure ResetMouse;
    // IGreedLevelHost
    procedure RefreshGoalItem;
    procedure SetTotalEffectTime(ATics: Integer);
    procedure LoadColorMaps(const ALumpName: string);
    function GetAmbientLight: Integer;
    procedure FadeOutLevel;
    procedure ResetDisplay;
    procedure NewMap(AMap, AActivate: Integer);
    // IGreedCheatHost
    procedure SetGameEpisode(AEpisode: Integer);
    procedure RestoreTimerHook;
    // IGreedMapSessionHost
    procedure SelectSong(AMap: Integer);
    procedure StopMusic;
    procedure MissionBriefing(AMap: Integer);
    procedure EndGame(AEpisode: Integer);
    procedure LoadTextures;
    procedure StartWait;
    procedure UpdateWait;
    procedure EndWait;
    procedure ResetSpawnCounts;
    function GetLowResolution: Boolean;
    // IGreedEventHost
    procedure ActivationSound(ASprite: Integer);
    procedure PlayFli(AMovie: Integer);
  end;

implementation

uses
  DelphiDoom.Greed.SongSelector;

{ TGreedGameViewHost }

constructor TGreedGameViewHost.Create(AParts: TGreedGameParts);
begin
  inherited Create;
  if not Assigned(AParts) then
    raise EArgumentNilException.Create('AParts');
  FParts := AParts;
end;

procedure TGreedGameViewHost.RefreshInventory;
begin
  // oldinventory := -2; inventoryleft; inventoryright
  FParts.Inventory.Refresh;
end;

procedure TGreedGameViewHost.RefreshAmmo;
begin
  FParts.View.RefreshAmmo;
end;

procedure TGreedGameViewHost.LoadWeapon(AWeapon: Integer);
begin
  FParts.WeaponView.LoadWeapon(AWeapon);
end;

function TGreedGameViewHost.GetWeaponPictureHeight: Integer;
begin
  Result := FParts.WeaponView.PictureHeight(0);
end;

procedure TGreedGameViewHost.ResetMouse;
begin
  // ResetMouse of d_ints.pas puts the cursor of the system at the centre of the window: the commands of the
  // game come from IGreedControls, that gives movements and has no cursor
end;

procedure TGreedGameViewHost.EngineWasReset;
begin
  // the session asks for ResetMouse at the end of resetengine, where the original has put the clock of the game
  // and fxtimecount back to 0: fxtimecount is of the renderer (the glow and the flicker of the walls)
  FParts.Renderer.SetEffectsTime(FParts.Session.FxTimeCount);
  ResetMouse;
end;

procedure TGreedGameViewHost.RefreshGoalItem;
begin
  FParts.Session.OldGoalItem := -1;
  FParts.View.RefreshGoalItem;
end;

procedure TGreedGameViewHost.SetTotalEffectTime(ATics: Integer);
begin
  FParts.View.SetTotalEffectTime(ATics);
end;

procedure TGreedGameViewHost.LoadColorMaps(const ALumpName: string);
begin
  FParts.Renderer.LoadColorMaps(ALumpName);
end;

function TGreedGameViewHost.GetAmbientLight: Integer;
begin
  Result := FParts.AmbientLight;
end;

procedure TGreedGameViewHost.FadeOutLevel;
begin
  FParts.View.FadeOutLevel;
end;

procedure TGreedGameViewHost.ResetDisplay;
begin
  FParts.View.ResetDisplay;
end;

procedure TGreedGameViewHost.NewMap(AMap, AActivate: Integer);
begin
  FParts.Session.NewMap(AMap, AActivate);
  // the sky is the one that the script of the new map names
  FParts.Renderer.SetBackdrop(FParts.Events.Backdrop);
end;

procedure TGreedGameViewHost.SetGameEpisode(AEpisode: Integer);
begin
  FParts.GameEpisode := AEpisode;
  FParts.View.SetGameEpisode(AEpisode);
end;

procedure TGreedGameViewHost.RestoreTimerHook;
begin
  // INT_TimerHook(PlayerCommand): the command of the player is always the one that the tic of the game runs
end;

procedure TGreedGameViewHost.SelectSong(AMap: Integer);
var
  LSong: TGreedSong;
begin
  LSong := TGreedSongSelector.Select(AMap, FParts.State.Demo, False);
  FParts.Music.Play(LSong.FileName, LSong.Pattern);
end;

procedure TGreedGameViewHost.StopMusic;
begin
  FParts.Music.Stop;
end;

procedure TGreedGameViewHost.MissionBriefing(AMap: Integer);
begin
  FParts.View.MissionBriefing(AMap);
end;

procedure TGreedGameViewHost.EndGame(AEpisode: Integer);
begin
  FParts.View.EndGame(AEpisode);
end;

procedure TGreedGameViewHost.LoadTextures;
begin
  // the renderer reads the lumps of the walls and of the flats when it first draws them
end;

procedure TGreedGameViewHost.StartWait;
begin
  FParts.View.StartWait;
end;

procedure TGreedGameViewHost.UpdateWait;
begin
  FParts.View.UpdateWait;
end;

procedure TGreedGameViewHost.EndWait;
begin
  FParts.View.EndWait;
end;

procedure TGreedGameViewHost.ResetSpawnCounts;
begin
  FParts.Spawner.ResetCounts;
end;

function TGreedGameViewHost.GetSystemClock: Cardinal;
begin
  Result := FParts.Clock.Clock;
end;

function TGreedGameViewHost.GetLowResolution: Boolean;
begin
  Result := FParts.LowResolution;
end;

procedure TGreedGameViewHost.ActivationSound(ASprite: Integer);
begin
  FParts.SpriteLogic.ActivationSound(ASprite);
end;

procedure TGreedGameViewHost.PlayFli(AMovie: Integer);
begin
  FParts.View.PlayFli(AMovie);
end;

end.
