{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the net game: packets, constants and errors      }
{  Port of xGreed (Jim Valavanis): the types of net.pas (the                    }
{  code that xGreed keeps in a comment after "end.") and greedcom_t of          }
{  protos_h.pas                                                                 }
{                                                                              }
{  xGreed (Jim Valavanis) and Raven 3D engine (c) 1996 Softdisk Publishing:    }
{  the user declares this port GPL v2 or later; the right on the parts         }
{  derived from the Softdisk code is not verified (docs\LICENZE.md)            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Net.Types;

interface

uses
  DelphiDoom.Greed.Types, DelphiDoom.Greed.SaveTypes;

const
  /// <summary>GREEDCOM_ID: what the driver of the DOS game wrote in greedcom.id</summary>
  GREED_NET_COM_ID = Integer($C7C7C7C7);
  /// <summary>NETIPX, NETSERIAL, NETMODEM: greedcom.nettype</summary>
  GREED_NET_IPX = 1;
  GREED_NET_SERIAL = 2;
  GREED_NET_MODEM = 3;
  /// <summary>GCMAXDATALENGTH: the bytes of greedcom.data, the buffer that every packet is built in and read from</summary>
  GREED_NET_MAX_DATA = 128;

  /// <summary>The id of a packet: its first 32 bit number (INITEVENTID .. MESSAGEEVENTID)</summary>
  GREED_NET_EVENT_INIT = 1;
  GREED_NET_EVENT_PLAYER = 2;
  GREED_NET_EVENT_SPAWN = 3;
  GREED_NET_EVENT_QUIT = 4;
  GREED_NET_EVENT_DOOR = 5;
  GREED_NET_EVENT_FRAG = 6;
  GREED_NET_EVENT_NEW_PLAYER = 7;
  GREED_NET_EVENT_ITEM = 8;
  GREED_NET_EVENT_BONUS = 9;
  GREED_NET_EVENT_PAUSE = 10;
  GREED_NET_EVENT_UNPAUSE = 11;
  GREED_NET_EVENT_TRIGGER = 12;
  GREED_NET_EVENT_SOUND = 13;
  GREED_NET_EVENT_JAMMER = 14;
  GREED_NET_EVENT_EVENT = 15;
  GREED_NET_EVENT_MESSAGE = 16;

  /// <summary>The bytes of a name of a player (char netname[13]): 12 characters and the zero</summary>
  GREED_NET_NAME_SIZE = 13;
  /// <summary>NETMSGSIZE: the bytes of the text of a message (char message[30])</summary>
  GREED_NET_TEXT_SIZE = 30;
  /// <summary>NetQuitGame says NetDeath(255): a death that nobody caused</summary>
  GREED_NET_NO_KILLER = 255;

  /// <summary>pevent.status of a player: nothing, was hit, is firing</summary>
  GREED_NET_STATUS_HIT = 1;
  GREED_NET_STATUS_FIRING = 2;

  /// <summary>The tics that NetWaitStart waits for the other players (10 minutes at 70 tics)</summary>
  GREED_NET_START_TIMEOUT = 42000;
  /// <summary>The tics between two "here I am" packets of NetWaitStart</summary>
  GREED_NET_START_PERIOD = 140;
  /// <summary>netwarpjamtime: the tics that the warp jammer of another player lasts</summary>
  GREED_NET_WARP_JAM_TICS = 70 * 60;

type
  /// <summary>Every failure of the net game of Greed (MS_Error of net.pas)</summary>
  EGreedNetException = class(EGreedException);

  TGreedNetName = packed array[0..GREED_NET_NAME_SIZE - 1] of AnsiChar;
  TGreedNetText = packed array[0..GREED_NET_TEXT_SIZE - 1] of AnsiChar;

  /// <summary>
  ///   The packets of the net game, as the C structures of net.pas: little endian 32 bit numbers, on the wire as
  ///   they are in memory. The two with a text (ievent_t, mevent_t) have the padding that the 32 bit C compiler
  ///   of the DOS game put after the text to align the next number (and the size) to 4 bytes: 40 bytes each. The
  ///   DOS game and its drivers can not be reached from here (see TGreedNetSession), so this choice has no
  ///   witness: it is the layout of a C compiler with its default alignment.
  ///   ievent_t: sent while the players wait for each other at the start
  /// </summary>
  TGreedNetInitEvent = packed record
    Id: Integer;
    PlayerId: Integer;
    /// <summary>How many players the sender has heard of, itself included</summary>
    Found: Integer;
    /// <summary>Player 0 counts here the players that have found everybody: the game starts when it is all of them</summary>
    Start: Integer;
    NetName: TGreedNetName;
    Padding: packed array[0..2] of Byte;
    Map: Integer;
    Difficulty: Integer;
  end;

  /// <summary>sevent_t: a sprite was made (a shot, a mine, a monster of a spawn area)</summary>
  TGreedNetSpawnEvent = packed record
    Id: Integer;
    PlayerId: Integer;
    Value: Integer;
    X: TGreedFixed;
    Y: TGreedFixed;
    Z: TGreedFixed;
    ZAdjust: TGreedFixed;
    Angle: Integer;
    Angle2: Integer;
    Active: Integer;
    SpawnId: Integer;
  end;

  /// <summary>qevent_t: quit, pause, unpause, warp jammer: only who did it</summary>
  TGreedNetPlayerOnlyEvent = packed record
    Id: Integer;
    PlayerId: Integer;
  end;

  /// <summary>devent_t: a door opened by a player, or a trigger flipped (the angle is of the trigger only)</summary>
  TGreedNetDoorEvent = packed record
    Id: Integer;
    PlayerId: Integer;
    X: TGreedFixed;
    Y: TGreedFixed;
    Angle: Integer;
  end;

  /// <summary>fevent_t: the sender died (BulletId is the player whose shot it was), or an event of the script ran</summary>
  TGreedNetFragEvent = packed record
    Id: Integer;
    PlayerId: Integer;
    BulletId: Integer;
  end;

  /// <summary>bevent_t: player 0 put the bonus item somewhere</summary>
  TGreedNetBonusEvent = packed record
    Id: Integer;
    PlayerId: Integer;
    Time: Integer;
    Score: Integer;
    TileX: Integer;
    TileY: Integer;
    Num: Integer;
  end;

  /// <summary>ipevent_t: the sender picked up what was on a tile</summary>
  TGreedNetItemEvent = packed record
    Id: Integer;
    PlayerId: Integer;
    TileX: Integer;
    TileY: Integer;
    MapSpot: Integer;
    /// <summary>type: the value of mapsprites of the tile when it was picked up</summary>
    Kind: Integer;
    CharType: Integer;
  end;

  /// <summary>eevent_t: a sound that the others must hear too</summary>
  TGreedNetSoundEvent = packed record
    Id: Integer;
    PlayerId: Integer;
    X: TGreedFixed;
    Y: TGreedFixed;
    Effect: Integer;
    Variation: Integer;
  end;

  /// <summary>mevent_t: a line of text typed by a player</summary>
  TGreedNetMessageEvent = packed record
    Id: Integer;
    PlayerId: Integer;
    Text: TGreedNetText;
    Padding: packed array[0..1] of Byte;
  end;

  /// <summary>
  ///   What the driver of the DOS game (NETGREED.EXE for IPX, SERGREED.EXE for serial line and modem) wrote in
  ///   greedcom_t before it started the game, and the name of SC.netname: who this computer is in the game
  /// </summary>
  TGreedNetConfig = record
    /// <summary>greedcom.consoleplayer: 0 .. NumPlayers - 1; player 0 decides the start, the bonus item, the monsters</summary>
    ConsolePlayer: Integer;
    /// <summary>greedcom.numplayers: 1 .. GREED_MAX_PLAYERS</summary>
    NumPlayers: Integer;
    /// <summary>greedcom.nettype: GREED_NET_IPX, GREED_NET_SERIAL or GREED_NET_MODEM</summary>
    NetType: Integer;
    /// <summary>SC.netname: at most 12 characters travel</summary>
    NetName: AnsiString;
    /// <summary>A game of that many players on an IPX-like net (every packet goes to everybody)</summary>
    class function Make(AConsolePlayer, ANumPlayers: Integer; const ANetName: AnsiString): TGreedNetConfig; static;
  end;

const
  SGreedNetUnknownType = 'Unknown net type!';
  SGreedNetBadPlayers = 'Net game: %d players, this is player %d';
  SGreedNetTimeOut = 'Multiplayer synch time-out error';
  SGreedNetDifferentMap = 'Player #%d is playing a different map!';
  SGreedNetNotWaiting = 'Net game: the wait for the start was not begun';

implementation

{ TGreedNetConfig }

class function TGreedNetConfig.Make(AConsolePlayer, ANumPlayers: Integer;
  const ANetName: AnsiString): TGreedNetConfig;
begin
  Result.ConsolePlayer := AConsolePlayer;
  Result.NumPlayers := ANumPlayers;
  Result.NetType := GREED_NET_IPX;
  Result.NetName := ANetName;
end;

end.
