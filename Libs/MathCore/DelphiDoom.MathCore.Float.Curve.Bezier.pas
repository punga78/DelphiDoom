{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdCurveBezier, a Bezier curve of   }
{  any degree                                                                  }
{                                                                              }
{  Port of idCurve_Bezier (idlib\math\Curve.h) of the Doom 3 GPL Source Code.  }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company. Based on  }
{  the Doom 3 GPL Source Code (id Software).                                   }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.Curve.Bezier;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Float.Curve;

type
  /// <summary>
  ///   Bezier curve (idCurve_Bezier): the degree is the number of knots minus one; only the first
  ///   and the last time matter, every knot value is a control point. The basis arrays have two
  ///   spare elements here: the original derivative functions write them one past the end.
  /// </summary>
  TIdCurveBezier<T> = class(TIdCurve<T>)
  protected
    /// <summary>Bezier basis functions, written from index <c>AOffset</c> of the array</summary>
    procedure Basis(const AOrder: Integer; const ATime: Single; var ABasis: TArray<Single>;
      const AOffset: Integer);
    procedure BasisFirstDerivative(const AOrder: Integer; const ATime: Single;
      var ABasis: TArray<Single>; const AOffset: Integer);
    procedure BasisSecondDerivative(const AOrder: Integer; const ATime: Single;
      var ABasis: TArray<Single>; const AOffset: Integer);
    function Combine(const ABasis: TArray<Single>): T;
  public
    function GetCurrentValue(const ATime: Single): T; override;
    function GetCurrentFirstDerivative(const ATime: Single): T; override;
    function GetCurrentSecondDerivative(const ATime: Single): T; override;
  end;

implementation

{ TIdCurveBezier<T> }

function TIdCurveBezier<T>.Combine(const ABasis: TArray<Single>): T;
var
  LIndex: Integer;
begin
  Result := Arithmetic.Multiply(FValues[0], ABasis[0]);
  for LIndex := 1 to FValues.Count - 1 do
    Result := Arithmetic.Add(Result, Arithmetic.Multiply(FValues[LIndex], ABasis[LIndex]));
end;

function TIdCurveBezier<T>.GetCurrentValue(const ATime: Single): T;
var
  LBasis: TArray<Single>;
begin
  SetLength(LBasis, FValues.Count + 2);
  Basis(FValues.Count, ATime, LBasis, 0);
  Result := Combine(LBasis);
end;

function TIdCurveBezier<T>.GetCurrentFirstDerivative(const ATime: Single): T;
var
  LBasis: TArray<Single>;
  LDuration, LFactor: Single;
begin
  SetLength(LBasis, FValues.Count + 2);
  BasisFirstDerivative(FValues.Count, ATime, LBasis, 0);
  Result := Combine(LBasis);
  LDuration := FTimes[FTimes.Count - 1] - FTimes[0];
  LFactor := Single(FValues.Count - 1) / LDuration;
  Result := Arithmetic.Multiply(Result, LFactor);
end;

function TIdCurveBezier<T>.GetCurrentSecondDerivative(const ATime: Single): T;
var
  LBasis: TArray<Single>;
  LDuration, LFactor, LNumerator, LSquare: Single;
begin
  SetLength(LBasis, FValues.Count + 2);
  BasisSecondDerivative(FValues.Count, ATime, LBasis, 0);
  Result := Combine(LBasis);
  LDuration := FTimes[FTimes.Count - 1] - FTimes[0];
  LNumerator := Single(FValues.Count - 2) * (FValues.Count - 1);
  LSquare := LDuration * LDuration;
  LFactor := LNumerator / LSquare;
  Result := Arithmetic.Multiply(Result, LFactor);
end;

procedure TIdCurveBezier<T>.Basis(const AOrder: Integer; const ATime: Single;
  var ABasis: TArray<Single>; const AOffset: Integer);
var
  LIndex, LJ, LDegree: Integer;
  LC: TArray<Single>;
  LC1, LC2, LS, LO, LPS, LPO, LValue: Single;
begin
  ABasis[AOffset] := 1.0;
  LDegree := AOrder - 1;
  if LDegree <= 0 then
    Exit;

  SetLength(LC, LDegree + 1);
  LValue := ATime - FTimes[0];
  LS := LValue / (FTimes[FTimes.Count - 1] - FTimes[0]);
  LO := 1.0 - LS;
  LPS := LS;
  LPO := LO;

  for LIndex := 1 to LDegree - 1 do
    LC[LIndex] := 1.0;
  for LIndex := 1 to LDegree - 1 do
  begin
    LC[LIndex - 1] := 0.0;
    LC1 := LC[LIndex];
    LC[LIndex] := 1.0;
    for LJ := LIndex + 1 to LDegree do
    begin
      LC2 := LC[LJ];
      LC[LJ] := LC1 + LC[LJ - 1];
      LC1 := LC2;
    end;
    ABasis[AOffset + LIndex] := LC[LDegree] * LPS;
    LPS := LPS * LS;
  end;
  for LIndex := LDegree - 1 downto 0 do
  begin
    ABasis[AOffset + LIndex] := ABasis[AOffset + LIndex] * LPO;
    LPO := LPO * LO;
  end;
  ABasis[AOffset + LDegree] := LPS;
end;

procedure TIdCurveBezier<T>.BasisFirstDerivative(const AOrder: Integer; const ATime: Single;
  var ABasis: TArray<Single>; const AOffset: Integer);
var
  LIndex: Integer;
begin
  Basis(AOrder - 1, ATime, ABasis, AOffset + 1);
  ABasis[AOffset] := 0.0;
  for LIndex := 0 to AOrder - 2 do
    ABasis[AOffset + LIndex] := ABasis[AOffset + LIndex] - ABasis[AOffset + LIndex + 1];
end;

procedure TIdCurveBezier<T>.BasisSecondDerivative(const AOrder: Integer; const ATime: Single;
  var ABasis: TArray<Single>; const AOffset: Integer);
var
  LIndex: Integer;
begin
  BasisFirstDerivative(AOrder - 1, ATime, ABasis, AOffset + 1);
  ABasis[AOffset] := 0.0;
  for LIndex := 0 to AOrder - 2 do
    ABasis[AOffset + LIndex] := ABasis[AOffset + LIndex] - ABasis[AOffset + LIndex + 1];
end;

end.
