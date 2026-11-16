{******************************************************************************}
{                                                                              }
{  DelphiDoom: configuration library - the table of the options and its file   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Configuration.TableStore;

interface

uses
  DelphiDoom.Configuration.Intf;

type
  /// <summary>
  ///   The steps of M_LoadDefaults, M_SaveDefaults and M_ForceDefault* (later TEngineDefaults)
  ///   that work on the table only: the values come from a document read with the format and
  ///   go to a writer of the format
  /// </summary>
  TConfigurationTableStore = class sealed(TInterfacedObject, IConfigurationTableStore)
  strict private
    FTable: IConfigurationTable;
    FFormat: IConfigurationFormat;
  public
    /// <remarks>Raises EArgumentNilException if one of them is nil</remarks>
    constructor Create(const ATable: IConfigurationTable; const AFormat: IConfigurationFormat);
    procedure ResetAll;
    procedure Apply(const ADocument: IConfigurationDocument);
    procedure Write(const AWriter: IConfigurationWriter);
    function ForceInteger(const AName: string; AValue: Integer): Boolean;
    function ForceBoolean(const AName: string; AValue: Boolean): Boolean;
    function ForceString(const AName: string; const AValue: string): Boolean;
    function Names: TArray<string>;
    procedure Reset(const AName: string; ASetFlags: Byte; const ASink: IConfigurationResetSink);
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Configuration.Types;

const
  STableIsNil = 'TConfigurationTableStore: the table is nil';
  SFormatIsNil = 'TConfigurationTableStore: the format is nil';
  SSinkIsNil = 'TConfigurationTableStore: the sink of the reset is nil';

{ TConfigurationTableStore }

constructor TConfigurationTableStore.Create(const ATable: IConfigurationTable;
  const AFormat: IConfigurationFormat);
begin
  inherited Create;
  if not Assigned(ATable) then
    raise EArgumentNilException.Create(STableIsNil);
  if not Assigned(AFormat) then
    raise EArgumentNilException.Create(SFormatIsNil);
  FTable := ATable;
  FFormat := AFormat;
end;

procedure TConfigurationTableStore.ResetAll;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FTable.Count - 1 do
    FTable.Item(LIndex).ResetToDefault;
end;

procedure TConfigurationTableStore.Apply(const ADocument: IConfigurationDocument);
var
  LLine: Integer;
  LFound: Integer;
  LName: string;
  LItem: IConfigurationItem;
begin
  for LLine := 0 to ADocument.Count - 1 do
  begin
    LName := ADocument.NameAt(LLine);
    LFound := FTable.IndexOf(LName);
    if LFound < 0 then
      Continue;
    LItem := FTable.Item(LFound);
    case LItem.Kind of
      cikInteger: LItem.SetInteger(FFormat.ParseInteger(ADocument.ValueOf(LName)));
      cikBoolean: LItem.SetBoolean(FFormat.ParseBoolean(ADocument.ValueOf(LName)));
      cikString: LItem.SetString(ADocument.ValueOf(LName));
    end;
  end;
end;

procedure TConfigurationTableStore.Write(const AWriter: IConfigurationWriter);
var
  LIndex: Integer;
  LItem: IConfigurationItem;
begin
  for LIndex := 0 to FTable.Count - 1 do
  begin
    LItem := FTable.Item(LIndex);
    case LItem.Kind of
      cikInteger: AWriter.AddValue(LItem.Name, FFormat.FormatInteger(LItem.GetInteger));
      cikString: AWriter.AddValue(LItem.Name, LItem.GetString);
      cikBoolean: AWriter.AddValue(LItem.Name, FFormat.FormatBoolean(LItem.GetBoolean));
      cikGroup: AWriter.AddGroup(LItem.Name);
    end;
  end;
end;

function TConfigurationTableStore.ForceInteger(const AName: string; AValue: Integer): Boolean;
var
  LName: string;
  LIndex: Integer;
  LItem: IConfigurationItem;
begin
  Result := False;
  LName := LowerCase(AName);
  // every row with the name: the old loop did not stop at the first one
  for LIndex := 0 to FTable.Count - 1 do
  begin
    LItem := FTable.Item(LIndex);
    if (LItem.Kind = cikInteger) and (LItem.Name = LName) then
    begin
      LItem.ForceInteger(AValue);
      Result := True;
    end;
  end;
end;

function TConfigurationTableStore.ForceBoolean(const AName: string; AValue: Boolean): Boolean;
var
  LName: string;
  LIndex: Integer;
  LItem: IConfigurationItem;
begin
  Result := False;
  LName := LowerCase(AName);
  for LIndex := 0 to FTable.Count - 1 do
  begin
    LItem := FTable.Item(LIndex);
    if (LItem.Kind = cikBoolean) and (LItem.Name = LName) then
    begin
      LItem.ForceBoolean(AValue);
      Result := True;
    end;
  end;
end;

function TConfigurationTableStore.ForceString(const AName: string; const AValue: string): Boolean;
var
  LName: string;
  LIndex: Integer;
  LItem: IConfigurationItem;
begin
  Result := False;
  LName := LowerCase(AName);
  for LIndex := 0 to FTable.Count - 1 do
  begin
    LItem := FTable.Item(LIndex);
    if (LItem.Kind = cikString) and (LItem.Name = LName) then
    begin
      LItem.ForceString(AValue);
      Result := True;
    end;
  end;
end;

function TConfigurationTableStore.Names: TArray<string>;
var
  LIndex: Integer;
  LCount: Integer;
begin
  SetLength(Result, FTable.Count);
  LCount := 0;
  for LIndex := 0 to FTable.Count - 1 do
    if FTable.Item(LIndex).Kind <> cikGroup then
    begin
      Result[LCount] := FTable.Item(LIndex).Name;
      Inc(LCount);
    end;
  SetLength(Result, LCount);
end;

procedure TConfigurationTableStore.Reset(const AName: string; ASetFlags: Byte;
  const ASink: IConfigurationResetSink);
var
  LName: string;
  LIndex: Integer;
  LItem: IConfigurationItem;
begin
  if not Assigned(ASink) then
    raise EArgumentNilException.Create(SSinkIsNil);
  LName := LowerCase(AName);
  // every row with the name, as the old loop
  for LIndex := 0 to FTable.Count - 1 do
  begin
    LItem := FTable.Item(LIndex);
    if LItem.Name <> LName then
      Continue;
    if LItem.Setable and ASetFlags <> 0 then
    begin
      if LItem.Kind = cikGroup then
        Exit;
      LItem.ResetToDefault;
      ASink.ValueReset(AName, LName);
    end
    else if ASink.HasCommand(LName) then
    begin
      if LItem.Kind = cikGroup then
        Exit;
      ASink.CommandReset(AName, LName, LItem);
    end;
  end;
end;

end.