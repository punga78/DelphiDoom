{******************************************************************************}
{                                                                              }
{  DelphiDoom: Gui library - opens menu files (trap_PC_LoadSource)             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.PrecompilerLoader;

interface

uses
  DelphiDoom.Gui.Intf, DelphiDoom.IdLib.Core.Intf;

type
  /// <summary>IGuiSourceLoader over an idParser and the file system the caller gives (a folder, a PK3, memory)</summary>
  TGuiPrecompilerLoader = class(TInterfacedObject, IGuiSourceLoader)
  strict private
    FFileSystem: IIdLibFileSystem;
    FLog: IIdLibLog;
  public
    constructor Create(const AFileSystem: IIdLibFileSystem; const ALog: IIdLibLog = nil);
    function Load(const AFileName: AnsiString): IGuiTokenSource;
  end;

implementation

uses
  DelphiDoom.Gui.PrecompilerSource;

constructor TGuiPrecompilerLoader.Create(const AFileSystem: IIdLibFileSystem; const ALog: IIdLibLog);
begin
  inherited Create;
  FFileSystem := AFileSystem;
  FLog := ALog;
end;

function TGuiPrecompilerLoader.Load(const AFileName: AnsiString): IGuiTokenSource;
begin
  Result := TGuiPrecompilerSource.Open(AFileName, FFileSystem, FLog);
end;

end.
