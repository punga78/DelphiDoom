{******************************************************************************}
{                                                                              }
{  DelphiDoom: configuration library - the table of the options                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Configuration.Table;

interface

uses
  DelphiDoom.Configuration.Intf;

type
  /// <summary>
  ///   The rows of the options in the order they were given (the order of the file). A name is
  ///   found as the old loops found it: the first row with that name
  /// </summary>
  TConfigurationTable = class sealed(TInterfacedObject, IConfigurationTable)
  strict private
    FItems: TArray<IConfigurationItem>;
  public
    /// <remarks>Raises EArgumentNilException if one of the rows is nil</remarks>
    constructor Create(const AItems: TArray<IConfigurationItem>);
    function Count: Integer;
    function Item(AIndex: Integer): IConfigurationItem;
    function IndexOf(const AName: string): Integer;
    function FindValue(const AName: string): IConfigurationItem;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Configuration.Types;

const
  SItemIsNil = 'TConfigurationTable: the row %d is nil';
  SBadPosition = 'TConfigurationTable: there is no row %d';

{ TConfigurationTable }

constructor TConfigurationTable.Create(const AItems: TArray<IConfigurationItem>);
var
  LIndex: Integer;
begin
  inherited Create;
  for LIndex := 0 to High(AItems) do
    if not Assigned(AItems[LIndex]) then
      raise EArgumentNilException.CreateFmt(SItemIsNil, [LIndex]);
  FItems := Copy(AItems);
end;

function TConfigurationTable.Count: Integer;
begin
  Result := Length(FItems);
end;

function TConfigurationTable.Item(AIndex: Integer): IConfigurationItem;
begin
  if (AIndex < 0) or (AIndex >= Length(FItems)) then
    raise EConfigurationException.CreateFmt(SBadPosition, [AIndex]);
  Result := FItems[AIndex];
end;

function TConfigurationTable.IndexOf(const AName: string): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FItems) do
    if FItems[LIndex].Name = AName then
      Exit(LIndex);
  Result := -1;
end;

function TConfigurationTable.FindValue(const AName: string): IConfigurationItem;
var
  LItem: IConfigurationItem;
begin
  for LItem in FItems do
    if (LItem.Kind <> cikGroup) and (LItem.Name = AName) then
      Exit(LItem);
  Result := nil;
end;

end.
