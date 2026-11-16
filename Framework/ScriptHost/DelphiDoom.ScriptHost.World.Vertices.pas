{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - the vertex functions of PS_GAME                   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  TVertex, GetVertexX, GetVertexY, IsValidVertex and GetVertexCount (the      }
{  PS_*Vertex* of psi_game.pas).                                               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.World.Vertices;

interface

uses
  DelphiDoom.ScriptHost.Intf,
  DelphiDoom.ScriptHost.World.Intf;

type
  /// <summary>The vertex functions of the unit PS_GAME (called with the object as Self)</summary>
  TScriptVertices = class(TInterfacedObject, IScriptVertices, IScriptFunctionSection)
  strict private
    FWorld: IScriptWorld;
  public
    /// <exception cref="EArgumentNilException">If the world is nil</exception>
    constructor Create(const AWorld: IScriptWorld);
    procedure Describe(const ATable: IScriptFunctionTable);
    function TVertex(const AId: Integer): Integer;
    function GetVertexX(const AVertex: Integer): Integer;
    function GetVertexY(const AVertex: Integer): Integer;
    function IsValidVertex(const AVertex: Integer): Boolean;
    function GetVertexCount: Integer;
  end;

implementation

uses
  System.SysUtils;

{ TScriptVertices }

constructor TScriptVertices.Create(const AWorld: IScriptWorld);
begin
  inherited Create;
  if not Assigned(AWorld) then
    raise EArgumentNilException.Create('AWorld');
  FWorld := AWorld;
end;

procedure TScriptVertices.Describe(const ATable: IScriptFunctionTable);
begin
  ATable.AddMethodWithCustomResult('procedure TVertex(const id: Integer);', '!TVertex',
    'function TVertex(const id: Integer): !TVertex;', Self, @TScriptVertices.TVertex);
  ATable.AddMethod('function GetVertexX(const v: integer): fixed_t;', Self,
    @TScriptVertices.GetVertexX);
  ATable.AddMethod('function GetVertexY(const v: integer): fixed_t;', Self,
    @TScriptVertices.GetVertexY);
  ATable.AddMethod('function IsValidVertex(const v: Integer): boolean;', Self,
    @TScriptVertices.IsValidVertex);
  ATable.AddMethod('function GetVertexCount: Integer;', Self, @TScriptVertices.GetVertexCount);
end;

function TScriptVertices.TVertex(const AId: Integer): Integer;
begin
  if IsValidVertex(AId) then
    Result := AId + 1
  else
    Result := SCRIPT_INVALID_ID;
end;

function TScriptVertices.GetVertexX(const AVertex: Integer): Integer;
begin
  if IsValidVertex(AVertex) then
    Result := FWorld.VertexX(AVertex)
  else
    Result := 0;
end;

function TScriptVertices.GetVertexY(const AVertex: Integer): Integer;
begin
  if IsValidVertex(AVertex) then
    Result := FWorld.VertexY(AVertex)
  else
    Result := 0;
end;

function TScriptVertices.IsValidVertex(const AVertex: Integer): Boolean;
begin
  Result := (AVertex >= 0) and (AVertex < FWorld.VertexCount);
end;

function TScriptVertices.GetVertexCount: Integer;
begin
  Result := FWorld.VertexCount;
end;

end.
