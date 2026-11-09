{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom formats library - the .BDY pictures            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (no code of OpenXcom in this unit)                                           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Xcom.BdyDecoder;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Image, DelphiDoom.Xcom.Intf;

type
  [TestFixture]
  [Category('xcom')]
  TTestXcomBdyDecoder = class(TObject)
  private
    FDecoder: IXcomImageDecoder;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeRipetereUnByte;
    [Test]
    procedure DovrebbeCopiareUnaSequenzaDiByte;
    [Test]
    procedure DovrebbeFermareUnaRipetizioneAFineRiga;
    [Test]
    procedure DovrebbeScartareUnaSequenzaCheEntraNellaRigaDopo;
    [Test]
    procedure DovrebbeUsareILimitiDelleSequenze;
    [Test]
    procedure DovrebbeRiusareIlByteSeIlFileFinisceDopoUnaRipetizione;
    [Test]
    procedure DovrebbeRiusareIlByteSeIlFileFinisceInUnaSequenza;
    [Test]
    procedure DovrebbeDareUnImmagineVuotaPerUnFileVuoto;
  end;

implementation

uses
  DelphiDoom.Xcom.Factory, DelphiDoom.Tests.Xcom.Builders;

{ TTestXcomBdyDecoder }

procedure TTestXcomBdyDecoder.Setup;
begin
  FDecoder := TXcomFactory.CreateBdyDecoder;
end;

procedure TTestXcomBdyDecoder.TearDown;
begin
  FDecoder := nil;
end;

procedure TTestXcomBdyDecoder.DovrebbeRipetereUnByte;
begin
  // $FE = 254: 257 - 254 = 3 copies of 5
  Assert.AreEqual('05 05 05 00', TXcomTestBuilders.Pixels(FDecoder.Decode(TXcomTestBuilders.Bytes([$FE, 5]), 4, 1)));
end;

procedure TTestXcomBdyDecoder.DovrebbeCopiareUnaSequenzaDiByte;
begin
  // 2: 1 + 2 = 3 bytes that follow
  Assert.AreEqual('0A 0B 0C 00', TXcomTestBuilders.Pixels(FDecoder.Decode(TXcomTestBuilders.Bytes([2, $A, $B, $C]), 4, 1)));
end;

procedure TTestXcomBdyDecoder.DovrebbeFermareUnaRipetizioneAFineRiga;
begin
  // 4 copies asked, the row has 2 pixels: the run stops with the row
  Assert.AreEqual('09 09 07 00', TXcomTestBuilders.Pixels(FDecoder.Decode(TXcomTestBuilders.Bytes([$FD, 9, 0, 7]), 2, 2)));
end;

procedure TTestXcomBdyDecoder.DovrebbeScartareUnaSequenzaCheEntraNellaRigaDopo;
begin
  // 4 bytes in a row of 2: only the ones of the first row are put, the others are read and thrown away
  Assert.AreEqual('01 02 00 00', TXcomTestBuilders.Pixels(FDecoder.Decode(TXcomTestBuilders.Bytes([3, 1, 2, 3, 4]), 2, 2)));
end;

procedure TTestXcomBdyDecoder.DovrebbeUsareILimitiDelleSequenze;
begin
  // 128 is the longest run of bytes that follow (1 + 128 would be 129 and that is a repetition), 129 repeats 128 times
  Assert.AreEqual('00 03 00', TXcomTestBuilders.Pixels(FDecoder.Decode(TXcomTestBuilders.Bytes([0, 0, 0, 3]), 3, 1)));
  Assert.AreEqual('04 04', TXcomTestBuilders.Pixels(FDecoder.Decode(TXcomTestBuilders.Bytes([129, 4]), 2, 1)));
end;

procedure TTestXcomBdyDecoder.DovrebbeRiusareIlByteSeIlFileFinisceDopoUnaRipetizione;
begin
  // the count of the run is the last byte of the file: the pixel is the count itself, as in the C++
  Assert.AreEqual('FE FE FE', TXcomTestBuilders.Pixels(FDecoder.Decode(TXcomTestBuilders.Bytes([$FE]), 3, 1)));
end;

procedure TTestXcomBdyDecoder.DovrebbeRiusareIlByteSeIlFileFinisceInUnaSequenza;
begin
  Assert.AreEqual('01 02 02', TXcomTestBuilders.Pixels(FDecoder.Decode(TXcomTestBuilders.Bytes([2, 1, 2]), 3, 1)));
end;

procedure TTestXcomBdyDecoder.DovrebbeDareUnImmagineVuotaPerUnFileVuoto;
begin
  Assert.AreEqual('00 00', TXcomTestBuilders.Pixels(FDecoder.Decode(nil, 2, 1)));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomBdyDecoder);

end.
