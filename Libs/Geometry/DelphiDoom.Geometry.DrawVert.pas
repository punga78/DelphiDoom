{******************************************************************************}
{                                                                              }
{  DelphiDoom: geometry library - the draw vertex (idDrawVert)                 }
{                                                                              }
{  Port of idDrawVert (idlib\geometry\DrawVert.h and DrawVert.cpp) of the      }
{  Doom 3 GPL Source Code. Copyright (C) 1999-2011 id Software LLC, a          }
{  ZeniMax Media company. Based on the Doom 3 GPL Source Code (id Software).   }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Geometry.DrawVert;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.IdLib.Math.Vec2, DelphiDoom.Geometry.Vec3;

type
  /// <summary>
  ///   A vertex of a surface (idDrawVert), 60 bytes: position, texture coordinates, normal, two
  ///   tangents and four bytes of colour. The texture coordinates are a <c>TIdVec2</c> of
  ///   <c>Libs\IdLib</c> (there is no 2D vector in <c>Libs\Geometry</c>).
  /// </summary>
  TGeoDrawVert = record
    Xyz: TGeoVec3;
    St: TIdVec2;
    Normal: TGeoVec3;
    Tangents: array[0..1] of TGeoVec3;
    Color: array[0..3] of Byte;
  private
    function GetItem(AIndex: Integer): Single;
    procedure SetItem(AIndex: Integer; AValue: Single);
  public
    /// <summary>The five floats xyz and st, as operator[] of the original (index 0..4)</summary>
    property Items[AIndex: Integer]: Single read GetItem write SetItem; default;
    procedure Clear;
    /// <summary>Linear interpolation of position and texture coordinates only</summary>
    procedure Lerp(const AFirst, ASecond: TGeoDrawVert; AFraction: Single);
    /// <summary>Linear interpolation of every field, colour bytes truncated</summary>
    procedure LerpAll(const AFirst, ASecond: TGeoDrawVert; AFraction: Single);
    /// <summary>Normalises the normal and rebuilds the two tangents orthogonal to it</summary>
    procedure Normalize;
    /// <summary>The four colour bytes as one little endian value (colour[0] is the low byte)</summary>
    procedure SetColor(AColor: Cardinal);
    function GetColor: Cardinal;
  end;

  PGeoDrawVert = ^TGeoDrawVert;

implementation

{ TGeoDrawVert }

function TGeoDrawVert.GetItem(AIndex: Integer): Single;
begin
  case AIndex of
    0: Result := Xyz.X;
    1: Result := Xyz.Y;
    2: Result := Xyz.Z;
    3: Result := St.X;
  else
    Result := St.Y;
  end;
end;

procedure TGeoDrawVert.SetItem(AIndex: Integer; AValue: Single);
begin
  case AIndex of
    0: Xyz.X := AValue;
    1: Xyz.Y := AValue;
    2: Xyz.Z := AValue;
    3: St.X := AValue;
  else
    St.Y := AValue;
  end;
end;

procedure TGeoDrawVert.Clear;
begin
  Xyz.Zero;
  St.Zero;
  Normal.Zero;
  Tangents[0].Zero;
  Tangents[1].Zero;
  Color[0] := 0;
  Color[1] := 0;
  Color[2] := 0;
  Color[3] := 0;
end;

procedure TGeoDrawVert.Lerp(const AFirst, ASecond: TGeoDrawVert; AFraction: Single);
begin
  Xyz := AFirst.Xyz + AFraction * (ASecond.Xyz - AFirst.Xyz);
  St := AFirst.St + AFraction * (ASecond.St - AFirst.St);
end;

procedure TGeoDrawVert.LerpAll(const AFirst, ASecond: TGeoDrawVert; AFraction: Single);
var
  LIndex: Integer;
  LValue: Single;
begin
  Xyz := AFirst.Xyz + AFraction * (ASecond.Xyz - AFirst.Xyz);
  St := AFirst.St + AFraction * (ASecond.St - AFirst.St);
  Normal := AFirst.Normal + AFraction * (ASecond.Normal - AFirst.Normal);
  Tangents[0] := AFirst.Tangents[0] + AFraction * (ASecond.Tangents[0] - AFirst.Tangents[0]);
  Tangents[1] := AFirst.Tangents[1] + AFraction * (ASecond.Tangents[1] - AFirst.Tangents[1]);
  for LIndex := 0 to 3 do
  begin
    // (byte)( a + f * ( b - a ) ): one float operation per step, then the truncated integer
    LValue := Single(ASecond.Color[LIndex]) - Single(AFirst.Color[LIndex]);
    LValue := AFraction * LValue;
    LValue := Single(AFirst.Color[LIndex]) + LValue;
    Color[LIndex] := Byte(Trunc(LValue));
  end;
end;

procedure TGeoDrawVert.Normalize;
begin
  Normal.NormalizeSelf;
  Tangents[1] := Normal.Cross(Tangents[0]);
  Tangents[1].NormalizeSelf;
  Tangents[0] := Tangents[1].Cross(Normal);
  Tangents[0].NormalizeSelf;
end;

procedure TGeoDrawVert.SetColor(AColor: Cardinal);
begin
  Color[0] := Byte(AColor);
  Color[1] := Byte(AColor shr 8);
  Color[2] := Byte(AColor shr 16);
  Color[3] := Byte(AColor shr 24);
end;

function TGeoDrawVert.GetColor: Cardinal;
begin
  Result := Cardinal(Color[0]) or (Cardinal(Color[1]) shl 8) or (Cardinal(Color[2]) shl 16) or
    (Cardinal(Color[3]) shl 24);
end;

end.
