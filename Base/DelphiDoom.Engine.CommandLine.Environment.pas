{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - what the start of the program reads for its command    }
{  line                                                                        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.CommandLine.Environment;

{$I Doom32.inc}

interface

uses
  DelphiDoom.CommandLine.Intf;

type
  /// <summary>
  ///   The process and the files as M_InitArgv read them: ParamStr, fexists, fexpand and fname
  ///   of d_delphi, I_IsCDRomDrive of i_system, the default file through a TDStringList (its
  ///   text, and the template written without the last empty line)
  /// </summary>
  TEngineProgramEnvironment = class sealed(TInterfacedObject, IProgramEnvironment)
  public
    function ArgumentCount: Integer;
    function Argument(AIndex: Integer): string;
    function FileExists(const AFileName: string): Boolean;
    function ExpandFileName(const AFileName: string): string;
    function FileNameOf(const APath: string): string;
    function IsProgramOnCdRom: Boolean;
    function IsCdRomDrive(ADrive: Char): Boolean;
    function TryReadDefaultFile(const AFileName: string; out AText: string): Boolean;
    procedure WriteDefaultFile(const AFileName, AText: string);
  end;

implementation

uses
  d_delphi,
  i_system;

{ TEngineProgramEnvironment }

function TEngineProgramEnvironment.ArgumentCount: Integer;
begin
  Result := ParamCount;
end;

function TEngineProgramEnvironment.Argument(AIndex: Integer): string;
begin
  Result := ParamStr(AIndex);
end;

function TEngineProgramEnvironment.FileExists(const AFileName: string): Boolean;
begin
  Result := fexists(AFileName);
end;

function TEngineProgramEnvironment.ExpandFileName(const AFileName: string): string;
begin
  Result := fexpand(AFileName);
end;

function TEngineProgramEnvironment.FileNameOf(const APath: string): string;
begin
  Result := fname(APath);
end;

function TEngineProgramEnvironment.IsProgramOnCdRom: Boolean;
begin
  Result := I_IsCDRomDrive;
end;

function TEngineProgramEnvironment.IsCdRomDrive(ADrive: Char): Boolean;
begin
  Result := I_IsCDRomDrive(ADrive);
end;

function TEngineProgramEnvironment.TryReadDefaultFile(const AFileName: string;
  out AText: string): Boolean;
var
  LList: TDStringList;
begin
  Result := fexists(AFileName);
  if not Result then
    Exit;
  LList := TDStringList.Create;
  try
    LList.LoadFromFile(AFileName);
    AText := LList.Text;
  finally
    LList.Free;
  end;
end;

procedure TEngineProgramEnvironment.WriteDefaultFile(const AFileName, AText: string);
var
  LList: TDStringList;
begin
  LList := TDStringList.Create;
  try
    LList.Text := AText;
    if (LList.Count > 0) and (LList[LList.Count - 1] = '') then
      LList.Delete(LList.Count - 1);
    LList.SaveToFile(AFileName);
  finally
    LList.Free;
  end;
end;

end.
