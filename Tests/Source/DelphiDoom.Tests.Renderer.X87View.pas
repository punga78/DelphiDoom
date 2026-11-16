{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the renderer library - the field of view, the voxels   }
{  and the teleport zoom                                                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Renderer.X87View;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  /// <summary>
  ///   TRendererX87.FieldOfView, VoxelColumnAngle, VoxelSpinAngle and TeleportDistance (issue #40): at 32 bit
  ///   each result is compared with the expression of the renderer computed by the FPU (copied here); the
  ///   fingerprint of the results is a constant and at 64 bit, where the renderer calls the class, the same
  ///   fingerprint must come out
  /// </summary>
  [TestFixture]
  [Category('renderer')]
  TTestRendererX87View = class(TObject)
  public
    [Test]
    procedure DovrebbeDareIlCampoVisivo;
    [Test]
    procedure DovrebbeDareLAngoloDiUnaColonnaDiVoxel;
    [Test]
    procedure DovrebbeDareLaRotazioneDiUnVoxel;
    [Test]
    procedure DovrebbeDareLaDistanzaDelloZoomDelTeletrasporto;
    [Test]
    procedure DovrebbeDareIlPuntoSulloSchermo;
    [Test]
    procedure DovrebbeDareLaLunghezzaDiUnMuroPerOpenGL;
  end;

implementation

uses
  System.Math, DelphiDoom.Renderer.X87, DelphiDoom.Tests.MathCore.Fingerprint;

const
  // the constants of tables.pas, as the renderer has them
  D_PI = 3.141592657;
  ANG180 = $80000000;
  ANGLE_MAX = $FFFFFFFF;
  FRACUNIT = 65536;
  FINEANGLES = 8192;
  TICRATE = 35;

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

{$IF SizeOf(Extended) > SizeOf(Double)}
// R_PointToScreenBufferEx of r_utils.pas as it was
function NativeScreenPoint(ADeltaX, ADeltaY, ADeltaZ, viewcos, viewsin, projection, projectiony, centerx, centery,
  viewwidth, viewheight: Integer; var x, y: Integer): Boolean;
var
  x1, y1: Single;
  tr_x, tr_y, tr_z: Single;
  tx, tz: Single;
  xscale, yscale: Single;
  dcos, dsin: Single;
begin
  Result := True;
  tr_x := ADeltaX / FRACUNIT;
  tr_y := ADeltaY / FRACUNIT;
  tr_z := ADeltaZ / FRACUNIT;
  dcos := viewcos / FRACUNIT;
  dsin := viewsin / FRACUNIT;
  tz := tr_x * dcos + tr_y * dsin;
  xscale := projection / FRACUNIT / tz;
  tx := tr_x * dsin - tr_y * dcos;
  x1 := centerx + tx * xscale;
  Result := Result and (x1 < viewwidth) and (x1 >= 0);
  yscale := projectiony / FRACUNIT / tz;
  y1 := centery - tr_z * yscale;
  Result := Result and (y1 < viewheight) and (y1 >= 0);
  x := Trunc(x1);
  y := Trunc(y1);
end;
{$IFEND}

{ TTestRendererX87View }

procedure TTestRendererX87View.DovrebbeDareLaLunghezzaDiUnMuroPerOpenGL;
const
  COUNT = 200000;
var
  LRandom: TRandomSource;
  LFingerprint: TFingerprint;
  LIndex: Integer;
  LDeltaX, LDeltaY, LResult, LShift: Integer;
  {$IF SizeOf(Extended) > SizeOf(Double)}
  A, B: Single;
  {$IFEND}
begin
  LRandom.State := 77;
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 0 to COUNT - 1 do
    begin
      // one draw for each statement: the order of evaluation is not the same at 32 and 64 bit
      LShift := Integer(LRandom.Next and 15);
      LDeltaX := Integer(LRandom.Next) div (1 shl LShift);
      LShift := Integer(LRandom.Next and 15);
      LDeltaY := Integer(LRandom.Next) div (1 shl LShift);
      LResult := TRendererX87.WallOffset(LDeltaX, LDeltaY);
      {$IF SizeOf(Extended) > SizeOf(Double)}
      A := LDeltaX / FRACUNIT;
      B := LDeltaY / FRACUNIT;
      Assert.AreEqual(Integer(Round(Sqrt(A * A + B * B) * FRACUNIT)), LResult, Format('%d %d', [LDeltaX, LDeltaY]));
      {$IFEND}
      LFingerprint.AddInteger(LResult);
    end;
    Assert.AreEqual('0DF9353734A62AB8/200000', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestRendererX87View.DovrebbeDareIlPuntoSulloSchermo;
const
  COUNT = 200000;
var
  LRandom: TRandomSource;
  LFingerprint: TFingerprint;
  LIndex: Integer;
  LDeltaX, LDeltaY, LDeltaZ, LCosine, LSine: Integer;
  LX, LY: Integer;
  LInside, LHandled: Boolean;
  {$IF SizeOf(Extended) > SizeOf(Double)}
  LNativeX, LNativeY: Integer;
  {$IFEND}
begin
  LRandom.State := 21;
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 0 to COUNT - 1 do
    begin
      LDeltaX := Integer(LRandom.Next) div 64;
      LDeltaY := Integer(LRandom.Next) div 64;
      LDeltaZ := Integer(LRandom.Next) div 4096;
      LCosine := Integer(LRandom.Next and $1FFFF) - $10000;
      LSine := Integer(LRandom.Next and $1FFFF) - $10000;
      LX := 0;
      LY := 0;
      LInside := False;
      LHandled := TRendererX87.ScreenPoint(LDeltaX, LDeltaY, LDeltaZ, LCosine, LSine, 320 * FRACUNIT, 400 * FRACUNIT,
        320, 200, 640, 400, LX, LY, LInside);
      {$IF SizeOf(Extended) > SizeOf(Double)}
      if LHandled then
      begin
        Assert.AreEqual(NativeScreenPoint(LDeltaX, LDeltaY, LDeltaZ, LCosine, LSine, 320 * FRACUNIT,
          400 * FRACUNIT, 320, 200, 640, 400, LNativeX, LNativeY), LInside);
        Assert.AreEqual(LNativeX, LX, Format('%d %d %d %d %d', [LDeltaX, LDeltaY, LDeltaZ, LCosine, LSine]));
        Assert.AreEqual(LNativeY, LY, Format('%d %d %d %d %d', [LDeltaX, LDeltaY, LDeltaZ, LCosine, LSine]));
      end;
      {$IFEND}
      LFingerprint.AddBoolean(LHandled);
      if LHandled then
      begin
        LFingerprint.AddBoolean(LInside);
        LFingerprint.AddInteger(LX);
        LFingerprint.AddInteger(LY);
      end;
    end;
    Assert.AreEqual('76A7F653EEB9DDEE/800000', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestRendererX87View.DovrebbeDareIlCampoVisivo;
const
  COUNT = 100000;
var
  LRandom: TRandomSource;
  LFingerprint: TFingerprint;
  LIndex: Integer;
  LAspect: Double;
  LResult: Integer;
begin
  LRandom.State := 40;
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 0 to COUNT - 1 do
    begin
      case LIndex of
        0: LAspect := 1.0;
        1: LAspect := 4 / 3;
        2: LAspect := 16 / 9;
        3: LAspect := 2.0;
        4: LAspect := 1.5;
      else
        // the monitor aspect is in 1..2 and the fake 3D correction (2 - cos) multiplies it
        LAspect := 1.0 + (LRandom.Next / 4294967296.0) * 2.0;
      end;
      LResult := TRendererX87.FieldOfView(LAspect, FINEANGLES);
      {$IF SizeOf(Extended) > SizeOf(Double)}
      Assert.AreEqual(Integer(Round(ArcTan(LAspect) * FINEANGLES / D_PI)), LResult, Format('%.17g', [LAspect]));
      {$IFEND}
      LFingerprint.AddInteger(LResult);
    end;
    Assert.AreEqual('0430A7678239B979/100000', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestRendererX87View.DovrebbeDareLAngoloDiUnaColonnaDiVoxel;
const
  COUNT = 100000;
var
  LRandom: TRandomSource;
  LFingerprint: TFingerprint;
  LIndex: Integer;
  LX, LY, LScale: Integer;
  LResult: Int64;
begin
  LRandom.State := 7;
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 0 to COUNT - 1 do
    begin
      LScale := (1 + Integer(LRandom.Next and 7)) * (FRACUNIT div 4);
      LX := (Integer(LRandom.Next and 127) - 64) * LScale;
      LY := (Integer(LRandom.Next and 127) - 64) * LScale;
      if LIndex < 9 then
      begin
        LX := (LIndex mod 3 - 1) * LScale;
        LY := (LIndex div 3 - 1) * LScale;
      end;
      LResult := TRendererX87.VoxelColumnAngle(LY, LX);
      {$IF SizeOf(Extended) > SizeOf(Double)}
      Assert.AreEqual(Round(ArcTan2(LY, LX) * (ANG180 / D_PI)), LResult, Format('%d %d', [LY, LX]));
      {$IFEND}
      LFingerprint.AddInt64(LResult);
    end;
    Assert.AreEqual('20022614DF31F76E/100000', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestRendererX87View.DovrebbeDareLaRotazioneDiUnVoxel;
const
  COUNT = 200000;
var
  LRandom: TRandomSource;
  LFingerprint: TFingerprint;
  LIndex: Integer;
  LLevelTime, LTicFraction, LSpin: Integer;
  LResult: Int64;
begin
  LRandom.State := 35;
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 0 to COUNT - 1 do
    begin
      // a level that lasts from seconds to days
      LLevelTime := Integer(LRandom.Next) shr (7 + Integer(LRandom.Next and 15));
      LTicFraction := Integer(LRandom.Next and $FFFF);
      LSpin := Integer(LRandom.Next and 1023) - 512;
      if LSpin = 0 then
        LSpin := 90;
      LResult := TRendererX87.VoxelSpinAngle(LLevelTime, LTicFraction, TICRATE, LSpin, True);
      {$IF SizeOf(Extended) > SizeOf(Double)}
      Assert.AreEqual(Round(((LLevelTime + LTicFraction / FRACUNIT) / TICRATE * LSpin) * (ANGLE_MAX / 360)),
        LResult, Format('%d %d %d', [LLevelTime, LTicFraction, LSpin]));
      {$IFEND}
      LFingerprint.AddInt64(LResult);
      LResult := TRendererX87.VoxelSpinAngle(LLevelTime, LTicFraction, TICRATE, LSpin, False);
      {$IF SizeOf(Extended) > SizeOf(Double)}
      Assert.AreEqual(Round((LLevelTime / TICRATE * LSpin) * (ANGLE_MAX / 360)), LResult,
        Format('%d %d', [LLevelTime, LSpin]));
      {$IFEND}
      LFingerprint.AddInt64(LResult);
    end;
    Assert.AreEqual('4E189BFFD20E15C8/400000', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

procedure TTestRendererX87View.DovrebbeDareLaDistanzaDelloZoomDelTeletrasporto;
const
  ZOOM = 15 * FRACUNIT;
var
  LFingerprint: TFingerprint;
  LTics: Integer;
  LResult: Integer;
  {$IF SizeOf(Extended) > SizeOf(Double)}
  LDistance: Single;
  {$IFEND}
begin
  LFingerprint := TFingerprint.Create;
  try
    // every value that the teleport counter can have
    for LTics := 1 to ZOOM do
    begin
      LResult := TRendererX87.TeleportDistance(LTics, ZOOM);
      {$IF SizeOf(Extended) > SizeOf(Double)}
      LDistance := Sqr(LTics / FRACUNIT) / (ZOOM / FRACUNIT);
      Assert.AreEqual(Integer(Round(LDistance * FRACUNIT)), LResult, Format('%d', [LTics]));
      {$IFEND}
      LFingerprint.AddInteger(LResult);
    end;
    Assert.AreEqual('808F7209B3E66310/983040', LFingerprint.ToHex);
  finally
    LFingerprint.Free;
  end;
end;

end.
