{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom formats library - .LBM files                  }
{                                                                              }
{  Tests\Data\Xcom\lbm.corpus.txt (one IFF file in hex per line, made by        }
{  Tools\Verifica\176\lbm\lbmharness.cpp) and lbm.golden.txt (what the real     }
{  IMG_Load of SDL_image 1.2.12 made of each: width, height, depth, color key,  }
{  palette, FNV-1a of the pixels). The real files of TFTD (UFOGRAPH\D0..D3.LBM  }
{  and the others) are compared with Reference\_dati\xcom_tftd\lbm_golden.txt,  }
{  that is not in the repository, if it is on this machine                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (no code of OpenXcom in this unit)                                           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Xcom.LbmReader;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Tests.Xcom.Skip, DelphiDoom.Xcom.Intf;

type
  [TestFixture]
  [Category('xcom')]
  [Category('xcom-golden')]
  TTestXcomLbmReader = class(TObject)
  private
    function Describe(const AReader: IXcomLbmReader; const ABytes: TBytes): string;
    function DataFile(const AName: string): string;
  public
    [Test]
    procedure DovrebbeLeggereGliLbmComeSdlImage;
    [Test]
    procedure DovrebbeLeggereILbmVeriDiTftdComeSdlImage;
    [Test]
    procedure DovrebbeRifiutareUnFileCheNonEIff;
    [Test]
    procedure DovrebbeRifiutareUnFileTroncato;
    [Test]
    procedure DovrebbeRifiutareUnTipoDiversoDaPbmEIlbm;
    [Test]
    procedure DovrebbeRifiutareUnFileSenzaIntestazione;
    [Test]
    procedure DovrebbeLeggereUnPbmSenzaCompressioneConLaPalette;
    [Test]
    procedure DovrebbeUsareIlNeroPerLeCopieMancantiDellaPalette;
    [Test]
    procedure DovrebbeRifiutareUnaPaletteDiPiuDi256Colori;
    [Test]
    procedure DovrebbeRifiutareUnPbmConPiuDiOttoPiani;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Palette, DelphiDoom.Xcom.Image, DelphiDoom.Xcom.Factory,
  DelphiDoom.Tests.Xcom.RealData;

function HexToBytes(const AHex: string): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(AHex) div 2);
  for LIndex := 0 to High(Result) do
    Result[LIndex] := StrToInt('$' + Copy(AHex, LIndex * 2 + 1, 2));
end;

function IffBytes(const AType: AnsiString; AWidth, AHeight, APlanes, AMasking, ACompression: Integer;
  const AColors: array of Byte; const ABody: array of Byte): TBytes;
var
  LStream: TBytesStream;

  procedure PutId(const AId: AnsiString);
  begin
    LStream.WriteBuffer(AId[1], 4);
  end;

  procedure Put(AValue: Integer; ACount: Integer);
  var
    LIndex: Integer;
    LByte: Byte;
  begin
    for LIndex := ACount - 1 downto 0 do
    begin
      LByte := (AValue shr (LIndex * 8)) and $FF;
      LStream.WriteBuffer(LByte, 1);
    end;
  end;

  procedure PutChunk(const AId: AnsiString; const AData: array of Byte);
  var
    LIndex: Integer;
  begin
    PutId(AId);
    Put(Length(AData), 4);
    for LIndex := 0 to High(AData) do
      Put(AData[LIndex], 1);
    if Odd(Length(AData)) then
      Put(0, 1);
  end;

begin
  LStream := TBytesStream.Create;
  try
    PutId('FORM');
    Put(0, 4);
    PutId(AType);
    PutChunk('BMHD', [AWidth shr 8, AWidth and $FF, AHeight shr 8, AHeight and $FF, 0, 0, 0, 0, APlanes, AMasking,
      ACompression, 0, 0, 3, 1, 1, 0, 0, 0, 0]);
    if Length(AColors) > 0 then
      PutChunk('CMAP', AColors);
    PutChunk('BODY', ABody);
    Result := Copy(LStream.Bytes, 0, LStream.Size);
  finally
    LStream.Free;
  end;
end;

{ TTestXcomLbmReader }

