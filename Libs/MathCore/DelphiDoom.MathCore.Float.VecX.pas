{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdVecX, the vector of any size     }
{                                                                              }
{  Port of idVecX (idlib\math\Vector.h and Vector.cpp) of the Doom 3 GPL       }
{  Source Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media       }
{  company. Based on the Doom 3 GPL Source Code (id Software).                 }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.VecX;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.IdLib.Math.Vec3, DelphiDoom.MathCore.Float.Types, DelphiDoom.MathCore.Float.Vec6;

type
  /// <summary>
  ///   A vector of Single of any size (idVecX). The C++ class has a static pool of temporary
  ///   memory so that operators can return vectors by value; here a vector is a class that owns
  ///   its memory (or points at memory given by <c>SetData</c>, which it never frees) and the
  ///   operators that make a new vector are functions whose result the caller frees. As in the
  ///   C++ the storage is padded with zeros to a multiple of four floats.
  /// </summary>
  TIdVecX = class
  strict private
    FSize: Integer;
    FStorage: TArray<Single>;
    FData: PIdSingleArray;
    FExternal: Boolean;
    function GetItem(const AIndex: Integer): Single;
    procedure SetItem(const AIndex: Integer; const AValue: Single);
    procedure ClearEnd;
  public
    constructor Create; overload;
    constructor Create(const ASize: Integer); overload;
    /// <summary>A vector over memory of the caller (idVecX(length, data)); never freed here</summary>
    constructor Create(const ASize: Integer; const AData: PIdSingleArray); overload;
    property Items[const AIndex: Integer]: Single read GetItem write SetItem; default;
    property Size: Integer read FSize;
    /// <summary>idVecX::ToFloatPtr</summary>
    property Data: PIdSingleArray read FData;
    /// <summary>operator=: takes the size and the values of another vector</summary>
    procedure Assign(const A: TIdVecX);
    /// <summary>operator+=</summary>
    procedure AddAssign(const A: TIdVecX);
    /// <summary>operator-=</summary>
    procedure SubtractAssign(const A: TIdVecX);
    /// <summary>operator*=</summary>
    procedure MultiplyAssign(const A: Single);
    /// <summary>operator/=: multiplies by the reciprocal</summary>
    procedure DivideAssign(const A: Single);
    /// <summary>operator-() as a new vector</summary>
    function Negative: TIdVecX;
    function Add(const A: TIdVecX): TIdVecX;
    function Subtract(const A: TIdVecX): TIdVecX;
    function Multiply(const A: Single): TIdVecX; overload;
    function Divide(const A: Single): TIdVecX;
    /// <summary>The dot product (operator*(idVecX))</summary>
    function Multiply(const A: TIdVecX): Single; overload;
    /// <summary>Exact comparison</summary>
    function Compare(const A: TIdVecX): Boolean; overload;
    function Compare(const A: TIdVecX; const AEpsilon: Single): Boolean; overload;
    procedure SetSize(const ASize: Integer);
    procedure ChangeSize(const ASize: Integer; const AMakeZero: Boolean = False);
    procedure SetData(const ASize: Integer; const AData: PIdSingleArray);
    procedure Zero; overload;
    procedure Zero(const ASize: Integer); overload;
    procedure Random(const ASeed: Integer; const ALower: Single = 0.0; const AUpper: Single = 1.0);
      overload;
    procedure Random(const ASize, ASeed: Integer; const ALower: Single = 0.0;
      const AUpper: Single = 1.0); overload;
    procedure Negate;
    procedure Clamp(const AMin, AMax: Single);
    procedure SwapElements(const AFirst, ASecond: Integer);
    function Length: Single;
    function LengthSqr: Single;
    /// <summary>The normalized vector as a new vector</summary>
    function Normalize: TIdVecX;
    /// <summary>Normalizes in place and returns the old length</summary>
    function NormalizeSelf: Single;
    function GetDimension: Integer;
    /// <summary>Components 3*i .. 3*i+2 as a vector (a copy)</summary>
    function GetSubVec3(const AIndex: Integer): TIdVec3;
    procedure SetSubVec3(const AIndex: Integer; const AValue: TIdVec3);
    /// <summary>Components 6*i .. 6*i+5 as a vector (a copy)</summary>
    function GetSubVec6(const AIndex: Integer): TIdVec6;
    procedure SetSubVec6(const AIndex: Integer; const AValue: TIdVec6);
    function ToString(const APrecision: Integer = 2): AnsiString; reintroduce;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Math, DelphiDoom.IdLib.Math.Random, DelphiDoom.IdLib.Text.Strings;

