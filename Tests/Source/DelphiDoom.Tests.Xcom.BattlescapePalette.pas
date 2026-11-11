{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom formats library - battlescape palettes (LBM)  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (no code of OpenXcom in this unit)                                           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Xcom.BattlescapePalette;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Tests.Xcom.Skip;

type
  [TestFixture]
  [Category('xcom')]
  TTestXcomBattlescapePalette = class(TObject)
  public
    [Test]
    procedure DovrebbeSostituireIlColore255ConLoSfondo;
    [Test]
    procedure DovrebbeRendereTrasparenteSoloIlColoreZero;
    [Test]
    procedure DovrebbeSchiarireIColoriUgualiAlloZeroDalSedicesimo;
    [Test]
    procedure DovrebbeFarGirareIlByteDelColoreChiaro;
    [Test]
    procedure DovrebbeRifiutareUnIndiceFuoriDaiQuattro;
    [Test]
    procedure DovrebbeRifiutareUnaPaletteDiMenoDi256Colori;
    [Test]
    procedure DovrebbeDareFalsoSeIlGiocoNonHaIlFile;
    [Test]
    procedure DovrebbeLeggereLaPaletteDaUnLbmDelGioco;
    [Test]
    procedure DovrebbeChiamareINomiDeiFile;
    [Test]
    procedure DovrebbeLeggereLeQuattroPaletteDiTftdSeCiSono;
  end;

implementation

uses
  System.Classes, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Palette, DelphiDoom.Xcom.Intf, DelphiDoom.Xcom.Factory,
  DelphiDoom.Xcom.MemoryFiles, DelphiDoom.Xcom.BattlescapePalette, DelphiDoom.Tests.Xcom.RealData;

function FlatPalette(ARed, AGreen, ABlue: Byte): TXcomPalette;
var
  LIndex: Integer;
begin
  Result := TXcomPalette.Create(XCOM_PALETTE_COLORS);
  for LIndex := 0 to XCOM_PALETTE_COLORS - 1 do
  begin
    Result.Colors[LIndex].Red := ARed;
    Result.Colors[LIndex].Green := AGreen;
    Result.Colors[LIndex].Blue := ABlue;
  end;
end;

function LbmFile(const AColors: TBytes): TBytes;
var
  LStream: TBytesStream;

  procedure PutBytes(const AValues: array of Byte);
  begin
    if Length(AValues) > 0 then
      LStream.WriteBuffer(AValues[0], Length(AValues));
  end;

begin
  LStream := TBytesStream.Create;
  try
    PutBytes([Ord('F'), Ord('O'), Ord('R'), Ord('M'), 0, 0, 0, 0, Ord('P'), Ord('B'), Ord('M'), 32]);
    PutBytes([Ord('B'), Ord('M'), Ord('H'), Ord('D'), 0, 0, 0, 20, 0, 16, 0, 1, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 1, 1,
      0, 0, 0, 0]);
    PutBytes([Ord('C'), Ord('M'), Ord('A'), Ord('P'), 0, 0, 3, 0]);
    PutBytes(AColors);
    PutBytes([Ord('B'), Ord('O'), Ord('D'), Ord('Y'), 0, 0, 0, 16, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]);
    Result := Copy(LStream.Bytes, 0, LStream.Size);
  finally
    LStream.Free;
  end;
end;

{ TTestXcomBattlescapePalette }

procedure TTestXcomBattlescapePalette.DovrebbeSostituireIlColore255ConLoSfondo;
var
  LPalette: TXcomPalette;
begin
  LPalette := TXcomBattlescapePalette.FromLbm(FlatPalette(100, 110, 120), 1);
  Assert.AreEqual(0, Integer(LPalette.Colors[255].Red));
  Assert.AreEqual(10, Integer(LPalette.Colors[255].Green));
  Assert.AreEqual(34, Integer(LPalette.Colors[255].Blue));
  LPalette := TXcomBattlescapePalette.FromLbm(FlatPalette(100, 110, 120), 3);
  Assert.AreEqual(2, Integer(LPalette.Colors[255].Red));
  Assert.AreEqual(0, Integer(LPalette.Colors[255].Green));
  Assert.AreEqual(24, Integer(LPalette.Colors[255].Blue));
  LPalette := TXcomBattlescapePalette.FromLbm(FlatPalette(100, 110, 120), 0);
  Assert.AreEqual(5, Integer(LPalette.Colors[255].Green));
  LPalette := TXcomBattlescapePalette.FromLbm(FlatPalette(100, 110, 120), 2);
  Assert.AreEqual(9, Integer(LPalette.Colors[255].Green));
end;

procedure TTestXcomBattlescapePalette.DovrebbeRendereTrasparenteSoloIlColoreZero;
var
  LPalette: TXcomPalette;
begin
  LPalette := TXcomBattlescapePalette.FromLbm(FlatPalette(100, 110, 120), 0);
  Assert.AreEqual(0, Integer(LPalette.Colors[0].Alpha));
  Assert.AreEqual(255, Integer(LPalette.Colors[1].Alpha));
  Assert.AreEqual(255, Integer(LPalette.Colors[255].Alpha));
end;

procedure TTestXcomBattlescapePalette.DovrebbeSchiarireIColoriUgualiAlloZeroDalSedicesimo;
var
  LPalette: TXcomPalette;
begin
  // every color is equal to the color 0: the ones from 16 on get one step lighter, the first 16 do not
  LPalette := TXcomBattlescapePalette.FromLbm(FlatPalette(7, 8, 9), 0);
  Assert.AreEqual(7, Integer(LPalette.Colors[15].Red));
  Assert.AreEqual(8, Integer(LPalette.Colors[16].Red));
  Assert.AreEqual(9, Integer(LPalette.Colors[16].Green));
  Assert.AreEqual(10, Integer(LPalette.Colors[16].Blue));
  // the color 255 (the background) is not the color 0 any more, so it is left alone
  Assert.AreEqual(5, Integer(LPalette.Colors[255].Green));
end;

procedure TTestXcomBattlescapePalette.DovrebbeFarGirareIlByteDelColoreChiaro;
var
  LPalette: TXcomPalette;
begin
  LPalette := TXcomBattlescapePalette.FromLbm(FlatPalette(255, 255, 255), 0);
  Assert.AreEqual(0, Integer(LPalette.Colors[20].Red));
  Assert.AreEqual(0, Integer(LPalette.Colors[20].Blue));
end;

procedure TTestXcomBattlescapePalette.DovrebbeRifiutareUnIndiceFuoriDaiQuattro;
begin
  Assert.WillRaise(
    procedure
    begin
      TXcomBattlescapePalette.FromLbm(FlatPalette(1, 2, 3), 4);
    end, EXcomException);
  Assert.WillRaise(
    procedure
    begin
      TXcomBattlescapePalette.FileName(-1);
    end, EXcomException);
end;

procedure TTestXcomBattlescapePalette.DovrebbeRifiutareUnaPaletteDiMenoDi256Colori;
begin
  Assert.WillRaise(
    procedure
    begin
      TXcomBattlescapePalette.FromLbm(TXcomPalette.Create(16), 0);
    end, EXcomException);
end;

procedure TTestXcomBattlescapePalette.DovrebbeDareFalsoSeIlGiocoNonHaIlFile;
var
  LFiles: TXcomMemoryFiles;
  LInterface: IXcomDataFiles;
  LPalette: TXcomPalette;
begin
  LFiles := TXcomMemoryFiles.Create;
  LInterface := LFiles;
  Assert.IsFalse(TXcomBattlescapePalette.TryLoad(LInterface, TXcomFactory.CreateLbmReader, 0, LPalette));
  Assert.AreEqual(0, LPalette.Count);
end;

procedure TTestXcomBattlescapePalette.DovrebbeLeggereLaPaletteDaUnLbmDelGioco;
var
  LFiles: TXcomMemoryFiles;
  LInterface: IXcomDataFiles;
  LPalette: TXcomPalette;
  LColors: TBytes;
  LIndex: Integer;
begin
  SetLength(LColors, 768);
  for LIndex := 0 to 767 do
    LColors[LIndex] := (LIndex * 7 + 1) and $FF;
  LFiles := TXcomMemoryFiles.Create;
  LInterface := LFiles;
  LFiles.Add('ufograph/d2.lbm', LbmFile(LColors));
  Assert.IsTrue(TXcomBattlescapePalette.TryLoad(LInterface, TXcomFactory.CreateLbmReader, 2, LPalette));
  Assert.AreEqual(256, LPalette.Count);
  Assert.AreEqual(Integer(LColors[3]), Integer(LPalette.Colors[1].Red));
  Assert.AreEqual(Integer(LColors[5]), Integer(LPalette.Colors[1].Blue));
  Assert.AreEqual(9, Integer(LPalette.Colors[255].Green));
  Assert.AreEqual(0, Integer(LPalette.Colors[0].Alpha));
end;

procedure TTestXcomBattlescapePalette.DovrebbeChiamareINomiDeiFile;
begin
  Assert.AreEqual('UFOGRAPH/D0.LBM', TXcomBattlescapePalette.FileName(0));
  Assert.AreEqual('UFOGRAPH/D3.LBM', TXcomBattlescapePalette.FileName(3));
end;

procedure TTestXcomBattlescapePalette.DovrebbeLeggereLeQuattroPaletteDiTftdSeCiSono;
var
  LFolder: string;
  LData: IXcomGameData;
  LPalette: TXcomPalette;
  LIndex: Integer;
begin
  LFolder := TXcomRealData.Folder;
  if LFolder = '' then
  begin
    TXcomTestSkip.Ignore('the real data are not on this machine');
    Exit;
  end;
  LData := TXcomFactory.CreateGameData(TXcomFactory.CreateFolderFiles([LFolder]));
  if not LData.Files.Exists('UFOGRAPH/D0.LBM') then
  begin
    TXcomTestSkip.Ignore('this game (UFO) has no battlescape LBM');
    Exit;
  end;
  for LIndex := 0 to TXcomBattlescapePalette.COUNT - 1 do
  begin
    Assert.IsTrue(TXcomBattlescapePalette.TryLoad(LData.Files, TXcomFactory.CreateLbmReader, LIndex, LPalette));
    Assert.AreEqual(256, LPalette.Count);
    Assert.AreEqual(0, Integer(LPalette.Colors[0].Alpha));
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomBattlescapePalette);

end.
