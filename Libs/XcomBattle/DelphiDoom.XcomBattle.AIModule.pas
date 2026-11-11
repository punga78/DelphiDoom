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
  DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattle.Intf, DelphiDoom.XcomBattle.Model;

const
  /// <summary>AIMode</summary>
  AI_PATROL = 0;
  AI_AMBUSH = 1;
  AI_COMBAT = 2;
  AI_ESCAPE = 3;

type
  /// <summary>
  ///   The AI state of one unit (AIModule): the mode, the patrol nodes and the units that hit it, what the saved
  ///   battle keeps. The nodes belong to the saved battle. The thinking (think, the four behaviours) is in
  ///   TXcomAIThinker
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
  public
    /// <summary>AIModule(save, unit, node)</summary>
    constructor Create(const AUnit: TXcomBattleUnit; const AFromNode: TXcomNode);
    /// <summary>load: the nodes are looked up in ANodes (the nodes of the saved battle); one that is not there stays</summary>
    procedure Load(const ANode: IYamlNode; const ANodes: TObjectList<TXcomNode>);
    /// <summary>save: fromNode, toNode, AIMode and wasHitBy</summary>
    function Save: IYamlNode;
    /// <summary>reset: the state that is not saved</summary>
    procedure Reset;
    /// <summary>freePatrolTarget</summary>
    procedure FreePatrolTarget;
    property Owner: TXcomBattleUnit read FUnit;
    property FromNode: TXcomNode read FFromNode write FFromNode;
    property ToNode: TXcomNode read FToNode write FToNode;
    property AIMode: Integer read FAIMode write FAIMode;
    property WasHitBy: TArray<Integer> read FWasHitBy write FWasHitBy;
    property Intelligence: Integer read FIntelligence;
    property EscapeTus: Integer read FEscapeTus write FEscapeTus;
    property AmbushTus: Integer read FAmbushTus write FAmbushTus;
    property TargetFaction: Integer read FTargetFaction;
  end;

implementation

constructor TXcomAIModule.Create(const AUnit: TXcomBattleUnit; const AFromNode: TXcomNode);
begin
  inherited Create;
  FUnit := AUnit;
  FFromNode := AFromNode;
  FAIMode := AI_PATROL;
  FIntelligence := AUnit.Intelligence;
  FTargetFaction := FACTION_PLAYER;
  if AUnit.OriginalFaction = FACTION_NEUTRAL then
    FTargetFaction := FACTION_HOSTILE;
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

end.