{ TIdVecX }

constructor TIdVecX.Create;
begin
  inherited Create;
  FSize := 0;
  FData := nil;
end;

constructor TIdVecX.Create(const ASize: Integer);
begin
  Create;
  SetSize(ASize);
end;

constructor TIdVecX.Create(const ASize: Integer; const AData: PIdSingleArray);
begin
  Create;
  SetData(ASize, AData);
end;

procedure TIdVecX.ClearEnd;
var
  LIndex: Integer;
begin
  LIndex := FSize;
  while LIndex < ((LIndex + 3) and not 3) do
  begin
    FData^[LIndex] := 0.0;
    Inc(LIndex);
  end;
end;

function TIdVecX.GetItem(const AIndex: Integer): Single;
begin
  Assert((AIndex >= 0) and (AIndex < FSize));
  Result := FData^[AIndex];
end;

procedure TIdVecX.SetItem(const AIndex: Integer; const AValue: Single);
begin
  Assert((AIndex >= 0) and (AIndex < FSize));
  FData^[AIndex] := AValue;
end;

procedure TIdVecX.SetSize(const ASize: Integer);
var
  LAlloc: Integer;
begin
  LAlloc := (ASize + 3) and not 3;
  if (not FExternal) and (LAlloc > System.Length(FStorage)) then
  begin
    SetLength(FStorage, LAlloc);
    FData := PIdSingleArray(FStorage);
  end;
  FSize := ASize;
  ClearEnd;
end;

procedure TIdVecX.ChangeSize(const ASize: Integer; const AMakeZero: Boolean);
var
  LAlloc, LIndex: Integer;
begin
  LAlloc := (ASize + 3) and not 3;
  if (not FExternal) and (LAlloc > System.Length(FStorage)) then
  begin
    // SetLength keeps the old values
    SetLength(FStorage, LAlloc);
    FData := PIdSingleArray(FStorage);
    if AMakeZero then
    begin
      for LIndex := FSize to ASize - 1 do
      begin
        FStorage[LIndex] := 0.0;
      end;
    end;
  end;
  FSize := ASize;
  ClearEnd;
end;

procedure TIdVecX.SetData(const ASize: Integer; const AData: PIdSingleArray);
begin
  FStorage := nil;
  FData := AData;
  FExternal := True;
  FSize := ASize;
  ClearEnd;
end;

procedure TIdVecX.Assign(const A: TIdVecX);
var
  LIndex: Integer;
begin
  SetSize(A.FSize);
  for LIndex := 0 to A.FSize - 1 do
  begin
    FData^[LIndex] := A.FData^[LIndex];
  end;
end;

procedure TIdVecX.AddAssign(const A: TIdVecX);
var
  LIndex: Integer;
begin
  Assert(FSize = A.FSize);
  for LIndex := 0 to FSize - 1 do
  begin
    Items[LIndex] := Items[LIndex] + A.Items[LIndex];
  end;
end;

procedure TIdVecX.SubtractAssign(const A: TIdVecX);
var
  LIndex: Integer;
begin
  Assert(FSize = A.FSize);
  for LIndex := 0 to FSize - 1 do
  begin
    Items[LIndex] := Items[LIndex] - A.Items[LIndex];
  end;
end;

