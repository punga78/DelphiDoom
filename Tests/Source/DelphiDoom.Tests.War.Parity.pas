{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - parity with the C of the remake      }
{  on the real DATA.WAR                                                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.Parity;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.War.Types, DelphiDoom.War.Intf,
  DelphiDoom.War.Factory, DelphiDoom.MathCore.Crc32, DelphiDoom.Tests.War.RealData;

type
  /// <summary>
  ///   The golden files are the output of war_ref.exe: the original wfile_loadWarFile of war1 (war_file.c,
  ///   extracted as it is) compiled with gcc and run on DATA.WAR (Tools\Verifica\191). Every line has index,
  ///   placeholder or not, offset, compressed, length in the file, length and CRC-32 of the expanded bytes
  /// </summary>
  [TestFixture]
  [Category('war')]
  TTestWarParity = class(TObject)
  private
    function Listing(const AArchive: IWarArchive): TStringList;
    procedure CompareWithGolden(const AGoldenName: string; const ACatalog: IWarCatalog);
  public
    [Test]
    procedure DovrebbeDareLoStessoElencoDelCodiceOriginaleCome_wg_loadDataFile;
    [Test]
    procedure DovrebbeDareLoStessoElencoDelCodiceOriginaleSenzaSaltareNulla;
    [Test]
    procedure DovrebbeRiconoscereIlGiocoCompletoDosDi583Voci;
    [Test]
    procedure DovrebbeSaltare68VociDiTipoSconosciuto;
    [Test]
    procedure DovrebbeLeggereTutteLeVociSenzaSaltareConUnaSolaLunghezza;
  end;

implementation

uses
  System.IOUtils;

{ TTestWarParity }

function TTestWarParity.Listing(const AArchive: IWarArchive): TStringList;
var
  LIndex: Integer;
  LInfo: TWarRecordInfo;
  LData: TBytes;
  LCrc: string;
begin
  Result := TStringList.Create;
  Result.Add(Format('H %u %d %d', [AArchive.ArchiveId, AArchive.EntryCount, Ord(AArchive.FileType)]));
  for LIndex := 0 to AArchive.EntryCount - 1 do
  begin
    LInfo := AArchive.GetRecordInfo(LIndex);
    if LInfo.Status <> wrsAvailable then
      Result.Add(Format('R %d P offset=%u', [LIndex, LInfo.Offset]))
    else
    begin
      LData := AArchive.ReadRecord(LIndex);
      Assert.AreEqual<Integer>(Integer(LInfo.Length), Length(LData));
      if Length(LData) > 0 then
        LCrc := TCrc32.ToHex(TCrc32.Calculate(LData[0], Length(LData)))
      else
        LCrc := TCrc32.ToHex(TCrc32.Calculate(LCrc, 0));
      Result.Add(Format('R %d D offset=%u compressed=%d clen=%u length=%u crc=%s',
        [LIndex, LInfo.Offset, Ord(LInfo.Compressed), LInfo.CompressedLength, LInfo.Length, LCrc]));
    end;
  end;
end;

procedure TTestWarParity.CompareWithGolden(const AGoldenName: string; const ACatalog: IWarCatalog);
var
  LPath: string;
  LGolden: TStringList;
  LActual: TStringList;
  LIndex: Integer;
begin
  LPath := TWarRealData.RequireDataWar;
  LGolden := TStringList.Create;
  try
    LGolden.LoadFromFile(TWarRealData.GoldenPath(AGoldenName));
    LActual := Listing(TWarFactory.OpenFile(LPath, ACatalog));
    try
      Assert.AreEqual(LGolden.Count, LActual.Count);
      for LIndex := 0 to LGolden.Count - 1 do
        Assert.AreEqual(LGolden[LIndex], LActual[LIndex], 'riga ' + IntToStr(LIndex));
    finally
      LActual.Free;
    end;
  finally
    LGolden.Free;
  end;
end;

procedure TTestWarParity.DovrebbeDareLoStessoElencoDelCodiceOriginaleCome_wg_loadDataFile;
begin
  CompareWithGolden('datawar.retail.golden.txt', TWarFactory.CreateCatalog);
end;

procedure TTestWarParity.DovrebbeDareLoStessoElencoDelCodiceOriginaleSenzaSaltareNulla;
begin
  CompareWithGolden('datawar.retail.noskip.golden.txt', nil);
end;

procedure TTestWarParity.DovrebbeRiconoscereIlGiocoCompletoDosDi583Voci;
var
  LArchive: IWarArchive;
begin
  LArchive := TWarFactory.OpenFile(TWarRealData.RequireDataWar, nil);
  Assert.AreEqual(Ord(wftRetail), Ord(LArchive.FileType));
  Assert.AreEqual(Cardinal($18), LArchive.ArchiveId);
  Assert.AreEqual(583, LArchive.EntryCount);
  Assert.AreEqual(Int64(12852768), TFile.GetSize(TWarRealData.RequireDataWar));
end;

procedure TTestWarParity.DovrebbeSaltare68VociDiTipoSconosciuto;
var
  LArchive: IWarArchive;
  LIndex: Integer;
  LSkipped: Integer;
begin
  LArchive := TWarFactory.OpenFile(TWarRealData.RequireDataWar, TWarFactory.CreateCatalog);
  LSkipped := 0;
  for LIndex := 0 to LArchive.EntryCount - 1 do
    if LArchive.GetRecordInfo(LIndex).Status = wrsSkipped then
      Inc(LSkipped);
  Assert.AreEqual(68, LSkipped);
end;

procedure TTestWarParity.DovrebbeLeggereTutteLeVociSenzaSaltareConUnaSolaLunghezza;
var
  LArchive: IWarArchive;
  LIndex: Integer;
  LTotal: Int64;
begin
  LArchive := TWarFactory.OpenFile(TWarRealData.RequireDataWar, nil);
  LTotal := 0;
  for LIndex := 0 to LArchive.EntryCount - 1 do
  begin
    Assert.AreEqual(Ord(wrsAvailable), Ord(LArchive.GetRecordInfo(LIndex).Status), 'voce ' + IntToStr(LIndex));
    Inc(LTotal, Length(LArchive.ReadRecord(LIndex)));
  end;
  Assert.IsTrue(LTotal > 0);
end;

end.
