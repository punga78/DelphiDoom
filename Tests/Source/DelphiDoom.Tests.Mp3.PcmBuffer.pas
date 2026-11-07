{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the mp3 library - the samples of a frame                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Mp3.PcmBuffer;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Mp3.PcmBuffer;

type
  [TestFixture]
  [Category('mp3')]
  TTestMp3PcmBuffer = class(TObject)
  public
    [Test]
    procedure DovrebbeIntrecciareICanali;
    [Test]
    procedure DovrebbeRifiutareUnNumeroDiCanaliSbagliato;
    [Test]
    procedure DovrebbeRifiutareUnCanaleFuoriDallUscita;
    [Test]
    procedure DovrebbeRifiutareTroppiCampioni;
    [Test]
    procedure DovrebbeRipartireDaZeroConClearBuffer;
  end;

implementation

{ TTestMp3PcmBuffer }

procedure TTestMp3PcmBuffer.DovrebbeIntrecciareICanali;
var
  LBuffer: TMp3PcmBuffer;
  LSamples: PSmallInt;
begin
  LBuffer := TMp3PcmBuffer.Create(2);
  try
    LBuffer.Append(1, 20);
    LBuffer.Append(0, 10);
    LBuffer.Append(0, 11);
    LBuffer.SetStopFlag;
    Assert.IsFalse(LBuffer.Complete);
    LBuffer.WriteBuffer;
    Assert.IsTrue(LBuffer.Complete);
    Assert.AreEqual(6, LBuffer.ByteCount);
    LSamples := LBuffer.Data;
    Assert.AreEqual(10, Integer(LSamples^));
    Inc(LSamples);
    Assert.AreEqual(20, Integer(LSamples^));
    Inc(LSamples);
    Assert.AreEqual(11, Integer(LSamples^));
  finally
    LBuffer.Free;
  end;
end;

procedure TTestMp3PcmBuffer.DovrebbeRifiutareUnNumeroDiCanaliSbagliato;
begin
  Assert.WillRaise(
    procedure
    begin
      TMp3PcmBuffer.Create(0).Free;
    end,
    EArgumentOutOfRangeException);
  Assert.WillRaise(
    procedure
    begin
      TMp3PcmBuffer.Create(3).Free;
    end,
    EArgumentOutOfRangeException);
end;

procedure TTestMp3PcmBuffer.DovrebbeRifiutareUnCanaleFuoriDallUscita;
var
  LBuffer: TMp3PcmBuffer;
begin
  LBuffer := TMp3PcmBuffer.Create(1);
  try
    Assert.WillRaise(
      procedure
      begin
        LBuffer.Append(1, 0);
      end,
      ERangeError);
  finally
    LBuffer.Free;
  end;
end;

procedure TTestMp3PcmBuffer.DovrebbeRifiutareTroppiCampioni;
var
  LBuffer: TMp3PcmBuffer;
begin
  LBuffer := TMp3PcmBuffer.Create(1);
  try
    Assert.WillRaise(
      procedure
      var
        LIndex: Integer;
      begin
        // more than the samples of a stereo frame
        for LIndex := 0 to 2 * 1152 do
          LBuffer.Append(0, 1);
      end,
      ERangeError);
  finally
    LBuffer.Free;
  end;
end;

procedure TTestMp3PcmBuffer.DovrebbeRipartireDaZeroConClearBuffer;
var
  LBuffer: TMp3PcmBuffer;
begin
  LBuffer := TMp3PcmBuffer.Create(2);
  try
    LBuffer.Append(0, 1);
    LBuffer.WriteBuffer;
    LBuffer.ClearBuffer;
    Assert.AreEqual(0, LBuffer.ByteCount);
    Assert.IsFalse(LBuffer.Complete);
    LBuffer.Append(1, 7);
    Assert.AreEqual(7, Integer(PSmallInt(PByte(LBuffer.Data) + SizeOf(SmallInt))^));
  finally
    LBuffer.Free;
  end;
end;

end.