procedure TIdVecX.MultiplyAssign(const A: Single);
var
  LIndex: Integer;
begin
  for LIndex := 0 to FSize - 1 do
  begin
    Items[LIndex] := Items[LIndex] * A;
  end;
end;

procedure TIdVecX.DivideAssign(const A: Single);
var
  LInverse: Single;
begin
  Assert(A <> 0.0);
  LInverse := 1.0 / A;
  MultiplyAssign(LInverse);
end;

function TIdVecX.Negative: TIdVecX;
var
  LIndex: Integer;
begin
  Result := TIdVecX.Create(FSize);
  for LIndex := 0 to FSize - 1 do
  begin
    Result.Items[LIndex] := -Items[LIndex];
  end;
end;

function TIdVecX.Add(const A: TIdVecX): TIdVecX;
var
  LIndex: Integer;
begin
  Assert(FSize = A.FSize);
  Result := TIdVecX.Create(FSize);
  for LIndex := 0 to FSize - 1 do
  begin
    Result.Items[LIndex] := Items[LIndex] + A.Items[LIndex];
  end;
end;

function TIdVecX.Subtract(const A: TIdVecX): TIdVecX;
var
  LIndex: Integer;
begin
  Assert(FSize = A.FSize);
  Result := TIdVecX.Create(FSize);
  for LIndex := 0 to FSize - 1 do
  begin
    Result.Items[LIndex] := Items[LIndex] - A.Items[LIndex];
  end;
end;

function TIdVecX.Multiply(const A: Single): TIdVecX;
var
  LIndex: Integer;
begin
  Result := TIdVecX.Create(FSize);
  for LIndex := 0 to FSize - 1 do
  begin
    Result.Items[LIndex] := Items[LIndex] * A;
  end;
end;

function TIdVecX.Divide(const A: Single): TIdVecX;
var
  LInverse: Single;
begin
  Assert(A <> 0.0);
  LInverse := 1.0 / A;
  Result := Multiply(LInverse);
end;

function TIdVecX.Multiply(const A: TIdVecX): Single;
var
  LIndex: Integer;
begin
  Assert(FSize = A.FSize);
  Result := 0.0;
  for LIndex := 0 to FSize - 1 do
  begin
    Result := Result + Items[LIndex] * A.Items[LIndex];
  end;
end;

function TIdVecX.Compare(const A: TIdVecX): Boolean;
var
  LIndex: Integer;
begin
  Assert(FSize = A.FSize);
  Result := True;
  for LIndex := 0 to FSize - 1 do
  begin
    if Items[LIndex] <> A.Items[LIndex] then
      Exit(False);
  end;
end;

function TIdVecX.Compare(const A: TIdVecX; const AEpsilon: Single): Boolean;
var
  LIndex: Integer;
begin
  Assert(FSize = A.FSize);
  Result := True;
  for LIndex := 0 to FSize - 1 do
  begin
    if TIdMath.Fabs(Items[LIndex] - A.Items[LIndex]) > AEpsilon then
      Exit(False);
  end;
end;

procedure TIdVecX.Zero;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FSize - 1 do
  begin
    Items[LIndex] := 0.0;
  end;
end;

procedure TIdVecX.Zero(const ASize: Integer);
begin
  SetSize(ASize);
  Zero;
end;

procedure TIdVecX.Random(const ASeed: Integer; const ALower, AUpper: Single);
var
  LIndex: Integer;
  LRange: Single;
  LRandom: TIdRandom;
begin
  LRandom := TIdRandom.Create(ASeed);
  LRange := AUpper - ALower;
  for LIndex := 0 to FSize - 1 do
  begin
    Items[LIndex] := ALower + LRandom.RandomFloat * LRange;
  end;
end;

procedure TIdVecX.Random(const ASize, ASeed: Integer; const ALower, AUpper: Single);
begin
  SetSize(ASize);
  Random(ASeed, ALower, AUpper);
end;

