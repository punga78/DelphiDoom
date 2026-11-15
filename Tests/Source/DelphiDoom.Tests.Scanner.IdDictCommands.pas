{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the scanner library - TIdDictCommands and the memory   }
{  report of TIdDictLister                                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Scanner.IdDictCommands;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.IdLib.Core.Intf,
  DelphiDoom.Scanner.IdDict, DelphiDoom.Scanner.IdDictCommands,
  DelphiDoom.Scanner.IdDictCommands.Intf, DelphiDoom.Scanner.IdDictLister,
  DelphiDoom.Tests.Scanner.IdFakes;

type
  TFakeCommandHost = class(TInterfacedObject, IIdCommandHost)
  public
    Names: TStringList;
    Descriptions: TStringList;
    Flags: TList;
    Handlers: array of TIdCommandHandler;
    constructor Create;
    destructor Destroy; override;
    procedure AddCommand(const AName, ADescription: string; const AFlags: Integer;
      const AHandler: TIdCommandHandler);
    procedure RemoveCommand(const AName: string);
  end;

  [TestFixture]
  [Category('IdDict')]
  TTestIdDictCommands = class
  strict private
    FLog: TFakeIdLibLog;
    FLogIntf: IIdLibLog;
    FLister: TIdDictLister;
    FDict: TIdDict;
    FHost: TFakeCommandHost;
    FHostIntf: IIdCommandHost;
    FCommands: TIdDictCommands;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeRegistrareITreComandiConFlagEDescrizioneDelCpp;
    [Test]
    procedure ILComandiDovrebberoElencareChiaviEValoriDelFornitore;
    [Test]
    procedure ShowDictMemoryDovrebbeStampareDueRighe;
    [Test]
    procedure UnregisterDovrebbeTogliereITreComandi;
    [Test]
    procedure DovrebbeRifiutareArgomentiNulli;
    [Test]
    procedure ShowMemoryUsageDovrebbeEssereMutoSenzaLog;
  end;

implementation

constructor TFakeCommandHost.Create;
begin
  inherited Create;
  Names := TStringList.Create;
  Descriptions := TStringList.Create;
  Flags := TList.Create;
end;

destructor TFakeCommandHost.Destroy;
begin
  Flags.Free;
  Descriptions.Free;
  Names.Free;
  inherited Destroy;
end;

procedure TFakeCommandHost.AddCommand(const AName, ADescription: string; const AFlags: Integer;
  const AHandler: TIdCommandHandler);
begin
  Names.Add(AName);
  Descriptions.Add(ADescription);
  Flags.Add(Pointer(AFlags));
  SetLength(Handlers, Length(Handlers) + 1);
  Handlers[High(Handlers)] := AHandler;
end;

procedure TFakeCommandHost.RemoveCommand(const AName: string);
var
  LIndex: Integer;
begin
  LIndex := Names.IndexOf(AName);
  if LIndex >= 0 then
  begin
    Names.Delete(LIndex);
    Descriptions.Delete(LIndex);
    Flags.Delete(LIndex);
    Delete(Handlers, LIndex, 1);
  end;
end;

procedure TTestIdDictCommands.Setup;
begin
  FLog := TFakeIdLibLog.Create;
  FLogIntf := FLog;
  FLister := TIdDictLister.Create(FLogIntf);
  FDict := TIdDict.Create;
  FDict.SetValue('classname', 'monster_zombie');
  FDict.SetValue('Health', '100');
  FHost := TFakeCommandHost.Create;
  FHostIntf := FHost;
  FCommands := TIdDictCommands.Create(FLister,
    function: TArray<TIdDict>
    begin
      Result := [FDict];
    end);
end;

procedure TTestIdDictCommands.TearDown;
begin
  FCommands.Free;
  FHostIntf := nil;
  FDict.Free;
  FLister.Free;
  FLogIntf := nil;
end;

procedure TTestIdDictCommands.DovrebbeRegistrareITreComandiConFlagEDescrizioneDelCpp;
begin
  FCommands.Register(FHostIntf);
  Assert.AreEqual(3, FHost.Names.Count);
  Assert.AreEqual('showDictMemory', FHost.Names[0]);
  Assert.AreEqual('shows memory used by dictionaries', FHost.Descriptions[0]);
  Assert.AreEqual(ID_CMD_FL_SYSTEM, Integer(FHost.Flags[0]));
  Assert.AreEqual('listDictKeys', FHost.Names[1]);
  Assert.AreEqual('lists all keys used by dictionaries', FHost.Descriptions[1]);
  Assert.AreEqual(ID_CMD_FL_SYSTEM or ID_CMD_FL_CHEAT, Integer(FHost.Flags[1]));
  Assert.AreEqual('listDictValues', FHost.Names[2]);
  Assert.AreEqual('lists all values used by dictionaries', FHost.Descriptions[2]);
  Assert.AreEqual(3, Integer(FHost.Flags[2]));
end;

procedure TTestIdDictCommands.ILComandiDovrebberoElencareChiaviEValoriDelFornitore;
begin
  FCommands.Register(FHostIntf);
  FHost.Handlers[1]();
  Assert.AreEqual('P: classname\n', FLog.Lines[0]);
  Assert.AreEqual('P: Health\n', FLog.Lines[1]);
  Assert.AreEqual('P:     2 keys\n', FLog.Lines[2]);
  FHost.Handlers[2]();
  Assert.AreEqual('P: 100\n', FLog.Lines[3]);
  Assert.AreEqual('P: monster_zombie\n', FLog.Lines[4]);
  Assert.AreEqual('P:     2 values\n', FLog.Lines[5]);
end;

procedure TTestIdDictCommands.ShowDictMemoryDovrebbeStampareDueRighe;
begin
  FCommands.Register(FHostIntf);
  FHost.Handlers[0]();
  Assert.AreEqual(2, FLog.Lines.Count);
  Assert.AreEqual('P:     0 KB in 2 keys\n', FLog.Lines[0]);
  Assert.AreEqual('P:     0 KB in 2 values\n', FLog.Lines[1]);
end;

procedure TTestIdDictCommands.UnregisterDovrebbeTogliereITreComandi;
begin
  FCommands.Register(FHostIntf);
  FCommands.Unregister;
  Assert.AreEqual(0, FHost.Names.Count);
  FCommands.Unregister;
  // registering twice replaces the first registration
  FCommands.Register(FHostIntf);
  FCommands.Register(FHostIntf);
  Assert.AreEqual(3, FHost.Names.Count);
end;

procedure TTestIdDictCommands.DovrebbeRifiutareArgomentiNulli;
begin
  Assert.WillRaise(
    procedure
    begin
      TIdDictCommands.Create(nil, function: TArray<TIdDict> begin Result := nil; end);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TIdDictCommands.Create(FLister, nil);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      FCommands.Register(nil);
    end, EArgumentNilException);
end;

procedure TTestIdDictCommands.ShowMemoryUsageDovrebbeEssereMutoSenzaLog;
var
  LSilent: TIdDictLister;
begin
  LSilent := TIdDictLister.Create(nil);
  try
    LSilent.ShowMemoryUsage([FDict]);
  finally
    LSilent.Free;
  end;
  Assert.AreEqual(0, FLog.Lines.Count);
end;

end.
