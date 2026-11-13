{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - the areas of a .proc file seen from a point  }
{                                                                              }
{  Port of idRenderWorldLocal::PointInArea, BoundsInAreas and BoundsInAreas_r  }
{  (RenderWorld.cpp), Doom 3 GPL Source Code.                                  }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Proc.AreaLocator;

interface

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Bounds, DelphiDoom.MapFile.Proc.ProcFile,
  DelphiDoom.MapFile.Proc.Intf;

type
  /// <summary>
  ///   Walks the "nodes" of a .proc file. The file is borrowed: it must outlive the locator.
  ///   A file without nodes is a world of a single area: the original has no node tree and
  ///   answers -1 / 0; so does this class. A child that is not a node of the file, or an area
  ///   that is not in 0..NumAreas-1, is an EProcFileException (the original reads outside its
  ///   array or stops with <c>common->Error</c> for the area)
  /// </summary>
  TProcAreaLocator = class(TInterfacedObject, IProcAreaLocator)
  strict private
    FFile: TProcFile;
    procedure CheckNode(const ANodeNum: Integer);
    function AreaOfChild(const AChild: Integer): Integer;
    procedure CollectAreas(const ANodeNum: Integer; const ABounds: TGeoBounds; var AAreas: TArray<Integer>;
      var ANumAreas: Integer; const AMaxAreas, ADepth: Integer);
  public
    constructor Create(const AFile: TProcFile);
    function PointInArea(const APoint: TGeoVec3): Integer;
    function BoundsInAreas(const ABounds: TGeoBounds; var AAreas: TArray<Integer>; const AMaxAreas: Integer): Integer;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.MapFile.Proc.Types;

resourcestring
  SNodeNotInFile = 'node %d is not in 0..%d';
  SAreaOutOfRange = 'idRenderWorld::PointInArea: area out of range (%d of %d)';
  STreeTooDeep = 'the node tree is deeper than its number of nodes';

{ TProcAreaLocator }

constructor TProcAreaLocator.Create(const AFile: TProcFile);
begin
  inherited Create;
  FFile := AFile;
end;

procedure TProcAreaLocator.CheckNode(const ANodeNum: Integer);
begin
  if (ANodeNum < 0) or (ANodeNum >= FFile.Nodes.Count) then
    raise EProcFileException.Create(Format(SNodeNotInFile, [ANodeNum, FFile.Nodes.Count - 1]));
end;

function TProcAreaLocator.AreaOfChild(const AChild: Integer): Integer;
begin
  // a negative child is the area -1 - child
  Result := -1 - AChild;
  if Result >= FFile.NumAreas then
    raise EProcFileException.Create(Format(SAreaOutOfRange, [Result, FFile.NumAreas]));
end;

function TProcAreaLocator.PointInArea(const APoint: TGeoVec3): Integer;
var
  LNodeNum, LSteps: Integer;
  LNode: TProcNode;
  LDistance: Single;
begin
  if FFile.Nodes.Count = 0 then
    Exit(-1);
  LNodeNum := 0;
  LSteps := 0;
  while True do
  begin
    CheckNode(LNodeNum);
    // a path longer than the number of nodes goes round a cycle
    Inc(LSteps);
    if LSteps > FFile.Nodes.Count then
      raise EProcFileException.Create(STreeTooDeep);
    LNode := FFile.Nodes[LNodeNum];
    LDistance := APoint.X * LNode.Plane.A + APoint.Y * LNode.Plane.B + APoint.Z * LNode.Plane.C + LNode.Plane.D;
    if LDistance > 0 then
      LNodeNum := LNode.PositiveChild
    else
      LNodeNum := LNode.NegativeChild;
    if LNodeNum = 0 then
      Exit(-1); // in solid
    if LNodeNum < 0 then
      Exit(AreaOfChild(LNodeNum));
  end;
end;

procedure TProcAreaLocator.CollectAreas(const ANodeNum: Integer; const ABounds: TGeoBounds;
  var AAreas: TArray<Integer>; var ANumAreas: Integer; const AMaxAreas, ADepth: Integer);
var
  LNodeNum, LSide, LIndex, LArea: Integer;
  LNode: TProcNode;
  LKnown: Boolean;
begin
  if ADepth > FFile.Nodes.Count then
    raise EProcFileException.Create(STreeTooDeep);
  LNodeNum := ANodeNum;
  repeat
    if LNodeNum < 0 then
    begin
      LArea := AreaOfChild(LNodeNum);
      LKnown := False;
      for LIndex := 0 to ANumAreas - 1 do
        if AAreas[LIndex] = LArea then
        begin
          LKnown := True;
          Break;
        end;
      if not LKnown and (ANumAreas < AMaxAreas) then
      begin
        AAreas[ANumAreas] := LArea;
        Inc(ANumAreas);
      end;
      Exit;
    end;
    CheckNode(LNodeNum);
    LNode := FFile.Nodes[LNodeNum];
    LSide := ABounds.PlaneSide(LNode.Plane);
    if LSide = 0 then // PLANESIDE_FRONT
      LNodeNum := LNode.PositiveChild
    else if LSide = 1 then // PLANESIDE_BACK
      LNodeNum := LNode.NegativeChild
    else
    begin
      if LNode.NegativeChild <> 0 then
      begin
        CollectAreas(LNode.NegativeChild, ABounds, AAreas, ANumAreas, AMaxAreas, ADepth + 1);
        if ANumAreas >= AMaxAreas then
          Exit;
      end;
      LNodeNum := LNode.PositiveChild;
    end;
  until LNodeNum = 0;
end;

function TProcAreaLocator.BoundsInAreas(const ABounds: TGeoBounds; var AAreas: TArray<Integer>;
  const AMaxAreas: Integer): Integer;
begin
  Result := 0;
  if FFile.Nodes.Count = 0 then
    Exit;
  if Length(AAreas) < AMaxAreas then
    SetLength(AAreas, AMaxAreas);
  CollectAreas(0, ABounds, AAreas, Result, AMaxAreas, 0);
end;

end.
