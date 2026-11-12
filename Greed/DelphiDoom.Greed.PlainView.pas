{******************************************************************************}
{                                                                              }
{  Greed32: the view of the game without status bar, menus and films           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.PlainView;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf, DelphiDoom.Greed.Frame.Intf,
  DelphiDoom.Greed.Game.Intf, DelphiDoom.Greed.GameView.Intf;

type
  /// <summary>
  ///   The least IGreedGameView and IGreedMessages that make a game: over the view of the level it draws only the
  ///   picture of the weapon (masked with the colour 0, scaled from the 320 x 200 view to the size of the frame);
  ///   the messages of the game are kept in a list (and written on the console if Echo is set); the menu and the
  ///   quick exit end the game; the screens between the maps, the films, the status bar and the map modes are not
  ///   drawn (the port of display.pas, menu.pas and playfli.pas takes this place)
  /// </summary>
  TGreedPlainView = class(TInterfacedObject, IGreedGameView, IGreedMessages)
  strict private
    FArchive: IGreedArchive;
    FMessages: TStringList;
    FEcho: Boolean;
    FPictureLump: Integer;
    FPicture: TGreedImage;
    procedure LoadPicture(ALump: Integer);
  public
    /// <summary>EArgumentNilException if AArchive is nil</summary>
    constructor Create(const AArchive: IGreedArchive);
    destructor Destroy; override;
    // IGreedGameView
    procedure RefreshInventory;
    procedure RefreshAmmo;
    procedure RefreshGoalItem;
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
    // IGreedMessages
    procedure WriteMessage(const AText: string);
    /// <summary>Every message of the game, in order</summary>
    property Messages: TStringList read FMessages;
    /// <summary>The messages are also written on the console</summary>
    property Echo: Boolean read FEcho write FEcho;
  end;

implementation

uses
  DelphiDoom.Greed.PictureDecoder, DelphiDoom.Greed.Game;

{ TGreedPlainView }

constructor TGreedPlainView.Create(const AArchive: IGreedArchive);
begin
  inherited Create;
  if not Assigned(AArchive) then
    raise EArgumentNilException.Create('AArchive');
  FArchive := AArchive;
  FMessages := TStringList.Create;
  FPictureLump := -1;
end;

destructor TGreedPlainView.Destroy;
begin
  FMessages.Free;
  inherited Destroy;
end;

procedure TGreedPlainView.RefreshInventory;
begin
end;

procedure TGreedPlainView.RefreshAmmo;
begin
end;

procedure TGreedPlainView.RefreshGoalItem;
begin
end;

procedure TGreedPlainView.ResetDisplay;
begin
end;

procedure TGreedPlainView.SetTotalEffectTime(ATics: Integer);
begin
end;

procedure TGreedPlainView.MissionBriefing(AMap: Integer);
begin
end;

procedure TGreedPlainView.EndGame(AEpisode: Integer);
begin
  WriteMessage(Format('End of the episode %d', [AEpisode]));
end;

procedure TGreedPlainView.PlayFli(AMovie: Integer);
begin
  WriteMessage(Format('Film %d', [AMovie]));
end;

procedure TGreedPlainView.StartWait;
begin
end;

procedure TGreedPlainView.UpdateWait;
begin
end;

procedure TGreedPlainView.EndWait;
begin
end;

procedure TGreedPlainView.FadeOutLevel;
begin
end;

procedure TGreedPlainView.ChangeViewSize(ABigger: Boolean);
begin
end;

procedure TGreedPlainView.SetGameEpisode(AEpisode: Integer);
begin
end;

function TGreedPlainView.ShowMenu: Boolean;
begin
  // there is no menu: Escape leaves the game
  Result := True;
end;

procedure TGreedPlainView.ShowHelp;
begin
end;

procedure TGreedPlainView.ShowPause;
begin
end;

function TGreedPlainView.ConfirmQuit: Boolean;
begin
  Result := True;
end;

procedure TGreedPlainView.LoadPicture(ALump: Integer);
var
  LDecoder: IGreedImageDecoder;
begin
  FPictureLump := ALump;
  FPicture := Default(TGreedImage);
  if (ALump < 0) or (ALump >= FArchive.LumpCount) then
    Exit;
  LDecoder := TGreedPictureDecoder.Create;
  try
    FPicture := LDecoder.Decode(FArchive.ReadLump(ALump));
  except
    // a lump that is not a picture draws nothing
    on EGreedDataException do
      FPicture := Default(TGreedImage);
  end;
end;

procedure TGreedPlainView.DrawOverlay(var AFrame: TGreedFrame; const AOverlay: TGreedViewOverlay);
var
  LX, LY, LSourceX, LSourceY: Integer;
  LPixel: Byte;
begin
  if (not AOverlay.WeaponVisible) or (AOverlay.WeaponLump < 0) then
    Exit;
  if AOverlay.WeaponLump <> FPictureLump then
    LoadPicture(AOverlay.WeaponLump);
  if (FPicture.Width = 0) or (AFrame.Width < 1) or (AFrame.Height < 1) then
    Exit;
  // the weapon is placed in the 320 x 200 view: the frame can be larger
  for LY := 0 to AFrame.Height - 1 do
  begin
    LSourceY := LY * GREED_GAME_VIEW_HEIGHT div AFrame.Height - AOverlay.WeaponY;
    if (LSourceY < 0) or (LSourceY >= FPicture.Height) then
      Continue;
    for LX := 0 to AFrame.Width - 1 do
    begin
      LSourceX := LX * GREED_GAME_VIEW_WIDTH div AFrame.Width - AOverlay.WeaponX;
      if (LSourceX < 0) or (LSourceX >= FPicture.Width) then
        Continue;
      LPixel := FPicture.Pixels[LSourceY * FPicture.Width + LSourceX];
      if LPixel <> 0 then
        AFrame.Pixels[LY * AFrame.Width + LX] := LPixel;
    end;
  end;
end;

procedure TGreedPlainView.WriteMessage(const AText: string);
begin
  FMessages.Add(AText);
  if FEcho then
    Writeln(AText);
end;

end.
