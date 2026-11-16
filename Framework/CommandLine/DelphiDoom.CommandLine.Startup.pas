{******************************************************************************}
{                                                                              }
{  DelphiDoom: command line library - the command line of the start           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.CommandLine.Startup;

interface

uses
  DelphiDoom.CommandLine.Intf;

type
  /// <summary>
  ///   The command line of the start (M_InitArgv of m_argv): the arguments of the process in
  ///   upper case (a name that is not an option and is an existing file becomes its full path),
  ///   then the file of default arguments of the program (Doom32.cmd), written with its template
  ///   when it does not exist and the drive can be written; on a CD-ROM also the file in the
  ///   working folder of the CD-ROM
  /// </summary>
  TCommandLineStartup = class sealed(TInterfacedObject, ICommandLineStartup)
  strict private
    FBuilder: ICommandLineBuilder;
    FSaveFileNames: ISaveFileNames;
    FEnvironment: IProgramEnvironment;
    FApplicationName: string;
    FDefaultFileName: string;
    procedure LoadDefaultFile(const AFileName, AProgramName: string; ATryWrite: Boolean);
  public
    /// <param name="ASaveFileNames">Gives the name of the default file on a CD-ROM</param>
    /// <param name="AApplicationName">The name in the template of the default file (APPNAME)</param>
    /// <param name="ADefaultFileName">The file of default arguments (DEFARGVFILENAME)</param>
    /// <remarks>Raises EArgumentNilException if a dependency is nil</remarks>
    constructor Create(const ABuilder: ICommandLineBuilder; const ASaveFileNames: ISaveFileNames;
      const AEnvironment: IProgramEnvironment; const AApplicationName, ADefaultFileName: string);
    /// <summary>Adds the arguments to the builder and builds the command line</summary>
    function Collect: ICommandLine;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.CommandLine.DefaultFile;

const
  SBuilderIsNil = 'TCommandLineStartup: the builder is nil';
  SSaveFileNamesIsNil = 'TCommandLineStartup: the names of the files are nil';
  SEnvironmentIsNil = 'TCommandLineStartup: the environment is nil';

{ TCommandLineStartup }

constructor TCommandLineStartup.Create(const ABuilder: ICommandLineBuilder;
  const ASaveFileNames: ISaveFileNames; const AEnvironment: IProgramEnvironment;
  const AApplicationName, ADefaultFileName: string);
begin
  inherited Create;
  if not Assigned(ABuilder) then
    raise EArgumentNilException.Create(SBuilderIsNil);
  if not Assigned(ASaveFileNames) then
    raise EArgumentNilException.Create(SSaveFileNamesIsNil);
  if not Assigned(AEnvironment) then
    raise EArgumentNilException.Create(SEnvironmentIsNil);
  FBuilder := ABuilder;
  FSaveFileNames := ASaveFileNames;
  FEnvironment := AEnvironment;
  FApplicationName := AApplicationName;
  FDefaultFileName := ADefaultFileName;
end;

procedure TCommandLineStartup.LoadDefaultFile(const AFileName, AProgramName: string;
  ATryWrite: Boolean);
var
  LText: string;
begin
  if FEnvironment.TryReadDefaultFile(AFileName, LText) then
    FBuilder.AddDefaultFile(LText)
  else if ATryWrite then
    FEnvironment.WriteDefaultFile(AFileName,
      TDefaultArgumentsFile.Template(FApplicationName, FEnvironment.FileNameOf(AProgramName)));
end;

function TCommandLineStartup.Collect: ICommandLine;
var
  LIndex: Integer;
  LArgument: string;
  LProgramName: string;
  LFileName: string;
begin
  LProgramName := '';
  for LIndex := 0 to FEnvironment.ArgumentCount do
  begin
    // the old strupper: only the letters a..z
    LArgument := UpperCase(FEnvironment.Argument(LIndex));
    if LArgument <> '' then
      if LArgument[1] <> '-' then
        if FEnvironment.FileExists(LArgument) then
          LArgument := FEnvironment.ExpandFileName(LArgument);
    if LIndex = 0 then
      LProgramName := LArgument;
    FBuilder.Add(LArgument);
  end;

  LoadDefaultFile(FDefaultFileName, LProgramName, not FEnvironment.IsProgramOnCdRom);

  if FEnvironment.IsProgramOnCdRom then
  begin
    LFileName := FSaveFileNames.ResolveName(FDefaultFileName);
    LoadDefaultFile(LFileName, LProgramName, not FEnvironment.IsCdRomDrive(LFileName[1]));
  end;

  Result := FBuilder.Build;
end;

end.
