{******************************************************************************}
{                                                                              }
{  DelphiDoom: Script - loads DDScript.dll and creates the library it exports  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Script.Loader;

interface

uses
  Winapi.Windows, System.SysUtils, DelphiDoom.Script.Intf;

type
  /// <summary>
  ///   Owns the DLL: loads it, asks it for an IScriptLibrary and unloads it
  ///   when destroyed, after having released the interface
  /// </summary>
  /// <remarks>
  ///   Every compiler and executor obtained from ScriptLibrary must be
  ///   released before the loader is destroyed, because their code lives
  ///   inside the DLL
  /// </remarks>
  TScriptLoader = class
  private
    FLibraryName: string;
    FHandle: HMODULE;
    FScriptLibrary: IScriptLibrary;
  public
    constructor Create(const ALibraryName: string = DDSCRIPT_LIBRARY_NAME);
    destructor Destroy; override;
    property LibraryName: string read FLibraryName;
    property ScriptLibrary: IScriptLibrary read FScriptLibrary;
  end;

implementation

{ TScriptLoader }

constructor TScriptLoader.Create(const ALibraryName: string);
var
  LCreate: TDDScriptCreate;
  LCode: Integer;
begin
  inherited Create;
  FLibraryName := ALibraryName;

  FHandle := LoadLibrary(PChar(FLibraryName));
  if FHandle = 0 then
    raise EScriptException.CreateFmt('Cannot load %s: %s',
      [FLibraryName, SysErrorMessage(GetLastError)]);

  LCreate := TDDScriptCreate(GetProcAddress(FHandle, DDSCRIPT_CREATE_EXPORT));
  if not Assigned(LCreate) then
    raise EScriptException.CreateFmt('%s does not export %s',
      [FLibraryName, DDSCRIPT_CREATE_EXPORT]);

  LCode := LCreate(FScriptLibrary);
  if (LCode <> SCRIPT_OK) or not Assigned(FScriptLibrary) then
    raise EScriptException.CreateCode(LCode);
end;

destructor TScriptLoader.Destroy;
begin
  FScriptLibrary := nil;
  if FHandle <> 0 then
    FreeLibrary(FHandle);
  inherited;
end;

end.
