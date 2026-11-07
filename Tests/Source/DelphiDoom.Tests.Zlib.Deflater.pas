{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TZlibDeflater                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Zlib.Deflater;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Zlib.Intf, DelphiDoom.Zlib.Deflater;

type
  [TestFixture]
  [Category('zlib')]
  TTestZlibDeflater = class(TObject)
  private
    function Deflate(ADeflater: TZlibDeflater): Integer;
  public
    [Test]
    procedure DovrebbeRifiutareUnFlussoNonAvviato;
    [Test]
    procedure DovrebbeRifiutareUnLivelloSbagliato;
  end;

implementation

{ TTestZlibDeflater }

function TTestZlibDeflater.Deflate(ADeflater: TZlibDeflater): Integer;
var
  LSource, LDest: TBytes;
  LBuffers: TZlibStreamBuffers;
begin
  LSource := TBytes.Create(1, 2, 3);
  SetLength(LDest, 64);
  LBuffers := Default(TZlibStreamBuffers);
  LBuffers.NextIn := Pointer(LSource);
  LBuffers.AvailIn := Length(LSource);
  LBuffers.NextOut := Pointer(LDest);
  LBuffers.AvailOut := Length(LDest);
  Result := ADeflater.Deflate(LBuffers, ZLIB_FINISH);
end;

procedure TTestZlibDeflater.DovrebbeRifiutareUnFlussoNonAvviato;
var
  LDeflater: TZlibDeflater;
begin
  LDeflater := TZlibDeflater.Create;
  try
    Assert.AreEqual(ZLIB_STREAM_ERROR, Deflate(LDeflater));
  finally
    LDeflater.Free;
  end;
end;

procedure TTestZlibDeflater.DovrebbeRifiutareUnLivelloSbagliato;
var
  LDeflater: TZlibDeflater;
begin
  // zlib knows the levels -1 to 9
  LDeflater := TZlibDeflater.Create;
  try
    Assert.AreEqual(ZLIB_STREAM_ERROR, LDeflater.Start(99));
    Assert.AreEqual(ZLIB_STREAM_ERROR, Deflate(LDeflater));
  finally
    LDeflater.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestZlibDeflater);

end.
