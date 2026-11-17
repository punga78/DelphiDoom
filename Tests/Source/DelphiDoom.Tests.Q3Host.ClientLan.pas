{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III host library - the server lists of the    }
{  menus (LAN_* of cl_ui.c), the network addresses (net_chan.c) and the CD key  }
{  (CLUI_GetCDKey, CL_CDKeyValidate), written on the C                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Q3Host.ClientLan;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Tests.Q3Host.ClientSupport;

type
  [TestFixture]
  [Category('Q3Host')]
  TTestQ3ClientLan = class
  strict private
    FRig: TQ3ClientRig;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure GliIndirizziDovrebberoEssereLettiEScrittiComeIlC;
    [Test]
    procedure UnIndirizzoCheNonSiRisolveDovrebbeEssereNaBad;
    [Test]
    procedure UnServerDovrebbeEssereAggiuntoUnaSolaVolta;
    [Test]
    procedure LeListeDovrebberoAvereILimitiDelC;
    [Test]
    procedure LeInformazioniDiUnServerDovrebberoAvereLeCoppieDelC;
    [Test]
    procedure UnoSlotNonUsatoDovrebbeDareLeRispostePredefinite;
    [Test]
    procedure RimuovereUnServerDovrebbeSpostareGliAltri;
    [Test]
    procedure IPingEIlVisibileDovrebberoSeguireLeRegoleDelC;
    [Test]
    procedure IlConfrontoDeiServerDovrebbeSeguireLaChiave;
    [Test]
    procedure LaCacheDeiServerDovrebbeAzzerareIConteggi;
    [Test]
    procedure LeChiamateDiUiSulleListeDovrebberoRiempireIBuffer;
    [Test]
    procedure LaCodaDeiPingEIlRegistroDelloStatoDovrebberoEssereVuoti;
    [Test]
    procedure LaChiaveDelCdDovrebbeEssereValidataComeIlC;
    [Test]
    procedure LaChiaveDelCdDovrebbeEssereSalvataSecondoIlModulo;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Qvm.Intf, DelphiDoom.Qvm.Factory, DelphiDoom.Q3Host.Types, DelphiDoom.Q3Host.Intf,
  DelphiDoom.Q3Host.Opcodes,
  DelphiDoom.Q3Host.Client.Types, DelphiDoom.Q3Host.UiNetAddress, DelphiDoom.Q3Host.UiLanServers,
  DelphiDoom.Q3Host.ClientCdKey, DelphiDoom.Tests.Q3Host.Services;

const
  BUFFER = 4096;
  NAME_ADDRESS = 8192;
  ADDRESS_ADDRESS = 8300;

procedure TTestQ3ClientLan.Setup;
begin
  FRig := TQ3ClientRig.Create;
end;

procedure TTestQ3ClientLan.TearDown;
begin
  FRig.Free;
end;

procedure TTestQ3ClientLan.GliIndirizziDovrebberoEssereLettiEScrittiComeIlC;
var
  LAddress: TQ3NetAddress;
begin
  Assert.IsTrue(TQ3NetAddresses.Parse('localhost', LAddress));
  Assert.AreEqual('loopback', string(TQ3NetAddresses.ToText(LAddress)));
  Assert.IsTrue(TQ3NetAddresses.Parse('192.168.1.5', LAddress));
  // no port: PORT_SERVER
  Assert.AreEqual('192.168.1.5:27960', string(TQ3NetAddresses.ToText(LAddress)));
  Assert.IsTrue(TQ3NetAddresses.Parse('10.0.0.1:27961', LAddress));
  Assert.AreEqual('10.0.0.1:27961', string(TQ3NetAddresses.ToText(LAddress)));
  // atoi of what is not a number is 0; the port is cast to a short
  Assert.IsTrue(TQ3NetAddresses.Parse('10.0.0.1:abc', LAddress));
  Assert.AreEqual('10.0.0.1:0', string(TQ3NetAddresses.ToText(LAddress)));
  Assert.IsTrue(TQ3NetAddresses.Parse('10.0.0.1:-1', LAddress));
  Assert.AreEqual('10.0.0.1:65535', string(TQ3NetAddresses.ToText(LAddress)));
  Assert.IsTrue(TQ3NetAddresses.Parse('10.0.0.1:70000', LAddress));
  Assert.AreEqual('10.0.0.1:4464', string(TQ3NetAddresses.ToText(LAddress)));
end;

procedure TTestQ3ClientLan.UnIndirizzoCheNonSiRisolveDovrebbeEssereNaBad;
var
  LAddress: TQ3NetAddress;
  LText: string;
begin
  for LText in ['', 'example.com', '1.2.3', '1.2.3.4.5', '300.1.1.1', '255.255.255.255', '1..2.3', '1.2.3.4a'] do
  begin
    Assert.IsFalse(TQ3NetAddresses.Parse(AnsiString(LText), LAddress), LText);
    Assert.IsTrue(LAddress.AddressType = NaBad, LText);
  end;
  // a bad address is never the same as another one, not even itself
  Assert.IsFalse(TQ3NetAddresses.Same(LAddress, LAddress));
  Assert.AreEqual('00000000.00000000000000000000:0', string(TQ3NetAddresses.ToText(LAddress)));
end;

procedure TTestQ3ClientLan.UnServerDovrebbeEssereAggiuntoUnaSolaVolta;
begin
  Assert.AreEqual(1, FRig.Lan.AddServer(Q3_AS_FAVORITES, 'one', '1.2.3.4:27960'));
  Assert.AreEqual(0, FRig.Lan.AddServer(Q3_AS_FAVORITES, 'other name', '1.2.3.4'));
  Assert.AreEqual(1, FRig.Lan.AddServer(Q3_AS_FAVORITES, 'two', '1.2.3.4:27961'));
  Assert.AreEqual(2, FRig.Lan.GetServerCount(Q3_AS_FAVORITES));
  // the same address in another list is another server
  Assert.AreEqual(1, FRig.Lan.AddServer(Q3_AS_LOCAL, 'one', '1.2.3.4'));
  Assert.AreEqual(-1, FRig.Lan.AddServer(7, 'x', '1.2.3.4'));
  Assert.AreEqual(0, FRig.Lan.GetServerCount(7));
  Assert.AreEqual(0, FRig.Lan.GetServerCount(Q3_AS_GLOBAL));
  Assert.AreEqual('one', string(FRig.Lan.GetServer(Q3_AS_FAVORITES, 0).HostName));
  Assert.IsTrue(FRig.Lan.GetServer(Q3_AS_FAVORITES, 0).Visible);
  // an address that does not resolve is added every time (NA_BAD is never equal to anything)
  Assert.AreEqual(1, FRig.Lan.AddServer(Q3_AS_MPLAYER, 'bad', 'no.such.host'));
  Assert.AreEqual(1, FRig.Lan.AddServer(Q3_AS_MPLAYER, 'bad', 'no.such.host'));
  Assert.AreEqual(2, FRig.Lan.GetServerCount(Q3_AS_MPLAYER));
end;

procedure TTestQ3ClientLan.LeListeDovrebberoAvereILimitiDelC;
var
  LIndex: Integer;
begin
  for LIndex := 0 to Q3_MAX_OTHER_SERVERS - 1 do
    Assert.AreEqual(1, FRig.Lan.AddServer(Q3_AS_LOCAL, 'local', AnsiString('10.0.0.' + IntToStr(LIndex))));
  Assert.AreEqual(-1, FRig.Lan.AddServer(Q3_AS_LOCAL, 'one more', '10.1.0.1'));
  // the global list holds 4096
  for LIndex := 0 to 299 do
    Assert.AreEqual(1, FRig.Lan.AddServer(Q3_AS_GLOBAL, 'global', AnsiString('10.2.' + IntToStr(LIndex div 200) + '.' +
      IntToStr(LIndex mod 200))));
  Assert.AreEqual(300, FRig.Lan.GetServerCount(Q3_AS_GLOBAL));
end;

procedure TTestQ3ClientLan.LeInformazioniDiUnServerDovrebberoAvereLeCoppieDelC;
var
  LServer: TQ3LanServer;
begin
  Assert.AreEqual(1, FRig.Lan.AddServer(Q3_AS_GLOBAL, 'My Server', '1.2.3.4'));
  LServer := FRig.Lan.GetServer(Q3_AS_GLOBAL, 0);
  LServer.MapName := 'oa_dm1';
  LServer.Clients := 3;
  LServer.MaxClients := 8;
  LServer.Ping := 25;
  FRig.Lan.SetServer(Q3_AS_GLOBAL, 0, LServer);
  // Info_SetValueForKey puts every new pair first: the last one set (punkbuster) is the first of the string, and the
  // game, which is empty, is not there at all
  Assert.AreEqual('\punkbuster\0\addr\1.2.3.4:27960\nettype\0\gametype\0\maxping\0\minping\0\ping\25' +
    '\sv_maxclients\8\clients\3\mapname\oa_dm1\hostname\My Server', string(FRig.Lan.GetServerInfo(Q3_AS_GLOBAL, 0)));
  Assert.AreEqual('1.2.3.4:27960', string(FRig.Lan.GetServerAddressString(Q3_AS_GLOBAL, 0)));
  Assert.AreEqual(25, FRig.Lan.GetServerPing(Q3_AS_GLOBAL, 0));
end;

procedure TTestQ3ClientLan.UnoSlotNonUsatoDovrebbeDareLeRispostePredefinite;
begin
  // the C checks the index against the size of the list, not against the servers counted: the slot is all zeros, whose
  // address type is NA_BOT
  Assert.AreEqual('bot', string(FRig.Lan.GetServerAddressString(Q3_AS_LOCAL, 5)));
  Assert.AreEqual(0, FRig.Lan.GetServerPing(Q3_AS_LOCAL, 5));
  Assert.IsFalse(FRig.Lan.ServerIsVisible(Q3_AS_LOCAL, 5));
  // outside the list, or a source that does not exist
  Assert.AreEqual('', string(FRig.Lan.GetServerAddressString(Q3_AS_LOCAL, Q3_MAX_OTHER_SERVERS)));
  Assert.AreEqual('', string(FRig.Lan.GetServerAddressString(Q3_AS_LOCAL, -1)));
  Assert.AreEqual('', string(FRig.Lan.GetServerInfo(9, 0)));
  Assert.AreEqual(-1, FRig.Lan.GetServerPing(Q3_AS_LOCAL, 200));
  Assert.IsFalse(FRig.Lan.ServerIsVisible(9, 0));
end;

procedure TTestQ3ClientLan.RimuovereUnServerDovrebbeSpostareGliAltri;
begin
  FRig.Lan.AddServer(Q3_AS_FAVORITES, 'a', '1.1.1.1');
  FRig.Lan.AddServer(Q3_AS_FAVORITES, 'b', '2.2.2.2');
  FRig.Lan.AddServer(Q3_AS_FAVORITES, 'c', '3.3.3.3');
  FRig.Lan.RemoveServer(Q3_AS_FAVORITES, '2.2.2.2');
  Assert.AreEqual(2, FRig.Lan.GetServerCount(Q3_AS_FAVORITES));
  Assert.AreEqual('c', string(FRig.Lan.GetServer(Q3_AS_FAVORITES, 1).HostName));
  // an address that is not there, and a list that does not exist, change nothing
  FRig.Lan.RemoveServer(Q3_AS_FAVORITES, '9.9.9.9');
  FRig.Lan.RemoveServer(9, '1.1.1.1');
  Assert.AreEqual(2, FRig.Lan.GetServerCount(Q3_AS_FAVORITES));
end;

procedure TTestQ3ClientLan.IPingEIlVisibileDovrebberoSeguireLeRegoleDelC;
begin
  FRig.Lan.AddServer(Q3_AS_LOCAL, 'a', '1.1.1.1');
  FRig.Lan.ResetPings(Q3_AS_LOCAL);
  Assert.AreEqual(-1, FRig.Lan.GetServer(Q3_AS_LOCAL, 0).Ping);
  Assert.AreEqual(-1, FRig.Lan.GetServer(Q3_AS_LOCAL, 127).Ping);
  FRig.Lan.MarkServerVisible(Q3_AS_LOCAL, 0, False);
  Assert.IsFalse(FRig.Lan.ServerIsVisible(Q3_AS_LOCAL, 0));
  // -1 is every slot of the list, the ones in use or not
  FRig.Lan.MarkServerVisible(Q3_AS_LOCAL, -1, True);
  Assert.IsTrue(FRig.Lan.ServerIsVisible(Q3_AS_LOCAL, 0));
  Assert.IsTrue(FRig.Lan.ServerIsVisible(Q3_AS_LOCAL, 100));
  // no network: nothing is pinged
  Assert.IsFalse(FRig.Lan.UpdateVisiblePings(Q3_AS_LOCAL));
end;

procedure TTestQ3ClientLan.IlConfrontoDeiServerDovrebbeSeguireLaChiave;
var
  LServer: TQ3LanServer;
begin
  FRig.Lan.AddServer(Q3_AS_LOCAL, 'Beta', '1.1.1.1');
  FRig.Lan.AddServer(Q3_AS_LOCAL, 'alpha', '2.2.2.2');
  LServer := FRig.Lan.GetServer(Q3_AS_LOCAL, 0);
  LServer.MapName := 'q3dm1';
  LServer.Clients := 5;
  LServer.GameType := 3;
  LServer.Ping := 80;
  FRig.Lan.SetServer(Q3_AS_LOCAL, 0, LServer);
  LServer := FRig.Lan.GetServer(Q3_AS_LOCAL, 1);
  LServer.MapName := 'Q3DM0';
  LServer.Clients := 5;
  LServer.GameType := 1;
  LServer.Ping := 20;
  FRig.Lan.SetServer(Q3_AS_LOCAL, 1, LServer);
  // the names ignore case: Beta after alpha
  Assert.AreEqual(1, FRig.Lan.CompareServers(Q3_AS_LOCAL, Q3_SORT_HOST, 0, 0, 1));
  Assert.AreEqual(-1, FRig.Lan.CompareServers(Q3_AS_LOCAL, Q3_SORT_HOST, 1, 0, 1));
  Assert.AreEqual(1, FRig.Lan.CompareServers(Q3_AS_LOCAL, Q3_SORT_MAP, 0, 0, 1));
  Assert.AreEqual(0, FRig.Lan.CompareServers(Q3_AS_LOCAL, Q3_SORT_CLIENTS, 0, 0, 1));
  Assert.AreEqual(0, FRig.Lan.CompareServers(Q3_AS_LOCAL, Q3_SORT_CLIENTS, 1, 0, 1));
  Assert.AreEqual(1, FRig.Lan.CompareServers(Q3_AS_LOCAL, Q3_SORT_GAME, 0, 0, 1));
  Assert.AreEqual(1, FRig.Lan.CompareServers(Q3_AS_LOCAL, Q3_SORT_PING, 0, 0, 1));
  Assert.AreEqual(-1, FRig.Lan.CompareServers(Q3_AS_LOCAL, Q3_SORT_PING, 1, 0, 1));
  Assert.AreEqual(-1, FRig.Lan.CompareServers(Q3_AS_LOCAL, Q3_SORT_PING, 0, 1, 0));
  // an unknown key is a draw, a server out of the list too
  Assert.AreEqual(0, FRig.Lan.CompareServers(Q3_AS_LOCAL, 5, 0, 0, 1));
  Assert.AreEqual(0, FRig.Lan.CompareServers(Q3_AS_LOCAL, Q3_SORT_PING, 0, 0, 500));
  Assert.AreEqual(0, FRig.Lan.CompareServers(9, Q3_SORT_PING, 0, 0, 1));
end;

procedure TTestQ3ClientLan.LaCacheDeiServerDovrebbeAzzerareIConteggi;
begin
  FRig.Lan.AddServer(Q3_AS_LOCAL, 'l', '1.1.1.1');
  FRig.Lan.AddServer(Q3_AS_GLOBAL, 'g', '1.1.1.1');
  FRig.Lan.AddServer(Q3_AS_MPLAYER, 'm', '1.1.1.1');
  FRig.Lan.AddServer(Q3_AS_FAVORITES, 'f', '1.1.1.1');
  FRig.Lan.LoadCachedServers;
  Assert.AreEqual(1, FRig.Lan.GetServerCount(Q3_AS_LOCAL));
  Assert.AreEqual(0, FRig.Lan.GetServerCount(Q3_AS_GLOBAL));
  Assert.AreEqual(0, FRig.Lan.GetServerCount(Q3_AS_MPLAYER));
  Assert.AreEqual(0, FRig.Lan.GetServerCount(Q3_AS_FAVORITES));
end;

procedure TTestQ3ClientLan.LeChiamateDiUiSulleListeDovrebberoRiempireIBuffer;
var
  LMemory: IQvmMemory;
begin
  LMemory := FRig.Memory(TQ3Module.Ui);
  LMemory.WriteString(NAME_ADDRESS, 'Arena', 6);
  LMemory.WriteString(ADDRESS_ADDRESS, '4.3.2.1:1234', 13);
  Assert.AreEqual(1, FRig.Call(TQ3Module.Ui, [UI_LAN_ADDSERVER, Q3_AS_GLOBAL, NAME_ADDRESS, ADDRESS_ADDRESS]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_LAN_ADDSERVER, Q3_AS_GLOBAL, NAME_ADDRESS, ADDRESS_ADDRESS]));
  Assert.AreEqual(1, FRig.Call(TQ3Module.Ui, [UI_LAN_GETSERVERCOUNT, Q3_AS_GLOBAL]));
  LMemory.Fill(BUFFER, $77, 64);
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_LAN_GETSERVERADDRESSSTRING, Q3_AS_GLOBAL, 0, BUFFER, 64]));
  Assert.AreEqual('4.3.2.1:1234', string(LMemory.ReadString(BUFFER)));
  // an index outside the list only puts a zero in the first byte
  LMemory.Fill(BUFFER, $77, 64);
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_LAN_GETSERVERADDRESSSTRING, Q3_AS_GLOBAL, -1, BUFFER, 64]));
  Assert.AreEqual(0, Integer(LMemory.ReadByte(BUFFER)));
  Assert.AreEqual($77, Integer(LMemory.ReadByte(BUFFER + 1)));
  LMemory.Fill(BUFFER, $77, 1024);
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_LAN_GETSERVERINFO, Q3_AS_GLOBAL, 0, BUFFER, 1024]));
  Assert.IsTrue(Pos('\hostname\Arena', string(LMemory.ReadString(BUFFER))) > 0);
  Assert.AreEqual(1, FRig.Call(TQ3Module.Ui, [UI_LAN_SERVERISVISIBLE, Q3_AS_GLOBAL, 0]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_LAN_MARKSERVERVISIBLE, Q3_AS_GLOBAL, 0, 0]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_LAN_SERVERISVISIBLE, Q3_AS_GLOBAL, 0]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_LAN_RESETPINGS, Q3_AS_GLOBAL]));
  Assert.AreEqual(-1, FRig.Call(TQ3Module.Ui, [UI_LAN_GETSERVERPING, Q3_AS_GLOBAL, 0]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_LAN_COMPARESERVERS, Q3_AS_GLOBAL, Q3_SORT_PING, 0, 0, 0]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_LAN_REMOVESERVER, Q3_AS_GLOBAL, ADDRESS_ADDRESS]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_LAN_GETSERVERCOUNT, Q3_AS_GLOBAL]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_LAN_LOADCACHEDSERVERS]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_LAN_SAVECACHEDSERVERS]));
