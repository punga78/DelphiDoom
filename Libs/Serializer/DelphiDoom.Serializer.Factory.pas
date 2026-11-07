{******************************************************************************}
{                                                                              }
{  DelphiDoom: serializer library - the factory: the composition root          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Serializer.Factory;

interface

uses
  DelphiDoom.Serializer.Intf;

type
  /// <summary>The only place that knows the classes behind ISerializer</summary>
  TSerializerFactory = class(TInterfacedObject, ISerializerFactory)
  strict private
    FStates: ISerializerStateResolver;
    FMobjs: ISerializerMobjResolver;
    FPlayers: ISerializerPlayerResolver;
  public
    /// <summary>The resolvers are shared by all the serializers that the factory makes</summary>
    constructor Create(const AStates: ISerializerStateResolver; const AMobjs: ISerializerMobjResolver;
      const APlayers: ISerializerPlayerResolver);
    function CreateSerializer: ISerializer;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Serializer.FieldCodec, DelphiDoom.Serializer.RecordSerializer;

{ TSerializerFactory }

constructor TSerializerFactory.Create(const AStates: ISerializerStateResolver;
  const AMobjs: ISerializerMobjResolver; const APlayers: ISerializerPlayerResolver);
begin
  inherited Create;
  if not Assigned(AStates) then
    raise EArgumentNilException.Create('AStates');
  if not Assigned(AMobjs) then
    raise EArgumentNilException.Create('AMobjs');
  if not Assigned(APlayers) then
    raise EArgumentNilException.Create('APlayers');
  FStates := AStates;
  FMobjs := AMobjs;
  FPlayers := APlayers;
end;

function TSerializerFactory.CreateSerializer: ISerializer;
begin
  Result := TRecordSerializer.Create(TSerializerFieldCodec.Create(FStates, FMobjs, FPlayers));
end;

end.
