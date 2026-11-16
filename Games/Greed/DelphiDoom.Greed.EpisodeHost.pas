{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the game as the briefings and the endings see it }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): the calls of               }
{  MissionBriefing, EndGame1, EndGame2 and EndGame3 of utils.pas to the game    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.EpisodeHost;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Game, DelphiDoom.Greed.Briefing, DelphiDoom.Greed.EndGame;

type
  /// <summary>
  ///   IGreedBriefingHost and IGreedEndGameHost on a TGreedGame: the player of the second and of the third episode
  ///   starts as a new hunter, and the songs of the screens are chosen as selectsong does
  /// </summary>
  TGreedEpisodeHost = class(TInterfacedObject, IGreedBriefingHost, IGreedEndGameHost)
  strict private
    FGame: TGreedGame;
  public
    /// <summary>AGame is not owned; EArgumentNilException if it is nil</summary>
    constructor Create(AGame: TGreedGame);
    procedure StartEpisode(AMap: Integer);
    procedure SelectSong(ASong: Integer);
  end;

implementation

uses
  DelphiDoom.Greed.SongSelector;

{ TGreedEpisodeHost }

constructor TGreedEpisodeHost.Create(AGame: TGreedGame);
begin
  inherited Create;
  if not Assigned(AGame) then
    raise EArgumentNilException.Create('AGame');
  FGame := AGame;
end;

procedure TGreedEpisodeHost.StartEpisode(AMap: Integer);
var
  LIndex: Integer;
begin
  // the same start as a level that is begun again: the score of the level, the first two weapons, a new inventory
  FGame.State.Player.LevelScore := FGame.State.LevelScore;
  FGame.State.Player.Weapons[2] := -1;
  FGame.State.Player.Weapons[3] := -1;
  FGame.State.Player.Weapons[4] := -1;
  FGame.State.Player.CurrentWeapon := 0;
  FGame.Parts.WeaponView.LoadWeapon(FGame.State.Player.Weapons[0]);
  for LIndex := Low(FGame.State.Player.Inventory) to High(FGame.State.Player.Inventory) do
    FGame.State.Player.Inventory[LIndex] := 0;
  FGame.State.Player.Inventory[7] := 2;
  FGame.State.Player.Inventory[5] := 2;
  FGame.State.Player.Inventory[4] := 2;
  FGame.State.Player.Inventory[2] := 4;
  FGame.State.Player.Ammo[0] := 100;
  FGame.State.Player.Ammo[1] := 100;
  FGame.State.Player.Ammo[2] := 100;
  FGame.State.Player.Angst := FGame.State.Player.MaxAngst;
  FGame.State.Player.Shield := 200;
end;

procedure TGreedEpisodeHost.SelectSong(ASong: Integer);
var
  LSong: TGreedSong;
begin
  LSong := TGreedSongSelector.Select(ASong, FGame.State.Demo, False);
  FGame.Parts.Music.Play(LSong.FileName, LSong.Pattern);
end;

end.