end;

procedure TTestQ3ClientLan.LaCodaDeiPingEIlRegistroDelloStatoDovrebberoEssereVuoti;
var
  LMemory: IQvmMemory;
begin
  LMemory := FRig.Memory(TQ3Module.Ui);
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_LAN_GETPINGQUEUECOUNT]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_LAN_CLEARPING, 3]));
  LMemory.Fill(BUFFER, $77, 32);
  LMemory.WriteInt32(BUFFER + 100, 99);
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_LAN_GETPING, 0, BUFFER, 32, BUFFER + 100]));
  Assert.AreEqual(0, Integer(LMemory.ReadByte(BUFFER)));
  Assert.AreEqual(0, LMemory.ReadInt32(BUFFER + 100));
  LMemory.Fill(BUFFER, $77, 32);
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_LAN_GETPINGINFO, 0, BUFFER, 32]));
  Assert.AreEqual(0, Integer(LMemory.ReadByte(BUFFER)));
  // a buffer of length 0 is left alone
  LMemory.Fill(BUFFER, $77, 32);
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_LAN_GETPINGINFO, 0, BUFFER, 0]));
  Assert.AreEqual($77, Integer(LMemory.ReadByte(BUFFER)));
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_LAN_UPDATEVISIBLEPINGS, Q3_AS_LOCAL]));
  // no address: the requests are reset, nothing answers
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_LAN_SERVERSTATUS, 0, 0, 0]));
  LMemory.WriteString(ADDRESS_ADDRESS, '1.2.3.4', 8);
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_LAN_SERVERSTATUS, ADDRESS_ADDRESS, BUFFER, 64]));
end;

