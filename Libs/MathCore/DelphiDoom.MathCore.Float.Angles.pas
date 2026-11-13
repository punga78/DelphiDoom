{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdAngles, the Euler angles         }
{                                                                              }
{  Port of idAngles (idlib\math\Angles.h and Angles.cpp) of the Doom 3 GPL     }
{  Source Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media       }
{  company. Based on the Doom 3 GPL Source Code (id Software).                 }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.Angles;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.IdLib.Math.Vec3;

type
  /// <summary>
  ///   Euler angles in degrees (idAngles): pitch (up and down), yaw (left and right) and roll
  ///   (fall over), three Single, 12 bytes. The conversions to matrix, quaternion and rotation
  ///   are in <c>TIdRotationConversions</c> (the types refer to each other, which units cannot).
  /// </summary>
  TIdAngles = record
    Pitch: Single;
    Yaw: Single;
    Roll: Single;
  private
    function GetItem(const AIndex: Integer): Single;
    procedure SetItem(const AIndex: Integer; const AValue: Single);
  public
    class function Create(const APitch, AYaw, ARoll: Single): TIdAngles; static;
    /// <summary>idAngles( const idVec3 &amp; ): the three components of the vector</summary>
    class function FromVec3(const AVector: TIdVec3): TIdAngles; static;
    procedure SetValues(const APitch, AYaw, ARoll: Single);
    procedure Zero;
    /// <summary>Component 0 (pitch), 1 (yaw) or 2 (roll)</summary>
    property Items[const AIndex: Integer]: Single read GetItem write SetItem; default;
    /// <summary>Negates the angles; in general this is not the inverse rotation</summary>
    class operator Negative(const A: TIdAngles): TIdAngles;
    class operator Add(const A, B: TIdAngles): TIdAngles;
    class operator Subtract(const A, B: TIdAngles): TIdAngles;
    class operator Multiply(const A: TIdAngles; const B: Single): TIdAngles;
    class operator Multiply(const A: Single; const B: TIdAngles): TIdAngles;
    /// <summary>Multiplies by the reciprocal, as the original (not a division per component)</summary>
    class operator Divide(const A: TIdAngles; const B: Single): TIdAngles;
    class operator Equal(const A, B: TIdAngles): Boolean;
    class operator NotEqual(const A, B: TIdAngles): Boolean;
    function Compare(const A: TIdAngles; const AEpsilon: Single): Boolean;
    /// <summary>Normalises to [0, 360)</summary>
    procedure Normalize360;
    /// <summary>Normalises to (-180, 180]</summary>
    procedure Normalize180;
    procedure Clamp(const AMin, AMax: TIdAngles);
    function GetDimension: Integer;
    /// <summary>The forward, right and up vectors (idAngles::ToVectors)</summary>
    procedure ToVectors(out AForward, ARight, AUp: TIdVec3);
    function ToForward: TIdVec3;
    function ToString(const APrecision: Integer = 2): AnsiString;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Math, DelphiDoom.IdLib.Text.Strings;

{ TIdAngles }

class function TIdAngles.Create(const APitch, AYaw, ARoll: Single): TIdAngles;
begin
  Result.Pitch := APitch;
  Result.Yaw := AYaw;
  Result.Roll := ARoll;
end;

class function TIdAngles.FromVec3(const AVector: TIdVec3): TIdAngles;
begin
  Result.Pitch := AVector.X;
  Result.Yaw := AVector.Y;
  Result.Roll := AVector.Z;
end;

procedure TIdAngles.SetValues(const APitch, AYaw, ARoll: Single);
begin
  Pitch := APitch;
  Yaw := AYaw;
  Roll := ARoll;
end;

procedure TIdAngles.Zero;
begin
  Pitch := 0.0;
  Yaw := 0.0;
  Roll := 0.0;
end;

function TIdAngles.GetItem(const AIndex: Integer): Single;
begin
  Result := PSingle(PByte(@Pitch) + AIndex * SizeOf(Single))^;
end;

procedure TIdAngles.SetItem(const AIndex: Integer; const AValue: Single);
begin
  PSingle(PByte(@Pitch) + AIndex * SizeOf(Single))^ := AValue;
end;

class operator TIdAngles.Negative(const A: TIdAngles): TIdAngles;
begin
  Result.Pitch := -A.Pitch;
  Result.Yaw := -A.Yaw;
  Result.Roll := -A.Roll;
end;

class operator TIdAngles.Add(const A, B: TIdAngles): TIdAngles;
begin
  Result.Pitch := A.Pitch + B.Pitch;
  Result.Yaw := A.Yaw + B.Yaw;
  Result.Roll := A.Roll + B.Roll;
end;

class operator TIdAngles.Subtract(const A, B: TIdAngles): TIdAngles;
begin
  Result.Pitch := A.Pitch - B.Pitch;
  Result.Yaw := A.Yaw - B.Yaw;
  Result.Roll := A.Roll - B.Roll;
end;

