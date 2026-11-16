{******************************************************************************}
{                                                                              }
{  DelphiDoom: glbsp - loads DDGlbsp.dll and creates the IGlbsp it exports     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Glbsp.Loader;

interface

uses
  Winapi.Windows, System.SysUtils, DelphiDoom.Glbsp.Intf;

type
  /// <summary>
  ///   Owns the DLL: loads it, asks it for an IGlbsp and unloads it when
  ///   destroyed, after having released the interface
  /// </summary>
  /// <remarks>
  ///   Every IGlbsp obtained from Glbsp (and every TGlbspClient built on it)
  ///   must be released before the loader is destroyed, because their code
  ///   lives inside the DLL
  /// </remarks>
  TGlbspLoader = class
  private
    FLibraryName: string;
    FHandle: HMODULE;
    FGlbsp: IGlbsp;
  public
    constructor Create(const ALibraryName: string = DDGLBSP_LIBRARY_NAME);
    destructor Destroy; override;
    property LibraryName: string read FLibraryName;
    property Glbsp: IGlbsp read FGlbsp;
  end;

implementation

{ TGlbspLoader }

constructor TGlbspLoader.Create(const ALibraryName: string);
var
  LCreate: TDDGlbspCreate;
  LCode: Integer;
begin
  inherited Create;
  FLibraryName := ALibraryName;

  FHandle := LoadLibrary(PChar(FLibraryName));
  if FHandle = 0 then
    raise EGlbspException.CreateCode(GLBSP_ERR_LOAD_LIBRARY,
      Format('Cannot load %s: %s', [FLibraryName, SysErrorMessage(GetLastError)]));

  // GetProcAddress takes an ANSI name: the string constant converts as is
  LCreate := TDDGlbspCreate(GetProcAddress(FHandle, DDGLBSP_CREATE_EXPORT));
  if not Assigned(LCreate) then
    raise EGlbspException.CreateCode(GLBSP_ERR_LOAD_LIBRARY,
      Format('%s does not export %s', [FLibraryName, DDGLBSP_CREATE_EXPORT]));

  LCode := LCreate(FGlbsp);
  if (LCode <> GLBSP_OK) or not Assigned(FGlbsp) then
    raise EGlbspException.CreateCode(LCode);
end;

destructor TGlbspLoader.Destroy;
begin
  FGlbsp := nil;
  if FHandle <> 0 then
    FreeLibrary(FHandle);
  inherited;
end;

end.