function TTestXcomLbmReader.DataFile(const AName: string): string;
begin
  Result := TPath.GetFullPath(ExtractFilePath(ParamStr(0)) + '..\..\Tests\Data\Xcom\' + AName);
end;

function TTestXcomLbmReader.Describe(const AReader: IXcomLbmReader; const ABytes: TBytes): string;
var
  LPicture: TXcomLbmPicture;
  LIndex: Integer;
  LHash: UInt64;
  LColor: TXcomColor;
begin
  try
    LPicture := AReader.Read(ABytes);
  except
    on EXcomDataException do
      Exit('ERR');
  end;
  Result := Format('%d %d 8 %d %d %d ', [LPicture.Image.Width, LPicture.Image.Height,
    Ord(LPicture.HasColorKey), LPicture.ColorKey, LPicture.Image.Palette.Count]);
  for LIndex := 0 to LPicture.Image.Palette.Count - 1 do
  begin
    LColor := LPicture.Image.Palette.Colors[LIndex];
    Result := Result + LowerCase(IntToHex(LColor.Red, 2) + IntToHex(LColor.Green, 2) + IntToHex(LColor.Blue, 2));
  end;
  LHash := UInt64($CBF29CE484222325);
  for LIndex := 0 to High(LPicture.Image.Pixels) do
  begin
    LHash := LHash xor LPicture.Image.Pixels[LIndex];
    LHash := LHash * UInt64($100000001B3);
  end;
  Result := Result + ' ' + UIntToStr(LHash);
end;

procedure TTestXcomLbmReader.DovrebbeLeggereGliLbmComeSdlImage;
var
  LCorpus: TStringList;
  LGolden: TStringList;
  LReader: IXcomLbmReader;
  LIndex: Integer;
  LLine: string;
  LFailures: Integer;
  LFirst: string;
begin
  LCorpus := TStringList.Create;
  LGolden := TStringList.Create;
  try
    LCorpus.LoadFromFile(DataFile('lbm.corpus.txt'));
    LGolden.LoadFromFile(DataFile('lbm.golden.txt'));
    Assert.AreEqual(LCorpus.Count, LGolden.Count);
    Assert.IsTrue(LCorpus.Count >= 600);
    LReader := TXcomFactory.CreateLbmReader;
    LFailures := 0;
    LFirst := '';
    for LIndex := 0 to LCorpus.Count - 1 do
    begin
      LLine := LCorpus[LIndex];
      if Describe(LReader, HexToBytes(Copy(LLine, 1, Pos(' ', LLine) - 1))) <> LGolden[LIndex] then
      begin
        Inc(LFailures);
        if LFirst = '' then
          LFirst := Format('%d (%s) got %s expected %s', [LIndex, Copy(LLine, Pos(' ', LLine) + 1, 80),
            Describe(LReader, HexToBytes(Copy(LLine, 1, Pos(' ', LLine) - 1))).Substring(0, 12) + '...' +
            Describe(LReader, HexToBytes(Copy(LLine, 1, Pos(' ', LLine) - 1))).Substring(
              Length(Describe(LReader, HexToBytes(Copy(LLine, 1, Pos(' ', LLine) - 1)))) - 30),
            LGolden[LIndex].Substring(0, 12) + '...' + LGolden[LIndex].Substring(Length(LGolden[LIndex]) - 30)]);
      end;
    end;
    Assert.AreEqual(0, LFailures, 'differences with SDL_image, the first one at ' + LFirst);
  finally
    LGolden.Free;
    LCorpus.Free;
  end;
end;

procedure TTestXcomLbmReader.DovrebbeLeggereILbmVeriDiTftdComeSdlImage;
var
  LFolder: string;
  LGoldenFile: string;
  LGolden: TStringList;
  LReader: IXcomLbmReader;
  LLine: string;
  LName: string;
  LFile: string;
  LChecked: Integer;
begin
  LFolder := TXcomRealData.Folder;
  if LFolder = '' then
  begin
    TXcomTestSkip.Ignore('the real data of TFTD are not on this machine');
    Exit;
  end;
  LGoldenFile := TPath.GetFullPath(TPath.Combine(LFolder, '..\lbm_golden.txt'));
  if not TFile.Exists(LGoldenFile) then
  begin
    TXcomTestSkip.Ignore('no lbm_golden.txt (lbmharness file) next to the data');
    Exit;
  end;
  LGolden := TStringList.Create;
  try
    LGolden.LoadFromFile(LGoldenFile);
    LReader := TXcomFactory.CreateLbmReader;
    LChecked := 0;
    for LLine in LGolden do
    begin
      LName := Copy(LLine, 1, Pos(' ', LLine) - 1);
      LFile := TPath.Combine(LFolder, 'UFOGRAPH\' + LName);
      if not TFile.Exists(LFile) then
        Continue;
      Assert.AreEqual(Copy(LLine, Pos(' ', LLine) + 1, MaxInt), Describe(LReader, TFile.ReadAllBytes(LFile)), LName);
      Inc(LChecked);
    end;
    Assert.IsTrue(LChecked > 0);
  finally
    LGolden.Free;
  end;
end;

procedure TTestXcomLbmReader.DovrebbeRifiutareUnFileCheNonEIff;
var
  LBytes: TBytes;
begin
  LBytes := IffBytes('PBM ', 2, 1, 8, 0, 0, [], [1, 2]);
  LBytes[0] := Ord('X');
  Assert.AreEqual('ERR', Describe(TXcomFactory.CreateLbmReader, LBytes));
end;

procedure TTestXcomLbmReader.DovrebbeRifiutareUnFileTroncato;
begin
  Assert.AreEqual('ERR', Describe(TXcomFactory.CreateLbmReader, Copy(IffBytes('PBM ', 2, 1, 8, 0, 0, [], [1, 2]), 0, 10)));
  Assert.AreEqual('ERR', Describe(TXcomFactory.CreateLbmReader, nil));
end;

procedure TTestXcomLbmReader.DovrebbeRifiutareUnTipoDiversoDaPbmEIlbm;
begin
  Assert.AreEqual('ERR', Describe(TXcomFactory.CreateLbmReader, IffBytes('ANIM', 2, 1, 8, 0, 0, [], [1, 2])));
end;

procedure TTestXcomLbmReader.DovrebbeRifiutareUnFileSenzaIntestazione;
var
  LBytes: TBytes;
begin
  // FORM, PBM, then BODY straight away
  LBytes := TBytes.Create(Ord('F'), Ord('O'), Ord('R'), Ord('M'), 0, 0, 0, 12, Ord('P'), Ord('B'), Ord('M'), 32,
    Ord('B'), Ord('O'), Ord('D'), Ord('Y'), 0, 0, 0, 0);
  Assert.AreEqual('ERR', Describe(TXcomFactory.CreateLbmReader, LBytes));
end;

procedure TTestXcomLbmReader.DovrebbeLeggereUnPbmSenzaCompressioneConLaPalette;
var
  LPicture: TXcomLbmPicture;
begin
  LPicture := TXcomFactory.CreateLbmReader.Read(IffBytes('PBM ', 16, 1, 8, 0, 0, [10, 20, 30, 40, 50, 60],
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]));
  Assert.AreEqual(16, LPicture.Image.Width);
  Assert.AreEqual(256, LPicture.Image.Palette.Count);
  Assert.AreEqual(40, Integer(LPicture.Image.Palette.Colors[1].Red));
  Assert.AreEqual(15, Integer(LPicture.Image.Pixels[15]));
  Assert.IsFalse(LPicture.HasColorKey);
end;

procedure TTestXcomLbmReader.DovrebbeUsareIlNeroPerLeCopieMancantiDellaPalette;
var
  LPicture: TXcomLbmPicture;
begin
  LPicture := TXcomFactory.CreateLbmReader.Read(IffBytes('PBM ', 16, 1, 8, 0, 0, [1, 2, 3],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]));
  Assert.AreEqual(0, Integer(LPicture.Image.Palette.Colors[5].Green));
  Assert.AreEqual(2, Integer(LPicture.Image.Palette.Colors[0].Green));
end;

procedure TTestXcomLbmReader.DovrebbeRifiutareUnaPaletteDiPiuDi256Colori;
var
  LColors: TBytes;
begin
  SetLength(LColors, 257 * 3);
  Assert.AreEqual('ERR', Describe(TXcomFactory.CreateLbmReader,
    IffBytes('PBM ', 16, 1, 8, 0, 0, LColors, [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])));
end;

procedure TTestXcomLbmReader.DovrebbeRifiutareUnPbmConPiuDiOttoPiani;
begin
  Assert.AreEqual('ERR', Describe(TXcomFactory.CreateLbmReader,
    IffBytes('PBM ', 16, 1, 24, 0, 0, [], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomLbmReader);

end.
