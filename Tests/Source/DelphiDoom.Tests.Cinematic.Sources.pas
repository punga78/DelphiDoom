{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the sources of the cinematic library                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Cinematic.Sources;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('cinematic')]
  TTestRoqMemorySource = class(TObject)
  public
    [Test]
    procedure DovrebbeLeggereEFermarsiAllaFine;
    [Test]
    procedure DovrebbeRiavvolgereConSeek;
    [Test]
    procedure DovrebbeLimitareSeekAiBordi;
    [Test]
    procedure DovrebbeDareZeroSeVuota;
  end;

  [TestFixture]
  [Category('cinematic')]
  TTestRoqStreamSource = class(TObject)
  public
    [Test]
    procedure DovrebbePartireDallaPosizioneDelloStream;
    [Test]
    procedure DovrebbeLeggereEMuoversi;
  end;

implementation

uses
  System.SysUtils, System.Classes,
  DelphiDoom.Cinematic.Intf,
  DelphiDoom.Cinematic.MemorySource,
  DelphiDoom.Cinematic.StreamSource;

{ TTestRoqMemorySource }

procedure TTestRoqMemorySource.DovrebbeLeggereEFermarsiAllaFine;
var
  LSource: IRoqSource;
  LBuffer: array[0..7] of Byte;
begin
  LSource := TRoqMemorySource.Create(TBytes.Create(1, 2, 3, 4, 5));
  Assert.AreEqual(Int64(5), LSource.Size);
  Assert.AreEqual(3, LSource.Read(LBuffer, 3));
  Assert.AreEqual(3, Integer(LBuffer[2]));
  Assert.AreEqual(Int64(3), LSource.Position);
  Assert.AreEqual(2, LSource.Read(LBuffer, 8));
  Assert.AreEqual(5, Integer(LBuffer[1]));
  Assert.AreEqual(0, LSource.Read(LBuffer, 8));
end;

procedure TTestRoqMemorySource.DovrebbeRiavvolgereConSeek;
var
  LSource: IRoqSource;
  LBuffer: array[0..1] of Byte;
begin
  LSource := TRoqMemorySource.Create(TBytes.Create(9, 8, 7));
  LSource.Read(LBuffer, 2);
  LSource.Seek(0);
  Assert.AreEqual(Int64(0), LSource.Position);
  LSource.Read(LBuffer, 2);
  Assert.AreEqual(9, Integer(LBuffer[0]));
  LSource.Seek(2);
  LSource.Read(LBuffer, 1);
  Assert.AreEqual(7, Integer(LBuffer[0]));
end;

procedure TTestRoqMemorySource.DovrebbeLimitareSeekAiBordi;
var
  LSource: IRoqSource;
begin
  LSource := TRoqMemorySource.Create(TBytes.Create(1, 2, 3));
  LSource.Seek(100);
  Assert.AreEqual(Int64(3), LSource.Position);
  LSource.Seek(-5);
  Assert.AreEqual(Int64(0), LSource.Position);
end;

procedure TTestRoqMemorySource.DovrebbeDareZeroSeVuota;
var
  LSource: IRoqSource;
  LByte: Byte;
begin
  LSource := TRoqMemorySource.Create(nil);
  Assert.AreEqual(Int64(0), LSource.Size);
  Assert.AreEqual(0, LSource.Read(LByte, 1));
end;

{ TTestRoqStreamSource }

procedure TTestRoqStreamSource.DovrebbePartireDallaPosizioneDelloStream;
var
  LStream: TBytesStream;
  LSource: IRoqSource;
  LByte: Byte;
begin
  LStream := TBytesStream.Create(TBytes.Create(1, 2, 3, 4));
  try
    LStream.Position := 2;
    LSource := TRoqStreamSource.Create(LStream);
    Assert.AreEqual(Int64(2), LSource.Size);
    Assert.AreEqual(Int64(0), LSource.Position);
    LSource.Read(LByte, 1);
    Assert.AreEqual(3, Integer(LByte));
    LSource.Seek(0);
    LSource.Read(LByte, 1);
    Assert.AreEqual(3, Integer(LByte));
  finally
    LStream.Free;
  end;
end;

procedure TTestRoqStreamSource.DovrebbeLeggereEMuoversi;
var
  LStream: TBytesStream;
  LSource: IRoqSource;
  LBuffer: array[0..3] of Byte;
begin
  LStream := TBytesStream.Create(TBytes.Create(5, 6, 7));
  try
    LSource := TRoqStreamSource.Create(LStream);
    Assert.AreEqual(3, LSource.Read(LBuffer, 4));
    Assert.AreEqual(Int64(3), LSource.Position);
    Assert.AreEqual(0, LSource.Read(LBuffer, 4));
    LSource.Seek(1);
    Assert.AreEqual(1, LSource.Read(LBuffer, 1));
    Assert.AreEqual(6, Integer(LBuffer[0]));
  finally
    LStream.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRoqMemorySource);
  TDUnitX.RegisterTestFixture(TTestRoqStreamSource);

end.
