{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the math core library - lines of the golden files of    }
{  the C++ idLib ("name inputs | outputs", floats written as #bits)            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MathCore.GoldenLines;

{$Q-}
{$R-}

interface

uses
  System.Classes;

type
  /// <summary>Reads the tokens of a line of a golden file: floats as #bits, integers, names</summary>
  TGoldenLineReader = record
    Tokens: TArray<string>;
    Position: Integer;
    /// <summary>Starts reading a line after its first token (the name)</summary>
    procedure Start(const ALine: string);
    function Float: Single;
    function Int: Integer;
    /// <summary>Skips the "|" separator</summary>
    procedure SkipBar;
  end;

  /// <summary>Writes and compares the lines the tests compute</summary>
  TGoldenLines = class sealed
  public
    class function BitsToSingle(const AToken: string): Single; static;
    /// <summary>The line up to and including its "|"</summary>
    class function HeadOf(const ALine: string): string; static;
    class procedure PutFloat(var ALine: string; const AValue: Single); static;
    class procedure PutInt(var ALine: string; const AValue: Integer); static;
    class procedure PutBool(var ALine: string; const AValue: Boolean); static;
    /// <summary>
    ///   Fails at the first token that differs. A float token is accepted if it is at most
    ///   <c>AMaxUlps</c> ULPs away, or within a relative error of 4e-6 (or the absolute one
    ///   <c>AAbsTolerance</c>, for results of a cancellation); two NaNs are equal; every other
    ///   token must be identical.
    /// </summary>
    class procedure Compare(const AExpected, AActual: TStrings; const AMaxUlps: Integer;
      const AAbsTolerance: Single); static;
  end;

implementation

uses
  System.SysUtils, System.Math, DUnitX.TestFramework, DelphiDoom.Tests.IdLib.Golden;

function OrderedBits(const ABits: Cardinal): Int64;
begin
  if (ABits and $80000000) <> 0 then
    Result := -Int64(ABits and $7FFFFFFF)
  else
    Result := Int64(ABits);
end;

function IsNaNBits(const ABits: Cardinal): Boolean;
begin
  Result := ((ABits and $7F800000) = $7F800000) and ((ABits and $007FFFFF) <> 0);
end;

function UlpDistance(const A, B: Cardinal): Int64;
begin
  Result := System.Abs(OrderedBits(A) - OrderedBits(B));
end;

{ TGoldenLineReader }

procedure TGoldenLineReader.Start(const ALine: string);
begin
  Tokens := ALine.Split([' ']);
  Position := 1;
end;

function TGoldenLineReader.Float: Single;
begin
  Result := TGoldenLines.BitsToSingle(Tokens[Position]);
  Inc(Position);
end;

function TGoldenLineReader.Int: Integer;
begin
  Result := StrToInt(Tokens[Position]);
  Inc(Position);
end;

procedure TGoldenLineReader.SkipBar;
begin
  Assert.AreEqual('|', Tokens[Position], 'separatore atteso');
  Inc(Position);
end;

{ TGoldenLines }

class function TGoldenLines.BitsToSingle(const AToken: string): Single;
var
  LBits: Cardinal;
begin
  LBits := Cardinal(StrToInt64('$' + Copy(AToken, 2, 8)));
  Result := PSingle(@LBits)^;
end;

class function TGoldenLines.HeadOf(const ALine: string): string;
begin
  Result := Copy(ALine, 1, Pos('|', ALine));
end;

class procedure TGoldenLines.PutFloat(var ALine: string; const AValue: Single);
begin
  ALine := ALine + ' ' + TIdLibGolden.FloatToken(AValue);
end;

class procedure TGoldenLines.PutInt(var ALine: string; const AValue: Integer);
begin
  ALine := ALine + ' ' + IntToStr(AValue);
end;

class procedure TGoldenLines.PutBool(var ALine: string; const AValue: Boolean);
begin
  if AValue then
    ALine := ALine + ' 1'
  else
    ALine := ALine + ' 0';
end;

class procedure TGoldenLines.Compare(const AExpected, AActual: TStrings; const AMaxUlps: Integer;
  const AAbsTolerance: Single);
var
  LLine, LToken: Integer;
  LExpectedTokens, LActualTokens: TArray<string>;
  LExpectedBits, LActualBits: Cardinal;
  LExpected, LActual: Single;
  LRelative: Double;
begin
  Assert.AreEqual(AExpected.Count, AActual.Count, 'numero di righe');
  for LLine := 0 to AExpected.Count - 1 do
  begin
    LExpectedTokens := AExpected[LLine].Split([' ']);
    LActualTokens := AActual[LLine].Split([' ']);
    Assert.AreEqual(Length(LExpectedTokens), Length(LActualTokens), 'numero di token' + sLineBreak +
      'atteso   ' + AExpected[LLine] + sLineBreak + 'ottenuto ' + AActual[LLine]);
    for LToken := 0 to Integer(Length(LExpectedTokens)) - 1 do
    begin
      if (LExpectedTokens[LToken] <> '') and (LExpectedTokens[LToken][1] = '#') then
      begin
        LExpectedBits := Cardinal(StrToInt64('$' + Copy(LExpectedTokens[LToken], 2, 8)));
        LActualBits := Cardinal(StrToInt64('$' + Copy(LActualTokens[LToken], 2, 8)));
        if IsNaNBits(LExpectedBits) and IsNaNBits(LActualBits) then
          Continue;
        if UlpDistance(LExpectedBits, LActualBits) <= AMaxUlps then
          Continue;
        LExpected := BitsToSingle(LExpectedTokens[LToken]);
        LActual := BitsToSingle(LActualTokens[LToken]);
        // the C++ is compiled by clang (each float operation rounded), Delphi keeps an expression
        // in the x87 registers: tolerance of a relative error of 4e-6 (or the absolute one)
        LRelative := 4E-6 * Max(Double(1.0), Double(System.Abs(LExpected)));
        if System.Abs(LActual - LExpected) <= Max(Double(AAbsTolerance), LRelative) then
          Continue;
        Assert.Fail(Format('riga %d, token %d: atteso %s, ottenuto %s (%d ULP)' + sLineBreak +
          'atteso   %s' + sLineBreak + 'ottenuto %s', [LLine, LToken, LExpectedTokens[LToken],
          LActualTokens[LToken], UlpDistance(LExpectedBits, LActualBits), AExpected[LLine],
          AActual[LLine]]));
      end
      else if LExpectedTokens[LToken] <> LActualTokens[LToken] then
        Assert.Fail(Format('riga %d, token %d: atteso %s, ottenuto %s' + sLineBreak +
          'atteso   %s' + sLineBreak + 'ottenuto %s', [LLine, LToken, LExpectedTokens[LToken],
          LActualTokens[LToken], AExpected[LLine], AActual[LLine]]));
    end;
  end;
end;

end.
