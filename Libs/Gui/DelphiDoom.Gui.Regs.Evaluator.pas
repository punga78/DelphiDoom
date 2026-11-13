{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - TGuiExpressionEvaluator                           }
{                                                                              }
{  Port of the GUI of Doom 3 (id Software, GPL v3): ui\Window.cpp              }
{  (idWindow::EvaluateRegisters). Copyright (C) 1999-2011 id Software LLC, a   }
{  ZeniMax Media company.                                                      }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Regs.Evaluator;

interface

uses
  DelphiDoom.IdLib.Core.Intf, DelphiDoom.Gui.Regs.Types, DelphiDoom.Gui.Regs.Intf, DelphiDoom.Gui.Regs.Store;

type
  /// <summary>
  ///   EvaluateRegisters: copies the constants, sets the time register and runs the operations in
  ///   order. A vector read with an index uses the intended component (the original reads the
  ///   stack: <c>((idVec4&amp;)var)[n]</c> casts the pointer variable, not the vector).
  /// </summary>
  TGuiExpressionEvaluator = class
  strict private
    FTables: IGuiTables;
    FLog: IIdLibLog;
  public
    constructor Create(const ATables: IGuiTables; const ALog: IIdLibLog);
    procedure Evaluate(const AStore: TGuiExpressionStore; const ATime: Integer; var ARegisters: TGuiRegisters;
      const AWindowName, ASourceFile: AnsiString);
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Scanner.IdCNumbers, DelphiDoom.IdLib.Math.Vec4, DelphiDoom.Gui.WinVar.Base,
  DelphiDoom.Gui.WinVar.Bool, DelphiDoom.Gui.WinVar.Float, DelphiDoom.Gui.WinVar.Int, DelphiDoom.Gui.WinVar.Vec4,
  DelphiDoom.Gui.Window.Types;

function FloatToInt(const AValue: Single): Integer;
begin
  // what cvttss2si gives for a value that does not fit
  if (AValue <> AValue) or (AValue >= 2147483648.0) or (AValue < -2147483648.0) then
    Result := Low(Integer)
  else
    Result := Trunc(AValue);
end;

function BoolToFloat(const AValue: Boolean): Single;
begin
  if AValue then
    Result := 1.0
  else
    Result := 0.0;
end;

constructor TGuiExpressionEvaluator.Create(const ATables: IGuiTables; const ALog: IIdLibLog);
begin
  inherited Create;
  FTables := ATables;
  FLog := ALog;
end;

procedure TGuiExpressionEvaluator.Evaluate(const AStore: TGuiExpressionStore; const ATime: Integer;
  var ARegisters: TGuiRegisters; const AWindowName, ASourceFile: AnsiString);
var
  LIndex: Integer;
  LOp: TGuiOp;
  LDivisor: Integer;
  LValue: Single;
begin
  for LIndex := WEXP_REG_NUM_PREDEFINED to AStore.RegisterCount - 1 do
    ARegisters[LIndex] := AStore.RegisterValue[LIndex];
  ARegisters[WEXP_REG_TIME] := ATime;
  for LIndex := 0 to AStore.OpCount - 1 do
  begin
    LOp := AStore.Ops[LIndex];
    if LOp.B = -2 then
      Continue;
    case LOp.OpType of
      otAdd:
        ARegisters[LOp.C] := ARegisters[LOp.A] + ARegisters[LOp.B];
      otSubtract:
        ARegisters[LOp.C] := ARegisters[LOp.A] - ARegisters[LOp.B];
      otMultiply:
        ARegisters[LOp.C] := ARegisters[LOp.A] * ARegisters[LOp.B];
      otDivide:
        if ARegisters[LOp.B] = 0.0 then
        begin
          if Assigned(FLog) then
            FLog.Warning(Format('Divide by zero in window ''%s'' in %s', [string(AWindowName), string(ASourceFile)]));
          ARegisters[LOp.C] := ARegisters[LOp.A];
        end
        else
          ARegisters[LOp.C] := ARegisters[LOp.A] / ARegisters[LOp.B];
      otMod:
        begin
          LDivisor := FloatToInt(ARegisters[LOp.B]);
          if LDivisor = 0 then
            LDivisor := 1;
          if LDivisor = -1 then
            ARegisters[LOp.C] := 0
          else
            ARegisters[LOp.C] := FloatToInt(ARegisters[LOp.A]) mod LDivisor;
        end;
      otTable:
        if Assigned(FTables) then
          ARegisters[LOp.C] := FTables.Lookup(LOp.A, ARegisters[LOp.B])
        else
          ARegisters[LOp.C] := 0;
      otGt:
        ARegisters[LOp.C] := BoolToFloat(ARegisters[LOp.A] > ARegisters[LOp.B]);
      otGe:
        ARegisters[LOp.C] := BoolToFloat(ARegisters[LOp.A] >= ARegisters[LOp.B]);
      otLt:
        ARegisters[LOp.C] := BoolToFloat(ARegisters[LOp.A] < ARegisters[LOp.B]);
      otLe:
        ARegisters[LOp.C] := BoolToFloat(ARegisters[LOp.A] <= ARegisters[LOp.B]);
      otEq:
        ARegisters[LOp.C] := BoolToFloat(ARegisters[LOp.A] = ARegisters[LOp.B]);
      otNe:
        ARegisters[LOp.C] := BoolToFloat(ARegisters[LOp.A] <> ARegisters[LOp.B]);
      otCond:
        if ARegisters[LOp.A] <> 0.0 then
          ARegisters[LOp.C] := ARegisters[LOp.B]
        else
          ARegisters[LOp.C] := ARegisters[LOp.D];
      otAnd:
        ARegisters[LOp.C] := BoolToFloat((ARegisters[LOp.A] <> 0.0) and (ARegisters[LOp.B] <> 0.0));
      otOr:
        ARegisters[LOp.C] := BoolToFloat((ARegisters[LOp.A] <> 0.0) or (ARegisters[LOp.B] <> 0.0));
      otVar:
        if not Assigned(LOp.Variable) then
          ARegisters[LOp.C] := 0.0
        else if (LOp.B >= 0) and (ARegisters[LOp.B] >= 0) and (ARegisters[LOp.B] < 4) and
          (LOp.Variable is TGuiWinVec4) then
        begin
          LValue := TGuiWinVec4(LOp.Variable).Value[Trunc(ARegisters[LOp.B])];
          ARegisters[LOp.C] := LValue;
        end
        else
          ARegisters[LOp.C] := LOp.Variable.X;
      otVars:
        if Assigned(LOp.Variable) then
          ARegisters[LOp.C] := TIdCNumbers.Atof(LOp.Variable.AsText)
        else
          ARegisters[LOp.C] := 0;
      otVarf:
        if Assigned(LOp.Variable) then
          ARegisters[LOp.C] := TGuiWinFloat(LOp.Variable).Value
        else
          ARegisters[LOp.C] := 0;
      otVari:
        if Assigned(LOp.Variable) then
          ARegisters[LOp.C] := TGuiWinInt(LOp.Variable).Value
        else
          ARegisters[LOp.C] := 0;
      otVarb:
        if Assigned(LOp.Variable) then
          ARegisters[LOp.C] := BoolToFloat(TGuiWinBool(LOp.Variable).Value)
        else
          ARegisters[LOp.C] := 0;
    else
      raise EGuiWindowException.Create('R_EvaluateExpression: bad opcode');
    end;
  end;
end;

end.
