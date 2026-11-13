{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - TGuiRegisterList                                  }
{                                                                              }
{  Port of the GUI of Doom 3 (id Software, GPL v3): ui\RegExp.h, RegExp.cpp    }
{  (idRegisterList). Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media  }
{  company.                                                                    }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Regs.RegisterList;

interface

uses
  System.Generics.Collections, DelphiDoom.IdLib.Math.Vec4, DelphiDoom.Scanner.IdParser,
  DelphiDoom.Gui.WinVar.Base, DelphiDoom.Gui.Regs.Types, DelphiDoom.Gui.Regs.Intf, DelphiDoom.Gui.Regs.Register;

type
  /// <summary>
  ///   idRegisterList: the registers of a window by name (names compare without case). It owns the
  ///   registers, not the variables. Not ported: the save game and demo file functions.
  /// </summary>
  TGuiRegisterList = class
  strict private
    FRegisters: TObjectList<TGuiRegister>;
    FIndexByName: TDictionary<AnsiString, Integer>;
    procedure ParseComponents(const ARegister: TGuiRegister; const AType: TGuiRegisterType;
      const ASource: TIdParser; const AOwner: IGuiRegisterOwner);
    function GetCount: Integer;
    function GetItems(const AIndex: Integer): TGuiRegister;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>
    ///   AddReg from a parser: a string register takes the next token (translated by the language
    ///   dictionary the first time), the others one expression per component separated by commas. A
    ///   register that exists keeps its place and takes the new variable and expressions.
    /// </summary>
    procedure AddReg(const AName: AnsiString; const AType: TGuiRegisterType; const ASource: TIdParser;
      const AOwner: IGuiRegisterOwner; const AVariable: TGuiWinVar); overload;
    /// <summary>AddReg from constants: only if the name is new</summary>
    procedure AddReg(const AName: AnsiString; const AType: TGuiRegisterType; const AData: TIdVec4;
      const AOwner: IGuiRegisterOwner; const AVariable: TGuiWinVar); overload;
    function FindReg(const AName: AnsiString): TGuiRegister;
    procedure SetToRegs(var ARegisters: TGuiRegisters);
    procedure GetFromRegs(const ARegisters: TGuiRegisters);
    procedure Reset;
    property Count: Integer read GetCount;
    property Items[const AIndex: Integer]: TGuiRegister read GetItems; default;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Text.Token;

constructor TGuiRegisterList.Create;
begin
  inherited Create;
  FRegisters := TObjectList<TGuiRegister>.Create(True);
  FIndexByName := TDictionary<AnsiString, Integer>.Create;
end;

destructor TGuiRegisterList.Destroy;
begin
  FIndexByName.Free;
  FRegisters.Free;
  inherited Destroy;
end;

function TGuiRegisterList.GetCount: Integer;
begin
  Result := FRegisters.Count;
end;

function TGuiRegisterList.GetItems(const AIndex: Integer): TGuiRegister;
begin
  Result := FRegisters[AIndex];
end;

function TGuiRegisterList.FindReg(const AName: AnsiString): TGuiRegister;
var
  LIndex: Integer;
begin
  if FIndexByName.TryGetValue(AnsiString(LowerCase(string(AName))), LIndex) then
    Result := FRegisters[LIndex]
  else
    Result := nil;
end;

procedure TGuiRegisterList.ParseComponents(const ARegister: TGuiRegister; const AType: TGuiRegisterType;
  const ASource: TIdParser; const AOwner: IGuiRegisterOwner);
var
  LIndex: Integer;
  LCount: Integer;
begin
  LCount := GUI_REGISTER_COUNT[AType];
  for LIndex := 0 to LCount - 1 do
  begin
    ARegister.Regs[LIndex] := Word(AOwner.ParseExpression(ASource));
    if LIndex < LCount - 1 then
      ASource.ExpectTokenString(',');
  end;
end;

procedure TGuiRegisterList.AddReg(const AName: AnsiString; const AType: TGuiRegisterType; const ASource: TIdParser;
  const AOwner: IGuiRegisterOwner; const AVariable: TGuiWinVar);
var
  LRegister: TGuiRegister;
  LToken: TIdToken;
begin
  LRegister := FindReg(AName);
  LToken := TIdToken.Create;
  if not Assigned(LRegister) then
  begin
    LRegister := TGuiRegister.Create(AName, AType);
    LRegister.Variable := AVariable;
    if AType = rtString then
    begin
      if ASource.ReadToken(LToken) then
        AOwner.InitVar(AVariable, AOwner.TranslateString(LToken.Text));
    end
    else
      ParseComponents(LRegister, AType, ASource, AOwner);
    FIndexByName.AddOrSetValue(AnsiString(LowerCase(string(AName))), FRegisters.Add(LRegister));
  end
  else
  begin
    LRegister.Variable := AVariable;
    if AType = rtString then
    begin
      if ASource.ReadToken(LToken) then
        AOwner.InitVar(AVariable, LToken.Text);
    end
    else
      ParseComponents(LRegister, AType, ASource, AOwner);
  end;
end;

procedure TGuiRegisterList.AddReg(const AName: AnsiString; const AType: TGuiRegisterType; const AData: TIdVec4;
  const AOwner: IGuiRegisterOwner; const AVariable: TGuiWinVar);
var
  LRegister: TGuiRegister;
  LIndex: Integer;
begin
  if Assigned(FindReg(AName)) then
    Exit;
  LRegister := TGuiRegister.Create(AName, AType);
  LRegister.Variable := AVariable;
  for LIndex := 0 to GUI_REGISTER_COUNT[AType] - 1 do
    LRegister.Regs[LIndex] := Word(AOwner.ExpressionConstant(AData[LIndex]));
  FIndexByName.AddOrSetValue(AnsiString(LowerCase(string(AName))), FRegisters.Add(LRegister));
end;

procedure TGuiRegisterList.SetToRegs(var ARegisters: TGuiRegisters);
var
  LIndex: Integer;
begin
  for LIndex := 0 to FRegisters.Count - 1 do
    FRegisters[LIndex].SetToRegs(ARegisters);
end;

procedure TGuiRegisterList.GetFromRegs(const ARegisters: TGuiRegisters);
var
  LIndex: Integer;
begin
  for LIndex := 0 to FRegisters.Count - 1 do
    FRegisters[LIndex].GetFromRegs(ARegisters);
end;

procedure TGuiRegisterList.Reset;
begin
  FRegisters.Clear;
  FIndexByName.Clear;
end;

end.
