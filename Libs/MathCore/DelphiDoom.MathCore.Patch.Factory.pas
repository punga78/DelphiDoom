{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore - patches of Quake III Arena: factory                  }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software). Copyright (C)   }
{  1999-2005 Id Software, Inc. This unit is derived from the Quake III Arena   }
{  source code and is therefore available under the GNU General Public         }
{  License, version 2 or (at your option) any later version.                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Patch.Factory;

interface

uses
  DelphiDoom.MathCore.Patch.Intf, DelphiDoom.MathCore.Patch.Types;

type
  /// <summary>The only place that knows the classes of the patch subdivision</summary>
  TPatchFactory = class
  public
    /// <summary>A subdivider with the given maximum error (the cvar r_subdivisions, default 4)</summary>
    class function CreateSubdivider(
      const ASubdivisions: Single = 4.0): IPatchSubdivider; static;
    class function CreateGridEditor: IPatchGridEditor; static;
  end;

implementation

uses
  DelphiDoom.MathCore.Patch.GridEditor, DelphiDoom.MathCore.Patch.Subdivider;

class function TPatchFactory.CreateSubdivider(const ASubdivisions: Single): IPatchSubdivider;
begin
  Result := TPatchSubdivider.Create(ASubdivisions);
end;

class function TPatchFactory.CreateGridEditor: IPatchGridEditor;
begin
  Result := TPatchGridEditor.Create;
end;

end.
