{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the idLib hashing - MD4                                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.IdLib.Hashing.Md4;

interface

uses
  DUnitX.TestFramework;

type
  /// <summary>Parity of TIdMd4 with MD4_Init/Update/Final/BlockChecksum of the C++ idLib</summary>
  [TestFixture]
  [Category('idlib')]
  TTestIdLibMd4 = class(TObject)
  public
    [Test]
    procedure DovrebbeDareLeStesseRispostePerIlCppSuTuttiIBuffer;
    [Test]
    procedure DovrebbeDareIVettoriDellaRfc1320;
  end;

implementation

uses
  System.SysUtils, System.Classes, DelphiDoom.IdLib.Hashing.Types, DelphiDoom.IdLib.Hashing.Md4,
  DelphiDoom.Tests.IdLib.Golden, DelphiDoom.Tests.IdLib.Hashing.Cases;

function TextDigest(const AText: AnsiString): string;
begin
  Result := TIdDigests.ToHex(TIdMd4.Digest(AText[1], Length(AText)));
end;

procedure TTestIdLibMd4.DovrebbeDareLeStesseRispostePerIlCppSuTuttiIBuffer;
var
  LGolden: TIdLibGolden;
  LActual: TStringList;
begin
  LGolden := TIdLibGolden.Create('hashing.golden.txt');
  LActual := TStringList.Create;
  try
    LGolden.Select(['md4', 'md4c']);
    TIdLibHashingCases.ForEach(
      procedure(AName: string; ABytes: TBytes)
      var
        LHash: TIdMd4;
        LOffset, LPiece: Integer;
      begin
        LActual.Add(Format('md4 %s %s %s', [AName,
          TIdDigests.ToHex(TIdMd4.Digest(TIdLibHashingCases.Ptr(ABytes)^, Length(ABytes))),
          LowerCase(IntToHex(TIdMd4.BlockChecksum(TIdLibHashingCases.Ptr(ABytes)^, Length(ABytes)), 8))]));
        LHash := TIdMd4.Create;
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
          LActual.Add(Format('md4c %s %s', [AName, TIdDigests.ToHex(LHash.Final)]));
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

procedure TTestIdLibMd4.DovrebbeDareIVettoriDellaRfc1320;
var
  LEmpty: Byte;
begin
  LEmpty := 0;
  Assert.AreEqual('31d6cfe0d16ae931b73c59d7e0c089c0', TIdDigests.ToHex(TIdMd4.Digest(LEmpty, 0)));
  Assert.AreEqual('bde52cb31de33e46245e05fbdbd6fb24', TextDigest('a'));
  Assert.AreEqual('a448017aaf21d8525fc10ae87aa6729d', TextDigest('abc'));
  Assert.AreEqual('d9130a8164549fe818874806e1c7014b', TextDigest('message digest'));
  Assert.AreEqual('d79e1c308aa5bbcdeea8ed63df412da9', TextDigest('abcdefghijklmnopqrstuvwxyz'));
  Assert.AreEqual('e33b4ddc9c38f2199c3e7b164fcc0536',
    TextDigest('12345678901234567890123456789012345678901234567890123456789012345678901234567890'));
end;

end.
