{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Wad library - sources of lumps (WAD, PAK, ZIP, folder, file)}
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Wad.Sources;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Zip, DUnitX.TestFramework,
  DelphiDoom.Wad.Types, DelphiDoom.Wad.Intf;

type
  [TestFixture]
  [Category('wad')]
  TTestWadSources = class(TObject)
  private
    FFolder: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestWadListsItsLumps;
    [Test]
    procedure TestWadKindsAreAccepted;
    [Test]
    procedure TestEmptyWadIsValid;
    [Test]
    procedure TestNamesAreUpperCaseAndCutAtZero;
    [Test]
    procedure TestNotAWadIsRefused;
    [Test]
    procedure TestTooShortIsRefused;
    [Test]
    procedure TestDirectoryOutsideTheFileIsRefused;
    [Test]
    procedure TestNegativeLumpCountIsRefused;
    [Test]
    procedure TestLumpOutsideTheFileFailsWhenRead;
    [Test]
    procedure TestEntryIndexOutOfRange;
    [Test]
    procedure TestReadEntryIntoFillsTheBuffer;
    [Test]
    procedure TestEmptyLumpNeedsNoValidPosition;
    [Test]
    procedure TestPakListsItsFiles;
    [Test]
    procedure TestPakDirectoryOutsideTheFileIsRefused;
    [Test]
    procedure TestWad2ListsItsEntries;
    [Test]
    procedure TestWad2DirectoryOutsideTheFileIsRefused;
    [Test]
    procedure TestFolderListsFilesBelowIt;
    [Test]
    procedure TestMissingFolderIsRefused;
    [Test]
    procedure TestZipListsItsFilesWithoutFolders;
    [Test]
    procedure TestBrokenZipIsRefused;
    [Test]
    procedure TestOtherFileIsOneLump;
    [Test]
    procedure TestOpenPathRecognisesTheContainers;
    [Test]
    procedure TestOpenPathOfAMissingFile;
    [Test]
    procedure TestOpenBytesRefusesOtherData;
  end;

implementation

uses
  DelphiDoom.Wad.Factory, DelphiDoom.Tests.Wad.Helpers;

type
  H = TWadTestHelpers;

{ TTestWadSources }

procedure TTestWadSources.Setup;
begin
  FFolder := H.NewTempFolder;
end;

procedure TTestWadSources.TearDown;
begin
  if TDirectory.Exists(FFolder) then
    TDirectory.Delete(FFolder, True);
end;

procedure TTestWadSources.TestWadListsItsLumps;
var
  LSource: IWadSource;
begin
  LSource := TWadFactory.OpenBytes('test.wad',
    H.MakeWad(['MAP01', 'THINGS', 'EMPTY'], [H.Bytes('abc'), H.Bytes('0123456789'), nil]));
  Assert.AreEqual(3, LSource.Count);
  Assert.AreEqual('MAP01', LSource.Entries[0].Name);
  Assert.AreEqual(3, LSource.Entries[0].Size);
  Assert.AreEqual(12, LSource.Entries[0].Offset);
  Assert.AreEqual(15, LSource.Entries[1].Offset);
  Assert.AreEqual(0, LSource.Entries[2].Size);
  Assert.AreEqual('0123456789', TEncoding.ANSI.GetString(LSource.ReadEntry(1)));
  Assert.AreEqual(0, Length(LSource.ReadEntry(2)));
  Assert.AreEqual(Ord(TWadSourceKind.Wad), Ord(LSource.Kind));
end;

procedure TTestWadSources.TestWadKindsAreAccepted;
var
  LKind: TWadKind;
begin
  for LKind := Low(TWadKind) to High(TWadKind) do
    Assert.AreEqual(1, TWadFactory.OpenBytes('k', H.MakeWad(['A'], [H.Bytes('x')], LKind)).Count);
end;

procedure TTestWadSources.TestEmptyWadIsValid;
begin
  Assert.AreEqual(0, TWadFactory.OpenBytes('empty', H.MakeWad([], [])).Count);
