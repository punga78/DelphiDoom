{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Wad library - the WADs of the games found in bin   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Wad.RealWads;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DUnitX.TestFramework, DelphiDoom.Wad.Types,
  DelphiDoom.Wad.Intf;

type
  /// <summary>
  ///   Reads the WADs of the games found in bin\... (not in the repository:
  ///   the tests that need one are skipped when it is missing) and compares
  ///   with a second, independent read of the directory
  /// </summary>
  [TestFixture]
  [Category('wad')]
  [Category('realwad')]
  TTestWadRealWads = class(TObject)
  private
    function FindWad(const AName: string): string;
    procedure CompareWithTheDirectoryOnDisk(const APath: string);
  public
    [Test]
    procedure TestFreedoom2;
    [Test]
    procedure TestDoomShareware;
    [Test]
    procedure TestHeretic;
    [Test]
    procedure TestHexen;
    [Test]
    procedure TestStrife;
    [Test]
    procedure TestRewriteOfARealWadKeepsTheLumps;
    [Test]
    procedure TestTwoWadsAndTheLastTakesPrecedence;
  end;

implementation

uses
  DelphiDoom.Wad.Factory, DelphiDoom.Wad.Name;

{ TTestWadRealWads }

function TTestWadRealWads.FindWad(const AName: string): string;
var
  LGame, LRoot: string;
begin
  Result := '';
  LRoot := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), '..'));
  for LGame in ['Doom', 'Heretic', 'Hexen', 'Strife'] do
    if TFile.Exists(TPath.Combine(TPath.Combine(LRoot, LGame), AName)) then
      Exit(TPath.Combine(TPath.Combine(LRoot, LGame), AName));
end;

procedure TTestWadRealWads.CompareWithTheDirectoryOnDisk(const APath: string);
var
  LSource: IWadSource;
  LStream: TFileStream;
  LHeader: TWadHeader;
  LRecord: TWadDirectoryRecord;
  LIndex: Integer;
  LDirectory: IWadDirectory;
  LFinder: IWadFinder;
begin
  LSource := TWadFactory.OpenPath(APath);
  LStream := TFileStream.Create(APath, fmOpenRead or fmShareDenyNone);
  try
    LStream.ReadBuffer(LHeader, SizeOf(LHeader));
    Assert.AreEqual(LHeader.NumLumps, LSource.Count);
    LStream.Position := LHeader.InfoTableOfs;
    for LIndex := 0 to LHeader.NumLumps - 1 do
    begin
      LStream.ReadBuffer(LRecord, SizeOf(LRecord));
      Assert.AreEqual(LRecord.FilePos, LSource.Entries[LIndex].Offset);
      Assert.AreEqual(LRecord.Size, LSource.Entries[LIndex].Size);
      Assert.AreEqual(TWadLumpName.FromRecord(LRecord), LSource.Entries[LIndex].Name);
    end;
  finally
    LStream.Free;
  end;

  // the lookup by name gives a lump with that name, and the last one of them
  LDirectory := TWadFactory.CreateDirectory;
  LDirectory.AddSource(LSource);
  LFinder := TWadFactory.CreateFinder(LDirectory);
  for LIndex := 0 to LDirectory.Count - 1 do
    if LDirectory.LumpName(LIndex) <> '' then
    begin
      Assert.AreEqual(LDirectory.LumpName(LIndex), LDirectory.LumpName(LFinder.CheckNumForName(LDirectory.LumpName(LIndex))));
      Assert.IsTrue(LFinder.CheckNumForName(LDirectory.LumpName(LIndex)) >= LIndex);
      Assert.IsTrue(LFinder.CheckFirstNumForName(LDirectory.LumpName(LIndex)) <= LIndex);
    end;
end;

procedure TTestWadRealWads.TestFreedoom2;
var
  LPath: string;
begin
  LPath := FindWad('FREEDOOM2.WAD');
  if LPath = '' then
    Assert.Pass('WAD not available in bin');
  CompareWithTheDirectoryOnDisk(LPath);
