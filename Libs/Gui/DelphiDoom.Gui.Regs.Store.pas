{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - TGuiExpressionStore                               }
{                                                                              }
{  Port of the GUI of Doom 3 (id Software, GPL v3): ui\Window.cpp              }
{  (ExpressionConstant, ExpressionTemporary, ExpressionOp, EmitOp).            }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Regs.Store;

interface

uses
  System.Generics.Collections, DelphiDoom.IdLib.Core.Intf, DelphiDoom.Gui.Regs.Types;

type
  /// <summary>
  ///   The registers and operations of the expressions of one window (<c>expressionRegisters</c>,
  ///   <c>ops</c> and the <c>registerIsTemporary</c> flags, which the original keeps in a static array
  ///   shared by all windows and saves around each child; here each window has its own). Constants are
  ///   shared, every operation gets a new temporary (the identity folding is commented out in the original).
  /// </summary>
  TGuiExpressionStore = class
  strict private
    FLog: IIdLibLog;
    FSourceFile: AnsiString;
    FRegisters: TList<Single>;
    FIsTemporary: array[0..GUI_MAX_EXPRESSION_REGISTERS - 1] of Boolean;
    FOps: TList<TGuiOp>;
    procedure Warn(const AText: string);
    function GetOps(const AIndex: Integer): TGuiOp;
    procedure SetOps(const AIndex: Integer; const AValue: TGuiOp);
    function GetRegisterCount: Integer;
    function GetOpCount: Integer;
    function GetRegisterValue(const AIndex: Integer): Single;
  public
    constructor Create(const ASourceFile: AnsiString; const ALog: IIdLibLog);
    destructor Destroy; override;
    procedure Clear;
    /// <summary>
    ///   A register with the constant (shared with an equal one). The first constant is preceded by a filler
    ///   in register 0 (-9999999). At the limit: a warning and register 0.
    /// </summary>
    function ExpressionConstant(const AValue: Single): Integer;
    function ExpressionTemporary: Integer;
    /// <summary>EmitOp: a new operation and its temporary; <c>AOpIndex</c> is where the operation is</summary>
    function EmitOp(const AA, AB: Integer; const AOpType: TGuiOpType; out AOpIndex: Integer): Integer; overload;
    function EmitOp(const AA, AB: Integer; const AOpType: TGuiOpType): Integer; overload;
    /// <summary>The operation that EmitOp of a full table returns (the first one, as the original does)</summary>
    property Ops[const AIndex: Integer]: TGuiOp read GetOps write SetOps;
    property OpCount: Integer read GetOpCount;
    property RegisterCount: Integer read GetRegisterCount;
    property RegisterValue[const AIndex: Integer]: Single read GetRegisterValue;
    function RegisterIsTemporary(const AIndex: Integer): Boolean;
  end;

implementation

uses
  System.SysUtils;

constructor TGuiExpressionStore.Create(const ASourceFile: AnsiString; const ALog: IIdLibLog);
begin
  inherited Create;
  FSourceFile := ASourceFile;
  FLog := ALog;
  FRegisters := TList<Single>.Create;
  FOps := TList<TGuiOp>.Create;
end;

destructor TGuiExpressionStore.Destroy;
begin
  FOps.Free;
  FRegisters.Free;
  inherited Destroy;
end;

procedure TGuiExpressionStore.Warn(const AText: string);
begin
  if Assigned(FLog) then
    FLog.Warning(AText);
end;

procedure TGuiExpressionStore.Clear;
begin
  FRegisters.Clear;
  FOps.Clear;
end;

function TGuiExpressionStore.GetOps(const AIndex: Integer): TGuiOp;
begin
  Result := FOps[AIndex];
end;

procedure TGuiExpressionStore.SetOps(const AIndex: Integer; const AValue: TGuiOp);
begin
  FOps[AIndex] := AValue;
end;

function TGuiExpressionStore.GetRegisterCount: Integer;
begin
  Result := FRegisters.Count;
end;

function TGuiExpressionStore.GetOpCount: Integer;
begin
  Result := FOps.Count;
end;

function TGuiExpressionStore.GetRegisterValue(const AIndex: Integer): Single;
begin
  Result := FRegisters[AIndex];
end;

function TGuiExpressionStore.RegisterIsTemporary(const AIndex: Integer): Boolean;
begin
  Result := FIsTemporary[AIndex];
end;

function TGuiExpressionStore.ExpressionConstant(const AValue: Single): Integer;
var
  LIndex: Integer;
begin
  for LIndex := WEXP_REG_NUM_PREDEFINED to FRegisters.Count - 1 do
    if (not FIsTemporary[LIndex]) and (FRegisters[LIndex] = AValue) then
      Exit(LIndex);
  if FRegisters.Count = GUI_MAX_EXPRESSION_REGISTERS then
  begin
    Warn(Format('expressionConstant: gui %s hit MAX_EXPRESSION_REGISTERS', [string(FSourceFile)]));
    Exit(0);
  end;
  // the original fills the registers up to the first predefined one that is missing
  while FRegisters.Count < WEXP_REG_NUM_PREDEFINED do
    FRegisters.Add(-9999999);
  Result := FRegisters.Add(AValue);
  FIsTemporary[Result] := False;
end;

function TGuiExpressionStore.ExpressionTemporary: Integer;
begin
  if FRegisters.Count = GUI_MAX_EXPRESSION_REGISTERS then
  begin
    Warn(Format('expressionTemporary: gui %s hit MAX_EXPRESSION_REGISTERS', [string(FSourceFile)]));
    Exit(0);
  end;
  Result := FRegisters.Count;
  FIsTemporary[Result] := True;
  FRegisters.Add(0);
end;

function TGuiExpressionStore.EmitOp(const AA, AB: Integer; const AOpType: TGuiOpType; out AOpIndex: Integer): Integer;
var
  LOp: TGuiOp;
begin
  if FOps.Count = GUI_MAX_EXPRESSION_OPS then
  begin
    Warn(Format('expressionOp: gui %s hit MAX_EXPRESSION_OPS', [string(FSourceFile)]));
    AOpIndex := 0;
    LOp := FOps[0];
  end
  else
  begin
    LOp := Default(TGuiOp);
    AOpIndex := FOps.Add(LOp);
  end;
  LOp.OpType := AOpType;
  LOp.A := AA;
  LOp.B := AB;
  LOp.C := ExpressionTemporary;
  FOps[AOpIndex] := LOp;
  Result := LOp.C;
end;

function TGuiExpressionStore.EmitOp(const AA, AB: Integer; const AOpType: TGuiOpType): Integer;
var
  LIndex: Integer;
begin
  Result := EmitOp(AA, AB, AOpType, LIndex);
end;

end.