end;

procedure TTestWadSources.TestNamesAreUpperCaseAndCutAtZero;
var
  LBytes: TBytes;
  LSource: IWadSource;
begin
  LBytes := H.MakeWad(['sky1'], [H.Bytes('z')]);
  // the name is the last 8 bytes of the 16 of the directory: put a character after the end
  LBytes[Length(LBytes) - 8 + 6] := Ord('q');
  LSource := TWadFactory.OpenBytes('n', LBytes);
  Assert.AreEqual('SKY1', LSource.Entries[0].Name);
end;

procedure TTestWadSources.TestNotAWadIsRefused;
begin
  Assert.WillRaise(procedure begin TWadFactory.OpenBytes('x', H.Bytes('JUNKJUNKJUNKJUNK')); end,
    EWadException);
end;

procedure TTestWadSources.TestTooShortIsRefused;
begin
  Assert.WillRaise(procedure begin TWadFactory.OpenBytes('x', H.Bytes('PWAD')); end, EWadException);
end;

procedure TTestWadSources.TestDirectoryOutsideTheFileIsRefused;
var
  LBytes: TBytes;
begin
  LBytes := H.MakeWad(['A'], [H.Bytes('xy')]);
  // 1000 lumps do not fit
  LBytes[4] := $E8;
  LBytes[5] := $03;
  Assert.WillRaise(procedure begin TWadFactory.OpenBytes('x', LBytes); end, EWadException);
end;

procedure TTestWadSources.TestNegativeLumpCountIsRefused;
var
  LBytes: TBytes;
begin
  LBytes := H.MakeWad(['A'], [H.Bytes('xy')]);
  LBytes[7] := $FF;
  Assert.WillRaise(procedure begin TWadFactory.OpenBytes('x', LBytes); end, EWadException);
end;

procedure TTestWadSources.TestLumpOutsideTheFileFailsWhenRead;
var
  LBytes: TBytes;
  LSource: IWadSource;
begin
  LBytes := H.MakeWad(['A', 'B'], [H.Bytes('xy'), H.Bytes('zw')]);
  // lump A gets a size of 5000 bytes: the file opens, the lump does not read
  LBytes[Length(LBytes) - 32 + 4] := $88;
  LBytes[Length(LBytes) - 32 + 5] := $13;
  LSource := TWadFactory.OpenBytes('x', LBytes);
  Assert.WillRaise(procedure begin LSource.ReadEntry(0); end, EWadException);
  Assert.AreEqual('zw', TEncoding.ANSI.GetString(LSource.ReadEntry(1)));
end;

procedure TTestWadSources.TestEntryIndexOutOfRange;
var
  LSource: IWadSource;
begin
  LSource := TWadFactory.OpenBytes('x', H.MakeWad(['A'], [H.Bytes('x')]));
  Assert.WillRaise(procedure begin LSource.Entries[1]; end, EWadException);
  Assert.WillRaise(procedure begin LSource.ReadEntry(-1); end, EWadException);
end;

procedure TTestWadSources.TestReadEntryIntoFillsTheBuffer;
var
  LSource: IWadSource;
  LBuffer: array[0..9] of AnsiChar;
begin
  LSource := TWadFactory.OpenBytes('x', H.MakeWad(['A', 'B'], [H.Bytes('abc'), H.Bytes('defg')]));
  FillChar(LBuffer, SizeOf(LBuffer), '.');
  LBuffer[9] := #0;
  LSource.ReadEntryInto(1, @LBuffer);
  Assert.AreEqual('defg.....', string(AnsiString(PAnsiChar(@LBuffer))), 'exactly the size of the lump');
  Assert.WillRaise(procedure begin LSource.ReadEntryInto(2, @LBuffer); end, EWadException);
end;

procedure TTestWadSources.TestEmptyLumpNeedsNoValidPosition;
var
  LBytes: TBytes;
  LSource: IWadSource;
  LBuffer: Byte;
