{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - the constants of the generalized linedef types    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.Constants.Generalized;

interface

uses
  DelphiDoom.ScriptHost.Constants.Intf;

type
  /// <summary>
  ///   The masks, shifts and bits of the generalized linedef types of Boom (DAMAGE_MASK,
  ///   gen_FloorCrush, DoorDelay...): numbers of the format of the maps, not of the engine
  /// </summary>
  TScriptGeneralizedConstants = class(TInterfacedObject, IScriptConstantProvider)
  public
    /// <summary>How many constants there are</summary>
    class function Count: Integer; static;
    procedure Describe(const ATable: IScriptConstantTable);
  end;

implementation

type
  TGeneralizedConstant = record
    Name: string;
    Value: Integer;
  end;

const
  GENERALIZED_CONSTANTS: array[0..80] of TGeneralizedConstant = (
    (Name: 'DAMAGE_MASK'; Value: $60),
    (Name: 'DAMAGE_SHIFT'; Value: 5),
    (Name: 'SECRET_MASK'; Value: $80),
    (Name: 'SECRET_SHIFT'; Value: 7),
    (Name: 'FRICTION_MASK'; Value: $100),
    (Name: 'FRICTION_SHIFT'; Value: 8),
    (Name: 'PUSH_MASK'; Value: $200),
    (Name: 'PUSH_SHIFT'; Value: 9),
    (Name: 'CGENFLOORBASE'; Value: $6000),
    (Name: 'CGENCEILINGBASE'; Value: $4000),
    (Name: 'CGENDOORBASE'; Value: $3C00),
    (Name: 'CGENLOCKEDBASE'; Value: $3800),
    (Name: 'CGENLIFTBASE'; Value: $3400),
    (Name: 'CGENSTAIRSBASE'; Value: $3000),
    (Name: 'CGENCRUSHERBASE'; Value: $2F80),
    (Name: 'TriggerType'; Value: $0007),
    (Name: 'TriggerTypeShift'; Value: 0),
    (Name: 'gen_FloorCrush'; Value: $1000),
    (Name: 'gen_FloorChange'; Value: $0C00),
    (Name: 'gen_FloorTarget'; Value: $0380),
    (Name: 'gen_FloorDirection'; Value: $0040),
    (Name: 'gen_FloorModel'; Value: $0020),
    (Name: 'gen_FloorSpeed'; Value: $0018),
    (Name: 'FloorCrushShift'; Value: 12),
    (Name: 'FloorChangeShift'; Value: 10),
    (Name: 'FloorTargetShift'; Value: 7),
    (Name: 'FloorDirectionShift'; Value: 6),
    (Name: 'FloorModelShift'; Value: 5),
    (Name: 'FloorSpeedShift'; Value: 3),
    (Name: 'CeilingCrush'; Value: $1000),
    (Name: 'CeilingChange'; Value: $0C00),
    (Name: 'CeilingTarget'; Value: $0380),
    (Name: 'CeilingDirection'; Value: $0040),
    (Name: 'CeilingModel'; Value: $0020),
    (Name: 'CeilingSpeed'; Value: $0018),
    (Name: 'CeilingCrushShift'; Value: 12),
    (Name: 'CeilingChangeShift'; Value: 10),
    (Name: 'CeilingTargetShift'; Value: 7),
    (Name: 'CeilingDirectionShift'; Value: 6),
    (Name: 'CeilingModelShift'; Value: 5),
    (Name: 'CeilingSpeedShift'; Value: 3),
    (Name: 'LiftTarget'; Value: $0300),
    (Name: 'LiftDelay'; Value: $00C0),
    (Name: 'LiftMonster'; Value: $0020),
    (Name: 'LiftSpeed'; Value: $0018),
    (Name: 'LiftTargetShift'; Value: 8),
    (Name: 'LiftDelayShift'; Value: 6),
    (Name: 'LiftMonsterShift'; Value: 5),
    (Name: 'LiftSpeedShift'; Value: 3),
    (Name: 'StairIgnore'; Value: $0200),
    (Name: 'StairDirection'; Value: $0100),
    (Name: 'StairStep'; Value: $00c0),
    (Name: 'StairMonster'; Value: $0020),
    (Name: 'StairSpeed'; Value: $0018),
    (Name: 'StairIgnoreShift'; Value: 9),
    (Name: 'StairDirectionShift'; Value: 8),
    (Name: 'StairStepShift'; Value: 6),
    (Name: 'StairMonsterShift'; Value: 5),
    (Name: 'StairSpeedShift'; Value: 3),
    (Name: 'CrusherSilent'; Value: $0040),
    (Name: 'CrusherMonster'; Value: $0020),
    (Name: 'CrusherSpeed'; Value: $0018),
    (Name: 'CrusherSilentShift'; Value: 6),
    (Name: 'CrusherMonsterShift'; Value: 5),
    (Name: 'CrusherSpeedShift'; Value: 3),
    (Name: 'DoorDelay'; Value: $0300),
    (Name: 'DoorMonster'; Value: $0080),
    (Name: 'DoorKind'; Value: $0060),
    (Name: 'DoorSpeed'; Value: $0018),
    (Name: 'DoorDelayShift'; Value: 8),
    (Name: 'DoorMonsterShift'; Value: 7),
    (Name: 'DoorKindShift'; Value: 5),
    (Name: 'DoorSpeedShift'; Value: 3),
    (Name: 'LockedNKeys'; Value: $0200),
    (Name: 'LockedKey'; Value: $01c0),
    (Name: 'LockedKind'; Value: $0020),
    (Name: 'LockedSpeed'; Value: $0018),
    (Name: 'LockedNKeysShift'; Value: 9),
    (Name: 'LockedKeyShift'; Value: 6),
    (Name: 'LockedKindShift'; Value: 5),
    (Name: 'LockedSpeedShift'; Value: 3)
  );

{ TScriptGeneralizedConstants }

class function TScriptGeneralizedConstants.Count: Integer;
begin
  Result := Length(GENERALIZED_CONSTANTS);
end;

procedure TScriptGeneralizedConstants.Describe(const ATable: IScriptConstantTable);
var
  LIndex: Integer;
begin
  for LIndex := Low(GENERALIZED_CONSTANTS) to High(GENERALIZED_CONSTANTS) do
    ATable.AddInteger(GENERALIZED_CONSTANTS[LIndex].Name, GENERALIZED_CONSTANTS[LIndex].Value);
end;

end.