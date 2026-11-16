{******************************************************************************}
{                                                                              }
{  DelphiDoom: id Tech library - the engine as the rest of the code sees it    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.IdTech.Intf;

interface

uses
  DelphiDoom.IdTech.Types;

type
  /// <summary>
  ///   What the code that needs to know the engine asks for: which generation of id Tech it is,
  ///   which source port runs it and at which version. It is given to the code (constructor or
  ///   Configure), never read from a global
  /// </summary>
  IIdTechEngine = interface
    ['{5F3A8D12-7C4B-4E90-A1D6-2B09E8C4F751}']
    function GetGeneration: TIdTechGeneration;
    function GetSourcePort: string;
    function GetVersion: TIdTechVersion;
    /// <summary>'id Tech 1'</summary>
    function GetName: string;
    /// <summary>'DelphiDoom 2.07 (id Tech 1)'</summary>
    function GetDisplayName: string;
    property Generation: TIdTechGeneration read GetGeneration;
    property SourcePort: string read GetSourcePort;
    property Version: TIdTechVersion read GetVersion;
    property Name: string read GetName;
    property DisplayName: string read GetDisplayName;
  end;

implementation

end.
