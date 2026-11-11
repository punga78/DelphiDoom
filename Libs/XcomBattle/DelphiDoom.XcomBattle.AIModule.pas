{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape library - the AI of a unit (AIModule)           }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattle.AIModule;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.NodeReader,
  DelphiDoom.XcomSave.Node, DelphiDoom.XcomSave.NodeWriter,
  DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattle.Intf, DelphiDoom.XcomBattle.Model,
  DelphiDoom.XcomBattle.Action;

const
  /// <summary>AIMode</summary>
  AI_PATROL = 0;
  AI_AMBUSH = 1;
  AI_COMBAT = 2;
  AI_ESCAPE = 3;

type
  /// <summary>
  ///   The AI state of one unit (AIModule): the mode, the patrol nodes and the units that hit it, what the saved
  ///   battle keeps, and what the thinking keeps from one cycle to the next (the target, the five planned
  ///   actions, the tiles it can reach). The nodes belong to the saved battle. The thinking itself (think and
  ///   the behaviours) is in TXcomAIThinker, which reads and writes this state
  /// </summary>
  TXcomAIModule = class(TInterfacedObject, IXcomUnitAI)
  strict private
    FUnit: TXcomBattleUnit;
    FFromNode: TXcomNode;
    FToNode: TXcomNode;
    FAIMode: Integer;
    FWasHitBy: TArray<Integer>;
    FIntelligence: Integer;
    FEscapeTus: Integer;
    FAmbushTus: Integer;
    FTargetFaction: Integer;
    FAggroTarget: TXcomBattleUnit;
    FKnownEnemies: Integer;
    FVisibleEnemies: Integer;
    FSpottingEnemies: Integer;
    FClosestDistance: Integer;
    FEscapeAction: TXcomBattleAction;
    FAmbushAction: TXcomBattleAction;
    FAttackAction: TXcomBattleAction;
    FPatrolAction: TXcomBattleAction;
    FPsiAction: TXcomBattleAction;
    FRifle: Boolean;
    FMelee: Boolean;
    FBlaster: Boolean;
    FDidPsi: Boolean;
    FReserve: Integer;
    FReachable: TArray<Integer>;
    FReachableWithAttack: TArray<Integer>;
  public
    /// <summary>AIModule(save, unit, node)</summary>
    constructor Create(const AUnit: TXcomBattleUnit; const AFromNode: TXcomNode);
    destructor Destroy; override;
    /// <summary>load: the nodes are looked up in ANodes (the nodes of the saved battle); one that is not there stays</summary>
    procedure Load(const ANode: IYamlNode; const ANodes: TObjectList<TXcomNode>);
    /// <summary>save: fromNode, toNode, AIMode and wasHitBy</summary>
    function Save: IYamlNode;
    /// <summary>reset: the state that is not saved</summary>
    procedure Reset;
    /// <summary>freePatrolTarget</summary>
    procedure FreePatrolTarget;
    /// <summary>setWasHitBy: notes the attacker of another faction that has not hit this unit yet</summary>
    procedure SetWasHitBy(const AAttacker: TXcomBattleUnit);
    /// <summary>getWasHitBy</summary>
    function GetWasHitBy(AAttacker: Integer): Boolean;
    property Owner: TXcomBattleUnit read FUnit;
    property FromNode: TXcomNode read FFromNode write FFromNode;
    property ToNode: TXcomNode read FToNode write FToNode;
    property AIMode: Integer read FAIMode write FAIMode;
    property WasHitBy: TArray<Integer> read FWasHitBy write FWasHitBy;
    property Intelligence: Integer read FIntelligence;
    property EscapeTus: Integer read FEscapeTus write FEscapeTus;
    property AmbushTus: Integer read FAmbushTus write FAmbushTus;
    property TargetFaction: Integer read FTargetFaction;
    /// <summary>The target of the last selection (getTarget)</summary>
    property AggroTarget: TXcomBattleUnit read FAggroTarget write FAggroTarget;
    property KnownEnemies: Integer read FKnownEnemies write FKnownEnemies;
    property VisibleEnemies: Integer read FVisibleEnemies write FVisibleEnemies;
    property SpottingEnemies: Integer read FSpottingEnemies write FSpottingEnemies;
    property ClosestDistance: Integer read FClosestDistance write FClosestDistance;
    property EscapeAction: TXcomBattleAction read FEscapeAction;
    property AmbushAction: TXcomBattleAction read FAmbushAction;
    property AttackAction: TXcomBattleAction read FAttackAction;
    property PatrolAction: TXcomBattleAction read FPatrolAction;
    property PsiAction: TXcomBattleAction read FPsiAction;
    property Rifle: Boolean read FRifle write FRifle;
    property Melee: Boolean read FMelee write FMelee;
    property Blaster: Boolean read FBlaster write FBlaster;
    property DidPsi: Boolean read FDidPsi write FDidPsi;
    /// <summary>getReserveMode: the time units reservation (BA_*) the unit asks for after its action</summary>
    property ReserveMode: Integer read FReserve write FReserve;
    property Reachable: TArray<Integer> read FReachable write FReachable;
    property ReachableWithAttack: TArray<Integer> read FReachableWithAttack write FReachableWithAttack;
  end;

