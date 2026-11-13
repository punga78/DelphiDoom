{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the table of the options as rows of Libs\Configuration }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Configuration.Table;

{$I Doom32.inc}

interface

uses
  DelphiDoom.Configuration.Intf;

type
  /// <summary>
  ///   Builds the table of the options from the data of m_defs (the array defaults: name,
  ///   pointer to the global, who can change it, values it starts with, kind), in its order.
  ///   The array stays the declaration of the options of each game; after the build only the
  ///   rows are read and written (the force no longer moves the pointers of the array)
  /// </summary>
  TEngineConfigurationTable = class sealed
  public
    class function Build: IConfigurationTable; static;
  end;

implementation

uses
  DelphiDoom.Configuration.Types,
  DelphiDoom.Configuration.Factory,
  DelphiDoom.Engine.Configuration.Global,
  m_defs;

{ TEngineConfigurationTable }

class function TEngineConfigurationTable.Build: IConfigurationTable;
const
  KINDS: array[ttype_t] of TConfigurationItemKind = (cikString, cikInteger, cikBoolean, cikGroup);
var
  LItems: TArray<IConfigurationItem>;
  LIndex: Integer;
  LDefaults: TConfigurationDefaults;
  LAccess: IConfigurationValueAccess;
begin
  SetLength(LItems, NUMDEFAULTS);
  for LIndex := 0 to NUMDEFAULTS - 1 do
  begin
    LDefaults.StringValue := defaults[LIndex].defaultsvalue;
    LDefaults.IntegerValue := defaults[LIndex].defaultivalue;
    LDefaults.BooleanValue := defaults[LIndex].defaultbvalue;
    if defaults[LIndex]._type = tGroup then
      LAccess := nil
    else
      LAccess := TEngineConfigurationGlobal.Create(defaults[LIndex].location);
    LItems[LIndex] := TConfigurationFactory.CreateItem(defaults[LIndex].name,
      KINDS[defaults[LIndex]._type], defaults[LIndex].setable, LDefaults, LAccess);
  end;
  Result := TConfigurationFactory.CreateTable(LItems);
end;

end.
