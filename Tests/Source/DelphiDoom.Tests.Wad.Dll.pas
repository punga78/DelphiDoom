{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the WAD DLL (engine, client and the real DDWad.dll)    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Wad.Dll;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DUnitX.TestFramework, DelphiDoom.Wad.Types,
  DelphiDoom.Wad.Intf, DelphiDoom.Wad.Dll.Intf, DelphiDoom.Wad.Dll.Client;

type
  /// <summary>The client and the adapters over the engine of the DLL linked in the test</summary>
  [TestFixture]
  [Category('wad')]
  [Category('waddll')]
  TTestWadDll = class(TObject)
  private
    FDll: IWadDll;
    FClient: TWadDllClient;
    function OpenSource(const ANames: array of string; const AData: array of string): IWadSource;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestVersion;
    [Test]
    procedure TestSourceListsItsLumps;
    [Test]
    procedure TestSourceKindAndName;
    [Test]
    procedure TestPakSourceThroughTheDll;
    [Test]
    procedure TestOpenPathOfAFile;
    [Test]
    procedure TestOpenPathOfAMissingFile;
    [Test]
    procedure TestNotAWadGivesTheMessageOfTheLibrary;
    [Test]
    procedure TestDirectoryFindsTheLastLump;
    [Test]
    procedure TestDirectoryFlagsAndRanges;
    [Test]
    procedure TestDirectoryReadsLumps;
    [Test]
    procedure TestDirectoryTruncateAndReplace;
    [Test]
    procedure TestDirectoryKnowsItsSources;
    [Test]
    procedure TestForeignSourcesAreRefused;
    [Test]
    procedure TestBuilderWritesTheBytesOfTheLibrary;
    [Test]
    procedure TestBuilderChanges;
    [Test]
    procedure TestBuilderLoadsASource;
    [Test]
    procedure TestEightBitNamesSurvive;
    [Test]
    procedure TestTextProtocol;
    [Test]
    procedure TestReadBuffersMustBeBigEnough;
    [Test]
    procedure TestNumbersOutOfRange;
    [Test]
    procedure TestInvalidArguments;
  end;

  /// <summary>The same through the real DDWad.dll, when it is built</summary>
  [TestFixture]
  [Category('wad')]
  [Category('waddll')]
  TTestWadDllLoader = class(TObject)
  private
    function DllPath: string;
  public
    [Test]
    procedure TestLoadsAndAnswers;
    [Test]
    procedure TestSourcesDirectoriesAndBuildersWorkThroughTheDll;
    [Test]
    procedure TestMissingLibrary;
  end;

implementation

uses
  DelphiDoom.Wad.Factory, DelphiDoom.Wad.Dll.Engine, DelphiDoom.Wad.Dll.Loader,
  DelphiDoom.Tests.Wad.Helpers;

type
  H = TWadTestHelpers;

  /// <summary>An object that looks like a source of the DLL and was not made by it</summary>
  TForeignSource = class(TInterfacedObject, IWadDllSource)
  public
    function GetKind: Integer; stdcall;
    function GetCount: Integer; stdcall;
    function GetName(ABuffer: PAnsiChar; ABufferSize: Cardinal; out ALength: Cardinal): Integer; stdcall;
    function GetEntryName(AIndex: Integer; ABuffer: PAnsiChar; ABufferSize: Cardinal;
      out ALength: Cardinal): Integer; stdcall;
    function GetEntryInfo(AIndex: Integer; out AOffset, ASize: Integer): Integer; stdcall;
    function ReadEntry(AIndex: Integer; ADestination: Pointer; ADestinationSize: Cardinal): Integer; stdcall;
  end;

function TForeignSource.GetKind: Integer;
begin
  Result := 0;
end;

function TForeignSource.GetCount: Integer;
begin
  Result := 0;
end;

function TForeignSource.GetName(ABuffer: PAnsiChar; ABufferSize: Cardinal; out ALength: Cardinal): Integer;
begin
  ALength := 0;
  Result := WADDLL_OK;
end;

function TForeignSource.GetEntryName(AIndex: Integer; ABuffer: PAnsiChar; ABufferSize: Cardinal;
  out ALength: Cardinal): Integer;
begin
  ALength := 0;
  Result := WADDLL_ERR_RANGE;
end;

function TForeignSource.GetEntryInfo(AIndex: Integer; out AOffset, ASize: Integer): Integer;
begin
  AOffset := 0;
  ASize := 0;
  Result := WADDLL_ERR_RANGE;
end;

function TForeignSource.ReadEntry(AIndex: Integer; ADestination: Pointer; ADestinationSize: Cardinal): Integer;
begin
  Result := WADDLL_ERR_RANGE;
end;

{ TTestWadDll }

procedure TTestWadDll.Setup;
begin
  FDll := TWadDllEngine.Create;
  FClient := TWadDllClient.Create(FDll);
end;

procedure TTestWadDll.TearDown;
begin
  FreeAndNil(FClient);
  FDll := nil;
end;

function TTestWadDll.OpenSource(const ANames: array of string; const AData: array of string): IWadSource;
var
  LData: array of TBytes;
  LIndex: Integer;
begin
  SetLength(LData, Length(AData));
  for LIndex := 0 to High(AData) do
    LData[LIndex] := H.Bytes(AData[LIndex]);
  Result := FClient.OpenBytes('test.wad', H.MakeWad(ANames, LData));
end;

procedure TTestWadDll.TestVersion;
begin
  Assert.AreEqual('DelphiDoom.Wad', string(AnsiString(FDll.GetVersion)));
end;

procedure TTestWadDll.TestSourceListsItsLumps;
var
  LSource: IWadSource;
begin
  LSource := OpenSource(['MAP01', 'THINGS', 'EMPTY'], ['abc', '0123456789', '']);
  Assert.AreEqual(3, LSource.Count);
  Assert.AreEqual('THINGS', LSource.Entries[1].Name);
  Assert.AreEqual(10, LSource.Entries[1].Size);
  Assert.AreEqual(15, LSource.Entries[1].Offset);
  Assert.AreEqual('0123456789', TEncoding.ANSI.GetString(LSource.ReadEntry(1)));
  Assert.AreEqual(0, Length(LSource.ReadEntry(2)));
  Assert.WillRaise(procedure begin LSource.Entries[3]; end, EWadException);
end;

procedure TTestWadDll.TestSourceKindAndName;
var
  LSource: IWadSource;
begin
  LSource := OpenSource(['A'], ['x']);
  Assert.AreEqual(Ord(TWadSourceKind.Wad), Ord(LSource.Kind));
  Assert.AreEqual('test.wad', LSource.Name);
end;

procedure TTestWadDll.TestPakSourceThroughTheDll;
var
  LSource: IWadSource;
begin
  LSource := FClient.OpenBytes('test.pak', H.MakePak(['sounds/a.wav', 'music/b.ogg'],
    [H.Bytes('RIFF'), H.Bytes('OggS12')]));
  Assert.AreEqual(Ord(TWadSourceKind.Pak), Ord(LSource.Kind));
  Assert.AreEqual('MUSIC/B.OGG', LSource.Entries[1].Name);
  Assert.AreEqual('OggS12', TEncoding.ANSI.GetString(LSource.ReadEntry(1)));
end;

procedure TTestWadDll.TestOpenPathOfAFile;
var
  LPath: string;
  LSource: IWadSource;
begin
  LPath := TPath.Combine(TPath.GetTempPath, 'ddwaddll_' + TGUID.NewGuid.ToString + '.wad');
  TFile.WriteAllBytes(LPath, H.MakeWad(['HELLO'], [H.Bytes('world')]));
  try
    LSource := FClient.OpenPath(LPath);
    Assert.AreEqual('world', TEncoding.ANSI.GetString(LSource.ReadEntry(0)));
    LSource := nil;
  finally
    TFile.Delete(LPath);
  end;
end;

procedure TTestWadDll.TestOpenPathOfAMissingFile;
var
  LSource: IWadDllSource;
begin
  Assert.AreEqual(WADDLL_ERR_NOT_FOUND, FDll.OpenPath(PAnsiChar('C:\no\such\file.wad'), LSource));
  Assert.IsNull(LSource);
  Assert.WillRaise(procedure begin FClient.OpenPath('C:\no\such\file.wad'); end, EWadException);
end;

procedure TTestWadDll.TestNotAWadGivesTheMessageOfTheLibrary;
var
  LMessage: string;
begin
  LMessage := '';
  try
    FClient.OpenBytes('junk.wad', H.Bytes('this is not a wad, not at all'));
  except
    on E: EWadException do
      LMessage := E.Message;
  end;
  Assert.IsTrue(Pos('junk.wad', LMessage) > 0, LMessage);
  Assert.IsTrue(Pos('(' + IntToStr(WADDLL_ERR_MALFORMED) + ')', LMessage) > 0, LMessage);
end;

procedure TTestWadDll.TestDirectoryFindsTheLastLump;
var
  LDirectory: IWadDirectory;
  LFinder: IWadFinder;
begin
  LDirectory := FClient.CreateDirectory;
  LFinder := FClient.CreateFinder(LDirectory);
  LDirectory.AddSource(OpenSource(['PLAYPAL', 'X'], ['old', 'x']));
  LDirectory.AddSource(OpenSource(['PLAYPAL'], ['patch']));
  Assert.AreEqual(3, LDirectory.Count);
  Assert.AreEqual(2, LFinder.CheckNumForName('playpal'));
  Assert.AreEqual(0, LFinder.CheckFirstNumForName('PLAYPAL'));
  Assert.AreEqual(-1, LFinder.CheckNumForName('NOPE'));
  Assert.AreEqual(2, LFinder.GetNumForName('PLAYPAL'));
  Assert.WillRaise(procedure begin LFinder.GetNumForName('NOPE'); end, EWadException);
  Assert.WillRaise(procedure begin LFinder.GetFirstNumForName('NOPE'); end, EWadException);
end;

procedure TTestWadDll.TestDirectoryFlagsAndRanges;
var
  LDirectory: IWadDirectory;
  LFinder: IWadFinder;
begin
  LDirectory := FClient.CreateDirectory;
  LFinder := FClient.CreateFinder(LDirectory);
  LDirectory.AddSource(OpenSource(['P_START', 'WALL', 'P_END', 'F_START', 'WALL', 'F_END'],
    ['', 'p', '', '', 'f', '']));
  Assert.AreEqual(Cardinal(TYPE_PATCH), LDirectory.LumpFlags(1));
  Assert.AreEqual(1, LFinder.CheckNumForName('WALL', TYPE_PATCH));
  Assert.AreEqual(4, LFinder.CheckNumForName('WALL', TYPE_FLOOR));
  Assert.AreEqual(1, LFinder.CheckNumForNameInRange('WALL', 0, 3));
  Assert.AreEqual(-1, LFinder.CheckNumForNameInRange('WALL', 2, 3));
end;

procedure TTestWadDll.TestDirectoryReadsLumps;
var
  LDirectory: IWadDirectory;
  LReader: ILumpReader;
  LBuffer: array[0..7] of AnsiChar;
begin
  LDirectory := FClient.CreateDirectory;
  LReader := FClient.CreateReader(LDirectory);
  LDirectory.AddSource(OpenSource(['TEXT', 'EMPTY'], ['hello'#13#10'world', '']));
  Assert.AreEqual('hello'#13#10'world', LReader.TextLump(0));
  Assert.AreEqual(12, LDirectory.LumpSize(0));
  Assert.AreEqual(12, LDirectory.LumpOffset(0));
  Assert.AreEqual('', LReader.TextLump(1));
  FillChar(LBuffer, SizeOf(LBuffer), '.');
  LReader.ReadLumpInto(1, @LBuffer);
  Assert.AreEqual(Ord('.'), Integer(Ord(LBuffer[0])), 'an empty lump writes nothing');
  Assert.AreEqual('TEXT', LDirectory.LumpName(0));
  Assert.WillRaise(procedure begin LDirectory.LumpName(2); end, EWadException);
end;

procedure TTestWadDll.TestDirectoryTruncateAndReplace;
var
  LDirectory: IWadDirectory;
  LFinder: IWadFinder;
begin
  LDirectory := FClient.CreateDirectory;
  LFinder := FClient.CreateFinder(LDirectory);
  LDirectory.AddSource(OpenSource(['A', 'B'], ['a1', 'b1']));
  LDirectory.AddSource(OpenSource(['C'], ['c1']));
  LDirectory.ReplaceSource(0, OpenSource(['A', 'B'], ['a2', 'bbbb']));
  Assert.AreEqual(4, LDirectory.LumpSize(1));
  Assert.WillRaise(procedure begin LDirectory.ReplaceSource(0, OpenSource(['A'], ['x'])); end, EWadException);
  LDirectory.Truncate(1);
  Assert.AreEqual(2, LDirectory.Count);
  Assert.AreEqual(1, LDirectory.SourceCount);
  Assert.AreEqual(-1, LFinder.CheckNumForName('C'));
  Assert.WillRaise(procedure begin LDirectory.Truncate(5); end, EWadException);
end;

procedure TTestWadDll.TestDirectoryKnowsItsSources;
var
  LDirectory: IWadDirectory;
begin
  LDirectory := FClient.CreateDirectory;
  LDirectory.AddSource(OpenSource(['A'], ['a']));
  LDirectory.AddSource(OpenSource(['B', 'C'], ['b', 'c']));
  Assert.AreEqual(1, LDirectory.LumpSourceIndex(2));
  Assert.AreEqual(2, LDirectory.Sources[1].Count);
  Assert.WillRaise(procedure begin LDirectory.Sources[2]; end, EWadException);
end;

procedure TTestWadDll.TestForeignSourcesAreRefused;
var
  LDirectory: IWadDirectory;
  LDllDirectory: IWadDllDirectory;
  LBuilder: IWadDllBuilder;
begin
  // a source made by the classes of the library, not by the DLL
  LDirectory := FClient.CreateDirectory;
  Assert.WillRaise(procedure begin
    LDirectory.AddSource(TWadFactory.OpenBytes('x', H.MakeWad(['A'], [H.Bytes('a')]))); end, EWadException);
  Assert.WillRaise(procedure begin LDirectory.AddSource(nil); end, EWadException);
  // an object that looks like a source of the DLL
  Assert.AreEqual(WADDLL_OK, FDll.CreateDirectory(LDllDirectory));
  Assert.AreEqual(WADDLL_ERR_FOREIGN_OBJECT, LDllDirectory.AddSource(TForeignSource.Create));
  Assert.AreEqual(WADDLL_ERR_INVALID_ARGUMENT, LDllDirectory.AddSource(nil));
  Assert.AreEqual(WADDLL_OK, FDll.CreateBuilder(WADDLL_KIND_PWAD, LBuilder));
  Assert.AreEqual(WADDLL_ERR_FOREIGN_OBJECT, LBuilder.LoadFrom(TForeignSource.Create));
end;

procedure TTestWadDll.TestBuilderWritesTheBytesOfTheLibrary;
var
  LThrough, LDirect: IWadBuilder;
  LA, LB: TBytes;
begin
  LThrough := FClient.CreateBuilder(TWadKind.IWad);
  LDirect := TWadFactory.CreateBuilder(TWadKind.IWad);
  LThrough.AddLump('MAP01', nil);
  LDirect.AddLump('MAP01', nil);
  LThrough.AddLump('thingS', H.Bytes('0123456789'));
  LDirect.AddLump('thingS', H.Bytes('0123456789'));
  LThrough.AddLump('ODD', H.Bytes('12345'));
  LDirect.AddLump('ODD', H.Bytes('12345'));
  LA := LThrough.ToBytes;
  LB := LDirect.ToBytes;
  Assert.AreEqual(Length(LB), Length(LA));
  Assert.IsTrue(CompareMem(@LA[0], @LB[0], Length(LA)));
  Assert.AreEqual(Ord(TWadKind.IWad), Ord(LThrough.Kind));
  Assert.AreEqual(3, FClient.OpenBytes('w', LA).Count);
end;

procedure TTestWadDll.TestBuilderChanges;
var
  LBuilder: IWadBuilder;
  LStream: TBytesStream;
begin
  LBuilder := FClient.CreateBuilder;
  Assert.AreEqual(Ord(TWadKind.PWad), Ord(LBuilder.Kind));
  LBuilder.AddLump('A', H.Bytes('a'));
  LBuilder.AddLump('C', H.Bytes('c'));
  LBuilder.InsertLump(1, 'B', H.Bytes('b'));
  LBuilder.ReplaceLump(1, H.Bytes('bbbb'));
  LBuilder.RenameLump(2, 'z');
  LBuilder.MoveLump(2, 0);
  LBuilder.DeleteLump(1);
  Assert.AreEqual(2, LBuilder.Count);
  Assert.AreEqual('Z', LBuilder.LumpNames[0]);
  Assert.AreEqual('bbbb', TEncoding.ANSI.GetString(LBuilder.LumpData[1]));
  Assert.AreEqual(1, LBuilder.IndexOf('b'));
  Assert.AreEqual(-1, LBuilder.IndexOf('nope'));
  LBuilder.Kind := TWadKind.DWad;
  Assert.AreEqual(Ord(TWadKind.DWad), Ord(LBuilder.Kind));
  LStream := TBytesStream.Create;
  try
    LBuilder.SaveToStream(LStream);
    Assert.AreEqual(Int64(Length(LBuilder.ToBytes)), LStream.Size);
  finally
    LStream.Free;
  end;
  Assert.WillRaise(procedure begin LBuilder.AddLump('TOOLONGNAME', nil); end, EWadException);
  Assert.WillRaise(procedure begin LBuilder.DeleteLump(5); end, EWadException);
  LBuilder.Clear;
  Assert.AreEqual(0, LBuilder.Count);
end;

procedure TTestWadDll.TestBuilderLoadsASource;
var
  LBuilder: IWadBuilder;
begin
  LBuilder := FClient.CreateBuilder;
  LBuilder.LoadFrom(OpenSource(['MAP01', 'THINGS'], ['', 'things data']));
  LBuilder.AddLump('EXTRA', H.Bytes('e'));
  Assert.AreEqual(3, LBuilder.Count);
  Assert.AreEqual('things data', TEncoding.ANSI.GetString(LBuilder.LumpData[1]));
  Assert.WillRaise(procedure begin
    LBuilder.LoadFrom(TWadFactory.OpenBytes('x', H.MakeWad(['A'], [H.Bytes('a')]))); end, EWadException);
end;

procedure TTestWadDll.TestEightBitNamesSurvive;
var
  LBuilder: IWadBuilder;
  LSource: IWadSource;
begin
  LBuilder := FClient.CreateBuilder;
  LBuilder.AddLump(#$C9'LAN VIT', H.Bytes('x'));
  LSource := FClient.OpenBytes('w', LBuilder.ToBytes);
  Assert.AreEqual(#$C9'LAN VIT', LSource.Entries[0].Name);
end;

procedure TTestWadDll.TestTextProtocol;
var
  LSource: IWadDllSource;
  LLength: Cardinal;
  LBuffer: array[0..15] of AnsiChar;
  LBytes: TBytes;
begin
  LBytes := H.MakeWad(['ABCDEFGH'], [H.Bytes('x')]);
  Assert.AreEqual(WADDLL_OK, FDll.OpenMemory(PAnsiChar('my.wad'), @LBytes[0], Cardinal(Length(LBytes)), LSource));
  // only the length
  Assert.AreEqual(WADDLL_OK, LSource.GetEntryName(0, nil, 0, LLength));
  Assert.AreEqual(Cardinal(8), LLength);
  // a buffer that is short by the terminator
  Assert.AreEqual(WADDLL_ERR_BUFFER_TOO_SMALL, LSource.GetEntryName(0, @LBuffer, 8, LLength));
  Assert.AreEqual(Cardinal(8), LLength);
  // a buffer of the right size
  Assert.AreEqual(WADDLL_OK, LSource.GetEntryName(0, @LBuffer, 9, LLength));
  Assert.AreEqual('ABCDEFGH', string(AnsiString(PAnsiChar(@LBuffer))));
end;

procedure TTestWadDll.TestReadBuffersMustBeBigEnough;
var
  LSource: IWadDllSource;
  LDirectory: IWadDllDirectory;
  LBuilder: IWadDllBuilder;
  LBytes: TBytes;
  LBuffer: array[0..3] of Byte;
  LIndex: Integer;
  LWritten: Cardinal;
begin
  LBytes := H.MakeWad(['A'], [H.Bytes('0123456789')]);
  Assert.AreEqual(WADDLL_OK, FDll.OpenMemory(PAnsiChar('w'), @LBytes[0], Cardinal(Length(LBytes)), LSource));
  Assert.AreEqual(WADDLL_ERR_BUFFER_TOO_SMALL, LSource.ReadEntry(0, @LBuffer, SizeOf(LBuffer)));
  Assert.AreEqual(WADDLL_ERR_INVALID_ARGUMENT, LSource.ReadEntry(0, nil, 10));
  Assert.AreEqual(WADDLL_OK, FDll.CreateDirectory(LDirectory));
  Assert.AreEqual(WADDLL_OK, LDirectory.AddSource(LSource));
  Assert.AreEqual(WADDLL_ERR_BUFFER_TOO_SMALL, LDirectory.ReadLump(0, @LBuffer, SizeOf(LBuffer)));
  Assert.AreEqual(WADDLL_OK, FDll.CreateBuilder(WADDLL_KIND_PWAD, LBuilder));
  Assert.AreEqual(WADDLL_OK, LBuilder.AddLump(PAnsiChar('X'), @LBytes[0], 10, LIndex));
  Assert.AreEqual(WADDLL_ERR_BUFFER_TOO_SMALL, LBuilder.ReadLump(0, @LBuffer, SizeOf(LBuffer)));
  Assert.AreEqual(WADDLL_ERR_BUFFER_TOO_SMALL, LBuilder.Serialize(@LBuffer, SizeOf(LBuffer), LWritten));
  Assert.IsTrue(LWritten > SizeOf(LBuffer), 'the needed size is given back');
end;

procedure TTestWadDll.TestNumbersOutOfRange;
var
  LSource: IWadDllSource;
  LDirectory: IWadDllDirectory;
  LBuilder: IWadDllBuilder;
  LBytes: TBytes;
  LLength: Cardinal;
  LOffset, LSize, LSourceIndex: Integer;
  LFlags: Cardinal;
begin
  LBytes := H.MakeWad(['A'], [H.Bytes('x')]);
  Assert.AreEqual(WADDLL_OK, FDll.OpenMemory(PAnsiChar('w'), @LBytes[0], Cardinal(Length(LBytes)), LSource));
  Assert.AreEqual(WADDLL_ERR_RANGE, LSource.GetEntryName(1, nil, 0, LLength));
  Assert.AreEqual(WADDLL_ERR_RANGE, LSource.GetEntryInfo(-1, LOffset, LSize));
  Assert.AreEqual(WADDLL_ERR_RANGE, LSource.ReadEntry(7, @LBytes[0], 1));
  Assert.AreEqual(WADDLL_OK, FDll.CreateDirectory(LDirectory));
  Assert.AreEqual(WADDLL_ERR_RANGE, LDirectory.GetLumpInfo(0, LOffset, LSize, LFlags, LSourceIndex));
  Assert.AreEqual(WADDLL_ERR_RANGE, LDirectory.Truncate(1));
  Assert.AreEqual(WADDLL_ERR_RANGE, LDirectory.GetSource(0, LSource));
  Assert.AreEqual(WADDLL_OK, FDll.CreateBuilder(WADDLL_KIND_PWAD, LBuilder));
  Assert.AreEqual(WADDLL_ERR_RANGE, LBuilder.DeleteLump(0));
  Assert.AreEqual(WADDLL_ERR_RANGE, LBuilder.InsertLump(1, PAnsiChar('A'), nil, 0));
end;

procedure TTestWadDll.TestInvalidArguments;
var
  LSource: IWadDllSource;
  LBuilder: IWadDllBuilder;
  LDirectory: IWadDllDirectory;
  LLump: Integer;
begin
  Assert.AreEqual(WADDLL_ERR_INVALID_ARGUMENT, FDll.OpenPath(nil, LSource));
  Assert.AreEqual(WADDLL_ERR_INVALID_ARGUMENT, FDll.OpenMemory(PAnsiChar('x'), nil, 0, LSource));
  Assert.AreEqual(WADDLL_ERR_INVALID_ARGUMENT, FDll.CreateBuilder(99, LBuilder));
  Assert.IsNull(LBuilder);
  Assert.AreEqual(WADDLL_OK, FDll.CreateDirectory(LDirectory));
  Assert.AreEqual(WADDLL_ERR_INVALID_ARGUMENT, LDirectory.CheckNumForName(nil, 0, LLump));
  Assert.AreEqual(-1, LLump);
end;

{ TTestWadDllLoader }

function TTestWadDllLoader.DllPath: string;
begin
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), '..\Libs\' + DDWAD_LIBRARY_NAME));
end;

procedure TTestWadDllLoader.TestLoadsAndAnswers;
var
  LLoader: TWadDllLoader;
begin
  if not TFile.Exists(DllPath) then
    Assert.Pass('DDWad.dll is not built');
  LLoader := TWadDllLoader.Create(DllPath);
  try
    Assert.AreEqual('DelphiDoom.Wad', string(AnsiString(LLoader.Wad.GetVersion)));
  finally
    LLoader.Free;
  end;
end;

procedure TTestWadDllLoader.TestSourcesDirectoriesAndBuildersWorkThroughTheDll;
var
  LLoader: TWadDllLoader;
  LClient: TWadDllClient;
  LSource: IWadSource;
  LDirectory: IWadDirectory;
  LFinder: IWadFinder;
  LReader: ILumpReader;
  LBuilder: IWadBuilder;
  LBytes: TBytes;
begin
  if not TFile.Exists(DllPath) then
    Assert.Pass('DDWad.dll is not built');
  LLoader := TWadDllLoader.Create(DllPath);
  LClient := TWadDllClient.Create(LLoader.Wad);
  try
    LBuilder := LClient.CreateBuilder(TWadKind.PWad);
    LBuilder.AddLump('S_START', nil);
    LBuilder.AddLump('TROOA1', H.Bytes('sprite'));
    LBuilder.AddLump('S_END', nil);
    LBytes := LBuilder.ToBytes;

    LSource := LClient.OpenBytes('through.wad', LBytes);
    LDirectory := LClient.CreateDirectory;
    LDirectory.AddSource(LSource);
    Assert.AreEqual(3, LDirectory.Count);
    LFinder := LClient.CreateFinder(LDirectory);
    LReader := LClient.CreateReader(LDirectory);
    Assert.AreEqual(1, LFinder.CheckNumForName('TROOA1', TYPE_SPRITE));
    Assert.AreEqual('sprite', LReader.TextLump(1));
  finally
    // everything of the DLL goes before the DLL
    LFinder := nil;
    LReader := nil;
    LBuilder := nil;
    LDirectory := nil;
    LSource := nil;
    LClient.Free;
    LLoader.Free;
  end;
end;

procedure TTestWadDllLoader.TestMissingLibrary;
var
  LCode: Integer;
begin
  LCode := WADDLL_OK;
  try
    TWadDllLoader.Create('C:\no\such\DDWad.dll').Free;
  except
    on E: EWadDllException do
      LCode := E.Code;
  end;
  Assert.AreEqual(WADDLL_ERR_NOT_FOUND, LCode);
end;

end.