begin
  LBytes := H.MakeWad(['MARK', 'A'], [nil, H.Bytes('xy')]);
  // the position of the empty lump points far outside the file
  LBytes[Length(LBytes) - 32] := $FF;
  LBytes[Length(LBytes) - 32 + 1] := $FF;
  LBytes[Length(LBytes) - 32 + 2] := $0F;
  LSource := TWadFactory.OpenBytes('x', LBytes);
  Assert.AreEqual(0, Length(LSource.ReadEntry(0)));
  LBuffer := 7;
  LSource.ReadEntryInto(0, @LBuffer);
  Assert.AreEqual(7, Integer(LBuffer), 'nothing written');
end;

procedure TTestWadSources.TestPakListsItsFiles;
var
  LSource: IWadSource;
begin
  LSource := TWadFactory.OpenBytes('test.pak',
    H.MakePak(['sounds/dspistol.wav', 'MODELS\Imp.md2'], [H.Bytes('RIFF'), H.Bytes('IDP2xx')]));
  Assert.AreEqual(2, LSource.Count);
  Assert.AreEqual('SOUNDS/DSPISTOL.WAV', LSource.Entries[0].Name);
  Assert.AreEqual('MODELS/IMP.MD2', LSource.Entries[1].Name);
  Assert.AreEqual('IDP2xx', TEncoding.ANSI.GetString(LSource.ReadEntry(1)));
  Assert.AreEqual(Ord(TWadSourceKind.Pak), Ord(LSource.Kind));
end;

procedure TTestWadSources.TestPakDirectoryOutsideTheFileIsRefused;
var
  LBytes: TBytes;
begin
  LBytes := H.MakePak(['a'], [H.Bytes('x')]);
  LBytes[8] := $FF;
  Assert.WillRaise(procedure begin TWadFactory.OpenBytes('x', LBytes); end, EWadException);
end;

procedure TTestWadSources.TestWad2ListsItsEntries;
var
  LSource: IWadSource;
begin
  LSource := TWadFactory.OpenBytes('test.wad',
    H.MakeWad2(['gfx/Wall', 'sky'], [H.Bytes('texture!'), H.Bytes('cloud')], True));
  Assert.AreEqual(2, LSource.Count);
  Assert.AreEqual('GFX/WALL', LSource.Entries[0].Name);
  Assert.AreEqual(8, LSource.Entries[0].Size);
  Assert.AreEqual('cloud', TEncoding.ANSI.GetString(LSource.ReadEntry(1)));
  Assert.AreEqual(1, TWadFactory.OpenBytes('q.wad', H.MakeWad2(['a'], [H.Bytes('x')])).Count, 'WAD2');
end;

procedure TTestWadSources.TestWad2DirectoryOutsideTheFileIsRefused;
var
  LBytes: TBytes;
begin
  LBytes := H.MakeWad2(['a'], [H.Bytes('x')]);
  LBytes[4] := $10;
  LBytes[5] := $27;
  Assert.WillRaise(procedure begin TWadFactory.OpenBytes('x', LBytes); end, EWadException);
end;

procedure TTestWadSources.TestFolderListsFilesBelowIt;
var
  LSource: IWadSource;
begin
  TDirectory.CreateDirectory(TPath.Combine(FFolder, 'sub'));
  TFile.WriteAllBytes(TPath.Combine(FFolder, 'b.txt'), H.Bytes('bb'));
  TFile.WriteAllBytes(TPath.Combine(FFolder, 'sub\a.txt'), H.Bytes('aaa'));
  LSource := TWadFactory.OpenPath(FFolder);
  Assert.AreEqual(2, LSource.Count);
  Assert.AreEqual('B.TXT', LSource.Entries[0].Name);
  Assert.AreEqual('SUB/A.TXT', LSource.Entries[1].Name);
  Assert.AreEqual(3, LSource.Entries[1].Size);
  Assert.AreEqual('aaa', TEncoding.ANSI.GetString(LSource.ReadEntry(1)));
  Assert.AreEqual(Ord(TWadSourceKind.Folder), Ord(LSource.Kind));
