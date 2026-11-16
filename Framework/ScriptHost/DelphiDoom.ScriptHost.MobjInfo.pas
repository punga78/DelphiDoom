{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - the mobjinfo functions of PS_GAME                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  IsValidMobjType, the two editor number functions, GetMobjInfoCount,         }
{  GetMobjInfoFlag and the 65 GetMobjInfo<Field> that are rows of              }
{  SCRIPT_MOBJINFO_FUNCTIONS: one small object for each row (the same method   }
{  with a different Self) instead of one routine for each field (the          }
{  PS_*MobjInfo*, PS_IsValidMobjType... of psi_game.pas).                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.MobjInfo;

interface

uses
  System.Generics.Collections,
  DelphiDoom.ScriptHost.Intf,
  DelphiDoom.ScriptHost.MobjInfo.Intf,
  DelphiDoom.ScriptHost.Types;

type
  /// <summary>The mobjinfo functions of the unit PS_GAME (called with the object as Self)</summary>
  TScriptMobjInfo = class(TInterfacedObject, IScriptMobjInfo, IScriptFunctionSection)
  strict private
    FSource: IScriptMobjInfoSource;
    FGame: TScriptGame;
    FBindings: TObjectList<TObject>;
    FNumberBindings: array[TScriptMobjInfoField] of TObject;
    FTextBindings: array[TScriptMobjInfoField] of TObject;
  public
    /// <exception cref="EArgumentNilException">If the source is nil</exception>
    constructor Create(const ASource: IScriptMobjInfoSource; const AGame: TScriptGame);
    destructor Destroy; override;
    procedure Describe(const ATable: IScriptFunctionTable);
    function IsValidMobjType(const AType: Integer): Boolean;
    /// <summary>The type of an editor number, SCRIPT_INVALID_ID for a negative one or for a number that is no type</summary>
    function GetMobjTypeFromEditorNumber(const ANumber: Integer): Integer;
    function GetEditorNumberFromMobjType(const AType: Integer): Integer;
    function GetMobjInfoCount: Integer;
    function GetNumber(const AField: TScriptMobjInfoField; const AType: Integer): Integer;
    function GetText(const AField: TScriptMobjInfoField; const AType: Integer): string;
    function GetMobjInfoFlag(const AType: Integer; const AFlag: Integer): Boolean;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.ScriptHost.MobjInfo.Table,
  DelphiDoom.ScriptHost.World.Intf;

type
  /// <summary>The function of a field that is a number: the field is the one of the object that is called</summary>
  TScriptMobjInfoNumberBinding = class(TObject)
  strict private
    FOwner: TScriptMobjInfo;
    FField: TScriptMobjInfoField;
  public
    constructor Create(const AOwner: TScriptMobjInfo; const AField: TScriptMobjInfoField);
    function Value(const AType: Integer): Integer;
  end;

  /// <summary>The function of a field that is a text or a sound</summary>
  TScriptMobjInfoTextBinding = class(TObject)
  strict private
    FOwner: TScriptMobjInfo;
    FField: TScriptMobjInfoField;
  public
    constructor Create(const AOwner: TScriptMobjInfo; const AField: TScriptMobjInfoField);
    function Value(const AType: Integer): string;
  end;

{ TScriptMobjInfoNumberBinding }

constructor TScriptMobjInfoNumberBinding.Create(const AOwner: TScriptMobjInfo;
  const AField: TScriptMobjInfoField);
begin
  inherited Create;
  FOwner := AOwner;
  FField := AField;
end;

function TScriptMobjInfoNumberBinding.Value(const AType: Integer): Integer;
begin
  Result := FOwner.GetNumber(FField, AType);
end;

{ TScriptMobjInfoTextBinding }

constructor TScriptMobjInfoTextBinding.Create(const AOwner: TScriptMobjInfo;
  const AField: TScriptMobjInfoField);
begin
  inherited Create;
  FOwner := AOwner;
  FField := AField;
end;

function TScriptMobjInfoTextBinding.Value(const AType: Integer): string;
begin
  Result := FOwner.GetText(FField, AType);
end;

{ TScriptMobjInfo }

constructor TScriptMobjInfo.Create(const ASource: IScriptMobjInfoSource;
  const AGame: TScriptGame);
begin
  inherited Create;
  if not Assigned(ASource) then
    raise EArgumentNilException.Create('ASource');
  FSource := ASource;
  FGame := AGame;
  FBindings := TObjectList<TObject>.Create(True);
end;

destructor TScriptMobjInfo.Destroy;
begin
  FBindings.Free;
  inherited Destroy;
end;

procedure TScriptMobjInfo.Describe(const ATable: IScriptFunctionTable);
var
  LRow: TScriptMobjInfoFunction;
  LNumber: TScriptMobjInfoNumberBinding;
  LText: TScriptMobjInfoTextBinding;
begin
  ATable.AddMethod('function IsValidMobjType(const typ: integer): boolean;', Self,
    @TScriptMobjInfo.IsValidMobjType);
  ATable.AddMethod('function GetMobjTypeFromEditorNumber(const en: integer): integer;', Self,
    @TScriptMobjInfo.GetMobjTypeFromEditorNumber);
  ATable.AddMethod('function GetEditorNumberFromMobjType(const typ: integer): integer;', Self,
    @TScriptMobjInfo.GetEditorNumberFromMobjType);
  ATable.AddMethod('function GetMobjInfoCount: integer;', Self, @TScriptMobjInfo.GetMobjInfoCount);
  for LRow in SCRIPT_MOBJINFO_FUNCTIONS do
  begin
    if not (FGame in LRow.Games) then
      Continue;
    if LRow.Shape = msFlag then
      ATable.AddMethod(LRow.Declaration, Self, @TScriptMobjInfo.GetMobjInfoFlag)
    else if SCRIPT_MOBJINFO_FIELDS[LRow.Field].Kind in [mikNumber, mikInheritance] then
    begin
      // the object of a field lives as long as this one: the interpreters keep their Self, and
      // Describe can be asked again (GetMobjInfoName2 shares the object of GetMobjInfoName)
      if not Assigned(FNumberBindings[LRow.Field]) then
      begin
        LNumber := TScriptMobjInfoNumberBinding.Create(Self, LRow.Field);
        FBindings.Add(LNumber);
        FNumberBindings[LRow.Field] := LNumber;
      end;
      ATable.AddMethod(LRow.Declaration, FNumberBindings[LRow.Field],
        @TScriptMobjInfoNumberBinding.Value);
    end
    else
    begin
      if not Assigned(FTextBindings[LRow.Field]) then
      begin
        LText := TScriptMobjInfoTextBinding.Create(Self, LRow.Field);
        FBindings.Add(LText);
        FTextBindings[LRow.Field] := LText;
      end;
      ATable.AddMethod(LRow.Declaration, FTextBindings[LRow.Field],
        @TScriptMobjInfoTextBinding.Value);
    end;
  end;
end;

function TScriptMobjInfo.IsValidMobjType(const AType: Integer): Boolean;
begin
  Result := (AType >= 0) and (AType < FSource.Count);
end;

function TScriptMobjInfo.GetMobjTypeFromEditorNumber(const ANumber: Integer): Integer;
begin
  if ANumber < 0 then
  begin
    Result := SCRIPT_INVALID_ID;
    Exit;
  end;
  Result := FSource.TypeFromEditorNumber(ANumber);
  if not IsValidMobjType(Result) then
    Result := SCRIPT_INVALID_ID;
end;

function TScriptMobjInfo.GetEditorNumberFromMobjType(const AType: Integer): Integer;
begin
  Result := GetNumber(mifDoomEdNum, AType);
end;

function TScriptMobjInfo.GetMobjInfoCount: Integer;
begin
  Result := FSource.Count;
end;

function TScriptMobjInfo.GetNumber(const AField: TScriptMobjInfoField;
  const AType: Integer): Integer;
begin
  if not IsValidMobjType(AType) then
  begin
    Result := SCRIPT_MOBJINFO_FIELDS[AField].Invalid;
    Exit;
  end;
  Result := FSource.Number(AType, AField);
  if (SCRIPT_MOBJINFO_FIELDS[AField].Kind = mikInheritance) and (Result < 0) then
    Result := SCRIPT_INVALID_ID;
end;

function TScriptMobjInfo.GetText(const AField: TScriptMobjInfoField;
  const AType: Integer): string;
begin
  if IsValidMobjType(AType) then
    Result := FSource.Text(AType, AField)
  else
    Result := '';
end;

function TScriptMobjInfo.GetMobjInfoFlag(const AType: Integer; const AFlag: Integer): Boolean;
begin
  Result := IsValidMobjType(AType) and FSource.Flag(AType, AFlag);
end;

end.
