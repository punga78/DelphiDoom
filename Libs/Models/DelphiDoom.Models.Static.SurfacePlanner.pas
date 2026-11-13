{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - static models: surfaces that share a        }
{  material                                                                    }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): renderer\Model.cpp       }
{  (the mergeTo loop of ConvertASEToModelSurfaces and                          }
{  ConvertLWOToModelSurfaces). Copyright (C) 1999-2011 id Software LLC, a      }
{  ZeniMax Media company. This unit is derived from the Doom 3 GPL source      }
{  code and is therefore available under the GNU General Public License,       }
{  version 3, with the additional terms of the Doom 3 Source Code License      }
{  (see README.md of Libs\IdLib); the repository as a whole is GPL v2 or       }
{  later.                                                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Static.SurfacePlanner;

interface

uses
  System.SysUtils,
  DelphiDoom.Models.Static.Model;

type
  /// <summary>
  ///   Decides which surface of the model every object of a file goes to: the modeling programs
  ///   save several objects with the same material and the engine merges them. Materials are
  ///   equal when the names are equal without case (the declaration manager looks them up that
  ///   way); the "discrete" materials (flares, autosprites) that are never merged need the
  ///   material declaration and are not known here.
  /// </summary>
  TStaticSurfacePlanner = class
  public
    /// <summary>
    ///   Adds the surfaces to AModel and returns, for every material name of the list, the index of
    ///   its surface. Without merging every name gets its own surface.
    /// </summary>
    class function Plan(const AModel: TStaticModel; const AMaterialNames: TArray<AnsiString>;
      const AMerge: Boolean): TArray<Integer>; static;
  end;

implementation

class function TStaticSurfacePlanner.Plan(const AModel: TStaticModel;
  const AMaterialNames: TArray<AnsiString>; const AMerge: Boolean): TArray<Integer>;
var
  LIndex, LSurface: Integer;
begin
  SetLength(Result, Length(AMaterialNames));
  for LIndex := 0 to High(AMaterialNames) do
  begin
    LSurface := 0;
    if AMerge then
      while (LSurface < AModel.NumSurfaces) and
        not SameText(string(AModel.MaterialName(LSurface)), string(AMaterialNames[LIndex])) do
        Inc(LSurface)
    else
      LSurface := AModel.NumSurfaces;
    if LSurface = AModel.NumSurfaces then
      LSurface := AModel.AddSurface(AMaterialNames[LIndex]);
    Result[LIndex] := LSurface;
  end;
end;

end.