procedure TTestQ3ClientLan.LaChiaveDelCdDovrebbeEssereValidataComeIlC;
begin
  // sixteen "A" add up to 0x410: the byte is 0x10
  Assert.IsTrue(TQ3ClientCdKey.Validate('AAAAAAAAAAAAAAAA', True, '10'));
  Assert.IsFalse(TQ3ClientCdKey.Validate('AAAAAAAAAAAAAAAA', True, '11'));
  Assert.IsTrue(TQ3ClientCdKey.Validate('aaaaaaaaaaaaaaaa', True, '10'));
  // 1131 = 0x46B: the checksum ignores the case of its letters
  Assert.IsTrue(TQ3ClientCdKey.Validate('ABCDGHJLPRSTW237', True, '6b'));
  Assert.IsTrue(TQ3ClientCdKey.Validate('ABCDGHJLPRSTW237', True, '6B'));
  // no checksum: any valid key
  Assert.IsTrue(TQ3ClientCdKey.Validate('ABCDGHJLPRSTW237', False, ''));
  // a character that is not in the list, a wrong length, a checksum of the wrong length
  Assert.IsFalse(TQ3ClientCdKey.Validate('AAAAAAAAAAAAAAA1', False, ''));
  Assert.IsFalse(TQ3ClientCdKey.Validate('AAAAAAAAAAAAAAA', False, ''));
  Assert.IsFalse(TQ3ClientCdKey.Validate('AAAAAAAAAAAAAAAAA', False, ''));
  Assert.IsFalse(TQ3ClientCdKey.Validate('AAAAAAAAAAAAAAAA', True, '100'));
  Assert.IsFalse(TQ3ClientCdKey.Validate('AAAAAAAAAAAAAAAA', True, '1'));
  // UI_VERIFY_CDKEY: the key and the checksum, or a NULL checksum
  FRig.Memory(TQ3Module.Ui).WriteString(NAME_ADDRESS, 'AAAAAAAAAAAAAAAA', 17);
  FRig.Memory(TQ3Module.Ui).WriteString(ADDRESS_ADDRESS, '10', 3);
  Assert.AreEqual(1, FRig.Call(TQ3Module.Ui, [UI_VERIFY_CDKEY, NAME_ADDRESS, ADDRESS_ADDRESS]));
  Assert.AreEqual(1, FRig.Call(TQ3Module.Ui, [UI_VERIFY_CDKEY, NAME_ADDRESS, 0]));
  FRig.Memory(TQ3Module.Ui).WriteString(ADDRESS_ADDRESS, '11', 3);
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_VERIFY_CDKEY, NAME_ADDRESS, ADDRESS_ADDRESS]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_SET_PBCLSTATUS, 1]));
end;

