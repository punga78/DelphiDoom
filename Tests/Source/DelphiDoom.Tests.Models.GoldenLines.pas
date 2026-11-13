{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D models library - golden files of lines          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.GoldenLines;

interface

uses
  System.SysUtils,
  System.Generics.Collections;

type
  /// <summary>
  ///   A golden file of the harnesses (Tests\Data\Models\...): a line is "key | values", a value
  ///   is a float as the bits of a Single ("#3f800000"), an integer or a word.
  /// </summary>
  TGoldenLines = class
  strict private
    FLines: TDictionary<string, TArray<string>>;
  public
    /// <summary>The file is relative to Tests\Data\Models (for example 'deform\deform.golden.txt')</summary>
    constructor Create(const ARelativeFile: string);
    destructor Destroy; override;
    function Has(const AKey: string): Boolean;
    /// <summary>The floats of a line (the values that start with #); fails the test if the key is not there</summary>
    function Floats(const AKey: string): TArray<Single>;
    /// <summary>The integers of a line (the values that are not floats)</summary>
    function Ints(const AKey: string): TArray<Integer>;
    /// <summary>The integers of a line as 64-bit values (colours are unsigned 32-bit)</summary>
    function Int64s(const AKey: string): TArray<Int64>;
    /// <summary>All the values of a line as they are written</summary>
    function Tokens(const AKey: string): TArray<string>;
  end;

implementation

uses
  System.Classes,
  System.IOUtils,
  DUnitX.TestFramework;

{ TGoldenLines }

constructor TGoldenLines.Create(const ARelativeFile: string);
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
      '..\..\Tests\Data\Models\' + ARelativeFile)));
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

destructor TGoldenLines.Destroy;
begin
  FLines.Free;
  inherited Destroy;
end;

function TGoldenLines.Has(const AKey: string): Boolean;
begin
  Result := FLines.ContainsKey(AKey);
end;

function TGoldenLines.Tokens(const AKey: string): TArray<string>;
begin
  Assert.IsTrue(FLines.TryGetValue(AKey, Result), 'chiave assente nel file golden: ' + AKey);
end;

function TGoldenLines.Floats(const AKey: string): TArray<Single>;
var
  LToken: string;
  LBits: Cardinal;
  LCount: Integer;
  LTokens: TArray<string>;
begin
  LTokens := Tokens(AKey);
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

function TGoldenLines.Int64s(const AKey: string): TArray<Int64>;
var
  LToken: string;
  LCount: Integer;
  LTokens: TArray<string>;
begin
  LTokens := Tokens(AKey);
  SetLength(Result, Length(LTokens));
  LCount := 0;
  for LToken in LTokens do
    if Copy(LToken, 1, 1) <> '#' then
    begin
      Result[LCount] := StrToInt64(LToken);
      Inc(LCount);
    end;
  SetLength(Result, LCount);
end;

function TGoldenLines.Ints(const AKey: string): TArray<Integer>;
var
  LToken: string;
  LCount: Integer;
  LTokens: TArray<string>;
begin
  LTokens := Tokens(AKey);
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

end.
