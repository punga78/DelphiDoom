{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the game as the introduction sees it             }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): the calls of dointro of     }
{  intro.pas to the game                                                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.IntroHost;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Game, DelphiDoom.Greed.Intro;

type
  /// <summary>IGreedIntroHost on a TGreedGame: the song of the introduction and the flags that say how it ended</summary>
  TGreedIntroHost = class(TInterfacedObject, IGreedIntroHost)
  strict private
    FGame: TGreedGame;
  public
    /// <summary>AGame is not owned; EArgumentNilException if it is nil</summary>
    constructor Create(AGame: TGreedGame);
    procedure BeginIntro;
    procedure UpdateSound;
    function QuitRequested: Boolean;
    function GameLoaded: Boolean;
  end;

implementation

const
  INTRO_SONG = 'INTRO.S3M';

{ TGreedIntroHost }

constructor TGreedIntroHost.Create(AGame: TGreedGame);
begin
  inherited Create;
  if not Assigned(AGame) then
    raise EArgumentNilException.Create('AGame');
  FGame := AGame;
end;

procedure TGreedIntroHost.BeginIntro;
begin
  FGame.Parts.Music.Play(INTRO_SONG, 0);
  FGame.State.QuitGame := False;
  FGame.State.GameLoaded := False;
end;

procedure TGreedIntroHost.UpdateSound;
begin
  // the mixer of the sound runs on its own thread: there is nothing to feed
end;

function TGreedIntroHost.QuitRequested: Boolean;
begin
  Result := FGame.State.QuitGame;
end;

function TGreedIntroHost.GameLoaded: Boolean;
begin
  Result := FGame.State.GameLoaded;
end;

end.