procedure TTestQ3ClientLan.LaChiaveDelCdDovrebbeEssereSalvataSecondoIlModulo;
var
  LHost: IQ3SyscallHost;
  LPlain, LUnique: IQvmMachine;
  LBytes: TBytes;
begin
  // the key at the start is sixteen blanks (no q3key file)
  LHost := FRig.Host(TQ3Module.Ui);
  LPlain := TQvmFactory.CreateMachine('plain', TQ3ClientPrograms.Constant(0), LHost);
  LUnique := TQvmFactory.CreateMachine('unique', TQ3ClientPrograms.Constant(1), LHost);
  LPlain.Memory.Fill(BUFFER, $77, 32);
  Assert.AreEqual(0, TQ3TestCalls.Invoke(LHost, LPlain, [UI_GET_CDKEY, BUFFER, 17]));
  Assert.AreEqual('                ', string(LPlain.Memory.ReadString(BUFFER)));
  Assert.AreEqual($77, Integer(LPlain.Memory.ReadByte(BUFFER + 17)));

  // set with a module that has no unique key: the first key
  LPlain.Memory.WriteString(BUFFER, '1234567890ABCDEF', 17);
  FRig.Console.CVars.ModifiedFlags := 0;
  Assert.AreEqual(0, TQ3TestCalls.Invoke(LHost, LPlain, [UI_SET_CDKEY, BUFFER]));
  Assert.AreEqual(1, FRig.Console.CVars.ModifiedFlags and 1);
  LBytes := FRig.CdKey.Get(False);
  Assert.AreEqual('1234567890ABCDEF', string(AnsiString(PAnsiChar(@LBytes[0]))));

  // a module with a unique key and a mod (fs_game) uses the second one, which starts empty
  FRig.Console.CVars.SetValueText('fs_game', 'mymod');
  LUnique.Memory.Fill(BUFFER, $77, 32);
  Assert.AreEqual(0, TQ3TestCalls.Invoke(LHost, LUnique, [UI_GET_CDKEY, BUFFER, 17]));
  Assert.AreEqual('', string(LUnique.Memory.ReadString(BUFFER)));
  LUnique.Memory.WriteString(BUFFER, 'FEDCBA0987654321', 17);
  Assert.AreEqual(0, TQ3TestCalls.Invoke(LHost, LUnique, [UI_SET_CDKEY, BUFFER]));
  Assert.AreEqual(0, TQ3TestCalls.Invoke(LHost, LUnique, [UI_GET_CDKEY, BUFFER + 100, 17]));
  Assert.AreEqual('FEDCBA0987654321', string(LUnique.Memory.ReadString(BUFFER + 100)));
  // the first key did not change
  LBytes := FRig.CdKey.Get(False);
  Assert.AreEqual('1234567890ABCDEF', string(AnsiString(PAnsiChar(@LBytes[0]))));
end;

end.
