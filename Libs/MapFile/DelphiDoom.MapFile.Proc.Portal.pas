{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - an inter area portal of a .proc file         }
{                                                                              }
{  Model of what idRenderWorldLocal::ParseInterAreaPortals reads for a portal  }
{  (RenderWorld_load.cpp), Doom 3 GPL Source Code.                             }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Proc.Portal;

interface

uses
  DelphiDoom.Geometry.Vec3;

type
  /// <summary>
  ///   The opening between two areas: the points of the polygon as the file has them (the
  ///   plane, the reversed twin and the lists of the areas that the renderer builds from it are
  ///   not part of the model) and the numbers of the area on the positive and on the negative side
  /// </summary>
  TProcPortal = class
  strict private
    FPositiveArea: Integer;
    FNegativeArea: Integer;
    FPoints: TArray<TGeoVec3>;
  public
    property PositiveArea: Integer read FPositiveArea write FPositiveArea;
    property NegativeArea: Integer read FNegativeArea write FNegativeArea;
    property Points: TArray<TGeoVec3> read FPoints write FPoints;
    function NumPoints: Integer;
  end;

implementation

{ TProcPortal }

function TProcPortal.NumPoints: Integer;
begin
  Result := Length(FPoints);
end;

end.
