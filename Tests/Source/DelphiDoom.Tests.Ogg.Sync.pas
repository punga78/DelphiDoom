{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TOggSync - the cases at the edges of libogg            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Ogg.Sync;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Ogg.Types;

type
  [TestFixture]
  [Category('ogg')]
  TTestOggSync = class(TObject)
  private
    FState: TOggSyncState;
    procedure Feed(const ABytes: TBytes);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeLiberareUnoStatoAllocato;
    [Test]
    procedure DovrebbeRicominciareDaCapoConReset;
    [Test]
    procedure DovrebbeNonFareNullaSuUnoStatoGuasto;
    [Test]
    procedure DovrebbeRifiutarePiuByteDelloSpazio;
    [Test]
    procedure DovrebbeSaltareTuttoSeNonTrovaUnaPagina;
  end;

implementation

uses
  DelphiDoom.Ogg.Memory, DelphiDoom.Ogg.Sync;

{ TTestOggSync }

procedure TTestOggSync.Setup;
begin
  TOggSync.Init(@FState);
end;

procedure TTestOggSync.TearDown;
begin
  TOggSync.Clear(@FState);
end;

procedure TTestOggSync.Feed(const ABytes: TBytes);
var
  LBuffer: PByte;
begin
  LBuffer := TOggSync.Buffer(@FState, Length(ABytes));
  Move(ABytes[0], LBuffer^, Length(ABytes));
  Assert.AreEqual(0, TOggSync.Wrote(@FState, Length(ABytes)));
end;

procedure TTestOggSync.DovrebbeLiberareUnoStatoAllocato;
var
  LState: POggSyncState;
begin
  LState := TOggMemory.Allocate(SizeOf(TOggSyncState));
  Assert.AreEqual(0, TOggSync.Init(LState));
  Assert.IsNotNull(TOggSync.Buffer(LState, 100));
  Assert.AreEqual(0, TOggSync.ClearAndFree(LState));
  Assert.AreEqual(0, TOggSync.ClearAndFree(nil));
end;

procedure TTestOggSync.DovrebbeRicominciareDaCapoConReset;
var
  LPage: TOggPage;
begin
  // Bytes that are not a page: the first time sync is lost is told
  Feed(TEncoding.ASCII.GetBytes('this is not the capture pattern of a page'));
  Assert.AreEqual(-1, TOggSync.PageOut(@FState, @LPage));
  Assert.AreEqual(0, TOggSync.Reset(@FState));
  Assert.AreEqual(0, FState.Fill);
  Assert.AreEqual(0, FState.Returned);
  Assert.AreEqual(0, FState.Unsynced);
  Assert.AreEqual(0, FState.HeaderBytes);
  Assert.AreEqual(0, FState.BodyBytes);
  // The memory is kept for what comes next
  Assert.IsTrue(FState.Storage > 0);
end;

procedure TTestOggSync.DovrebbeNonFareNullaSuUnoStatoGuasto;
var
  LPage: TOggPage;
begin
  // A negative storage is how libogg marks a state that cannot be used
  FState.Storage := -1;
  Assert.AreEqual(-1, TOggSync.Check(@FState));
  Assert.AreEqual(-1, TOggSync.Reset(@FState));
  Assert.IsNull(TOggSync.Buffer(@FState, 10));
  Assert.AreEqual(-1, TOggSync.Wrote(@FState, 0));
  Assert.AreEqual(0, Integer(TOggSync.PageSeek(@FState, @LPage)));
  Assert.AreEqual(0, TOggSync.PageOut(@FState, @LPage));
  FState.Storage := 0;
end;

procedure TTestOggSync.DovrebbeRifiutarePiuByteDelloSpazio;
begin
  TOggSync.Buffer(@FState, 10);
  Assert.AreEqual(-1, TOggSync.Wrote(@FState, FState.Storage + 1));
  Assert.AreEqual(0, FState.Fill);
end;

procedure TTestOggSync.DovrebbeSaltareTuttoSeNonTrovaUnaPagina;
var
  LGarbage: TBytes;
  LPage: TOggPage;
begin
  // Thirty bytes without an 'O': all of them are skipped at once
  SetLength(LGarbage, 30);
  FillChar(LGarbage[0], Length(LGarbage), Ord('x'));
  Feed(LGarbage);
  Assert.AreEqual(-30, Integer(TOggSync.PageSeek(@FState, @LPage)));
  Assert.AreEqual(30, FState.Returned);
  Assert.AreEqual(0, Integer(TOggSync.PageSeek(@FState, @LPage)));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestOggSync);

end.
