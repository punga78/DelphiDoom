{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Wad library - TLumpCache                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Wad.LumpCache;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Wad.Types, DelphiDoom.Wad.Intf;

type
  [TestFixture]
  [Category('wad')]
  TTestWadLumpCache = class(TObject)
  public
    [Test]
    procedure TestLumpIsReadOnlyOnce;
    [Test]
    procedure TestPurgeDropsOnlyTheCacheLevel;
    [Test]
    procedure TestStaticAskedAfterCacheIsKept;
    [Test]
    procedure TestReleaseForgetsOneLump;
    [Test]
    procedure TestClearForgetsEverything;
    [Test]
    procedure TestErrorsOfTheReaderPass;
    [Test]
    procedure TestNilReaderIsRefused;
    [Test]
    procedure TestWorksOnADirectory;
  end;

implementation

uses
  DelphiDoom.Wad.Factory, DelphiDoom.Tests.Wad.Helpers;

type
  /// <summary>A reader that counts the reads and gives the lump number as data</summary>
  TFakeReader = class(TInterfacedObject, ILumpReader)
  public
    Reads: Integer;
    function ReadLump(ALump: Integer): TBytes;
    procedure ReadLumpInto(ALump: Integer; ADestination: Pointer);
    function TextLump(ALump: Integer): string;
  end;

function TFakeReader.ReadLump(ALump: Integer): TBytes;
begin
  Inc(Reads);
  if ALump < 0 then
    raise EWadException.Create('no such lump');
  Result := TBytes.Create(Byte(ALump));
end;

procedure TFakeReader.ReadLumpInto(ALump: Integer; ADestination: Pointer);
begin
  PByte(ADestination)^ := Byte(ALump);
end;

function TFakeReader.TextLump(ALump: Integer): string;
begin
  Result := IntToStr(ALump);
end;

{ TTestWadLumpCache }

procedure TTestWadLumpCache.TestLumpIsReadOnlyOnce;
var
  LReader: TFakeReader;
  LCache: ILumpCache;
begin
  LReader := TFakeReader.Create;
  LCache := TWadFactory.CreateCache(LReader);
  Assert.AreEqual(7, Integer(LCache.Lump(7, TLumpCacheLevel.Cache)[0]));
  Assert.AreEqual(7, Integer(LCache.Lump(7, TLumpCacheLevel.Cache)[0]));
  Assert.AreEqual(7, Integer(LCache.Lump(7, TLumpCacheLevel.Static)[0]));
  Assert.AreEqual(1, LReader.Reads);
  Assert.AreEqual(1, LCache.CachedCount);
end;

procedure TTestWadLumpCache.TestPurgeDropsOnlyTheCacheLevel;
var
  LReader: TFakeReader;
  LCache: ILumpCache;
begin
  LReader := TFakeReader.Create;
  LCache := TWadFactory.CreateCache(LReader);
  LCache.Lump(1, TLumpCacheLevel.Static);
  LCache.Lump(2, TLumpCacheLevel.Cache);
  Assert.AreEqual(2, LCache.CachedCount);
  LCache.Purge;
  Assert.AreEqual(1, LCache.CachedCount);
  LCache.Lump(1, TLumpCacheLevel.Cache);
  Assert.AreEqual(2, LReader.Reads, 'the static lump is not read again');
  LCache.Lump(2, TLumpCacheLevel.Cache);
  Assert.AreEqual(3, LReader.Reads, 'the purged one is');
end;

procedure TTestWadLumpCache.TestStaticAskedAfterCacheIsKept;
var
  LReader: TFakeReader;
  LCache: ILumpCache;
begin
  LReader := TFakeReader.Create;
  LCache := TWadFactory.CreateCache(LReader);
  LCache.Lump(5, TLumpCacheLevel.Cache);
  LCache.Lump(5, TLumpCacheLevel.Static);
  LCache.Purge;
  Assert.AreEqual(1, LCache.CachedCount);
end;

procedure TTestWadLumpCache.TestReleaseForgetsOneLump;
var
  LCache: ILumpCache;
begin
  LCache := TWadFactory.CreateCache(TFakeReader.Create);
  LCache.Lump(1, TLumpCacheLevel.Static);
  LCache.Lump(2, TLumpCacheLevel.Cache);
  LCache.Release(1);
  LCache.Release(2);
  LCache.Release(3);
  Assert.AreEqual(0, LCache.CachedCount);
end;

procedure TTestWadLumpCache.TestClearForgetsEverything;
var
  LCache: ILumpCache;
begin
  LCache := TWadFactory.CreateCache(TFakeReader.Create);
  LCache.Lump(1, TLumpCacheLevel.Static);
  LCache.Lump(2, TLumpCacheLevel.Cache);
  LCache.Clear;
  Assert.AreEqual(0, LCache.CachedCount);
end;

procedure TTestWadLumpCache.TestErrorsOfTheReaderPass;
var
  LCache: ILumpCache;
begin
  LCache := TWadFactory.CreateCache(TFakeReader.Create);
  Assert.WillRaise(procedure begin LCache.Lump(-1, TLumpCacheLevel.Cache); end, EWadException);
  Assert.AreEqual(0, LCache.CachedCount);
end;

procedure TTestWadLumpCache.TestNilReaderIsRefused;
begin
  Assert.WillRaise(procedure begin TWadFactory.CreateCache(nil); end, EArgumentNilException);
end;

procedure TTestWadLumpCache.TestWorksOnADirectory;
var
  LDirectory: IWadDirectory;
  LCache: ILumpCache;
begin
  LDirectory := TWadFactory.CreateDirectory;
  LDirectory.AddSource(TWadFactory.OpenBytes('w',
    TWadTestHelpers.MakeWad(['A'], [TWadTestHelpers.Bytes('data')])));
  LCache := TWadFactory.CreateCache(TWadFactory.CreateReader(LDirectory));
  Assert.AreEqual('data', TEncoding.ANSI.GetString(LCache.Lump(0, TLumpCacheLevel.Cache)));
end;

end.
