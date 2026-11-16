{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the contract of the glBSP runner                        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Nodes.Intf;

interface

uses
  DelphiDoom.Glbsp.Client;

type
  /// <summary>
  ///   Runs glBSP to build the GL nodes of a WAD (the old ND_RunGlbsp and gld_BuildNodes of
  ///   nd_main). What glBSP prints goes to the log, as it did when the program was started
  ///   from the engine
  /// </summary>
  IEngineGlbspRunner = interface
    ['{7D2F4B18-E6A3-4C95-8B07-1A5C93E0D624}']
    /// <summary>Runs the node builder; false (and the reason printed) if it fails</summary>
    function Run(const AWadFile, AGwaFile: string; const AOptions: TGlbspOptions): Boolean;
    /// <summary>
    ///   Builds the GL-friendly nodes of AWadFile into AGwaFile (quiet, in the Hexen format
    ///   for Hexen); a failure is a warning of the log
    /// </summary>
    function BuildGlFriendly(const AWadFile, AGwaFile: string): Boolean;
  end;

implementation

end.
