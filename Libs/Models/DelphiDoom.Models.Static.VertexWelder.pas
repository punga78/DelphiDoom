{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - static models: unique vertex combinations   }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): renderer\Model.cpp       }
{  (matchVert_t and the loop of ConvertASEToModelSurfaces and                  }
{  ConvertLWOToModelSurfaces). Copyright (C) 1999-2011 id Software LLC, a      }
{  ZeniMax Media company. This unit is derived from the Doom 3 GPL source      }
{  code and is therefore available under the GNU General Public License,       }
{  version 3, with the additional terms of the Doom 3 Source Code License      }
{  (see README.md of Libs\IdLib); the repository as a whole is GPL v2 or       }
{  later.                                                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Static.VertexWelder;

interface

uses
  System.SysUtils,
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.Models.Static.Types;

type
  /// <summary>
  ///   Formats keep positions, texture coordinates, normals and colours apart; a surface needs
  ///   them together. The welder gives the index of the vertex for a combination (position,
  ///   texture coordinate, colour, normal), creating it the first time: the chain of the position
  ///   is searched in the order of creation, as the original does. Used by the ASE, LWO and MA
  ///   converters.
  /// </summary>
  TStaticVertexWelder = class
  strict private
    type
      TMatchVert = record
        V: Integer;
        Tv: Integer;
        Color: Cardinal;
        Normal: TIdVec3;
        Next: Integer;
      end;
  strict private
    FTable: TArray<TMatchVert>;
    FHeads: TArray<Integer>;
    FCount: Integer;
  public
    /// <summary>APositionCount heads of chains and room for AMaxVerts different combinations</summary>
    constructor Create(const APositionCount, AMaxVerts: Integer);
    /// <summary>
    ///   The index of the vertex: an existing one with the same texture coordinate and colour
    ///   and, when ANormalsParsed, a normal that dots more than ANormalEpsilon (otherwise the
    ///   texture coordinate and the colour are enough); a new one if none matches.
    /// </summary>
    function Find(const APosition, ATexCoord: Integer; const AColor: Cardinal; const ANormal: TIdVec3;
      const ANormalsParsed: Boolean; const ANormalEpsilon: Single): Integer;
    /// <summary>How many different vertexes were created (tri->numVerts)</summary>
    property Count: Integer read FCount;
    function Position(const AVertex: Integer): Integer;
    function TexCoord(const AVertex: Integer): Integer;
    function Color(const AVertex: Integer): Cardinal;
    function Normal(const AVertex: Integer): TIdVec3;
  end;

implementation

{ TStaticVertexWelder }

constructor TStaticVertexWelder.Create(const APositionCount, AMaxVerts: Integer);
var
  LIndex: Integer;
begin
  inherited Create;
  SetLength(FTable, AMaxVerts);
  SetLength(FHeads, APositionCount);
  for LIndex := 0 to High(FHeads) do
    FHeads[LIndex] := -1;
end;

function TStaticVertexWelder.Find(const APosition, ATexCoord: Integer; const AColor: Cardinal;
  const ANormal: TIdVec3; const ANormalsParsed: Boolean; const ANormalEpsilon: Single): Integer;
var
  LLast, LCurrent: Integer;
  LDot: Single;
begin
  LLast := -1;
  LCurrent := FHeads[APosition];
  while LCurrent >= 0 do
  begin
    if (FTable[LCurrent].Tv = ATexCoord) and (FTable[LCurrent].Color = AColor) then
    begin
      if not ANormalsParsed then
        Break;
      LDot := FTable[LCurrent].Normal * ANormal;
      if LDot > ANormalEpsilon then
        Break;
    end;
    LLast := LCurrent;
    LCurrent := FTable[LCurrent].Next;
  end;
  if LCurrent < 0 then
  begin
    LCurrent := FCount;
    FTable[LCurrent].V := APosition;
    FTable[LCurrent].Tv := ATexCoord;
    FTable[LCurrent].Normal := ANormal;
    FTable[LCurrent].Color := AColor;
    FTable[LCurrent].Next := -1;
    if LLast >= 0 then
      FTable[LLast].Next := LCurrent
    else
      FHeads[APosition] := LCurrent;
    Inc(FCount);
  end;
  Result := LCurrent;
end;

function TStaticVertexWelder.Position(const AVertex: Integer): Integer;
begin
  Result := FTable[AVertex].V;
end;

function TStaticVertexWelder.TexCoord(const AVertex: Integer): Integer;
begin
  Result := FTable[AVertex].Tv;
end;

function TStaticVertexWelder.Color(const AVertex: Integer): Cardinal;
begin
  Result := FTable[AVertex].Color;
end;

function TStaticVertexWelder.Normal(const AVertex: Integer): TIdVec3;
begin
  Result := FTable[AVertex].Normal;
end;

end.
