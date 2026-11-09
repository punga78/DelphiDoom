{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom ruleset library - the text dump of a      }
{  ruleset, line by line like Tools\Verifica\176\mod\dump_common.h              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomMod.DumpWriter;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.XcomMod.Types, DelphiDoom.XcomMod.UnitStats;

type
  /// <summary>Collects the lines "section|name|field=value" that the C++ harness (modload) prints</summary>
  TXcomDumpWriter = class
  strict private
    FLines: TStringList;
    FSection: string;
    FName: string;
  public
    constructor Create;
    destructor Destroy; override;
    class function Escape(const AText: string): string; static;
    class function Quote(const AText: string): string; static;
    class function HexDouble(AValue: Double): string; static;
    class function HexSingle(AValue: Single): string; static;
    class function QuoteList(const AValues: TArray<string>): string; static;
    class function IntList(const AValues: TArray<Integer>): string; static;
    class function DoubleList(const AValues: TArray<Double>): string; static;
    /// <summary>The eleven stats as numbers separated by /</summary>
    class function StatsText(const AStats: TXcomUnitStats): string; static;
    procedure Begin_(const ASection, AName: string);
    procedure Line(const AKey, AValue: string);
    procedure Int(const AKey: string; AValue: Integer);
    procedure Card(const AKey: string; AValue: Cardinal);
    procedure Bool(const AKey: string; AValue: Boolean);
    procedure Dbl(const AKey: string; AValue: Double);
    procedure Sgl(const AKey: string; AValue: Single);
    procedure Str(const AKey, AValue: string);
    procedure Strs(const AKey: string; const AValues: TArray<string>);
    procedure Ints(const AKey: string; const AValues: TArray<Integer>);
    procedure Dbls(const AKey: string; const AValues: TArray<Double>);
    procedure IntMap(const AKey: string; const AValues: TXcomStringMap<Integer>);
    procedure CardMap(const AKey: string; const AValues: TXcomStringMap<Cardinal>);
    property Lines: TStringList read FLines;
  end;

implementation

{ TXcomDumpWriter }

constructor TXcomDumpWriter.Create;
begin
  inherited Create;
  FLines := TStringList.Create;
end;

destructor TXcomDumpWriter.Destroy;
begin
  FLines.Free;
  inherited Destroy;
end;

class function TXcomDumpWriter.Escape(const AText: string): string;
var
  LBytes: TBytes;
  LByte: Byte;
begin
  Result := '';
  LBytes := TEncoding.UTF8.GetBytes(AText);
  for LByte in LBytes do
    case LByte of
      Ord('\'): Result := Result + '\\';
      10: Result := Result + '\n';
      Ord('|'): Result := Result + '\x7C';
    else
      if (LByte < 32) or (LByte >= 127) then
        Result := Result + '\x' + IntToHex(LByte, 2)
      else
        Result := Result + Char(LByte);
    end;
end;

class function TXcomDumpWriter.Quote(const AText: string): string;
begin
  Result := '''' + Escape(AText) + '''';
end;

class function TXcomDumpWriter.HexDouble(AValue: Double): string;
begin
  Result := IntToHex(PUInt64(@AValue)^, 16);
end;

class function TXcomDumpWriter.HexSingle(AValue: Single): string;
begin
  Result := IntToHex(PCardinal(@AValue)^, 8);
end;

class function TXcomDumpWriter.QuoteList(const AValues: TArray<string>): string;
var
  LIndex: Integer;
begin
  Result := '[';
  for LIndex := 0 to High(AValues) do
  begin
    if LIndex > 0 then
      Result := Result + ',';
    Result := Result + Quote(AValues[LIndex]);
  end;
  Result := Result + ']';
end;

class function TXcomDumpWriter.IntList(const AValues: TArray<Integer>): string;
var
  LIndex: Integer;
begin
  Result := '[';
  for LIndex := 0 to High(AValues) do
  begin
    if LIndex > 0 then
      Result := Result + ',';
    Result := Result + IntToStr(AValues[LIndex]);
  end;
  Result := Result + ']';
end;

class function TXcomDumpWriter.DoubleList(const AValues: TArray<Double>): string;
var
  LIndex: Integer;
begin
  Result := '[';
  for LIndex := 0 to High(AValues) do
  begin
    if LIndex > 0 then
      Result := Result + ',';
    Result := Result + HexDouble(AValues[LIndex]);
  end;
  Result := Result + ']';
end;

class function TXcomDumpWriter.StatsText(const AStats: TXcomUnitStats): string;
begin
  Result := Format('%d/%d/%d/%d/%d/%d/%d/%d/%d/%d/%d', [AStats.TimeUnits, AStats.Stamina, AStats.Health,
    AStats.Bravery, AStats.Reactions, AStats.Firing, AStats.Throwing, AStats.Strength, AStats.PsiStrength,
    AStats.PsiSkill, AStats.Melee]);
end;

procedure TXcomDumpWriter.Begin_(const ASection, AName: string);
begin
  FSection := ASection;
  FName := Escape(AName);
end;

procedure TXcomDumpWriter.Line(const AKey, AValue: string);
begin
  FLines.Add(FSection + '|' + FName + '|' + AKey + '=' + AValue);
end;

procedure TXcomDumpWriter.Int(const AKey: string; AValue: Integer);
begin
  Line(AKey, IntToStr(AValue));
end;

procedure TXcomDumpWriter.Card(const AKey: string; AValue: Cardinal);
begin
  Line(AKey, UIntToStr(AValue));
end;

procedure TXcomDumpWriter.Bool(const AKey: string; AValue: Boolean);
begin
  Line(AKey, IntToStr(Ord(AValue)));
end;

procedure TXcomDumpWriter.Dbl(const AKey: string; AValue: Double);
begin
  Line(AKey, HexDouble(AValue));
end;

procedure TXcomDumpWriter.Sgl(const AKey: string; AValue: Single);
begin
  Line(AKey, HexSingle(AValue));
end;

procedure TXcomDumpWriter.Str(const AKey, AValue: string);
begin
  Line(AKey, Quote(AValue));
end;

procedure TXcomDumpWriter.Strs(const AKey: string; const AValues: TArray<string>);
begin
  Line(AKey, QuoteList(AValues));
end;

procedure TXcomDumpWriter.Ints(const AKey: string; const AValues: TArray<Integer>);
begin
  Line(AKey, IntList(AValues));
end;

procedure TXcomDumpWriter.Dbls(const AKey: string; const AValues: TArray<Double>);
begin
  Line(AKey, DoubleList(AValues));
end;

procedure TXcomDumpWriter.IntMap(const AKey: string; const AValues: TXcomStringMap<Integer>);
var
  LIndex: Integer;
  LText: string;
begin
  LText := '{';
  for LIndex := 0 to AValues.Count - 1 do
  begin
    if LIndex > 0 then
      LText := LText + ',';
    LText := LText + Quote(AValues.Key(LIndex)) + ':' + IntToStr(AValues.Value(LIndex));
  end;
  Line(AKey, LText + '}');
end;

procedure TXcomDumpWriter.CardMap(const AKey: string; const AValues: TXcomStringMap<Cardinal>);
var
  LIndex: Integer;
  LText: string;
begin
  LText := '{';
  for LIndex := 0 to AValues.Count - 1 do
  begin
    if LIndex > 0 then
      LText := LText + ',';
    LText := LText + Quote(AValues.Key(LIndex)) + ':' + UIntToStr(AValues.Value(LIndex));
  end;
  Line(AKey, LText + '}');
end;

end.
