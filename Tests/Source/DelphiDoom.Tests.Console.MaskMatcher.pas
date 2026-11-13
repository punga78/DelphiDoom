{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the masks of the console                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Console.MaskMatcher;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('console')]
  TTestConsoleMaskMatcher = class(TObject)
  private
    function Names: TArray<string>;
    function Joined(const AMask: string): string;
  public
    [Test]
    procedure TestMaskWithoutStarIsAPrefix;
    [Test]
    procedure TestStarAtTheStartAcceptsAnyBeginning;
    [Test]
    procedure TestStarOnlyAcceptsEverything;
    [Test]
    procedure TestMaskIsNotCaseSensitive;
    [Test]
    procedure TestTheEndOfTheNameIsNotChecked;
    [Test]
    procedure TestPiecesMustFollowEachOther;
    [Test]
    procedure TestNoNamesFit;
    [Test]
    procedure TestTheOrderOfTheNamesIsKept;
  end;

implementation

uses
  DelphiDoom.Console.MaskMatcher;

{ TTestConsoleMaskMatcher }

function TTestConsoleMaskMatcher.Names: TArray<string>;
begin
  Result := TArray<string>.Create('echo', 'exec', 'execcommandfile', 'typeof', 'multi1', 'multi2');
end;

function TTestConsoleMaskMatcher.Joined(const AMask: string): string;
begin
  Result := string.Join(',', TConsoleMaskMatcher.Filter(Names, AMask));
end;

procedure TTestConsoleMaskMatcher.TestMaskWithoutStarIsAPrefix;
begin
  Assert.AreEqual('exec,execcommandfile', Joined('exec'), 'dovrebbe trovare i nomi che iniziano cosi''');
end;

procedure TTestConsoleMaskMatcher.TestStarAtTheStartAcceptsAnyBeginning;
begin
  Assert.AreEqual('echo,execcommandfile,typeof', Joined('*o*'),
    'dovrebbe cercare il pezzo in qualunque punto');
end;

procedure TTestConsoleMaskMatcher.TestStarOnlyAcceptsEverything;
begin
  Assert.AreEqual<Integer>(6, Length(TConsoleMaskMatcher.Filter(Names, '*')), 'dovrebbe accettare tutti i nomi');
  Assert.AreEqual<Integer>(6, Length(TConsoleMaskMatcher.Filter(Names, '')), 'dovrebbe accettare tutti i nomi');
end;

procedure TTestConsoleMaskMatcher.TestMaskIsNotCaseSensitive;
begin
  Assert.AreEqual('echo', Joined('ECH*'), 'dovrebbe ignorare le maiuscole');
end;

procedure TTestConsoleMaskMatcher.TestTheEndOfTheNameIsNotChecked;
begin
  // old behaviour kept: "e*o" fits "execcommandfile" too, which does not end with "o"
  Assert.AreEqual('echo,execcommandfile', Joined('e*o'),
    'dovrebbe conservare il difetto: la fine del nome non e'' controllata');
end;

procedure TTestConsoleMaskMatcher.TestPiecesMustFollowEachOther;
begin
  Assert.AreEqual('multi1,multi2', Joined('mu*i*'), 'dovrebbe accettare i pezzi in ordine');
  Assert.AreEqual('', Joined('a*a'), 'dovrebbe conservare il difetto: i pezzi uguali non si ripetono');
end;

procedure TTestConsoleMaskMatcher.TestNoNamesFit;
begin
  Assert.AreEqual<Integer>(0, Length(TConsoleMaskMatcher.Filter(Names, 'zz*')), 'dovrebbe dare una lista vuota');
end;

procedure TTestConsoleMaskMatcher.TestTheOrderOfTheNamesIsKept;
begin
  Assert.AreEqual('echo,exec,execcommandfile,typeof,multi1,multi2', Joined('*'),
    'dovrebbe lasciare i nomi nell''ordine ricevuto');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestConsoleMaskMatcher);

end.
