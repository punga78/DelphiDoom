{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the idLib ports - golden files and sample data         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.IdLib.Golden;

{$Q-}
{$R-}

interface

uses
  System.Classes;

type
  /// <summary>
  ///   Compares the lines a test computes with a file of Tests\Data\IdLib written by the real C++
  ///   idLib (see Tests\Data\IdLib\README.md). Lines are made of space separated tokens; a token
  ///   that starts with '#' is a 32-bit float written as eight hexadecimal digits of its bit
  ///   pattern and is compared with a tolerance in ULPs, every other token must be identical.
  /// </summary>
  TIdLibGolden = class
  private
    FLines: TStringList;
  public
    constructor Create(const AFileName: string);
    destructor Destroy; override;
    property Lines: TStringList read FLines;
    /// <summary>Keeps only the section that starts with the line "== name" (up to the next "== " line)</summary>
    procedure SelectSection(const AName: string);
    /// <summary>Keeps only the lines whose first token is one of the given ones</summary>
    procedure Select(const AFirstTokens: array of string);
    /// <summary>
    ///   Fails the test at the first line that differs from the golden file (or if the number of
    ///   lines differs); <c>AMaxUlps</c> is the tolerance of the '#' tokens
    /// </summary>
    procedure Compare(const AActual: TStrings; const AMaxUlps: Integer = 0); overload;
    /// <summary>
    ///   As above, but the tolerance applies only to the lines whose first token is one of 
    ///   <c>ALooseNames</c> (the results of the transcendental functions of the C library, which the
    ///   two compilers do not round the same way); every other line must be identical
    /// </summary>
    procedure Compare(const AActual: TStrings; const AMaxUlps: Integer; const ALooseNames: array of string;
      const AAbsTolerance: Single = 0); overload;
    /// <summary>The bit pattern of a float as a '#' token</summary>
    class function FloatToken(const AValue: Single): string; static;
    /// <summary>The full path of a file of Tests\Data\IdLib</summary>
    class function DataPath(const AFileName: string): string; static;
  end;

  /// <summary>Deterministic pseudo random numbers, the same as the harness of the C++ goldens</summary>
  TIdLibSampler = class
  private
    FState: Cardinal;
  public
    constructor Create(const ASeed: Cardinal);
    /// <summary>x = x * 1664525 + 1013904223; the byte is x shr 24</summary>
    function NextByte: Byte;
    /// <summary>A 32-bit value from the same generator</summary>
    function NextCardinal: Cardinal;
    /// <summary>A float in the range [-ARange, ARange) with 24 random bits</summary>
    function NextFloat(const ARange: Single): Single;
  end;

implementation

uses
  System.SysUtils, System.IOUtils, System.Math, DUnitX.TestFramework;

function BitsOf(const AValue: Single): Cardinal; inline;
begin
  Result := PCardinal(@AValue)^;
end;

function BitsToSingle(const ABits: Cardinal): Single; inline;
begin
  Result := PSingle(@ABits)^;
end;

function OrderedBits(const ABits: Cardinal): Int64;
begin
  // monotonic mapping of the IEEE bit patterns to integers, so that the distance is in ULPs
  if (ABits and $80000000) <> 0 then
    Result := -Int64(ABits and $7FFFFFFF)
  else
    Result := Int64(ABits);
end;

{ TIdLibGolden }

constructor TIdLibGolden.Create(const AFileName: string);
begin
  inherited Create;
  FLines := TStringList.Create;
  FLines.LoadFromFile(DataPath(AFileName));
end;

destructor TIdLibGolden.Destroy;
begin
  FLines.Free;
  inherited Destroy;
end;

procedure TIdLibGolden.SelectSection(const AName: string);
var
  LIndex, LStart, LEnd: Integer;
begin
  LStart := -1;
  LEnd := FLines.Count;
  for LIndex := 0 to FLines.Count - 1 do
    if FLines[LIndex] = '== ' + AName then
      LStart := LIndex
    else if (LStart >= 0) and (LIndex > LStart) and (Copy(FLines[LIndex], 1, 3) = '== ') then
    begin
      LEnd := LIndex;
      Break;
    end;
  Assert.IsTrue(LStart >= 0, 'sezione assente nel file golden: ' + AName);
  for LIndex := FLines.Count - 1 downto LEnd do
    FLines.Delete(LIndex);
  for LIndex := LStart - 1 downto 0 do
    FLines.Delete(LIndex);
end;

procedure TIdLibGolden.Select(const AFirstTokens: array of string);
var
  LIndex, LToken: Integer;
  LFirst: string;
  LKeep: Boolean;
begin
  for LIndex := FLines.Count - 1 downto 0 do
  begin
    LFirst := FLines[LIndex].Split([' '])[0];
    LKeep := False;
    for LToken := 0 to High(AFirstTokens) do
      if LFirst = AFirstTokens[LToken] then
        LKeep := True;
    if not LKeep then
      FLines.Delete(LIndex);
  end;
end;

class function TIdLibGolden.DataPath(const AFileName: string): string;
begin
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\Tests\Data\IdLib\' + AFileName));
end;

class function TIdLibGolden.FloatToken(const AValue: Single): string;
begin
  Result := '#' + LowerCase(IntToHex(BitsOf(AValue), 8));
end;

procedure TIdLibGolden.Compare(const AActual: TStrings; const AMaxUlps: Integer);
begin
  Compare(AActual, AMaxUlps, []);
end;

procedure TIdLibGolden.Compare(const AActual: TStrings; const AMaxUlps: Integer; const ALooseNames: array of string;
  const AAbsTolerance: Single);
var
  LIndex, LToken, LName, LUlps: Integer;
  LLoose: Boolean;
  LExpected, LActual: TArray<string>;
  LDistance: Int64;
begin
  for LIndex := 0 to FLines.Count - 1 do
  begin
    Assert.IsTrue(LIndex < AActual.Count, 'mancano righe: il golden ne ha ' + IntToStr(FLines.Count) +
      ', il calcolo ' + IntToStr(AActual.Count));
    if FLines[LIndex] = AActual[LIndex] then
      Continue;
    LExpected := FLines[LIndex].Split([' ']);
    LActual := AActual[LIndex].Split([' ']);
    LLoose := Length(ALooseNames) = 0;
    for LName := 0 to High(ALooseNames) do
      if LExpected[0] = ALooseNames[LName] then
        LLoose := True;
    if LLoose then
      LUlps := AMaxUlps
    else
      LUlps := 0;
    Assert.AreEqual(Length(LExpected), Length(LActual), Format('riga %d: attesa "%s", ottenuta "%s"',
      [LIndex + 1, FLines[LIndex], AActual[LIndex]]));
    for LToken := 0 to High(LExpected) do
    begin
      if LExpected[LToken] = LActual[LToken] then
        Continue;
      if (LUlps > 0) and (Length(LExpected[LToken]) = 9) and (LExpected[LToken][1] = '#') and
        (Length(LActual[LToken]) = 9) and (LActual[LToken][1] = '#') then
      begin
        LDistance := Abs(OrderedBits(Cardinal(StrToInt64('$' + Copy(LExpected[LToken], 2, 8)))) -
          OrderedBits(Cardinal(StrToInt64('$' + Copy(LActual[LToken], 2, 8)))));
        if LDistance <= LUlps then
          Continue;
        // a result that is almost zero (sin of 2*pi) can be far in ULPs and close in value
        if LLoose and (AAbsTolerance > 0) and (System.Abs(BitsToSingle(Cardinal(StrToInt64('$' + Copy(LExpected[LToken], 2, 8)))) -
          BitsToSingle(Cardinal(StrToInt64('$' + Copy(LActual[LToken], 2, 8))))) <= AAbsTolerance) then
          Continue;
      end;
      Assert.Fail(Format('riga %d: attesa "%s", ottenuta "%s"', [LIndex + 1, FLines[LIndex], AActual[LIndex]]));
    end;
  end;
  Assert.AreEqual(FLines.Count, AActual.Count, 'il calcolo ha righe in piu'' del golden');
end;

{ TIdLibSampler }

constructor TIdLibSampler.Create(const ASeed: Cardinal);
begin
  inherited Create;
  FState := ASeed;
end;

function TIdLibSampler.NextCardinal: Cardinal;
begin
  FState := FState * 1664525 + 1013904223;
  Result := FState;
end;

function TIdLibSampler.NextByte: Byte;
begin
  Result := Byte(NextCardinal shr 24);
end;

function TIdLibSampler.NextFloat(const ARange: Single): Single;
var
  LBits: Cardinal;
begin
  LBits := NextCardinal shr 8;
  Result := ((LBits / 8388608.0) - 1.0) * ARange;
end;

end.
