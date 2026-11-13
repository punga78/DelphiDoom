{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the geometry library - golden file of the C++ idLib    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Geometry.Golden;

{$Q-}
{$R-}

interface

uses
  System.Classes, System.Generics.Collections,
  DelphiDoom.IdLib.Math.Vec2, DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Mat3, DelphiDoom.Geometry.Plane,
  DelphiDoom.Geometry.DrawVert;

type
  /// <summary>Reads the tokens of a golden line: floats written as #bits, integers in decimal</summary>
  TGeoGoldenReader = record
  strict private
    FTokens: TArray<string>;
    FPosition: Integer;
  public
    /// <summary>Splits the line; the name (first token) is skipped</summary>
    class function Open(const ALine: string): TGeoGoldenReader; static;
    function Float: Single;
    function Int: Integer;
    function UInt: System.Cardinal;
    function Flag: Boolean;
    function Vec3: TGeoVec3;
    function Vec2: TIdVec2;
    function Mat3: TGeoMat3;
    function Plane: TGeoPlane;
    /// <summary>Position, texture, normal, two tangents and the colour as one number</summary>
    function DrawVert: TGeoDrawVert;
    /// <summary>Position, texture and normal only (the other fields are not defined by the C++)</summary>
    function DrawVertShort: TGeoDrawVert;
    function Done: Boolean;
  end;

  /// <summary>Writes the tokens of the output of a recomputed line in the format of the golden file</summary>
  TGeoGoldenWriter = class
  strict private
    FText: string;
  public
    procedure Float(AValue: Single);
    procedure Int(AValue: Integer);
    procedure UInt(AValue: System.Cardinal);
    procedure Flag(AValue: Boolean);
    procedure Vec3(const AValue: TGeoVec3);
    procedure Vec2(const AValue: TIdVec2);
    procedure Mat3(const AValue: TGeoMat3);
    procedure Plane(const AValue: TGeoPlane);
    procedure DrawVert(const AValue: TGeoDrawVert);
    procedure DrawVertShort(const AValue: TGeoDrawVert);
    property Text: string read FText;
  end;

  /// <summary>The lines of a file of Tests\Data\Geometry and the comparison with the recomputed output</summary>
  TGeoGolden = class
  public
    /// <summary>The full path of a file of Tests\Data\Geometry (relative to the folder of the executable)</summary>
    class function DataPath(const AFileName: string): string; static;
    /// <summary>The lines whose first token is one of the names, in file order</summary>
    class function Load(const AFileName: string; const ANames: array of string): TStringList; static;
    /// <summary>
    ///   Fails when the outputs (the tokens after the bar) differ: integers must be identical, floats
    ///   (tokens "#xxxxxxxx") must be within AMaxUlps, or a relative error of 4e-6, or AAbsTolerance
    /// </summary>
    class procedure CompareOutput(const ALine, AActualOutput: string; AMaxUlps: Integer = 2;
      AAbsTolerance: Single = 1E-4); static;
    class function InputsOf(const ALine: string): string; static;
    /// <summary>The bits of a float as a golden token</summary>
    class function FloatToken(AValue: Single): string; static;
    class function TokenToFloat(const AToken: string): Single; static;
  end;

/// <summary>Fails when two floats differ by more than the tolerance</summary>
procedure AssertNear(AExpected, AActual, ATolerance: Single);

implementation

uses
  System.SysUtils, System.IOUtils, System.Math, DUnitX.TestFramework;

function OrderedBits(ABits: System.Cardinal): Int64;
begin
  // monotonic mapping of the IEEE bit patterns to integers, so that the distance is in ULPs
  if (ABits and $80000000) <> 0 then
    Result := -Int64(ABits and $7FFFFFFF)
  else
    Result := Int64(ABits);
end;

procedure AssertNear(AExpected, AActual, ATolerance: Single);
begin
  Assert.IsTrue(Abs(AExpected - AActual) <= ATolerance, Format('atteso %g, ottenuto %g (tolleranza %g)',
    [AExpected, AActual, ATolerance]));
end;

{ TGeoGoldenReader }

class function TGeoGoldenReader.Open(const ALine: string): TGeoGoldenReader;
begin
  Result.FTokens := ALine.Split([' ']);
  Result.FPosition := 1;
end;

function TGeoGoldenReader.Float: Single;
begin
  Result := TGeoGolden.TokenToFloat(FTokens[FPosition]);
  Inc(FPosition);
end;

function TGeoGoldenReader.Int: Integer;
begin
  Result := StrToInt(FTokens[FPosition]);
  Inc(FPosition);
end;

function TGeoGoldenReader.UInt: System.Cardinal;
begin
  Result := System.Cardinal(StrToInt64(FTokens[FPosition]));
  Inc(FPosition);
end;

function TGeoGoldenReader.Flag: Boolean;
begin
  Result := Int <> 0;
end;

function TGeoGoldenReader.Vec3: TGeoVec3;
begin
  Result.X := Float;
  Result.Y := Float;
  Result.Z := Float;
end;

function TGeoGoldenReader.Vec2: TIdVec2;
begin
  Result.X := Float;
  Result.Y := Float;
end;

function TGeoGoldenReader.Mat3: TGeoMat3;
begin
  Result.Rows[0] := Vec3;
  Result.Rows[1] := Vec3;
  Result.Rows[2] := Vec3;
end;

function TGeoGoldenReader.Plane: TGeoPlane;
begin
  Result.A := Float;
  Result.B := Float;
  Result.C := Float;
  Result.D := Float;
end;

function TGeoGoldenReader.DrawVert: TGeoDrawVert;
begin
  Result.Xyz := Vec3;
  Result.St := Vec2;
  Result.Normal := Vec3;
  Result.Tangents[0] := Vec3;
  Result.Tangents[1] := Vec3;
  Result.SetColor(UInt);
end;

function TGeoGoldenReader.DrawVertShort: TGeoDrawVert;
begin
  Result.Clear;
  Result.Xyz := Vec3;
  Result.St := Vec2;
  Result.Normal := Vec3;
end;

function TGeoGoldenReader.Done: Boolean;
begin
  Result := FPosition >= Length(FTokens);
end;

{ TGeoGoldenWriter }

procedure TGeoGoldenWriter.Float(AValue: Single);
begin
  FText := FText + ' ' + TGeoGolden.FloatToken(AValue);
end;

procedure TGeoGoldenWriter.Int(AValue: Integer);
begin
  FText := FText + ' ' + IntToStr(AValue);
end;

procedure TGeoGoldenWriter.UInt(AValue: System.Cardinal);
begin
  FText := FText + ' ' + UIntToStr(AValue);
end;

procedure TGeoGoldenWriter.Flag(AValue: Boolean);
begin
  if AValue then
    FText := FText + ' 1'
  else
    FText := FText + ' 0';
end;

procedure TGeoGoldenWriter.Vec3(const AValue: TGeoVec3);
begin
  Float(AValue.X);
  Float(AValue.Y);
  Float(AValue.Z);
end;

procedure TGeoGoldenWriter.Vec2(const AValue: TIdVec2);
begin
  Float(AValue.X);
  Float(AValue.Y);
end;

procedure TGeoGoldenWriter.Mat3(const AValue: TGeoMat3);
var
  LRow: Integer;
begin
  for LRow := 0 to 2 do
    Vec3(AValue.Rows[LRow]);
end;

procedure TGeoGoldenWriter.Plane(const AValue: TGeoPlane);
begin
  Float(AValue.A);
  Float(AValue.B);
  Float(AValue.C);
  Float(AValue.D);
end;

procedure TGeoGoldenWriter.DrawVert(const AValue: TGeoDrawVert);
begin
  Vec3(AValue.Xyz);
  Vec2(AValue.St);
  Vec3(AValue.Normal);
  Vec3(AValue.Tangents[0]);
  Vec3(AValue.Tangents[1]);
  UInt(AValue.GetColor);
end;

procedure TGeoGoldenWriter.DrawVertShort(const AValue: TGeoDrawVert);
begin
  Vec3(AValue.Xyz);
  Vec2(AValue.St);
  Vec3(AValue.Normal);
end;

{ TGeoGolden }

class function TGeoGolden.DataPath(const AFileName: string): string;
begin
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\Tests\Data\Geometry\' + AFileName));
end;

class function TGeoGolden.Load(const AFileName: string; const ANames: array of string): TStringList;
var
  LAll: TStringList;
  LLine, LFirst: string;
  LIndex, LName: Integer;
  LKeep: Boolean;
begin
  Result := TStringList.Create;
  LAll := TStringList.Create;
  try
    LAll.LoadFromFile(DataPath(AFileName));
    for LIndex := 0 to LAll.Count - 1 do
    begin
      LLine := LAll[LIndex];
      LFirst := Copy(LLine, 1, Pos(' ', LLine) - 1);
      LKeep := False;
      for LName := 0 to High(ANames) do
        if LFirst = ANames[LName] then
          LKeep := True;
      if LKeep then
        Result.Add(LLine);
    end;
  finally
    LAll.Free;
  end;
end;

class function TGeoGolden.FloatToken(AValue: Single): string;
begin
  Result := '#' + LowerCase(IntToHex(PCardinal(@AValue)^, 8));
end;

class function TGeoGolden.TokenToFloat(const AToken: string): Single;
var
  LBits: System.Cardinal;
begin
  LBits := System.Cardinal(StrToInt64('$' + Copy(AToken, 2, 8)));
  Result := PSingle(@LBits)^;
end;

class function TGeoGolden.InputsOf(const ALine: string): string;
begin
  Result := Copy(ALine, 1, Pos(' |', ALine) - 1);
end;

class procedure TGeoGolden.CompareOutput(const ALine, AActualOutput: string; AMaxUlps: Integer;
  AAbsTolerance: Single);
var
  LExpected, LActual: TArray<string>;
  LExpectedValue, LActualValue, LDifference: Single;
  LIndex: Integer;
  LBar: Integer;
  LOk: Boolean;
begin
  LBar := Pos(' |', ALine);
  Assert.IsTrue(LBar > 0, 'riga senza barra: ' + Copy(ALine, 1, 60));
  LExpected := Copy(ALine, LBar + 3, MaxInt).Trim.Split([' ']);
  LActual := AActualOutput.Trim.Split([' ']);
  Assert.AreEqual(Length(LExpected), Length(LActual),
    'numero di valori diverso nella riga "' + Copy(ALine, 1, 40) + '"');
  for LIndex := 0 to High(LExpected) do
  begin
    if LExpected[LIndex] = LActual[LIndex] then
      Continue;
    LOk := False;
    if (Length(LExpected[LIndex]) = 9) and (LExpected[LIndex][1] = '#') and (Length(LActual[LIndex]) = 9) and
      (LActual[LIndex][1] = '#') then
    begin
      LExpectedValue := TokenToFloat(LExpected[LIndex]);
      LActualValue := TokenToFloat(LActual[LIndex]);
      if IsNan(LExpectedValue) and IsNan(LActualValue) then
        LOk := True
      else if not (IsNan(LExpectedValue) or IsNan(LActualValue)) then
      begin
        if Abs(OrderedBits(PCardinal(@LExpectedValue)^) - OrderedBits(PCardinal(@LActualValue)^)) <= AMaxUlps then
          LOk := True
        else
        begin
          LDifference := Abs(LExpectedValue - LActualValue);
          LOk := (LDifference <= AAbsTolerance) or (LDifference <= 4E-6 * Max(Abs(LExpectedValue), Abs(LActualValue)));
        end;
      end;
    end;
    Assert.IsTrue(LOk, Format('"%s": valore %d atteso %s (%g), ottenuto %s (%g)',
      [Copy(ALine, 1, 40), LIndex, LExpected[LIndex], TokenToFloat(LExpected[LIndex]), LActual[LIndex],
      TokenToFloat(LActual[LIndex])]));
  end;
end;

end.
