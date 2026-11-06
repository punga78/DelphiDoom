{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the math core library - the vectors                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MathCore.VectorMath;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Tests.MathCore.Golden,
  DelphiDoom.Tests.MathCore.Fingerprint, DelphiDoom.MathCore.Types;

type
  /// <summary>
  ///   Parity with the old m_vectors (golden file vectors.golden.txt: the bits of the results
  ///   on series of random vectors, at Win32) and a few values written by hand
  /// </summary>
  [TestFixture]
  [Category('mathcore')]
  TTestMathCoreVectorMath = class(TObject)
  private
    FGolden: TGoldenFile;
    procedure AddVector3(const AFingerprint: TFingerprint; const AVector: TVec3);
    procedure AddVector2(const AFingerprint: TFingerprint; const AVector: TVec2);
    function RandomUnit3(var AState: Cardinal): TVec3;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeRiconoscereINanCometIsNan;
    [Test]
    procedure DovrebbeConvertireInRadianti;
    [Test]
    procedure DovrebbeProiettareUnPuntoSuUnPiano;
    [Test]
    procedure DovrebbeTrovareUnVettorePerpendicolare;
    [Test]
    procedure DovrebbeRuotareUnPuntoAttornoAUnVettore;
    [Test]
    procedure DovrebbeConfrontareDueVettori;
    [Test]
    procedure DovrebbeFareLeOperazioniDiBaseSuVettoriATreComponenti;
    [Test]
    procedure DovrebbeCalcolareLunghezzaENormalizzazione;
    [Test]
    procedure DovrebbeComporreLeRotazioni;
    [Test]
    procedure DovrebbeFareLeOperazioniSuVettoriADueComponenti;
    [Test]
    procedure DovrebbeCalcolareIlRimbalzoSuUnMuro;

    [Test]
    procedure DovrebbeLasciareUnVettoreNulloComeEra;
    [Test]
    procedure DovrebbeNormalizzareAUnaLunghezzaDiUno;
    [Test]
    procedure DovrebbeCalcolareProdottoScalareEVettoriale;
  end;

implementation

uses
  DelphiDoom.MathCore.VectorMath, DelphiDoom.Tests.MathCore.Samples;

{ TTestMathCoreVectorMath }

procedure TTestMathCoreVectorMath.Setup;
begin
  FGolden := TGoldenFile.Create('vectors.golden.txt');
end;

procedure TTestMathCoreVectorMath.TearDown;
begin
  FGolden.Free;
end;

procedure TTestMathCoreVectorMath.AddVector3(const AFingerprint: TFingerprint; const AVector: TVec3);
begin
  AFingerprint.AddSingle(AVector[0]);
  AFingerprint.AddSingle(AVector[1]);
  AFingerprint.AddSingle(AVector[2]);
end;

procedure TTestMathCoreVectorMath.AddVector2(const AFingerprint: TFingerprint; const AVector: TVec2);
begin
  AFingerprint.AddSingle(AVector[0]);
  AFingerprint.AddSingle(AVector[1]);
end;

function TTestMathCoreVectorMath.RandomUnit3(var AState: Cardinal): TVec3;
begin
  Result := TMathCoreSamples.NextVector3(AState);
  TVectorMath.Normalize3(Result);
end;

procedure TTestMathCoreVectorMath.DovrebbeRiconoscereINanCometIsNan;
var
  LFingerprint: TFingerprint;
  LState: Cardinal;
  LIndex: Integer;
  LBits: Cardinal;
  LValue: Single;
begin
  LFingerprint := TFingerprint.Create;
  try
    LState := TMathCoreSamples.INITIAL_STATE;
    for LIndex := 0 to 3999 do
    begin
      LBits := TMathCoreSamples.NextRandom(LState);
      Move(LBits, LValue, 4);
      LFingerprint.AddBoolean(TVectorMath.IsNaN(LValue));
    end;
    LBits := $7F800000; Move(LBits, LValue, 4); LFingerprint.AddBoolean(TVectorMath.IsNaN(LValue));
    LBits := $FF800000; Move(LBits, LValue, 4); LFingerprint.AddBoolean(TVectorMath.IsNaN(LValue));
    LBits := $7FC00000; Move(LBits, LValue, 4); LFingerprint.AddBoolean(TVectorMath.IsNaN(LValue));
    LBits := $00000000; Move(LBits, LValue, 4); LFingerprint.AddBoolean(TVectorMath.IsNaN(LValue));
    LBits := $7F7FFFFF; Move(LBits, LValue, 4); LFingerprint.AddBoolean(TVectorMath.IsNaN(LValue));
    FGolden.Check('vec.IsNaN', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestMathCoreVectorMath.DovrebbeConvertireInRadianti;
var
  LFingerprint: TFingerprint;
  LState: Cardinal;
  LIndex: Integer;
begin
  LFingerprint := TFingerprint.Create;
  try
    LState := TMathCoreSamples.INITIAL_STATE;
    for LIndex := 1 to 2000 do
      LFingerprint.AddSingle(TVectorMath.DegreesToRadians(TMathCoreSamples.NextFloat(LState) / 100));
    FGolden.Check('vec.DegreesToRadians', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestMathCoreVectorMath.DovrebbeProiettareUnPuntoSuUnPiano;
var
  LFingerprint: TFingerprint;
  LState: Cardinal;
  LIndex: Integer;
  A, B, C: TVec3;
begin
  LFingerprint := TFingerprint.Create;
  try
    LState := TMathCoreSamples.INITIAL_STATE;
    for LIndex := 1 to 2000 do
    begin
      A := TMathCoreSamples.NextVector3(LState);
      B := TMathCoreSamples.NextVector3(LState);
      TVectorMath.ProjectPointOnPlane(C, A, B);
      AddVector3(LFingerprint, C);
    end;
    FGolden.Check('vec.ProjectPointOnPlane', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestMathCoreVectorMath.DovrebbeTrovareUnVettorePerpendicolare;
var
  LFingerprint: TFingerprint;
  LState: Cardinal;
  LIndex: Integer;
  A, C: TVec3;
begin
  LFingerprint := TFingerprint.Create;
  try
    LState := TMathCoreSamples.INITIAL_STATE;
    for LIndex := 1 to 2000 do
    begin
      A := RandomUnit3(LState);
      TVectorMath.PerpendicularVector(C, A);
      AddVector3(LFingerprint, C);
    end;
    A[0] := 1; A[1] := 0; A[2] := 0; TVectorMath.PerpendicularVector(C, A); AddVector3(LFingerprint, C);
    A[0] := 0; A[1] := 0; A[2] := 1; TVectorMath.PerpendicularVector(C, A); AddVector3(LFingerprint, C);
    A[0] := 0; A[1] := -1; A[2] := 0; TVectorMath.PerpendicularVector(C, A); AddVector3(LFingerprint, C);
    FGolden.Check('vec.PerpendicularVector', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestMathCoreVectorMath.DovrebbeRuotareUnPuntoAttornoAUnVettore;
var
  LFingerprint: TFingerprint;
  LState: Cardinal;
  LIndex: Integer;
  A, B, C: TVec3;
  LDegrees: Single;
begin
  LFingerprint := TFingerprint.Create;
  try
    LState := TMathCoreSamples.INITIAL_STATE;
    for LIndex := 1 to 1500 do
    begin
      A := RandomUnit3(LState);
      B := TMathCoreSamples.NextVector3(LState);
      LDegrees := TMathCoreSamples.NextFloat(LState) / 100;
      TVectorMath.RotatePointAroundVector(C, A, B, LDegrees);
      AddVector3(LFingerprint, C);
    end;
    FGolden.Check('vec.RotatePointAroundVector', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestMathCoreVectorMath.DovrebbeConfrontareDueVettori;
var
  LFingerprint: TFingerprint;
  LState: Cardinal;
  LIndex: Integer;
  A, B: TVec3;
begin
  LFingerprint := TFingerprint.Create;
  try
    LState := TMathCoreSamples.INITIAL_STATE;
    for LIndex := 1 to 2000 do
    begin
      A := TMathCoreSamples.NextVector3(LState);
      B := A;
      if LIndex mod 3 = 0 then
        B := TMathCoreSamples.NextVector3(LState);
      if LIndex mod 3 = 1 then
        B[LIndex mod 3] := B[LIndex mod 3] + 1;
      // the old function gave 1 or 0
      if TVectorMath.Compare3(A, B) then
        LFingerprint.AddInteger(1)
      else
        LFingerprint.AddInteger(0);
    end;
    FGolden.Check('vec.Compare3', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestMathCoreVectorMath.DovrebbeFareLeOperazioniDiBaseSuVettoriATreComponenti;
var
  LFingerprint: TFingerprint;
  LState: Cardinal;
  LIndex: Integer;
  A, B, C: TVec3;
  LScale: Single;
begin
  LFingerprint := TFingerprint.Create;
  try
    LState := TMathCoreSamples.INITIAL_STATE;
    for LIndex := 1 to 2000 do
    begin
      A := TMathCoreSamples.NextVector3(LState);
      B := TMathCoreSamples.NextVector3(LState);
      LScale := TMathCoreSamples.NextFloat(LState) / 64;
      TVectorMath.MultiplyAdd3(A, LScale, B, C);
      AddVector3(LFingerprint, C);
    end;
    FGolden.Check('vec.MultiplyAdd3', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;

  LFingerprint := TFingerprint.Create;
  try
    LState := TMathCoreSamples.INITIAL_STATE;
    for LIndex := 1 to 2000 do
    begin
      A := TMathCoreSamples.NextVector3(LState);
      B := TMathCoreSamples.NextVector3(LState);
      LFingerprint.AddSingle(TVectorMath.Dot3(A, B));
    end;
    FGolden.Check('vec.Dot3', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;

  LFingerprint := TFingerprint.Create;
  try
    LState := TMathCoreSamples.INITIAL_STATE;
    for LIndex := 1 to 2000 do
    begin
      A := TMathCoreSamples.NextVector3(LState);
      B := TMathCoreSamples.NextVector3(LState);
      TVectorMath.Subtract3(A, B, C);
      AddVector3(LFingerprint, C);
    end;
    FGolden.Check('vec.Subtract3', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;

  LFingerprint := TFingerprint.Create;
  try
    LState := TMathCoreSamples.INITIAL_STATE;
    for LIndex := 1 to 2000 do
    begin
      A := TMathCoreSamples.NextVector3(LState);
      B := TMathCoreSamples.NextVector3(LState);
      TVectorMath.Add3(A, B, C);
      AddVector3(LFingerprint, C);
    end;
    FGolden.Check('vec.Add3', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;

  LFingerprint := TFingerprint.Create;
  try
    LState := TMathCoreSamples.INITIAL_STATE;
    for LIndex := 1 to 2000 do
    begin
      A := TMathCoreSamples.NextVector3(LState);
      B := TMathCoreSamples.NextVector3(LState);
      TVectorMath.Cross3(A, B, C);
      AddVector3(LFingerprint, C);
    end;
    FGolden.Check('vec.Cross3', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;

  LFingerprint := TFingerprint.Create;
  try
    LState := TMathCoreSamples.INITIAL_STATE;
    for LIndex := 1 to 2000 do
    begin
      A := TMathCoreSamples.NextVector3(LState);
      TVectorMath.Inverse3(A);
      AddVector3(LFingerprint, A);
    end;
    FGolden.Check('vec.Inverse3', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;

  LFingerprint := TFingerprint.Create;
  try
    LState := TMathCoreSamples.INITIAL_STATE;
    for LIndex := 1 to 2000 do
    begin
      A := TMathCoreSamples.NextVector3(LState);
      LScale := TMathCoreSamples.NextFloat(LState) / 64;
      TVectorMath.Scale3(A, LScale, C);
      AddVector3(LFingerprint, C);
    end;
    FGolden.Check('vec.Scale3', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestMathCoreVectorMath.DovrebbeCalcolareLunghezzaENormalizzazione;
var
  LFingerprint: TFingerprint;
  LState: Cardinal;
  LIndex: Integer;
  A: TVec3;
begin
  LFingerprint := TFingerprint.Create;
  try
    LState := TMathCoreSamples.INITIAL_STATE;
    for LIndex := 1 to 2000 do
    begin
      A := TMathCoreSamples.NextVector3(LState);
      LFingerprint.AddSingle(TVectorMath.Length3(A));
    end;
    FGolden.Check('vec.Length3', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;

  LFingerprint := TFingerprint.Create;
  try
    LState := TMathCoreSamples.INITIAL_STATE;
    for LIndex := 1 to 2000 do
    begin
      A := TMathCoreSamples.NextVector3(LState);
      LFingerprint.AddSingle(TVectorMath.Normalize3(A));
      AddVector3(LFingerprint, A);
    end;
    A[0] := 0; A[1] := 0; A[2] := 0;
    LFingerprint.AddSingle(TVectorMath.Normalize3(A));
    AddVector3(LFingerprint, A);
    FGolden.Check('vec.Normalize3', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestMathCoreVectorMath.DovrebbeComporreLeRotazioni;
var
  LFingerprint: TFingerprint;
  LState: Cardinal;
  LIndex: Integer;
  LCell: Integer;
  M1, M2, M3: TMat3;
begin
  LFingerprint := TFingerprint.Create;
  try
    LState := TMathCoreSamples.INITIAL_STATE;
    for LIndex := 1 to 1000 do
    begin
      for LCell := 0 to 8 do
      begin
        M1[LCell div 3, LCell mod 3] := TMathCoreSamples.NextFloat(LState) / 64;
        M2[LCell div 3, LCell mod 3] := TMathCoreSamples.NextFloat(LState) / 64;
      end;
      TVectorMath.ConcatRotations(M1, M2, M3);
      for LCell := 0 to 8 do
        LFingerprint.AddSingle(M3[LCell div 3, LCell mod 3]);
    end;
    FGolden.Check('vec.ConcatRotations', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestMathCoreVectorMath.DovrebbeFareLeOperazioniSuVettoriADueComponenti;
var
  LFingerprint: TFingerprint;
  LState: Cardinal;
  LIndex: Integer;
  P, Q: TVec2;
  LScale: Single;
begin
  LFingerprint := TFingerprint.Create;
  try
    LState := TMathCoreSamples.INITIAL_STATE;
    for LIndex := 1 to 2000 do
    begin
      P := TMathCoreSamples.NextVector2(LState);
      Q := TMathCoreSamples.NextVector2(LState);
      LFingerprint.AddSingle(TVectorMath.Dot2(P, Q));
    end;
    FGolden.Check('vec.Dot2', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;

  LFingerprint := TFingerprint.Create;
  try
    LState := TMathCoreSamples.INITIAL_STATE;
    for LIndex := 1 to 2000 do
    begin
      P := TMathCoreSamples.NextVector2(LState);
      Q := TMathCoreSamples.NextVector2(LState);
      AddVector2(LFingerprint, TVectorMath.Subtract2(P, Q));
    end;
    FGolden.Check('vec.Subtract2', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;

  LFingerprint := TFingerprint.Create;
  try
    LState := TMathCoreSamples.INITIAL_STATE;
    for LIndex := 1 to 2000 do
    begin
      P := TMathCoreSamples.NextVector2(LState);
      Q := TMathCoreSamples.NextVector2(LState);
      AddVector2(LFingerprint, TVectorMath.Add2(P, Q));
    end;
    FGolden.Check('vec.Add2', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;

  LFingerprint := TFingerprint.Create;
  try
    LState := TMathCoreSamples.INITIAL_STATE;
    for LIndex := 1 to 2000 do
    begin
      P := TMathCoreSamples.NextVector2(LState);
      LScale := TMathCoreSamples.NextFloat(LState) / 64;
      AddVector2(LFingerprint, TVectorMath.Scale2(P, LScale));
    end;
    FGolden.Check('vec.Scale2', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;

  LFingerprint := TFingerprint.Create;
  try
    LState := TMathCoreSamples.INITIAL_STATE;
    for LIndex := 1 to 2000 do
    begin
      P := TMathCoreSamples.NextVector2(LState);
      LFingerprint.AddSingle(TVectorMath.Length2(P));
    end;
    FGolden.Check('vec.Length2', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;

  LFingerprint := TFingerprint.Create;
  try
    LState := TMathCoreSamples.INITIAL_STATE;
    for LIndex := 1 to 2000 do
    begin
      P := TMathCoreSamples.NextVector2(LState);
      LFingerprint.AddSingle(TVectorMath.Normalize2(P));
      AddVector2(LFingerprint, P);
    end;
    P[0] := 0; P[1] := 0;
    LFingerprint.AddSingle(TVectorMath.Normalize2(P));
    AddVector2(LFingerprint, P);
    FGolden.Check('vec.Normalize2', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestMathCoreVectorMath.DovrebbeCalcolareIlRimbalzoSuUnMuro;
var
  LFingerprint: TFingerprint;
  LState: Cardinal;
  LIndex: Integer;
  P, Q, R: TVec2;
begin
  LFingerprint := TFingerprint.Create;
  try
    LState := TMathCoreSamples.INITIAL_STATE;
    for LIndex := 1 to 2000 do
    begin
      P := TMathCoreSamples.NextVector2(LState);
      Q := TMathCoreSamples.NextVector2(LState);
      TVectorMath.CalculateReflect2(P, Q, R);
      AddVector2(LFingerprint, R);
    end;
    FGolden.Check('vec.CalculateReflect2', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestMathCoreVectorMath.DovrebbeLasciareUnVettoreNulloComeEra;
var
  A: TVec3;
begin
  A[0] := 0; A[1] := 0; A[2] := 0;
  Assert.AreEqual(Single(0), TVectorMath.Normalize3(A));
  Assert.AreEqual(Single(0), A[0]);
  Assert.AreEqual(Single(0), A[2]);
end;

procedure TTestMathCoreVectorMath.DovrebbeNormalizzareAUnaLunghezzaDiUno;
var
  A: TVec3;
begin
  A[0] := 3; A[1] := 0; A[2] := 4;
  Assert.AreEqual(Single(5), TVectorMath.Normalize3(A));
  Assert.AreEqual(Double(1), Double(TVectorMath.Length3(A)), 0.000001);
  Assert.AreEqual(Double(0.6), Double(A[0]), 0.000001);
end;

procedure TTestMathCoreVectorMath.DovrebbeCalcolareProdottoScalareEVettoriale;
var
  A, B, C: TVec3;
begin
  A[0] := 1; A[1] := 0; A[2] := 0;
  B[0] := 0; B[1] := 1; B[2] := 0;
  Assert.AreEqual(Single(0), TVectorMath.Dot3(A, B));
  TVectorMath.Cross3(A, B, C);
  Assert.AreEqual(Single(1), C[2]);
  Assert.IsTrue(TVectorMath.Compare3(A, A));
  Assert.IsFalse(TVectorMath.Compare3(A, B));
end;

end.
