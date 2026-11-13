{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - TMaterialRegisterTable                    }
{                                                                              }
{  Port of the material of Doom 3 (id Software, GPL v3):                       }
{  renderer\Material.cpp (GetExpressionConstant, GetExpressionTemporary,       }
{  GetExpressionOp, EmitOp). Copyright (C) 1999-2011 id Software LLC, a        }
{  ZeniMax Media company.                                                      }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Material.Registers;

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Core.Intf, DelphiDoom.Decl.Material.Types;

type
  /// <summary>
  ///   The registers and the operations a material builds while it is parsed (the register part of
  ///   <c>mtrParsingData_t</c>): constants are shared, temporaries get one operation each, identity
  ///   operations are folded. A limit that is hit or a syntax error sets <c>Defaulted</c> (MF_DEFAULTED).
  /// </summary>
  TMaterialRegisterTable = class
  strict private
    FLog: IIdLibLog;
    FMaterialName: AnsiString;
    FIsTemporary: array[0..MAX_EXPRESSION_REGISTERS - 1] of Boolean;
    FValues: array[0..MAX_EXPRESSION_REGISTERS - 1] of Single;
    FOps: array[0..MAX_EXPRESSION_OPS - 1] of TMaterialOp;
    FNumRegisters: Integer;
    FNumOps: Integer;
    FDefaulted: Boolean;
    FRegistersAreConstant: Boolean;
    procedure Warn(const AMessage: string);
    function NewOp: Integer;
  public
    /// <summary>The first <c>EXP_REG_NUM_PREDEFINED</c> registers are temporaries (the parameters)</summary>
    constructor Create(const AMaterialName: AnsiString; const ALog: IIdLibLog; const AInitiallyConstant: Boolean);
    /// <summary>The register that holds the constant (shared); 0 and a warning when the table is full</summary>
    function GetConstant(const AValue: Single): Integer;
    function GetTemporary: Integer;
    /// <summary>EmitOp: the register of <c>A op B</c>, folding the identities of add and multiply</summary>
    function EmitOp(const AA, AB: Integer; const AOpType: TMaterialOpType): Integer;
    procedure MarkDefaulted;
    /// <summary>True if the register holds a constant that can be folded (it is not a temporary)</summary>
    function IsConstant(const ARegister: Integer): Boolean;
    function GetValue(const ARegister: Integer): Single;
    function GetOp(const AIndex: Integer): TMaterialOp;
    /// <summary>Copies what the parse made</summary>
    function CopyValues: TArray<Single>;
    function CopyOps: TArray<TMaterialOp>;
    property NumRegisters: Integer read FNumRegisters;
    property NumOps: Integer read FNumOps;
    property Defaulted: Boolean read FDefaulted;
    /// <summary>False as soon as an expression reads time, a parameter, a global or the sound</summary>
    property RegistersAreConstant: Boolean read FRegistersAreConstant write FRegistersAreConstant;
  end;

implementation

{ TMaterialRegisterTable }

constructor TMaterialRegisterTable.Create(const AMaterialName: AnsiString; const ALog: IIdLibLog;
  const AInitiallyConstant: Boolean);
var
  LIndex: Integer;
begin
  inherited Create;
  FMaterialName := AMaterialName;
  FLog := ALog;
  FNumRegisters := EXP_REG_NUM_PREDEFINED;
  FRegistersAreConstant := AInitiallyConstant;
  // they are not constants that can be folded
  for LIndex := 0 to EXP_REG_NUM_PREDEFINED - 1 do
    FIsTemporary[LIndex] := True;
end;

procedure TMaterialRegisterTable.Warn(const AMessage: string);
begin
  if Assigned(FLog) then
    FLog.Warning(AMessage);
end;

procedure TMaterialRegisterTable.MarkDefaulted;
begin
  FDefaulted := True;
end;

function TMaterialRegisterTable.IsConstant(const ARegister: Integer): Boolean;
begin
  Result := not FIsTemporary[ARegister];
