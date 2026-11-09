{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the states of the actors, as a table that changes  }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.StateTableCopy;

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.StateTypes, DelphiDoom.Keen.Intf;

type
  /// <summary>
  ///   A copy of a table of states (the 213 of the game, or the ones of a test): the code of the game changes
  ///   the flag of a state for a moment, and the table that is in the program must not change
  /// </summary>
  TKeenStateTableCopy = class(TInterfacedObject, IKeenStateTable)
  strict private
    FStates: TArray<TKeenStateDef>;
  public
    constructor Create(const AStates: array of TKeenStateDef);
    /// <summary>The 213 states of kd_keen.c, kd_act1.c and kd_act2.c</summary>
    class function CreateGameStates: IKeenStateTable; static;
    function GetCount: Integer;
    function GetDef(AIndex: Integer): TKeenStateDef;
    procedure SetPushToFloor(AIndex: Integer; AValue: Boolean);
  end;

implementation

uses
  DelphiDoom.Keen.StateTable;

{ TKeenStateTableCopy }

constructor TKeenStateTableCopy.Create(const AStates: array of TKeenStateDef);
var
  LIndex: Integer;
begin
  inherited Create;
  SetLength(FStates, Length(AStates));
  for LIndex := 0 to High(AStates) do
    FStates[LIndex] := AStates[LIndex];
end;

class function TKeenStateTableCopy.CreateGameStates: IKeenStateTable;
begin
  Result := TKeenStateTableCopy.Create(KEEN_STATES);
end;

function TKeenStateTableCopy.GetCount: Integer;
begin
  Result := Length(FStates);
end;

function TKeenStateTableCopy.GetDef(AIndex: Integer): TKeenStateDef;
begin
  if (AIndex < 0) or (AIndex >= Length(FStates)) then
    raise EKeenException.CreateFmt(SKeenStateInvalid, [AIndex, Length(FStates)]);
  Result := FStates[AIndex];
end;

procedure TKeenStateTableCopy.SetPushToFloor(AIndex: Integer; AValue: Boolean);
begin
  if (AIndex < 0) or (AIndex >= Length(FStates)) then
    raise EKeenException.CreateFmt(SKeenStateInvalid, [AIndex, Length(FStates)]);
  FStates[AIndex].PushToFloor := AValue;
end;

end.
