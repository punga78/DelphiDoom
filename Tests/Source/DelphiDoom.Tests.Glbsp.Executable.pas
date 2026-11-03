{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the embedded glbsp executable                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Glbsp.Executable;

{
  The program is never run here: these tests only check that the bytes copied
  from Base\nd_main.pas are the whole file and look like a Win32 executable.
}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Glbsp.Executable;

type
  [TestFixture]
  [Category('glbsp')]
  TTestGlbspExecutable = class(TObject)
  private
    function ByteAt(AOffset: Cardinal): Byte;
  public
    [Test]
    procedure TestSizeIs57404;
    [Test]
    procedure TestDataIsAssigned;
    [Test]
    procedure TestStartsWithMZ;
    [Test]
    procedure TestPeHeaderIsWhereTheDosHeaderSays;
    [Test]
    procedure TestLastByteIsReadable;
  end;

implementation

{ TTestGlbspExecutable }

function TTestGlbspExecutable.ByteAt(AOffset: Cardinal): Byte;
begin
  Result := PByte(NativeUInt(GlbspExecutableData) + AOffset)^;
end;

procedure TTestGlbspExecutable.TestSizeIs57404;
begin
  Assert.AreEqual(57404, Integer(GlbspExecutableSize));
  Assert.AreEqual(GLBSP_EXECUTABLE_SIZE, Integer(GlbspExecutableSize));
end;

procedure TTestGlbspExecutable.TestDataIsAssigned;
begin
  Assert.IsTrue(GlbspExecutableData <> nil);
end;

procedure TTestGlbspExecutable.TestStartsWithMZ;
begin
  Assert.AreEqual(Integer($4D), Integer(ByteAt(0)));
  Assert.AreEqual(Integer($5A), Integer(ByteAt(1)));
end;

procedure TTestGlbspExecutable.TestPeHeaderIsWhereTheDosHeaderSays;
var
  LPeOffset: Cardinal;
begin
  // e_lfanew, at offset $3C of the DOS header
  LPeOffset := PCardinal(NativeUInt(GlbspExecutableData) + $3C)^;
  Assert.IsTrue(LPeOffset + 4 < GlbspExecutableSize);
  Assert.AreEqual(Integer(Ord('P')), Integer(ByteAt(LPeOffset)));
  Assert.AreEqual(Integer(Ord('E')), Integer(ByteAt(LPeOffset + 1)));
  Assert.AreEqual(0, Integer(ByteAt(LPeOffset + 2)));
  Assert.AreEqual(0, Integer(ByteAt(LPeOffset + 3)));
end;

procedure TTestGlbspExecutable.TestLastByteIsReadable;
begin
  // Only proves that the array really reaches its declared length
  ByteAt(GlbspExecutableSize - 1);
  Assert.Pass;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGlbspExecutable);

end.
