{******************************************************************************}
{                                                                              }
{  DelphiDoom: QVM library - the table of the loaded machines                  }
{  Based on the Quake III Arena GPL Source Code (id Software)                  }
{  Port of vmTable, VM_Create (the table and the file), VM_Restart, VM_Free,   }
{  VM_Clear and VM_VmInfo_f (code/qcommon/vm.c), Quake III Arena 1.32          }
{  Copyright (C) 1999-2005 Id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Qvm.Manager;

interface

uses
  System.SysUtils, DelphiDoom.Logging.Intf, DelphiDoom.BotAi.Import.Intf, DelphiDoom.Qvm.Types,
  DelphiDoom.Qvm.Intf;

type
  /// <summary>
  ///   The machines by name, at most QVM_MAX_MACHINES. A module is read from 'vm/name.qvm' of the injected
  ///   files (the same contract the bot library reads its files with) and, when asked, its symbols from
  ///   'vm/name.map'. It is not a global: who needs two tables makes two managers
  /// </summary>
  TQvmManager = class(TInterfacedObject, IQvmManager)
  strict private
    FFiles: IBotFileSource;
    FLog: ILog;
    FLimits: TQvmLimits;
    FLoadSymbols: Boolean;
    FMachines: TArray<IQvmMachine>;
    procedure LogInfo(const AText: string);
    function IndexOf(const AMachine: IQvmMachine): Integer;
  public
    /// <param name="ALog">May be nil</param>
    /// <param name="ALoadSymbols">The com_developer of the original: read the .map of every module</param>
    constructor Create(const AFiles: IBotFileSource; const ALog: ILog; const ALimits: TQvmLimits;
      ALoadSymbols: Boolean);
    function GetCount: Integer;
    function Load(const AModule: AnsiString; const AHost: IQvmHost): IQvmMachine;
    function Find(const AModule: AnsiString): IQvmMachine;
    procedure Restart(const AMachine: IQvmMachine);
    procedure Unload(const AMachine: IQvmMachine);
    procedure Clear;
    function Info: TArray<TQvmInfo>;
  end;

implementation

uses
  DelphiDoom.Models.Q3Player.TokenReader, DelphiDoom.Qvm.Machine;

const
  SBadParms = 'VM_Create: bad parms';
  SNoFreeMachine = 'VM_Create: no free vm_t';
  SRestartFailed = 'VM_Restart failed.';
  SNotInTable = 'The machine %s is not in the table';
  SLoading = 'Loading vm file %s.' + sLineBreak;
  SFailed = 'Failed.' + sLineBreak;
  SNoSymbolFile = 'Couldn''t load symbol file: %s' + sLineBreak;
  SSymbolsParsed = '%d symbols parsed from %s' + sLineBreak;
  IMAGE_PATH = 'vm/%s.qvm';
  SYMBOL_PATH = 'vm/%s.map';

{ TQvmManager }

constructor TQvmManager.Create(const AFiles: IBotFileSource; const ALog: ILog; const ALimits: TQvmLimits;
  ALoadSymbols: Boolean);
begin
  inherited Create;
  FFiles := AFiles;
  FLog := ALog;
  FLimits := ALimits;
  FLoadSymbols := ALoadSymbols;
end;

procedure TQvmManager.LogInfo(const AText: string);
begin
  if Assigned(FLog) then
    FLog.Info(AText);
end;

function TQvmManager.GetCount: Integer;
begin
  Result := Length(FMachines);
end;

function TQvmManager.Find(const AModule: AnsiString): IQvmMachine;
var
  LMachine: IQvmMachine;
begin
  // see if we already have the VM (Q_stricmp)
  for LMachine in FMachines do
    if TQ3TokenReader.SameWord(LMachine.Name, AModule) then
      Exit(LMachine);
  Result := nil;
end;

function TQvmManager.IndexOf(const AMachine: IQvmMachine): Integer;
begin
  for Result := 0 to High(FMachines) do
    if FMachines[Result] = AMachine then
      Exit;
  Result := -1;
end;

function TQvmManager.Load(const AModule: AnsiString; const AHost: IQvmHost): IQvmMachine;
var
  LName, LPath: AnsiString;
  LData, LSymbolData: TBytes;
  LText: AnsiString;
begin
  if (AModule = '') or not Assigned(AHost) then
    raise EQvmException.Create(SBadParms);
  LName := Copy(AModule, 1, QVM_MAX_NAME);
  Result := Find(LName);
  if Assigned(Result) then
    Exit;
  if Length(FMachines) >= QVM_MAX_MACHINES then
    raise EQvmException.Create(SNoFreeMachine);

  // load the image
  LPath := AnsiString(Format(IMAGE_PATH, [string(LName)]));
  LogInfo(Format(SLoading, [string(LPath)]));
  if not FFiles.TryReadFile(LPath, LData) then
  begin
    LogInfo(SFailed);
    Exit(nil);
  end;
  Result := TQvmMachine.Create(LName, LData, AHost, FLimits);

  // load the map file
  if FLoadSymbols then
  begin
    LPath := AnsiString(Format(SYMBOL_PATH, [string(LName)]));
    if FFiles.TryReadFile(LPath, LSymbolData) then
    begin
      SetString(LText, PAnsiChar(LSymbolData), Length(LSymbolData));
      LogInfo(Format(SSymbolsParsed, [Result.Symbols.Load(LText), string(LPath)]));
    end
    else
      LogInfo(Format(SNoSymbolFile, [string(LPath)]));
  end;
  FMachines := FMachines + [Result];
end;

procedure TQvmManager.Restart(const AMachine: IQvmMachine);
var
  LPath: AnsiString;
  LData: TBytes;
begin
  if IndexOf(AMachine) < 0 then
    raise EQvmException.CreateFmt(SNotInTable, [string(AMachine.Name)]);
  LPath := AnsiString(Format(IMAGE_PATH, [string(AMachine.Name)]));
  LogInfo(Format(SLoading, [string(LPath)]));
  if not FFiles.TryReadFile(LPath, LData) then
    raise EQvmException.Create(SRestartFailed);
  AMachine.Restart(LData);
end;

procedure TQvmManager.Unload(const AMachine: IQvmMachine);
var
  LIndex: Integer;
begin
  LIndex := IndexOf(AMachine);
  if LIndex >= 0 then
    Delete(FMachines, LIndex, 1);
end;

procedure TQvmManager.Clear;
begin
  FMachines := nil;
end;

function TQvmManager.Info: TArray<TQvmInfo>;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(FMachines));
  for LIndex := 0 to High(FMachines) do
    Result[LIndex] := FMachines[LIndex].Info;
end;

end.
