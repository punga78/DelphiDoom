{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TBinary of DD_IDE (compressed streams of System.ZLib)  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Ide.Binary;

interface

uses
  System.SysUtils, System.Classes, System.ZLib, DUnitX.TestFramework, ide_binary;

type
  [TestFixture]
  [Category('ide')]
  TTestIdeBinary = class(TObject)
  private
    function Pattern(ASize: Integer): TBytes;
    procedure RoundTrip(ASize: Integer; ALevel: TCompressionLevel);
  public
    [Test]
    procedure TestRoundTripDefault;
    [Test]
    procedure TestRoundTripEveryLevel;
    [Test]
    procedure TestEmptyBinary;
    [Test]
    procedure TestCompressedSizeIsReported;
  end;

implementation

{ TTestIdeBinary }

function TTestIdeBinary.Pattern(ASize: Integer): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, ASize);
  for LIndex := 0 to ASize - 1 do
    Result[LIndex] := Byte((LIndex * 7) xor (LIndex shr 5));
end;

procedure TTestIdeBinary.RoundTrip(ASize: Integer; ALevel: TCompressionLevel);
var
  LSource, LTarget: TBinary;
  LStream: TMemoryStream;
  LBytes: TBytes;
begin
  LBytes := Pattern(ASize);
  LSource := TBinary.Create;
  LTarget := TBinary.Create;
  LStream := TMemoryStream.Create;
  try
    if ASize > 0 then
      LSource.Data.Write(LBytes[0], ASize);
    LSource.CompressionLevel := ALevel;
    LSource.SaveToStream(LStream, True);
    LStream.Position := 0;
    LTarget.LoadFromStream(LStream, True);
    Assert.AreEqual(ASize, LTarget.Size);
    if ASize > 0 then
      Assert.IsTrue(CompareMem(LTarget.Memory, @LBytes[0], ASize), 'contents');
  finally
    LStream.Free;
    LTarget.Free;
    LSource.Free;
  end;
end;

procedure TTestIdeBinary.TestRoundTripDefault;
begin
  RoundTrip(100000, clDefault);
end;

procedure TTestIdeBinary.TestRoundTripEveryLevel;
var
  LLevel: TCompressionLevel;
begin
  for LLevel := Low(TCompressionLevel) to High(TCompressionLevel) do
    RoundTrip(70000, LLevel);
end;

procedure TTestIdeBinary.TestEmptyBinary;
begin
  RoundTrip(0, clDefault);
end;

procedure TTestIdeBinary.TestCompressedSizeIsReported;
var
  LSource: TBinary;
  LStream: TMemoryStream;
  LBytes: TBytes;
begin
  SetLength(LBytes, 20000);
  LSource := TBinary.Create;
  LStream := TMemoryStream.Create;
  try
    LSource.Data.Write(LBytes[0], Length(LBytes));
    LSource.SaveToStream(LStream, True);
    Assert.IsTrue(LSource.CompressedSize > 0);
  finally
    LStream.Free;
    LSource.Free;
  end;
end;

end.
