{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - the references inside a .proc file           }
{                                                                              }
{  Written for this library. Licensed under the GNU General Public License,    }
{  version 2 or later.                                                         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Proc.Validator;

interface

uses
  DelphiDoom.MapFile.Proc.ProcFile;

type
  /// <summary>
  ///   Checks that the numbers of a .proc file agree with each other: the indexes of a surface
  ///   point to its vertices and come in threes, the counts of a shadow model are inside its
  ///   indexes, a portal has three points at least, the children of a node are nodes or areas
  ///   that exist. The original does none of this at load time (a wrong index is found, if at
  ///   all, when the model is drawn)
  /// </summary>
  TProcFileValidator = class
  public
    /// <summary>One line of text for every problem; empty when the file is coherent</summary>
    class function Check(const AFile: TProcFile): TArray<string>; static;
  end;

implementation

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.MapFile.Proc.Types, DelphiDoom.MapFile.Proc.Model,
  DelphiDoom.MapFile.Proc.Surface, DelphiDoom.MapFile.Proc.ShadowModel, DelphiDoom.MapFile.Proc.Portal;

resourcestring
  SIndexOutOfRange = 'model "%s", surface %d: index %d is not in 0..%d';
  SIndexesNotTriangles = 'model "%s", surface %d: %d indexes are not a whole number of triangles';
  SShadowIndexOutOfRange = 'shadowModel "%s": index %d is not in 0..%d';
  SShadowIndexesNotTriangles = 'shadowModel "%s": %d indexes are not a whole number of triangles';
  SShadowCountOutOfRange = 'shadowModel "%s": %s is %d, the model has %d indexes';
  SPortalPoints = 'portal %d has %d points, at least 3 are needed';
  SNodeChild = 'node %d: child %d is not a node (1..%d) nor an area (0..%d)';

procedure CheckSurface(const AModelName: string; const ASurfaceIndex: Integer; const ASurface: TProcSurface;
  const AProblems: TList<string>);
var
  LIndex: Integer;
begin
  if ASurface.NumIndexes mod 3 <> 0 then
    AProblems.Add(Format(SIndexesNotTriangles, [AModelName, ASurfaceIndex, ASurface.NumIndexes]));
  for LIndex := 0 to ASurface.NumIndexes - 1 do
    if (ASurface.Indexes[LIndex] < 0) or (ASurface.Indexes[LIndex] >= ASurface.NumVertices) then
      AProblems.Add(Format(SIndexOutOfRange, [AModelName, ASurfaceIndex, ASurface.Indexes[LIndex],
        ASurface.NumVertices - 1]));
end;

procedure CheckShadowModel(const AModel: TProcShadowModel; const AProblems: TList<string>);
var
  LIndex, LNumIndexes: Integer;
  LName: string;
begin
  LName := string(AModel.Name);
  LNumIndexes := Length(AModel.Indexes);
  if LNumIndexes mod 3 <> 0 then
    AProblems.Add(Format(SShadowIndexesNotTriangles, [LName, LNumIndexes]));
  for LIndex := 0 to LNumIndexes - 1 do
    if (AModel.Indexes[LIndex] < 0) or (AModel.Indexes[LIndex] >= Length(AModel.Vertices)) then
      AProblems.Add(Format(SShadowIndexOutOfRange, [LName, AModel.Indexes[LIndex], Length(AModel.Vertices) - 1]));
  if (AModel.NumShadowIndexesNoCaps < 0) or (AModel.NumShadowIndexesNoCaps > LNumIndexes) then
    AProblems.Add(Format(SShadowCountOutOfRange, [LName, 'noCaps', AModel.NumShadowIndexesNoCaps, LNumIndexes]));
  if (AModel.NumShadowIndexesNoFrontCaps < 0) or (AModel.NumShadowIndexesNoFrontCaps > LNumIndexes) then
    AProblems.Add(Format(SShadowCountOutOfRange, [LName, 'noFrontCaps', AModel.NumShadowIndexesNoFrontCaps,
      LNumIndexes]));
end;

procedure CheckNode(const AFile: TProcFile; const ANodeIndex, AChild: Integer; const AProblems: TList<string>);
var
  LValid: Boolean;
begin
  if AChild > 0 then
    LValid := AChild < AFile.Nodes.Count
  else if AFile.HasPortalSection then
    LValid := (-1 - AChild) < AFile.NumAreas
  else
    LValid := True;
  if not LValid then
    AProblems.Add(Format(SNodeChild, [ANodeIndex, AChild, AFile.Nodes.Count - 1, AFile.NumAreas - 1]));
end;

{ TProcFileValidator }

class function TProcFileValidator.Check(const AFile: TProcFile): TArray<string>;
var
  LProblems: TList<string>;
  LModel: TProcModel;
  LShadowModel: TProcShadowModel;
  LIndex, LSurfaceIndex: Integer;
begin
  LProblems := TList<string>.Create;
  try
    for LModel in AFile.Models do
      for LSurfaceIndex := 0 to LModel.NumSurfaces - 1 do
        CheckSurface(string(LModel.Name), LSurfaceIndex, LModel.Surfaces[LSurfaceIndex], LProblems);
    for LShadowModel in AFile.ShadowModels do
      CheckShadowModel(LShadowModel, LProblems);
    for LIndex := 0 to AFile.Portals.Count - 1 do
      if AFile.Portals[LIndex].NumPoints < 3 then
        LProblems.Add(Format(SPortalPoints, [LIndex, AFile.Portals[LIndex].NumPoints]));
    for LIndex := 0 to AFile.Nodes.Count - 1 do
    begin
      CheckNode(AFile, LIndex, AFile.Nodes[LIndex].PositiveChild, LProblems);
      CheckNode(AFile, LIndex, AFile.Nodes[LIndex].NegativeChild, LProblems);
    end;
    Result := LProblems.ToArray;
  finally
    LProblems.Free;
  end;
end;

end.
