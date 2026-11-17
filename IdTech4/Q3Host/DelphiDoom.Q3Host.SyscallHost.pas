{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the dispatcher of the system calls      }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): the switch of    }
{  SV_GameSystemCalls (sv_game.c), CL_CgameSystemCalls (cl_cgame.c) and         }
{  CL_UISystemCalls (cl_ui.c). Copyright (C) 1999-2005 Id Software, Inc. This   }
{  unit is derived from the Quake III Arena source code and is therefore        }
{  available under the GNU General Public License, version 2 or (at your        }
{  option) any later version.                                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Host.SyscallHost;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Qvm.Types, DelphiDoom.Qvm.Intf,
  DelphiDoom.Q3Host.Types, DelphiDoom.Q3Host.Intf;

type
  /// <summary>
  ///   The IQvmHost of one module: the "switch ( args[0] )" of the three system call functions of Quake III as a
  ///   table from the number to a handler. A number the module has no entry for is the "Bad system trap" of the
  ///   C (EQ3UnknownSyscallException); a number it has but nobody registered raises
  ///   EQ3UnhandledSyscallException, unless a fallback host is set (an engine that implements part of the calls)
  /// </summary>
  TQ3SyscallHost = class(TInterfacedObject, IQvmHost, IQ3SyscallRegistry, IQ3SyscallHost)
  strict private
    FModule: TQ3Module;
    FHandlers: TDictionary<Integer, TQ3SyscallHandler>;
    FFallback: IQvmHost;
    FOwned: TObjectList<TObject>;
  public
    constructor Create(AModule: TQ3Module);
    destructor Destroy; override;
    /// <summary>The host frees the object when it goes away, after its handlers (the world of the server game)</summary>
    procedure Own(AObject: TObject);
    function SystemCall(const AMachine: IQvmMachine; const AArguments: TQvmSystemCallArguments): Integer;
    procedure Register(ANumber: Integer; const AHandler: TQ3SyscallHandler);
    function IsRegistered(ANumber: Integer): Boolean;
    function RegisteredCount: Integer;
    property Module: TQ3Module read FModule;
    /// <summary>Asked for the numbers that are system calls of the module and have no handler; may be nil</summary>
    function GetRegistry: IQ3SyscallRegistry;
    function GetFallback: IQvmHost;
    procedure SetFallback(const AValue: IQvmHost);
    property Fallback: IQvmHost read GetFallback write SetFallback;
  end;

implementation

uses
  DelphiDoom.Q3Host.OpcodeCatalog;

constructor TQ3SyscallHost.Create(AModule: TQ3Module);
begin
  inherited Create;
  FModule := AModule;
  FHandlers := TDictionary<Integer, TQ3SyscallHandler>.Create;
end;

destructor TQ3SyscallHost.Destroy;
begin
  // the handlers first: they may use what the host owns
  FHandlers.Free;
  FOwned.Free;
  inherited Destroy;
end;

procedure TQ3SyscallHost.Own(AObject: TObject);
begin
  if not Assigned(FOwned) then
    FOwned := TObjectList<TObject>.Create(True);
  FOwned.Add(AObject);
end;

procedure TQ3SyscallHost.Register(ANumber: Integer; const AHandler: TQ3SyscallHandler);
begin
  FHandlers.AddOrSetValue(ANumber, AHandler);
end;

function TQ3SyscallHost.IsRegistered(ANumber: Integer): Boolean;
begin
  Result := FHandlers.ContainsKey(ANumber);
end;

function TQ3SyscallHost.RegisteredCount: Integer;
begin
  Result := FHandlers.Count;
end;

function TQ3SyscallHost.GetRegistry: IQ3SyscallRegistry;
begin
  Result := Self;
end;

function TQ3SyscallHost.GetFallback: IQvmHost;
begin
  Result := FFallback;
end;

procedure TQ3SyscallHost.SetFallback(const AValue: IQvmHost);
begin
  FFallback := AValue;
end;

function TQ3SyscallHost.SystemCall(const AMachine: IQvmMachine;
  const AArguments: TQvmSystemCallArguments): Integer;
var
  LHandler: TQ3SyscallHandler;
  LName: string;
begin
  if FHandlers.TryGetValue(AArguments[0], LHandler) then
    Exit(LHandler(AMachine, AArguments));
  if not TQ3OpcodeCatalog.TryImportName(FModule, AArguments[0], LName) then
    raise EQ3UnknownSyscallException.CreateFmt(SQ3BadSystemTrap,
      [TQ3OpcodeCatalog.ModuleName(FModule), AArguments[0]]);
  if Assigned(FFallback) then
    Exit(FFallback.SystemCall(AMachine, AArguments));
  raise EQ3UnhandledSyscallException.CreateFmt(SQ3UnhandledSystemTrap,
    [LName, AArguments[0], TQ3OpcodeCatalog.ModuleName(FModule)]);
end;

end.
