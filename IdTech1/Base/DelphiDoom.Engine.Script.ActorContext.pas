{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the implicit actor of the scripts                      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Script.ActorContext;

interface

uses
  p_mobj_h,
  DelphiDoom.Engine.Script.ActorContext.Intf;

type
  /// <summary>
  ///   The current actor of the scripts: a pointer to the mobj, as the old variable was (the key 0
  ///   gives it back without looking for it among the mobjs)
  /// </summary>
  TEngineScriptActorContext = class(TInterfacedObject, IEngineScriptActorContext)
  strict private
    FActor: Pmobj_t;
  public
    constructor Create;
    function CurrentKey: Cardinal;
    procedure Enter(const AActor: Pmobj_t);
    procedure Leave;
    function Current: Pmobj_t;
    function MobjFromKey(const AKey: Cardinal): Pmobj_t;
  end;

implementation

uses
  p_mobjlist,
  DelphiDoom.ScriptHost.World.Intf;

{ TEngineScriptActorContext }

constructor TEngineScriptActorContext.Create;
begin
  inherited Create;
  FActor := nil;
end;

function TEngineScriptActorContext.CurrentKey: Cardinal;
begin
  if FActor <> nil then
    Result := FActor.key
  else
    Result := SCRIPT_INVALID_ID;
end;

procedure TEngineScriptActorContext.Enter(const AActor: Pmobj_t);
begin
  FActor := AActor;
end;

procedure TEngineScriptActorContext.Leave;
begin
  FActor := nil;
end;

function TEngineScriptActorContext.Current: Pmobj_t;
begin
  Result := FActor;
end;

function TEngineScriptActorContext.MobjFromKey(const AKey: Cardinal): Pmobj_t;
begin
  if AKey = 0 then
    Result := FActor
  else if AKey = SCRIPT_INVALID_ID then
    Result := nil
  else
    Result := mobjlist.FindMobjFromKey(AKey);
end;

end.
