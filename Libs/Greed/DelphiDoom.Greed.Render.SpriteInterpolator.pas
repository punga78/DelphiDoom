{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the smooth movement of the sprites              }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): r_interpolate.pas           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Render.SpriteInterpolator;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Greed.Actor.Types, DelphiDoom.Greed.LinkedPool, DelphiDoom.Greed.World.Intf,
  DelphiDoom.Greed.Render.Types;

type
  /// <summary>
  ///   The sprites move 8 tics at a time but are drawn at each picture: between two moves they are put where they
  ///   would be (from their old and new position, angle and height), and after the picture they go back to the new
  ///   values. The monsters keep their position (the game moves them on its own). Nothing is drawn here
  /// </summary>
  TGreedSpriteInterpolator = class
  strict private
    FSprites: TGreedLinkedPool<TGreedSprite>;
    FClock: IGreedRenderClock;
    FEnabled: Boolean;
    class function CalcInt(APrev, ANext, AFrac: Integer): Integer; static;
    class function CalcAngle(APrev, ANext, AFrac: Integer): Integer; static;
    class function IsMonster(AKind: Integer): Boolean; static;
  public
    constructor Create(ASprites: TGreedLinkedPool<TGreedSprite>; const AClock: IGreedRenderClock);
    /// <summary>InterpolateSprites</summary>
    procedure Interpolate(const AWorld: IGreedWorld);
    /// <summary>RestoreInterpolateSprites: the sprites go back to their new values</summary>
    procedure Restore;
    /// <summary>interpolate: the original has it on</summary>
    property Enabled: Boolean read FEnabled write FEnabled;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Terrain;

{ TGreedSpriteInterpolator }

constructor TGreedSpriteInterpolator.Create(ASprites: TGreedLinkedPool<TGreedSprite>;
  const AClock: IGreedRenderClock);
begin
  inherited Create;
  if not Assigned(ASprites) then
    raise EArgumentNilException.Create('ASprites');
  if not Assigned(AClock) then
    raise EArgumentNilException.Create('AClock');
  FSprites := ASprites;
  FClock := AClock;
  FEnabled := True;
end;

class function TGreedSpriteInterpolator.IsMonster(AKind: Integer): Boolean;
begin
  // S_MONSTER13..15 and their _NS, S_MONSTER1..4, 6..12 and 5 with the _NS of each (protos_h.pas)
  Result := ((AKind >= 34) and (AKind <= 39)) or ((AKind >= 75) and (AKind <= 82)) or
    ((AKind >= 84) and (AKind <= 99));
end;

class function TGreedSpriteInterpolator.CalcInt(APrev, ANext, AFrac: Integer): Integer;
begin
  if ANext = APrev then
    Result := APrev
  else
    Result := APrev + Round((ANext - APrev) / GREED_FRACUNIT * AFrac);
end;

class function TGreedSpriteInterpolator.CalcAngle(APrev, ANext, AFrac: Integer): Integer;
var
  LPrevE, LNextE, LMidE: Extended;
begin
  if APrev = ANext then
    Result := APrev
  else
  begin
    if ((APrev < 256) and (ANext > 768)) or ((ANext < 256) and (APrev > 768)) then
    begin
      LPrevE := APrev / (GREED_ANGLES + 1);
      LNextE := ANext / (GREED_ANGLES + 1);
      if APrev > ANext then
        LNextE := LNextE + 1.0
      else
        LPrevE := LPrevE + 1.0;
      LMidE := LPrevE + (LNextE - LPrevE) / GREED_FRACUNIT * AFrac;
      if LMidE > 1.0 then
        LMidE := LMidE - 1.0;
      Result := Round(LMidE * (GREED_ANGLES + 1)) and GREED_ANGLES;
    end
    else if APrev > ANext then
      Result := (APrev - Round((APrev - ANext) / GREED_FRACUNIT * AFrac)) and GREED_ANGLES
    else
      Result := (APrev + Round((ANext - APrev) / GREED_FRACUNIT * AFrac)) and GREED_ANGLES;
  end;
end;

procedure TGreedSpriteInterpolator.Interpolate(const AWorld: IGreedWorld);
var
  LIndex, LFrac: Integer;
  LSprite: PGreedSprite;
begin
  if not FEnabled then
    Exit;
  LFrac := GREED_FRACUNIT - (FClock.GetSpriteMoveTime - FClock.GetTimeCount) * (GREED_FRACUNIT div 8);
  if LFrac <= 0 then
    LFrac := 0;
  if LFrac >= GREED_FRACUNIT then
    Exit;
  LIndex := FSprites.First;
  while LIndex <> GREED_POOL_NIL do
  begin
    LSprite := PGreedSprite(FSprites.Item(LIndex));
    if not IsMonster(LSprite^.Kind) then
    begin
      LSprite^.X := CalcInt(LSprite^.OldX, LSprite^.NewX, LFrac);
      LSprite^.Y := CalcInt(LSprite^.OldY, LSprite^.NewY, LFrac);
    end;

    if (LSprite^.Kind = GREED_S_BLOOD_SPLAT) and LSprite^.Grounded then
      LSprite^.Z := TGreedTerrain.FloorZ(AWorld, LSprite^.X, LSprite^.Y)
    else if (LSprite^.OldFloorZ >= LSprite^.OldZ) and (LSprite^.NewFloorZ >= LSprite^.NewZ) then
      LSprite^.Z := TGreedTerrain.FloorZ(AWorld, LSprite^.X, LSprite^.Y)
    else
      LSprite^.Z := CalcInt(LSprite^.OldZ, LSprite^.NewZ, LFrac);
    LSprite^.Angle := CalcAngle(LSprite^.OldAngle, LSprite^.NewAngle, LFrac);

    LIndex := FSprites.Next(LIndex);
  end;
end;

procedure TGreedSpriteInterpolator.Restore;
var
  LIndex: Integer;
  LSprite: PGreedSprite;
begin
  LIndex := FSprites.First;
  while LIndex <> GREED_POOL_NIL do
  begin
    LSprite := PGreedSprite(FSprites.Item(LIndex));
    if not IsMonster(LSprite^.Kind) then
    begin
      LSprite^.X := LSprite^.NewX;
      LSprite^.Y := LSprite^.NewY;
    end;
    LSprite^.Z := LSprite^.NewZ;
    LSprite^.Angle := LSprite^.NewAngle;
    LIndex := FSprites.Next(LIndex);
  end;
end;

end.
