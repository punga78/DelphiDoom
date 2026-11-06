{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the net library - the nodes of the command line        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Net.NodeListParser;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Net.Types, DelphiDoom.Net.NodeListParser;

type
  [TestFixture]
  [Category('net')]
  TTestNetNodeListParser = class(TObject)
  public
    [Test]
    procedure TestNamesAndAddressesWithPorts;
    [Test]
    procedure TestListEndsAtTheNextOption;
    [Test]
    procedure TestNoHostsIsAnEmptyList;
    [Test]
    procedure TestPortWithoutDigitsIsZero;
    [Test]
    procedure TestPortIsTruncatedToSixteenBits;
    [Test]
    procedure TestPortOfAnotherHostIsNotTheOneBefore;
    [Test]
    [TestCase('Cifre', '12,12')]
    [TestCase('Cifre e lettere', '12x,12')]
    [TestCase('Lettere', 'abc,0')]
    [TestCase('Vuoto', ',0')]
    [TestCase('Meno', '-7,-7')]
    [TestCase('Spazi', '  5,5')]
    procedure TestLeadingNumberIsAtoi(const AText: string; AExpected: Integer);
  end;

implementation

{ TTestNetNodeListParser }

procedure TTestNetNodeListParser.TestNamesAndAddressesWithPorts;
var
  LNodes: TArray<TNetNodeAddress>;
begin
  LNodes := TNetNodeListParser.Parse(['-NET', '2', '.192.168.0.2', 'PC3', ':6000', '.10.0.0.9'], 2, 5029);
  Assert.AreEqual(3, Length(LNodes));
  Assert.AreEqual('192.168.0.2', LNodes[0].Host);
  Assert.IsTrue(LNodes[0].IsLiteral);
  Assert.AreEqual(Word(5029), LNodes[0].Port, 'porta di default');
  Assert.AreEqual('PC3', LNodes[1].Host);
  Assert.IsFalse(LNodes[1].IsLiteral);
  Assert.AreEqual(Word(6000), LNodes[1].Port);
  Assert.AreEqual('10.0.0.9', LNodes[2].Host);
  Assert.AreEqual(Word(5029), LNodes[2].Port);
end;

procedure TTestNetNodeListParser.TestListEndsAtTheNextOption;
var
  LNodes: TArray<TNetNodeAddress>;
begin
  LNodes := TNetNodeListParser.Parse(['-NET', '1', 'PC2', '-DUP', '2', 'PC9'], 2, 5029);
  Assert.AreEqual(1, Length(LNodes));
  Assert.AreEqual('PC2', LNodes[0].Host);
end;

procedure TTestNetNodeListParser.TestNoHostsIsAnEmptyList;
begin
  Assert.AreEqual(0, Length(TNetNodeListParser.Parse(['-NET', '1'], 2, 5029)));
  Assert.AreEqual(0, Length(TNetNodeListParser.Parse(['-NET', '1', '-DRONE'], 2, 5029)));
  Assert.AreEqual(0, Length(TNetNodeListParser.Parse(nil, 0, 5029)));
end;

procedure TTestNetNodeListParser.TestPortWithoutDigitsIsZero;
var
  LNodes: TArray<TNetNodeAddress>;
begin
  LNodes := TNetNodeListParser.Parse(['PC2', ':X'], 0, 5029);
  Assert.AreEqual(Word(0), LNodes[0].Port);
end;

procedure TTestNetNodeListParser.TestPortIsTruncatedToSixteenBits;
var
  LNodes: TArray<TNetNodeAddress>;
begin
  LNodes := TNetNodeListParser.Parse(['PC2', ':65541'], 0, 5029);
  Assert.AreEqual(Word(5), LNodes[0].Port, 'htons(atoi) del vecchio codice');
end;

procedure TTestNetNodeListParser.TestPortOfAnotherHostIsNotTheOneBefore;
var
  LNodes: TArray<TNetNodeAddress>;
begin
  LNodes := TNetNodeListParser.Parse(['PC2', ':7000', 'PC3'], 0, 5029);
  Assert.AreEqual(Word(7000), LNodes[0].Port);
  Assert.AreEqual(Word(5029), LNodes[1].Port);
end;

procedure TTestNetNodeListParser.TestLeadingNumberIsAtoi(const AText: string; AExpected: Integer);
begin
  Assert.AreEqual(AExpected, TNetNodeListParser.LeadingNumber(AText));
end;

end.
