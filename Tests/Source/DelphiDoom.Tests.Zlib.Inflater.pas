{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TZlibInflater                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Zlib.Inflater;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Zlib.Intf, DelphiDoom.Zlib.Inflater;

type
  [TestFixture]
  [Category('zlib')]
  TTestZlibInflater = class(TObject)
  private
    function Inflate(AInflater: TZlibInflater; const ASource: TBytes;
      out ADest: TBytes): Integer;
  public
    [Test]
    procedure DovrebbeRifiutareUnFlussoNonAvviato;
    [Test]
    procedure DovrebbeDareErroreDiDatiSeServeUnDizionario;
    [Test]
    procedure DovrebbeDecomprimereUnFlussoAvviato;
  end;

implementation

uses
  DelphiDoom.Tests.Zlib.Streams;

const
  ZLIB_WINDOW_BITS = 15;

{ TTestZlibInflater }

function TTestZlibInflater.Inflate(AInflater: TZlibInflater; const ASource: TBytes;
  out ADest: TBytes): Integer;
var
  LBuffers: TZlibStreamBuffers;
begin
  SetLength(ADest, 64);
  LBuffers := Default(TZlibStreamBuffers);
  LBuffers.NextIn := Pointer(ASource);
  LBuffers.AvailIn := Length(ASource);
  LBuffers.NextOut := Pointer(ADest);
  LBuffers.AvailOut := Length(ADest);
  Result := AInflater.Inflate(LBuffers, ZLIB_FINISH);
  SetLength(ADest, LBuffers.TotalOut);
end;

procedure TTestZlibInflater.DovrebbeRifiutareUnFlussoNonAvviato;
var
  LInflater: TZlibInflater;
  LDest: TBytes;
begin
  LInflater := TZlibInflater.Create;
  try
    Assert.AreEqual(ZLIB_STREAM_ERROR, Inflate(LInflater, TZlibTestStreams.ZlibOfAbc, LDest));
  finally
    LInflater.Free;
  end;
end;

procedure TTestZlibInflater.DovrebbeDareErroreDiDatiSeServeUnDizionario;
var
  LInflater: TZlibInflater;
  LDest: TBytes;
begin
  LInflater := TZlibInflater.Create;
  try
    Assert.AreEqual(ZLIB_OK, LInflater.Start(ZLIB_WINDOW_BITS));
    Assert.AreEqual(ZLIB_DATA_ERROR,
      Inflate(LInflater, TZlibTestStreams.ZlibThatNeedsADictionary, LDest));
  finally
    LInflater.Free;
  end;
end;

procedure TTestZlibInflater.DovrebbeDecomprimereUnFlussoAvviato;
var
  LInflater: TZlibInflater;
  LDest: TBytes;
begin
  LInflater := TZlibInflater.Create;
  try
    Assert.AreEqual(ZLIB_OK, LInflater.Start(ZLIB_WINDOW_BITS));
    Assert.AreEqual(ZLIB_STREAM_END, Inflate(LInflater, TZlibTestStreams.ZlibOfAbc, LDest));
    Assert.AreEqual<Integer>(3, Length(LDest));
    Assert.AreEqual(Ord('a'), Integer(LDest[0]));
  finally
    LInflater.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestZlibInflater);

end.
