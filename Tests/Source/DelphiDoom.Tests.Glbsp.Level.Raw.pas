{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the level records of the glbsp port                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Glbsp.Level.Raw;

interface

uses
  DUnitX.TestFramework,
  DelphiDoom.Glbsp.Level.Raw,
  DelphiDoom.Glbsp.Level.Types;

type
  [TestFixture]
  [Category('glbsp')]
  TTestGlbspLevelRaw = class(TObject)
  public
    // The sizes are those of the C structures of glbsp: they decide how the
    // lumps are read and written
    [Test]
    procedure TestDimensioniDeiRecordDelLivello;
    [Test]
    procedure TestDimensioniDeiRecordDeiNodi;
    [Test]
    procedure TestSuperBloccoFoglia;
  end;

implementation

procedure TTestGlbspLevelRaw.TestDimensioniDeiRecordDelLivello;
begin
  Assert.AreEqual(8, SizeOf(TRawBlockmapHeader));
  Assert.AreEqual(4, SizeOf(TRawVertex));
  Assert.AreEqual(8, SizeOf(TRawV2Vertex));
  Assert.AreEqual(14, SizeOf(TRawLinedef));
  Assert.AreEqual(16, SizeOf(TRawHexenLinedef));
  Assert.AreEqual(30, SizeOf(TRawSidedef));
  Assert.AreEqual(26, SizeOf(TRawSector));
  Assert.AreEqual(10, SizeOf(TRawThing));
  Assert.AreEqual(20, SizeOf(TRawHexenThing));
end;

procedure TTestGlbspLevelRaw.TestDimensioniDeiRecordDeiNodi;
begin
  Assert.AreEqual(12, SizeOf(TRawSeg));
  Assert.AreEqual(10, SizeOf(TRawGLSeg));
  Assert.AreEqual(16, SizeOf(TRawV3Seg));
  Assert.AreEqual(8, SizeOf(TRawBBox));
  Assert.AreEqual(28, SizeOf(TRawNode));
  Assert.AreEqual(4, SizeOf(TRawSubsector));
  Assert.AreEqual(8, SizeOf(TRawV3Subsector));
  Assert.AreEqual(32, SizeOf(TRawV5Node));
end;

procedure TTestGlbspLevelRaw.TestSuperBloccoFoglia;
var
  LBlock: TGlbspSuperBlock;
begin
  LBlock := TGlbspSuperBlock.Create;
  try
    LBlock.X1 := 0;
    LBlock.Y1 := 0;
    LBlock.X2 := 256;
    LBlock.Y2 := 256;
    Assert.IsTrue(LBlock.IsLeaf);

    LBlock.X2 := 512;
    Assert.IsFalse(LBlock.IsLeaf);
  finally
    LBlock.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGlbspLevelRaw);

end.
