{******************************************************************************}
{                                                                              }
{  DelphiDoom: net transport library - the contract of the transport           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Net.Transport.Intf;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   Datagrams between the computers of the game. Nodes are numbered as the engine does: node 0 is
  ///   this computer (never sent to), the others are in the order of the command line
  /// </summary>
  INetTransport = interface
    ['{4B8E21D6-7A53-4C09-9E1F-3D6A0C85B724}']
    /// <summary>Computers of the game, this one included</summary>
    function NodeCount: Integer;
    /// <summary>One datagram to a node (1..NodeCount - 1); a failure is an ENetException</summary>
    procedure Send(ANode: Integer; const AData: TBytes);
    /// <summary>
    ///   The next datagram, if there is one, and the node that sent it. A datagram from somebody that
    ///   is not a node of the game is not a datagram: the answer is false
    /// </summary>
    function Receive(out ANode: Integer; out AData: TBytes): Boolean;
  end;

implementation

end.
