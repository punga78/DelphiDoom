{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 host library - the minimal session                       }
{                                                                              }
{  Written for this repository: NOT a port of idSessionLocal (Session.cpp      }
{  needs the game, the renderer, the sound and the GUIs). It has only the      }
{  states that a program without a window needs: no map or a map running.      }
{  There is no C++ parity for it.                                              }
{  Licensed under the GNU General Public License, version 2 or later.          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.D3Host.Session;

interface

uses
  DelphiDoom.D3Host.Types, DelphiDoom.D3Host.Input.Intf, DelphiDoom.D3Host.Lifecycle.Intf,
  DelphiDoom.D3Host.Session.Intf;

type
  /// <summary>The state of the session</summary>
  TD3SessionState = (ssIdle, ssLoading, ssInGame);

  /// <summary>
  ///   The session that the life cycle drives: Map loads a map through the injected loader and from then on every
  ///   Frame runs a game frame; Stop unloads it. Idle sessions do nothing (the menu is not ported). Screen updates
  ///   are counted and nothing is drawn.
  /// </summary>
  TD3Session = class(TInterfacedObject, ID3SessionLifecycle, ID3ScreenUpdater)
  strict private
    FState: TD3CommonState;
    FLoader: ID3MapLoader;
    FRunner: ID3GameRunner;
    FStatus: TD3SessionState;
    FMapName: AnsiString;
    FFrames: Integer;
    FScreenUpdates: Integer;
  public
    constructor Create(const AState: TD3CommonState; const ALoader: ID3MapLoader; const ARunner: ID3GameRunner);
    procedure Init;
    procedure Shutdown;
    procedure Frame;
    procedure GuiFrameEvents;
    procedure StartMenu(const APlayIntro: Boolean);
    procedure WriteCDKey;
    procedure UpdateScreen(const AOutOfSequence: Boolean);
    /// <summary>The map command: unloads a running map, loads the new one (the loader starts its main script)</summary>
    procedure Map(const AMapName: AnsiString);
    /// <summary>Unloads the running map</summary>
    procedure Stop;
    property Status: TD3SessionState read FStatus;
    property MapName: AnsiString read FMapName;
    property GameFrames: Integer read FFrames;
    property ScreenUpdates: Integer read FScreenUpdates;
  end;

implementation

constructor TD3Session.Create(const AState: TD3CommonState; const ALoader: ID3MapLoader;
  const ARunner: ID3GameRunner);
begin
  inherited Create;
  FState := AState;
  FLoader := ALoader;
  FRunner := ARunner;
end;

procedure TD3Session.Init;
begin
  FStatus := ssIdle;
end;

procedure TD3Session.Shutdown;
begin
  Stop;
end;

procedure TD3Session.Frame;
begin
  if FStatus = ssInGame then
  begin
    FRunner.RunFrame(FState.TicNumber);
    Inc(FFrames);
  end;
end;

procedure TD3Session.GuiFrameEvents;
begin
end;

procedure TD3Session.StartMenu(const APlayIntro: Boolean);
begin
  FStatus := ssIdle;
end;

procedure TD3Session.WriteCDKey;
begin
end;

procedure TD3Session.UpdateScreen(const AOutOfSequence: Boolean);
begin
  Inc(FScreenUpdates);
end;

procedure TD3Session.Map(const AMapName: AnsiString);
begin
  Stop;
  FStatus := ssLoading;
  try
    FLoader.LoadMap(AMapName);
  except
    FStatus := ssIdle;
    raise;
  end;
  FMapName := AMapName;
  FStatus := ssInGame;
end;

procedure TD3Session.Stop;
begin
  if FStatus = ssInGame then
    FLoader.UnloadMap;
  FStatus := ssIdle;
  FMapName := '';
end;

end.
