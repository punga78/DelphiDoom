{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - where the autoexec of the console comes from           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Console.Startup;

{$I Doom32.inc}

interface

uses
  DelphiDoom.CommandLine.Intf,
  DelphiDoom.Console.Intf,
  DelphiDoom.Engine.Wad.Lumps.Intf;

type
  /// <summary>
  ///   The autoexec file of the game (Doom32.con...), the AUTOEXEC lumps of the loaded files and
  ///   the file of the command line parameter -con
  /// </summary>
  TEngineConsoleStartup = class(TInterfacedObject, IConsoleStartupSource)
  strict private
    FCommandLine: ICommandLine;
    FSaveFileNames: ISaveFileNames;
    FLumps: IEngineLumps;
  public
    /// <param name="ACommandLine">Where -con is looked for</param>
    /// <param name="ASaveFileNames">Where the default autoexec file is written</param>
    /// <param name="ALumps">The lumps with the AUTOEXEC text</param>
    constructor Create(const ACommandLine: ICommandLine; const ASaveFileNames: ISaveFileNames;
      const ALumps: IEngineLumps);
    function AutoExecFileName: string;
    function DefaultAutoExecExists: Boolean;
    procedure CreateDefaultAutoExec(const ALines: TArray<string>);
    function AutoExecLumpTexts: TArray<string>;
    function CommandLineFileName: string;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  d_delphi,
  c_con;

const
  AUTOEXEC_LUMP_NAME = 'AUTOEXEC';
  SCommandLineIsNil = 'TEngineConsoleStartup: the command line is nil';
  SSaveFileNamesIsNil = 'TEngineConsoleStartup: the names of the saved files are nil';

{ TEngineConsoleStartup }

constructor TEngineConsoleStartup.Create(const ACommandLine: ICommandLine;
  const ASaveFileNames: ISaveFileNames; const ALumps: IEngineLumps);
begin
  inherited Create;
  if not Assigned(ACommandLine) then
    raise EArgumentNilException.Create(SCommandLineIsNil);
  if not Assigned(ASaveFileNames) then
    raise EArgumentNilException.Create(SSaveFileNamesIsNil);
  if not Assigned(ALumps) then
    raise EArgumentNilException.Create('ALumps');
  FCommandLine := ACommandLine;
  FSaveFileNames := ASaveFileNames;
  FLumps := ALumps;
end;

function TEngineConsoleStartup.AutoExecFileName: string;
begin
  Result := autoexecfile;
end;

function TEngineConsoleStartup.DefaultAutoExecExists: Boolean;
begin
  Result := fexists(DEFAUTOEXEC);
end;

procedure TEngineConsoleStartup.CreateDefaultAutoExec(const ALines: TArray<string>);
var
  LText: TStringList;
  LLine: string;
begin
  LText := TStringList.Create;
  try
    for LLine in ALines do
      LText.Add(LLine);
    LText.SaveToFile(FSaveFileNames.ResolveName(DEFAUTOEXEC));
  finally
    LText.Free;
  end;
end;

function TEngineConsoleStartup.AutoExecLumpTexts: TArray<string>;
var
  LTexts: TList<string>;
  LLump: Integer;
begin
  LTexts := TList<string>.Create;
  try
    for LLump := 0 to FLumps.Count - 1 do
      if FLumps.NameOf(LLump) = AUTOEXEC_LUMP_NAME then
        LTexts.Add(FLumps.TextOf(LLump));
    Result := LTexts.ToArray;
  finally
    LTexts.Free;
  end;
end;

function TEngineConsoleStartup.CommandLineFileName: string;
var
  LParam: Integer;
begin
  Result := '';
  LParam := FCommandLine.IndexOf('-con');
  if (LParam > 0) and (LParam < FCommandLine.Count - 1) then
    Result := FCommandLine[LParam + 1];
end;

end.
