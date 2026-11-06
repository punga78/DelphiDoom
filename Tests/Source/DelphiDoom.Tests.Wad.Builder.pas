{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Wad library - TWadBuilder                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Wad.Builder;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DUnitX.TestFramework, DelphiDoom.Wad.Types,
  DelphiDoom.Wad.Intf;

type
  [TestFixture]
  [Category('wad')]
  TTestWadBuilder = class(TObject)
  private
    FBuilder: IWadBuilder;
    function Reopen: IWadSource;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure TestEmptyWadIs12Bytes;
    [Test]
    procedure TestExactBytesOfASmallWad;
    [Test]
    procedure TestWriteThenReadBack;
    [Test]
    procedure TestKindsWriteTheirIdentification;
    [Test]
    procedure TestNamesAreUpperCase;
    [Test]
    procedure TestBadNamesAreRefused;
    [Test]
    procedure TestInsertReplaceRenameDeleteMove;
    [Test]
    procedure TestIndexOfAndBadIndexes;
    [Test]
    procedure TestDuplicateNamesAreKept;
    [Test]
    procedure TestDataIsCopied;
    [Test]
    procedure TestModifyAPwad;
    [Test]
    procedure TestRewriteGivesTheSameBytes;
    [Test]
    procedure TestSaveToFile;
    [Test]
    procedure TestHandMadeWadIsAccepted;
  end;

implementation

uses
  DelphiDoom.Wad.Factory, DelphiDoom.Tests.Wad.Helpers;

type
  H = TWadTestHelpers;

{ TTestWadBuilder }

procedure TTestWadBuilder.Setup;
begin
  FBuilder := TWadFactory.CreateBuilder;
end;

function TTestWadBuilder.Reopen: IWadSource;
begin
  Result := TWadFactory.OpenBytes('built', FBuilder.ToBytes);
end;

procedure TTestWadBuilder.TestEmptyWadIs12Bytes;
var
  LBytes: TBytes;
  LNumLumps, LTable: Integer;
begin
  LBytes := FBuilder.ToBytes;
  Assert.AreEqual(12, Length(LBytes));
  Assert.AreEqual('PWAD', TEncoding.ANSI.GetString(LBytes, 0, 4));
  Move(LBytes[4], LNumLumps, 4);
  Move(LBytes[8], LTable, 4);
  Assert.AreEqual(0, LNumLumps);
  Assert.AreEqual(12, LTable);
  Assert.AreEqual(0, Reopen.Count);
end;

procedure TTestWadBuilder.TestExactBytesOfASmallWad;
var
  LBytes: TBytes;
  LExpected: TBytes;
begin
  FBuilder.Kind := TWadKind.IWad;
  FBuilder.AddLump('ab', H.Bytes('xyz'));
  LBytes := FBuilder.ToBytes;
  // header 12, data 3 + 1 pad, directory 16
  Assert.AreEqual(12 + 4 + 16, Length(LBytes));
  LExpected := TBytes.Create(
    Ord('I'), Ord('W'), Ord('A'), Ord('D'), 1, 0, 0, 0, 16, 0, 0, 0,
    Ord('x'), Ord('y'), Ord('z'), 0,
    12, 0, 0, 0, 3, 0, 0, 0, Ord('A'), Ord('B'), 0, 0, 0, 0, 0, 0);
  Assert.IsTrue(CompareMem(@LBytes[0], @LExpected[0], Length(LExpected)));
end;

procedure TTestWadBuilder.TestWriteThenReadBack;
var
  LSource: IWadSource;
begin
  FBuilder.AddLump('MAP01', nil);
  FBuilder.AddLump('THINGS', H.Bytes('0123456789'));
  FBuilder.AddLump('ODD', H.Bytes('12345'));
  LSource := Reopen;
  Assert.AreEqual(3, LSource.Count);
  Assert.AreEqual('MAP01', LSource.Entries[0].Name);
  Assert.AreEqual(0, LSource.Entries[0].Size);
  Assert.AreEqual('0123456789', TEncoding.ANSI.GetString(LSource.ReadEntry(1)));
  Assert.AreEqual('12345', TEncoding.ANSI.GetString(LSource.ReadEntry(2)));
  Assert.AreEqual(0, LSource.Entries[1].Offset mod 4);
  Assert.AreEqual(0, LSource.Entries[2].Offset mod 4);
end;

procedure TTestWadBuilder.TestKindsWriteTheirIdentification;
var
  LId: Integer;
begin
  FBuilder.Kind := TWadKind.IWad;
  Move(FBuilder.ToBytes[0], LId, 4);
  Assert.AreEqual(WAD_ID_IWAD, LId);
  FBuilder.Kind := TWadKind.DWad;
  Move(FBuilder.ToBytes[0], LId, 4);
  Assert.AreEqual(WAD_ID_DWAD, LId);
  FBuilder.Kind := TWadKind.PWad;
  Move(FBuilder.ToBytes[0], LId, 4);
  Assert.AreEqual(WAD_ID_PWAD, LId);
end;

procedure TTestWadBuilder.TestNamesAreUpperCase;
begin
  FBuilder.AddLump('sky1', nil);
  Assert.AreEqual('SKY1', FBuilder.LumpNames[0]);
  Assert.AreEqual('SKY1', Reopen.Entries[0].Name);
end;

procedure TTestWadBuilder.TestBadNamesAreRefused;
begin
  Assert.WillRaise(procedure begin FBuilder.AddLump('', nil); end, EWadException);
  Assert.WillRaise(procedure begin FBuilder.AddLump('TOOLONGNAME', nil); end, EWadException);
  Assert.WillRaise(procedure begin FBuilder.AddLump('A B', nil); end, EWadException);
  Assert.AreEqual(0, FBuilder.Count);
end;

procedure TTestWadBuilder.TestInsertReplaceRenameDeleteMove;
begin
  FBuilder.AddLump('A', H.Bytes('a'));
  FBuilder.AddLump('C', H.Bytes('c'));
  FBuilder.InsertLump(1, 'B', H.Bytes('b'));
  Assert.AreEqual('A,B,C', FBuilder.LumpNames[0] + ',' + FBuilder.LumpNames[1] + ',' + FBuilder.LumpNames[2]);
  FBuilder.ReplaceLump(1, H.Bytes('bbbb'));
  Assert.AreEqual('bbbb', TEncoding.ANSI.GetString(FBuilder.LumpData[1]));
  FBuilder.RenameLump(2, 'z');
  Assert.AreEqual('Z', FBuilder.LumpNames[2]);
  FBuilder.MoveLump(2, 0);
  Assert.AreEqual('Z', FBuilder.LumpNames[0]);
  Assert.AreEqual('A', FBuilder.LumpNames[1]);
  FBuilder.DeleteLump(1);
  Assert.AreEqual(2, FBuilder.Count);
  Assert.AreEqual('B', FBuilder.LumpNames[1]);
  Assert.AreEqual('Z', Reopen.Entries[0].Name);
end;

procedure TTestWadBuilder.TestIndexOfAndBadIndexes;
begin
  FBuilder.AddLump('A', nil);
  FBuilder.AddLump('B', nil);
  Assert.AreEqual(1, FBuilder.IndexOf('b'));
  Assert.AreEqual(-1, FBuilder.IndexOf('C'));
  Assert.WillRaise(procedure begin FBuilder.DeleteLump(2); end, EWadException);
  Assert.WillRaise(procedure begin FBuilder.ReplaceLump(-1, nil); end, EWadException);
  Assert.WillRaise(procedure begin FBuilder.InsertLump(3, 'X', nil); end, EWadException);
  Assert.WillRaise(procedure begin FBuilder.MoveLump(0, 2); end, EWadException);
  Assert.WillRaise(procedure begin FBuilder.RenameLump(0, ''); end, EWadException);
  Assert.WillRaise(procedure begin FBuilder.LumpData[5]; end, EWadException);
end;

procedure TTestWadBuilder.TestDuplicateNamesAreKept;
begin
  FBuilder.AddLump('X', H.Bytes('1'));
  FBuilder.AddLump('X', H.Bytes('2'));
  Assert.AreEqual(2, Reopen.Count);
  Assert.AreEqual('2', TEncoding.ANSI.GetString(Reopen.ReadEntry(1)));
end;

procedure TTestWadBuilder.TestDataIsCopied;
var
  LData: TBytes;
begin
  LData := H.Bytes('abc');
  FBuilder.AddLump('A', LData);
  LData[0] := Ord('z');
  Assert.AreEqual('abc', TEncoding.ANSI.GetString(FBuilder.LumpData[0]));
  Assert.AreEqual('abc', TEncoding.ANSI.GetString(FBuilder.LumpData[0]));
end;

procedure TTestWadBuilder.TestModifyAPwad;
var
  LOther: IWadBuilder;
  LSource: IWadSource;
begin
  LOther := TWadFactory.CreateBuilder;
  LOther.LoadFrom(TWadFactory.OpenBytes('p',
    H.MakeWad(['MAP01', 'THINGS', 'LINEDEFS'], [nil, H.Bytes('t'), H.Bytes('l')])));
  Assert.AreEqual(3, LOther.Count);
  LOther.ReplaceLump(1, H.Bytes('new things'));
  LOther.AddLump('EXTRA', H.Bytes('e'));
  FBuilder := LOther;
  LSource := Reopen;
  Assert.AreEqual(4, LSource.Count);
  Assert.AreEqual('new things', TEncoding.ANSI.GetString(LSource.ReadEntry(1)));
  Assert.AreEqual('l', TEncoding.ANSI.GetString(LSource.ReadEntry(2)));
end;

procedure TTestWadBuilder.TestRewriteGivesTheSameBytes;
var
  LFirst, LSecond: TBytes;
  LOther: IWadBuilder;
begin
  FBuilder.AddLump('A', H.Bytes('aaaa'));
  FBuilder.AddLump('B', H.Bytes('bb'));
  FBuilder.AddLump('C', nil);
  LFirst := FBuilder.ToBytes;
  LOther := TWadFactory.CreateBuilder;
  LOther.LoadFrom(TWadFactory.OpenBytes('x', LFirst));
  LSecond := LOther.ToBytes;
  Assert.AreEqual(Length(LFirst), Length(LSecond));
  Assert.IsTrue(CompareMem(@LFirst[0], @LSecond[0], Length(LFirst)));
end;

procedure TTestWadBuilder.TestSaveToFile;
var
  LPath: string;
  LSource: IWadSource;
begin
  LPath := TPath.Combine(TPath.GetTempPath, 'ddwad_builder_' + TGUID.NewGuid.ToString + '.wad');
  try
    FBuilder.AddLump('HELLO', H.Bytes('world'));
    FBuilder.SaveToFile(LPath);
    LSource := TWadFactory.OpenPath(LPath);
    Assert.AreEqual('world', TEncoding.ANSI.GetString(LSource.ReadEntry(0)));
    // the stream of a file source keeps the file open: free it to delete
    LSource := nil;
  finally
    TFile.Delete(LPath);
  end;
end;

procedure TTestWadBuilder.TestHandMadeWadIsAccepted;
var
  LOther: IWadBuilder;
begin
  // data without padding, as the original tools write it
  LOther := TWadFactory.CreateBuilder;
  LOther.LoadFrom(TWadFactory.OpenBytes('hand',
    H.MakeWad(['A', 'B'], [H.Bytes('123'), H.Bytes('45')])));
  Assert.AreEqual('123', TEncoding.ANSI.GetString(LOther.LumpData[0]));
  Assert.AreEqual('45', TEncoding.ANSI.GetString(LOther.LumpData[1]));
end;

end.
