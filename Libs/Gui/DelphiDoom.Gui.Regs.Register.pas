{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - TGuiRegister                                      }
{                                                                              }
{  Port of the GUI of Doom 3 (id Software, GPL v3): ui\RegExp.h, RegExp.cpp    }
{  (idRegister). Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media      }
{  company.                                                                    }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Regs.Register;

interface

uses
  DelphiDoom.Gui.WinVar.Base, DelphiDoom.Gui.Regs.Types;

type
  /// <summary>
  ///   idRegister: the registers that hold the value of a variable of a window while the expressions
  ///   are evaluated. The variable is not owned (the window owns it).
  /// </summary>
  TGuiRegister = class
  strict private
    FEnabled: Boolean;
    FRegisterType: TGuiRegisterType;
    FName: AnsiString;
    FRegCount: Integer;
    FRegs: array[0..3] of Word;
    FVariable: TGuiWinVar;
    function GetRegs(const AIndex: Integer): Word;
    procedure SetRegs(const AIndex: Integer; const AValue: Word);
    function IsActive: Boolean;
  public
    constructor Create(const AName: AnsiString; const AType: TGuiRegisterType);
    /// <summary>The variable to the registers (nothing if disabled, bound to the state or no longer evaluated)</summary>
    procedure SetToRegs(var ARegisters: TGuiRegisters);
    /// <summary>The registers to the variable (same conditions)</summary>
    procedure GetFromRegs(const ARegisters: TGuiRegisters);
    procedure CopyRegs(const ASource: TGuiRegister);
    property Enabled: Boolean read FEnabled write FEnabled;
    property RegisterType: TGuiRegisterType read FRegisterType;
    property Name: AnsiString read FName;
    property RegCount: Integer read FRegCount;
    property Regs[const AIndex: Integer]: Word read GetRegs write SetRegs;
    property Variable: TGuiWinVar read FVariable write FVariable;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Math.Vec2, DelphiDoom.IdLib.Math.Vec3, DelphiDoom.IdLib.Math.Vec4,
  DelphiDoom.Gui.Rectangle, DelphiDoom.Gui.Window.Types, DelphiDoom.Gui.WinVar.Bool, DelphiDoom.Gui.WinVar.Float,
  DelphiDoom.Gui.WinVar.Int, DelphiDoom.Gui.WinVar.Rectangle, DelphiDoom.Gui.WinVar.Vec2,
  DelphiDoom.Gui.WinVar.Vec3, DelphiDoom.Gui.WinVar.Vec4;

const
  SBadRegisterType = 'idRegister: bad reg type';

constructor TGuiRegister.Create(const AName: AnsiString; const AType: TGuiRegisterType);
begin
  inherited Create;
  FName := AName;
  FRegisterType := AType;
  FRegCount := GUI_REGISTER_COUNT[AType];
  FEnabled := AType <> rtString;
end;

function TGuiRegister.GetRegs(const AIndex: Integer): Word;
begin
  Result := FRegs[AIndex];
end;

procedure TGuiRegister.SetRegs(const AIndex: Integer; const AValue: Word);
begin
  FRegs[AIndex] := AValue;
end;

function TGuiRegister.IsActive: Boolean;
begin
  Result := FEnabled and Assigned(FVariable) and (not Assigned(FVariable.BoundDict)) and FVariable.Eval;
end;

procedure TGuiRegister.SetToRegs(var ARegisters: TGuiRegisters);
var
  LValue: TIdVec4;
  LIndex: Integer;
begin
  if not IsActive then
    Exit;
  LValue.Zero;
  case FRegisterType of
    rtVec4:
      LValue := (FVariable as TGuiWinVec4).Value;
    rtRectangle:
      LValue := (FVariable as TGuiWinRectangle).Value.ToVec4;
    rtVec2:
      begin
        LValue.X := (FVariable as TGuiWinVec2).Value.X;
        LValue.Y := (FVariable as TGuiWinVec2).Value.Y;
      end;
    rtVec3:
      begin
        LValue.X := (FVariable as TGuiWinVec3).Value.X;
        LValue.Y := (FVariable as TGuiWinVec3).Value.Y;
        LValue.Z := (FVariable as TGuiWinVec3).Value.Z;
      end;
    rtFloat:
      LValue.X := (FVariable as TGuiWinFloat).Value;
    rtInt:
      LValue.X := (FVariable as TGuiWinInt).Value;
    rtBool:
      LValue.X := (FVariable as TGuiWinBool).X;
  else
    raise EGuiWindowException.Create(SBadRegisterType);
  end;
  for LIndex := 0 to FRegCount - 1 do
    ARegisters[FRegs[LIndex]] := LValue[LIndex];
end;

procedure TGuiRegister.GetFromRegs(const ARegisters: TGuiRegisters);
var
  LValue: TIdVec4;
  LIndex: Integer;
  LNumber: Single;
begin
  if not IsActive then
    Exit;
  LValue.Zero;
  for LIndex := 0 to FRegCount - 1 do
    LValue[LIndex] := ARegisters[FRegs[LIndex]];
  LNumber := LValue.X;
  case FRegisterType of
    rtVec4:
      (FVariable as TGuiWinVec4).Value := LValue;
    rtRectangle:
      (FVariable as TGuiWinRectangle).Value := TGuiRectangle.FromVec4(LValue);
    rtVec2:
      (FVariable as TGuiWinVec2).Value := LValue.ToVec2;
    rtVec3:
      (FVariable as TGuiWinVec3).Value := LValue.ToVec3;
    rtFloat:
      (FVariable as TGuiWinFloat).Value := LNumber;
    rtInt:
      // an int variable takes the float truncated (a value out of range is $80000000 as cvttss2si gives)
      if (LNumber >= 2147483648.0) or (LNumber < -2147483648.0) or (LNumber <> LNumber) then
        (FVariable as TGuiWinInt).Value := Low(Integer)
      else
        (FVariable as TGuiWinInt).Value := Trunc(LNumber);
    rtBool:
      (FVariable as TGuiWinBool).Value := LNumber <> 0.0;
  else
    raise EGuiWindowException.Create(SBadRegisterType);
  end;
end;

procedure TGuiRegister.CopyRegs(const ASource: TGuiRegister);
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    FRegs[LIndex] := ASource.FRegs[LIndex];
end;

end.
