{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - a brush                                      }
{                                                                              }
{  Port of idMapBrush (MapFile.h, MapFile.cpp, idlib), Doom 3 GPL Source Code. }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Brush;

interface

uses
  System.Generics.Collections, DelphiDoom.MapFile.Types, DelphiDoom.MapFile.Primitive,
  DelphiDoom.MapFile.BrushSide;

type
  /// <summary>A convex volume given by the planes of its sides. It owns its sides</summary>
  TMapBrush = class(TMapPrimitive)
  strict private
    FSides: TObjectList<TMapBrushSide>;
  protected
    function GetPrimitiveType: TMapPrimitiveType; override;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>Adds a side; the brush owns it from now on and the index is returned (AddSide)</summary>
    function AddSide(const ASide: TMapBrushSide): Integer;
    function GetNumSides: Integer;
    function GetSide(const AIndex: Integer): TMapBrushSide;
    /// <summary>
    ///   The planes and materials combined with exclusive or; texture coordinates and key/value
    ///   pairs are not taken into account (idMapBrush::GetGeometryCRC)
    /// </summary>
    function GetGeometryCrc: Cardinal; override;
  end;

implementation

uses
  DelphiDoom.MapFile.GeometryCrc;

{ TMapBrush }

constructor TMapBrush.Create;
begin
  inherited Create;
  FSides := TObjectList<TMapBrushSide>.Create(True);
end;

destructor TMapBrush.Destroy;
begin
  FSides.Free;
  inherited Destroy;
end;

function TMapBrush.GetPrimitiveType: TMapPrimitiveType;
begin
  Result := mptBrush;
end;

function TMapBrush.AddSide(const ASide: TMapBrushSide): Integer;
begin
  Result := FSides.Add(ASide);
end;

function TMapBrush.GetNumSides: Integer;
begin
  Result := FSides.Count;
end;

function TMapBrush.GetSide(const AIndex: Integer): TMapBrushSide;
begin
  Result := FSides[AIndex];
end;

function TMapBrush.GetGeometryCrc: Cardinal;
var
  LIndex: Integer;
  LSide: TMapBrushSide;
begin
  Result := 0;
  for LIndex := 0 to FSides.Count - 1 do
  begin
    LSide := FSides[LIndex];
    Result := Result xor TMapGeometryCrc.FloatCrc(LSide.Plane.A);
    Result := Result xor TMapGeometryCrc.FloatCrc(LSide.Plane.B);
    Result := Result xor TMapGeometryCrc.FloatCrc(LSide.Plane.C);
    Result := Result xor TMapGeometryCrc.FloatCrc(LSide.Plane.D);
    Result := Result xor TMapGeometryCrc.StringCrc(LSide.Material);
  end;
end;

end.
