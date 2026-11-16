{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - the types of the MODELDEF lump              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Definition.Types;

interface

uses
  System.SysUtils;

type
  /// <summary>A model as MODELDEF writes it: the file, the offset, the scale and the files merged with it</summary>
  TModelDefinitionItem = record
    /// <summary>The file of the model, in capital letters</summary>
    Name: string;
    /// <summary>The function of a DLL model</summary>
    Proc: string;
    XOffset: Single;
    YOffset: Single;
    ZOffset: Single;
    XScale: Single;
    YScale: Single;
    ZScale: Single;
    /// <summary>The files whose frames are added to the model, in capital letters</summary>
    FrameMerge: TArray<string>;
  end;

  /// <summary>A state that shows a model with a texture and a range of frames</summary>
  TModelDefinitionState = record
    /// <summary>The index the sink gave to the model, or -1</summary>
    ModelIndex: Integer;
    /// <summary>The index the sink gave to the texture, or -1</summary>
    Texture: Integer;
    StartFrame: Integer;
    EndFrame: Integer;
    /// <summary>Not read from the lump: the renderer sets it at run time</summary>
    NextFrame: Integer;
    /// <summary>The index of the state of the game</summary>
    State: Integer;
    Transparency: Single;
  end;

resourcestring
  SModelDefTokenExpected = 'SC_ParseModelDefinition(): Token expected at line %d'#13#10;
  SModelDefUnknownState = 'SC_ParseModelDefinition(): Unknown state "%s" at line %d'#13#10;
  SModelDefUnknownToken = 'SC_ParseModelDefinition(): Unknown token "%s" at line %d'#13#10;

implementation

end.
