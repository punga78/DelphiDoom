{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the start of a level                              }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  SetupGameLevel and FadeAndUnhook of kd_play.c                                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.LevelSetup;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.GameTypes, DelphiDoom.Keen.Intf, DelphiDoom.Keen.UserIntf,
  DelphiDoom.Keen.LevelScanner, DelphiDoom.Keen.ActorMover, DelphiDoom.Keen.PlayLoop;

type
  /// <summary>
  ///   Makes the map of gamestate.mapon the level that is played: a working copy of the map goes to the refresh
  ///   manager, to the walls of the actors and to their functions; the world map is patched with what the player
  ///   has done; the actors of the info plane are spawned. The cache manager of the original (which graphics to
  ///   load, with its "loading" bar) is not here: the graphics are all in memory
  /// </summary>
  TKeenLevelSetup = class(TInterfacedObject, IKeenLevelSetup)
  strict private
    FMaps: IKeenMapSource;
    FRefresh: IKeenRefresh;
    FTiming: IKeenRefreshTiming;
    FScanner: TKeenLevelScanner;
    FMover: TKeenActorMover;
    FPlayLoop: TKeenPlayLoop;
    FContext: IKeenActionContext;
    FPlayer: IKeenPlayerFunctions;
    FFader: IKeenFader;
    FWindows: IKeenUserWindows;
    FMap: IKeenWorkingMap;
    FFadeCount: Integer;
    procedure FadeAndUnhook;
  public
    /// <param name="AMaps">The maps of the game</param>
    /// <param name="ARefresh">The refresh manager, that also resets its timing</param>
    /// <param name="AScanner">Spawns the actors of the info plane (not owned)</param>
    /// <param name="AMover">The walls of the actors (not owned)</param>
    /// <param name="APlayLoop">The limits of the sleep of the actors (not owned)</param>
    /// <param name="AContext">The map of the functions of the actors, the list of the actors and the play state</param>
    /// <param name="APlayer">SpawnScore</param>
    constructor Create(const AMaps: IKeenMapSource; const ARefresh: IKeenRefresh; AScanner: TKeenLevelScanner;
      AMover: TKeenActorMover; APlayLoop: TKeenPlayLoop; const AContext: IKeenActionContext;
      const APlayer: IKeenPlayerFunctions; const AFader: IKeenFader; const AWindows: IKeenUserWindows);
    destructor Destroy; override;
    function GetMap: IKeenWorkingMap;
    procedure SetupGameLevel(ALoadNow: Boolean);
    procedure HookFadeIn;
    procedure CenterViewOnPlayer;
  end;

implementation

uses
  DelphiDoom.Keen.WorkingMap;

{ TKeenLevelSetup }

constructor TKeenLevelSetup.Create(const AMaps: IKeenMapSource; const ARefresh: IKeenRefresh;
  AScanner: TKeenLevelScanner; AMover: TKeenActorMover; APlayLoop: TKeenPlayLoop; const AContext: IKeenActionContext;
  const APlayer: IKeenPlayerFunctions; const AFader: IKeenFader; const AWindows: IKeenUserWindows);
begin
  inherited Create;
  if not Assigned(AMaps) then
    raise EArgumentNilException.Create('AMaps');
  if not Assigned(ARefresh) then
    raise EArgumentNilException.Create('ARefresh');
  if not Assigned(AScanner) then
    raise EArgumentNilException.Create('AScanner');
  if not Assigned(AMover) then
    raise EArgumentNilException.Create('AMover');
  if not Assigned(APlayLoop) then
    raise EArgumentNilException.Create('APlayLoop');
  if not Assigned(AContext) then
    raise EArgumentNilException.Create('AContext');
  if not Assigned(APlayer) then
    raise EArgumentNilException.Create('APlayer');
  if not Assigned(AFader) then
    raise EArgumentNilException.Create('AFader');
  if not Assigned(AWindows) then
    raise EArgumentNilException.Create('AWindows');
  FMaps := AMaps;
  FRefresh := ARefresh;
  if not Supports(ARefresh, IKeenRefreshTiming, FTiming) then
    raise EArgumentException.Create('ARefresh');
  FScanner := AScanner;
  FMover := AMover;
  FPlayLoop := APlayLoop;
  FContext := AContext;
  FPlayer := APlayer;
  FFader := AFader;
  FWindows := AWindows;
end;

destructor TKeenLevelSetup.Destroy;
begin
  // the hook of the fade is a method of this object
  if Assigned(FRefresh) then
    FRefresh.SetRefreshHook(nil);
  inherited Destroy;
end;

function TKeenLevelSetup.GetMap: IKeenWorkingMap;
begin
  Result := FMap;
end;

procedure TKeenLevelSetup.FadeAndUnhook;
begin
  Inc(FFadeCount);
  if FFadeCount = 2 then
  begin
    FRefresh.ForceRefresh;
    FFader.FadeIn;
    FRefresh.SetRefreshHook(nil);
    // don't adaptively time the fade
    FTiming.ResetTiming;
  end;
end;

procedure TKeenLevelSetup.HookFadeIn;
begin
  FFadeCount := 0;
  FRefresh.SetRefreshHook(FadeAndUnhook);
end;

procedure TKeenLevelSetup.CenterViewOnPlayer;
var
  LPlayer: PKeenObject;
  LOrgX: Integer;
  LOrgY: Integer;
begin
  LPlayer := FContext.Objects.Player;
  LOrgX := Integer(LPlayer^.X) - (150 shl 4);
  LOrgY := Integer(LPlayer^.Y) - (84 shl 4);
  if LOrgX < 0 then
    LOrgX := 0;
  if LOrgY < 0 then
    LOrgY := 0;
  FRefresh.NewPosition(LOrgX, LOrgY);
  FPlayLoop.CalcInactivate;
end;

procedure TKeenLevelSetup.SetupGameLevel(ALoadNow: Boolean);
var
  LMapOn: Integer;
begin
  LMapOn := FContext.Play.GameState^.MapOn;
  // CA_CacheMap: the header and the three planes; mapon is the map that is loaded
  FMap := TKeenWorkingMap.Create(FMaps.LoadMap(LMapOn));
  FContext.Play.MapOn := LMapOn;
  FRefresh.NewMap(FMap);
  FContext.SetMap(FMap);
  FMover.SetMap(FMap);
  // decide which actors are needed and spawn them
  if LMapOn = 0 then
    FScanner.PatchWorldMap(FMap, FContext.Play.GameState^);
  // the map 20 is the title screen
  if LMapOn <> KEEN_TITLE_MAP then
    FScanner.ScanInfoPlane(FMap);
  FRefresh.MarkTileGraphics;
  if ALoadNow and (LMapOn <> KEEN_TITLE_MAP) and FScanner.BombsPresent then
  begin
    FWindows.Video.FixRefreshBuffer;
    FWindows.DrawWindow(10, 1, 20, 2);
    FWindows.PrintCentered('Boobus Bombs Near!');
    FWindows.Video.UpdateScreen;
  end;
  if (LMapOn <> KEEN_TITLE_MAP) and ALoadNow then
  begin
    FFader.FadeOut;
    HookFadeIn;
    FPlayer.SpawnScore;
    // start the view on the player
    CenterViewOnPlayer;
  end;
end;

end.
