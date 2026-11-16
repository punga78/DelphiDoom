{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the game of the scenes as a game of a session     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.App.UiSessionGame;

interface

uses
  System.SysUtils, DelphiDoom.GameHost.Types, DelphiDoom.GameHost.Events.Intf, DelphiDoom.War.Campaign.Intf,
  DelphiDoom.War.Ui.Intf, DelphiDoom.War.Ui.Game, DelphiDoom.War.App.SessionTypes;

type
  /// <summary>
  ///   IWarSessionGame on a TWarUiGame: the events go through TWarUiEventAdapter, a frame is RunFrame and then
  ///   BeginInputFrame, and the game starts on the logo of the Blizzard or, with -play, on a mission of the campaign.
  ///   It owns the game
  /// </summary>
  TWarUiSessionGame = class(TInterfacedObject, IWarSessionGame)
  strict private
    FGame: TWarUiGame;
    FAdapter: IGameHostEventSink;
    FWidth: Integer;
    FHeight: Integer;
  public
    /// <summary>
    ///   The game must have been made with the picture of AWidth x AHeight pixels. It goes to the first scene of AStart
    ///   (EWarException if the mission is not in the campaign)
    /// </summary>
    constructor Create(const AGame: TWarUiGame; const AStart: TWarSessionStart; const ACampaigns: IWarCampaigns;
      AWidth, AHeight: Integer);
    destructor Destroy; override;
    procedure Post(const AEvent: TGameHostEvent);
    procedure RunFrame(ADelta: Single);
    function QuitRequested: Boolean;
    function Settings: IWarGameSettings;
    function Pixels: TArray<Byte>;
    function Width: Integer;
    function Height: Integer;
  end;

implementation

uses
  DelphiDoom.War.Level.Types, DelphiDoom.War.Types, DelphiDoom.War.Ui.EventAdapter;

resourcestring
  SWarSessionNoMission = 'The mission %d of the race %d is not in the campaign';

{ TWarUiSessionGame }

constructor TWarUiSessionGame.Create(const AGame: TWarUiGame; const AStart: TWarSessionStart;
  const ACampaigns: IWarCampaigns; AWidth, AHeight: Integer);
var
  LMapType: Integer;
begin
  inherited Create;
  if not Assigned(AGame) then
    raise EArgumentNilException.Create('AGame');
  FGame := AGame;
  FWidth := AWidth;
  FHeight := AHeight;
  FAdapter := TWarUiEventAdapter.Create(FGame);
  try
    if AStart.Mission > 0 then
    begin
      if not ACampaigns.TryGetMapType(TWarRace(AStart.Race), AStart.Mission, LMapType) then
        raise EWarException.CreateFmt(SWarSessionNoMission, [AStart.Mission, AStart.Race]);
      FGame.Manager.SetNextCampaignMap(LMapType, 0);
    end
    else
      FGame.Manager.SetNextScene(FGame.Scenes.CreateBlizzard, 0);
  except
    FAdapter := nil;
    FGame.Free;
    raise;
  end;
end;

destructor TWarUiSessionGame.Destroy;
begin
  FAdapter := nil;
  FGame.Free;
  inherited Destroy;
end;

procedure TWarUiSessionGame.Post(const AEvent: TGameHostEvent);
begin
  FAdapter.Post(AEvent);
end;

procedure TWarUiSessionGame.RunFrame(ADelta: Single);
begin
  FGame.Manager.RunFrame(ADelta);
  FGame.Manager.BeginInputFrame;
end;

function TWarUiSessionGame.QuitRequested: Boolean;
begin
  Result := FGame.Manager.QuitRequested;
end;

function TWarUiSessionGame.Settings: IWarGameSettings;
begin
  Result := FGame.Settings;
end;

function TWarUiSessionGame.Pixels: TArray<Byte>;
begin
  Result := FGame.Canvas.Blitter.Pixels;
end;

function TWarUiSessionGame.Width: Integer;
begin
  Result := FWidth;
end;

function TWarUiSessionGame.Height: Integer;
begin
  Result := FHeight;
end;

end.
