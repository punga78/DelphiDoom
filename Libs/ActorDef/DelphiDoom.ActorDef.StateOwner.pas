{******************************************************************************}
{                                                                              }
{  DelphiDoom: ActorDef library - what a state reader asks of its owner        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ActorDef.StateOwner;

interface

type
  /// <summary>
  ///   The thing that has the states (an actor or a weapon): the labels that it has, the
  ///   name that its states get in the engine and the targets of a goto that are its labels
  /// </summary>
  IActorDefStateOwner = interface
    ['{6C1F82E4-A907-4B35-8D1C-E4570B93A2D8}']
    /// <summary>The words that start a group of states: 'spawn:', 'see:' ...</summary>
    function LabelTokens: TArray<string>;
    /// <summary>The name of the engine for a state that has a label of its own</summary>
    function AliasFor(const ALabel: string): string;
    /// <summary>
    ///   AGoto is the text of a goto in upper case, without its // comment. If it is one of the
    ///   labels of the owner (with an offset, as in SPAWN+2) gives the state and true
    /// </summary>
    function TryResolveLabel(const AGoto: string; out AState: Integer): Boolean;
  end;

implementation

end.
