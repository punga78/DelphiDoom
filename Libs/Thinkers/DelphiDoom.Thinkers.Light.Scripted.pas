{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - the lights of the scripted specials          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.Light.Scripted;

// The light level is 16 bit and the old code let the values wrap when they were stored; the
// fixed point products are 32 bit and wrap too
{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Intf, DelphiDoom.Thinkers.Light.Types, DelphiDoom.Thinkers.Light.Intf;

type
  /// <summary>
  ///   The lights of the scripted specials of Hexen and of the text maps (EVH_SpawnLight and
  ///   TH_Light of udmf_lights): raise, lower or set the level at once, or fade, glow, flicker
  ///   and strobe in time
  /// </summary>
  TLightScripted = class
  public
    /// <summary>
    ///   Starts one light on one sector. The kinds that change the level at once do it here and
    ///   give Instant; the others give the state the thinker needs and Thinker; an unknown kind
    ///   gives Invalid and touches nothing. The kind Flicker uses one random number
    /// </summary>
    class function Spawn(AKind: TLightKind; const ASector: ILightSector;
      const AArguments: TLightArguments; const ARandom: IGameRandom;
      out AState: TLightScriptedState): TLightScriptedOutcome; static;
    /// <summary>
    ///   One tic of a light. Gives True when the light is finished and the thinker has to be
    ///   removed (a fade that reached its level)
    /// </summary>
    class function Tick(AKind: TLightKind; AValue1, AValue2: Integer; var ATics1, ATics2,
      ACount: Integer; var ALightLevel: SmallInt; const ARandom: IGameRandom): Boolean; static;
  end;

implementation

uses
  DelphiDoom.MathCore.FixedMath, DelphiDoom.Thinkers.Light.Neighbors;

const
  LEVEL_MIN = 0;
  LEVEL_MAX = 255;
  FLICKER_COUNT_MASK = 64;
  FLICKER_SHORT_MASK = 7;
  FLICKER_LONG_MASK = 31;

procedure ClampLevel(const ASector: ILightSector);
begin
  if ASector.LightLevel < LEVEL_MIN then
    ASector.LightLevel := LEVEL_MIN
  else if ASector.LightLevel > LEVEL_MAX then
    ASector.LightLevel := LEVEL_MAX;
end;

{ TLightScripted }

class function TLightScripted.Spawn(AKind: TLightKind; const ASector: ILightSector;
  const AArguments: TLightArguments; const ARandom: IGameRandom;
  out AState: TLightScriptedState): TLightScriptedOutcome;
begin
  AState := Default(TLightScriptedState);
  Result := TLightScriptedOutcome.Instant;

  case AKind of
    TLightKind.RaiseByValue:
      begin
        ASector.LightLevel := ASector.LightLevel + AArguments.Arg1;
        if ASector.LightLevel > LEVEL_MAX then
          ASector.LightLevel := LEVEL_MAX;
      end;
    TLightKind.LowerByValue:
      begin
        ASector.LightLevel := ASector.LightLevel - AArguments.Arg1;
        if ASector.LightLevel < LEVEL_MIN then
          ASector.LightLevel := LEVEL_MIN;
      end;
    TLightKind.ChangeToValue:
      begin
        ASector.LightLevel := AArguments.Arg1;
        ClampLevel(ASector);
      end;
    TLightKind.Fade:
      begin
        Result := TLightScriptedOutcome.Thinker;
        // destination light level and the change for each tic
        AState.Value1 := AArguments.Arg1;
        AState.Value2 := TFixedMath.Divide((AArguments.Arg1 - ASector.LightLevel) * LIGHT_FRACUNIT,
          AArguments.Arg2 * LIGHT_FRACUNIT);
        if ASector.LightLevel <= AArguments.Arg1 then
          AState.Tics2 := 1
        else
          AState.Tics2 := -1;
      end;
    TLightKind.Glow:
      begin
        Result := TLightScriptedOutcome.Thinker;
        // upper and lower light level, and the change for each tic
        AState.Value1 := AArguments.Arg1;
        AState.Value2 := AArguments.Arg2;
        AState.Tics1 := TFixedMath.Divide((AArguments.Arg1 - ASector.LightLevel) * LIGHT_FRACUNIT,
          AArguments.Arg3 * LIGHT_FRACUNIT);
        if ASector.LightLevel <= AArguments.Arg1 then
          AState.Tics2 := 1
        else
          AState.Tics2 := -1;
      end;
    TLightKind.Flicker:
      begin
        Result := TLightScriptedOutcome.Thinker;
        AState.Value1 := AArguments.Arg1;
        AState.Value2 := AArguments.Arg2;
        ASector.LightLevel := AState.Value1;
        AState.Count := (ARandom.NextPlay and FLICKER_COUNT_MASK) + 1;
      end;
    TLightKind.Strobe:
      begin
        Result := TLightScriptedOutcome.Thinker;
        AState.Value1 := AArguments.Arg1;
        AState.Value2 := AArguments.Arg2;
        AState.Tics1 := AArguments.Arg3;
        AState.Tics2 := AArguments.Arg4;
        AState.Count := AArguments.Arg3;
        ASector.LightLevel := AState.Value1;
      end;
    TLightKind.StrobeDoom:
      begin
        Result := TLightScriptedOutcome.Thinker;
        AState.Value1 := ASector.LightLevel;
        AState.Value2 := TLightNeighbors.LowestOrOwn(ASector);
        if AState.Value2 = AState.Value1 then
          AState.Value2 := 0;
        AState.Tics1 := AArguments.Arg1;
        AState.Tics2 := AArguments.Arg2;
        AState.Count := AArguments.Arg1;
        ASector.LightLevel := AState.Value1;
      end;
    TLightKind.MaxNeighbor:
      begin
        ASector.LightLevel := TLightNeighbors.HighestOrOwn(ASector);
        ClampLevel(ASector);
      end;
    TLightKind.MinNeighbor:
      begin
        ASector.LightLevel := TLightNeighbors.LowestOrOwn(ASector);
        ClampLevel(ASector);
      end;
  else
    Result := TLightScriptedOutcome.Invalid;
  end;
end;

class function TLightScripted.Tick(AKind: TLightKind; AValue1, AValue2: Integer; var ATics1,
  ATics2, ACount: Integer; var ALightLevel: SmallInt; const ARandom: IGameRandom): Boolean;
begin
  Result := False;

  if ACount > 0 then
  begin
    ACount := ACount - 1;
    Exit;
  end;

  case AKind of
    TLightKind.Fade:
      begin
        ALightLevel := SmallInt(((ALightLevel * LIGHT_FRACUNIT) + AValue2) div LIGHT_FRACUNIT);
        if ATics2 = 1 then
        begin
          if ALightLevel >= AValue1 then
          begin
            ALightLevel := SmallInt(AValue1);
            Result := True;
          end;
        end
        else if ALightLevel <= AValue1 then
        begin
          ALightLevel := SmallInt(AValue1);
          Result := True;
        end;
      end;
    TLightKind.Glow:
      begin
        ALightLevel := SmallInt(((ALightLevel * LIGHT_FRACUNIT) + ATics1) div LIGHT_FRACUNIT);
        if ATics2 = 1 then
        begin
          if ALightLevel >= AValue1 then
          begin
            ALightLevel := SmallInt(AValue1);
            ATics1 := -ATics1;
            // reverse direction
            ATics2 := -1;
          end;
        end
        else if ALightLevel <= AValue2 then
        begin
          ALightLevel := SmallInt(AValue2);
          ATics1 := -ATics1;
          // reverse direction
          ATics2 := 1;
        end;
      end;
    TLightKind.Flicker:
      begin
        if ALightLevel = AValue1 then
        begin
          ALightLevel := SmallInt(AValue2);
          ACount := (ARandom.NextPlay and FLICKER_SHORT_MASK) + 1;
        end
        else
        begin
          ALightLevel := SmallInt(AValue1);
          ACount := (ARandom.NextPlay and FLICKER_LONG_MASK) + 1;
        end;
      end;
    TLightKind.Strobe,
    TLightKind.StrobeDoom:
      begin
        if ALightLevel = AValue1 then
        begin
          ALightLevel := SmallInt(AValue2);
          ACount := ATics2;
        end
        else
        begin
          ALightLevel := SmallInt(AValue1);
          ACount := ATics1;
        end;
      end;
  end;
end;

end.
