{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the exit of the silent line teleports                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Thinkers.TeleportLineExit;

// The old block is written in the test as it was in p_telept.pas before the library, with
// wrapping arithmetic as in the engine
{$Q-}
{$R-}

interface

uses
  DUnitX.TestFramework, DelphiDoom.Thinkers.Teleport.Intf;

type
  /// <summary>
  ///   The side of a point for the tests: the real one (the sign of a cross product) for an exit
  ///   line, or a fixed answer that is wrong for the first queries
  /// </summary>
  TFakeLineSide = class(TInterfacedObject, ITeleportLineSide)
  strict private
    FStartX: Integer;
    FStartY: Integer;
    FDx: Integer;
    FDy: Integer;
    FWrongAnswers: Integer;
    FFixedSide: Integer;
    FUseFixed: Boolean;
  public
    Queries: Integer;
    /// <summary>The side by geometry of the line that starts at (X, Y) and has vector (Dx, Dy)</summary>
    constructor CreateGeometric(AStartX, AStartY, ADx, ADy: Integer);
    /// <summary>Answers the wrong side for AWrongAnswers queries and then the side ASide</summary>
    constructor CreateFixed(ASide, AWrongAnswers: Integer);
    function PointOnSide(AX, AY: Integer): Integer;
  end;

  [TestFixture]
  [Category('thinkers')]
  TTestThinkersTeleportLineExit = class(TObject)
  public
    [Test]
    procedure DovrebbeInterpolareLaPosizioneSullaLineaDiUscita;
    [Test]
    procedure DovrebbeAggiungereMezzoGiroSeNonERovesciato;
    [Test]
    procedure DovrebbeRovesciareLaPosizioneSeERovesciato;
    [Test]
    procedure DovrebbeSpostareDiUnaUnitaPerOgniRispostaSbagliata;
    [Test]
    procedure DovrebbeFermarsiDopoAlPiuUndiciPassi;
    [Test]
    procedure DovrebbeSpostareSulLatoGiustoLungoXSeLaLineaEVerticale;
    [Test]
    procedure DovrebbeVolereIlLatoUnoPerUnGiocatoreCheScende;
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelVecchioCodice;
  end;

implementation

uses
  DelphiDoom.MathCore.Types, DelphiDoom.MathCore.FixedMath, DelphiDoom.MathCore.Trigonometry,
  DelphiDoom.Thinkers.Teleport.LineExit;

const
  FRACUNIT = 65536;

var
  GSeed: Cardinal;

function NextValue: Cardinal;
begin
  GSeed := GSeed * 1664525 + 1013904223;
  Result := GSeed;
end;

{ TFakeLineSide }

constructor TFakeLineSide.CreateGeometric(AStartX, AStartY, ADx, ADy: Integer);
begin
  inherited Create;
  FStartX := AStartX;
  FStartY := AStartY;
  FDx := ADx;
  FDy := ADy;
end;

constructor TFakeLineSide.CreateFixed(ASide, AWrongAnswers: Integer);
begin
  inherited Create;
  FFixedSide := ASide;
  FWrongAnswers := AWrongAnswers;
  FUseFixed := True;
end;

function TFakeLineSide.PointOnSide(AX, AY: Integer): Integer;
var
  LCross: Int64;
begin
  Inc(Queries);
  if FUseFixed then
  begin
    if FWrongAnswers > 0 then
    begin
      Dec(FWrongAnswers);
      Result := 1 - FFixedSide;
    end
    else
      Result := FFixedSide;
    Exit;
  end;
  LCross := Int64(AX - FStartX) * FDy - Int64(AY - FStartY) * FDx;
  if LCross < 0 then
    Result := 1
  else
    Result := 0;
end;

function MakeInput(ASourceDx, ASourceDy, AExitDx, AExitDy: Integer): TTeleportLineInput;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.SourceDx := ASourceDx;
  Result.SourceDy := ASourceDy;
  Result.ExitDx := AExitDx;
  Result.ExitDy := AExitDy;
end;

/// <summary>The block of EV_SilentLineTeleport as it was</summary>
procedure OldLineExit(const AInput: TTeleportLineInput; const ASide: ITeleportLineSide;
  out AOutput: TTeleportLineOutput);
var
  pos: Integer;
  angle: Cardinal;
  x, y, s, c: Integer;
  fudge, side: Integer;
begin
  if Abs(AInput.SourceDx) > Abs(AInput.SourceDy) then
    pos := TFixedMath.Divide(AInput.ThingX - AInput.SourceStartX, AInput.SourceDx)
  else
    pos := TFixedMath.Divide(AInput.ThingY - AInput.SourceStartY, AInput.SourceDy);

  angle := AInput.ExitAngle - AInput.SourceAngle;
  if AInput.Reverse then
    pos := FRACUNIT - pos
  else
    angle := angle + ANG180;

  x := AInput.ExitEndX - TFixedMath.Mul(pos, AInput.ExitDx);
  y := AInput.ExitEndY - TFixedMath.Mul(pos, AInput.ExitDy);

  s := TTrigonometry.FineSine(angle shr ANGLETOFINESHIFT);
  c := TTrigonometry.FineCosine(angle shr ANGLETOFINESHIFT);

  fudge := 10;

  if AInput.Reverse or (AInput.ThingIsPlayer and AInput.StepDown) then
    side := 1
  else
    side := 0;

  while (ASide.PointOnSide(x, y) <> side) and (fudge >= 0) do
  begin
    Dec(fudge);
    if Abs(AInput.ExitDx) > Abs(AInput.ExitDy) then
      y := y - (1 - 2 * Ord(Ord(AInput.ExitDx < 0) <> side))
    else
      x := x + (1 - 2 * Ord(Ord(AInput.ExitDy < 0) <> side));
  end;

  AOutput.X := x;
  AOutput.Y := y;
  AOutput.Angle := angle;
  AOutput.Sine := s;
  AOutput.Cosine := c;
end;

{ TTestThinkersTeleportLineExit }

procedure TTestThinkersTeleportLineExit.DovrebbeInterpolareLaPosizioneSullaLineaDiUscita;
var
  LInput: TTeleportLineInput;
  LOutput: TTeleportLineOutput;
begin
  // the thing is at a quarter of the source line; the exit line goes up for 64 units and ends
  // at (200, 100): a quarter from the end it is at y = 100 - 16
  LInput := MakeInput(64 * FRACUNIT, 0, 0, 64 * FRACUNIT);
  LInput.ThingX := 16 * FRACUNIT;
  LInput.ExitEndX := 200 * FRACUNIT;
  LInput.ExitEndY := 100 * FRACUNIT;
  TTeleportLineExit.Compute(LInput, TFakeLineSide.CreateFixed(0, 0), LOutput);
  Assert.AreEqual(200 * FRACUNIT, LOutput.X);
  Assert.AreEqual(84 * FRACUNIT, LOutput.Y);
end;

procedure TTestThinkersTeleportLineExit.DovrebbeAggiungereMezzoGiroSeNonERovesciato;
var
  LInput: TTeleportLineInput;
  LOutput: TTeleportLineOutput;
begin
  LInput := MakeInput(64 * FRACUNIT, 0, 0, 64 * FRACUNIT);
  LInput.SourceAngle := 0;
  LInput.ExitAngle := ANG90;
  TTeleportLineExit.Compute(LInput, TFakeLineSide.CreateFixed(0, 0), LOutput);
  Assert.AreEqual(Cardinal($C0000000), LOutput.Angle);
  Assert.AreEqual(TTrigonometry.FineSine(6144), LOutput.Sine);
  Assert.AreEqual(TTrigonometry.FineCosine(6144), LOutput.Cosine);
end;

procedure TTestThinkersTeleportLineExit.DovrebbeRovesciareLaPosizioneSeERovesciato;
var
  LInput: TTeleportLineInput;
  LOutput: TTeleportLineOutput;
begin
  LInput := MakeInput(64 * FRACUNIT, 0, 0, 64 * FRACUNIT);
  LInput.ThingX := 16 * FRACUNIT;
  LInput.ExitEndX := 200 * FRACUNIT;
  LInput.ExitEndY := 100 * FRACUNIT;
  LInput.SourceAngle := 0;
  LInput.ExitAngle := ANG90;
  LInput.Reverse := True;
  // the position is 1 - 1/4 = 3/4: y = 100 - 48; no half turn
  TTeleportLineExit.Compute(LInput, TFakeLineSide.CreateFixed(1, 0), LOutput);
  Assert.AreEqual(52 * FRACUNIT, LOutput.Y);
  Assert.AreEqual(Cardinal(ANG90), LOutput.Angle);
end;

procedure TTestThinkersTeleportLineExit.DovrebbeSpostareDiUnaUnitaPerOgniRispostaSbagliata;
var
  LInput: TTeleportLineInput;
  LOutput: TTeleportLineOutput;
  LSide: TFakeLineSide;
  LHolder: ITeleportLineSide;
begin
  // a horizontal exit line (vector along x): the thing moves along y, one unit a step
  LInput := MakeInput(64 * FRACUNIT, 0, 64 * FRACUNIT, 0);
  LInput.ExitEndY := 10 * FRACUNIT;
  LSide := TFakeLineSide.CreateFixed(0, 3);
  LHolder := LSide;
  TTeleportLineExit.Compute(LInput, LHolder, LOutput);
  Assert.AreEqual(10 * FRACUNIT - 3, LOutput.Y);
  Assert.AreEqual(4, LSide.Queries);
end;

procedure TTestThinkersTeleportLineExit.DovrebbeFermarsiDopoAlPiuUndiciPassi;
var
  LInput: TTeleportLineInput;
  LOutput: TTeleportLineOutput;
begin
  LInput := MakeInput(64 * FRACUNIT, 0, 64 * FRACUNIT, 0);
  LInput.ExitEndY := 10 * FRACUNIT;
  TTeleportLineExit.Compute(LInput, TFakeLineSide.CreateFixed(0, 1000), LOutput);
  Assert.AreEqual(10 * FRACUNIT - 11, LOutput.Y);
end;

procedure TTestThinkersTeleportLineExit.DovrebbeSpostareSulLatoGiustoLungoXSeLaLineaEVerticale;
var
  LInput: TTeleportLineInput;
  LOutput: TTeleportLineOutput;
begin
  // a vertical exit line going up: dy > dx, so the thing moves along x (+1 for the side 0)
  LInput := MakeInput(0, 64 * FRACUNIT, 0, 64 * FRACUNIT);
  LInput.ExitEndX := 30 * FRACUNIT;
  TTeleportLineExit.Compute(LInput, TFakeLineSide.CreateFixed(0, 2), LOutput);
  Assert.AreEqual(30 * FRACUNIT + 2, LOutput.X);
end;

procedure TTestThinkersTeleportLineExit.DovrebbeVolereIlLatoUnoPerUnGiocatoreCheScende;
var
  LInput: TTeleportLineInput;
  LOutput: TTeleportLineOutput;
  LSide: TFakeLineSide;
  LHolder: ITeleportLineSide;
begin
  LInput := MakeInput(64 * FRACUNIT, 0, 64 * FRACUNIT, 0);
  LInput.ThingIsPlayer := True;
  LInput.StepDown := True;
  // it asks for side 1: a side that answers 1 at once needs no step
  LSide := TFakeLineSide.CreateFixed(1, 0);
  LHolder := LSide;
  TTeleportLineExit.Compute(LInput, LHolder, LOutput);
  Assert.AreEqual(1, LSide.Queries);
  // a player that does not step down asks for side 0: the same answer is wrong and it moves
  LInput.StepDown := False;
  LSide := TFakeLineSide.CreateFixed(1, 0);
  LHolder := LSide;
  TTeleportLineExit.Compute(LInput, LHolder, LOutput);
  Assert.AreEqual(12, LSide.Queries);
end;

procedure TTestThinkersTeleportLineExit.DovrebbeDareLeStesseRisposteDelVecchioCodice;
var
  LIndex: Integer;
  LInput: TTeleportLineInput;
  LOld, LNew: TTeleportLineOutput;
  LExitDx, LExitDy: Integer;
begin
  GSeed := 99;
  for LIndex := 1 to 20000 do
  begin
    LInput.SourceDx := (Integer(NextValue) shr 12) - 200000;
    LInput.SourceDy := (Integer(NextValue) shr 12) - 200000;
    if (LInput.SourceDx = 0) and (LInput.SourceDy = 0) then
      LInput.SourceDx := FRACUNIT;
    LInput.SourceStartX := (Integer(NextValue) shr 8) - 8000000;
    LInput.SourceStartY := (Integer(NextValue) shr 8) - 8000000;
    LInput.SourceAngle := NextValue;
    LExitDx := (Integer(NextValue) shr 12) - 200000;
    LExitDy := (Integer(NextValue) shr 12) - 200000;
    LInput.ExitDx := LExitDx;
    LInput.ExitDy := LExitDy;
    LInput.ExitEndX := (Integer(NextValue) shr 8) - 8000000;
    LInput.ExitEndY := (Integer(NextValue) shr 8) - 8000000;
    LInput.ExitAngle := NextValue;
    LInput.ThingX := (Integer(NextValue) shr 8) - 8000000;
    LInput.ThingY := (Integer(NextValue) shr 8) - 8000000;
    LInput.Reverse := (NextValue and 1) = 1;
    LInput.ThingIsPlayer := (NextValue and 1) = 1;
    LInput.StepDown := (NextValue and 1) = 1;
    OldLineExit(LInput, TFakeLineSide.CreateGeometric(LInput.ExitEndX - LExitDx,
      LInput.ExitEndY - LExitDy, LExitDx, LExitDy), LOld);
    TTeleportLineExit.Compute(LInput, TFakeLineSide.CreateGeometric(LInput.ExitEndX - LExitDx,
      LInput.ExitEndY - LExitDy, LExitDx, LExitDy), LNew);
    Assert.AreEqual(LOld.X, LNew.X, 'x');
    Assert.AreEqual(LOld.Y, LNew.Y, 'y');
    Assert.AreEqual(LOld.Angle, LNew.Angle, 'angle');
    Assert.AreEqual(LOld.Sine, LNew.Sine, 'sine');
    Assert.AreEqual(LOld.Cosine, LNew.Cosine, 'cosine');
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestThinkersTeleportLineExit);

end.
