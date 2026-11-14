{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D models library - the MD5 golden file            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.Md5Golden;

interface

uses
  System.Classes,
  System.SysUtils,
  System.Generics.Collections;

/// <summary>Assert.AreEqual of two values with a tolerance (the generic one does not take it)</summary>
procedure CheckNear(const AExpected, AActual, ATolerance: Double; const AMessage: string = '');

/// <summary>All the occurrences of AOld in an 8-bit text replaced by ANew</summary>
function Replace8(const AText, AOld, ANew: AnsiString): AnsiString;

type
  /// <summary>
  ///   Tests\Data\Models\md5\cube.golden.txt: the output of the real idTech 4 classes (see
  ///   Tests\Data\Models\md5\README.md). A line is "key args | values": a value is a float as the
  ///   bits of a Single ("#3f800000") or an integer.
  /// </summary>
  TMd5Golden = class
  strict private
    FLines: TDictionary<string, TArray<string>>;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>The floats of a line (the tokens that start with #); fails the test if the key is not there</summary>
    function Floats(const AKey: string): TArray<Single>;
    /// <summary>The integers of a line (the tokens without #)</summary>
    function Ints(const AKey: string): TArray<Integer>;
    function Has(const AKey: string): Boolean;
    /// <summary>The text of a file of Tests\Data\Models\md5 as an 8-bit string</summary>
    class function ReadText(const AFileName: string): AnsiString; static;
    /// <summary>
    ///   Two floats are the same when they differ by 2 ULP, or by 4e-6 relative, or by 1e-5
    ///   absolute (the C++ rounds every operation to float, Delphi x87 keeps the expression in a
    ///   register: sums that cancel change the last bits)
    /// </summary>
    class function Close(const AExpected, AActual: Single): Boolean; static;
    class function Describe(const AValue: Single): string; static;
  end;

implementation

uses
  System.IOUtils,
  System.Math,
  DUnitX.TestFramework;

function BitsOf(const AValue: Single): Cardinal;
begin
  Result := PCardinal(@AValue)^;
end;

procedure CheckNear(const AExpected, AActual, ATolerance: Double; const AMessage: string);
begin
  Assert.AreEqual(AExpected, AActual, ATolerance, AMessage);
end;

function Replace8(const AText, AOld, ANew: AnsiString): AnsiString;
begin
  Result := AnsiString(StringReplace(string(AText), string(AOld), string(ANew), [rfReplaceAll]));
end;

{ TMd5Golden }

constructor TMd5Golden.Create;
var
  LLines: TStringList;
  LLine, LKey, LRest: string;
  LPos: Integer;
begin
  inherited Create;
  FLines := TDictionary<string, TArray<string>>.Create;
  LLines := TStringList.Create;
  try
    LLines.LoadFromFile(TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
      '..\..\..\..\Tests\Data\Models\md5\cube.golden.txt')));
    for LLine in LLines do
    begin
      LPos := Pos(' |', LLine);
      if LPos = 0 then
        Continue;
      LKey := Copy(LLine, 1, LPos - 1);
      LRest := Trim(Copy(LLine, LPos + 2, MaxInt));
      FLines.AddOrSetValue(LKey, LRest.Split([' '], TStringSplitOptions.ExcludeEmpty));
    end;
  finally
    LLines.Free;
  end;
end;

destructor TMd5Golden.Destroy;
begin
  FLines.Free;
  inherited Destroy;
end;

function TMd5Golden.Has(const AKey: string): Boolean;
begin
  Result := FLines.ContainsKey(AKey);
end;

function TMd5Golden.Floats(const AKey: string): TArray<Single>;
var
  LTokens: TArray<string>;
  LToken: string;
  LBits: Cardinal;
  LCount: Integer;
begin
  Assert.IsTrue(FLines.TryGetValue(AKey, LTokens), 'chiave assente nel file golden: ' + AKey);
  SetLength(Result, Length(LTokens));
  LCount := 0;
  for LToken in LTokens do
    if Copy(LToken, 1, 1) = '#' then
    begin
      LBits := StrToUInt('$' + Copy(LToken, 2, 8));
      Result[LCount] := PSingle(@LBits)^;
      Inc(LCount);
    end;
  SetLength(Result, LCount);
end;

function TMd5Golden.Ints(const AKey: string): TArray<Integer>;
var
  LTokens: TArray<string>;
  LToken: string;
  LCount: Integer;
begin
  Assert.IsTrue(FLines.TryGetValue(AKey, LTokens), 'chiave assente nel file golden: ' + AKey);
  SetLength(Result, Length(LTokens));
  LCount := 0;
  for LToken in LTokens do
    if Copy(LToken, 1, 1) <> '#' then
    begin
      Result[LCount] := StrToInt(LToken);
      Inc(LCount);
    end;
  SetLength(Result, LCount);
end;
class function TMd5Golden.ReadText(const AFileName: string): AnsiString;
var
  LBytes: TBytes;
begin
  LBytes := TFile.ReadAllBytes(TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\..\..\Tests\Data\Models\md5\' + AFileName)));
  SetString(Result, PAnsiChar(@LBytes[0]), Length(LBytes));
end;

class function TMd5Golden.Close(const AExpected, AActual: Single): Boolean;
var
  LDifference: Single;
  LUlps: Int64;
begin
  if IsNan(AExpected) or IsNan(AActual) then
    Exit(IsNan(AExpected) and IsNan(AActual));
  if AExpected = AActual then
    Exit(True);
  LDifference := Abs(AExpected - AActual);
  if LDifference <= 1E-5 then
    Exit(True);
  if LDifference <= 4E-6 * Max(Abs(AExpected), Abs(AActual)) then
    Exit(True);
  LUlps := Abs(Int64(Integer(BitsOf(AExpected))) - Int64(Integer(BitsOf(AActual))));
  Result := LUlps <= 2;
end;

class function TMd5Golden.Describe(const AValue: Single): string;
begin
  Result := FloatToStr(AValue) + ' (#' + IntToHex(BitsOf(AValue), 8) + ')';
end;

end.
