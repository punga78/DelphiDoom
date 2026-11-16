{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the commands of an old demo after the player's death   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Demo.DeathTrimmer;

{$POINTERMATH ON}

interface

uses
  DUnitX.TestFramework,
  DelphiDoom.Demo.DeathTrimmer;

type
  [TestFixture]
  [Category('demo')]
  TTestDemoDeathTrimmer = class
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeEssereUgualeAlVecchioCodiceSuBufferCasuali;
    [Test]
    procedure DovrebbeEssereUgualeAlVecchioCodiceSenzaFineDelleDemo;
    [Test]
    procedure DovrebbeLasciareIlComandoDiFineSeLaDemoFinisceSubito;
    [Test]
    procedure DovrebbeTroncareDopoQuattroSecondiEMettereIlMarcatore;
  end;

implementation

uses
  System.SysUtils;

const
  DEMOMARKER = $80;
  TICRATE = 35;

type
  PByteArray = ^TByteArray;
  TByteArray = array[0..65535] of Byte;

var
  demo_p: PByteArray;
  demoend: PByte;

// G_SafeCompatibilityDemo of Doom, copied as it was without the test of the player
// state and of compatibility_done, that stay with the caller
procedure OldTrim;
var
  i: integer;
begin
  i := 4;
  while (NativeInt(@demo_p[i]) < NativeInt(demoend) - 4) and (demo_p[i] <> DEMOMARKER) do
    inc(i, 4);
  // JVAL: Leave maximum 4 seconds after player death
  if i > 4 * TICRATE * 4 then
  begin
    i := 4 * TICRATE * 4;
    demo_p[i] := DEMOMARKER;
  end;
  FillChar(demo_p^, i, 0);
end;

{ TTestDemoDeathTrimmer }

procedure TTestDemoDeathTrimmer.Setup;
begin
  RandSeed := 245;
end;

procedure TTestDemoDeathTrimmer.DovrebbeEssereUgualeAlVecchioCodiceSuBufferCasuali;
var
  LOld: array[0..2047] of Byte;
  LNew: array[0..2047] of Byte;
  LRepeat: Integer;
  LIndex: Integer;
  LLength: Integer;
  LMarker: Integer;
begin
  for LRepeat := 1 to 400 do
  begin
    LLength := 16 + Random(2000);
    for LIndex := 0 to High(LOld) do
    begin
      LOld[LIndex] := Random(DEMOMARKER); // no marker by chance
      LNew[LIndex] := LOld[LIndex];
    end;
    LMarker := Random(LLength);
    LOld[LMarker] := DEMOMARKER;
    LNew[LMarker] := DEMOMARKER;

    demo_p := @LOld[0];
    demoend := @LOld[LLength];
    OldTrim;

    TDemoDeathTrimmer.Trim(@LNew[0], @LNew[LLength]);

    Assert.IsTrue(CompareMem(@LOld[0], @LNew[0], SizeOf(LOld)),
      Format('length %d, marker at %d', [LLength, LMarker]));
  end;
end;

procedure TTestDemoDeathTrimmer.DovrebbeEssereUgualeAlVecchioCodiceSenzaFineDelleDemo;
var
  LOld: array[0..2047] of Byte;
  LNew: array[0..2047] of Byte;
  LIndex: Integer;
begin
  for LIndex := 0 to High(LOld) do
  begin
    LOld[LIndex] := 1 + Random(100);
    LNew[LIndex] := LOld[LIndex];
  end;

  demo_p := @LOld[0];
  demoend := @LOld[2000];
  OldTrim;

  TDemoDeathTrimmer.Trim(@LNew[0], @LNew[2000]);

  Assert.IsTrue(CompareMem(@LOld[0], @LNew[0], SizeOf(LOld)));
end;

procedure TTestDemoDeathTrimmer.DovrebbeLasciareIlComandoDiFineSeLaDemoFinisceSubito;
var
  LBytes: array[0..63] of Byte;
begin
  FillChar(LBytes, SizeOf(LBytes), 7);
  LBytes[8] := DEMOMARKER;
  TDemoDeathTrimmer.Trim(@LBytes[0], PByte(@LBytes[0]) + 64);
  Assert.AreEqual<Integer>(0, LBytes[0]);
  Assert.AreEqual<Integer>(0, LBytes[7]);
  Assert.AreEqual<Integer>(DEMOMARKER, LBytes[8]);
  Assert.AreEqual<Integer>(7, LBytes[9]);
end;

procedure TTestDemoDeathTrimmer.DovrebbeTroncareDopoQuattroSecondiEMettereIlMarcatore;
var
  LBytes: array[0..1999] of Byte;
begin
  FillChar(LBytes, SizeOf(LBytes), 7);
  TDemoDeathTrimmer.Trim(@LBytes[0], PByte(@LBytes[0]) + 2000);
  Assert.AreEqual<Integer>(0, LBytes[559]);
  Assert.AreEqual<Integer>(DEMOMARKER, LBytes[560]);
  Assert.AreEqual<Integer>(7, LBytes[561]);
end;

end.
