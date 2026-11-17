{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the entities of the AAS as the bots    }
{  see them                                                                    }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): be_aas_entity.c.}
{  Copyright (C) 1999-2005 Id Software, Inc. This unit is derived from the     }
{  Quake III Arena source code and is therefore available under the GNU        }
{  General Public License, version 2 or (at your option) any later version.    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Host.Bot.EntitySource;

interface

uses
  System.SysUtils, DelphiDoom.MathCore.Types, DelphiDoom.Aas.Entity.Types, DelphiDoom.Aas.Entity.Table,
  DelphiDoom.BotAi.World.Intf;

type
  /// <summary>
  ///   IBotEntitySource on the entity table of the AAS system, read from the system at every call: AAS_Setup makes
  ///   a new table (and AAS_Shutdown frees it), so no object may keep the old one. Without a table (before
  ///   AAS_Setup) there are no entities
  /// </summary>
  TQ3BotEntitySource = class(TInterfacedObject, IBotEntitySource)
  strict private
    FTable: TFunc<TAasEntityTable>;
  public
    constructor Create(const ATable: TFunc<TAasEntityTable>);
    function EntityType(const AEntity: Integer): Integer;
    function EntityModelIndex(const AEntity: Integer): Integer;
    function EntityModelNum(const AEntity: Integer): Integer;
    function EntityInfo(const AEntity: Integer): TAasEntityInfo;
    function NextEntity(const AEntity: Integer): Integer;
    function OriginOfMoverWithModelNum(const AModelNum: Integer; out AOrigin: TVec3): Boolean;
  end;

implementation

constructor TQ3BotEntitySource.Create(const ATable: TFunc<TAasEntityTable>);
begin
  inherited Create;
  FTable := ATable;
end;

function TQ3BotEntitySource.EntityType(const AEntity: Integer): Integer;
var
  LTable: TAasEntityTable;
begin
  LTable := FTable();
  if Assigned(LTable) then
    Result := LTable.EntityType(AEntity)
  else
    Result := 0;
end;

function TQ3BotEntitySource.EntityModelIndex(const AEntity: Integer): Integer;
var
  LTable: TAasEntityTable;
begin
  LTable := FTable();
  if Assigned(LTable) then
    Result := LTable.EntityModelIndex(AEntity)
  else
    Result := 0;
end;

function TQ3BotEntitySource.EntityModelNum(const AEntity: Integer): Integer;
var
  LTable: TAasEntityTable;
begin
  LTable := FTable();
  if Assigned(LTable) then
    Result := LTable.EntityModelNum(AEntity)
  else
    Result := 0;
end;

function TQ3BotEntitySource.EntityInfo(const AEntity: Integer): TAasEntityInfo;
var
  LTable: TAasEntityTable;
begin
  LTable := FTable();
  if Assigned(LTable) then
    Result := LTable.EntityInfo(AEntity)
  else
    Result := Default(TAasEntityInfo);
end;

function TQ3BotEntitySource.NextEntity(const AEntity: Integer): Integer;
var
  LTable: TAasEntityTable;
begin
  LTable := FTable();
  if Assigned(LTable) then
    Result := LTable.NextEntity(AEntity)
  else
    Result := 0;
end;

function TQ3BotEntitySource.OriginOfMoverWithModelNum(const AModelNum: Integer; out AOrigin: TVec3): Boolean;
var
  LTable: TAasEntityTable;
begin
  LTable := FTable();
  if Assigned(LTable) then
    Result := LTable.OriginOfMoverWithModelNum(AModelNum, AOrigin)
  else
  begin
    AOrigin := Default(TVec3);
    Result := False;
  end;
end;

end.