end;

procedure TTestWadSources.TestMissingFolderIsRefused;
begin
  Assert.WillRaise(procedure begin TWadFactory.OpenPath(TPath.Combine(FFolder, 'nope')); end,
    EWadException);
end;

procedure TTestWadSources.TestZipListsItsFilesWithoutFolders;
var
  LZip: TZipFile;
  LPath: string;
  LSource: IWadSource;
begin
  LPath := TPath.Combine(FFolder, 'test.pk3');
  LZip := TZipFile.Create;
  try
    LZip.Open(LPath, TZipMode.zmWrite);
    LZip.Add(H.Bytes('hello pk3'), 'Textures/wall.txt');
    LZip.Add(H.Bytes('x'), 'readme.txt');
  finally
    LZip.Free;
  end;
  LSource := TWadFactory.OpenPath(LPath);
  Assert.AreEqual(Ord(TWadSourceKind.Zip), Ord(LSource.Kind));
  Assert.AreEqual(2, LSource.Count);
  Assert.AreEqual('TEXTURES/WALL.TXT', LSource.Entries[0].Name);
  Assert.AreEqual(9, LSource.Entries[0].Size);
  Assert.AreEqual('hello pk3', TEncoding.ANSI.GetString(LSource.ReadEntry(0)));
end;

procedure TTestWadSources.TestBrokenZipIsRefused;
var
  LPath: string;
begin
  LPath := TPath.Combine(FFolder, 'bad.pk3');
  // starts like a ZIP, is not
  TFile.WriteAllBytes(LPath, TBytes.Create($50, $4B, $03, $04, 1, 2, 3, 4, 5, 6));
  Assert.WillRaise(procedure begin TWadFactory.OpenPath(LPath); end, EWadException);
end;

procedure TTestWadSources.TestOtherFileIsOneLump;
var
  LPath: string;
  LSource: IWadSource;
begin
  LPath := TPath.Combine(FFolder, 'dspistol.lmp');
  TFile.WriteAllBytes(LPath, H.Bytes('sound'));
  LSource := TWadFactory.OpenPath(LPath);
  Assert.AreEqual(Ord(TWadSourceKind.SingleFile), Ord(LSource.Kind));
  Assert.AreEqual(1, LSource.Count);
  Assert.AreEqual('DSPISTOL', LSource.Entries[0].Name);
  Assert.AreEqual('sound', TEncoding.ANSI.GetString(LSource.ReadEntry(0)));
end;

procedure TTestWadSources.TestOpenPathRecognisesTheContainers;
var
  LPath: string;
  LSource: IWadSource;
begin
  LPath := TPath.Combine(FFolder, 'a.bin');
  TFile.WriteAllBytes(LPath, H.MakeWad(['A'], [H.Bytes('1')], TWadKind.IWad));
  LSource := TWadFactory.OpenPath(LPath);
  Assert.AreEqual(Ord(TWadSourceKind.Wad), Ord(LSource.Kind), 'by content, not by extension');
  // the source keeps the file open
  LSource := nil;
  TFile.WriteAllBytes(LPath, H.MakePak(['a'], [H.Bytes('1')]));
  LSource := TWadFactory.OpenPath(LPath);
  Assert.AreEqual(Ord(TWadSourceKind.Pak), Ord(LSource.Kind));
  LSource := nil;
end;

procedure TTestWadSources.TestOpenPathOfAMissingFile;
begin
  Assert.WillRaise(procedure begin TWadFactory.OpenPath(TPath.Combine(FFolder, 'missing.wad')); end,
    EWadException);
end;

procedure TTestWadSources.TestOpenBytesRefusesOtherData;
begin
  Assert.WillRaise(procedure begin TWadFactory.OpenBytes('x', H.Bytes('hello world, not a wad')); end,
    EWadException);
  Assert.WillRaise(procedure begin TWadFactory.OpenBytes('x', nil); end, EWadException);
end;

end.
