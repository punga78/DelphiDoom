{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the texture definitions library - the names            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.TextureDefs.Names;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('texturedefs')]
  TTestTextureDefsNames = class(TObject)
  public
    [Test]
    procedure TestDecodeStopsAtTheFirstZero;
    [Test]
    procedure TestDecodeReadsEightBytesWithoutTerminator;
    [Test]
    procedure TestDecodeMakesUpperCase;
    [Test]
    procedure TestDecodeStartsAtTheOffset;
    [Test]
    procedure TestUpperAsciiLeavesOtherCharacters;
    [Test]
    procedure TestTrimCutsSpacesAtBothEnds;
    [Test]
    procedure TestTrimOfOnlySpacesIsEmpty;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.TextureDefs.Names;

function Bytes(const AText: string; ALength: Integer): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, ALength);
  for LIndex := 1 to Length(AText) do
    Result[LIndex - 1] := Ord(AText[LIndex]);
end;

{ TTestTextureDefsNames }

procedure TTestTextureDefsNames.TestDecodeStopsAtTheFirstZero;
begin
  Assert.AreEqual('AB', TTextureDefsNames.Decode(Bytes('AB', 8), 0), 'dovrebbe fermarsi al primo zero');
end;

procedure TTestTextureDefsNames.TestDecodeReadsEightBytesWithoutTerminator;
begin
  Assert.AreEqual('ABCDEFGH', TTextureDefsNames.Decode(Bytes('ABCDEFGHIJ', 10), 0),
    'dovrebbe leggere al massimo otto byte');
end;

procedure TTestTextureDefsNames.TestDecodeMakesUpperCase;
begin
  Assert.AreEqual('WALL1', TTextureDefsNames.Decode(Bytes('wAll1', 8), 0), 'dovrebbe dare le maiuscole');
end;

procedure TTestTextureDefsNames.TestDecodeStartsAtTheOffset;
begin
  Assert.AreEqual('XY', TTextureDefsNames.Decode(Bytes('..XY', 12), 2), 'dovrebbe partire dallo scostamento');
end;

procedure TTestTextureDefsNames.TestUpperAsciiLeavesOtherCharacters;
begin
  Assert.AreEqual('A_1-Z', TTextureDefsNames.UpperAscii('a_1-z'), 'dovrebbe cambiare solo a..z');
end;

procedure TTestTextureDefsNames.TestTrimCutsSpacesAtBothEnds;
begin
  Assert.AreEqual('A B', TTextureDefsNames.Trim('  A B '), 'dovrebbe tagliare agli estremi');
end;

procedure TTestTextureDefsNames.TestTrimOfOnlySpacesIsEmpty;
begin
  Assert.AreEqual('', TTextureDefsNames.Trim('   '), 'dovrebbe dare il testo vuoto');
end;

end.
