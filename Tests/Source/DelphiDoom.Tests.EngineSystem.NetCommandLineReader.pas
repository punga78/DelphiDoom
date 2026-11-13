{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the engine system library - the network options        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.EngineSystem.NetCommandLineReader;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.CommandLine.Intf, DelphiDoom.Logging.Intf,
  DelphiDoom.EngineSystem.Types, DelphiDoom.EngineSystem.Intf,
  DelphiDoom.Tests.EngineSystem.Fakes;

type
  [TestFixture]
  [Category('enginesystem')]
  TTestNetCommandLineReader = class(TObject)
  private
    FLog: TRecordingLog;
    FLogRef: ILog;
    function Reader(const AArguments: array of string): INetCommandLineReader;
    function Options(const AArguments: array of string; APort: Integer = 5029): TNetCommandLineOptions;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeRifiutareParametriNulli;
    [Test]
    procedure DovrebbeDareUnGiocoASingoloSenzaOpzioni;
    [Test]
    procedure DovrebbeLeggereIlDup;
    [Test]
    procedure DovrebbeLimitareIlDupTraUnoENove;
    [Test]
    procedure DovrebbeIgnorareIlDupSenzaValore;
    [Test]
    procedure DovrebbeLeggereLExtratic;
    [Test]
    procedure DovrebbeLeggereLaPortaEScriverla;
    [Test]
    procedure DovrebbeLeggereLaPortaInEsadecimale;
    [Test]
    procedure DovrebbeTenereLaPortaPrecedenteSenzaOpzione;
    [Test]
    procedure DovrebbeScegliereIlDrone;
    [Test]
    procedure DovrebbeDareLaPrecedenzaASinistra;
    [Test]
    procedure DovrebbeLeggereLaRete;
    [Test]
    procedure DovrebbeDireSeUnNodoELetterale;
    [Test]
    procedure DovrebbeLeggereLaRetePrivaDiGiocatore;
    [Test]
    procedure DovrebbeFarLeStesseDomandeDelVecchioCodice;
    [Test]
    procedure DovrebbeDareLoStessoRisultatoDelVecchioCodice;
  end;

implementation

uses
  DelphiDoom.CommandLine.Factory, DelphiDoom.Net.Types,
  DelphiDoom.EngineSystem.Factory, DelphiDoom.EngineSystem.NetCommandLineReader,
  DelphiDoom.Tests.EngineSystem.Legacy;

{ TTestNetCommandLineReader }

procedure TTestNetCommandLineReader.Setup;
begin
  FLog := TRecordingLog.Create;
  FLogRef := FLog;
end;

procedure TTestNetCommandLineReader.TearDown;
begin
  FLogRef := nil;
  FLog := nil;
end;

function TTestNetCommandLineReader.Reader(const AArguments: array of string): INetCommandLineReader;
var
  LItems: TArray<string>;
  LIndex: Integer;
begin
  SetLength(LItems, Length(AArguments));
  for LIndex := 0 to High(AArguments) do
    LItems[LIndex] := AArguments[LIndex];
  Result := TEngineSystemFactory.CreateNetCommandLineReader(
    TCommandLineFactory.CreateCommandLine(LItems), FLogRef);
end;

function TTestNetCommandLineReader.Options(const AArguments: array of string;
  APort: Integer): TNetCommandLineOptions;
begin
  Result := Reader(AArguments).Read(APort);
end;

procedure TTestNetCommandLineReader.DovrebbeRifiutareParametriNulli;
begin
  Assert.WillRaise(
    procedure
    begin
      TNetCommandLineReader.Create(nil, FLogRef);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TNetCommandLineReader.Create(TCommandLineFactory.CreateCommandLine(nil), nil);
    end, EArgumentNilException);
end;

procedure TTestNetCommandLineReader.DovrebbeDareUnGiocoASingoloSenzaOpzioni;
var
  LOptions: TNetCommandLineOptions;
begin
  LOptions := Options(['DOOM32.EXE']);
  Assert.IsFalse(LOptions.IsNetGame);
  Assert.AreEqual(1, LOptions.TicDup);
  Assert.AreEqual(0, LOptions.ExtraTics);
  Assert.AreEqual(5029, LOptions.Port);
  Assert.AreEqual(1, LOptions.NumNodes);
  Assert.AreEqual(0, LOptions.ConsolePlayer);
  Assert.AreEqual(0, Length(LOptions.Peers));
  Assert.IsTrue(LOptions.Drone = ndvNone);
  Assert.AreEqual('', FLog.InfoText);
end;

procedure TTestNetCommandLineReader.DovrebbeLeggereIlDup;
begin
  Assert.AreEqual(3, Options(['D', '-dup', '3']).TicDup);
end;

procedure TTestNetCommandLineReader.DovrebbeLimitareIlDupTraUnoENove;
begin
  Assert.AreEqual(1, Options(['D', '-dup', '0']).TicDup);
  Assert.AreEqual(1, Options(['D', '-dup', '/']).TicDup);
  Assert.AreEqual(9, Options(['D', '-dup', 'A']).TicDup);
  Assert.AreEqual(9, Options(['D', '-dup', '9']).TicDup);
end;

procedure TTestNetCommandLineReader.DovrebbeIgnorareIlDupSenzaValore;
begin
  // the last argument has nothing after it; an empty argument is the terminator of the string
  Assert.AreEqual(1, Options(['D', '-dup']).TicDup);
  Assert.AreEqual(1, Options(['D', '-dup', '']).TicDup);
end;

procedure TTestNetCommandLineReader.DovrebbeLeggereLExtratic;
begin
  Assert.AreEqual(1, Options(['D', '-extratic']).ExtraTics);
end;

procedure TTestNetCommandLineReader.DovrebbeLeggereLaPortaEScriverla;
begin
  Assert.AreEqual(6000, Options(['D', '-port', '6000']).Port);
  Assert.AreEqual('Using Port 6000'#13#10, FLog.InfoText);
end;

procedure TTestNetCommandLineReader.DovrebbeLeggereLaPortaInEsadecimale;
begin
  Assert.AreEqual(4096, Options(['D', '-port', '0x1000']).Port);
  Assert.AreEqual(77, Options(['D', '-port', '#77']).Port);
  // what is not a number is 0, as the atoi of the old code
  Assert.AreEqual(0, Options(['D', '-port', 'XYZ']).Port);
end;

procedure TTestNetCommandLineReader.DovrebbeTenereLaPortaPrecedenteSenzaOpzione;
begin
  Assert.AreEqual(7777, Options(['D'], 7777).Port);
  Assert.AreEqual(7777, Options(['D', '-port'], 7777).Port);
end;

procedure TTestNetCommandLineReader.DovrebbeScegliereIlDrone;
begin
  Assert.IsTrue(Options(['D', '-left']).Drone = ndvLeft);
  Assert.IsTrue(Options(['D', '-right']).Drone = ndvRight);
  Assert.IsTrue(Options(['D', '-back']).Drone = ndvBack);
end;

procedure TTestNetCommandLineReader.DovrebbeDareLaPrecedenzaASinistra;
begin
  Assert.IsTrue(Options(['D', '-back', '-right', '-left']).Drone = ndvLeft);
  Assert.IsTrue(Options(['D', '-back', '-right']).Drone = ndvRight);
end;

procedure TTestNetCommandLineReader.DovrebbeLeggereLaRete;
var
  LOptions: TNetCommandLineOptions;
begin
  LOptions := Options(['D', '-net', '2', 'ALPHA', 'BETA', ':6001']);
  Assert.IsTrue(LOptions.IsNetGame);
  Assert.AreEqual(1, LOptions.ConsolePlayer);
  Assert.AreEqual(3, LOptions.NumNodes);
  Assert.AreEqual(2, Length(LOptions.Peers));
  Assert.AreEqual('ALPHA', LOptions.Peers[0].Host);
  Assert.AreEqual(5029, Integer(LOptions.Peers[0].Port));
  Assert.AreEqual(6001, Integer(LOptions.Peers[1].Port));
  Assert.AreEqual('console player number: 1'#13#10 +
    'Node number 1 hostname ALPHA'#13#10 +
    'Node number 2 hostname BETA'#13#10 +
    'Total number of players : 3'#13#10, FLog.InfoText);
end;

procedure TTestNetCommandLineReader.DovrebbeDireSeUnNodoELetterale;
begin
  Options(['D', '-net', '1', '.1.2.3.4']);
  Assert.IsTrue(Pos('Node number 1 address', FLog.InfoText) > 0);
end;

procedure TTestNetCommandLineReader.DovrebbeLeggereLaRetePrivaDiGiocatore;
var
  LOptions: TNetCommandLineOptions;
begin
  // -net is the last argument: the player number is the terminator of an empty string
  LOptions := Options(['D', '-net']);
  Assert.IsTrue(LOptions.IsNetGame);
  Assert.AreEqual(-49, LOptions.ConsolePlayer);
  Assert.AreEqual(1, LOptions.NumNodes);
end;

procedure TTestNetCommandLineReader.DovrebbeFarLeStesseDomandeDelVecchioCodice;
var
  LQueried: IQueriedCommandLine;
  LLegacy: TLegacyNet;
  LAsked: TStringList;
  LName: string;
begin
  LQueried := TCommandLineFactory.CreateQueriedCommandLine;
  LQueried.Attach(TCommandLineFactory.CreateCommandLine(TArray<string>.Create('D', '-left', '-net', '1')));
  TEngineSystemFactory.CreateNetCommandLineReader(LQueried, FLogRef).Read(5029);
  LLegacy := TLegacyNet.Create(['D', '-left', '-net', '1']);
  LAsked := TStringList.Create;
  try
    LLegacy.I_InitNetwork;
    LAsked.Sorted := True;
    LAsked.Duplicates := dupIgnore;
    for LName in LLegacy.Asked do
      LAsked.Add(UpperCase(LName));
    Assert.AreEqual(LAsked.Count, Length(LQueried.QueriedNames));
    for LName in LQueried.QueriedNames do
      Assert.IsTrue(LAsked.IndexOf(UpperCase(LName)) >= 0, LName);
  finally
    LAsked.Free;
    LLegacy.Free;
  end;
end;

procedure TTestNetCommandLineReader.DovrebbeDareLoStessoRisultatoDelVecchioCodice;
const
  WORDS: array[0..21] of string = ('-dup', '-extratic', '-port', '-left', '-right', '-back', '-net',
    '1', '2', '3', '9', '0x10', '#7', 'ABC', '.1.2.3.4', 'HOST', 'HOST:5001', '-X', '', '5', 'Q', '77');
var
  LCase: Integer;
  LCount: Integer;
  LIndex: Integer;
  LArguments: TArray<string>;
  LLegacy: TLegacyNet;
  LOptions: TNetCommandLineOptions;
  LLegacyLog: TRecordingLog;
  LLegacyLogRef: ILog;
  LPeer: Integer;
  LPort: Integer;
begin
  RandSeed := 185;
  for LCase := 1 to 3000 do
  begin
    LCount := 1 + Random(9);
    SetLength(LArguments, LCount);
    LArguments[0] := 'DOOM32.EXE';
    for LIndex := 1 to LCount - 1 do
      LArguments[LIndex] := WORDS[Random(Length(WORDS))];
    LPort := 5000 + Random(100);

    LLegacy := TLegacyNet.Create(LArguments);
    LLegacyLog := TRecordingLog.Create;
    LLegacyLogRef := LLegacyLog;
    try
      LLegacy.net_port := LPort;
      LLegacy.I_InitNetwork;
      LOptions := TNetCommandLineReader.Create(TCommandLineFactory.CreateCommandLine(LArguments),
        LLegacyLogRef).Read(LPort);

      Assert.AreEqual(LLegacy.net_ticdup, LOptions.TicDup, 'dup');
      Assert.AreEqual(LLegacy.net_extratics, LOptions.ExtraTics, 'extratic');
      Assert.AreEqual(LLegacy.net_port, LOptions.Port, 'port');
      Assert.IsTrue(LLegacy.drone = LOptions.Drone, 'drone');
      Assert.AreEqual(LLegacy.netgame, LOptions.IsNetGame, 'netgame');
      Assert.AreEqual(LLegacy.net_consoleplayer, LOptions.ConsolePlayer, 'consoleplayer');
      Assert.AreEqual(LLegacy.net_numnodes, LOptions.NumNodes, 'numnodes');
      Assert.AreEqual(Length(LLegacy.net_peers), Length(LOptions.Peers), 'peers');
      for LPeer := 0 to High(LOptions.Peers) do
      begin
        Assert.AreEqual(LLegacy.net_peers[LPeer].Host, LOptions.Peers[LPeer].Host);
        Assert.AreEqual(Integer(LLegacy.net_peers[LPeer].Port), Integer(LOptions.Peers[LPeer].Port));
        Assert.AreEqual(LLegacy.net_peers[LPeer].IsLiteral, LOptions.Peers[LPeer].IsLiteral);
      end;
      Assert.AreEqual(LLegacy.Output, LLegacyLog.InfoText, 'output');
    finally
      LLegacy.Free;
      LLegacyLogRef := nil;
    end;
  end;
end;

end.
