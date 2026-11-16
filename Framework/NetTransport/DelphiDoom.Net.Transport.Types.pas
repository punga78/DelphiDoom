{******************************************************************************}
{                                                                              }
{  DelphiDoom: net transport library - shared types and constants              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Net.Transport.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>Port of the engine when -port is not given (IPPORT_USERRESERVED + $1d)</summary>
  NET_DEFAULT_PORT = 5000 + $1D;

type
  /// <summary>Every failure of the net libraries; the engine turns it into I_Error</summary>
  ENetException = class(Exception);

  /// <summary>Where another computer is: a name or a dotted address, and a port</summary>
  TNetNodeAddress = record
    Host: string;
    /// <summary>True: Host is a dotted address (written ".1.2.3.4" in the arguments), no name lookup</summary>
    IsLiteral: Boolean;
    Port: Word;
  end;

implementation

end.
