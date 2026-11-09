{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - shared types, constants and the sorted    }
{  string map                                                                   }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.Types;

interface

uses
  System.SysUtils, System.Generics.Collections;

type
  /// <summary>Base of the errors of the ruleset library (the Exception of OpenXcom that a rule throws)</summary>
  EXcomModException = class(Exception);

  /// <summary>
  ///   std::map&lt;std::string, V&gt;: the pairs in the order of the keys (byte order of the UTF-8
  ///   text, as std::string compares), an existing key keeps its place and takes the new value
  /// </summary>
  TXcomStringMap<V> = class
  strict private
    FKeys: TList<string>;
    FValues: TList<V>;
    function Find(const AKey: string; out AIndex: Integer): Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    function Count: Integer;
    procedure Clear;
    /// <summary>map[key] = value</summary>
    procedure SetValue(const AKey: string; const AValue: V);
    function Key(AIndex: Integer): string;
    function Value(AIndex: Integer): V;
    function TryGetValue(const AKey: string; out AValue: V): Boolean;
    function ContainsKey(const AKey: string): Boolean;
    /// <summary>erase</summary>
    procedure Remove(const AKey: string);
    /// <summary>A new map with the same pairs (the caller frees it)</summary>
    function Copy: TXcomStringMap<V>;
  end;

  /// <summary>std::string::compare: byte order of the UTF-8 text</summary>
function XcomCompareUtf8(const AFirst, ASecond: string): Integer;

implementation

function XcomCompareUtf8(const AFirst, ASecond: string): Integer;
var
  LFirst, LSecond: TBytes;
  LIndex, LCommon: Integer;
begin
  LFirst := TEncoding.UTF8.GetBytes(AFirst);
  LSecond := TEncoding.UTF8.GetBytes(ASecond);
  LCommon := Length(LFirst);
  if Length(LSecond) < LCommon then
    LCommon := Length(LSecond);
  for LIndex := 0 to LCommon - 1 do
    if LFirst[LIndex] <> LSecond[LIndex] then
      Exit(Integer(LFirst[LIndex]) - Integer(LSecond[LIndex]));
  Result := Length(LFirst) - Length(LSecond);
end;

{ TXcomStringMap<V> }

constructor TXcomStringMap<V>.Create;
begin
  inherited Create;
  FKeys := TList<string>.Create;
  FValues := TList<V>.Create;
end;

destructor TXcomStringMap<V>.Destroy;
begin
  FKeys.Free;
  FValues.Free;
  inherited Destroy;
end;

function TXcomStringMap<V>.Find(const AKey: string; out AIndex: Integer): Boolean;
var
  LLow, LHigh, LMiddle, LCompare: Integer;
begin
  LLow := 0;
  LHigh := FKeys.Count - 1;
  while LLow <= LHigh do
  begin
    LMiddle := (LLow + LHigh) div 2;
    LCompare := XcomCompareUtf8(FKeys[LMiddle], AKey);
    if LCompare = 0 then
    begin
      AIndex := LMiddle;
      Exit(True);
    end;
    if LCompare < 0 then
      LLow := LMiddle + 1
    else
      LHigh := LMiddle - 1;
  end;
  AIndex := LLow;
  Result := False;
end;

function TXcomStringMap<V>.Count: Integer;
begin
  Result := FKeys.Count;
end;

procedure TXcomStringMap<V>.Clear;
begin
  FKeys.Clear;
  FValues.Clear;
end;

procedure TXcomStringMap<V>.SetValue(const AKey: string; const AValue: V);
var
  LIndex: Integer;
begin
  if Find(AKey, LIndex) then
    FValues[LIndex] := AValue
  else
  begin
    FKeys.Insert(LIndex, AKey);
    FValues.Insert(LIndex, AValue);
  end;
end;

function TXcomStringMap<V>.Key(AIndex: Integer): string;
begin
  Result := FKeys[AIndex];
end;

function TXcomStringMap<V>.Value(AIndex: Integer): V;
begin
  Result := FValues[AIndex];
end;

function TXcomStringMap<V>.TryGetValue(const AKey: string; out AValue: V): Boolean;
var
  LIndex: Integer;
begin
  Result := Find(AKey, LIndex);
  if Result then
    AValue := FValues[LIndex];
end;

function TXcomStringMap<V>.ContainsKey(const AKey: string): Boolean;
var
  LIndex: Integer;
begin
  Result := Find(AKey, LIndex);
end;

procedure TXcomStringMap<V>.Remove(const AKey: string);
var
  LIndex: Integer;
begin
  if Find(AKey, LIndex) then
  begin
    FKeys.Delete(LIndex);
    FValues.Delete(LIndex);
  end;
end;

function TXcomStringMap<V>.Copy: TXcomStringMap<V>;
begin
  Result := TXcomStringMap<V>.Create;
  Result.FKeys.AddRange(FKeys);
  Result.FValues.AddRange(FValues);
end;

end.
