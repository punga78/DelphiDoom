{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the definitions library - the reader of SWITCHES       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Definitions.SwitchLumpReader;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Definitions.Types;

type
  [TestFixture]
  [Category('definitions')]
  TTestSwitchLumpReader = class(TObject)
  private
    function Entry(const AName1, AName2: string; AEpisode: Integer; AWithSound: Boolean;
      ASound: Integer = 0): TBytes;
    function Join(const AParts: array of TBytes): TBytes;
    function Read(const ABytes: TBytes; AWithSound: Boolean): TArray<TDefSwitchPair>;
  public
    [Test]
    procedure TestUnLumpVuotoNonHaVoci;
    [Test]
    procedure TestUnaVoceDiDoomHaVentiByte;
    [Test]
    procedure TestLeVociSonoNellOrdineDelLump;
    [Test]
    procedure TestUnaVoceDiStrifeHaVentiquattroByteELaSuoneria;
    [Test]
    procedure TestLEpisodioHaIlSegno;
    [Test]
    procedure TestUnNomeFiniscePrimaDelloZero;
    [Test]
    procedure TestUnNomeDiNoveCaratteriSenzaZeroVieneTagliatoAOtto;
    [Test]
    procedure TestIlTerminatoreEUnaVoceComeLeAltre;
    [Test]
    procedure TestLaCodaPiuCortaDiUnaVoceEScartata;
    [Test]
    procedure TestIlNomeDelSuonoDelLumpEVuoto;
  end;

implementation

uses
  DelphiDoom.Definitions.Intf, DelphiDoom.Definitions.Factory;

{ TTestSwitchLumpReader }

function TTestSwitchLumpReader.Entry(const AName1, AName2: string; AEpisode: Integer;
  AWithSound: Boolean; ASound: Integer): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, 20);
  if AWithSound then
    SetLength(Result, 24);
  FillChar(Result[0], Length(Result), 0);
  for LIndex := 1 to Length(AName1) do
    if LIndex <= 9 then
      Result[LIndex - 1] := Ord(AName1[LIndex]);
  for LIndex := 1 to Length(AName2) do
    if LIndex <= 9 then
      Result[9 + LIndex - 1] := Ord(AName2[LIndex]);
  Result[18] := AEpisode and $FF;
  Result[19] := (AEpisode shr 8) and $FF;
  if AWithSound then
  begin
    Result[20] := ASound and $FF;
    Result[21] := (ASound shr 8) and $FF;
    Result[22] := (ASound shr 16) and $FF;
    Result[23] := (ASound shr 24) and $FF;
  end;
end;

function TTestSwitchLumpReader.Join(const AParts: array of TBytes): TBytes;
var
  LPart: TBytes;
begin
  Result := nil;
  for LPart in AParts do
    Result := Result + LPart;
end;

function TTestSwitchLumpReader.Read(const ABytes: TBytes; AWithSound: Boolean): TArray<TDefSwitchPair>;
begin
  Result := TDefinitionsFactory.CreateSwitchLumpReader(AWithSound).Read(ABytes);
end;

procedure TTestSwitchLumpReader.TestUnLumpVuotoNonHaVoci;
begin
  Assert.AreEqual<Integer>(0, Length(Read(nil, False)));
  Assert.AreEqual<Integer>(0, Length(Read(nil, True)));
end;

procedure TTestSwitchLumpReader.TestUnaVoceDiDoomHaVentiByte;
var
  LPairs: TArray<TDefSwitchPair>;
begin
  LPairs := Read(Entry('SW1BRCOM', 'SW2BRCOM', 1, False), False);
  Assert.AreEqual<Integer>(1, Length(LPairs));
  Assert.AreEqual('SW1BRCOM', LPairs[0].Name1);
  Assert.AreEqual('SW2BRCOM', LPairs[0].Name2);
  Assert.AreEqual(1, Integer(LPairs[0].Episode));
end;

procedure TTestSwitchLumpReader.TestLeVociSonoNellOrdineDelLump;
var
  LPairs: TArray<TDefSwitchPair>;
begin
  LPairs := Read(Join([Entry('A', 'B', 1, False), Entry('C', 'D', 2, False), Entry('E', 'F', 3, False)]), False);
  Assert.AreEqual<Integer>(3, Length(LPairs));
  Assert.AreEqual('C', LPairs[1].Name1);
  Assert.AreEqual('F', LPairs[2].Name2);
  Assert.AreEqual(3, Integer(LPairs[2].Episode));
end;

procedure TTestSwitchLumpReader.TestUnaVoceDiStrifeHaVentiquattroByteELaSuoneria;
var
  LPairs: TArray<TDefSwitchPair>;
begin
  LPairs := Read(Join([Entry('A', 'B', 1, True, 305419896), Entry('C', 'D', 2, True, -1)]), True);
  Assert.AreEqual<Integer>(2, Length(LPairs));
  Assert.AreEqual(305419896, LPairs[0].Sound);
  Assert.AreEqual(-1, LPairs[1].Sound);
  Assert.AreEqual('C', LPairs[1].Name1);
end;

procedure TTestSwitchLumpReader.TestLEpisodioHaIlSegno;
var
  LPairs: TArray<TDefSwitchPair>;
begin
  LPairs := Read(Join([Entry('A', 'B', -1, False), Entry('C', 'D', 32767, False), Entry('E', 'F', -32768, False)]), False);
  Assert.AreEqual(-1, Integer(LPairs[0].Episode));
  Assert.AreEqual(32767, Integer(LPairs[1].Episode));
  Assert.AreEqual(-32768, Integer(LPairs[2].Episode));
end;

procedure TTestSwitchLumpReader.TestUnNomeFiniscePrimaDelloZero;
var
  LBytes: TBytes;
begin
  LBytes := Entry('SW1', 'SW2', 1, False);
  LBytes[4] := Ord('X'); // dopo lo zero: non conta
  Assert.AreEqual('SW1', Read(LBytes, False)[0].Name1);
end;

procedure TTestSwitchLumpReader.TestUnNomeDiNoveCaratteriSenzaZeroVieneTagliatoAOtto;
begin
  Assert.AreEqual('ABCDEFGH', Read(Entry('ABCDEFGHI', 'X', 1, False), False)[0].Name1);
end;

procedure TTestSwitchLumpReader.TestIlTerminatoreEUnaVoceComeLeAltre;
var
  LPairs: TArray<TDefSwitchPair>;
begin
  LPairs := Read(Join([Entry('A', 'B', 1, False), Entry('', '', -1, False), Entry('C', 'D', 1, False)]), False);
  Assert.AreEqual<Integer>(3, Length(LPairs));
  Assert.AreEqual('', LPairs[1].Name1);
  Assert.AreEqual(-1, Integer(LPairs[1].Episode));
end;

procedure TTestSwitchLumpReader.TestLaCodaPiuCortaDiUnaVoceEScartata;
begin
  Assert.AreEqual<Integer>(1, Length(Read(Join([Entry('A', 'B', 1, False), BytesOf('abc')]), False)));
  Assert.AreEqual<Integer>(0, Length(Read(Entry('A', 'B', 1, False), True)), 'venti byte non bastano a Strife');
end;

procedure TTestSwitchLumpReader.TestIlNomeDelSuonoDelLumpEVuoto;
begin
  Assert.AreEqual('', Read(Entry('A', 'B', 1, True, 5), True)[0].SoundName);
end;

end.
