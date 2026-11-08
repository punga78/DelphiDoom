{******************************************************************************}
{                                                                              }
{  DelphiDoom: command line library - the names of the saved files             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.CommandLine.SaveFileNames;

interface

uses
  System.SysUtils,
  DelphiDoom.CommandLine.Intf;

type
  /// <summary>
  ///   M_CheckParmCDROM and M_SaveFileName of the old m_argv.pas: the program runs "from a
  ///   CD-ROM" when its drive is one or when -cdrom is on the command line; then the files
  ///   go to the working folder, that is made the first time the answer is needed. The answer
  ///   is asked once and kept
  /// </summary>
  TSaveFileNames = class(TInterfacedObject, ISaveFileNames)
  strict private
    FCommandLine: ICommandLine;
    FIsProgramOnCdRom: TFunc<Boolean>;
    FEnsureDirectory: TProc<string>;
    FWorkingFolder: string;
    FChecked: Boolean;
    FCdRomMode: Boolean;
  public
    /// <param name="ACommandLine">Where -cdrom is looked for</param>
    /// <param name="AIsProgramOnCdRom">True when the drive of the program is a CD-ROM</param>
    /// <param name="AEnsureDirectory">Makes the working folder</param>
    /// <param name="AWorkingFolder">The folder of the files in CD-ROM mode, with the trailing backslash</param>
    constructor Create(const ACommandLine: ICommandLine; const AIsProgramOnCdRom: TFunc<Boolean>;
      const AEnsureDirectory: TProc<string>; const AWorkingFolder: string);
    function IsCdRomMode: Boolean;
    function ResolveName(const AFileName: string): string;
  end;

implementation

const
  SCommandLineMissing = 'ACommandLine';
  SIsProgramOnCdRomMissing = 'AIsProgramOnCdRom';
  SEnsureDirectoryMissing = 'AEnsureDirectory';
  SCdRomParameter = '-cdrom';

{ TSaveFileNames }

constructor TSaveFileNames.Create(const ACommandLine: ICommandLine;
  const AIsProgramOnCdRom: TFunc<Boolean>; const AEnsureDirectory: TProc<string>;
  const AWorkingFolder: string);
begin
  inherited Create;
  if not Assigned(ACommandLine) then
    raise EArgumentNilException.Create(SCommandLineMissing);
  if not Assigned(AIsProgramOnCdRom) then
    raise EArgumentNilException.Create(SIsProgramOnCdRomMissing);
  if not Assigned(AEnsureDirectory) then
    raise EArgumentNilException.Create(SEnsureDirectoryMissing);
  FCommandLine := ACommandLine;
  FIsProgramOnCdRom := AIsProgramOnCdRom;
  FEnsureDirectory := AEnsureDirectory;
  FWorkingFolder := AWorkingFolder;
end;

function TSaveFileNames.IsCdRomMode: Boolean;
begin
  if not FChecked then
  begin
    FChecked := True;
    FCdRomMode := FIsProgramOnCdRom() or (FCommandLine.IndexOf(SCdRomParameter) > 0);
    if FCdRomMode then
      FEnsureDirectory(FWorkingFolder);
  end;
  Result := FCdRomMode;
end;

function TSaveFileNames.ResolveName(const AFileName: string): string;
begin
  if IsCdRomMode then
    Result := FWorkingFolder + AFileName
  else
    Result := AFileName;
end;

end.
