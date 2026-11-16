{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the view of the game with its screens            }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): the calls of raven.pas and  }
{  utils.pas to display.pas, menu.pas, intro.pas and playfli.pas                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.ScreenView;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Frame.Intf, DelphiDoom.Greed.GameView.Intf, DelphiDoom.Greed.Application.Intf;

type
  /// <summary>
  ///   IGreedGameView made of two: the status bar, the weapon and the messages go to the view that draws them
  ///   (AInner), the screens that take the whole picture for a while (menus, briefings, endings, movies) to the
  ///   program (IGreedScreens). The game is made with this view before the program exists: Screens is given
  ///   after. Without it the calls of the screens go to the inner view
  /// </summary>
  TGreedScreenView = class(TInterfacedObject, IGreedGameView)
  strict private
    FInner: IGreedGameView;
    FScreens: IGreedScreens;
  public
    /// <summary>EArgumentNilException if AInner is nil</summary>
    constructor Create(const AInner: IGreedGameView);
    procedure RefreshAmmo;
    procedure RefreshGoalItem;
    procedure ResetMessages;
    procedure ResetDisplay;
    procedure SetTotalEffectTime(ATics: Integer);
    procedure MissionBriefing(AMap: Integer);
    procedure EndGame(AEpisode: Integer);
    procedure PlayFli(AMovie: Integer);
    procedure StartWait;
    procedure UpdateWait;
    procedure EndWait;
    procedure FadeOutLevel;
    procedure ChangeViewSize(ABigger: Boolean);
    procedure SetGameEpisode(AEpisode: Integer);
    function ShowMenu: Boolean;
    procedure ShowHelp;
    procedure ShowPause;
    function ConfirmQuit: Boolean;
    procedure DrawOverlay(var AFrame: TGreedFrame; const AOverlay: TGreedViewOverlay);
    /// <summary>Who shows the screens; nil to go back to the inner view</summary>
    property Screens: IGreedScreens read FScreens write FScreens;
  end;

implementation

{ TGreedScreenView }

constructor TGreedScreenView.Create(const AInner: IGreedGameView);
begin
  inherited Create;
  if not Assigned(AInner) then
    raise EArgumentNilException.Create('AInner');
  FInner := AInner;
end;

procedure TGreedScreenView.RefreshAmmo;
begin
  FInner.RefreshAmmo;
end;

procedure TGreedScreenView.RefreshGoalItem;
begin
  FInner.RefreshGoalItem;
end;

procedure TGreedScreenView.ResetMessages;
begin
  FInner.ResetMessages;
end;

procedure TGreedScreenView.ResetDisplay;
begin
  FInner.ResetDisplay;
  if Assigned(FScreens) then
    FScreens.ReleaseScreen;
end;

procedure TGreedScreenView.SetTotalEffectTime(ATics: Integer);
begin
  FInner.SetTotalEffectTime(ATics);
end;

procedure TGreedScreenView.MissionBriefing(AMap: Integer);
begin
  if Assigned(FScreens) then
    FScreens.MissionBriefing(AMap)
  else
    FInner.MissionBriefing(AMap);
end;

procedure TGreedScreenView.EndGame(AEpisode: Integer);
begin
  if Assigned(FScreens) then
    FScreens.EndGame(AEpisode)
  else
    FInner.EndGame(AEpisode);
end;

procedure TGreedScreenView.PlayFli(AMovie: Integer);
begin
  if Assigned(FScreens) then
    FScreens.PlayFli(AMovie)
  else
    FInner.PlayFli(AMovie);
end;

procedure TGreedScreenView.StartWait;
begin
  if Assigned(FScreens) then
    FScreens.StartWait
  else
    FInner.StartWait;
end;

procedure TGreedScreenView.UpdateWait;
begin
  if Assigned(FScreens) then
    FScreens.UpdateWait
  else
    FInner.UpdateWait;
end;

procedure TGreedScreenView.EndWait;
begin
  if Assigned(FScreens) then
    FScreens.EndWait
  else
    FInner.EndWait;
end;

procedure TGreedScreenView.FadeOutLevel;
begin
  if Assigned(FScreens) then
    FScreens.FadeOutLevel
  else
    FInner.FadeOutLevel;
end;

procedure TGreedScreenView.ChangeViewSize(ABigger: Boolean);
begin
  FInner.ChangeViewSize(ABigger);
end;

procedure TGreedScreenView.SetGameEpisode(AEpisode: Integer);
begin
  FInner.SetGameEpisode(AEpisode);
end;

function TGreedScreenView.ShowMenu: Boolean;
begin
  if Assigned(FScreens) then
    Result := FScreens.ShowMenu
  else
    Result := FInner.ShowMenu;
end;

procedure TGreedScreenView.ShowHelp;
begin
  if Assigned(FScreens) then
    FScreens.ShowHelp
  else
    FInner.ShowHelp;
end;

procedure TGreedScreenView.ShowPause;
begin
  if Assigned(FScreens) then
    FScreens.ShowPause
  else
    FInner.ShowPause;
end;

function TGreedScreenView.ConfirmQuit: Boolean;
begin
  if Assigned(FScreens) then
    Result := FScreens.ConfirmQuit
  else
    Result := FInner.ConfirmQuit;
end;

procedure TGreedScreenView.DrawOverlay(var AFrame: TGreedFrame; const AOverlay: TGreedViewOverlay);
begin
  FInner.DrawOverlay(AFrame, AOverlay);
end;

end.
