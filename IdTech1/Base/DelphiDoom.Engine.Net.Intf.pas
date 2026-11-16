{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the loop of the game around the network                }
{  Copyright (C) 2004-2023 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Net.Intf;

{$I Doom32.inc}

interface

uses
  d_ticcmd;

type
  /// <summary>
  ///   The game seen from the network: the start of the nodes, the commands that come and go at
  ///   each tic, how many tics to run and the end of a network game. The composition root gives it
  ///   to the main loop (d_main), to the game (g_game, for the consistency and the commands of the
  ///   other players), to the renderer (r_main sends the commands while it draws) and to the
  ///   system (i_system, at the end). It was the facade d_net.pas
  /// </summary>
  IEngineNetGame = interface
    ['{5C1E8A47-93D2-4F06-B7A8-2E6D41F0C953}']
    /// <summary>
    ///   Reads the command line, opens the transport of a network game and agrees the settings of
    ///   the game with the other nodes (D_CheckNetGame)
    /// </summary>
    procedure Start;
    /// <summary>Releases the network: the sockets are closed with the transport (D_ShutDownNetGame)</summary>
    procedure Shutdown;
    /// <summary>Builds the commands of the console player and sends them (NetUpdate)</summary>
    procedure Update;
    /// <summary>Tells the other players that this one leaves the game (D_QuitNetGame)</summary>
    procedure Quit;
    /// <summary>Runs the tics that the network has, drawing between them (D_RunMultipleTicks)</summary>
    procedure RunMultipleTics;
    /// <summary>Runs one tic and draws it, for -singletics (D_RunSingleTick)</summary>
    procedure RunSingleTic;
    /// <summary>The consistency check that a new command carries (D_NetExpectedConsistency)</summary>
    function ExpectedConsistency: SmallInt;
    /// <summary>
    ///   Compares the consistency of a command that arrived with the one kept for its tic, and
    ///   keeps the new local value (D_VerifyNetConsistency)
    /// </summary>
    procedure VerifyConsistency(const APlayer: Integer; const AReceived: SmallInt;
      const ALocalValue: Integer);
    /// <summary>The command of a player for a position of the buffer of the network (D_GetNetCommand)</summary>
    procedure GetCommand(const APlayer, ABuffer: Integer; const ACommand: Pticcmd_t);
  end;

implementation

end.
