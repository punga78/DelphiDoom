{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the keen library - fakes for the actors and the game    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.GameFakes;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Keen.Types, DelphiDoom.Keen.GameTypes,
  DelphiDoom.Keen.StateTypes, DelphiDoom.Keen.Intf;

type
  /// <summary>The functions of the states: each id has the procedure that the test gave it; the calls are written down</summary>
  TFakeKeenActions = class(TInterfacedObject, IKeenActions)
  public
    Calls: TList<string>;
    OnThink: TDictionary<Word, TProc<PKeenObject>>;
    OnContact: TDictionary<Word, TProc<PKeenObject, PKeenObject>>;
    OnReact: TDictionary<Word, TProc<PKeenObject>>;
    constructor Create;
    destructor Destroy; override;
    procedure Think(AAction: Word; AObject: PKeenObject);
    procedure Contact(AAction: Word; AObject, AOther: PKeenObject);
    procedure React(AAction: Word; AObject: PKeenObject);
  end;

  TFakeKeenEvents = class(TInterfacedObject, IKeenGameEvents)
  public
    KillCount: Integer;
    Sounds: TList<Integer>;
    CheckKeysCount: Integer;
    BeginPlayCount: Integer;
    GodModeCleared: Integer;
    GameLoaded: Boolean;
    OnCheckKeys: TProc;
    constructor Create;
    destructor Destroy; override;
    procedure KillKeen;
    procedure PlaySound(ASound: Integer);
    procedure CheckKeys;
    function IsGameLoaded: Boolean;
    procedure BeginPlay;
    procedure ClearGodMode;
  end;

  /// <summary>Spawns what the test sees: the call is written down and the actor is made like a real spawner would</summary>
  TFakeKeenSpawner = class(TInterfacedObject, IKeenActorSpawner)
  strict private
    FObjects: IKeenObjectList;
    procedure Record_(const AName: string; ATileX, ATileY, AExtra: Integer);
  public
    Calls: TList<string>;
    /// <summary>What the spawned actors get: the active field, to see that the scanner changes it</summary>
    ActiveOfSpawned: TKeenActive;
    constructor Create(const AObjects: IKeenObjectList);
    destructor Destroy; override;
    procedure SpawnKeen(ATileX, ATileY, ADirection: Integer);
    procedure SpawnWorldKeen(ATileX, ATileY: Integer);
    procedure SpawnBonus(ATileX, ATileY, AType: Integer);
    procedure SpawnDoor(ATileX, ATileY: Integer);
    procedure SpawnBrocco(ATileX, ATileY: Integer);
    procedure SpawnTomat(ATileX, ATileY: Integer);
    procedure SpawnCarrot(ATileX, ATileY: Integer);
    procedure SpawnAspar(ATileX, ATileY: Integer);
    procedure SpawnGrape(ATileX, ATileY: Integer);
    procedure SpawnTater(ATileX, ATileY: Integer);
    procedure SpawnCart(ATileX, ATileY: Integer);
    procedure SpawnFrenchy(ATileX, ATileY: Integer);
    procedure SpawnMelon(ATileX, ATileY, ADirection: Integer);
    procedure SpawnSquasher(ATileX, ATileY: Integer);
    procedure SpawnApel(ATileX, ATileY: Integer);
    procedure SpawnPeaPod(ATileX, ATileY: Integer);
    procedure SpawnPeaBrain(ATileX, ATileY: Integer);
    procedure SpawnBoobus(ATileX, ATileY: Integer);
  end;

implementation

{ TFakeKeenActions }

constructor TFakeKeenActions.Create;
begin
  inherited Create;
  Calls := TList<string>.Create;
  OnThink := TDictionary<Word, TProc<PKeenObject>>.Create;
  OnContact := TDictionary<Word, TProc<PKeenObject, PKeenObject>>.Create;
  OnReact := TDictionary<Word, TProc<PKeenObject>>.Create;
end;

destructor TFakeKeenActions.Destroy;
begin
  OnReact.Free;
  OnContact.Free;
  OnThink.Free;
  Calls.Free;
  inherited Destroy;
end;

procedure TFakeKeenActions.Think(AAction: Word; AObject: PKeenObject);
var
  LProc: TProc<PKeenObject>;
begin
  Calls.Add(Format('think %d %d', [AAction, AObject^.Slot]));
  if OnThink.TryGetValue(AAction, LProc) then
    LProc(AObject);
end;

procedure TFakeKeenActions.Contact(AAction: Word; AObject, AOther: PKeenObject);
var
  LProc: TProc<PKeenObject, PKeenObject>;
begin
  Calls.Add(Format('contact %d %d %d', [AAction, AObject^.Slot, AOther^.Slot]));
  if OnContact.TryGetValue(AAction, LProc) then
    LProc(AObject, AOther);
end;

procedure TFakeKeenActions.React(AAction: Word; AObject: PKeenObject);
var
  LProc: TProc<PKeenObject>;
begin
  Calls.Add(Format('react %d %d', [AAction, AObject^.Slot]));
  if OnReact.TryGetValue(AAction, LProc) then
    LProc(AObject);
end;

{ TFakeKeenEvents }

constructor TFakeKeenEvents.Create;
begin
  inherited Create;
  Sounds := TList<Integer>.Create;
end;

destructor TFakeKeenEvents.Destroy;
begin
  Sounds.Free;
  inherited Destroy;
end;

procedure TFakeKeenEvents.KillKeen;
begin
  Inc(KillCount);
end;

procedure TFakeKeenEvents.PlaySound(ASound: Integer);
begin
  Sounds.Add(ASound);
end;

procedure TFakeKeenEvents.CheckKeys;
begin
  Inc(CheckKeysCount);
  if Assigned(OnCheckKeys) then
    OnCheckKeys();
end;

function TFakeKeenEvents.IsGameLoaded: Boolean;
begin
  Result := GameLoaded;
end;

procedure TFakeKeenEvents.BeginPlay;
begin
  Inc(BeginPlayCount);
end;

procedure TFakeKeenEvents.ClearGodMode;
begin
  Inc(GodModeCleared);
end;

{ TFakeKeenSpawner }

constructor TFakeKeenSpawner.Create(const AObjects: IKeenObjectList);
begin
  inherited Create;
  FObjects := AObjects;
  Calls := TList<string>.Create;
  ActiveOfSpawned := kaYes;
end;

destructor TFakeKeenSpawner.Destroy;
begin
  Calls.Free;
  inherited Destroy;
end;

procedure TFakeKeenSpawner.Record_(const AName: string; ATileX, ATileY, AExtra: Integer);
var
  LObject: PKeenObject;
begin
  Calls.Add(Format('%s %d %d %d', [AName, ATileX, ATileY, AExtra]));
  LObject := FObjects.GetNewObj(False);
  LObject^.X := Word(ATileX shl 8);
  LObject^.Y := Word(ATileY shl 8);
  LObject^.Active := ActiveOfSpawned;
end;

procedure TFakeKeenSpawner.SpawnKeen(ATileX, ATileY, ADirection: Integer);
begin
  Record_('keen', ATileX, ATileY, ADirection);
end;

procedure TFakeKeenSpawner.SpawnWorldKeen(ATileX, ATileY: Integer);
begin
  Record_('worldkeen', ATileX, ATileY, 0);
end;

procedure TFakeKeenSpawner.SpawnBonus(ATileX, ATileY, AType: Integer);
begin
  Record_('bonus', ATileX, ATileY, AType);
end;

procedure TFakeKeenSpawner.SpawnDoor(ATileX, ATileY: Integer);
begin
  Record_('door', ATileX, ATileY, 0);
end;

procedure TFakeKeenSpawner.SpawnBrocco(ATileX, ATileY: Integer);
begin
  Record_('brocco', ATileX, ATileY, 0);
end;

procedure TFakeKeenSpawner.SpawnTomat(ATileX, ATileY: Integer);
begin
  Record_('tomat', ATileX, ATileY, 0);
end;

procedure TFakeKeenSpawner.SpawnCarrot(ATileX, ATileY: Integer);
begin
  Record_('carrot', ATileX, ATileY, 0);
end;

procedure TFakeKeenSpawner.SpawnAspar(ATileX, ATileY: Integer);
begin
  Record_('aspar', ATileX, ATileY, 0);
end;

procedure TFakeKeenSpawner.SpawnGrape(ATileX, ATileY: Integer);
begin
  Record_('grape', ATileX, ATileY, 0);
end;

procedure TFakeKeenSpawner.SpawnTater(ATileX, ATileY: Integer);
begin
  Record_('tater', ATileX, ATileY, 0);
end;

procedure TFakeKeenSpawner.SpawnCart(ATileX, ATileY: Integer);
begin
  Record_('cart', ATileX, ATileY, 0);
end;

procedure TFakeKeenSpawner.SpawnFrenchy(ATileX, ATileY: Integer);
begin
  Record_('frenchy', ATileX, ATileY, 0);
end;

procedure TFakeKeenSpawner.SpawnMelon(ATileX, ATileY, ADirection: Integer);
begin
  Record_('melon', ATileX, ATileY, ADirection);
end;

procedure TFakeKeenSpawner.SpawnSquasher(ATileX, ATileY: Integer);
begin
  Record_('squasher', ATileX, ATileY, 0);
end;

procedure TFakeKeenSpawner.SpawnApel(ATileX, ATileY: Integer);
begin
  Record_('apel', ATileX, ATileY, 0);
end;

procedure TFakeKeenSpawner.SpawnPeaPod(ATileX, ATileY: Integer);
begin
  Record_('peapod', ATileX, ATileY, 0);
end;

procedure TFakeKeenSpawner.SpawnPeaBrain(ATileX, ATileY: Integer);
begin
  Record_('peabrain', ATileX, ATileY, 0);
end;

procedure TFakeKeenSpawner.SpawnBoobus(ATileX, ATileY: Integer);
begin
  Record_('boobus', ATileX, ATileY, 0);
end;

end.
