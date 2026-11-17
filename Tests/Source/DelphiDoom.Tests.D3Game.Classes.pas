{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Doom 3 game library - the classes of the harness   }
{  (idMover, idDoor, idLight...) that the scenarios of                         }
{  Tools\Verifica\255\harness_game.cpp spawn and make think                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.D3Game.Classes;

interface

uses
  System.SysUtils, DelphiDoom.D3Game.Types, DelphiDoom.D3Game.Intf, DelphiDoom.D3Game.ClassBase,
  DelphiDoom.D3Game.Entity, DelphiDoom.Tests.D3Game.World;

type
  /// <summary>
  ///   What the entities of the harness have in common: they write what they do to the trace of the fake world (the
  ///   <c>Think</c> of <c>idEntity</c> of the harness prints, the library one does not)
  /// </summary>
  TTestEntity = class(TD3Entity)
  strict private
    FWorldTrace: TD3GameFakeWorld;
  public
    constructor Create(const AWorld: ID3EntityWorld; const ACanceller: ID3EventCanceller;
      const ATrace: TD3GameFakeWorld);
    procedure Think; override;
    procedure UpdatePhysicsTime(const ATime: Integer); override;
    property WorldTrace: TD3GameFakeWorld read FWorldTrace;
  end;

  TTestItem = class(TTestEntity)
  public
    constructor Create(const AWorld: ID3EntityWorld; const ACanceller: ID3EventCanceller;
      const ATrace: TD3GameFakeWorld);
    class procedure SpawnClass(const AInstance: TD3Class); static;
  end;

  TTestMover = class(TTestEntity)
  strict private
    FThinkCount: Integer;
  public
    constructor Create(const AWorld: ID3EntityWorld; const ACanceller: ID3EventCanceller;
      const ATrace: TD3GameFakeWorld);
    class procedure SpawnClass(const AInstance: TD3Class); static;
    procedure Think; override;
  end;

  TTestDoor = class(TTestMover)
  public
    constructor Create(const AWorld: ID3EntityWorld; const ACanceller: ID3EventCanceller;
      const ATrace: TD3GameFakeWorld);
    class procedure SpawnClass(const AInstance: TD3Class); static;
  end;

  /// <summary>No spawn function and no events of its own</summary>
  TTestPlat = class(TTestMover)
  public
    constructor Create(const AWorld: ID3EntityWorld; const ACanceller: ID3EventCanceller;
      const ATrace: TD3GameFakeWorld);
  end;

  /// <summary>No spawn function and no events of its own</summary>
  TTestLight = class(TTestEntity)
  public
    constructor Create(const AWorld: ID3EntityWorld; const ACanceller: ID3EventCanceller;
      const ATrace: TD3GameFakeWorld);
  end;

  TTestPlayerStart = class(TTestEntity)
  public
    constructor Create(const AWorld: ID3EntityWorld; const ACanceller: ID3EventCanceller;
      const ATrace: TD3GameFakeWorld);
    class procedure SpawnClass(const AInstance: TD3Class); static;
  end;

  TTestWorldspawn = class(TTestEntity)
  public
    constructor Create(const AWorld: ID3EntityWorld; const ACanceller: ID3EventCanceller;
      const ATrace: TD3GameFakeWorld);
    class procedure SpawnClass(const AInstance: TD3Class); static;
  end;

  TTestTriggerMulti = class(TTestEntity)
  public
    constructor Create(const AWorld: ID3EntityWorld; const ACanceller: ID3EventCanceller;
      const ATrace: TD3GameFakeWorld);
    class procedure SpawnClass(const AInstance: TD3Class); static;
  end;

  /// <summary>An object that is not an entity</summary>
  TTestDebugHelper = class(TD3Class)
  strict private
    FWorldTrace: TD3GameFakeWorld;
  public
    constructor Create(const ACanceller: ID3EventCanceller; const ATrace: TD3GameFakeWorld);
    class procedure SpawnClass(const AInstance: TD3Class); static;
    property WorldTrace: TD3GameFakeWorld read FWorldTrace;
  end;

  /// <summary>The spawn function of an abstract class (never called: it cannot be made)</summary>
  TTestBinder = class(TTestEntity)
  public
    class procedure SpawnClass(const AInstance: TD3Class); static;
  end;

implementation

function NameOf(const AInstance: TD3Class): string;
begin
  Result := string(TD3Entity(AInstance).GetName);
end;

function TraceOf(const AInstance: TD3Class): TD3GameFakeWorld;
begin
  Result := TTestEntity(AInstance).WorldTrace;
end;

{ TTestEntity }

constructor TTestEntity.Create(const AWorld: ID3EntityWorld; const ACanceller: ID3EventCanceller;
  const ATrace: TD3GameFakeWorld);
begin
  inherited Create(AWorld, ACanceller);
  FWorldTrace := ATrace;
end;

procedure TTestEntity.Think;
begin
  FWorldTrace.Line('THINK ' + string(GetName));
end;

procedure TTestEntity.UpdatePhysicsTime(const ATime: Integer);
begin
  FWorldTrace.Line(Format('CALL physics.UpdateTime %d', [ATime]));
end;

{ TTestItem }

constructor TTestItem.Create(const AWorld: ID3EntityWorld; const ACanceller: ID3EventCanceller;
  const ATrace: TD3GameFakeWorld);
begin
  inherited Create(AWorld, ACanceller, ATrace);
  ATrace.Line('CTOR idItem');
end;

class procedure TTestItem.SpawnClass(const AInstance: TD3Class);
begin
  TraceOf(AInstance).Line('SPAWN idItem ' + NameOf(AInstance));
end;

{ TTestMover }

constructor TTestMover.Create(const AWorld: ID3EntityWorld; const ACanceller: ID3EventCanceller;
  const ATrace: TD3GameFakeWorld);
begin
  inherited Create(AWorld, ACanceller, ATrace);
  ATrace.Line('CTOR idMover');
end;

class procedure TTestMover.SpawnClass(const AInstance: TD3Class);
begin
  TraceOf(AInstance).Line('SPAWN idMover ' + NameOf(AInstance));
  TD3Entity(AInstance).BecomeActive(D3_TH_THINK);
end;

procedure TTestMover.Think;
begin
  Inc(FThinkCount);
  WorldTrace.Line(Format('THINK idMover %s %d', [string(GetName), FThinkCount]));
  if FThinkCount >= SpawnArgs.GetInt('thinks', '2') then
    BecomeInactive(D3_TH_THINK);
end;

{ TTestDoor }

constructor TTestDoor.Create(const AWorld: ID3EntityWorld; const ACanceller: ID3EventCanceller;
  const ATrace: TD3GameFakeWorld);
begin
  inherited Create(AWorld, ACanceller, ATrace);
  ATrace.Line('CTOR idDoor');
end;

class procedure TTestDoor.SpawnClass(const AInstance: TD3Class);
begin
  TraceOf(AInstance).Line('SPAWN idDoor ' + NameOf(AInstance));
end;

{ TTestPlat }

constructor TTestPlat.Create(const AWorld: ID3EntityWorld; const ACanceller: ID3EventCanceller;
  const ATrace: TD3GameFakeWorld);
begin
  inherited Create(AWorld, ACanceller, ATrace);
  ATrace.Line('CTOR idPlat');
end;

{ TTestLight }

constructor TTestLight.Create(const AWorld: ID3EntityWorld; const ACanceller: ID3EventCanceller;
  const ATrace: TD3GameFakeWorld);
begin
  inherited Create(AWorld, ACanceller, ATrace);
  ATrace.Line('CTOR idLight');
end;

{ TTestPlayerStart }

constructor TTestPlayerStart.Create(const AWorld: ID3EntityWorld; const ACanceller: ID3EventCanceller;
  const ATrace: TD3GameFakeWorld);
begin
  inherited Create(AWorld, ACanceller, ATrace);
  ATrace.Line('CTOR idPlayerStart');
end;

class procedure TTestPlayerStart.SpawnClass(const AInstance: TD3Class);
begin
  TraceOf(AInstance).Line('SPAWN idPlayerStart ' + NameOf(AInstance));
end;

{ TTestWorldspawn }

constructor TTestWorldspawn.Create(const AWorld: ID3EntityWorld; const ACanceller: ID3EventCanceller;
  const ATrace: TD3GameFakeWorld);
begin
  inherited Create(AWorld, ACanceller, ATrace);
  ATrace.Line('CTOR idWorldspawn');
end;

class procedure TTestWorldspawn.SpawnClass(const AInstance: TD3Class);
begin
  TraceOf(AInstance).Line('SPAWN idWorldspawn ' + NameOf(AInstance));
end;

{ TTestTriggerMulti }

constructor TTestTriggerMulti.Create(const AWorld: ID3EntityWorld; const ACanceller: ID3EventCanceller;
  const ATrace: TD3GameFakeWorld);
begin
  inherited Create(AWorld, ACanceller, ATrace);
  ATrace.Line('CTOR idTrigger_Multi');
end;

class procedure TTestTriggerMulti.SpawnClass(const AInstance: TD3Class);
begin
  TraceOf(AInstance).Line('SPAWN idTrigger_Multi ' + NameOf(AInstance));
  TD3Entity(AInstance).BecomeActive(D3_TH_THINK);
end;

{ TTestDebugHelper }

constructor TTestDebugHelper.Create(const ACanceller: ID3EventCanceller; const ATrace: TD3GameFakeWorld);
begin
  inherited Create(ACanceller);
  FWorldTrace := ATrace;
  ATrace.Line('CTOR idDebugHelper');
end;

class procedure TTestDebugHelper.SpawnClass(const AInstance: TD3Class);
begin
  TTestDebugHelper(AInstance).WorldTrace.Line('SPAWN idDebugHelper');
end;

{ TTestBinder }

class procedure TTestBinder.SpawnClass(const AInstance: TD3Class);
begin
  TraceOf(AInstance).Line('SPAWN idBinder');
end;

end.
