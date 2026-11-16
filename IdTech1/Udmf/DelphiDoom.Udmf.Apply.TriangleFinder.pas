{******************************************************************************}
{                                                                              }
{  DelphiDoom: UDMF library - the three vertexes of a triangular sector        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Udmf.Apply.TriangleFinder;

interface

type
  /// <summary>Tells whether the lines of a sector make a triangle of vertexes that the text map described</summary>
  TUdmfTriangleFinder = class
  public
    /// <summary>The three vertexes of a closed triangle, in the order they appear in the endpoints</summary>
    /// <param name="AEndpoints">Start and end vertex of each of the three lines, one after the other</param>
    /// <param name="AVertexCount">The vertexes that the text map described: a number from this one up was
    /// added by the node builder and has no extra values</param>
    /// <param name="AVertexes">The three numbers when the result is true</param>
    /// <returns>False when the endpoints are not exactly three different vertexes, or one has no extra values</returns>
    class function TryFind(const AEndpoints: array of Integer; AVertexCount: Integer;
      out AVertexes: TArray<Integer>): Boolean; static;
  end;

implementation

{ TUdmfTriangleFinder }

class function TUdmfTriangleFinder.TryFind(const AEndpoints: array of Integer;
  AVertexCount: Integer; out AVertexes: TArray<Integer>): Boolean;
var
  LIndex, LCount, LKnown: Integer;
  LFound: Boolean;
begin
  SetLength(AVertexes, Length(AEndpoints));
  LCount := 0;
  for LIndex := 0 to High(AEndpoints) do
  begin
    LFound := False;
    for LKnown := 0 to LCount - 1 do
      if AVertexes[LKnown] = AEndpoints[LIndex] then
      begin
        LFound := True;
        Break;
      end;
    if not LFound then
    begin
      AVertexes[LCount] := AEndpoints[LIndex];
      Inc(LCount);
    end;
  end;
  SetLength(AVertexes, LCount);

  Result := LCount = 3;
  if Result then
    for LIndex := 0 to 2 do
      if AVertexes[LIndex] >= AVertexCount then
      begin
        Result := False;
        Break;
      end;
  if not Result then
    AVertexes := nil;
end;

end.
