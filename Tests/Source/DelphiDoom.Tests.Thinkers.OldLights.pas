{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the thinkers library - the lights as the old code      }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Thinkers.OldLights;

// The statements of the procedures are the ones of p_lights.pas and udmf_lights.pas before the
// library, with the sector replaced by a fake one and P_Random by an IGameRandom: the tests
// run the old and the new code side by side on the same series of random numbers
{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Intf, DelphiDoom.Tests.Thinkers.Fakes;

type
  TOldFireFlicker = record
    Sector: TFakeLightSector;
    Count: Integer;
    MaxLight: Integer;
    MinLight: Integer;
  end;

  TOldLightFlash = record
    Sector: TFakeLightSector;
    Count: Integer;
    MaxLight: Integer;
    MinLight: Integer;
    MaxTime: Integer;
    MinTime: Integer;
  end;

  TOldStrobe = record
    Sector: TFakeLightSector;
    Count: Integer;
    MinLight: Integer;
    MaxLight: Integer;
    DarkTime: Integer;
    BrightTime: Integer;
  end;

  TOldGlow = record
    Sector: TFakeLightSector;
    MinLight: Integer;
    MaxLight: Integer;
    Direction: Integer;
  end;

  TOldScripted = record
    Sector: TFakeLightSector;
    Kind: Integer;
    Value1: Integer;
    Value2: Integer;
    Tics1: Integer;
    Tics2: Integer;
    Count: Integer;
    Removed: Boolean;
  end;

  TOldPhase = record
    Sector: TFakeLightSector;
    Index: Integer;
    Base: Integer;
  end;

function OldMinSurroundingLight(ASector: TFakeLightSector; AMax: Integer): Integer;
function OldLowestLightSurrounding(ASector: TFakeLightSector): Integer;
function OldHighestLightSurrounding(ASector: TFakeLightSector): Integer;

procedure OldSpawnFireFlicker(var AFlick: TOldFireFlicker; ASector: TFakeLightSector; AStrife: Boolean);
procedure OldTickFireFlicker(var AFlick: TOldFireFlicker; const ARandom: IGameRandom; AStrife: Boolean);
procedure OldSpawnLightFlash(var AFlash: TOldLightFlash; ASector: TFakeLightSector; const ARandom: IGameRandom);
procedure OldTickLightFlash(var AFlash: TOldLightFlash; const ARandom: IGameRandom);
procedure OldSpawnStrobe(var AFlash: TOldStrobe; ASector: TFakeLightSector; AFastOrSlow, AInSync: Integer;
  const ARandom: IGameRandom);
procedure OldTickStrobe(var AFlash: TOldStrobe);
procedure OldSpawnGlow(var AGlow: TOldGlow; ASector: TFakeLightSector);
procedure OldTickGlow(var AGlow: TOldGlow);

/// <summary>The kind is the position in lighttype_t; gives the thinker flag and the result</summary>
function OldSpawnScripted(var ALight: TOldScripted; ASector: TFakeLightSector; AKind, AArg1, AArg2,
  AArg3, AArg4: Integer; const ARandom: IGameRandom; out AThink: Boolean): Boolean;
procedure OldTickScripted(var ALight: TOldScripted; const ARandom: IGameRandom);

procedure OldSpawnPhase(var APhase: TOldPhase; ASector: TFakeLightSector; ABase, AIndex, AMask: Integer);
procedure OldTickPhase(var APhase: TOldPhase);

implementation

uses
  DelphiDoom.MathCore.FixedMath, DelphiDoom.Thinkers.Light.Intf;

const
  FRACUNIT = 65536;

  PhaseTable: array[0..63] of Integer = (
    128, 112,  96,  80,  64,  48,  32,  32,
     16,  16,  16,   0,   0,   0,   0,   0,
      0,   0,   0,   0,   0,   0,   0,   0,
      0,   0,   0,   0,   0,   0,   0,   0,
      0,   0,   0,   0,   0,   0,   0,   0,
      0,   0,   0,   0,   0,   0,   0,   0,
      0,   0,   0,   0,   0,  16,  16,  16,
     32,  32,  48,  64,  80,  96, 112, 128
  );

function OldMinSurroundingLight(ASector: TFakeLightSector; AMax: Integer): Integer;
var
  I: Integer;
  Check: ILightSector;
begin
  Result := AMax;
  for I := 0 to ASector.GetNeighborCount - 1 do
  begin
    Check := ASector.GetNeighbor(I);
    if Check <> nil then
      if Check.GetLightLevel < Result then
        Result := Check.GetLightLevel;
  end;
end;

function OldLowestLightSurrounding(ASector: TFakeLightSector): Integer;
const
  MAXLIGHT = $FFFF;
begin
  Result := OldMinSurroundingLight(ASector, MAXLIGHT);
  if Result = MAXLIGHT then
    Result := ASector.Level;
end;

function OldHighestLightSurrounding(ASector: TFakeLightSector): Integer;
const
  MINLIGHT = -1;
var
  I: Integer;
  Other: ILightSector;
begin
  Result := MINLIGHT;
  for I := 0 to ASector.GetNeighborCount - 1 do
  begin
    Other := ASector.GetNeighbor(I);
    if Other <> nil then
      if Other.GetLightLevel < Result then
        Result := Other.GetLightLevel;
  end;
  if Result = MINLIGHT then
    Result := ASector.Level;
end;

procedure OldSpawnFireFlicker(var AFlick: TOldFireFlicker; ASector: TFakeLightSector; AStrife: Boolean);
begin
  AFlick.Sector := ASector;
  AFlick.MaxLight := ASector.Level;
  if AStrife then
  begin
    AFlick.MinLight := ASector.Level - 32;
    if AFlick.MinLight < 0 then
      AFlick.MinLight := 0;
    AFlick.Count := 2;
  end
  else
  begin
    AFlick.MinLight := OldMinSurroundingLight(ASector, ASector.Level) + 16;
    AFlick.Count := 4;
  end;
end;

procedure OldTickFireFlicker(var AFlick: TOldFireFlicker; const ARandom: IGameRandom; AStrife: Boolean);
var
  Amount: Integer;
begin
  AFlick.Count := AFlick.Count - 1;
  if AFlick.Count > 0 then
    Exit;

  if AStrife then
    Amount := (ARandom.NextPlay and 3) * 8
  else
    Amount := (ARandom.NextPlay and 3) * 16;

  if AFlick.Sector.Level - Amount < AFlick.MinLight then
    AFlick.Sector.Level := SmallInt(AFlick.MinLight)
  else
    AFlick.Sector.Level := SmallInt(AFlick.MaxLight - Amount);

  if AStrife then
    AFlick.Count := (ARandom.NextPlay and 3) + 1
  else
    AFlick.Count := 4;
end;

procedure OldSpawnLightFlash(var AFlash: TOldLightFlash; ASector: TFakeLightSector; const ARandom: IGameRandom);
begin
  AFlash.Sector := ASector;
  AFlash.MaxLight := ASector.Level;
  AFlash.MinLight := OldMinSurroundingLight(ASector, ASector.Level);
  AFlash.MaxTime := 64;
  AFlash.MinTime := 7;
  AFlash.Count := (ARandom.NextPlay and AFlash.MaxTime) + 1;
end;

procedure OldTickLightFlash(var AFlash: TOldLightFlash; const ARandom: IGameRandom);
begin
  AFlash.Count := AFlash.Count - 1;
  if AFlash.Count > 0 then
    Exit;

  if AFlash.Sector.Level = AFlash.MaxLight then
  begin
    AFlash.Sector.Level := SmallInt(AFlash.MinLight);
    AFlash.Count := (ARandom.NextPlay and AFlash.MinTime) + 1;
  end
  else
  begin
    AFlash.Sector.Level := SmallInt(AFlash.MaxLight);
    AFlash.Count := (ARandom.NextPlay and AFlash.MaxTime) + 1;
  end;
end;

procedure OldSpawnStrobe(var AFlash: TOldStrobe; ASector: TFakeLightSector; AFastOrSlow, AInSync: Integer;
  const ARandom: IGameRandom);
begin
  AFlash.Sector := ASector;
  AFlash.DarkTime := AFastOrSlow;
  AFlash.BrightTime := 5;
  AFlash.MaxLight := ASector.Level;
  AFlash.MinLight := OldMinSurroundingLight(ASector, ASector.Level);

  if AFlash.MinLight = AFlash.MaxLight then
    AFlash.MinLight := 0;

  if AInSync = 0 then
    AFlash.Count := (ARandom.NextPlay and 7) + 1
  else
    AFlash.Count := 1;
end;

procedure OldTickStrobe(var AFlash: TOldStrobe);
begin
  AFlash.Count := AFlash.Count - 1;
  if AFlash.Count > 0 then
    Exit;

  if AFlash.Sector.Level = AFlash.MinLight then
  begin
    AFlash.Sector.Level := SmallInt(AFlash.MaxLight);
    AFlash.Count := AFlash.BrightTime;
  end
  else
  begin
    AFlash.Sector.Level := SmallInt(AFlash.MinLight);
    AFlash.Count := AFlash.DarkTime;
  end;
end;

procedure OldSpawnGlow(var AGlow: TOldGlow; ASector: TFakeLightSector);
begin
  AGlow.Sector := ASector;
  AGlow.MinLight := OldMinSurroundingLight(ASector, ASector.Level);
  AGlow.MaxLight := ASector.Level;
  AGlow.Direction := -1;
end;

procedure OldTickGlow(var AGlow: TOldGlow);
begin
  case AGlow.Direction of
    -1:
      begin
        AGlow.Sector.Level := SmallInt(AGlow.Sector.Level - 8);
        if AGlow.Sector.Level <= AGlow.MinLight then
        begin
          AGlow.Sector.Level := SmallInt(AGlow.Sector.Level + 8);
          AGlow.Direction := 1;
        end;
      end;
    1:
      begin
        AGlow.Sector.Level := SmallInt(AGlow.Sector.Level + 8);
        if AGlow.Sector.Level >= AGlow.MaxLight then
        begin
          AGlow.Sector.Level := SmallInt(AGlow.Sector.Level - 8);
          AGlow.Direction := -1;
        end;
      end;
  end;
end;

function OldSpawnScripted(var ALight: TOldScripted; ASector: TFakeLightSector; AKind, AArg1, AArg2,
  AArg3, AArg4: Integer; const ARandom: IGameRandom; out AThink: Boolean): Boolean;
begin
  AThink := False;
  ALight.Sector := ASector;
  ALight.Kind := AKind;
  ALight.Count := 0;
  ALight.Removed := False;
  Result := True;
  case AKind of
    0:
      begin
        ASector.Level := SmallInt(ASector.Level + AArg1);
        if ASector.Level > 255 then
          ASector.Level := 255;
      end;
    1:
      begin
        ASector.Level := SmallInt(ASector.Level - AArg1);
        if ASector.Level < 0 then
          ASector.Level := 0;
      end;
    2:
      begin
        ASector.Level := SmallInt(AArg1);
        if ASector.Level < 0 then
          ASector.Level := 0
        else if ASector.Level > 255 then
          ASector.Level := 255;
      end;
    3:
      begin
        AThink := True;
        ALight.Value1 := AArg1;
        ALight.Value2 := TFixedMath.Divide((AArg1 - ASector.Level) * FRACUNIT, AArg2 * FRACUNIT);
        if ASector.Level <= AArg1 then
          ALight.Tics2 := 1
        else
          ALight.Tics2 := -1;
      end;
    4:
      begin
        AThink := True;
        ALight.Value1 := AArg1;
        ALight.Value2 := AArg2;
        ALight.Tics1 := TFixedMath.Divide((AArg1 - ASector.Level) * FRACUNIT, AArg3 * FRACUNIT);
        if ASector.Level <= AArg1 then
          ALight.Tics2 := 1
        else
          ALight.Tics2 := -1;
      end;
    5:
      begin
        AThink := True;
        ALight.Value1 := AArg1;
        ALight.Value2 := AArg2;
        ASector.Level := SmallInt(ALight.Value1);
        ALight.Count := (ARandom.NextPlay and 64) + 1;
      end;
    6:
      begin
        AThink := True;
        ALight.Value1 := AArg1;
        ALight.Value2 := AArg2;
        ALight.Tics1 := AArg3;
        ALight.Tics2 := AArg4;
        ALight.Count := AArg3;
        ASector.Level := SmallInt(ALight.Value1);
      end;
    9:
      begin
        AThink := True;
        ALight.Value1 := ASector.Level;
        ALight.Value2 := OldLowestLightSurrounding(ASector);
        if ALight.Value2 = ALight.Value1 then
          ALight.Value2 := 0;
        ALight.Tics1 := AArg1;
        ALight.Tics2 := AArg2;
        ALight.Count := AArg1;
        ASector.Level := SmallInt(ALight.Value1);
      end;
    7:
      begin
        ASector.Level := SmallInt(OldHighestLightSurrounding(ASector));
        if ASector.Level < 0 then
          ASector.Level := 0
        else if ASector.Level > 255 then
          ASector.Level := 255;
      end;
    8:
      begin
        ASector.Level := SmallInt(OldLowestLightSurrounding(ASector));
        if ASector.Level < 0 then
          ASector.Level := 0
        else if ASector.Level > 255 then
          ASector.Level := 255;
      end;
  else
    Result := False;
  end;
end;

procedure OldTickScripted(var ALight: TOldScripted; const ARandom: IGameRandom);
begin
  if ALight.Count > 0 then
  begin
    Dec(ALight.Count);
    Exit;
  end;

  case ALight.Kind of
    3:
      begin
        ALight.Sector.Level := SmallInt(((ALight.Sector.Level * FRACUNIT) + ALight.Value2) div FRACUNIT);
        if ALight.Tics2 = 1 then
        begin
          if ALight.Sector.Level >= ALight.Value1 then
          begin
            ALight.Sector.Level := SmallInt(ALight.Value1);
            ALight.Removed := True;
          end;
        end
        else if ALight.Sector.Level <= ALight.Value1 then
        begin
          ALight.Sector.Level := SmallInt(ALight.Value1);
          ALight.Removed := True;
        end;
      end;
    4:
      begin
        ALight.Sector.Level := SmallInt(((ALight.Sector.Level * FRACUNIT) + ALight.Tics1) div FRACUNIT);
        if ALight.Tics2 = 1 then
        begin
          if ALight.Sector.Level >= ALight.Value1 then
          begin
            ALight.Sector.Level := SmallInt(ALight.Value1);
            ALight.Tics1 := -ALight.Tics1;
            ALight.Tics2 := -1;
          end;
        end
        else if ALight.Sector.Level <= ALight.Value2 then
        begin
          ALight.Sector.Level := SmallInt(ALight.Value2);
          ALight.Tics1 := -ALight.Tics1;
          ALight.Tics2 := 1;
        end;
      end;
    5:
      begin
        if ALight.Sector.Level = ALight.Value1 then
        begin
          ALight.Sector.Level := SmallInt(ALight.Value2);
          ALight.Count := (ARandom.NextPlay and 7) + 1;
        end
        else
        begin
          ALight.Sector.Level := SmallInt(ALight.Value1);
          ALight.Count := (ARandom.NextPlay and 31) + 1;
        end;
      end;
    6, 9:
      begin
        if ALight.Sector.Level = ALight.Value1 then
        begin
          ALight.Sector.Level := SmallInt(ALight.Value2);
          ALight.Count := ALight.Tics2;
        end
        else
        begin
          ALight.Sector.Level := SmallInt(ALight.Value1);
          ALight.Count := ALight.Tics1;
        end;
      end;
  end;
end;

procedure OldSpawnPhase(var APhase: TOldPhase; ASector: TFakeLightSector; ABase, AIndex, AMask: Integer);
begin
  APhase.Sector := ASector;
  if AIndex = -1 then
    APhase.Index := ASector.Level and 63
  else
    APhase.Index := AIndex and 63;
  APhase.Base := ABase and 255;
  ASector.Level := SmallInt(APhase.Base + PhaseTable[APhase.Index]);
  ASector.SetSpecial(ASector.GetSpecial and not AMask);
end;

procedure OldTickPhase(var APhase: TOldPhase);
begin
  APhase.Index := (APhase.Index + 1) and 63;
  APhase.Sector.Level := SmallInt(APhase.Base + PhaseTable[APhase.Index]);
end;

end.
