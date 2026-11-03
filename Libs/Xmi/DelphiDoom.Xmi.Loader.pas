{******************************************************************************}
{                                                                              }
{  DelphiDoom: XMI/CMF - loads DDXmi.dll and creates the IXmi it exports       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xmi.Loader;

interface

uses
  Winapi.Windows, System.SysUtils, DelphiDoom.Xmi.Intf;

type
  /// <summary>
  ///   Owns the DLL: loads it, asks it for an IXmi and unloads it when
  ///   destroyed, after having released the interface
  /// </summary>
  /// <remarks>
  ///   Every IXmi obtained from Xmi must be released before the loader is
  ///   destroyed, because its code lives inside the DLL
  /// </remarks>
  TXmiLoader = class
  private
    FLibraryName: string;
    FHandle: HMODULE;
    FXmi: IXmi;
  public
    constructor Create(const ALibraryName: string = DDXMI_LIBRARY_NAME);
    destructor Destroy; override;
    property LibraryName: string read FLibraryName;
    property Xmi: IXmi read FXmi;
  end;

implementation

{ TXmiLoader }

constructor TXmiLoader.Create(const ALibraryName: string);
var
  LCreate: TDDXmiCreate;
  LCode: Integer;
begin
  inherited Create;
  FLibraryName := ALibraryName;

  FHandle := LoadLibrary(PChar(FLibraryName));
  if FHandle = 0 then
    raise EXmiException.CreateFmt('Cannot load %s: %s',
      [FLibraryName, SysErrorMessage(GetLastError)]);

  LCreate := TDDXmiCreate(GetProcAddress(FHandle, DDXMI_CREATE_EXPORT));
  if not Assigned(LCreate) then
    raise EXmiException.CreateFmt('%s does not export %s',
      [FLibraryName, DDXMI_CREATE_EXPORT]);

  LCode := LCreate(FXmi);
  if (LCode <> XMI_OK) or not Assigned(FXmi) then
    raise EXmiException.CreateCode(LCode);
end;

destructor TXmiLoader.Destroy;
begin
  FXmi := nil;
  if FHandle <> 0 then
    FreeLibrary(FHandle);
  inherited;
end;

end.
