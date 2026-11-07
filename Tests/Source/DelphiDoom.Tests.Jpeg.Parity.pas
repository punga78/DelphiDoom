{******************************************************************************}
{                                                                              }
{  DelphiDoom: parity tests of the JPEG decoder with the old one (IJG 6b)      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Jpeg.Parity;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections,
  DUnitX.TestFramework, DelphiDoom.Jpeg.Intf;

type
  /// <summary>
  ///   The decoder gives, for every stream of TJpegCases, the same answers as
  ///   the decoder translated letter by letter from libjpeg 6b that it
  ///   replaced: the same result code, the same size and, when the stream is
  ///   decoded, the same pixels. The answers of the old decoder are kept as
  ///   fingerprints in Tests\Data\Jpeg\jpeg_golden.txt
  /// </summary>
  [TestFixture]
  [Category('jpeg')]
  TTestJpegParity = class(TObject)
  private
    FJpeg: IJpeg;
    function DataPath(const AFileName: string): string;
    function LoadGolden: TDictionary<string, string>;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestSameAnswersAsTheOldDecoder;
    [Test]
    procedure TestCasesHaveDistinctNames;
    [Test]
    procedure TestSomeStreamsAreDecoded;
  end;

implementation

uses
  DelphiDoom.Jpeg.Engine, DelphiDoom.Tests.Jpeg.Cases,
  DelphiDoom.Tests.Jpeg.Observer;

{ TTestJpegParity }

procedure TTestJpegParity.Setup;
begin
  FJpeg := TJpegEngine.Create;
end;

procedure TTestJpegParity.TearDown;
begin
  FJpeg := nil;
end;

function TTestJpegParity.DataPath(const AFileName: string): string;
begin
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\Tests\Data\Jpeg\' + AFileName));
end;

function TTestJpegParity.LoadGolden: TDictionary<string, string>;
var
  LLines: TStringList;
  LLine: string;
  LTab: Integer;
begin
  Result := TDictionary<string, string>.Create;
  LLines := TStringList.Create;
  try
    LLines.LoadFromFile(DataPath('jpeg_golden.txt'));
    for LLine in LLines do
    begin
      LTab := Pos(#9, LLine);
      if LTab > 0 then
        Result.Add(Copy(LLine, 1, LTab - 1), Copy(LLine, LTab + 1, MaxInt));
    end;
  finally
    LLines.Free;
  end;
end;

procedure TTestJpegParity.TestSameAnswersAsTheOldDecoder;
var
  LGolden: TDictionary<string, string>;
  LCases: TArray<TJpegCase>;
  LCase: TJpegCase;
  LExpected: string;
  LActual: string;
  LFailures: TStringList;
  LChecked: Integer;
begin
  LGolden := LoadGolden;
  LFailures := TStringList.Create;
  try
    LCases := TJpegCases.All;
    LChecked := 0;
    for LCase in LCases do
    begin
      if not LGolden.TryGetValue(LCase.Name, LExpected) then
      begin
        LFailures.Add(LCase.Name + ': not in the golden file');
        Continue;
      end;
      LActual := IntToHex(TJpegObserver.Fingerprint(FJpeg, LCase.Data), 16);
      if LActual <> LExpected then
        LFailures.Add(LCase.Name + ': ' + LActual + ' instead of ' + LExpected);
      Inc(LChecked);
    end;
    Assert.AreEqual(LGolden.Count, Length(LCases), 'Cases and golden entries');
    Assert.AreEqual(0, LFailures.Count, Format('%d of %d streams differ:'#13#10'%s',
      [LFailures.Count, Length(LCases), Copy(LFailures.Text, 1, 3000)]));
    Assert.IsTrue(LChecked > 500, 'Too few streams');
  finally
    LFailures.Free;
    LGolden.Free;
  end;
end;

procedure TTestJpegParity.TestCasesHaveDistinctNames;
var
  LNames: TDictionary<string, Boolean>;
  LCase: TJpegCase;
begin
  LNames := TDictionary<string, Boolean>.Create;
  try
    for LCase in TJpegCases.All do
    begin
      Assert.IsFalse(LNames.ContainsKey(LCase.Name), 'Twice: ' + LCase.Name);
      LNames.Add(LCase.Name, True);
    end;
  finally
    LNames.Free;
  end;
end;

procedure TTestJpegParity.TestSomeStreamsAreDecoded;
var
  LCase: TJpegCase;
  LInfo: TJpegInfo;
  LPixels: TBytes;
  LDecoded: Integer;
begin
  // The corpus is of no use if most of it is refused: count the streams that
  // decode (the number comes from the old decoder)
  LDecoded := 0;
  for LCase in TJpegCases.All do
  begin
    if FJpeg.GetInfo(Pointer(LCase.Data), Length(LCase.Data), LInfo) <> DDJPEG_OK then
      Continue;
    SetLength(LPixels, LInfo.Width * LInfo.Height * LInfo.Components);
    if FJpeg.Decode(Pointer(LCase.Data), Length(LCase.Data), Pointer(LPixels),
         Length(LPixels), LInfo) = DDJPEG_OK then
      Inc(LDecoded);
  end;
  Assert.IsTrue(LDecoded > 400, Format('Only %d streams decode', [LDecoded]));
end;

end.
