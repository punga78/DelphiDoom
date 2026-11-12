{******************************************************************************}
{                                                                              }
{  Greed32: the HUD of the game: canvas, fonts, status bar, weapon, messages    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.HudView;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf, DelphiDoom.Greed.Frame.Intf,
  DelphiDoom.Greed.Game.Intf, DelphiDoom.Greed.GameView.Intf, DelphiDoom.Greed.Game, DelphiDoom.Greed.Canvas,
  DelphiDoom.Greed.Font, DelphiDoom.Greed.TextPrinter, DelphiDoom.Greed.Hud, DelphiDoom.Greed.MessageLine,
  DelphiDoom.Greed.WeaponPainter;

type
  /// <summary>
  ///   IGreedGameView and IGreedMessages on the HUD of the library: after the view of the level it clears the
  ///   canvas of 320 x 200 pixels, draws the holo suit, the weapon, the map modes, the status bar and the message
  ///   line on it and puts it over the frame (UpdateView of the original, from DrawHolo to rewritemsg). The game
  ///   needs its view and its message line to be made, and they need its state: the object is made first, gives
  ///   the messages that are written before the game exists to the line when Attach is called, and makes the HUD
  ///   then. The screens between the maps, the films and the menus are not here (they are a job of another unit):
  ///   the menu and the quick exit end the game. Not drawn: the rear view camera (the game does not make its
  ///   picture)
  /// </summary>
  TGreedHudView = class(TInterfacedObject, IGreedGameView, IGreedMessages)
  strict private
    FArchive: IGreedArchive;
    FGame: TGreedGame;
    FCanvas: TGreedCanvas;
    FPrinter: TGreedTextPrinter;
    FFont1, FFont2, FFont3: TGreedFont;
    FHud: TGreedHud;
    FPainter: TGreedWeaponPainter;
    FLine: TGreedMessageLine;
    FLineIntf: IGreedMessages;
    FEcho: Boolean;
    FBefore: TStringList;
    FLoggedMessages: TStringList;
    function LoadFont(const AName: string): TGreedFont;
  public
    /// <summary>EArgumentNilException if AArchive is nil</summary>
    constructor Create(const AArchive: IGreedArchive);
    destructor Destroy; override;
    /// <summary>
    ///   Makes the HUD on the state of AGame (the game keeps no reference to this object that is not an
    ///   interface): ApproxZero is 0, the transparency table is the lump TRANSPARENCY, the fonts are FONT1 .. FONT3
    ///   and the size of the view is the one of the settings (4)
    /// </summary>
    procedure Attach(AGame: TGreedGame);
    // IGreedGameView
    procedure RefreshAmmo;
    procedure RefreshGoalItem;
    procedure ResetDisplay;
    procedure ResetMessages;
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
    // IGreedMessages
    procedure WriteMessage(const AText: string);
    /// <summary>Every message of the game, in order (a list for the proofs without a window)</summary>
    property Messages: TStringList read FLoggedMessages;
    /// <summary>The messages are also written on the console</summary>
    property Echo: Boolean read FEcho write FEcho;
  end;

implementation

uses
  DelphiDoom.Greed.GameRenderer.Intf, DelphiDoom.Greed.Hud.Intf;

const
  LUMP_TRANSPARENCY = 'TRANSPARENCY';
  LUMP_FONT = 'FONT';
  SETTINGS_VIEW_SIZE = 4;

{ TGreedHudView }

constructor TGreedHudView.Create(const AArchive: IGreedArchive);
begin
  inherited Create;
  if not Assigned(AArchive) then
    raise EArgumentNilException.Create('AArchive');
  FArchive := AArchive;
  FBefore := TStringList.Create;
  FLoggedMessages := TStringList.Create;
end;

destructor TGreedHudView.Destroy;
begin
  FLineIntf := nil;
  FLine := nil;
  FPainter.Free;
  FHud.Free;
  FPrinter.Free;
  FFont3.Free;
  FFont2.Free;
  FFont1.Free;
  FCanvas.Free;
  FLoggedMessages.Free;
  FBefore.Free;
  inherited Destroy;
end;

function TGreedHudView.LoadFont(const AName: string): TGreedFont;
begin
  Result := TGreedFont.Create(FArchive.ReadLump(FArchive.RequireIndexOf(AName)));
end;

procedure TGreedHudView.Attach(AGame: TGreedGame);
var
  LIndex: Integer;
begin
  if not Assigned(AGame) then
    raise EArgumentNilException.Create('AGame');
  FGame := AGame;
  FCanvas := TGreedCanvas.Create;
  FCanvas.ApproxZero := 0;
  FCanvas.SetTransparency(FArchive.ReadLump(FArchive.RequireIndexOf(LUMP_TRANSPARENCY)));
  FFont1 := LoadFont(LUMP_FONT + '1');
  FFont2 := LoadFont(LUMP_FONT + '2');
  FFont3 := LoadFont(LUMP_FONT + '3');
  FPrinter := TGreedTextPrinter.Create(FCanvas);
  FHud := TGreedHud.Create(AGame.State, FCanvas, FPrinter, AGame.Inventory, FArchive,
    AGame.Parts.Renderer.TileLightReader, FFont2, FFont3);
  FHud.CurrentViewSize := SETTINGS_VIEW_SIZE;
  FHud.WindowWidth := GREED_GAME_VIEW_WIDTH;
  FHud.WindowHeight := GREED_GAME_VIEW_HEIGHT;
  FPainter := TGreedWeaponPainter.Create(AGame.State, AGame.Parts.WeaponPictures, FArchive, FCanvas,
    AGame.Parts.Renderer.WeaponLight);
  FLine := TGreedMessageLine.Create(AGame.State, FPrinter, FFont1);
  FLineIntf := FLine;
  for LIndex := 0 to FBefore.Count - 1 do
    FLineIntf.WriteMessage(FBefore[LIndex]);
  FBefore.Clear;
end;

procedure TGreedHudView.RefreshAmmo;
begin
  if Assigned(FHud) then
    FHud.RefreshAmmo;
end;

procedure TGreedHudView.RefreshGoalItem;
begin
  if Assigned(FHud) then
    FHud.RefreshGoalItem;
end;

procedure TGreedHudView.ResetDisplay;
begin
  if Assigned(FHud) then
    FHud.ResetDisplay;
end;

procedure TGreedHudView.ResetMessages;
begin
  if Assigned(FLine) then
    FLine.TimeMessage := 0;
end;

procedure TGreedHudView.SetTotalEffectTime(ATics: Integer);
begin
  if Assigned(FHud) then
    FHud.SetTotalEffectTime(ATics);
end;

procedure TGreedHudView.MissionBriefing(AMap: Integer);
begin
end;

procedure TGreedHudView.EndGame(AEpisode: Integer);
begin
  WriteMessage(Format('End of the episode %d', [AEpisode]));
end;

procedure TGreedHudView.PlayFli(AMovie: Integer);
begin
  WriteMessage(Format('Film %d', [AMovie]));
end;

procedure TGreedHudView.StartWait;
begin
end;

procedure TGreedHudView.UpdateWait;
begin
end;

procedure TGreedHudView.EndWait;
begin
end;

procedure TGreedHudView.FadeOutLevel;
begin
end;

procedure TGreedHudView.ChangeViewSize(ABigger: Boolean);
begin
  if Assigned(FHud) then
    FHud.ChangeViewSize(ABigger);
end;

procedure TGreedHudView.SetGameEpisode(AEpisode: Integer);
begin
end;

function TGreedHudView.ShowMenu: Boolean;
begin
  // there is no menu yet: Escape leaves the game
  Result := True;
end;

procedure TGreedHudView.ShowHelp;
begin
end;

procedure TGreedHudView.ShowPause;
begin
end;

function TGreedHudView.ConfirmQuit: Boolean;
begin
  Result := True;
end;

procedure TGreedHudView.DrawOverlay(var AFrame: TGreedFrame; const AOverlay: TGreedViewOverlay);
begin
  if not Assigned(FHud) then
    Exit;
  FCanvas.Clear;
  if FGame.State.Player.HoloPic <> 0 then
    FHud.DrawHolo;
  if AOverlay.WeaponVisible then
    FPainter.Draw(AOverlay.WeaponX, AOverlay.WeaponY, GREED_GAME_VIEW_HEIGHT);
  FHud.DrawOverlay;
  FLine.Rewrite(FHud.CurrentViewSize);
  FCanvas.ComposeOnto(AFrame);
end;

procedure TGreedHudView.WriteMessage(const AText: string);
begin
  FLoggedMessages.Add(AText);
  if FEcho then
    Writeln(AText);
  if Assigned(FLineIntf) then
    FLineIntf.WriteMessage(AText)
  else
    FBefore.Add(AText);
end;

end.
