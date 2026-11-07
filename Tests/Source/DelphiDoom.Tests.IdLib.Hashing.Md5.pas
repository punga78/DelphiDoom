{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the idLib hashing - MD5                                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.IdLib.Hashing.Md5;

interface

uses
  DUnitX.TestFramework;

type
  /// <summary>Parity of TIdMd5 with MD5_Init/Update/Final/BlockChecksum of the C++ idLib</summary>
  [TestFixture]
  [Category('idlib')]
  TTestIdLibMd5 = class(TObject)
  public
    [Test]
    procedure DovrebbeDareLeStesseRispostePerIlCppSuTuttiIBuffer;
    [Test]
    procedure DovrebbeDareIVettoriDellaRfc1321;
    [Test]
    procedure DovrebbeRipartireDaZeroDopoFinal;
  end;

implementation

uses
  System.SysUtils, System.Classes, DelphiDoom.IdLib.Hashing.Types, DelphiDoom.IdLib.Hashing.Md5,
  DelphiDoom.Tests.IdLib.Golden, DelphiDoom.Tests.IdLib.Hashing.Cases;

function TextDigest(const AText: AnsiString): string;
begin
  Result := TIdDigests.ToHex(TIdMd5.Digest(AText[1], Length(AText)));
end;

procedure TTestIdLibMd5.DovrebbeDareLeStesseRispostePerIlCppSuTuttiIBuffer;
var
  LGolden: TIdLibGolden;
  LActual: TStringList;
begin
  LGolden := TIdLibGolden.Create('hashing.golden.txt');
  LActual := TStringList.Create;
  try
    LGolden.Select(['md5', 'md5c']);
    TIdLibHashingCases.ForEach(
      procedure(AName: string; ABytes: TBytes)
      var
        LHash: TIdMd5;
        LOffset, LPiece: Integer;
      begin
        LActual.Add(Format('md5 %s %s %s', [AName,
          TIdDigests.ToHex(TIdMd5.Digest(TIdLibHashingCases.Ptr(ABytes)^, Length(ABytes))),
          LowerCase(IntToHex(TIdMd5.BlockChecksum(TIdLibHashingCases.Ptr(ABytes)^, Length(ABytes)), 8))]));
        LHash := TIdMd5.Create;
        try
          LOffset := 0;
          while LOffset < Length(ABytes) do
          begin
            LPiece := Length(ABytes) - LOffset;
            if LPiece > 7 then
              LPiece := 7;
            LHash.Update(ABytes[LOffset], LPiece);
            Inc(LOffset, LPiece);
          end;
          LActual.Add(Format('md5c %s %s', [AName, TIdDigests.ToHex(LHash.Final)]));
        finally
          LHash.Free;
        end;
      end);
    LGolden.Compare(LActual);
  finally
    LActual.Free;
    LGolden.Free;
  end;
end;

procedure TTestIdLibMd5.DovrebbeDareIVettoriDellaRfc1321;
var
  LEmpty: Byte;
begin
  LEmpty := 0;
  Assert.AreEqual('d41d8cd98f00b204e9800998ecf8427e', TIdDigests.ToHex(TIdMd5.Digest(LEmpty, 0)));
  Assert.AreEqual('0cc175b9c0f1b6a831c399e269772661', TextDigest('a'));
  Assert.AreEqual('900150983cd24fb0d6963f7d28e17f72', TextDigest('abc'));
  Assert.AreEqual('f96b697d7cb7938d525a2f31aaf161d0', TextDigest('message digest'));
  Assert.AreEqual('c3fcd3d76192e4007dfb496cca67e13b', TextDigest('abcdefghijklmnopqrstuvwxyz'));
  Assert.AreEqual('57edf4a22be3c955ac49da2e2107b67a',
    TextDigest('12345678901234567890123456789012345678901234567890123456789012345678901234567890'));
end;

procedure TTestIdLibMd5.DovrebbeRipartireDaZeroDopoFinal;
var
  LHash: TIdMd5;
  LText: AnsiString;
begin
  LText := 'abc';
  LHash := TIdMd5.Create;
  try
    LHash.Update(LText[1], 3);
    LHash.Final;
    LHash.Update(LText[1], 3);
    Assert.AreEqual('900150983cd24fb0d6963f7d28e17f72', TIdDigests.ToHex(LHash.Final));
  finally
    LHash.Free;
  end;
end;

end.
