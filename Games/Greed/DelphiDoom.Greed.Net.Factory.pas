{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the net game: where a session is made            }
{  Port of xGreed (Jim Valavanis): what "-net" does in                          }
{  intro.pas (netmode, NetInit) before the game starts                          }
{                                                                              }
{  xGreed (Jim Valavanis) and Raven 3D engine (c) 1996 Softdisk Publishing:    }
{  the user declares this port GPL v2 or later; the right on the parts         }
{  derived from the Softdisk code is not verified (docs\LICENZE.md)            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Net.Factory;

interface

uses
  System.SysUtils, DelphiDoom.Net.Transport.Intf, DelphiDoom.Greed.Game, DelphiDoom.Greed.Net.Types,
  DelphiDoom.Greed.Net.Intf;

type
  /// <summary>
  ///   The only place that knows the class of the session of the net game: it makes one for a game and gives it
  ///   to the game
  /// </summary>
  TGreedNetFactory = class
  public
    /// <summary>
    ///   A session for AGame over ATransport (an INetTransport of IdTech1\Net: the UDP one, or a fake one in the
    ///   tests), with the parts of that game; the game becomes a net game (TGreedGame.AttachNet). To call before
    ///   TGreedGame.NewGame. What comes back is the wait for the other players: after NewGame the program calls
    ///   BeginWaitStart and then WaitStartStep, while the clock of the game goes on, until it says true.
    ///   The session must not be used after the game was freed. EArgumentNilException if AGame or ATransport is
    ///   nil; EGreedNetException if AConfig is not of a game of 1..8 players
    /// </summary>
    class function Attach(AGame: TGreedGame; const ATransport: INetTransport;
      const AConfig: TGreedNetConfig): IGreedNetStart; static;
  end;

implementation

uses
  DelphiDoom.Greed.Game.Intf, DelphiDoom.Greed.Net.Session;

{ TGreedNetFactory }

class function TGreedNetFactory.Attach(AGame: TGreedGame; const ATransport: INetTransport;
  const AConfig: TGreedNetConfig): IGreedNetStart;
var
  LSession: TGreedNetSession;
  LHost: IGreedNetHost;
begin
  if not Assigned(AGame) then
    raise EArgumentNilException.Create('AGame');
  // the host of the logic of the game answers the sound, the score and the calls of the packets
  LHost := AGame.NetHost;
  LSession := TGreedNetSession.Create(AGame.State, ATransport, AConfig, AGame.Parts.Archive, AGame.Parts.SpawnerIntf,
    LHost as IGreedGameSound, AGame.Parts.Messages, LHost as IGreedPlayerHealth, AGame.Parts.Random,
    AGame.Parts.EventsIntf, LHost);
  Result := LSession;
  AGame.AttachNet(LSession);
end;

end.
