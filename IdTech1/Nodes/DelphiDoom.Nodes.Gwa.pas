{******************************************************************************}
{                                                                              }
{  DelphiDoom: Nodes library - the nodes of a GWA file                         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Nodes.Gwa;

interface

uses
  DelphiDoom.Nodes.Types, DelphiDoom.Nodes.Intf;

type
  /// <summary>The records read from a GWA: what the reader gives, held for the engine</summary>
  TNodesGwa = class(TInterfacedObject, INodesGwa)
  strict private
    FVersion: Integer;
    FGlVertexes: TArray<TNodesGlVertex>;
    FSubsectors: TArray<TNodesGlSubsector>;
    FNodes: TArray<TNodesGlNode>;
    FSegs: TArray<TNodesGlSeg>;
  public
    constructor Create(AVersion: Integer; const AGlVertexes: TArray<TNodesGlVertex>;
      const ASubsectors: TArray<TNodesGlSubsector>; const ANodes: TArray<TNodesGlNode>;
      const ASegs: TArray<TNodesGlSeg>);
    function GetVersion: Integer;
    function GetGlVertexes: TArray<TNodesGlVertex>;
    function GetSubsectors: TArray<TNodesGlSubsector>;
    function GetNodes: TArray<TNodesGlNode>;
    function GetSegs: TArray<TNodesGlSeg>;
  end;

implementation

{ TNodesGwa }

constructor TNodesGwa.Create(AVersion: Integer; const AGlVertexes: TArray<TNodesGlVertex>;
  const ASubsectors: TArray<TNodesGlSubsector>; const ANodes: TArray<TNodesGlNode>;
  const ASegs: TArray<TNodesGlSeg>);
begin
  inherited Create;
  FVersion := AVersion;
  FGlVertexes := AGlVertexes;
  FSubsectors := ASubsectors;
  FNodes := ANodes;
  FSegs := ASegs;
end;

function TNodesGwa.GetVersion: Integer;
begin
  Result := FVersion;
end;

function TNodesGwa.GetGlVertexes: TArray<TNodesGlVertex>;
begin
  Result := FGlVertexes;
end;

function TNodesGwa.GetSubsectors: TArray<TNodesGlSubsector>;
begin
  Result := FSubsectors;
end;

function TNodesGwa.GetNodes: TArray<TNodesGlNode>;
begin
  Result := FNodes;
end;

function TNodesGwa.GetSegs: TArray<TNodesGlSeg>;
begin
  Result := FSegs;
end;

end.
