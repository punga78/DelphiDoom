{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - names and numbers of the traps          }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): g_public.h,      }
{  cg_public.h, ui_public.h. Copyright (C) 1999-2005 Id Software, Inc. This     }
{  unit is derived from the Quake III Arena source code and is therefore        }
{  available under the GNU General Public License, version 2 or (at your        }
{  option) any later version.                                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Host.OpcodeCatalog;

interface

uses
  DelphiDoom.Q3Host.Types;

type
  /// <summary>
  ///   What the module can ask of the host (the imports, gameImport_t, cgameImport_t and uiImport_t) and
  ///   what the host can ask of the module (the exports, vmMain commands): number to name and back
  /// </summary>
  TQ3OpcodeCatalog = class
  strict private
    class function ImportTable(AModule: TQ3Module): TArray<TQ3OpcodeEntry>; static;
    class function ExportTable(AModule: TQ3Module): TArray<TQ3OpcodeEntry>; static;
    class function Lookup(const ATable: TArray<TQ3OpcodeEntry>; AValue: Integer; out AName: string): Boolean; static;
  public
    /// <summary>The name of an import (G_PRINT, CG_PRINT, ...); False if the number is not a system call</summary>
    class function TryImportName(AModule: TQ3Module; ANumber: Integer; out AName: string): Boolean; static;
    /// <summary>The name of an export (GAME_INIT, CG_INIT, UI_INIT, ...)</summary>
    class function TryExportName(AModule: TQ3Module; ANumber: Integer; out AName: string): Boolean; static;
    /// <summary>The number of an import by name; False if the module has none with this name</summary>
    class function TryImportNumber(AModule: TQ3Module; const AName: string; out ANumber: Integer): Boolean; static;
    class function ImportCount(AModule: TQ3Module): Integer; static;
    class function ExportCount(AModule: TQ3Module): Integer; static;
    /// <summary>All the imports of a module, in the order of the enum</summary>
    class function ImportEntries(AModule: TQ3Module): TArray<TQ3OpcodeEntry>; static;
    class function ExportEntries(AModule: TQ3Module): TArray<TQ3OpcodeEntry>; static;
    class function ModuleName(AModule: TQ3Module): string; static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Q3Host.OpcodeTables;

function CopyEntries(const ASource: array of TQ3OpcodeEntry): TArray<TQ3OpcodeEntry>;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(ASource));
  for LIndex := 0 to High(ASource) do
    Result[LIndex] := ASource[LIndex];
end;

class function TQ3OpcodeCatalog.ImportTable(AModule: TQ3Module): TArray<TQ3OpcodeEntry>;
begin
  case AModule of
    TQ3Module.Game:
      Result := CopyEntries(Q3_GAME_IMPORTS);
    TQ3Module.CGame:
      Result := CopyEntries(Q3_CGAME_IMPORTS);
  else
    Result := CopyEntries(Q3_UI_IMPORTS);
  end;
end;

class function TQ3OpcodeCatalog.ExportTable(AModule: TQ3Module): TArray<TQ3OpcodeEntry>;
begin
  case AModule of
    TQ3Module.Game:
      Result := CopyEntries(Q3_GAME_EXPORTS);
    TQ3Module.CGame:
      Result := CopyEntries(Q3_CGAME_EXPORTS);
  else
    Result := CopyEntries(Q3_UI_EXPORTS);
  end;
end;

class function TQ3OpcodeCatalog.Lookup(const ATable: TArray<TQ3OpcodeEntry>; AValue: Integer;
  out AName: string): Boolean;
var
  LEntry: TQ3OpcodeEntry;
begin
  for LEntry in ATable do
    if LEntry.Value = AValue then
    begin
      AName := LEntry.Name;
      Exit(True);
    end;
  AName := '';
  Result := False;
end;

class function TQ3OpcodeCatalog.TryImportName(AModule: TQ3Module; ANumber: Integer; out AName: string): Boolean;
begin
  Result := Lookup(ImportTable(AModule), ANumber, AName);
end;

class function TQ3OpcodeCatalog.TryExportName(AModule: TQ3Module; ANumber: Integer; out AName: string): Boolean;
begin
  Result := Lookup(ExportTable(AModule), ANumber, AName);
end;

class function TQ3OpcodeCatalog.TryImportNumber(AModule: TQ3Module; const AName: string;
  out ANumber: Integer): Boolean;
var
  LEntry: TQ3OpcodeEntry;
begin
  for LEntry in ImportTable(AModule) do
    if LEntry.Name = AName then
    begin
      ANumber := LEntry.Value;
      Exit(True);
    end;
  ANumber := 0;
  Result := False;
end;

class function TQ3OpcodeCatalog.ImportCount(AModule: TQ3Module): Integer;
begin
  Result := Length(ImportTable(AModule));
end;

class function TQ3OpcodeCatalog.ExportCount(AModule: TQ3Module): Integer;
begin
  Result := Length(ExportTable(AModule));
end;

class function TQ3OpcodeCatalog.ImportEntries(AModule: TQ3Module): TArray<TQ3OpcodeEntry>;
begin
  Result := ImportTable(AModule);
end;

class function TQ3OpcodeCatalog.ExportEntries(AModule: TQ3Module): TArray<TQ3OpcodeEntry>;
begin
  Result := ExportTable(AModule);
end;

class function TQ3OpcodeCatalog.ModuleName(AModule: TQ3Module): string;
const
  NAMES: array[TQ3Module] of string = ('game', 'cgame', 'ui');
begin
  Result := NAMES[AModule];
end;

end.
