{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the matrices of MathCore - the lines of the golden     }
{  files written by the C++ harness                                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MathCore.Matrix.Lines;

{$Q-}
{$R-}

interface

uses
  System.Classes, DelphiDoom.MathCore.Float.MatX, DelphiDoom.MathCore.Float.Types,
  DelphiDoom.MathCore.Float.VecX;

type
  TFloats = array of Single;

  /// <summary>
  ///   Reading and writing of the lines of Tests\Data\MathCore\matx.golden.txt: "name inputs | outputs",
  ///   floats as '#' and eight hexadecimal digits of the bit pattern, the other tokens (flags,
  ///   indexes, separators ';name') as they are.
  /// </summary>
  TMatrixLines = class sealed
  public
    class function DataPath(const AFileName: string): string; static;
    class function Bits(const AToken: string): Single; static;
    class function ParseInputs(const ALine: string; out AName: string): TFloats; static;
    /// <summary>The line up to and including the '|'</summary>
    class function HeadOf(const ALine: string): string; static;
    class procedure Put(var ALine: string; const AValue: Single); static;
    class procedure PutInt(var ALine: string; const AValue: Integer); static;
    class procedure PutFlag(var ALine: string; const AValue: Boolean); static;
    class procedure Sep(var ALine: string; const AName: string); static;
    class procedure PutFlat(var ALine: string; const AValues: Pointer; const ACount: Integer); static;
    class procedure PutVecX(var ALine: string; const AValue: TIdVecX); static;
    class procedure PutMatX(var ALine: string; const AValue: TIdMatX); static;
    /// <summary>
    ///   The eigenvectors (the columns) one after the other, each with its largest component
    ///   positive: the sign of an eigenvector is not stable between compilers
    /// </summary>
    class procedure PutEigen(var ALine: string; const AValue: TIdMatX); static;
    /// <summary>The lower triangle with the diagonal, by rows</summary>
    class procedure PutLower(var ALine: string; const AValue: TIdMatX); static;
    /// <summary>
    ///   Fails the test at the first token that differs: '#' tokens by ULPs or relative error or
    ///   absolute error (two NaN are equal), every other token must be identical
    /// </summary>
    class procedure CompareLines(const AExpected, AActual: TStrings; const AMaxUlps: Integer;
      const ARelative, AAbsolute: Single); static;
  end;

implementation

uses
  System.IOUtils, System.Math, System.SysUtils, DelphiDoom.Tests.IdLib.Golden,
  DUnitX.TestFramework;

function UlpDistance(const ABitsA, ABitsB: Cardinal): Int64;
  function Ordered(const ABits: Cardinal): Int64;
  begin
    if (ABits and $80000000) <> 0 then
      Result := -Int64(ABits and $7FFFFFFF)
    else
      Result := Int64(ABits);
  end;
begin
  Result := System.Abs(Ordered(ABitsA) - Ordered(ABitsB));
end;

function IsNaNBits(const ABits: Cardinal): Boolean;
begin
  Result := ((ABits and $7F800000) = $7F800000) and ((ABits and $007FFFFF) <> 0);
end;

{ TMatrixLines }

class function TMatrixLines.DataPath(const AFileName: string): string;
begin
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\..\..\Tests\Data\MathCore\' + AFileName));
end;

class function TMatrixLines.Bits(const AToken: string): Single;
var
  LBits: Cardinal;
begin
  LBits := Cardinal(StrToInt64('$' + Copy(AToken, 2, 8)));
  Result := PSingle(@LBits)^;
end;

class function TMatrixLines.ParseInputs(const ALine: string; out AName: string): TFloats;
var
  LParts: TArray<string>;
  LIndex, LCount: Integer;
begin
  LParts := ALine.Split([' ']);
  AName := LParts[0];
  SetLength(Result, 0);
  LCount := 0;
  for LIndex := 1 to High(LParts) do
  begin
    if LParts[LIndex] = '|' then
      Break;
    SetLength(Result, LCount + 1);
    Result[LCount] := Bits(LParts[LIndex]);
    Inc(LCount);
  end;
end;

class function TMatrixLines.HeadOf(const ALine: string): string;
begin
  Result := Copy(ALine, 1, Pos('|', ALine));
end;

class procedure TMatrixLines.Put(var ALine: string; const AValue: Single);
begin
  ALine := ALine + ' ' + TIdLibGolden.FloatToken(AValue);
end;

class procedure TMatrixLines.PutInt(var ALine: string; const AValue: Integer);
begin
  ALine := ALine + ' ' + IntToStr(AValue);
end;

class procedure TMatrixLines.PutFlag(var ALine: string; const AValue: Boolean);
begin
  if AValue then
    ALine := ALine + ' 1'
  else
    ALine := ALine + ' 0';
end;

class procedure TMatrixLines.Sep(var ALine: string; const AName: string);
begin
  ALine := ALine + ' ;' + AName;
end;

class procedure TMatrixLines.PutFlat(var ALine: string; const AValues: Pointer;
  const ACount: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 0 to ACount - 1 do
  begin
    Put(ALine, PIdSingleArray(AValues)^[LIndex]);
  end;
end;

class procedure TMatrixLines.PutVecX(var ALine: string; const AValue: TIdVecX);
begin
  PutFlat(ALine, AValue.Data, AValue.Size);
end;

class procedure TMatrixLines.PutMatX(var ALine: string; const AValue: TIdMatX);
begin
  PutFlat(ALine, AValue.Data, AValue.NumRows * AValue.NumColumns);
end;

class procedure TMatrixLines.PutEigen(var ALine: string; const AValue: TIdMatX);
var
  LRow, LColumn, LBest: Integer;
  LSign: Single;
begin
  for LColumn := 0 to AValue.NumColumns - 1 do
  begin
    LBest := 0;
    for LRow := 1 to AValue.NumRows - 1 do
    begin
      if System.Abs(AValue[LRow, LColumn]) > System.Abs(AValue[LBest, LColumn]) then
        LBest := LRow;
    end;
    if AValue[LBest, LColumn] < 0.0 then
      LSign := -1.0
    else
      LSign := 1.0;
    for LRow := 0 to AValue.NumRows - 1 do
    begin
      Put(ALine, AValue[LRow, LColumn] * LSign);
    end;
  end;
end;

class procedure TMatrixLines.PutLower(var ALine: string; const AValue: TIdMatX);
var
  LRow, LColumn: Integer;
begin
  for LRow := 0 to AValue.NumRows - 1 do
  begin
    for LColumn := 0 to LRow do
    begin
      Put(ALine, AValue[LRow, LColumn]);
    end;
  end;
end;

class procedure TMatrixLines.CompareLines(const AExpected, AActual: TStrings;
  const AMaxUlps: Integer; const ARelative, AAbsolute: Single);
var
  LLine, LToken: Integer;
  LExpectedTokens, LActualTokens: TArray<string>;
  LExpectedBits, LActualBits: Cardinal;
  LExpected, LActual: Single;
begin
  Assert.AreEqual(AExpected.Count, AActual.Count, 'numero di righe');
  for LLine := 0 to AExpected.Count - 1 do
  begin
    LExpectedTokens := AExpected[LLine].Split([' ']);
    LActualTokens := AActual[LLine].Split([' ']);
    Assert.AreEqual(Length(LExpectedTokens), Length(LActualTokens),
      'numero di token, riga ' + IntToStr(LLine) + ': ' + Copy(AExpected[LLine], 1, 40));
    for LToken := 0 to High(LExpectedTokens) do
    begin
      if (LExpectedTokens[LToken] <> '') and (LExpectedTokens[LToken][1] = '#') then
      begin
        LExpectedBits := Cardinal(StrToInt64('$' + Copy(LExpectedTokens[LToken], 2, 8)));
        LActualBits := Cardinal(StrToInt64('$' + Copy(LActualTokens[LToken], 2, 8)));
        if IsNaNBits(LExpectedBits) and IsNaNBits(LActualBits) then
          Continue;
        LExpected := Bits(LExpectedTokens[LToken]);
        LActual := Bits(LActualTokens[LToken]);
        if (UlpDistance(LExpectedBits, LActualBits) > AMaxUlps) and
          (System.Abs(LActual - LExpected) >
            System.Math.Max(AAbsolute, ARelative * System.Math.Max(1.0, System.Abs(LExpected)))) then
        begin
          Assert.Fail(Format('riga %d, token %d: atteso %s, ottenuto %s (%d ULP)' + sLineBreak +
            'atteso   %s' + sLineBreak + 'ottenuto %s',
            [LLine, LToken, LExpectedTokens[LToken], LActualTokens[LToken],
             UlpDistance(LExpectedBits, LActualBits), AExpected[LLine], AActual[LLine]]));
        end;
      end
      else
      begin
        if LExpectedTokens[LToken] <> LActualTokens[LToken] then
          Assert.Fail(Format('riga %d, token %d: atteso "%s", ottenuto "%s"' + sLineBreak +
            'atteso   %s' + sLineBreak + 'ottenuto %s',
            [LLine, LToken, LExpectedTokens[LToken], LActualTokens[LToken], AExpected[LLine],
             AActual[LLine]]));
      end;
    end;
  end;
end;

end.
