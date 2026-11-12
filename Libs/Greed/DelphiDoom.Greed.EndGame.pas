{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the end of an episode                            }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): EndGame1, EndGame2 and      }
{  EndGame3 of utils.pas                                                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.EndGame;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Intf, DelphiDoom.Greed.Save.Intf, DelphiDoom.Greed.Font,
  DelphiDoom.Greed.TextPrinter, DelphiDoom.Greed.Display, DelphiDoom.Greed.MenuInput, DelphiDoom.Greed.FliPlayer,
  DelphiDoom.Greed.ScreenScript;

type
  /// <summary>What the endings ask to the game</summary>
  IGreedEndGameHost = interface
    ['{4D9B2C6E-A153-4F87-8E0A-B7C5D3916F42}']
    /// <summary>selectsong(22) at the start of the first and of the second ending</summary>
    procedure SelectSong(ASong: Integer);
  end;

  /// <summary>
  ///   EndGame1, EndGame2 and EndGame3 without their loops: Start(episode) does what the original does up to its
  ///   first wait, each Tick is a tic of the timer, Active is false when the original would have returned (the
  ///   original then sets redo: the caller starts the intro again without the title screens). An ending is the
  ///   movies of the episode, the screen REDCHARS with the closing text in nine shades of red (all drawn at once)
  ///   until a key, then SOFTLOGO, CREDITS1, CREDITS2 and CREDITS3, a key for each; a picture that is not in the
  ///   archive is skipped. The first ending of the Assassinator edition has no CREDITS3
  /// </summary>
  TGreedEndGame = class
  strict private
    FScript: TGreedScreenScript;
    FHost: IGreedEndGameHost;
    FVariant: TGreedGameVariant;
    FAssassinator: Boolean;
    procedure Credits(const AScreen: string; ALabel: Integer);
  public
    /// <summary>EArgumentNilException for a missing dependency (AMovies may be nil)</summary>
    constructor Create(ADisplay: TGreedDisplay; AInput: TGreedMenuInput; APrinter: TGreedTextPrinter;
      AFont1: TGreedFont; APlayer: TGreedFliPlayer; const AMovies: IGreedExternalFiles;
      const AHost: IGreedEndGameHost; AVariant: TGreedGameVariant; AAssassinator: Boolean = False);
    destructor Destroy; override;
    /// <summary>EndGame1, EndGame2 or EndGame3; EGreedException for another number</summary>
    procedure Start(AEpisode: Integer);
    procedure Tick;
    function Active: Boolean;
  end;

implementation

uses
  DelphiDoom.Greed.Types;

const
  TIC_RATE = 70;
  SGreedEndGameEpisode = 'Greed: there is no ending for the episode %d';

  SEnding1 =
    'BY SUCCESSFULLY BRAVING THE DESARIAN'#13#10 +
    'PENAL COLONY YOU EMERGE VICTORIOUS'#13#10 +
    'WITH THE BRASS RING OF BYZANT IN HAND.'#13#10 +
    '...BUT IT''S NOT OVER YET, HUNTER.'#13#10 +
    'IT''S ON TO PHASE TWO OF THE HUNT, THE'#13#10 +
    'CITY TEMPLE OF RISTANAK.  ARE YOU'#13#10 +
    'PREPARED TO FACE THE Y''RKTARELIAN'#13#10 +
    'PRIESTHOOD AND THEIR PAGAN GOD?'#13#10 +
    'NOT BLOODY LIKELY...'#13#10#13#10#13#10#13#10#13#10#13#10 +
    'TO BE CONTINUED...'#13#10;
  SEnding2 =
    'WITH Y''RKTAREL DEAD AND THE PRIESTHOOD'#13#10 +
    'IN RUINS CONGRATULATE YOURSELF, HUNTER.'#13#10 +
    'YOU''VE ANNHILIATED YET ANOTHER CULTURE'#13#10 +
    'ALL FOR THE SAKE OF THE HUNT.'#13#10 +
    '...BUT DON''T RELAX YET, FOR IT''S ON TO'#13#10 +
    'PHASE THREE OF THE HUNT.  THIS TIME'#13#10 +
    'YOU''LL BATTLE AN ENTIRE ARMY AS YOU FACE'#13#10 +
    'OFF WITH LORD KAAL IN HIS SPACEBORN'#13#10 +
    'MOUNTAIN CITADEL.'#13#10 +
    'DO YOU HAVE WHAT IT TAKES TO SLAY LORD'#13#10 +
    'KAAL AND WREST FROM HIM THE IMPERIAL SIGIL?'#13#10#13#10#13#10#13#10#13#10#13#10 +
    'TO BE CONTINUED...'#13#10;
  SEnding3Tail =
    'VESTIGES OF MILITARY AUTHORITY FOR THE SECTOR.'#13#10 +
    'YOU COULD HAVE RICHES, FAME AND POWER,'#13#10 +
    'AND YOUR CHOICE OF PLEASURE PLANETS.'#13#10 +
    'UNFORTUNATELY, YOU''RE STUCK ON A SHIP THAT''S'#13#10 +
    'DRIFTING THROUGH HYPERSPACE.  IN SHORT'#13#10 +
    'YOU''RE LOST.  LUCKY FOR THE PASSENGERS'#13#10 +
    'THAT YOU''RE A HEROIC HUNTER THAT CAN SAVE'#13#10 +
    'THEM FROM THEIR FATE IN THE CLUTCHES'#13#10 +
    'OF THE MAZDEEN EMPEROR.  OR CAN YOU?'#13#10#13#10#13#10#13#10#13#10#13#10 +
    'TO BE CONTINUED...'#13#10;
  // the third game alone: the hunter has not seen the first two episodes
  SEnding3Alone =
    'WELL, YOU SUCCESSFULLY PULLED DOWN THE LAST'#13#10 + SEnding3Tail;
  SEnding3 =
    'WELL, YOU SUCCESSFULLY BRAVED A BLOODY RIOT, FACED'#13#10 +
    'A GOD AND SURVIVED, AND PULLED DOWN THE LAST'#13#10 + SEnding3Tail;

{ TGreedEndGame }

constructor TGreedEndGame.Create(ADisplay: TGreedDisplay; AInput: TGreedMenuInput; APrinter: TGreedTextPrinter;
  AFont1: TGreedFont; APlayer: TGreedFliPlayer; const AMovies: IGreedExternalFiles;
  const AHost: IGreedEndGameHost; AVariant: TGreedGameVariant; AAssassinator: Boolean);
begin
  inherited Create;
  if not Assigned(AHost) then
    raise EArgumentNilException.Create('AHost');
  // the script checks the others
  FScript := TGreedScreenScript.Create(ADisplay, AInput, APrinter, AFont1, APlayer, AMovies);
  FHost := AHost;
  FVariant := AVariant;
  FAssassinator := AAssassinator;
end;

destructor TGreedEndGame.Destroy;
begin
  FScript.Free;
  inherited;
end;

function TGreedEndGame.Active: Boolean;
begin
  Result := FScript.Active;
end;

procedure TGreedEndGame.Tick;
begin
  FScript.Tick;
end;

procedure TGreedEndGame.Credits(const AScreen: string; ALabel: Integer);
begin
  FScript.LoadScreen(AScreen, gsmSkip, ALabel);
  FScript.FadeIn(48);
  FScript.ClearNewAscii;
  FScript.WaitKey;
  FScript.FadeOut(0, 0, 0, 48);
  FScript.FillScreen(0);
  FScript.Mark(ALabel);
end;

procedure TGreedEndGame.Start(AEpisode: Integer);
var
  LText: string;
begin
  if (AEpisode < 1) or (AEpisode > 3) then
    raise EGreedException.CreateFmt(SGreedEndGameEpisode, [AEpisode]);
  FScript.Clear;
  if AEpisode < 3 then
    FHost.SelectSong(22);
  case AEpisode of
    1:
      begin
        FScript.Movie('PRISON1.FLI');
        FScript.Movie('TEMPLE1.FLI');
        LText := SEnding1;
      end;
    2:
      begin
        FScript.Movie('TEMPLE2.FLI');
        FScript.Movie('JUMPBAS1.FLI');
        FScript.Movie('JUMPBAS2.FLI');
        LText := SEnding2;
      end;
  else
    FScript.Movie('JUMPBAS3.FLI');
    FScript.Movie('JUMPBAS4.FLI');
    FScript.Movie('JUMPBAS5.FLI');
    FScript.Movie('JUMPBAS6.FLI');
    FScript.Movie('JUMPBS6B.FLI');
    FScript.Movie('JUMPBAS7.FLI');
    FScript.Movie('JUMPBAS8.FLI');
    FScript.Movie('JUMPBAS9.FLI');
    if FVariant = ggvGame3 then
      LText := SEnding3Alone
    else
      LText := SEnding3;
  end;
  FScript.FillPalette(0, 0, 0);
  FScript.LoadScreen('REDCHARS');
  FScript.FadeIn(48);
  FScript.Wait(2 * TIC_RATE);
  FScript.TextFade(80, [LText], 64, 73, 0);
  FScript.ClearNewAscii;
  FScript.WaitKey;
  FScript.FadeOut(0, 0, 0, 48);
  FScript.FillScreen(0);
  Credits('SOFTLOGO', 1);
  Credits('CREDITS1', 2);
  Credits('CREDITS2', 3);
  if (AEpisode <> 1) or not FAssassinator then
    Credits('CREDITS3', 4);
  FScript.Start;
end;

end.
