{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the line of sight rule of p_sight                      }
{                                                                              }
{  P_CheckSight on a map built in memory: two sectors side by side, one        }
{  partition line between them, one wall (a line with its two segs). The       }
{  expected answers come from what the rule means (a wall, a door that is      }
{  closed, a ledge that hides the feet), worked out by hand in each test.      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Rules.Sight;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.MathCore.Types,
  doomdata,
  doomdef,
  g_game,
  m_fixed,
  p_mobj_h,
  p_setup,
  p_sight,
  r_defs;

type
  [TestFixture]
  [Category('rules')]
  TTestRulesSight = class
  strict private
    FSectors: array[0..2] of sector_t;
    FSubsectors: array[0..1] of subsector_t;
    FSegs: array[0..1] of seg_t;
    FNodes: array[0..0] of node_t;
    FVertices: array[0..1] of vertex_t;
    FLine: line_t;
    FFirst: mobj_t;
    FSecond: mobj_t;
    FReject: array[0..0] of Byte;
    procedure MakeSector(const AIndex: Integer; const AFloor, ACeiling: fixed_t);
    procedure MakeMap(const ATwoSided: Boolean);
    procedure PlaceThings(const AFirstFloor, ASecondFloor: fixed_t);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeVedereAttraversoUnaLineaConLaStessaAltezzaDaiDueLati;
    [Test]
    procedure DovrebbeNonVedereAttraversoUnMuroAUnSoloLato;
    [Test]
    procedure DovrebbeNonVedereAttraversoUnaPortaChiusa;
    [Test]
    procedure DovrebbeVedereSopraUnSoffittoPiuBassoSeLaCosaEAlta;
    [Test]
    procedure DovrebbeVedereLaCimaDiUnaCosaSuUnGradinoAlto;
    [Test]
    procedure DovrebbeNonVedereUnaCosaNascostaDaUnGradinoPiuAltoDellaSuaCima;
    [Test]
    procedure DovrebbeVedereSimmetricamenteDaiDueVersi;
    [Test]
    procedure DovrebbeNonVedereSeLaTabellaRejectDiceCheNonSiVedono;
    [Test]
    procedure DovrebbeConfrontareIlPavimentoNelloStessoSettore;
    [Test]
    procedure DovrebbeNonVedereDaUnPianoIntermedioFraLeDueCose;
  end;

implementation

const
  Wall = 64 * FRACUNIT;

{ TTestRulesSight }

procedure TTestRulesSight.MakeSector(const AIndex: Integer; const AFloor, ACeiling: fixed_t);
begin
  FillChar(FSectors[AIndex], SizeOf(sector_t), 0);
  FSectors[AIndex].floorheight := AFloor;
  FSectors[AIndex].ceilingheight := ACeiling;
  FSectors[AIndex].midsec := -1;
  FSectors[AIndex].heightsec := -1;
end;

// Sector 0 is for x < 0 and sector 1 for x > 0; the partition line is x = 0 going up (front side: x > 0). The
// segment of the line in the subsector of sector 0 has sector 0 in front, the one in the subsector of sector 1 the
// opposite.
procedure TTestRulesSight.MakeMap(const ATwoSided: Boolean);
begin
  FVertices[0].x := 0;
  FVertices[0].y := -Wall;
  FVertices[1].x := 0;
  FVertices[1].y := Wall;

  FillChar(FLine, SizeOf(FLine), 0);
  FLine.v1 := @FVertices[0];
  FLine.v2 := @FVertices[1];
  FLine.dx := 0;
  FLine.dy := 2 * Wall;
  FLine.slopetype := ST_VERTICAL;
  FLine.bbox[BOX_TOP] := Wall;
  FLine.bbox[BOX_BOTTOM] := -Wall;
  FLine.bbox[BOX_LEFT] := 0;
  FLine.bbox[BOX_RIGHT] := 0;
  if ATwoSided then
    FLine.flags := ML_TWOSIDED
  else
    FLine.flags := 0;

  FillChar(FSegs, SizeOf(FSegs), 0);
  FSegs[0].v1 := @FVertices[0];
  FSegs[0].v2 := @FVertices[1];
  FSegs[0].linedef := @FLine;
  FSegs[0].frontsector := @FSectors[0];
  FSegs[1].v1 := @FVertices[1];
  FSegs[1].v2 := @FVertices[0];
  FSegs[1].linedef := @FLine;
  FSegs[1].frontsector := @FSectors[1];
  if ATwoSided then
  begin
    FSegs[0].backsector := @FSectors[1];
    FSegs[1].backsector := @FSectors[0];
  end;

  FillChar(FSubsectors, SizeOf(FSubsectors), 0);
  FSubsectors[0].sector := @FSectors[0];
  FSubsectors[0].numlines := 1;
  FSubsectors[0].firstline := 0;
  FSubsectors[1].sector := @FSectors[1];
  FSubsectors[1].numlines := 1;
  FSubsectors[1].firstline := 1;

  FillChar(FNodes, SizeOf(FNodes), 0);
  FNodes[0].x := 0;
  FNodes[0].y := -Wall;
  FNodes[0].dx := 0;
  FNodes[0].dy := 2 * Wall;
  // children[0] is the front side (x > 0), children[1] the back side
  FNodes[0].children[0] := LongWord(NF_SUBSECTOR_V5) or 1;
  FNodes[0].children[1] := LongWord(NF_SUBSECTOR_V5);

  numsectors := 2;
  sectors := @FSectors[0];
  numsubsectors := 2;
  subsectors := @FSubsectors[0];
  numsegs := 2;
  segs := @FSegs[0];
  numnodes := 1;
  nodes := @FNodes[0];
  hasvanillanodes := False;
  rejectmatrixsize := 0;
  rejectmatrix := nil;
end;

procedure TTestRulesSight.PlaceThings(const AFirstFloor, ASecondFloor: fixed_t);
begin
  FillChar(FFirst, SizeOf(FFirst), 0);
  FillChar(FSecond, SizeOf(FSecond), 0);
  FFirst.x := -32 * FRACUNIT;
  FFirst.y := 0;
  FFirst.z := AFirstFloor;
  FFirst.floorz := AFirstFloor;
  FFirst.height := 56 * FRACUNIT;
  FFirst.subsector := @FSubsectors[0];
  FSecond.x := 32 * FRACUNIT;
  FSecond.y := 0;
  FSecond.z := ASecondFloor;
  FSecond.floorz := ASecondFloor;
  FSecond.height := 56 * FRACUNIT;
  FSecond.subsector := @FSubsectors[1];
end;

procedure TTestRulesSight.Setup;
begin
  // from 2.07 the side of a point against a horizontal line is the right one (before, the engine compared the x with
  // the y of the line, as the old executable did)
  shim_engineversion := VERSION207;
  TGameSession.DemoPlayback := False;
  TGameSession.DemoRecording := False;
  MakeSector(0, 0, 128 * FRACUNIT);
  MakeSector(1, 0, 128 * FRACUNIT);
  MakeMap(True);
  PlaceThings(0, 0);
end;

procedure TTestRulesSight.TearDown;
begin
  shim_engineversion := 203;
  numsectors := 0;
  sectors := nil;
  subsectors := nil;
  segs := nil;
  nodes := nil;
  numnodes := 0;
  rejectmatrix := nil;
  rejectmatrixsize := 0;
end;

procedure TTestRulesSight.DovrebbeVedereAttraversoUnaLineaConLaStessaAltezzaDaiDueLati;
begin
  Assert.IsTrue(TSightRoutines.P_CheckSight(@FFirst, @FSecond));
end;

procedure TTestRulesSight.DovrebbeNonVedereAttraversoUnMuroAUnSoloLato;
begin
  MakeMap(False);
  Assert.IsFalse(TSightRoutines.P_CheckSight(@FFirst, @FSecond));
end;

procedure TTestRulesSight.DovrebbeNonVedereAttraversoUnaPortaChiusa;
begin
  // the door is the ceiling of the second sector at the floor: nothing is open (opentop <= openbottom)
  MakeSector(1, 0, 0);
  Assert.IsFalse(TSightRoutines.P_CheckSight(@FFirst, @FSecond));
end;

procedure TTestRulesSight.DovrebbeVedereSopraUnSoffittoPiuBassoSeLaCosaEAlta;
begin
  // eyes at 56 - 14 = 42; the ceiling of the second sector is at 40, half way: the slope to the top of the opening
  // is (40 - 42) / 0.5 = -4 units, the top of the thing is at +14 and its feet at -42: the feet are still seen
  MakeSector(1, 0, 40 * FRACUNIT);
  Assert.IsTrue(TSightRoutines.P_CheckSight(@FFirst, @FSecond));
end;

procedure TTestRulesSight.DovrebbeVedereLaCimaDiUnaCosaSuUnGradinoAlto;
begin
  // the floor of the second sector is at 64 and the thing stands on it: eyes at 42, the bottom slope becomes
  // (64 - 42) / 0.5 = 44, the top of the thing is at (64 + 56 - 42) = 78: 78 > 44, seen
  MakeSector(1, 64 * FRACUNIT, 128 * FRACUNIT);
  PlaceThings(0, 64 * FRACUNIT);
  Assert.IsTrue(TSightRoutines.P_CheckSight(@FFirst, @FSecond));
end;

procedure TTestRulesSight.DovrebbeNonVedereUnaCosaNascostaDaUnGradinoPiuAltoDellaSuaCima;
begin
  // the floor is at 100: the bottom slope is (100 - 42) / 0.5 = 116, the top of the thing is at 100 + 56 - 42 = 114:
  // the top is below the bottom of the opening (114 <= 116), hidden
  MakeSector(1, 100 * FRACUNIT, 200 * FRACUNIT);
  PlaceThings(0, 100 * FRACUNIT);
  Assert.IsFalse(TSightRoutines.P_CheckSight(@FFirst, @FSecond));
end;

procedure TTestRulesSight.DovrebbeVedereSimmetricamenteDaiDueVersi;
begin
  Assert.AreEqual(TSightRoutines.P_CheckSight(@FFirst, @FSecond), TSightRoutines.P_CheckSight(@FSecond, @FFirst));
  MakeMap(False);
  Assert.AreEqual(TSightRoutines.P_CheckSight(@FFirst, @FSecond), TSightRoutines.P_CheckSight(@FSecond, @FFirst));
  MakeMap(True);
  MakeSector(1, 0, 0);
  Assert.AreEqual(TSightRoutines.P_CheckSight(@FFirst, @FSecond), TSightRoutines.P_CheckSight(@FSecond, @FFirst));
end;

procedure TTestRulesSight.DovrebbeNonVedereSeLaTabellaRejectDiceCheNonSiVedono;
begin
  // bit s1 * numsectors + s2 = 0 * 2 + 1 = 1 of the first byte
  FReject[0] := 2;
  rejectmatrix := @FReject[0];
  rejectmatrixsize := 1;
  Assert.IsFalse(TSightRoutines.P_CheckSight(@FFirst, @FSecond));
  // another bit: the pair is not rejected
  FReject[0] := 1;
  Assert.IsTrue(TSightRoutines.P_CheckSight(@FFirst, @FSecond));
end;

procedure TTestRulesSight.DovrebbeConfrontareIlPavimentoNelloStessoSettore;
begin
  // two things in the same sector (version 1.22 to 2.03): they see each other when they stand on the same floor
  shim_engineversion := VERSION203;
  FSecond.subsector := @FSubsectors[0];
  FSecond.floorz := FFirst.floorz;
  Assert.IsTrue(TSightRoutines.P_CheckSight(@FFirst, @FSecond));
  FSecond.floorz := FFirst.floorz + 8 * FRACUNIT;
  Assert.IsFalse(TSightRoutines.P_CheckSight(@FFirst, @FSecond));
end;

procedure TTestRulesSight.DovrebbeNonVedereDaUnPianoIntermedioFraLeDueCose;
begin
  // a 3d floor (sector 2) in the sector of the second thing, from 40 to 48: the first thing is at 0..32, below its
  // floor, and the second thing is above it
  MakeSector(2, 40 * FRACUNIT, 48 * FRACUNIT);
  FSectors[1].midsec := 2;
  FFirst.z := 0;
  FFirst.height := 32 * FRACUNIT;
  FSecond.z := 64 * FRACUNIT;
  Assert.IsFalse(TSightRoutines.P_CheckSight(@FFirst, @FSecond));
end;

end.