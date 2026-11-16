{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the renderer library - the floating point of the       }
{  polygon clipper                                                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Renderer.ClipperX87;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  /// <summary>
  ///   TRendererClipperX87 against the expressions of r_clipper.pas (issue #40): at 32 bit each result is compared
  ///   with the expression computed by the FPU (copied here); the fingerprint of the results is a constant and at
  ///   64 bit, where the clipper calls the class, the same fingerprint must come out
  /// </summary>
  [TestFixture]
  [Category('renderer')]
  TTestRendererClipperX87 = class(TObject)
  public
    [Test]
    procedure DovrebbeDareLaPendenzaInversaEIlPuntoSuUnLato;
    [Test]
    procedure DovrebbeDareLeIntersezioniDiDueLati;
  end;

implementation

uses
  DelphiDoom.Renderer.ClipperX87, DelphiDoom.Tests.MathCore.Fingerprint;

type
  TRandomSource = record
    State: Cardinal;
    function Next: Cardinal;
  end;

function TRandomSource.Next: Cardinal;
begin
  State := State * 1664525 + 1013904223;
  Result := State xor (State shr 13);
end;

// a coordinate of the clipper: map units in 16.16
function Coordinate(var ARandom: TRandomSource): Int64;
begin
  case ARandom.Next and 3 of
    0: Result := Int64(Integer(ARandom.Next)) div 8;
    1: Result := Int64(Integer(ARandom.Next)) div 1024;
    2: Result := (Int64(ARandom.Next and 4095) - 2048) * 65536;
  else
    Result := Int64(ARandom.Next and 65535) - 32768;
  end;
end;

{ TTestRendererClipperX87 }

procedure TTestRendererClipperX87.DovrebbeDareLaPendenzaInversaEIlPuntoSuUnLato;
const
  COUNT = 200000;
var
  LRandom: TRandomSource;
  LFingerprint: TFingerprint;
  LIndex: Integer;
  LDeltaX, LDeltaY, LBotX, LResult: Int64;
  LDx: Double;
  {$IF SizeOf(Extended) > SizeOf(Double)}
  LNative: Double;
  {$IFEND}
begin
  LRandom.State := 6;
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 0 to COUNT - 1 do
    begin
      LDeltaX := Coordinate(LRandom);
      LDeltaY := Coordinate(LRandom);
      if LDeltaY = 0 then
        LDeltaY := 1;
      LBotX := Coordinate(LRandom);
      LDx := TRendererClipperX87.InverseSlope(LDeltaX, LDeltaY);
      {$IF SizeOf(Extended) > SizeOf(Double)}
      LNative := LDeltaX / LDeltaY;
      Assert.IsTrue(LNative = LDx, Format('%d / %d', [LDeltaX, LDeltaY]));
      {$IFEND}
      LFingerprint.AddDouble(LDx);
      LResult := TRendererClipperX87.RoundOffset(LDx, LDeltaY);
      {$IF SizeOf(Extended) > SizeOf(Double)}
      Assert.AreEqual(Round(LDx * (LDeltaY)), LResult, Format('%g * %d', [LDx, LDeltaY]));
      {$IFEND}
      LFingerprint.AddInt64(LResult);
      // the clipper divides by Dx only when it is not zero
      if LDx = 0 then
        LResult := 0
      else
        LResult := TRendererClipperX87.RoundAtX(LBotX, LDx, 12.5);
      {$IF SizeOf(Extended) > SizeOf(Double)}
      if LDx <> 0 then
        Assert.AreEqual(Round(LBotX / LDx + 12.5), LResult, Format('%d / %g', [LBotX, LDx]));
      {$IFEND}
      LFingerprint.AddInt64(LResult);
    end;
    Assert.AreEqual('3D7A52C5E47DC55D/600000', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestRendererClipperX87.DovrebbeDareLeIntersezioniDiDueLati;
const
  COUNT = 200000;
var
  LRandom: TRandomSource;
  LFingerprint: TFingerprint;
  LIndex: Integer;
  LBotX1, LBotY1, LBotX2, LBotY2, LDeltaX, LDeltaY: Int64;
  LDx1, LDx2, LB1, LB2, LM: Double;
  LResult: Int64;
  {$IF SizeOf(Extended) > SizeOf(Double)}
  LNative: Double;
  {$IFEND}
begin
  LRandom.State := 8;
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 0 to COUNT - 1 do
    begin
      LBotX1 := Coordinate(LRandom);
      LBotY1 := Coordinate(LRandom);
      LBotX2 := Coordinate(LRandom);
      LBotY2 := Coordinate(LRandom);
      // the order of evaluation of the arguments is not the same at 32 and 64 bit: one draw for each statement
      LDeltaX := Coordinate(LRandom);
      LDeltaY := Coordinate(LRandom) or 1;
      LDx1 := TRendererClipperX87.InverseSlope(LDeltaX, LDeltaY);
      LDeltaX := Coordinate(LRandom);
      LDeltaY := Coordinate(LRandom) or 1;
      LDx2 := TRendererClipperX87.InverseSlope(LDeltaX, LDeltaY);
      if LDx1 = LDx2 then
        Continue;
      LB1 := TRendererClipperX87.Intercept(LBotX1, LBotY1, LDx1);
      LB2 := TRendererClipperX87.Intercept(LBotX2, LBotY2, LDx2);
      {$IF SizeOf(Extended) > SizeOf(Double)}
      LNative := LBotX1 - LBotY1 * LDx1;
      Assert.IsTrue(LNative = LB1);
      LNative := LBotX2 - LBotY2 * LDx2;
      Assert.IsTrue(LNative = LB2);
      {$IFEND}
      LM := TRendererClipperX87.CrossingY(LB1, LB2, LDx1, LDx2);
      {$IF SizeOf(Extended) > SizeOf(Double)}
      LNative := (LB2 - LB1) / (LDx1 - LDx2);
      Assert.IsTrue(LNative = LM, Format('%g %g %g %g', [LB1, LB2, LDx1, LDx2]));
      {$IFEND}
      LFingerprint.AddDouble(LB1);
      LFingerprint.AddDouble(LM);
      LResult := TRendererClipperX87.RoundAtY(LDx1, LM, LB1);
      {$IF SizeOf(Extended) > SizeOf(Double)}
      Assert.AreEqual(Round(LDx1 * LM + LB1), LResult, Format('%g %g %g', [LDx1, LM, LB1]));
      {$IFEND}
      LFingerprint.AddInt64(LResult);
      if LDx2 <> 0 then
      begin
        LB1 := TRendererClipperX87.VerticalIntercept(LBotX1, LBotY1, LDx2);
        {$IF SizeOf(Extended) > SizeOf(Double)}
        LNative := LBotY1 - (LBotX1 / LDx2);
        Assert.IsTrue(LNative = LB1);
        {$IFEND}
        LFingerprint.AddDouble(LB1);
      end;
    end;
    Assert.AreEqual('080198AC4249547A/799990', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

end.
