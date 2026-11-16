{******************************************************************************}
{                                                                              }
{  DelphiDoom: UDMF library - the map that was read                           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Udmf.Map;

interface

uses
  System.Generics.Collections, DelphiDoom.Udmf.Types;

type
  /// <summary>What the text of a map says: its namespace and its things, lines, sides, vertexes and sectors, in the order of the text</summary>
  TUdmfMap = class
  private
    FNamespace: string;
    FLineTranslate: Boolean;
    FThings: TList<TUdmfThing>;
    FLines: TList<TUdmfLine>;
    FSides: TList<TUdmfSide>;
    FVertexes: TList<TUdmfVertex>;
    FSectors: TList<TUdmfSector>;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>In capital letters, as the last namespace of the text; empty if there is none</summary>
    property Namespace: string read FNamespace write FNamespace;
    property LineTranslate: Boolean read FLineTranslate write FLineTranslate;
    property Things: TList<TUdmfThing> read FThings;
    property Lines: TList<TUdmfLine> read FLines;
    property Sides: TList<TUdmfSide> read FSides;
    property Vertexes: TList<TUdmfVertex> read FVertexes;
    property Sectors: TList<TUdmfSector> read FSectors;
  end;

implementation

{ TUdmfMap }

constructor TUdmfMap.Create;
begin
  inherited Create;
  FThings := TList<TUdmfThing>.Create;
  FLines := TList<TUdmfLine>.Create;
  FSides := TList<TUdmfSide>.Create;
  FVertexes := TList<TUdmfVertex>.Create;
  FSectors := TList<TUdmfSector>.Create;
end;

destructor TUdmfMap.Destroy;
begin
  FSectors.Free;
  FVertexes.Free;
  FSides.Free;
  FLines.Free;
  FThings.Free;
  inherited Destroy;
end;

end.