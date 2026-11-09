{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the specials of the sectors, for the scripts           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Script.SectorSpecials;

interface

uses
  DelphiDoom.ScriptHost.SectorSpecials.Intf,
  DelphiDoom.ScriptHost.SectorSpecials.Types;

type
  /// <summary>
  ///   The gateway of the script classes to the specials of the map (the EVH_* of udmf_*, the
  ///   polyobjects of po_man, the lightning of udmf_spec or p_anim). The only class of the
  ///   scripts of sector specials that knows the types of the engine; it was in psi_map.pas
  /// </summary>
  TEngineScriptSectorSpecials = class(TInterfacedObject, IScriptSectorSpecials)
  public
    function DoCeiling(var AArguments: TScriptSpecialArguments; const AKind: TScriptCeilingKind): Boolean;
    function CeilingCrushStop(var AArguments: TScriptSpecialArguments): Boolean;
    function DoDoor(var AArguments: TScriptSpecialArguments; const AKind: TScriptDoorKind): Boolean;
    function DoFloor(var AArguments: TScriptSpecialArguments; const AKind: TScriptFloorKind): Boolean;
    function DoFloorAndCeiling(var AArguments: TScriptSpecialArguments; const ARaise: Boolean): Boolean;
    function FloorCrushStop(var AArguments: TScriptSpecialArguments): Boolean;
    function StartFloorWaggle(const ATag, AAmplitude, AFrequency, AOffset, ATime: Integer): Boolean;
    function SpawnLight(var AArguments: TScriptSpecialArguments; const AKind: TScriptLightKind): Boolean;
    procedure ForceLightning(const ATics: Integer);
    function BuildPillar(var AArguments: TScriptSpecialArguments; const ACrush: Boolean): Boolean;
    function OpenPillar(var AArguments: TScriptSpecialArguments): Boolean;
    function DoPlat(var AArguments: TScriptSpecialArguments; const AKind: TScriptPlatKind): Boolean;
    function OpenPolyDoor(var AArguments: TScriptSpecialArguments; const AKind: TScriptPolyDoorKind): Boolean;
    function MovePoly(var AArguments: TScriptSpecialArguments; const ATimesEight, AOverride: Boolean): Boolean;
    function RotatePoly(var AArguments: TScriptSpecialArguments; const ADirection: Integer;
      const AOverride: Boolean): Boolean;
  end;

implementation

uses
  System.SysUtils,
  p_spec,
  {$IFDEF HEXEN}
  p_anim,
  {$ELSE}
  udmf_spec,
  {$ENDIF}
  po_man,
  udmf_ceilng,
  udmf_doors,
  udmf_floor,
  udmf_lights,
  udmf_plats;

const
  CEILING_KINDS: array[TScriptCeilingKind] of ceiling_e = (
    CLEV_CRUSHANDRAISE,
    CLEV_CRUSHRAISEANDSTAY,
    CLEV_LOWERANDCRUSH,
    CLEV_LOWERBYVALUE,
    CLEV_LOWERBYVALUETIMES8,
    CLEV_LOWERTOFLOOR,
    CLEV_LOWERTOMAXFLOOR,
    CLEV_LOWERTOLOWEST,
    CLEV_MOVETOVALUEANDCRUSH,
    CLEV_MOVETOVALUE,
    CLEV_MOVETOVALUETIMES8,
    CLEV_RAISEBYVALUE,
    CLEV_RAISEBYVALUETIMES8,
    CLEV_RAISETOHIGHESTFLOOR,
    CLEV_RAISETOHIGHEST
  );

  DOOR_KINDS: array[TScriptDoorKind] of vldoor_e = (
    DREV_CLOSE,
    DREV_CLOSEWAITTHENOPEN,
    DREV_OPEN,
    DREV_NORMAL
  );

  FLOOR_KINDS: array[TScriptFloorKind] of floor_e = (
    FLEV_LOWERFLOORBYVALUE,
    FLEV_LOWERBYVALUETIMES8,
    FLEV_LOWERFLOORTOHIGHEST,
    FLEV_LOWERFLOORTOLOWESTCEILING,
    FLEV_LOWERFLOORTOLOWEST,
    FLEV_LOWERFLOOR,
    FLEV_MOVETOVALUE,
    FLEV_MOVETOVALUETIMES8,
    FLEV_RAISEFLOORCRUSHDOOM,
    FLEV_RAISEFLOORCRUSH,
    FLEV_RAISETOTEXTURE,
    FLEV_RAISEFLOORBYVALUE,
    FLEV_RAISEFLOORBYVALUETIMES8,
    FLEV_RAISETIMES8INSTANT,
    FLEV_LOWERTIMES8INSTANT,
    FLEV_RAISETOCEILING,
    FLEV_RAISEFLOOR,
    FLEV_RAISETOLOWESTCEILING,
    FLEV_RAISEFLOORTONEAREST,
    FLEV_FLOORTOCEILINGINSTANT
  );

  LIGHT_KINDS: array[TScriptLightKind] of lighttype_t = (
    LITE_CHANGETOVALUE,
    LITE_FADE,
    LITE_FLICKER,
    LITE_GLOW,
    LITE_LOWERBYVALUE,
    LITE_MAXNEIGHTBOR,
    LITE_MINNEIGHTBOR,
    LITE_RAISEBYVALUE,
    LITE_STROBE,
    LITE_STROBEDOOM
  );

  PLAT_KINDS: array[TScriptPlatKind] of plattype_e = (
    PLAT_DOWNBYVALUEWAITUPSTAY,
    PLAT_DOWNWAITUPSTAY,
    PLAT_DOWNWAITUPSTAYLIP,
    PLAT_PERPETUALRAISE,
    PLAT_PERPETUALRAISELIP,
    PLAT_UPBYVALUEWAITDOWNSTAY,
    PLAT_UPNEARESTWAITDOWNSTAY,
    PLAT_UPWAITDOWNSTAY
  );

  POLYDOOR_KINDS: array[TScriptPolyDoorKind] of podoortype_t = (
    PODOOR_SLIDE,
    PODOOR_SWING
  );

{ TEngineScriptSectorSpecials }

function TEngineScriptSectorSpecials.DoCeiling(var AArguments: TScriptSpecialArguments;
  const AKind: TScriptCeilingKind): Boolean;
begin
  Result := EVH_DoCeiling(nil, @AArguments, CEILING_KINDS[AKind]);
end;

function TEngineScriptSectorSpecials.CeilingCrushStop(var AArguments: TScriptSpecialArguments): Boolean;
begin
  Result := EVH_CeilingCrushStop(nil, @AArguments);
end;

function TEngineScriptSectorSpecials.DoDoor(var AArguments: TScriptSpecialArguments;
  const AKind: TScriptDoorKind): Boolean;
begin
  Result := EVH_DoDoor(nil, @AArguments, DOOR_KINDS[AKind]);
end;

function TEngineScriptSectorSpecials.DoFloor(var AArguments: TScriptSpecialArguments;
  const AKind: TScriptFloorKind): Boolean;
begin
  Result := EVH_DoFloor(nil, @AArguments, FLOOR_KINDS[AKind]);
end;

function TEngineScriptSectorSpecials.DoFloorAndCeiling(var AArguments: TScriptSpecialArguments;
  const ARaise: Boolean): Boolean;
begin
  Result := EVH_DoFloorAndCeiling(nil, @AArguments, ARaise);
end;

function TEngineScriptSectorSpecials.FloorCrushStop(var AArguments: TScriptSpecialArguments): Boolean;
begin
  Result := EVH_FloorCrushStop(nil, @AArguments);
end;

function TEngineScriptSectorSpecials.StartFloorWaggle(const ATag, AAmplitude, AFrequency, AOffset,
  ATime: Integer): Boolean;
begin
  Result := EVH_StartFloorWaggle(ATag, AAmplitude, AFrequency, AOffset, ATime);
end;

function TEngineScriptSectorSpecials.SpawnLight(var AArguments: TScriptSpecialArguments;
  const AKind: TScriptLightKind): Boolean;
begin
  Result := EVH_SpawnLight(nil, @AArguments, LIGHT_KINDS[AKind]);
end;

procedure TEngineScriptSectorSpecials.ForceLightning(const ATics: Integer);
begin
  P_ForceLightning(ATics);
end;

function TEngineScriptSectorSpecials.BuildPillar(var AArguments: TScriptSpecialArguments;
  const ACrush: Boolean): Boolean;
begin
  Result := EVH_BuildPillar(nil, @AArguments, ACrush);
end;

function TEngineScriptSectorSpecials.OpenPillar(var AArguments: TScriptSpecialArguments): Boolean;
begin
  Result := EVH_OpenPillar(nil, @AArguments);
end;

function TEngineScriptSectorSpecials.DoPlat(var AArguments: TScriptSpecialArguments;
  const AKind: TScriptPlatKind): Boolean;
begin
  Result := EVH_DoPlat(nil, @AArguments, PLAT_KINDS[AKind], 0);
end;

function TEngineScriptSectorSpecials.OpenPolyDoor(var AArguments: TScriptSpecialArguments;
  const AKind: TScriptPolyDoorKind): Boolean;
begin
  Result := EVH_OpenPolyDoor(nil, @AArguments, POLYDOOR_KINDS[AKind]);
end;

function TEngineScriptSectorSpecials.MovePoly(var AArguments: TScriptSpecialArguments;
  const ATimesEight, AOverride: Boolean): Boolean;
begin
  Result := EVH_MovePoly(nil, @AArguments, ATimesEight, AOverride);
end;

function TEngineScriptSectorSpecials.RotatePoly(var AArguments: TScriptSpecialArguments;
  const ADirection: Integer; const AOverride: Boolean): Boolean;
begin
  Result := EVH_RotatePoly(nil, @AArguments, ADirection, AOverride);
end;

end.
