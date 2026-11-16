{******************************************************************************}
{                                                                              }
{  DelphiDoom: Nodes library - the vertex of a GL seg                          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Nodes.GlVertexIndex;

interface

type
  /// <summary>
  ///   Where the vertex of a GL seg is in the vertexes of the level: the vertexes of the map
  ///   first, then the GL vertexes of GL_VERT. The bit that marks a GL vertex depends on the
  ///   version of the nodes: bit 15 up to V2, bit 30 in V3 and V4, bit 31 in V5. It was
  ///   CheckGLVertex of nd_main.pas
  /// </summary>
  TNodesGlVertexIndex = class sealed
  public
    /// <summary>
    ///   The index in the vertexes of the level of the vertex ANumber of a seg; AFirstGlVertex is
    ///   the number of the vertexes of the map. A number without the bit of a GL vertex, or of a
    ///   version over 5, is the index of a vertex of the map
    /// </summary>
    class function Resolve(AVersion, ANumber, AFirstGlVertex: Integer): Integer; static;
  end;

implementation

const
  GL_VERTEX_BIT_V2 = 15;
  GL_VERTEX_BIT_V3 = 30;
  GL_VERTEX_BIT_V5 = 31;

{ TNodesGlVertexIndex }

class function TNodesGlVertexIndex.Resolve(AVersion, ANumber, AFirstGlVertex: Integer): Integer;
begin
  if AVersion <= 2 then
  begin
    if ANumber and (1 shl GL_VERTEX_BIT_V2) <> 0 then
      Exit(ANumber and (1 shl GL_VERTEX_BIT_V2 - 1) + AFirstGlVertex);
  end
  else if AVersion <= 4 then
  begin
    if ANumber and (1 shl GL_VERTEX_BIT_V3) <> 0 then
      Exit(ANumber and (1 shl GL_VERTEX_BIT_V3 - 1) + AFirstGlVertex);
  end
  else if AVersion = 5 then
  begin
    if Cardinal(ANumber) and (Cardinal(1) shl GL_VERTEX_BIT_V5) <> 0 then
      Exit(Integer(Cardinal(ANumber) and (Cardinal(1) shl GL_VERTEX_BIT_V5 - 1)) + AFirstGlVertex);
  end;
  Result := ANumber;
end;

end.
