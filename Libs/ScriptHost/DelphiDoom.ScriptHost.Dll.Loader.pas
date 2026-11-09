{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - loader of the DLLs of the PAK files               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  It is the old ps_dll.pas as a class: the source of the files, the library   }
{  and the log are given by the constructor.                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.Dll.Loader;

interface

uses
  System.Generics.Collections,
  DelphiDoom.Logging.Intf,
  DelphiDoom.ScriptHost.Dll.Intf;

type
  /// <summary>Loads each DLL once from a temporary copy and counts the users</summary>
  TScriptDllLoader = class(TInterfacedObject, IScriptDllLoader)
  strict private
    type
      TLoadedDll = record
        Handle: NativeUInt;
        LoadCount: Integer;
      end;
    var
      FSource: IScriptDllSource;
      FLibrary: IScriptDllLibrary;
      FLog: ILog;
      FLoaded: TDictionary<string, TLoadedDll>;
  public
    constructor Create(const ASource: IScriptDllSource; const ALibrary: IScriptDllLibrary;
      const ALog: ILog);
    destructor Destroy; override;
    function Load(const AName: string): NativeUInt;
    function Unload(const AName: string): Boolean;
    procedure Shutdown;
  end;

implementation

uses
  System.SysUtils;

const
  SZeroLoadCount = 'PS_PAKUnLoadDll(): Zero LoadCount on dll "%s"'#13#10;

{ TScriptDllLoader }

constructor TScriptDllLoader.Create(const ASource: IScriptDllSource;
  const ALibrary: IScriptDllLibrary; const ALog: ILog);
begin
  inherited Create;
  if not Assigned(ASource) then
    raise EArgumentNilException.Create('ASource');
  if not Assigned(ALibrary) then
    raise EArgumentNilException.Create('ALibrary');
  if not Assigned(ALog) then
    raise EArgumentNilException.Create('ALog');
  FSource := ASource;
  FLibrary := ALibrary;
  FLog := ALog;
  FLoaded := TDictionary<string, TLoadedDll>.Create;
end;

destructor TScriptDllLoader.Destroy;
begin
  FLoaded.Free;
  inherited;
end;

function TScriptDllLoader.Load(const AName: string): NativeUInt;
var
  LKey: string;
  LEntry: TLoadedDll;
  LPath: string;
begin
  LKey := FSource.KeyOf(AName);
  if FLoaded.TryGetValue(LKey, LEntry) then
  begin
    Inc(LEntry.LoadCount);
    FLoaded[LKey] := LEntry;
    Result := LEntry.Handle;
    Exit;
  end;

  if not FSource.Extract(AName, LPath) then
  begin
    Result := 0;
    Exit;
  end;

  Result := FLibrary.Load(LPath);
  if Result = 0 then
    Exit;

  LEntry.Handle := Result;
  LEntry.LoadCount := 1;
  FLoaded.Add(LKey, LEntry);
end;

function TScriptDllLoader.Unload(const AName: string): Boolean;
var
  LKey: string;
  LEntry: TLoadedDll;
begin
  LKey := FSource.KeyOf(AName);
  if not FLoaded.TryGetValue(LKey, LEntry) then
  begin
    Result := False;
    Exit;
  end;

  if LEntry.LoadCount <= 0 then
    FLog.Warning(Format(SZeroLoadCount, [LKey]))
  else
    Dec(LEntry.LoadCount);

  if LEntry.LoadCount = 0 then
  begin
    FLibrary.Unload(LEntry.Handle);
    FLoaded.Remove(LKey);
  end
  else
    FLoaded[LKey] := LEntry;
  Result := True;
end;

procedure TScriptDllLoader.Shutdown;
begin
  FLoaded.Clear;
end;

end.
