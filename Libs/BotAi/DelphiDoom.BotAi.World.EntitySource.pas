{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotAasEntitySource, the entities of the AAS           }
{                                                                              }
{  Adapts the table of the entities of Libs\Aas (be_aas_entity.c) to what the  }
{  goals and the movement ask. Based on the Quake III Arena GPL Source Code    }
{  (id Software). Copyright (C) 1999-2005 Id Software, Inc. This unit is       }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.World.EntitySource;

interface

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Aas.Entity.Types, DelphiDoom.Aas.Entity.Table, DelphiDoom.BotAi.World.Intf;

type
  /// <summary>The entity table of a <c>TAasSystem</c> (Entities) seen as an <c>IBotEntitySource</c>; the table is not owned</summary>
  TBotAasEntitySource = class(TInterfacedObject, IBotEntitySource)
  strict private
    FTable: TAasEntityTable;
  public
    constructor Create(const ATable: TAasEntityTable);
    function EntityType(const AEntity: Integer): Integer;
    function EntityModelIndex(const AEntity: Integer): Integer;
    function EntityModelNum(const AEntity: Integer): Integer;
    function EntityInfo(const AEntity: Integer): TAasEntityInfo;
    function NextEntity(const AEntity: Integer): Integer;
    function OriginOfMoverWithModelNum(const AModelNum: Integer; out AOrigin: TVec3): Boolean;
  end;

implementation

{ TBotAasEntitySource }

constructor TBotAasEntitySource.Create(const ATable: TAasEntityTable);
begin
  inherited Create;
  FTable := ATable;
end;

function TBotAasEntitySource.EntityType(const AEntity: Integer): Integer;
begin
  Result := FTable.EntityType(AEntity);
end;

function TBotAasEntitySource.EntityModelIndex(const AEntity: Integer): Integer;
begin
  Result := FTable.EntityModelIndex(AEntity);
end;

function TBotAasEntitySource.EntityModelNum(const AEntity: Integer): Integer;
begin
  Result := FTable.EntityModelNum(AEntity);
end;

function TBotAasEntitySource.EntityInfo(const AEntity: Integer): TAasEntityInfo;
begin
  Result := FTable.EntityInfo(AEntity);
end;

function TBotAasEntitySource.NextEntity(const AEntity: Integer): Integer;
begin
  Result := FTable.NextEntity(AEntity);
end;

function TBotAasEntitySource.OriginOfMoverWithModelNum(const AModelNum: Integer; out AOrigin: TVec3): Boolean;
begin
  Result := FTable.OriginOfMoverWithModelNum(AModelNum, AOrigin);
end;

end.
