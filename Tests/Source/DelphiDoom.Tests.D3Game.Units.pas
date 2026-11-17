{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Doom 3 game library - what the golden files of     }
{  the C++ do not say: the rules of this port (ownership, errors, observers)   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.D3Game.Units;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Tests.D3Game.Rig;

type
  [TestFixture]
  [Category('D3Game')]
  TTestD3GameUnits = class
  strict private
    FRig: TD3GameRig;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DichiarareDueVolteLaStessaClasseDovrebbeSollevareUnErrore;
    [Test]
    procedure UnaClasseDichiarataPrimaDellaSuperclasseDovrebbeEssereNellaGerarchia;
    [Test]
    procedure LErroreDiGameLocalDovrebbeStamparsiESollevareUnaEccezione;
    [Test]
    procedure IlGiocoDovrebbeLiberareLeEntitaCheHaGenerato;
    [Test]
    procedure UnOsservatoreDovrebbeSapereQuandoUnaEntitaEntraEEsceDallaTabella;
    [Test]
    procedure UnEventoDelleClassiDovrebbeRaggiungereLOggettoDaProcessEvent;
  end;

implementation

uses
  System.SysUtils, System.Classes, DelphiDoom.Scanner.IdDict, DelphiDoom.DoomScript.EventDef,
  DelphiDoom.D3Game.Types, DelphiDoom.D3Game.Intf, DelphiDoom.D3Game.ClassBase, DelphiDoom.D3Game.Entity,
  DelphiDoom.D3Game.Local;

type
  /// <summary>An observer that writes what it is told</summary>
  TRecordingObserver = class(TInterfacedObject, ID3EntityObserver)
  strict private
    FLog: TStringList;
  public
    constructor Create(const ALog: TStringList);
    procedure EntityRegistered(const AEntity: TObject; const AEntityNumber: Integer);
    procedure EntityUnregistered(const AEntityNumber: Integer);
  end;

constructor TRecordingObserver.Create(const ALog: TStringList);
begin
  inherited Create;
  FLog := ALog;
end;

procedure TRecordingObserver.EntityRegistered(const AEntity: TObject; const AEntityNumber: Integer);
begin
  FLog.Add('in ' + IntToStr(AEntityNumber));
end;

procedure TRecordingObserver.EntityUnregistered(const AEntityNumber: Integer);
begin
  FLog.Add('out ' + IntToStr(AEntityNumber));
end;

procedure TTestD3GameUnits.Setup;
begin
  FRig := TD3GameRig.Create;
  FRig.Classes.Init;
  FRig.Game.NewMap;
  FRig.World.AddDef('func_door', ['spawnclass', 'idDoor']);
end;

procedure TTestD3GameUnits.TearDown;
begin
  FRig.Free;
end;

procedure TTestD3GameUnits.DichiarareDueVolteLaStessaClasseDovrebbeSollevareUnErrore;
begin
  Assert.WillRaise(
    procedure
    begin
      FRig.Classes.Declare('idDoor', 'idMover', nil, TD3Class.SpawnClass);
    end, EArgumentException);
end;

procedure TTestD3GameUnits.UnaClasseDichiarataPrimaDellaSuperclasseDovrebbeEssereNellaGerarchia;
var
  LDoor: TD3TypeInfo;
  LMover: TD3TypeInfo;
begin
  // idDoor is declared before idMover in the rig: the link is made when idMover is declared
  LDoor := FRig.Classes.GetClass('idDoor');
  LMover := FRig.Classes.GetClass('idMover');
  Assert.AreSame(LMover, LDoor.Super);
  Assert.IsTrue(LDoor.IsType(LMover));
  Assert.IsFalse(LMover.IsType(LDoor));
  Assert.IsTrue(LDoor.IsType(FRig.Classes.GetClass('idClass')));
end;

procedure TTestD3GameUnits.LErroreDiGameLocalDovrebbeStamparsiESollevareUnaEccezione;
begin
  Assert.WillRaise(
    procedure
    begin
      FRig.Classes.CreateInstance('idBinder');
    end, ED3GameException);
  Assert.AreEqual('ERROR Cannot instanciate abstract class idBinder.', FRig.World.Trace[FRig.World.Trace.Count - 1]);
end;

procedure TTestD3GameUnits.IlGiocoDovrebbeLiberareLeEntitaCheHaGenerato;
var
  LArgs: TIdDict;
  LEntity: TD3Entity;
begin
  LArgs := TIdDict.Create;
  try
    LArgs.SetValue('classname', 'func_door');
    LArgs.SetValue('name', 'a');
    Assert.IsTrue(FRig.Game.SpawnEntityDef(LArgs, LEntity));
    Assert.IsNotNull(LEntity);
    Assert.AreEqual(D3_MAX_CLIENTS, LEntity.EntityNumber);
    // freeing the rig frees the game, which frees the entity (the test fails on a leak or a double free)
  finally
    LArgs.Free;
  end;
end;

procedure TTestD3GameUnits.UnOsservatoreDovrebbeSapereQuandoUnaEntitaEntraEEsceDallaTabella;
var
  LLog: TStringList;
  LRig: TD3GameRig;
  LArgs: TIdDict;
  LEntity: TD3Entity;
begin
  LLog := TStringList.Create;
  try
    LRig := TD3GameRig.Create(TRecordingObserver.Create(LLog));
    try
      LRig.Classes.Init;
      LRig.Game.NewMap;
      LRig.World.AddDef('func_door', ['spawnclass', 'idDoor']);
      LArgs := TIdDict.Create;
      try
        LArgs.SetValue('classname', 'func_door');
        Assert.IsTrue(LRig.Game.SpawnEntityDef(LArgs, LEntity));
        Assert.AreEqual('in 32', LLog.Text.Trim);
        Assert.IsTrue(LRig.Game.RemoveEntity(32));
        Assert.AreEqual('in 32' + sLineBreak + 'out 32', LLog.Text.Trim);
      finally
        LArgs.Free;
      end;
    finally
      LRig.Free;
    end;
  finally
    LLog.Free;
  end;
end;
procedure TTestD3GameUnits.UnEventoDelleClassiDovrebbeRaggiungereLOggettoDaProcessEvent;
var
  LObject: TD3Class;
  LHide: TDoomScriptEventDef;
begin
  LObject := FRig.Game.CreateObject(FRig.Classes.GetClass('idDoor'));
  LHide := FRig.Events.FindEvent('hide');
  Assert.IsTrue(LObject.ProcessEvent(LHide));
  Assert.AreEqual('EVENT idDoor.Hide ', FRig.World.Trace[FRig.World.Trace.Count - 1]);
  Assert.IsFalse(LObject.ProcessEvent(FRig.Events.FindEvent('show')));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestD3GameUnits);

end.
