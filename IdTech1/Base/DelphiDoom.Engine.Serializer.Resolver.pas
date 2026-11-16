{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the pointers of states, mobjs and players of a save    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Serializer.Resolver;

interface

uses
  DelphiDoom.Serializer.Intf;

type
  /// <summary>
  ///   Answers the serializer: a state is an index in states[], a mobj has the key that it got
  ///   when it was spawned, a player is its index in players[] plus one. The only class that
  ///   reads those globals for the save files
  /// </summary>
  TEngineSerializerResolver = class(TInterfacedObject, ISerializerStateResolver,
    ISerializerMobjResolver, ISerializerPlayerResolver)
  public
    function StateIndex(const AState: Pointer): Cardinal;
    function StateAt(AIndex: Cardinal): Pointer;
    function MobjKey(const AMobj: Pointer): Cardinal;
    function MobjByKey(AKey: Cardinal): Pointer;
    function PlayerNumber(const APlayer: Pointer): Cardinal;
    function PlayerByNumber(ANumber: Cardinal): Pointer;
  end;

implementation

uses
  d_player,
  info_h,
  info,
  p_mobj_h,
  p_mobj;

{ TEngineSerializerResolver }

function TEngineSerializerResolver.StateIndex(const AState: Pointer): Cardinal;
begin
  Result := Cardinal((NativeInt(AState) - NativeInt(@states[0])) div SizeOf(state_t));
end;

function TEngineSerializerResolver.StateAt(AIndex: Cardinal): Pointer;
begin
  Result := @states[AIndex];
end;

function TEngineSerializerResolver.MobjKey(const AMobj: Pointer): Cardinal;
begin
  Result := Pmobj_t(AMobj).key;
end;

function TEngineSerializerResolver.MobjByKey(AKey: Cardinal): Pointer;
begin
  Result := P_FindMobjFromKey(AKey);
end;

function TEngineSerializerResolver.PlayerNumber(const APlayer: Pointer): Cardinal;
begin
  Result := Cardinal((NativeInt(APlayer) - NativeInt(@players[0])) div SizeOf(player_t)) + 1;
end;

function TEngineSerializerResolver.PlayerByNumber(ANumber: Cardinal): Pointer;
begin
  Result := @players[ANumber - 1];
end;

end.
