{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Wad library - records of the lumps of a level      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Wad.Level;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Wad.Types;

type
  [TestFixture]
  [Category('wad')]
  TTestWadLevelTypes = class(TObject)
  public
    [Test]
    procedure TestSizesOfTheLumpRecords;
    [Test]
    procedure TestSizesOfTheFileRecords;
    [Test]
    procedure TestFieldOffsets;
    [Test]
    procedure TestRecordsHoldNoPointers;
  end;

implementation

uses
  DelphiDoom.Wad.Level.Types;

{ TTestWadLevelTypes }

procedure TTestWadLevelTypes.TestSizesOfTheLumpRecords;
begin
  // the sizes the engine and the other tools expect in the lumps of a level
  Assert.AreEqual(10, SizeOf(TWadThing));
  Assert.AreEqual(20, SizeOf(TWadHexenThing));
  Assert.AreEqual(14, SizeOf(TWadLinedef));
  Assert.AreEqual(16, SizeOf(TWadHexenLinedef));
  Assert.AreEqual(30, SizeOf(TWadSidedef));
  Assert.AreEqual(4, SizeOf(TWadVertex));
  Assert.AreEqual(12, SizeOf(TWadSeg));
  Assert.AreEqual(4, SizeOf(TWadSubsector));
  Assert.AreEqual(28, SizeOf(TWadNode));
  Assert.AreEqual(26, SizeOf(TWadSector));
end;

procedure TTestWadLevelTypes.TestSizesOfTheFileRecords;
begin
  Assert.AreEqual(WAD_HEADER_SIZE, SizeOf(TWadHeader));
  Assert.AreEqual(WAD_DIRECTORY_RECORD_SIZE, SizeOf(TWadDirectoryRecord));
  Assert.AreEqual(PAK_DIRECTORY_RECORD_SIZE, SizeOf(TPakDirectoryRecord));
end;

procedure TTestWadLevelTypes.TestFieldOffsets;
var
  LNode: TWadNode;
  LSidedef: TWadSidedef;
  LHexenThing: TWadHexenThing;
begin
  Assert.AreEqual(8, Integer(NativeInt(@LNode.BoundingBox) - NativeInt(@LNode)));
  Assert.AreEqual(24, Integer(NativeInt(@LNode.Children) - NativeInt(@LNode)));
  Assert.AreEqual(4, Integer(NativeInt(@LSidedef.TopTexture) - NativeInt(@LSidedef)));
  Assert.AreEqual(28, Integer(NativeInt(@LSidedef.Sector) - NativeInt(@LSidedef)));
  Assert.AreEqual(15, Integer(NativeInt(@LHexenThing.Arguments) - NativeInt(@LHexenThing)));
end;

procedure TTestWadLevelTypes.TestRecordsHoldNoPointers;
begin
  // a record of numbers and fixed arrays only is the same on 32 and 64 bits: its size is fixed
  Assert.IsFalse(IsManagedType(TWadThing));
  Assert.IsFalse(IsManagedType(TWadHexenLinedef));
  Assert.IsFalse(IsManagedType(TWadSidedef));
  Assert.IsFalse(IsManagedType(TWadNode));
  Assert.IsFalse(IsManagedType(TWadSector));
end;

end.
