{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the cheat sequence                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Console.CheatSequence;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Console.Types, DelphiDoom.Console.CheatSequence;

type
  [TestFixture]
  [Category('console')]
  TTestCheatSequence = class(TObject)
  private
    function Typed(const ACheat: TCheatSequence; const AKeys: string): string;
    function Sequence(const ABytes: array of Byte): TCheatSequence;
  public
    [Test]
    procedure TestRightKeysAcquireTheCheat;
    [Test]
    procedure TestWrongKeyResetsTheProgress;
    [Test]
    procedure TestWrongKeyIsNotRetriedAsTheFirstKey;
    [Test]
    procedure TestCheatCanBeAcquiredManyTimes;
    [Test]
    procedure TestResetStartsAgain;
    [Test]
    procedure TestParameterKeysAreCaptured;
    [Test]
    procedure TestParameterStaysAvailableAfterAcquire;
    [Test]
    procedure TestParameterOfTwoKeysIsAcquiredOnTheSecond;
    [Test]
    procedure TestKeyThatIsNotAByteIsNeverPartOfACheat;
    [Test]
    procedure TestSequenceThatIsEmptyIsAnError;
    [Test]
    procedure TestCheatOfOneKey;
  end;

implementation

uses
  DelphiDoom.Console.CheatSequenceReader, DelphiDoom.Console.Factory, DelphiDoom.Tests.Console.CheatData;

{ TTestCheatSequence }

function TTestCheatSequence.Sequence(const ABytes: array of Byte): TCheatSequence;
begin
  Result := TConsoleFactory.CreateCheatSequence(TCheatSequenceReader.FromBytes(ABytes));
end;

function TTestCheatSequence.Typed(const ACheat: TCheatSequence; const AKeys: string): string;
var
  LChar: Char;
begin
  Result := '';
  for LChar in AKeys do
    case ACheat.Check(Ord(LChar)) of
      csUnknown: Result := Result + 'U';
      csPending: Result := Result + 'P';
      csAcquired: Result := Result + 'A';
    end;
end;

procedure TTestCheatSequence.TestRightKeysAcquireTheCheat;
var
  LCheat: TCheatSequence;
begin
  LCheat := Sequence(IDDQD);
  try
    Assert.AreEqual('PPPPA', Typed(LCheat, 'iddqd'), 'dovrebbe essere in attesa fino all''ultimo tasto');
  finally
    LCheat.Free;
  end;
end;

procedure TTestCheatSequence.TestWrongKeyResetsTheProgress;
var
  LCheat: TCheatSequence;
begin
  LCheat := Sequence(IDDQD);
  try
    Assert.AreEqual('PPUUUU', Typed(LCheat, 'idxddq'), 'dovrebbe ricominciare dopo un tasto sbagliato');
    Assert.AreEqual('PPPPA', Typed(LCheat, 'iddqd'), 'dovrebbe poter ricominciare');
  finally
    LCheat.Free;
  end;
end;

procedure TTestCheatSequence.TestWrongKeyIsNotRetriedAsTheFirstKey;
var
  LCheat: TCheatSequence;
begin
  LCheat := Sequence(IDDQD);
  try
    // old defect kept: the wrong "i" resets, it is not the first key of a new try
    Assert.AreEqual('PUUUUU', Typed(LCheat, 'iiddqd'),
      'dovrebbe conservare il difetto: il tasto sbagliato non conta come primo');
  finally
    LCheat.Free;
  end;
end;

procedure TTestCheatSequence.TestCheatCanBeAcquiredManyTimes;
var
  LCheat: TCheatSequence;
begin
  LCheat := Sequence(IDDQD);
  try
    Assert.AreEqual('PPPPAPPPPA', Typed(LCheat, 'iddqdiddqd'), 'dovrebbe riconoscerlo due volte');
  finally
    LCheat.Free;
  end;
end;

procedure TTestCheatSequence.TestResetStartsAgain;
var
  LCheat: TCheatSequence;
begin
  LCheat := Sequence(IDDQD);
  try
    Typed(LCheat, 'idd');
    LCheat.Reset;
    Assert.AreEqual('PPPPA', Typed(LCheat, 'iddqd'), 'dovrebbe ripartire dal primo tasto');
  finally
    LCheat.Free;
  end;
end;

procedure TTestCheatSequence.TestParameterKeysAreCaptured;
var
  LCheat: TCheatSequence;
begin
  LCheat := Sequence(IDMUS);
  try
    Assert.AreEqual('PPPPPUA', Typed(LCheat, 'idmus12'), 'dovrebbe leggere due tasti di parametro');
    Assert.AreEqual('12', LCheat.Param, 'dovrebbe dare il parametro');
  finally
    LCheat.Free;
  end;
end;

procedure TTestCheatSequence.TestParameterStaysAvailableAfterAcquire;
var
  LCheat: TCheatSequence;
begin
  LCheat := Sequence(IDMUS);
  try
    Typed(LCheat, 'idmus34');
    Assert.AreEqual('34', LCheat.Param, 'dovrebbe tenere il parametro dopo l''ultimo tasto');
  finally
    LCheat.Free;
  end;
end;

procedure TTestCheatSequence.TestParameterOfTwoKeysIsAcquiredOnTheSecond;
var
  LCheat: TCheatSequence;
begin
  LCheat := Sequence(IDMUS);
  try
    Assert.AreEqual('PPPPPU', Typed(LCheat, 'idmus1'), 'dovrebbe aspettare il secondo tasto');
    Assert.AreEqual('A', Typed(LCheat, '2'), 'dovrebbe completarsi al secondo tasto');
  finally
    LCheat.Free;
  end;
end;

procedure TTestCheatSequence.TestKeyThatIsNotAByteIsNeverPartOfACheat;
var
  LCheat: TCheatSequence;
begin
  LCheat := Sequence(IDDQD);
  try
    Assert.AreEqual(csUnknown, LCheat.Check(256), 'dovrebbe rifiutare un tasto oltre 255');
    Assert.AreEqual(csUnknown, LCheat.Check(-1), 'dovrebbe rifiutare un tasto negativo');
    Assert.AreEqual('PPPPA', Typed(LCheat, 'iddqd'), 'dovrebbe poter ricominciare');
  finally
    LCheat.Free;
  end;
end;

procedure TTestCheatSequence.TestSequenceThatIsEmptyIsAnError;
begin
  Assert.WillRaise(
    procedure
    begin
      TConsoleFactory.CreateCheatSequence('');
    end,
    EConsoleException, 'dovrebbe rifiutare una sequenza vuota');
end;

procedure TTestCheatSequence.TestCheatOfOneKey;
var
  LCheat: TCheatSequence;
begin
  LCheat := Sequence([$B2, $FF]);
  try
    Assert.AreEqual('AA', Typed(LCheat, 'ii'), 'dovrebbe completarsi a ogni tasto giusto');
  finally
    LCheat.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestCheatSequence);

end.