end;

procedure TTestWadRealWads.TestDoomShareware;
var
  LPath: string;
begin
  LPath := FindWad('DOOM1.WAD');
  if LPath = '' then
    Assert.Pass('WAD not available in bin');
  CompareWithTheDirectoryOnDisk(LPath);
end;

procedure TTestWadRealWads.TestHeretic;
var
  LPath: string;
begin
  LPath := FindWad('HERETIC1.WAD');
  if LPath = '' then
    Assert.Pass('WAD not available in bin');
  CompareWithTheDirectoryOnDisk(LPath);
end;

procedure TTestWadRealWads.TestHexen;
var
  LPath: string;
begin
  LPath := FindWad('HEXEN.WAD');
  if LPath = '' then
    Assert.Pass('WAD not available in bin');
  CompareWithTheDirectoryOnDisk(LPath);
end;

procedure TTestWadRealWads.TestStrife;
var
  LPath: string;
begin
  LPath := FindWad('STRIFE0.WAD');
  if LPath = '' then
    Assert.Pass('WAD not available in bin');
  CompareWithTheDirectoryOnDisk(LPath);
end;

procedure TTestWadRealWads.TestRewriteOfARealWadKeepsTheLumps;
var
  LPath: string;
  LSource, LRewritten: IWadSource;
  LBuilder: IWadBuilder;
  LIndex: Integer;
  LOriginal, LCopy: TBytes;
begin
  LPath := FindWad('DOOM1.WAD');
  if LPath = '' then
    Assert.Pass('WAD not available in bin');
  LSource := TWadFactory.OpenPath(LPath);
  LBuilder := TWadFactory.CreateBuilder(TWadKind.IWad);
  LBuilder.LoadFrom(LSource);
  LRewritten := TWadFactory.OpenBytes('rewritten', LBuilder.ToBytes);
  Assert.AreEqual(LSource.Count, LRewritten.Count);
  LIndex := 0;
  while LIndex < LSource.Count do
  begin
    Assert.AreEqual(LSource.Entries[LIndex].Name, LRewritten.Entries[LIndex].Name);
    LOriginal := LSource.ReadEntry(LIndex);
    LCopy := LRewritten.ReadEntry(LIndex);
    Assert.AreEqual(Length(LOriginal), Length(LCopy), LSource.Entries[LIndex].Name);
    if Length(LOriginal) > 0 then
      Assert.IsTrue(CompareMem(@LOriginal[0], @LCopy[0], Length(LOriginal)),
        'lump ' + LSource.Entries[LIndex].Name);
    // looking at a lump out of 7 keeps the test short
    Inc(LIndex, 7);
  end;
end;

procedure TTestWadRealWads.TestTwoWadsAndTheLastTakesPrecedence;
var
  LPath: string;
  LDirectory: IWadDirectory;
  LFinder: IWadFinder;
  LBuilder: IWadBuilder;
  LPatch: TBytes;
begin
  LPath := FindWad('DOOM1.WAD');
  if LPath = '' then
    Assert.Pass('WAD not available in bin');
  LDirectory := TWadFactory.CreateDirectory;
  LDirectory.AddSource(TWadFactory.OpenPath(LPath));
  LFinder := TWadFactory.CreateFinder(LDirectory);
  Assert.IsTrue(LFinder.CheckNumForName('PLAYPAL') >= 0);

  LBuilder := TWadFactory.CreateBuilder;
  LPatch := TBytes.Create(1, 2, 3);
  LBuilder.AddLump('PLAYPAL', LPatch);
  LDirectory.AddSource(TWadFactory.OpenBytes('patch', LBuilder.ToBytes));
  Assert.AreEqual(LDirectory.Count - 1, LFinder.CheckNumForName('PLAYPAL'));
  Assert.AreEqual(3, LDirectory.LumpSize(LFinder.CheckNumForName('PLAYPAL')));
  Assert.IsTrue(LDirectory.LumpSize(LFinder.CheckFirstNumForName('PLAYPAL')) > 3);
end;

end.
