{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - TMaterialExpressionEvaluator              }
{                                                                              }
{  Port of the material of Doom 3 (id Software, GPL v3):                       }
{  renderer\Material.cpp (idMaterial::EvaluateRegisters). Copyright (C)        }
{  1999-2011 id Software LLC, a ZeniMax Media company.                         }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Material.Evaluator;

interface

uses
  System.SysUtils, DelphiDoom.Decl.Intf, DelphiDoom.Decl.Material.Types;

type
  /// <summary>
  ///   Runs the operations of a material over its registers. The time, the parameters and the sound level
  ///   come in a <c>TMaterialEvaluationInput</c> (no view or sound emitter), the tables from the finder.
  ///   Floating point exceptions are masked while it runs, so a division by zero is an infinity as in C.
  /// </summary>
  TMaterialExpressionEvaluator = class
  strict private
    FFinder: IDeclFinder;
    class function TruncateToInteger(const AValue: Single): Integer; static;
    class function FlagToValue(const AFlag: Boolean): Single; static; inline;
  public
    constructor Create(const AFinder: IDeclFinder);
    /// <summary>
    ///   <c>ARegisters</c> is resized to the number of the constants and filled; <c>AConstants</c> holds the
    ///   values the parse gave to the first registers (the predefined ones are overwritten from the input)
    /// </summary>
    procedure Evaluate(const AConstants: TArray<Single>; const AOps: TArray<TMaterialOp>;
      const AInput: TMaterialEvaluationInput; var ARegisters: TArray<Single>);
  end;

implementation

uses
  System.Math, DelphiDoom.Decl.Types, DelphiDoom.Decl.Table;

{ TMaterialExpressionEvaluator }

constructor TMaterialExpressionEvaluator.Create(const AFinder: IDeclFinder);
begin
  inherited Create;
  FFinder := AFinder;
end;

// (int) of a float as the x86 does it: what does not fit is the "integer indefinite" value
class function TMaterialExpressionEvaluator.TruncateToInteger(const AValue: Single): Integer;
begin
  if IsNan(AValue) or (AValue >= 2147483648.0) or (AValue < -2147483648.0) then
    Result := Low(Integer)
  else
    Result := Trunc(AValue);
end;

class function TMaterialExpressionEvaluator.FlagToValue(const AFlag: Boolean): Single;
begin
  if AFlag then
    Result := 1
  else
    Result := 0;
end;

procedure TMaterialExpressionEvaluator.Evaluate(const AConstants: TArray<Single>;
  const AOps: TArray<TMaterialOp>; const AInput: TMaterialEvaluationInput; var ARegisters: TArray<Single>);
var
  LIndex, LDivisor: Integer;
  LOp: TMaterialOp;
  LMask: TArithmeticExceptionMask;
  LDecl: IDecl;
  LTable: IDeclTable;
begin
  SetLength(ARegisters, Length(AConstants));
  // copy the material constants
  for LIndex := EXP_REG_NUM_PREDEFINED to High(AConstants) do
    ARegisters[LIndex] := AConstants[LIndex];

  // copy the local and global parameters
  ARegisters[EXP_REG_TIME] := AInput.Time;
  for LIndex := 0 to MAX_ENTITY_SHADER_PARMS - 1 do
    ARegisters[EXP_REG_PARM0 + LIndex] := AInput.Parms[LIndex];
  for LIndex := 0 to MAX_GLOBAL_SHADER_PARMS - 1 do
    ARegisters[EXP_REG_GLOBAL0 + LIndex] := AInput.GlobalParms[LIndex];

  LMask := SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]);
  try
    for LOp in AOps do
      case LOp.OpType of
        TMaterialOpType.Add:
          ARegisters[LOp.C] := ARegisters[LOp.A] + ARegisters[LOp.B];
        TMaterialOpType.Subtract:
          ARegisters[LOp.C] := ARegisters[LOp.A] - ARegisters[LOp.B];
        TMaterialOpType.Multiply:
          ARegisters[LOp.C] := ARegisters[LOp.A] * ARegisters[LOp.B];
        TMaterialOpType.Divide:
          ARegisters[LOp.C] := ARegisters[LOp.A] / ARegisters[LOp.B];
        TMaterialOpType.Modulo:
          begin
            LDivisor := TruncateToInteger(ARegisters[LOp.B]);
            if LDivisor = 0 then
              LDivisor := 1;
            // the C operator on the most negative value and -1 traps; here it is 0
            if LDivisor = -1 then
              ARegisters[LOp.C] := 0
            else
              ARegisters[LOp.C] := TruncateToInteger(ARegisters[LOp.A]) mod LDivisor;
          end;
        TMaterialOpType.Table:
          begin
            LDecl := FFinder.DeclByIndex(DECL_TABLE, LOp.A);
            if (not Assigned(LDecl)) or (not Supports(LDecl, IDeclTable, LTable)) then
              raise EDeclMaterialException.CreateFmt('no table with the index %d', [LOp.A]);
            ARegisters[LOp.C] := LTable.TableLookup(ARegisters[LOp.B]);
          end;
        TMaterialOpType.Sound:
          if AInput.HasSoundEmitter then
            ARegisters[LOp.C] := AInput.SoundAmplitude
          else
            ARegisters[LOp.C] := 0;
        TMaterialOpType.GreaterThan:
          ARegisters[LOp.C] := FlagToValue(ARegisters[LOp.A] > ARegisters[LOp.B]);
        TMaterialOpType.GreaterOrEqual:
          ARegisters[LOp.C] := FlagToValue(ARegisters[LOp.A] >= ARegisters[LOp.B]);
        TMaterialOpType.LessThan:
          ARegisters[LOp.C] := FlagToValue(ARegisters[LOp.A] < ARegisters[LOp.B]);
        TMaterialOpType.LessOrEqual:
          ARegisters[LOp.C] := FlagToValue(ARegisters[LOp.A] <= ARegisters[LOp.B]);
        TMaterialOpType.Equal:
          ARegisters[LOp.C] := FlagToValue(ARegisters[LOp.A] = ARegisters[LOp.B]);
        TMaterialOpType.NotEqual:
          ARegisters[LOp.C] := FlagToValue(ARegisters[LOp.A] <> ARegisters[LOp.B]);
        TMaterialOpType.LogicalAnd:
          ARegisters[LOp.C] := FlagToValue((ARegisters[LOp.A] <> 0) and (ARegisters[LOp.B] <> 0));
        TMaterialOpType.LogicalOr:
          ARegisters[LOp.C] := FlagToValue((ARegisters[LOp.A] <> 0) or (ARegisters[LOp.B] <> 0));
      end;
  finally
    SetExceptionMask(LMask);
  end;
end;

end.
