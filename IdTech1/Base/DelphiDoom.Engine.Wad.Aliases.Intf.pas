{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - other names of the lumps                               }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Wad.Aliases.Intf;

interface

type
  /// <summary>
  ///   A game whose pictures have a name that is not the one of a lump (Radix: "MainMenuButton1",
  ///   the name in RADIX.DAT) gives the engine this table: w_wad.pas asks it when a name is longer
  ///   than 8 characters or no lump has it
  /// </summary>
  IEngineLumpAliases = interface
    ['{E4A2906B-17C5-4F3D-B8A9-52D0C7F16E3A}']
    /// <summary>The name of the lump that stands for AName; false when the table does not know it</summary>
    function TryResolve(const AName: string; out ALumpName: string): Boolean;
    /// <summary>The directory of the lumps has changed: the table is read again at the next question</summary>
    procedure Reset;
  end;

implementation

end.