class operator TIdAngles.Multiply(const A: TIdAngles; const B: Single): TIdAngles;
begin
  Result.Pitch := A.Pitch * B;
  Result.Yaw := A.Yaw * B;
  Result.Roll := A.Roll * B;
end;

class operator TIdAngles.Multiply(const A: Single; const B: TIdAngles): TIdAngles;
begin
  Result.Pitch := A * B.Pitch;
  Result.Yaw := A * B.Yaw;
  Result.Roll := A * B.Roll;
end;

class operator TIdAngles.Divide(const A: TIdAngles; const B: Single): TIdAngles;
var
  LInverse: Single;
begin
  LInverse := 1.0 / B;
  Result.Pitch := A.Pitch * LInverse;
  Result.Yaw := A.Yaw * LInverse;
  Result.Roll := A.Roll * LInverse;
end;

class operator TIdAngles.Equal(const A, B: TIdAngles): Boolean;
begin
  Result := (A.Pitch = B.Pitch) and (A.Yaw = B.Yaw) and (A.Roll = B.Roll);
end;

class operator TIdAngles.NotEqual(const A, B: TIdAngles): Boolean;
begin
  Result := not (A = B);
end;

function TIdAngles.Compare(const A: TIdAngles; const AEpsilon: Single): Boolean;
begin
  Result := False;
  if TIdMath.Fabs(Pitch - A.Pitch) > AEpsilon then
    Exit;
  if TIdMath.Fabs(Yaw - A.Yaw) > AEpsilon then
    Exit;
  if TIdMath.Fabs(Roll - A.Roll) > AEpsilon then
    Exit;
  Result := True;
end;

procedure TIdAngles.Normalize360;
var
  LIndex: Integer;
  LValue: Single;
begin
  for LIndex := 0 to 2 do
  begin
    LValue := Items[LIndex];
    if (LValue >= 360.0) or (LValue < 0.0) then
    begin
      LValue := LValue - TIdMath.Floor(LValue / 360.0) * 360.0;
      if LValue >= 360.0 then
        LValue := LValue - 360.0;
      if LValue < 0.0 then
        LValue := LValue + 360.0;
      Items[LIndex] := LValue;
    end;
  end;
end;

procedure TIdAngles.Normalize180;
begin
  Normalize360;
  if Pitch > 180.0 then
    Pitch := Pitch - 360.0;
  if Yaw > 180.0 then
    Yaw := Yaw - 360.0;
  if Roll > 180.0 then
    Roll := Roll - 360.0;
end;

procedure TIdAngles.Clamp(const AMin, AMax: TIdAngles);
begin
  if Pitch < AMin.Pitch then
    Pitch := AMin.Pitch
  else if Pitch > AMax.Pitch then
    Pitch := AMax.Pitch;
  if Yaw < AMin.Yaw then
    Yaw := AMin.Yaw
  else if Yaw > AMax.Yaw then
    Yaw := AMax.Yaw;
  if Roll < AMin.Roll then
    Roll := AMin.Roll
  else if Roll > AMax.Roll then
    Roll := AMax.Roll;
end;

function TIdAngles.GetDimension: Integer;
begin
  Result := 3;
end;

procedure TIdAngles.ToVectors(out AForward, ARight, AUp: TIdVec3);
var
  LSinRoll, LSinPitch, LSinYaw, LCosRoll, LCosPitch, LCosYaw: Single;
begin
  TIdMath.SinCos(Yaw * ID_DEG2RAD, LSinYaw, LCosYaw);
  TIdMath.SinCos(Pitch * ID_DEG2RAD, LSinPitch, LCosPitch);
  TIdMath.SinCos(Roll * ID_DEG2RAD, LSinRoll, LCosRoll);
  AForward.SetValues(LCosPitch * LCosYaw, LCosPitch * LSinYaw, -LSinPitch);
  ARight.SetValues(
    -LSinRoll * LSinPitch * LCosYaw + LCosRoll * LSinYaw,
    -LSinRoll * LSinPitch * LSinYaw + -LCosRoll * LCosYaw,
    -LSinRoll * LCosPitch);
  AUp.SetValues(
    LCosRoll * LSinPitch * LCosYaw + -LSinRoll * -LSinYaw,
    LCosRoll * LSinPitch * LSinYaw + -LSinRoll * LCosYaw,
    LCosRoll * LCosPitch);
end;

function TIdAngles.ToForward: TIdVec3;
var
  LSinPitch, LSinYaw, LCosPitch, LCosYaw: Single;
begin
  TIdMath.SinCos(Yaw * ID_DEG2RAD, LSinYaw, LCosYaw);
  TIdMath.SinCos(Pitch * ID_DEG2RAD, LSinPitch, LCosPitch);
  Result.SetValues(LCosPitch * LCosYaw, LCosPitch * LSinYaw, -LSinPitch);
end;

function TIdAngles.ToString(const APrecision: Integer): AnsiString;
begin
  Result := TIdStrings.FloatArrayToString([Pitch, Yaw, Roll], APrecision);
end;

end.
