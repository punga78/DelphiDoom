{******************************************************************************}
{                                                                              }
{  DelphiDoom: glbsp - arrays of the level being built                         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Port of the level arrays of level.c of glBSP 2.24 (C) 2000-2007 Andrew      }
{  Apted                                                                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Glbsp.Level.Data;

interface

uses
  System.Generics.Collections,
  System.SysUtils,
  DelphiDoom.Glbsp.Level.Types;

const
  SNoSuchObject = 'No such %s number #%d';

type
  /// <summary>
  ///   All the objects of the level: they are created through the New
  ///   methods, found through the Lookup methods and freed together with
  ///   the container. It replaces the global arrays of the C original
  /// </summary>
  TGlbspLevelData = class
  private
    FVertices: TObjectList<TGlbspVertex>;
    FLinedefs: TObjectList<TGlbspLinedef>;
    FSidedefs: TObjectList<TGlbspSidedef>;
    FSectors: TObjectList<TGlbspSector>;
    FThings: TObjectList<TGlbspThing>;
    FSegs: TObjectList<TGlbspSeg>;
    FSubsecs: TObjectList<TGlbspSubsec>;
    FNodes: TObjectList<TGlbspNode>;
    FStaleNodes: TObjectList<TGlbspNode>;
    FWallTips: TObjectList<TGlbspWallTip>;
    FNumNormalVert: Integer;
    FNumGlVert: Integer;
    FNumCompleteSeg: Integer;
    FDoingNormal: Boolean;
    FDoingHexen: Boolean;
    function Lookup<T: class>(const AList: TObjectList<T>; const AIndex: Integer;
      const AKind: string): T;
  public
    constructor Create;
    destructor Destroy; override;

    function NewVertex: TGlbspVertex;
    function NewLinedef: TGlbspLinedef;
    function NewSidedef: TGlbspSidedef;
    function NewSector: TGlbspSector;
    function NewThing: TGlbspThing;
    function NewSeg: TGlbspSeg;
    function NewSubsec: TGlbspSubsec;
    function NewNode: TGlbspNode;
    function NewStaleNode: TGlbspNode;
    function NewWallTip: TGlbspWallTip;

    /// <exception cref="EGlbspLevelException">no object with that index</exception>
    function LookupVertex(const AIndex: Integer): TGlbspVertex;
    function LookupLinedef(const AIndex: Integer): TGlbspLinedef;
    function LookupSidedef(const AIndex: Integer): TGlbspSidedef;
    function LookupSector(const AIndex: Integer): TGlbspSector;
    function LookupThing(const AIndex: Integer): TGlbspThing;
    function LookupSeg(const AIndex: Integer): TGlbspSeg;
    function LookupSubsec(const AIndex: Integer): TGlbspSubsec;
    function LookupNode(const AIndex: Integer): TGlbspNode;
    function LookupStaleNode(const AIndex: Integer): TGlbspNode;

    /// <summary>Frees everything and resets the counters</summary>
    procedure Clear;

    property Vertices: TObjectList<TGlbspVertex> read FVertices;
    property Linedefs: TObjectList<TGlbspLinedef> read FLinedefs;
    property Sidedefs: TObjectList<TGlbspSidedef> read FSidedefs;
    property Sectors: TObjectList<TGlbspSector> read FSectors;
    property Things: TObjectList<TGlbspThing> read FThings;
    property Segs: TObjectList<TGlbspSeg> read FSegs;
    property Subsecs: TObjectList<TGlbspSubsec> read FSubsecs;
    property Nodes: TObjectList<TGlbspNode> read FNodes;
    property StaleNodes: TObjectList<TGlbspNode> read FStaleNodes;
    property WallTips: TObjectList<TGlbspWallTip> read FWallTips;
    property NumNormalVert: Integer read FNumNormalVert write FNumNormalVert;
    property NumGlVert: Integer read FNumGlVert write FNumGlVert;
    property NumCompleteSeg: Integer read FNumCompleteSeg write FNumCompleteSeg;
    /// <summary>The normal nodes are built too, not only the GL ones</summary>
    property DoingNormal: Boolean read FDoingNormal write FDoingNormal;
    property DoingHexen: Boolean read FDoingHexen write FDoingHexen;
  end;

implementation

{ TGlbspLevelData }

constructor TGlbspLevelData.Create;
begin
  inherited Create;
  FVertices := TObjectList<TGlbspVertex>.Create(True);
  FLinedefs := TObjectList<TGlbspLinedef>.Create(True);
  FSidedefs := TObjectList<TGlbspSidedef>.Create(True);
  FSectors := TObjectList<TGlbspSector>.Create(True);
  FThings := TObjectList<TGlbspThing>.Create(True);
  FSegs := TObjectList<TGlbspSeg>.Create(True);
  FSubsecs := TObjectList<TGlbspSubsec>.Create(True);
  FNodes := TObjectList<TGlbspNode>.Create(True);
  FStaleNodes := TObjectList<TGlbspNode>.Create(True);
  FWallTips := TObjectList<TGlbspWallTip>.Create(True);
end;

destructor TGlbspLevelData.Destroy;
begin
  FWallTips.Free;
  FStaleNodes.Free;
  FNodes.Free;
  FSubsecs.Free;
  FSegs.Free;
  FThings.Free;
  FSectors.Free;
  FSidedefs.Free;
  FLinedefs.Free;
  FVertices.Free;
  inherited Destroy;
end;

procedure TGlbspLevelData.Clear;
begin
  FVertices.Clear;
  FSidedefs.Clear;
  FLinedefs.Clear;
  FSectors.Clear;
  FThings.Clear;
  FSegs.Clear;
  FSubsecs.Clear;
  FNodes.Clear;
  FStaleNodes.Clear;
  FWallTips.Clear;
  FNumNormalVert := 0;
  FNumGlVert := 0;
  FNumCompleteSeg := 0;
end;

function TGlbspLevelData.Lookup<T>(const AList: TObjectList<T>; const AIndex: Integer;
  const AKind: string): T;
begin
  if (AIndex < 0) or (AIndex >= AList.Count) then
    raise EGlbspLevelException.CreateFmt(SNoSuchObject, [AKind, AIndex]);
  Result := AList[AIndex];
end;

function TGlbspLevelData.NewVertex: TGlbspVertex;
begin
  Result := TGlbspVertex.Create;
  FVertices.Add(Result);
end;

function TGlbspLevelData.NewLinedef: TGlbspLinedef;
begin
  Result := TGlbspLinedef.Create;
  FLinedefs.Add(Result);
end;

function TGlbspLevelData.NewSidedef: TGlbspSidedef;
begin
  Result := TGlbspSidedef.Create;
  FSidedefs.Add(Result);
end;

function TGlbspLevelData.NewSector: TGlbspSector;
begin
  Result := TGlbspSector.Create;
  FSectors.Add(Result);
end;

function TGlbspLevelData.NewThing: TGlbspThing;
begin
  Result := TGlbspThing.Create;
  FThings.Add(Result);
end;

function TGlbspLevelData.NewSeg: TGlbspSeg;
begin
  Result := TGlbspSeg.Create;
  FSegs.Add(Result);
end;

function TGlbspLevelData.NewSubsec: TGlbspSubsec;
begin
  Result := TGlbspSubsec.Create;
  FSubsecs.Add(Result);
end;

function TGlbspLevelData.NewNode: TGlbspNode;
begin
  Result := TGlbspNode.Create;
  FNodes.Add(Result);
end;

function TGlbspLevelData.NewStaleNode: TGlbspNode;
begin
  Result := TGlbspNode.Create;
  FStaleNodes.Add(Result);
end;

function TGlbspLevelData.NewWallTip: TGlbspWallTip;
begin
  Result := TGlbspWallTip.Create;
  FWallTips.Add(Result);
end;

function TGlbspLevelData.LookupVertex(const AIndex: Integer): TGlbspVertex;
begin
  Result := Lookup<TGlbspVertex>(FVertices, AIndex, 'vertex');
end;

function TGlbspLevelData.LookupLinedef(const AIndex: Integer): TGlbspLinedef;
begin
  Result := Lookup<TGlbspLinedef>(FLinedefs, AIndex, 'linedef');
end;

function TGlbspLevelData.LookupSidedef(const AIndex: Integer): TGlbspSidedef;
begin
  Result := Lookup<TGlbspSidedef>(FSidedefs, AIndex, 'sidedef');
end;

function TGlbspLevelData.LookupSector(const AIndex: Integer): TGlbspSector;
begin
  Result := Lookup<TGlbspSector>(FSectors, AIndex, 'sector');
end;

function TGlbspLevelData.LookupThing(const AIndex: Integer): TGlbspThing;
begin
  Result := Lookup<TGlbspThing>(FThings, AIndex, 'thing');
end;

function TGlbspLevelData.LookupSeg(const AIndex: Integer): TGlbspSeg;
begin
  Result := Lookup<TGlbspSeg>(FSegs, AIndex, 'seg');
end;

function TGlbspLevelData.LookupSubsec(const AIndex: Integer): TGlbspSubsec;
begin
  Result := Lookup<TGlbspSubsec>(FSubsecs, AIndex, 'subsector');
end;

function TGlbspLevelData.LookupNode(const AIndex: Integer): TGlbspNode;
begin
  Result := Lookup<TGlbspNode>(FNodes, AIndex, 'node');
end;

function TGlbspLevelData.LookupStaleNode(const AIndex: Integer): TGlbspNode;
begin
  Result := Lookup<TGlbspNode>(FStaleNodes, AIndex, 'stale_node');
end;

end.
