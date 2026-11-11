{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape library - the common part of the steps of the   }
{  battle that carry an action (BattleState)                                    }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattle.StateBase;

interface

uses
  System.SysUtils, DelphiDoom.XcomBattle.Action, DelphiDoom.XcomBattle.State.Intf, DelphiDoom.XcomBattle.Game.Intf;

type
  /// <summary>
  ///   A step with the game it belongs to and its own copy of the action (the C++ BattleState holds a
  ///   BattleAction by value): the base of the steps that spend time units or move a unit
  /// </summary>
  TXcomBattleStateBase = class(TInterfacedObject, IXcomBattleState)
  strict private
    FAction: TXcomBattleAction;
  strict protected
    FGame: IXcomBattlescapeGame;
    property ActionData: TXcomBattleAction read FAction;
  public
    /// <param name="AAction">The action to copy; nil starts an empty one</param>
    constructor Create(const AGame: IXcomBattlescapeGame; const AAction: TXcomBattleAction = nil);
    destructor Destroy; override;
    procedure Init; virtual; abstract;
    procedure Think; virtual; abstract;
    procedure Cancel; virtual;
    procedure Deinit; virtual;
    function StateName: string; virtual; abstract;
    function Action: TXcomBattleAction;
  end;

implementation

constructor TXcomBattleStateBase.Create(const AGame: IXcomBattlescapeGame; const AAction: TXcomBattleAction);
begin
  inherited Create;
  FGame := AGame;
  FAction := TXcomBattleAction.Create;
  if Assigned(AAction) then
    FAction.Assign(AAction);
end;

destructor TXcomBattleStateBase.Destroy;
begin
  FAction.Free;
  inherited Destroy;
end;

procedure TXcomBattleStateBase.Cancel;
begin
end;

procedure TXcomBattleStateBase.Deinit;
begin
end;

function TXcomBattleStateBase.Action: TXcomBattleAction;
begin
  Result := FAction;
end;

end.
