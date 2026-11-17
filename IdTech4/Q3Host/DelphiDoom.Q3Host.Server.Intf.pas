{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - what the server in memory needs from   }
{  the outside                                                                 }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): server.h,       }
{  sv_snapshot.c (SV_SendMessageToClient). Copyright (C) 1999-2005 Id          }
{  Software, Inc. This unit is derived from the Quake III Arena source code    }
{  and is therefore available under the GNU General Public License, version 2  }
{  or (at your option) any later version.                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Host.Server.Intf;

interface

uses
  System.SysUtils, DelphiDoom.Net.Q3.Types;

type
  /// <summary>
  ///   Where the messages of the server go (SV_SendMessageToClient, NET_OutOfBandPrint). The in memory loop gives
  ///   them to the parser of the client; the network layer writes them to the netchan of the client
  /// </summary>
  IQ3ServerOutput = interface
    ['{6E2B94C1-7A30-4D58-B1F6-0C93D5A8E274}']
    /// <summary>
    ///   One message for the client, as the parser of the client reads it (the acknowledge of the client commands
    ///   first, svc_EOF last) and the sequence the netchan of the slot gives it. The sequence is
    ///   client->netchan.outgoingSequence before the message
    /// </summary>
    procedure SendMessage(AClient: Integer; const AMessage: TBytes; ASequence: Integer);
    /// <summary>NET_OutOfBandPrint( NS_SERVER, address, text ): "connectResponse", "print\n...", "challengeResponse n"</summary>
    procedure SendOutOfBand(const AAddress: TQ3NetAddress; const AText: AnsiString);
    /// <summary>client->netchan.unsentFragments: the last message is still going out in pieces</summary>
    function HasUnsentFragments(AClient: Integer): Boolean;
    /// <summary>SV_Netchan_TransmitNextFragment</summary>
    procedure TransmitNextFragment(AClient: Integer);
  end;

implementation

end.
