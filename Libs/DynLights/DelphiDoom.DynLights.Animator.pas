{******************************************************************************}
{                                                                              }
{  DelphiDoom: dynamic lights library - the animation of the lights           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.DynLights.Animator;

// the times are multiplied by FRACUNIT as 32 bit integers, and the old code let them wrap
{$OVERFLOWCHECKS OFF}
{$RANGECHECKS OFF}

interface

uses
  DelphiDoom.DynLights.Types, DelphiDoom.DynLights.Intf;

type
  /// <summary>
  ///   Gives the color, the radius and the offset of a light at a given time (the old
  ///   R_GetDynamicLight). A point light is still, a flicker light switches between its two
  ///   states by chance or by an interval, a pulse light goes smoothly from one to the other.
  ///   What was computed is kept for the next call, as the old code kept it in the light
  /// </summary>
  TDynLightAnimator = class(TInterfacedObject, IDynLightAnimator)
  private
    FRegistry: IDynLightRegistry;
    FRandom: IDynLightRandom;
    /// <summary>The time a light was computed for (-1: never)</summary>
    FValidCount: TArray<Integer>;
    FRender: TArray<TDynLightRender>;
    procedure EnsureState(AIndex: Integer);
    procedure CalcOffset(const ALight: TDynLightDefinition; var ARender: TDynLightRender;
      ARecalc: Boolean);
    procedure SetColor1(const ALight: TDynLightDefinition; var ARender: TDynLightRender);
    procedure SetColor2(const ALight: TDynLightDefinition; var ARender: TDynLightRender);
    procedure AnimatePoint(AIndex: Integer; const ALight: TDynLightDefinition;
      var ARender: TDynLightRender; ALevelTime: Integer);
    procedure AnimateFlicker(AIndex: Integer; const ALight: TDynLightDefinition;
      var ARender: TDynLightRender; ALevelTime: Integer);
    procedure AnimatePulse(AIndex: Integer; const ALight: TDynLightDefinition;
      var ARender: TDynLightRender; ALevelTime: Integer);
  public
    constructor Create(const ARegistry: IDynLightRegistry; const ARandom: IDynLightRandom);
    function GetRender(AIndex, ALevelTime: Integer): TDynLightRender;
    procedure Reset;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.DynLights.FixedMath;

const
  SNeedsCollaborators = 'TDynLightAnimator needs a registry and a random source';

{ TDynLightAnimator }

constructor TDynLightAnimator.Create(const ARegistry: IDynLightRegistry;
  const ARandom: IDynLightRandom);
begin
  inherited Create;
  if not (Assigned(ARegistry) and Assigned(ARandom)) then
    raise EArgumentNilException.Create(SNeedsCollaborators);
  FRegistry := ARegistry;
  FRandom := ARandom;
end;

procedure TDynLightAnimator.EnsureState(AIndex: Integer);
var
  LOld: Integer;
  LIndex: Integer;
begin
  LOld := Length(FValidCount);
  if AIndex < LOld then
    Exit;
  SetLength(FValidCount, AIndex + 1);
  SetLength(FRender, AIndex + 1);
  for LIndex := LOld to AIndex do
  begin
    FValidCount[LIndex] := -1;
    FRender[LIndex] := Default(TDynLightRender);
  end;
end;

procedure TDynLightAnimator.CalcOffset(const ALight: TDynLightDefinition;
  var ARender: TDynLightRender; ARecalc: Boolean);
var
  LRandom: Integer;
begin
  if ALight.RandomOffset then
  begin
    LRandom := FRandom.NextByte;
    ARender.X := (ALight.OffsetX1 * LRandom + ALight.OffsetX2 * (255 - LRandom)) / 255;
    LRandom := FRandom.NextByte;
    ARender.Y := (ALight.OffsetY1 * LRandom + ALight.OffsetY2 * (255 - LRandom)) / 255;
    LRandom := FRandom.NextByte;
    ARender.Z := (ALight.OffsetZ1 * LRandom + ALight.OffsetZ2 * (255 - LRandom)) / 255;
  end
  else if ARecalc then
  begin
    ARender.X := ALight.OffsetX1;
    ARender.Y := ALight.OffsetY1;
    ARender.Z := ALight.OffsetZ1;
  end;
end;

procedure TDynLightAnimator.SetColor1(const ALight: TDynLightDefinition;
  var ARender: TDynLightRender);
begin
  ARender.R := ALight.R1;
  ARender.G := ALight.G1;
  ARender.B := ALight.B1;
end;

procedure TDynLightAnimator.SetColor2(const ALight: TDynLightDefinition;
  var ARender: TDynLightRender);
begin
  ARender.R := ALight.R2;
  ARender.G := ALight.G2;
  ARender.B := ALight.B2;
end;

procedure TDynLightAnimator.AnimatePoint(AIndex: Integer; const ALight: TDynLightDefinition;
  var ARender: TDynLightRender; ALevelTime: Integer);
begin
  // point lights, a bit static
  if FValidCount[AIndex] < 0 then
  begin
    SetColor1(ALight, ARender);
    ARender.Radius := ALight.Size1;
    CalcOffset(ALight, ARender, True);
  end
  else if FValidCount[AIndex] <> ALevelTime then
    CalcOffset(ALight, ARender, False);
  FValidCount[AIndex] := ALevelTime;
end;

procedure TDynLightAnimator.AnimateFlicker(AIndex: Integer; const ALight: TDynLightDefinition;
  var ARender: TDynLightRender; ALevelTime: Integer);
begin
  // the chance and the interval switch the size and the color, once a second
  if FValidCount[AIndex] = ALevelTime div DYNLIGHT_TICRATE then
    Exit;

  if ALight.ColorChance > 0 then
  begin
    if FRandom.NextByte < ALight.ColorChance then
      SetColor1(ALight, ARender)
    else
      SetColor2(ALight, ARender);
  end
  else if ALight.ColorInterval > 0 then
  begin
    if Odd(TDynLightFixedMath.Divide(ALight.RandomSeed + ALevelTime * DYNLIGHT_FRACUNIT,
      ALight.ColorInterval)) then
      SetColor1(ALight, ARender)
    else
      SetColor2(ALight, ARender);
  end
  else
    SetColor1(ALight, ARender);

  if ALight.Chance > 0 then
  begin
    if FRandom.NextByte < ALight.Chance then
      ARender.Radius := ALight.Size1
    else
      ARender.Radius := ALight.Size2;
  end
  else if ALight.Interval > 0 then
  begin
    if Odd(TDynLightFixedMath.Divide(ALight.RandomSeed + ALevelTime * DYNLIGHT_FRACUNIT,
      ALight.Interval)) then
      ARender.Radius := ALight.Size1
    else
      ARender.Radius := ALight.Size2;
  end
  else
    ARender.Radius := ALight.Size1;

  CalcOffset(ALight, ARender, FValidCount[AIndex] < 0);
  FValidCount[AIndex] := ALevelTime div DYNLIGHT_TICRATE;
end;

procedure TDynLightAnimator.AnimatePulse(AIndex: Integer; const ALight: TDynLightDefinition;
  var ARender: TDynLightRender; ALevelTime: Integer);
var
  LFrac: Integer;
  LFrac1: Single;
  LFrac2: Single;
begin
  // the time moves smoothly from one size and color to the other
  if FValidCount[AIndex] = ALevelTime then
    Exit;

  if ALight.ColorInterval > 0 then
  begin
    LFrac := TDynLightFixedMath.Divide(ALight.RandomSeed + ALevelTime * DYNLIGHT_FRACUNIT,
      ALight.ColorInterval) mod ALight.ColorInterval;
    LFrac1 := LFrac / ALight.ColorInterval;
    LFrac2 := 1.0 - LFrac1;
    ARender.R := ALight.R1 * LFrac1 + ALight.R2 * LFrac2;
    ARender.G := ALight.G1 * LFrac1 + ALight.G2 * LFrac2;
    ARender.B := ALight.B1 * LFrac1 + ALight.B2 * LFrac2;
  end
  // a color chance should not be in a pulse light, but just in case
  else if ALight.ColorChance > 0 then
  begin
    if FRandom.NextByte < ALight.ColorChance then
      SetColor1(ALight, ARender)
    else
      SetColor2(ALight, ARender);
  end
  else
    SetColor1(ALight, ARender);

  if ALight.Interval > 0 then
  begin
    LFrac := TDynLightFixedMath.Divide(ALight.RandomSeed + ALevelTime * DYNLIGHT_FRACUNIT,
      ALight.Interval) mod ALight.Interval;
    LFrac1 := LFrac / ALight.Interval;
    LFrac2 := 1.0 - LFrac1;
    ARender.Radius := ALight.Size1 * LFrac1 + ALight.Size2 * LFrac2;
  end
  // a chance should not be in a pulse light either
  else if ALight.Chance > 0 then
  begin
    if FRandom.NextByte < ALight.Chance then
      ARender.Radius := ALight.Size1
    else
      ARender.Radius := ALight.Size2;
  end
  else
    ARender.Radius := ALight.Size1;

  CalcOffset(ALight, ARender, FValidCount[AIndex] < 0);
  FValidCount[AIndex] := ALevelTime;
end;

procedure TDynLightAnimator.Reset;
begin
  FValidCount := nil;
  FRender := nil;
end;

function TDynLightAnimator.GetRender(AIndex, ALevelTime: Integer): TDynLightRender;
var
  LLight: TDynLightDefinition;
  LRender: TDynLightRender;
begin
  EnsureState(AIndex);
  LLight := FRegistry.Get(AIndex);
  LRender := FRender[AIndex];
  LRender.Shadow := False;
  case LLight.Kind of
    TDynLightKind.Point:
      AnimatePoint(AIndex, LLight, LRender, ALevelTime);
    TDynLightKind.Flicker:
      AnimateFlicker(AIndex, LLight, LRender, ALevelTime);
    TDynLightKind.Pulse:
      AnimatePulse(AIndex, LLight, LRender, ALevelTime);
  end;
  FRender[AIndex] := LRender;
  Result := LRender;
end;

end.
