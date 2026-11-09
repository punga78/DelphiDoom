{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - the contracts of the MODELDEF parser        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Definition.Intf;

interface

uses
  DelphiDoom.Models.Definition.Types;

type
  /// <summary>What the parser asks to the game</summary>
  IModelDefinitionLookup = interface
    ['{4B7A1C92-5E30-4D68-A1F4-93C8D2E07B15}']
    /// <summary>The index of a state by its name (capital letters); negative if there is none</summary>
    function FindState(const AName: string): Integer;
  end;

  /// <summary>What the parser gives: the models, the textures and the states, in the order they are written</summary>
  IModelDefinitionSink = interface
    ['{C0D93E41-7A52-4B1F-86E3-2F5A19B8C764}']
    /// <summary>Adds a model; the answer is its index (the one of a model with the same name if it is there)</summary>
    function AddModel(const AItem: TModelDefinitionItem): Integer;
    /// <summary>Adds a texture by its name (capital letters); the answer is its index</summary>
    function AddTexture(const AName: string): Integer;
    /// <summary>Adds a state that shows a model</summary>
    procedure AddState(const AState: TModelDefinitionState);
  end;

  /// <summary>Reads the text of a MODELDEF lump</summary>
  IModelDefinitionParser = interface
    ['{7E52A8D3-19C4-4F06-B3A7-D86140E5F29B}']
    /// <summary>The parts of the text go to the sink in the order they are written; the problems are warnings</summary>
    procedure Parse(const AText: string; const ASink: IModelDefinitionSink);
  end;

implementation

end.
