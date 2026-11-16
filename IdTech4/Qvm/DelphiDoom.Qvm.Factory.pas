{******************************************************************************}
{                                                                              }
{  DelphiDoom: QVM library - the factory: the composition root                 }
{  Based on the Quake III Arena GPL Source Code (id Software)                  }
{  Copyright (C) 1999-2005 Id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Qvm.Factory;

interface

uses
  System.SysUtils, DelphiDoom.Logging.Intf, DelphiDoom.BotAi.Import.Intf, DelphiDoom.Qvm.Types,
  DelphiDoom.Qvm.Intf;

type
  /// <summary>The only place that knows the classes behind the QVM contracts</summary>
  TQvmFactory = class
  public
    /// <summary>A machine from the bytes of a .qvm file, with the default limits</summary>
    /// <param name="AHost">Who answers the system calls of the program</param>
    class function CreateMachine(const AName: AnsiString; const AFileData: TBytes;
      const AHost: IQvmHost): IQvmMachine; overload; static;
    class function CreateMachine(const AName: AnsiString; const AFileData: TBytes; const AHost: IQvmHost;
      const ALimits: TQvmLimits): IQvmMachine; overload; static;
    /// <summary>The table of the machines, loaded by name from 'vm/name.qvm' of AFiles</summary>
    /// <param name="ALog">May be nil</param>
    /// <param name="ALoadSymbols">Read 'vm/name.map' too</param>
    class function CreateManager(const AFiles: IBotFileSource; const ALog: ILog; const ALimits: TQvmLimits;
      ALoadSymbols: Boolean): IQvmManager; static;
  end;

implementation

uses
  DelphiDoom.Qvm.Machine, DelphiDoom.Qvm.Manager;

{ TQvmFactory }

class function TQvmFactory.CreateMachine(const AName: AnsiString; const AFileData: TBytes;
  const AHost: IQvmHost): IQvmMachine;
begin
  Result := TQvmMachine.Create(AName, AFileData, AHost, TQvmLimits.Default);
end;

class function TQvmFactory.CreateMachine(const AName: AnsiString; const AFileData: TBytes; const AHost: IQvmHost;
  const ALimits: TQvmLimits): IQvmMachine;
begin
  Result := TQvmMachine.Create(AName, AFileData, AHost, ALimits);
end;

class function TQvmFactory.CreateManager(const AFiles: IBotFileSource; const ALog: ILog;
  const ALimits: TQvmLimits; ALoadSymbols: Boolean): IQvmManager;
begin
  Result := TQvmManager.Create(AFiles, ALog, ALimits, ALoadSymbols);
end;

end.
