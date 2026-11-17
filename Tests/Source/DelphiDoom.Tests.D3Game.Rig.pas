{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Doom 3 game library - a game on fakes: the fake    }
{  world, the events, the classes of the harness declared in the order of      }
{  harness_game.cpp, and the game                                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.D3Game.Rig;

interface

uses
  System.SysUtils, DelphiDoom.DoomScript.Types, DelphiDoom.DoomScript.EventDef, DelphiDoom.DoomScript.EventRegistry, DelphiDoom.D3Game.Types,
  DelphiDoom.D3Game.Intf, DelphiDoom.D3Game.ClassBase, DelphiDoom.D3Game.ClassSystem, DelphiDoom.D3Game.Entity,
  DelphiDoom.D3Game.Local, DelphiDoom.Tests.D3Game.World, DelphiDoom.Tests.D3Game.Classes;

type
  /// <summary>
  ///   A class system and a game on a fake world, with the events and the classes of the harness. The classes are
  ///   declared in the order of the C++ file (a subclass before its superclass on purpose); <c>Init</c> is for the
  ///   test to call.
  /// </summary>
  TD3GameRig = class
  strict private
    FWorld: TD3GameFakeWorld;
    FEvents: TDoomScriptEventRegistry;
    FClasses: TD3ClassSystem;
    FGame: TD3GameLocal;
    FEvActivate: TDoomScriptEventDef;
    FEvHide: TDoomScriptEventDef;
    FEvShow: TDoomScriptEventDef;
    FEvOpen: TDoomScriptEventDef;
    FEvPing: TDoomScriptEventDef;
    procedure DeclareEvents;
    procedure DeclareClasses;
    procedure EntityEvent(const AType: TD3TypeInfo; const AEvent: TDoomScriptEventDef; const ALabel: string);
  public
    /// <param name="AObserver">told when an entity enters or leaves the table; may be nil</param>
    constructor Create(const AObserver: ID3EntityObserver = nil);
    destructor Destroy; override;
    property World: TD3GameFakeWorld read FWorld;
    property Events: TDoomScriptEventRegistry read FEvents;
    property Classes: TD3ClassSystem read FClasses;
    property Game: TD3GameLocal read FGame;
  end;

implementation

constructor TD3GameRig.Create(const AObserver: ID3EntityObserver);
var
  LServices: TD3GameServices;
begin
  inherited Create;
  FWorld := TD3GameFakeWorld.Create;
  FEvents := TDoomScriptEventRegistry.Create;
  FClasses := TD3ClassSystem.Create(FWorld, FEvents, FWorld);
  LServices.Printer := FWorld;
  LServices.EntityDefs := FWorld;
  LServices.SpawnFunctions := FWorld;
  LServices.ScriptNames := FWorld;
  LServices.Settings := FWorld;
  LServices.MapSteps := FWorld;
  LServices.EventCanceller := FWorld;
  LServices.EntityObserver := AObserver;
  FGame := TD3GameLocal.Create(LServices, FClasses);
  DeclareEvents;
  DeclareClasses;
end;

destructor TD3GameRig.Destroy;
begin
  FGame.Free;
  FClasses.Free;
  FEvents.Free;
  FWorld.Free;
  inherited Destroy;
end;

procedure TD3GameRig.DeclareEvents;
begin
  FEvActivate := FEvents.Define('activate', 'e');
  FEvHide := FEvents.Define('hide');
  FEvShow := FEvents.Define('show');
  FEvOpen := FEvents.Define('open');
  // the same name and format: the same event number
  FEvents.Define('activate', 'e');
  FEvPing := FEvents.Define('ping', 'd');
end;

procedure TD3GameRig.EntityEvent(const AType: TD3TypeInfo; const AEvent: TDoomScriptEventDef; const ALabel: string);
var
  LTrace: TD3GameFakeWorld;
begin
  LTrace := FWorld;
  AType.AddEvent(AEvent,
    procedure(const ATarget: TD3Class; const AEventDef: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      LTrace.Line(Format('EVENT %s %s', [ALabel, string(TD3Entity(ATarget).GetName)]));
    end);
end;

procedure TD3GameRig.DeclareClasses;
var
  LGame: TD3GameLocal;
  LWorld: TD3GameFakeWorld;
  LType: TD3TypeInfo;
begin
  LGame := FGame;
  LWorld := FWorld;
  // the order of the CLASS_DECLARATION lines of harness_game.cpp (the static initialization order)
  LType := FClasses.Declare('idDoor', 'idMover',
    function: TD3Class
    begin
      Result := TTestDoor.Create(LGame, LGame, LWorld);
    end, TTestDoor.SpawnClass);
  EntityEvent(LType, FEvActivate, 'idDoor.Activate');
  EntityEvent(LType, FEvHide, 'idDoor.Hide');

  LType := FClasses.Declare('idMover', 'idEntity',
    function: TD3Class
    begin
      Result := TTestMover.Create(LGame, LGame, LWorld);
    end, TTestMover.SpawnClass);
  EntityEvent(LType, FEvOpen, 'idMover.Open');

  LType := FClasses.Declare('idEntity', 'idClass', nil, TD3Entity.SpawnClass, True);
  EntityEvent(LType, FEvHide, 'idEntity.Hide');

  LType := FClasses.Declare('idItem', 'idEntity',
    function: TD3Class
    begin
      Result := TTestItem.Create(LGame, LGame, LWorld);
    end, TTestItem.SpawnClass);
  EntityEvent(LType, FEvShow, 'idItem.Show');

  FClasses.Declare('idPlayerStart', 'idEntity',
    function: TD3Class
    begin
      Result := TTestPlayerStart.Create(LGame, LGame, LWorld);
    end, TTestPlayerStart.SpawnClass);

  FClasses.Declare('idLight', 'idEntity',
    function: TD3Class
    begin
      Result := TTestLight.Create(LGame, LGame, LWorld);
    end, TTestLight.SpawnClass);

  FClasses.Declare('idWorldspawn', 'idEntity',
    function: TD3Class
    begin
      Result := TTestWorldspawn.Create(LGame, LGame, LWorld);
    end, TTestWorldspawn.SpawnClass);

  LType := FClasses.Declare('idTrigger_Multi', 'idEntity',
    function: TD3Class
    begin
      Result := TTestTriggerMulti.Create(LGame, LGame, LWorld);
    end, TTestTriggerMulti.SpawnClass);
  EntityEvent(LType, FEvPing, 'idTrigger_Multi.Ping');

  FClasses.Declare('idDebugHelper', 'idClass',
    function: TD3Class
    begin
      Result := TTestDebugHelper.Create(LGame, LWorld);
    end, TTestDebugHelper.SpawnClass);

  FClasses.Declare('idPlat', 'idMover',
    function: TD3Class
    begin
      Result := TTestPlat.Create(LGame, LGame, LWorld);
    end, TTestPlat.SpawnClass);

  FClasses.Declare('idBinder', 'idEntity', nil, TTestBinder.SpawnClass, True);
end;

end.
