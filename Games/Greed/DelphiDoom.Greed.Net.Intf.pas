{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the net game: the contracts                      }
{  Port of xGreed (Jim Valavanis): the routines that net.pas                    }
{  gives to the game and the ones of the game that it calls                     }
{                                                                              }
{  xGreed (Jim Valavanis) and Raven 3D engine (c) 1996 Softdisk Publishing:    }
{  the user declares this port GPL v2 or later; the right on the parts         }
{  derived from the Softdisk code is not verified (docs\LICENZE.md)            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Net.Intf;

interface

uses
  DelphiDoom.Greed.Types, DelphiDoom.Greed.SaveTypes;

type
  /// <summary>
  ///   What the logic of the game asks of the net game: the Net* routines of net.pas. The game calls them only
  ///   when netmode is true. Every packet goes to all the other players
  /// </summary>
  IGreedNetLink = interface
    ['{5E2B7C41-8D06-4F39-A1B4-90C3E6D27F58}']
    /// <summary>NetGetData: every packet that arrived is read and done (a sprite moves, a door opens ...)</summary>
    procedure GetData;
    /// <summary>NetSendPlayerData: where the player is and what it is doing; its status goes back to 0</summary>
    procedure SendPlayerData;
    /// <summary>NetNewPlayerData: the player entered the map (at the start and after each death)</summary>
    procedure NewPlayerData;
    /// <summary>NetSendSpawn: the same arguments of SpawnSprite</summary>
    procedure SendSpawn(AValue: Integer; AX, AY, AZ, AZAdjust: TGreedFixed; AAngle, AAngle2: Integer;
      AActive: Boolean; ASpawnId: Integer);
    /// <summary>NetSoundEffect(n, variation, x, y)</summary>
    procedure SoundEffect(ASound, AVariation: Integer; AX, AY: TGreedFixed);
    /// <summary>NetItemPickup(x, y): the tile, before the item is taken away from mapsprites</summary>
    procedure ItemPickup(ATileX, ATileY: Integer);
    /// <summary>NetDeath(bulletid): the player died; ABulletId is the spawnid of the shot (a player if under 8)</summary>
    procedure Death(ABulletId: Integer);
    /// <summary>NetGetClosestPlayer(sx, sy): TargX, TargY and TargZ of the state become the nearest visible player</summary>
    procedure GetClosestPlayer(ATileX, ATileY: Integer);
    /// <summary>NetOpenDoor(x, y)</summary>
    procedure OpenDoor(AX, AY: TGreedFixed);
    /// <summary>NetCheckHere(centerx, centery, angle): the use key did something at that place</summary>
    procedure CheckHere(ACenterX, ACenterY: TGreedFixed; AAngle: Integer);
    /// <summary>NetBonusItem: the bonus item of the state is told to the others (player 0 only places it)</summary>
    procedure BonusItem;
    /// <summary>NetPause and NetUnPause</summary>
    procedure Pause;
    procedure UnPause;
    /// <summary>NetSendMessage(s): at most 30 bytes of text travel</summary>
    procedure SendMessage(const AText: AnsiString);
    /// <summary>NetQuitGame: a death that nobody caused and then the goodbye</summary>
    procedure QuitGame;
    /// <summary>greedcom.numplayers</summary>
    function GetNumPlayers: Integer;
    /// <summary>greedcom.consoleplayer (playernum of the game)</summary>
    function GetConsolePlayer: Integer;
    /// <summary>netpaused: another player paused the game</summary>
    function GetPaused: Boolean;
    /// <summary>netwarpjammer and netwarpjamtime: the spawn areas are still while the time has not come</summary>
    function GetWarpJammer: Boolean;
    function GetWarpJamTime: Integer;
    /// <summary>playerdata[n]: the last that was heard of a player (of this one: the last that was sent)</summary>
    function GetPlayerData(APlayer: Integer): TGreedPlayerEvent;
    /// <summary>fragcount[n]: the kills of a player</summary>
    function GetFragCount(APlayer: Integer): Integer;
    /// <summary>netnames[n]</summary>
    function GetNetName(APlayer: Integer): AnsiString;
    property NumPlayers: Integer read GetNumPlayers;
    property ConsolePlayer: Integer read GetConsolePlayer;
    property Paused: Boolean read GetPaused;
    property WarpJammer: Boolean read GetWarpJammer;
    property WarpJamTime: Integer read GetWarpJamTime;
    property PlayerData[APlayer: Integer]: TGreedPlayerEvent read GetPlayerData;
    property FragCount[APlayer: Integer]: Integer read GetFragCount;
    property NetName[APlayer: Integer]: AnsiString read GetNetName;
  end;

  /// <summary>
  ///   NetWaitStart cut in steps: the players tell each other who they are until player 0 says that everybody
  ///   knows everybody. The program calls Step while the clock of the game goes on
  /// </summary>
  IGreedNetStart = interface
    ['{C8417A2E-3B5D-4960-8E72-F4A09D1B6C35}']
    /// <summary>The beginning of NetWaitStart: nobody is known but this player; the time-out starts now</summary>
    procedure BeginWaitStart;
    /// <summary>
    ///   One turn of the loop of NetWaitStart. True when the game starts: the clock of the game is then at its
    ///   start, the others were told where the player is and the first packets were read. EGreedNetException after
    ///   10 minutes, or if somebody plays another map
    /// </summary>
    function WaitStartStep: Boolean;
  end;

  /// <summary>What net.pas calls of the other units of the game when a packet says so</summary>
  IGreedNetHost = interface
    ['{2F90D6B3-71E8-4C45-B3A7-6D5E18C4029A}']
    /// <summary>TryDoor(x, y) of raven.pas</summary>
    procedure TryDoor(ACenterX, ACenterY: TGreedFixed);
    /// <summary>CheckItems(tilex, tiley, false, chartype) of raven.pas: another player took what is on the tile</summary>
    procedure CheckItems(ATileX, ATileY: Integer; AUseIt: Boolean; ACharType: Integer);
    /// <summary>CheckHere(false, x, y, angle) of raven.pas: another player used a switch or a trigger</summary>
    procedure CheckHere(AUseIt: Boolean; ACenterX, ACenterY: TGreedFixed; AAngle: Integer);
    /// <summary>oldgoalitem := -1 (display.pas): the goal of the status bar is drawn again</summary>
    procedure RefreshGoalItem;
  end;

implementation

end.
