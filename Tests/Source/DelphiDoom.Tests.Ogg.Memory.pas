{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TOggMemory                                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Ogg.Memory;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('ogg')]
  TTestOggMemory = class(TObject)
  public
    [Test]
    procedure DovrebbeDareUnBloccoDiZeri;
    [Test]
    procedure DovrebbeDareNilSeLaMemoriaNonBasta;
    [Test]
    procedure DovrebbeAllocareSeSiRiallocaNil;
    [Test]
    procedure DovrebbeTenereIlBloccoSeNonPuoCrescere;
    [Test]
    procedure DovrebbeAccettareNilDaLiberare;
  end;

implementation

uses
  DelphiDoom.Ogg.Memory;

const
  // More than a process can ever have, at 32 and 64 bit
  TOO_MUCH = High(NativeInt) - 1024;

{ TTestOggMemory }

procedure TTestOggMemory.DovrebbeDareUnBloccoDiZeri;
var
  LBlock: PByte;
  LIndex: Integer;
begin
  LBlock := TOggMemory.Allocate(100);
  try
    for LIndex := 0 to 99 do
      Assert.AreEqual(0, Integer(LBlock[LIndex]));
  finally
    TOggMemory.Release(LBlock);
  end;
end;

procedure TTestOggMemory.DovrebbeDareNilSeLaMemoriaNonBasta;
begin
  Assert.IsNull(TOggMemory.Allocate(TOO_MUCH));
end;

procedure TTestOggMemory.DovrebbeAllocareSeSiRiallocaNil;
var
  LBlock: PByte;
begin
  LBlock := TOggMemory.Reallocate(nil, 16);
  try
    Assert.IsNotNull(LBlock);
    Assert.AreEqual(0, Integer(LBlock[15]));
  finally
    TOggMemory.Release(LBlock);
  end;
end;

procedure TTestOggMemory.DovrebbeTenereIlBloccoSeNonPuoCrescere;
var
  LBlock: PByte;
begin
  LBlock := TOggMemory.Allocate(16);
  try
    LBlock[3] := 42;
    Assert.IsNull(TOggMemory.Reallocate(LBlock, TOO_MUCH));
    // The old block is still the caller's, with what it held
    Assert.AreEqual(42, Integer(LBlock[3]));
  finally
    TOggMemory.Release(LBlock);
  end;
end;

procedure TTestOggMemory.DovrebbeAccettareNilDaLiberare;
begin
  TOggMemory.Release(nil);
  Assert.Pass;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestOggMemory);

end.
