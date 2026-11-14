{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - interpreter of the scripts                        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  It was the part of ps_import.pas that does not name the engine: the         }
{  functions, classes and constants come from the IScriptHostServices.         }
{                                                                              }
{******************************************************************************}

{$I Doom32.inc}

unit DelphiDoom.ScriptHost.Exec;
{$I PascalScript.inc}

interface

uses
  ps_defs,
  ps_runtime,
  DelphiDoom.ScriptHost.Services.Intf;

type
  /// <summary>The interpreter of Pascal Script that loads the compiled scripts of the game</summary>
  TDoomExec = class(TPSExec)
  private
    FServices: IScriptHostServices;
  public
    /// <summary>
    ///   The services are the ones of the importer (TPSDoomRuntimeClassImporter) or, if AServices is nil,
    ///   the ones of the importer; with another importer AServices is needed
    /// </summary>
    /// <exception cref="EArgumentNilException">If there are no services</exception>
    constructor CreateDoomExec(const aImporter: TPSRuntimeClassImporter;
      const AServices: IScriptHostServices = nil); virtual;
    property Services: IScriptHostServices read FServices;
    function LoadData(const pcode: TbtString): Boolean; override;
  end;

implementation

uses
  System.SysUtils,
  Classes,
  uPSR_dateutils,
  uPSR_dll,
  DelphiDoom.Logging.Intf,
  DelphiDoom.ScriptHost.ClassImporter,
  DelphiDoom.ScriptHost.Compiled;

//==============================================================================
//
// TDoomExec.CreateDoomExec
//
//==============================================================================
constructor TDoomExec.CreateDoomExec(const aImporter: TPSRuntimeClassImporter;
  const AServices: IScriptHostServices);
begin
  inherited Create;
  FServices := AServices;
  if FServices = nil then
    if aImporter is TPSDoomRuntimeClassImporter then
      FServices := TPSDoomRuntimeClassImporter(aImporter).Services
    else
      raise EArgumentNilException.Create('AServices');
  AllowNullClasses := True;
  RegisterDLLRuntime(Self);
  RegisterClassLibraryRuntime(Self, aImporter);
  RegisterDateTimeLibrary_R(Self);
end;

//==============================================================================
//
// TDoomExec.LoadData
//
//==============================================================================
function TDoomExec.LoadData(const pcode: TbtString): Boolean;
var
  dta: TbtString;
  unitstr: TbtString;
  len: integer;
  ver: integer;
  i, x: integer;
  lst: TStringList;

  procedure Warn(const AText: string);
  begin
    if Assigned(FServices.Log) then
      FServices.Log.Warning(AText);
  end;

  function RegisterRTLUnit(const s: string): boolean;
  begin
    if FServices.Registry.RegisterExecutor(s, Self) then
    begin
      Result := True;
    end
    else if s = 'ALL' then
    begin
      FServices.Registry.RegisterExecutorForAll(Self);
      Result := True;
    end
    else
    begin
      Warn(Format('RegisterRTLUnit(): Unknown RTL unit %s'#13#10, [s]));
      Result := False;
    end;
  end;

begin
  len := Length(pcode);
  if len < 4 then
  begin
    Result := False;
    Exit;
  end;

  if PLongWord(@pcode[1])^ <> SCRIPT_COMPILED_ID then
  begin
    RegisterRTLUnit('SYSTEM');
    Result := inherited LoadData(pcode);
    Exit;
  end;

  if len < 16 then
  begin
    Result := False;
    Exit;
  end;

  ver := PLongWord(@pcode[5])^;
  if ver <> SCRIPT_COMPILED_VERSION then
  begin
    Result := False;
    Exit;
  end;

  x := PLongWord(@pcode[9])^;
  if len < 12 + x then
  begin
    Result := False;
    Exit;
  end;

  SetLength(unitstr, x);
  for i := 1 to x do
    unitstr[i] := pcode[i + 12];

  lst := TStringList.Create;
  lst.Text := string(unitstr);

  if lst.Count < 2 then
  begin
    lst.Free;
    Result := False;
    Exit;
  end;

  if lst.Strings[0] <> FServices.GameName then
  begin
    Warn(Format('TDoomExec.LoadData(): Can not load "%s" compiled script while playing "%s"'#13#10,
      [lst.Strings[0], FServices.GameName]));
    lst.Free;
    Result := False;
    Exit;
  end;

  for i := 1 to lst.Count - 1 do
    RegisterRTLUnit(lst.Strings[i]);
  lst.Free;

  dta := Copy(pcode, x + 13, len - x - 12);
  Result := inherited LoadData(dta);

  if Result then
  begin
    // JVAL: Must be called after TPSExec.LoadData()
    FServices.Classes.BindVariables(Self);
  end;
end;

end.