procedure TIdVecX.Negate;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FSize - 1 do
  begin
    Items[LIndex] := -Items[LIndex];
  end;
end;

procedure TIdVecX.Clamp(const AMin, AMax: Single);
var
  LIndex: Integer;
begin
  for LIndex := 0 to FSize - 1 do
  begin
    if Items[LIndex] < AMin then
      Items[LIndex] := AMin
    else if Items[LIndex] > AMax then
      Items[LIndex] := AMax;
  end;
end;

procedure TIdVecX.SwapElements(const AFirst, ASecond: Integer);
var
  LTemp: Single;
begin
  LTemp := Items[AFirst];
  Items[AFirst] := Items[ASecond];
  Items[ASecond] := LTemp;
end;

function TIdVecX.Length: Single;
begin
  Result := TIdMath.Sqrt(LengthSqr);
end;

function TIdVecX.LengthSqr: Single;
var
  LIndex: Integer;
begin
  Result := 0.0;
  for LIndex := 0 to FSize - 1 do
  begin
    Result := Result + Items[LIndex] * Items[LIndex];
  end;
end;

function TIdVecX.Normalize: TIdVecX;
var
  LIndex: Integer;
  LInverseSqrt, LSum: Single;
begin
  Result := TIdVecX.Create(FSize);
  LSum := LengthSqr;
  LInverseSqrt := TIdMath.InvSqrt(LSum);
  for LIndex := 0 to FSize - 1 do
  begin
    Result.Items[LIndex] := Items[LIndex] * LInverseSqrt;
  end;
end;

function TIdVecX.NormalizeSelf: Single;
var
  LIndex: Integer;
  LInverseSqrt, LSum: Single;
begin
  LSum := LengthSqr;
  LInverseSqrt := TIdMath.InvSqrt(LSum);
  for LIndex := 0 to FSize - 1 do
  begin
    Items[LIndex] := Items[LIndex] * LInverseSqrt;
  end;
  Result := LInverseSqrt * LSum;
end;

function TIdVecX.GetDimension: Integer;
begin
  Result := FSize;
end;

function TIdVecX.GetSubVec3(const AIndex: Integer): TIdVec3;
begin
  Assert((AIndex >= 0) and (AIndex * 3 + 3 <= FSize));
  Result := TIdVec3.Create(Items[AIndex * 3], Items[AIndex * 3 + 1], Items[AIndex * 3 + 2]);
end;

procedure TIdVecX.SetSubVec3(const AIndex: Integer; const AValue: TIdVec3);
begin
  Assert((AIndex >= 0) and (AIndex * 3 + 3 <= FSize));
  Items[AIndex * 3] := AValue.X;
  Items[AIndex * 3 + 1] := AValue.Y;
  Items[AIndex * 3 + 2] := AValue.Z;
end;

function TIdVecX.GetSubVec6(const AIndex: Integer): TIdVec6;
var
  LIndex: Integer;
begin
  Assert((AIndex >= 0) and (AIndex * 6 + 6 <= FSize));
  for LIndex := 0 to 5 do
  begin
    Result.P[LIndex] := Items[AIndex * 6 + LIndex];
  end;
end;

procedure TIdVecX.SetSubVec6(const AIndex: Integer; const AValue: TIdVec6);
var
  LIndex: Integer;
begin
  Assert((AIndex >= 0) and (AIndex * 6 + 6 <= FSize));
  for LIndex := 0 to 5 do
  begin
    Items[AIndex * 6 + LIndex] := AValue.P[LIndex];
  end;
end;

function TIdVecX.ToString(const APrecision: Integer): AnsiString;
var
  LValues: TArray<Single>;
  LIndex: Integer;
begin
  SetLength(LValues, FSize);
  for LIndex := 0 to FSize - 1 do
  begin
    LValues[LIndex] := Items[LIndex];
  end;
  Result := TIdStrings.FloatArrayToString(LValues, APrecision);
end;

end.
