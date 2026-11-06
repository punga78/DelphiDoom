{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the math core library - the runner of the pair series  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MathCore.PairRunner;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Tests.MathCore.Golden;

type
  TBinFunction = reference to function(A, B: Integer): Integer;
  TBinUnsignedFunction = reference to function(A, B: Cardinal): Cardinal;
  TUnaryFunction = reference to function(A: Integer): Integer;
  TUnaryDoubleFunction = reference to function(A: Integer): Double;
  TBinDoubleFunction = reference to function(A, B: Integer): Double;
  TBin64Function = reference to function(A, B: Integer): Int64;

  /// <summary>
  ///   Runs a function of the new library on the same pairs of numbers on which the temporary
  ///   harness ran the old one (edge values first, then pseudo random ones) and compares the
  ///   fingerprint of the results with the golden file. A function that raises an exception
  ///   counts as an exception in the series, as in the harness.
  /// </summary>
  TPairRunner = class
  private
    FGolden: TGoldenFile;
    FFirst: TArray<Integer>;
    FSecond: TArray<Integer>;
    FEdgeCount: Integer;
  public
    constructor Create(const AGolden: TGoldenFile);
    procedure Bin(const AKey: string; const AFunction: TBinFunction);
    procedure BinUnsigned(const AKey: string; const AFunction: TBinUnsignedFunction);
    procedure Unary(const AKey: string; const AFunction: TUnaryFunction);
    procedure UnaryDouble(const AKey: string; const AFunction: TUnaryDoubleFunction);
    procedure BinDouble(const AKey: string; const AFunction: TBinDoubleFunction);
    procedure Bin64(const AKey: string; const AFunction: TBin64Function);
    property First: TArray<Integer> read FFirst;
    property Second: TArray<Integer> read FSecond;
    property EdgeCount: Integer read FEdgeCount;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Tests.MathCore.Samples, DelphiDoom.Tests.MathCore.Fingerprint;

{ TPairRunner }

constructor TPairRunner.Create(const AGolden: TGoldenFile);
begin
  inherited Create;
  FGolden := AGolden;
  TMathCoreSamples.BuildPairs(FFirst, FSecond);
  FEdgeCount := Length(TMathCoreSamples.EdgeValues) * Length(TMathCoreSamples.EdgeValues);
end;

procedure TPairRunner.Bin(const AKey: string; const AFunction: TBinFunction);
var
  LEdge, LRandom, LCurrent: TFingerprint;
  LIndex: Integer;
begin
  LEdge := TFingerprint.Create;
  LRandom := TFingerprint.Create;
  try
    for LIndex := 0 to High(FFirst) do
    begin
      if LIndex < FEdgeCount then
        LCurrent := LEdge
      else
        LCurrent := LRandom;
      try
        LCurrent.AddInteger(AFunction(FFirst[LIndex], FSecond[LIndex]));
      except
        on Exception do
          LCurrent.AddException;
      end;
    end;
    FGolden.Check(AKey + '.edge', LEdge.ToHex);
    FGolden.Check(AKey + '.random', LRandom.ToHex);
  finally
    LEdge.Free;
    LRandom.Free;
  end;
end;

procedure TPairRunner.BinUnsigned(const AKey: string; const AFunction: TBinUnsignedFunction);
var
  LEdge, LRandom, LCurrent: TFingerprint;
  LIndex: Integer;
begin
  LEdge := TFingerprint.Create;
  LRandom := TFingerprint.Create;
  try
    for LIndex := 0 to High(FFirst) do
    begin
      if LIndex < FEdgeCount then
        LCurrent := LEdge
      else
        LCurrent := LRandom;
      try
        LCurrent.AddCardinal(AFunction(Cardinal(FFirst[LIndex]), Cardinal(FSecond[LIndex])));
      except
        on Exception do
          LCurrent.AddException;
      end;
    end;
    FGolden.Check(AKey + '.edge', LEdge.ToHex);
    FGolden.Check(AKey + '.random', LRandom.ToHex);
  finally
    LEdge.Free;
    LRandom.Free;
  end;
end;

procedure TPairRunner.Unary(const AKey: string; const AFunction: TUnaryFunction);
var
  LEdge, LRandom, LCurrent: TFingerprint;
  LIndex: Integer;
begin
  LEdge := TFingerprint.Create;
  LRandom := TFingerprint.Create;
  try
    for LIndex := 0 to High(FFirst) do
    begin
      if LIndex < FEdgeCount then
        LCurrent := LEdge
      else
        LCurrent := LRandom;
      try
        LCurrent.AddInteger(AFunction(FFirst[LIndex]));
      except
        on Exception do
          LCurrent.AddException;
      end;
    end;
    FGolden.Check(AKey + '.edge', LEdge.ToHex);
    FGolden.Check(AKey + '.random', LRandom.ToHex);
  finally
    LEdge.Free;
    LRandom.Free;
  end;
end;

procedure TPairRunner.UnaryDouble(const AKey: string; const AFunction: TUnaryDoubleFunction);
var
  LFingerprint: TFingerprint;
  LIndex: Integer;
begin
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 0 to High(FFirst) do
      try
        LFingerprint.AddDouble(AFunction(FFirst[LIndex]));
      except
        on Exception do
          LFingerprint.AddException;
      end;
    FGolden.Check(AKey, LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TPairRunner.BinDouble(const AKey: string; const AFunction: TBinDoubleFunction);
var
  LFingerprint: TFingerprint;
  LIndex: Integer;
begin
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 0 to High(FFirst) do
      try
        LFingerprint.AddDouble(AFunction(FFirst[LIndex], FSecond[LIndex]));
      except
        on Exception do
          LFingerprint.AddException;
      end;
    FGolden.Check(AKey, LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TPairRunner.Bin64(const AKey: string; const AFunction: TBin64Function);
var
  LFingerprint: TFingerprint;
  LIndex: Integer;
begin
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 0 to High(FFirst) do
      try
        LFingerprint.AddInt64(AFunction(FFirst[LIndex], FSecond[LIndex]));
      except
        on Exception do
          LFingerprint.AddException;
      end;
    FGolden.Check(AKey, LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

end.
