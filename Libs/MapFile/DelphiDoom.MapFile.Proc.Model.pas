{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - a "model" of a .proc file                    }
{                                                                              }
{  Model of the idRenderModel that idRenderWorldLocal::ParseModel builds       }
{  (RenderWorld_load.cpp), Doom 3 GPL Source Code.                             }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Proc.Model;

interface

uses
  System.Generics.Collections, DelphiDoom.MapFile.Proc.Surface;

type
  /// <summary>
  ///   A static model: the name ("_area0", "_area1", ... for the world, the name of the entity
  ///   for the others) and its surfaces, which the model owns
  /// </summary>
  TProcModel = class
  strict private
    FName: AnsiString;
    FSurfaces: TObjectList<TProcSurface>;
  public
    constructor Create(const AName: AnsiString);
    destructor Destroy; override;
    property Name: AnsiString read FName write FName;
    property Surfaces: TObjectList<TProcSurface> read FSurfaces;
    /// <summary>The model takes the surface</summary>
    procedure AddSurface(const ASurface: TProcSurface);
    function NumSurfaces: Integer;
  end;

implementation

{ TProcModel }

constructor TProcModel.Create(const AName: AnsiString);
begin
  inherited Create;
  FName := AName;
  FSurfaces := TObjectList<TProcSurface>.Create(True);
end;

destructor TProcModel.Destroy;
begin
  FSurfaces.Free;
  inherited Destroy;
end;

procedure TProcModel.AddSurface(const ASurface: TProcSurface);
begin
  FSurfaces.Add(ASurface);
end;

function TProcModel.NumSurfaces: Integer;
begin
  Result := FSurfaces.Count;
end;

end.
