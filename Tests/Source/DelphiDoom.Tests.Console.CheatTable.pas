{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the cheat table                                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Console.CheatTable;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Console.Types, DelphiDoom.Console.CheatTable;

type
  [TestFixture]
  [Category('console')]
  TTestCheatTable = class(TObject)
  private
    FTable: TCheatTable;
    function Feed(const AKeys: string; out AAcquired: string): Boolean;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestAcquiredCheatIsNamed;
    [Test]
    procedure TestKeyOfACheatInProgressIsTaken;
    [Test]
    procedure TestKeyOfNoCheatIsNotTaken;
    [Test]
    procedure TestFirstAcquiredCheatStopsTheChain;
    [Test]
    procedure TestDisabledCheatDoesNotSeeTheKeys;
    [Test]
    procedure TestFindGivesTheSequenceToReadItsParameter;
    [Test]
    procedure TestSameNameTwiceIsAnError;
    [Test]
    procedure TestResetStartsAllTheCheatsAgain;
  end;

implementation

uses
  DelphiDoom.Console.CheatSequenceReader, DelphiDoom.Console.Factory, DelphiDoom.Tests.Console.CheatData;

{ TTestCheatTable }

procedure TTestCheatTable.Setup;
begin
  FTable := TConsoleFactory.CreateCheatTable;
  FTable.Add('god', TCheatSequenceReader.FromBytes(IDDQD), nil);
  FTable.Add('ammo', TCheatSequenceReader.FromBytes(IDKFA), nil);
  FTable.Add('mus', TCheatSequenceReader.FromBytes(IDMUS), nil);
end;

procedure TTestCheatTable.TearDown;
begin
  FTable.Free;
end;

function TTestCheatTable.Feed(const AKeys: string; out AAcquired: string): Boolean;
var
  LChar: Char;
begin
  Result := False;
  AAcquired := '';
  for LChar in AKeys do
    Result := FTable.Feed(Ord(LChar), AAcquired);
end;

procedure TTestCheatTable.TestAcquiredCheatIsNamed;
var
  LName: string;
begin
  Assert.IsTrue(Feed('iddqd', LName), 'dovrebbe prendere il tasto');
  Assert.AreEqual('god', LName, 'dovrebbe dare il nome del cheat');
end;

procedure TTestCheatTable.TestKeyOfACheatInProgressIsTaken;
var
  LName: string;
begin
  Assert.IsTrue(Feed('id', LName), 'dovrebbe prendere il tasto di un cheat in corso');
  Assert.AreEqual('', LName, 'non dovrebbe essere ancora completo');
end;

procedure TTestCheatTable.TestKeyOfNoCheatIsNotTaken;
var
  LName: string;
begin
  Assert.IsFalse(Feed('x', LName), 'dovrebbe lasciare il tasto al gioco');
end;

procedure TTestCheatTable.TestFirstAcquiredCheatStopsTheChain;
var
  LName: string;
begin
  // two cheats with the same keys: only the first one sees the last key
  FTable.Free;
  FTable := TConsoleFactory.CreateCheatTable;
  FTable.Add('first', TCheatSequenceReader.FromBytes(IDDQD), nil);
  FTable.Add('second', TCheatSequenceReader.FromBytes(IDDQD), nil);
  Feed('iddqd', LName);
  Assert.AreEqual('first', LName, 'dovrebbe fermarsi al primo cheat completo');
  Assert.AreEqual(Integer(csAcquired), Integer(FTable.Find('second').Check(Ord('d'))),
    'il secondo non ha visto l''ultimo tasto: lo completa solo con quello');
end;

procedure TTestCheatTable.TestDisabledCheatDoesNotSeeTheKeys;
var
  LName: string;
  LEnabled: Boolean;
begin
  FTable.Free;
  FTable := TConsoleFactory.CreateCheatTable;
  LEnabled := False;
  FTable.Add('god', TCheatSequenceReader.FromBytes(IDDQD),
    function: Boolean
    begin
      Result := LEnabled;
    end);
  Assert.IsFalse(Feed('iddqd', LName), 'dovrebbe ignorare un cheat non attivo');
  LEnabled := True;
  Assert.IsTrue(Feed('iddqd', LName), 'dovrebbe vedere i tasti quando e'' attivo');
  Assert.AreEqual('god', LName);
end;

procedure TTestCheatTable.TestFindGivesTheSequenceToReadItsParameter;
var
  LName: string;
begin
  Feed('idmus07', LName);
  Assert.AreEqual('mus', LName);
  Assert.AreEqual('07', FTable.Find('MUS').Param, 'dovrebbe dare il parametro, senza badare alle maiuscole');
  Assert.IsNull(FTable.Find('nothing'), 'dovrebbe dare nil per un nome che non c''e''');
end;

procedure TTestCheatTable.TestSameNameTwiceIsAnError;
begin
  Assert.WillRaise(
    procedure
    begin
      FTable.Add('GOD', TCheatSequenceReader.FromBytes(IDDQD), nil);
    end,
    EConsoleException, 'dovrebbe rifiutare un nome gia'' nella tabella');
end;

procedure TTestCheatTable.TestResetStartsAllTheCheatsAgain;
var
  LName: string;
begin
  Feed('idd', LName);
  FTable.Reset;
  Assert.IsTrue(Feed('iddqd', LName), 'dovrebbe ripartire');
  Assert.AreEqual('god', LName);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestCheatTable);

end.