end;

function TMaterialRegisterTable.GetValue(const ARegister: Integer): Single;
begin
  Result := FValues[ARegister];
end;

function TMaterialRegisterTable.GetOp(const AIndex: Integer): TMaterialOp;
begin
  Result := FOps[AIndex];
end;

function TMaterialRegisterTable.GetConstant(const AValue: Single): Integer;
var
  LIndex: Integer;
begin
  for LIndex := EXP_REG_NUM_PREDEFINED to FNumRegisters - 1 do
    if (not FIsTemporary[LIndex]) and (FValues[LIndex] = AValue) then
      Exit(LIndex);
  if FNumRegisters = MAX_EXPRESSION_REGISTERS then
  begin
    Warn(Format('GetExpressionConstant: material ''%s'' hit MAX_EXPRESSION_REGISTERS', [string(FMaterialName)]));
    FDefaulted := True;
    Exit(0);
  end;
  FIsTemporary[FNumRegisters] := False;
  FValues[FNumRegisters] := AValue;
  Result := FNumRegisters;
  Inc(FNumRegisters);
end;

function TMaterialRegisterTable.GetTemporary: Integer;
begin
  if FNumRegisters = MAX_EXPRESSION_REGISTERS then
  begin
    Warn(Format('GetExpressionTemporary: material ''%s'' hit MAX_EXPRESSION_REGISTERS', [string(FMaterialName)]));
    FDefaulted := True;
    Exit(0);
  end;
  FIsTemporary[FNumRegisters] := True;
  Result := FNumRegisters;
  Inc(FNumRegisters);
end;

function TMaterialRegisterTable.NewOp: Integer;
begin
  if FNumOps = MAX_EXPRESSION_OPS then
  begin
    Warn(Format('GetExpressionOp: material ''%s'' hit MAX_EXPRESSION_OPS', [string(FMaterialName)]));
    FDefaulted := True;
    // the original hands out the first operation again
    Exit(0);
  end;
  Result := FNumOps;
  Inc(FNumOps);
end;

function TMaterialRegisterTable.EmitOp(const AA, AB: Integer; const AOpType: TMaterialOpType): Integer;
var
  LOp: Integer;
begin
  // optimize away identity operations
  if AOpType = TMaterialOpType.Add then
  begin
    if IsConstant(AA) and (FValues[AA] = 0) then
      Exit(AB);
    if IsConstant(AB) and (FValues[AB] = 0) then
      Exit(AA);
    if IsConstant(AA) and IsConstant(AB) then
      Exit(GetConstant(FValues[AA] + FValues[AB]));
  end;
  if AOpType = TMaterialOpType.Multiply then
  begin
    if IsConstant(AA) and (FValues[AA] = 1) then
      Exit(AB);
    if IsConstant(AA) and (FValues[AA] = 0) then
      Exit(AA);
    if IsConstant(AB) and (FValues[AB] = 1) then
      Exit(AA);
    if IsConstant(AB) and (FValues[AB] = 0) then
      Exit(AB);
    if IsConstant(AA) and IsConstant(AB) then
      Exit(GetConstant(FValues[AA] * FValues[AB]));
  end;

  LOp := NewOp;
  FOps[LOp].OpType := AOpType;
  FOps[LOp].A := AA;
  FOps[LOp].B := AB;
  FOps[LOp].C := GetTemporary;
  Result := FOps[LOp].C;
end;

function TMaterialRegisterTable.CopyValues: TArray<Single>;
var
  LIndex: Integer;
begin
  SetLength(Result, FNumRegisters);
  for LIndex := 0 to FNumRegisters - 1 do
    Result[LIndex] := FValues[LIndex];
end;

function TMaterialRegisterTable.CopyOps: TArray<TMaterialOp>;
var
  LIndex: Integer;
begin
  SetLength(Result, FNumOps);
  for LIndex := 0 to FNumOps - 1 do
    Result[LIndex] := FOps[LIndex];
end;

end.