implementation

constructor TXcomAIModule.Create(const AUnit: TXcomBattleUnit; const AFromNode: TXcomNode);
begin
  inherited Create;
  FUnit := AUnit;
  FFromNode := AFromNode;
  FAIMode := AI_PATROL;
  FIntelligence := AUnit.Intelligence;
  FClosestDistance := 100;
  FReserve := BA_NONE;
  FEscapeAction := TXcomBattleAction.Create;
  FAmbushAction := TXcomBattleAction.Create;
  FAttackAction := TXcomBattleAction.Create;
  FPatrolAction := TXcomBattleAction.Create;
  FPsiAction := TXcomBattleAction.Create;
  FTargetFaction := FACTION_PLAYER;
  if AUnit.OriginalFaction = FACTION_NEUTRAL then
    FTargetFaction := FACTION_HOSTILE;
end;

destructor TXcomAIModule.Destroy;
begin
  FEscapeAction.Free;
  FAmbushAction.Free;
  FAttackAction.Free;
  FPatrolAction.Free;
  FPsiAction.Free;
  inherited Destroy;
end;

procedure TXcomAIModule.Load(const ANode: IYamlNode; const ANodes: TObjectList<TXcomNode>);
var
  LFromId: Integer;
  LToId: Integer;
begin
  LFromId := TXcomNodeReader.ReadInteger(ANode, 'fromNode', -1);
  LToId := TXcomNodeReader.ReadInteger(ANode, 'toNode', -1);
  FAIMode := TXcomNodeReader.ReadInteger(ANode, 'AIMode', AI_PATROL);
  FWasHitBy := TXcomNodeReader.ReadIntegers(ANode, 'wasHitBy', FWasHitBy);
  // the C++ comment: figure out why AI are sometimes left with junk nodes
  if (LFromId >= 0) and (LFromId < ANodes.Count) then
    FFromNode := ANodes[LFromId];
  if (LToId >= 0) and (LToId < ANodes.Count) then
    FToNode := ANodes[LToId];
end;

function TXcomAIModule.Save: IYamlNode;
var
  LFromId: Integer;
  LToId: Integer;
begin
  LFromId := -1;
  LToId := -1;
  if Assigned(FFromNode) then
    LFromId := FFromNode.Id;
  if Assigned(FToNode) then
    LToId := FToNode.Id;
  Result := TXcomNodeWriter.NewMap;
  TXcomNodeWriter.SetInteger(Result, 'fromNode', LFromId);
  TXcomNodeWriter.SetInteger(Result, 'toNode', LToId);
  TXcomNodeWriter.SetInteger(Result, 'AIMode', FAIMode);
  TXcomNodeWriter.SetIntegers(Result, 'wasHitBy', FWasHitBy);
end;

procedure TXcomAIModule.Reset;
begin
  FEscapeTus := 0;
  FAmbushTus := 0;
end;

procedure TXcomAIModule.FreePatrolTarget;
begin
  if Assigned(FToNode) then
    FToNode.Deallocate;
end;

procedure TXcomAIModule.SetWasHitBy(const AAttacker: TXcomBattleUnit);
begin
  if (AAttacker.Faction <> FUnit.Faction) and (not GetWasHitBy(AAttacker.Id)) then
    FWasHitBy := FWasHitBy + [AAttacker.Id];
end;

function TXcomAIModule.GetWasHitBy(AAttacker: Integer): Boolean;
var
  LId: Integer;
begin
  Result := False;
  for LId in FWasHitBy do
    if LId = AAttacker then
      Exit(True);
end;

end.
