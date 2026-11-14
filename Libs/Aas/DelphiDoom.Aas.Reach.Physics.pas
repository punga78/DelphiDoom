{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - jump and fall limits of the player                }
{                                                                              }
{  Port of AAS_FallDamageDistance, AAS_FallDelta, AAS_MaxJumpHeight,           }
{  AAS_MaxJumpDistance and AAS_BarrierJumpTravelTime of be_aas_reach.c. Based  }
{  on the Quake III Arena GPL Source Code (id Software). Copyright (C)         }
{  1999-2005 Id Software, Inc. This unit is derived from the Quake III Arena   }
{  source code and is therefore available under the GNU General Public         }
{  License, version 2 or (at your option) any later version.                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Reach.Physics;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Aas.Move.Types, DelphiDoom.Aas.Reach.Intf;

type
  /// <summary>The limits of what a player can do, from the physics settings</summary>
  TAasReachPhysics = class(TInterfacedObject, IAasReachPhysics)
  strict private
    FSettings: TAasMoveSettings;
  public
    constructor Create(const ASettings: TAasMoveSettings);
    function FallDamageDistance: Integer;
    function FallDelta(const ADistance: Single): Single;
    function MaxJumpHeight(const APhysJumpVel: Single): Single;
    function MaxJumpDistance(const APhysJumpVel: Single): Single;
    function BarrierJumpTravelTime: Word;
  end;

implementation

uses
  System.SysUtils;

const
  // the literals of the C code are doubles
  CHalf: Double = 0.5;
  CTenth: Double = 0.1;
  CTenThousandth: Double = 0.0001;

{ TAasReachPhysics }

constructor TAasReachPhysics.Create(const ASettings: TAasMoveSettings);
begin
  inherited Create;
  FSettings := ASettings;
end;

function TAasReachPhysics.FallDamageDistance: Integer;
var
  LMaxZVelocity, LGravity, LTime: Single;
  LRoot, LHalfGravity, LStep: Double;
begin
  LRoot := Sqrt(Double(300000));
  LMaxZVelocity := LRoot;
  LGravity := FSettings.PhysGravity;
  LTime := LMaxZVelocity / LGravity;
  // return 0.5 * gravity * t * t: the whole product is a double, then an int
  LHalfGravity := CHalf * LGravity;
  LStep := LHalfGravity * LTime;
  LStep := LStep * LTime;
  Result := Trunc(LStep);
end;

function TAasReachPhysics.FallDelta(const ADistance: Single): Single;
var
  LTime, LDelta, LSquare, LGravity: Single;
  LQuotient, LResult: Double;
begin
  LGravity := FSettings.PhysGravity;
  // t = sqrt(fabs(distance) * 2 / gravity): fabs and the sqrt are doubles
  LQuotient := Abs(Double(ADistance));
  LQuotient := LQuotient * 2;
  LQuotient := LQuotient / LGravity;
  LTime := Sqrt(LQuotient);
  LDelta := LTime * LGravity;
  LSquare := LDelta * LDelta;
  LResult := Double(LSquare) * CTenThousandth;
  Result := LResult;
end;

function TAasReachPhysics.MaxJumpHeight(const APhysJumpVel: Single): Single;
var
  LGravity, LQuotient: Single;
  LResult: Double;
begin
  LGravity := FSettings.PhysGravity;
  // 0.5 * g * (v / g) * (v / g): from the left, a double times a float
  LQuotient := APhysJumpVel / LGravity;
  LResult := CHalf * LGravity;
  LResult := LResult * LQuotient;
  LResult := LResult * LQuotient;
  Result := LResult;
end;

function TAasReachPhysics.MaxJumpDistance(const APhysJumpVel: Single): Single;
var
  LGravity, LMaxVelocity, LTime, LJumpTime, LSum: Single;
  LHalfGravity, LQuotient: Double;
begin
  LGravity := FSettings.PhysGravity;
  LMaxVelocity := FSettings.PhysMaxVelocity;
  // time a player takes to fall the height
  LHalfGravity := CHalf * LGravity;
  LQuotient := FSettings.RsMaxJumpFallHeight / LHalfGravity;
  LTime := Sqrt(LQuotient);
  LJumpTime := APhysJumpVel / LGravity;
  LSum := LTime + LJumpTime;
  Result := LMaxVelocity * LSum;
end;

function TAasReachPhysics.BarrierJumpTravelTime: Word;
var
  LDivisor, LTravelTime: Double;
begin
  LDivisor := FSettings.PhysGravity * CTenth;
  LTravelTime := FSettings.PhysJumpVel / LDivisor;
  Result := Word(Trunc(LTravelTime) and $FFFF);
end;

end.
