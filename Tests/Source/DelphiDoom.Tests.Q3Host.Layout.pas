{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III host library - the layout in memory of    }
{  what the system calls share with the modules, against the real headers       }
{  (Tools\Verifica\254\layout.sh, gcc -m32)                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Q3Host.Layout;

interface

uses
  DUnitX.TestFramework, System.Generics.Collections, DelphiDoom.Qvm.Intf, DelphiDoom.Q3Host.Intf;

type
  [TestFixture]
  [Category('Q3Host')]
  TTestQ3HostLayout = class
  strict private
    FValues: TDictionary<string, Integer>;
    FMachine: IQvmMachine;
    function Golden(const AName: string): Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure LeDimensioniDelleStruttureDovrebberoEssereQuelleDelC;
    [Test]
    procedure GliOffsetDellEntitaDovrebberoEssereQuelliDelC;
    [Test]
    procedure IlTraceDovrebbeEssereScrittoComeIlC;
    [Test]
    procedure IlTraceScrittoDovrebbeTornareLetto;
    [Test]
    procedure UnVettoreNulloDovrebbeEssereIlVettoreZero;
  end;

implementation

uses
  System.SysUtils, System.Classes, DelphiDoom.Qvm.Factory, DelphiDoom.Collision.Q3.Types, DelphiDoom.Q3Host.GameWorld,
  DelphiDoom.Q3Host.TraceMemory, DelphiDoom.Tests.Qvm.Programs, DelphiDoom.Tests.Qvm.Support, DelphiDoom.Tests.Shared.Files;

procedure TTestQ3HostLayout.Setup;
var
  LLines: TStringList;
  LLine: string;
  LSplit: Integer;
  LText: Integer;
begin
  FValues := TDictionary<string, Integer>.Create;
  LLines := TTestFiles.Lines(TTestFiles.DataFile('Q3Host', 'layout.golden.txt'));
  try
    for LLine in LLines do
    begin
      LSplit := LLine.LastDelimiter(' ');
      FValues.AddOrSetValue(Copy(LLine, 1, LSplit), StrToInt(Copy(LLine, LSplit + 2, MaxInt)));
    end;
  finally
    LLines.Free;
  end;
  FMachine := TQvmFactory.CreateMachine('layout', TQvmPrograms.AnySystemCall(LText), TQvmNullHost.Create);
end;

procedure TTestQ3HostLayout.TearDown;
begin
  FValues.Free;
end;

function TTestQ3HostLayout.Golden(const AName: string): Integer;
begin
  Assert.IsTrue(FValues.TryGetValue(AName, Result), AName);
end;

procedure TTestQ3HostLayout.LeDimensioniDelleStruttureDovrebberoEssereQuelleDelC;
begin
  Assert.AreEqual(56, Golden('sizeof trace_t'));
  Assert.AreEqual(TQ3TraceMemory.TRACE_SIZE, Golden('sizeof trace_t'));
  Assert.AreEqual(272, Golden('sizeof vmCvar_t'));
  Assert.AreEqual(24, Golden('sizeof usercmd_t'));
  Assert.AreEqual(36, Golden('sizeof qtime_t'));
  Assert.AreEqual(TQ3GameWorld.MAX_GENTITIES, Golden('const MAX_GENTITIES'));
  Assert.AreEqual(TQ3GameWorld.ENTITYNUM_NONE, Golden('const ENTITYNUM_NONE'));
  Assert.AreEqual(TQ3GameWorld.ENTITYNUM_WORLD, Golden('const ENTITYNUM_WORLD'));
  Assert.AreEqual(TQ3GameWorld.SOLID_BMODEL, Golden('const SOLID_BMODEL'));
  Assert.AreEqual(TQ3GameWorld.SVF_CAPSULE, Golden('const SVF_CAPSULE'));
  Assert.AreEqual(TQ3GameWorld.SVF_BOT, Golden('const SVF_BOT'));
end;

procedure TTestQ3HostLayout.GliOffsetDellEntitaDovrebberoEssereQuelliDelC;
var
  LBase: Integer;
begin
  Assert.AreEqual(Golden('entityState_t.number'), TQ3GameWorld.OFFSET_NUMBER);
  Assert.AreEqual(Golden('entityState_t.origin'), TQ3GameWorld.OFFSET_ORIGIN);
  Assert.AreEqual(Golden('entityState_t.angles'), TQ3GameWorld.OFFSET_ANGLES);
  Assert.AreEqual(Golden('entityState_t.modelindex'), TQ3GameWorld.OFFSET_MODELINDEX);
  Assert.AreEqual(Golden('entityState_t.solid'), TQ3GameWorld.OFFSET_SOLID);
  // r follows s, and entityShared_t of g_public.h starts with an entityState_t of its own
  LBase := Golden('sharedEntity_t.r');
  Assert.AreEqual(LBase + Golden('entityShared_t.linked'), TQ3GameWorld.OFFSET_LINKED);
  Assert.AreEqual(LBase + Golden('entityShared_t.linkcount'), TQ3GameWorld.OFFSET_LINKCOUNT);
  Assert.AreEqual(LBase + Golden('entityShared_t.svFlags'), TQ3GameWorld.OFFSET_SVFLAGS);
  Assert.AreEqual(LBase + Golden('entityShared_t.bmodel'), TQ3GameWorld.OFFSET_BMODEL);
  Assert.AreEqual(LBase + Golden('entityShared_t.mins'), TQ3GameWorld.OFFSET_MINS);
  Assert.AreEqual(LBase + Golden('entityShared_t.maxs'), TQ3GameWorld.OFFSET_MAXS);
  Assert.AreEqual(LBase + Golden('entityShared_t.contents'), TQ3GameWorld.OFFSET_CONTENTS);
  Assert.AreEqual(LBase + Golden('entityShared_t.absmin'), TQ3GameWorld.OFFSET_ABSMIN);
  Assert.AreEqual(LBase + Golden('entityShared_t.absmax'), TQ3GameWorld.OFFSET_ABSMAX);
  Assert.AreEqual(LBase + Golden('entityShared_t.currentOrigin'), TQ3GameWorld.OFFSET_CURRENTORIGIN);
  Assert.AreEqual(LBase + Golden('entityShared_t.currentAngles'), TQ3GameWorld.OFFSET_CURRENTANGLES);
  Assert.AreEqual(LBase + Golden('entityShared_t.ownerNum'), TQ3GameWorld.OFFSET_OWNERNUM);
  Assert.AreEqual(Golden('sizeof sharedEntity_t'), TQ3GameWorld.OFFSET_OWNERNUM + 4);
end;

procedure TTestQ3HostLayout.IlTraceDovrebbeEssereScrittoComeIlC;
var
  LTrace: TQ3Trace;
  LAddress: Integer;
  LMemory: IQvmMemory;
begin
  LMemory := FMachine.Memory;
  LAddress := 1000;
  LMemory.Fill(LAddress, $EE, TQ3TraceMemory.TRACE_SIZE + 4);
  LTrace := Default(TQ3Trace);
  LTrace.AllSolid := True;
  LTrace.Fraction := 0.5;
  LTrace.EndPos[0] := 1;
  LTrace.EndPos[2] := 3;
  LTrace.Plane.Normal[1] := -1;
  LTrace.Plane.Dist := 7;
  LTrace.Plane.PlaneType := 4;
  LTrace.Plane.SignBits := 2;
  LTrace.SurfaceFlags := 77;
  LTrace.Contents := 88;
  LTrace.EntityNum := 1022;
  TQ3TraceMemory.WriteTrace(LMemory, LAddress, LTrace);
  Assert.AreEqual(1, LMemory.ReadInt32(LAddress + Golden('trace_t.allsolid')));
  Assert.AreEqual(0, LMemory.ReadInt32(LAddress + Golden('trace_t.startsolid')));
  Assert.AreEqual($3F000000, LMemory.ReadInt32(LAddress + Golden('trace_t.fraction')));
  Assert.AreEqual($3F800000, LMemory.ReadInt32(LAddress + Golden('trace_t.endpos')));
  Assert.AreEqual(Integer($BF800000), LMemory.ReadInt32(LAddress + Golden('trace_t.plane') + 4));
  Assert.AreEqual($40E00000, LMemory.ReadInt32(LAddress + Golden('trace_t.plane') + Golden('cplane_t.dist')));
  Assert.AreEqual(4, Integer(LMemory.ReadByte(LAddress + Golden('trace_t.plane') + Golden('cplane_t.type'))));
  Assert.AreEqual(2, Integer(LMemory.ReadByte(LAddress + Golden('trace_t.plane') + Golden('cplane_t.signbits'))));
  // the padding of the plane is zero, as after the memset of the C
  Assert.AreEqual(0, Integer(LMemory.ReadByte(LAddress + Golden('trace_t.plane') + Golden('cplane_t.signbits') + 1)));
  Assert.AreEqual(77, LMemory.ReadInt32(LAddress + Golden('trace_t.surfaceFlags')));
  Assert.AreEqual(88, LMemory.ReadInt32(LAddress + Golden('trace_t.contents')));
  Assert.AreEqual(1022, LMemory.ReadInt32(LAddress + Golden('trace_t.entityNum')));
  // and nothing after the 56 bytes
  Assert.AreEqual($EE, Integer(LMemory.ReadByte(LAddress + 56)));
end;

procedure TTestQ3HostLayout.IlTraceScrittoDovrebbeTornareLetto;
var
  LTrace, LRead: TQ3Trace;
begin
  LTrace := Default(TQ3Trace);
  LTrace.StartSolid := True;
  LTrace.Fraction := 0.25;
  LTrace.EndPos[1] := 12.5;
  LTrace.Plane.Normal[2] := 1;
  LTrace.Plane.Dist := -3;
  LTrace.Plane.PlaneType := 2;
  LTrace.Plane.SignBits := 1;
  LTrace.SurfaceFlags := 5;
  LTrace.Contents := 6;
  LTrace.EntityNum := 9;
  TQ3TraceMemory.WriteTrace(FMachine.Memory, 2000, LTrace);
  LRead := TQ3TraceMemory.ReadTrace(FMachine.Memory, 2000);
  Assert.IsTrue(CompareMem(@LTrace, @LRead, SizeOf(LTrace)) or
    ((LRead.StartSolid = LTrace.StartSolid) and (LRead.Fraction = LTrace.Fraction) and
    (LRead.EndPos[1] = 12.5) and (LRead.Plane.Dist = -3) and (LRead.EntityNum = 9) and (LRead.Plane.SignBits = 1)));
end;

procedure TTestQ3HostLayout.UnVettoreNulloDovrebbeEssereIlVettoreZero;
var
  LVector: TQ3Vec3;
begin
  FMachine.Memory.WriteInt32(3000, $3F800000);
  LVector := TQ3TraceMemory.ReadVec3(FMachine.Memory, 0);
  Assert.AreEqual(Single(0), LVector[0]);
  Assert.AreEqual(Single(0), LVector[2]);
  LVector := TQ3TraceMemory.ReadVec3(FMachine.Memory, 3000);
  Assert.AreEqual(Single(1), LVector[0]);
end;

end.
