{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the idLib hashing - CRC-32 (the one of MathCore)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.IdLib.Hashing.Crc32;

interface

uses
  DUnitX.TestFramework;

type
  /// <summary>
  ///   idLib CRC32_BlockChecksum is the standard CRC-32: Libs\MathCore (TCrc32) already has it,
  ///   so idLib gets no class of its own. This fixture shows that the two agree.
  /// </summary>
  [TestFixture]
  [Category('idlib')]
  TTestIdLibCrc32 = class(TObject)
  public
    [Test]
    procedure DovrebbeDareLeStesseRispostePerIlCppSuTuttiIBuffer;
  end;

implementation

uses
  System.SysUtils, System.Classes, DelphiDoom.MathCore.Crc32, DelphiDoom.Tests.IdLib.Golden,
  DelphiDoom.Tests.IdLib.Hashing.Cases;

procedure TTestIdLibCrc32.DovrebbeDareLeStesseRispostePerIlCppSuTuttiIBuffer;
var
  LGolden: TIdLibGolden;
  LActual: TStringList;
begin
  LGolden := TIdLibGolden.Create('hashing.golden.txt');
  LActual := TStringList.Create;
  try
    LGolden.Select(['crc32', 'crc32c']);
    TIdLibHashingCases.ForEach(
      procedure(AName: string; ABytes: TBytes)
      var
        LCrc: TCrc32;
        LOffset, LPiece: Integer;
      begin
        LActual.Add(Format('crc32 %s %s', [AName,
          LowerCase(IntToHex(TCrc32.Calculate(TIdLibHashingCases.Ptr(ABytes)^, Length(ABytes)), 8))]));
        LCrc := TCrc32.Create;
        try
          LOffset := 0;
          while LOffset < Length(ABytes) do
          begin
            LPiece := Length(ABytes) - LOffset;
            if LPiece > 5 then
              LPiece := 5;
            LCrc.Update(ABytes[LOffset], LPiece);
            Inc(LOffset, LPiece);
          end;
          LActual.Add(Format('crc32c %s %s', [AName, LowerCase(IntToHex(LCrc.Value, 8))]));
        finally
          LCrc.Free;
        end;
      end);
    LGolden.Compare(LActual);
  finally
    LActual.Free;
    LGolden.Free;
  end;
end;

end.
