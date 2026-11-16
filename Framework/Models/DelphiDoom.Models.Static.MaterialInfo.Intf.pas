{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - what a model asks to its materials          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Static.MaterialInfo.Intf;

interface

type
  /// <summary>
  ///   The few properties of an <c>idMaterial</c> that finishing a model depends on. The models
  ///   keep materials as names: whoever has the materials answers here. Replaces the
  ///   declaration manager (<c>surf->shader->ShouldCreateBackSides()</c> and the like).
  /// </summary>
  IStaticMaterialInfo = interface
    ['{6D1B94E7-3A52-4C08-BE71-95F0A3C27D48}']
    /// <summary>Two sided lit surface: the triangles are duplicated reversed (ShouldCreateBackSides)</summary>
    function ShouldCreateBackSides(const AMaterialName: AnsiString): Boolean;
    /// <summary>The tangents come from the largest triangle of each vertex (UseUnsmoothedTangents)</summary>
    function UseUnsmoothedTangents(const AMaterialName: AnsiString): Boolean;
  end;

implementation

end.
