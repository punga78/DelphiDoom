{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the world adapters of the bots (TBotAasWorld,          }
{  TBotAasEntitySource) and of the goal system factory                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.BotAi.WorldUnits;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('BotAi.World')]
  TTestBotWorldUnits = class
  public
    [Test]
    procedure DovrebbeEssereSenzaMappaFinoAlSetMap;
    [Test]
    procedure DovrebbeSollevareEccezioneSeMancaUnaParteDellaMappa;
    [Test]
    procedure DovrebbeTornareSenzaMappaDopoClearMap;
    [Test]
    procedure DovrebbeRicordareIlTempo;
    [Test]
    procedure DovrebbeDareLeRisposteDiUnaTabellaVuota;
    [Test]
    procedure DovrebbeCrearePerOgniFabbricaUnSistemaDiObiettivi;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.MathCore.Types, DelphiDoom.BotAi.Exceptions, DelphiDoom.BotAi.Import.Intf,
  DelphiDoom.Aas.Main.Intf, DelphiDoom.Aas.Entity.Table, DelphiDoom.BotAi.World.Intf, DelphiDoom.BotAi.World.AasWorld,
  DelphiDoom.BotAi.World.EntitySource, DelphiDoom.BotAi.Goal.Factory;

type
  TQuietImport = class(TInterfacedObject, IBotImport)
  public
    procedure Print(const ALevel: Integer; const AMessage: AnsiString);
    procedure LogWrite(const AMessage: AnsiString);
    function Time: Single;
    procedure Command(const AClient: Integer; const ACommand: AnsiString);
  end;

  TNothingLoaded = class(TInterfacedObject, IAasFrameState)
  public
    function GetLoaded: Boolean;
    function GetInitialized: Boolean;
    function GetTime: Single;
    function GetNumFrames: Integer;
  end;

procedure TQuietImport.Print(const ALevel: Integer; const AMessage: AnsiString);
begin
end;

procedure TQuietImport.LogWrite(const AMessage: AnsiString);
begin
end;

function TQuietImport.Time: Single;
begin
  Result := 0;
end;

procedure TQuietImport.Command(const AClient: Integer; const ACommand: AnsiString);
begin
end;

function TNothingLoaded.GetLoaded: Boolean;
begin
  Result := False;
end;

function TNothingLoaded.GetInitialized: Boolean;
begin
  Result := False;
end;

function TNothingLoaded.GetTime: Single;
begin
  Result := 0;
end;

function TNothingLoaded.GetNumFrames: Integer;
begin
  Result := 0;
end;

{ TTestBotWorldUnits }

procedure TTestBotWorldUnits.DovrebbeEssereSenzaMappaFinoAlSetMap;
var
  LWorld: TBotAasWorld;
  LHolder: IBotAasWorld;
begin
  LWorld := TBotAasWorld.Create(nil, nil, nil);
  LHolder := LWorld;
  Assert.IsFalse(LHolder.Loaded);
  LWorld.SetMap(nil, nil, nil, nil, nil, nil, nil);
  Assert.IsTrue(LHolder.Loaded);
end;

procedure TTestBotWorldUnits.DovrebbeSollevareEccezioneSeMancaUnaParteDellaMappa;
var
  LHolder: IBotAasWorld;
begin
  LHolder := TBotAasWorld.Create(nil, nil, nil);
  Assert.WillRaise(procedure begin LHolder.Areas; end, EBotAiException);
  Assert.WillRaise(procedure begin LHolder.Sampler; end, EBotAiException);
  Assert.WillRaise(procedure begin LHolder.Tracer; end, EBotAiException);
  Assert.WillRaise(procedure begin LHolder.Router; end, EBotAiException);
  Assert.WillRaise(procedure begin LHolder.Movement; end, EBotAiException);
  Assert.WillRaise(procedure begin LHolder.BestReachable; end, EBotAiException);
  Assert.WillRaise(procedure begin LHolder.BspEntities; end, EBotAiException);
end;

procedure TTestBotWorldUnits.DovrebbeTornareSenzaMappaDopoClearMap;
var
  LWorld: TBotAasWorld;
  LHolder: IBotAasWorld;
begin
  LWorld := TBotAasWorld.Create(nil, nil, nil);
  LHolder := LWorld;
  LWorld.SetMap(nil, nil, nil, nil, nil, nil, nil);
  LWorld.ClearMap;
  Assert.IsFalse(LHolder.Loaded);
  Assert.WillRaise(procedure begin LHolder.Areas; end, EBotAiException);
end;

procedure TTestBotWorldUnits.DovrebbeRicordareIlTempo;
var
  LWorld: TBotAasWorld;
  LHolder: IBotAasWorld;
begin
  LWorld := TBotAasWorld.Create(nil, nil, nil);
  LHolder := LWorld;
  Assert.AreEqual(Single(0), LHolder.Time);
  LWorld.SetTime(12.5);
  Assert.AreEqual(Single(12.5), LHolder.Time);
end;

procedure TTestBotWorldUnits.DovrebbeDareLeRisposteDiUnaTabellaVuota;
var
  LTable: TAasEntityTable;
  LSource: IBotEntitySource;
  LOrigin: TVec3;
begin
  LTable := TAasEntityTable.Create(TQuietImport.Create, TNothingLoaded.Create, nil, 4,
    function(const AHead: Integer): Integer
    begin
      Result := 0;
    end);
  try
    LSource := TBotAasEntitySource.Create(LTable);
    Assert.AreEqual(0, LSource.EntityType(1));
    Assert.AreEqual(0, LSource.EntityModelIndex(1));
    Assert.AreEqual(0, LSource.EntityModelNum(1));
    Assert.AreEqual(0, LSource.EntityInfo(1).EntityType);
    Assert.AreEqual(0, LSource.NextEntity(0));
    Assert.IsFalse(LSource.OriginOfMoverWithModelNum(3, LOrigin));
    Assert.AreEqual(Single(0), LOrigin[0]);
  finally
    LSource := nil;
    LTable.Free;
  end;
end;

procedure TTestBotWorldUnits.DovrebbeCrearePerOgniFabbricaUnSistemaDiObiettivi;
begin
  Assert.IsTrue(Assigned(TBotGoalFactory.CreateGoalSystem(TQuietImport.Create, nil, nil, nil, nil, nil, nil, False)));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestBotWorldUnits);

end.
