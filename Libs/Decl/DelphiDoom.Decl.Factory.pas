{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - TDeclFactory, the place that knows the    }
{  concrete classes                                                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Factory;

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Core.Intf, DelphiDoom.Decl.Intf, DelphiDoom.Decl.Source.Intf;

type
  /// <summary>Builds a declaration manager (the composition root of the library)</summary>
  TDeclFactory = class sealed
  public
    /// <summary>An empty manager: no type is registered, no file is read</summary>
    class function CreateManager(const ASource: IDeclSource; const ALog: IIdLibLog = nil): IDeclManager; static;
    /// <summary>
    ///   A manager with the standard types of Doom 3 registered (<c>TDeclStandardTypes.RegisterTypes</c>) and, if
    ///   <c>ALoadFolders</c>, the standard folders loaded
    /// </summary>
    class function CreateStandardManager(const ASource: IDeclSource; const ALog: IIdLibLog = nil;
      const ALoadFolders: Boolean = True): IDeclManager; static;
  end;

implementation

uses
  DelphiDoom.Decl.Manager, DelphiDoom.Decl.StandardTypes;

{ TDeclFactory }

class function TDeclFactory.CreateManager(const ASource: IDeclSource; const ALog: IIdLibLog): IDeclManager;
begin
  Result := TDeclManager.Create(ASource, ALog);
end;

class function TDeclFactory.CreateStandardManager(const ASource: IDeclSource; const ALog: IIdLibLog;
  const ALoadFolders: Boolean): IDeclManager;
begin
  Result := CreateManager(ASource, ALog);
  TDeclStandardTypes.RegisterTypes(Result.GetRegistry, []);
  if ALoadFolders then
    TDeclStandardTypes.RegisterFolders(Result.GetRegistry);
end;

end.
