{******************************************************************************}
{                                                                              }
{  DelphiDoom: ACS compiler library - the factory: the composition root       }
{  Copyright (C) 1995 Raven Software, Corp. (original ACC 1.10)                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Acs.Factory;

interface

uses
  System.SysUtils, DelphiDoom.Acs.Intf, DelphiDoom.Acs.Machine.Intf, DelphiDoom.Logging.Intf;

type
  /// <summary>The only place that knows the classes behind the ACS contracts</summary>
  TAcsFactory = class
  public
    /// <param name="AProvider">The files that a script includes</param>
    /// <param name="ALog">May be nil</param>
    class function CreateCompiler(const AProvider: IAcsSourceProvider;
      const ALog: ILog): IAcsCompiler; static;
    /// <summary>The virtual machine that runs the object code of the maps</summary>
    /// <param name="AHost">Everything that a script does to the game</param>
    /// <param name="ALog">May be nil</param>
    class function CreateMachine(const AHost: IAcsHost; const ALog: ILog): IAcsMachine; static;
    /// <summary>A provider with no files</summary>
    class function CreateEmptyProvider: IAcsSourceProvider; static;
    /// <summary>
    ///   A provider with files in memory: the names and the texts go in two lists of the same
    ///   length
    /// </summary>
    class function CreateMemoryProvider(const ANames: array of string;
      const ATexts: array of TBytes): IAcsSourceProvider; static;
  end;

implementation

uses
  DelphiDoom.Acs.Compiler, DelphiDoom.Acs.Machine, DelphiDoom.Acs.MemorySourceProvider;

{ TAcsFactory }

class function TAcsFactory.CreateCompiler(const AProvider: IAcsSourceProvider;
  const ALog: ILog): IAcsCompiler;
begin
  Result := TAcsCompiler.Create(AProvider, ALog);
end;

class function TAcsFactory.CreateMachine(const AHost: IAcsHost; const ALog: ILog): IAcsMachine;
begin
  Result := TAcsMachine.Create(AHost, ALog);
end;

class function TAcsFactory.CreateEmptyProvider: IAcsSourceProvider;
begin
  Result := TAcsMemorySourceProvider.Create;
end;

class function TAcsFactory.CreateMemoryProvider(const ANames: array of string;
  const ATexts: array of TBytes): IAcsSourceProvider;
var
  LProvider: TAcsMemorySourceProvider;
  LIndex: Integer;
begin
  LProvider := TAcsMemorySourceProvider.Create;
  Result := LProvider;
  for LIndex := 0 to High(ANames) do
    LProvider.Add(ANames[LIndex], ATexts[LIndex]);
end;

end.