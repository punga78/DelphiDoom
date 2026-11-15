{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - the lump commands (lumpsize, lumpnum, ...)    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.LumpCommands;

interface

uses
  DelphiDoom.Logging.Intf, DelphiDoom.Console.Intf;

type
  /// <summary>
  ///   Port of w_utils.pas: "lumpsize, lumplength, lumplen", "lumpnum, checknumforname", "numlumps"
  ///   and "savelumptodisk". The lumps and the files are given, so the tests need neither a WAD
  ///   nor the disk.
  /// </summary>
  TConsoleLumpCommands = class(TInterfacedObject, IConsoleCommandGroup)
  strict private
    FRegistry: ICommandRegistry;
    FOutput: IConsoleOutput;
    FLumps: IConsoleLumpSource;
    FFiles: IConsoleLumpFiles;
    FLog: ILog;
    procedure WriteLine(const AText: string);
    function FindLump(const AName: string): Integer;
  public
    /// <summary>EArgumentNilException if a parameter is nil</summary>
    constructor Create(const ARegistry: ICommandRegistry; const AOutput: IConsoleOutput;
      const ALumps: IConsoleLumpSource; const AFiles: IConsoleLumpFiles; const ALog: ILog);
    /// <summary>The size of a lump given by name or by number ("#12", "0x1F")</summary>
    procedure LumpLength(const AName: string);
    /// <summary>The number of the last lump with the name</summary>
    procedure CheckNumForName(const AName: string);
    procedure NumLumps;
    /// <summary>
    ///   Writes a lump to a file of the folder of the saves; a name without a dot gets ".lmp".
    ///   A write that fails is a warning to the log
    /// </summary>
    procedure SaveLumpToDisk(const ALumpName, AFileName: string);
    procedure Register;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Console.Numbers;

const
  LINE_BREAK = #13#10;
  NOT_FOUND = -1;
  SPECIFY_LUMP = 'Please specify the lump name';
  USAGE_FIRST = 'Usage is:';
  USAGE_SECOND = '  savelumptodisk [lumpname] [filename]';
  SLumpDoesNotExist = 'Lump %s does not exist';
  SLumpSize = 'Lump %s size = %dKB (%d bytes)';
  SLumpNumber = 'Lump %s num = %d';
  STotalLumps = '%d total lumps';
  SLumpNotFound = 'Lump %s not found.';
  SLumpSaved = 'Lump %s saved to file %s (%d bytes).';
  SCanNotSave = 'Can not save lump %s to file %s.' + LINE_BREAK;
  DEFAULT_EXTENSION = '.lmp';

{ TConsoleLumpCommands }

constructor TConsoleLumpCommands.Create(const ARegistry: ICommandRegistry;
  const AOutput: IConsoleOutput; const ALumps: IConsoleLumpSource;
  const AFiles: IConsoleLumpFiles; const ALog: ILog);
begin
  inherited Create;
  if not Assigned(ARegistry) then
    raise EArgumentNilException.Create('ARegistry');
  if not Assigned(AOutput) then
    raise EArgumentNilException.Create('AOutput');
  if not Assigned(ALumps) then
    raise EArgumentNilException.Create('ALumps');
  if not Assigned(AFiles) then
    raise EArgumentNilException.Create('AFiles');
  if not Assigned(ALog) then
    raise EArgumentNilException.Create('ALog');
  FRegistry := ARegistry;
  FOutput := AOutput;
  FLumps := ALumps;
  FFiles := AFiles;
  FLog := ALog;
end;

procedure TConsoleLumpCommands.WriteLine(const AText: string);
begin
  FOutput.Write(AText + LINE_BREAK);
end;

function TConsoleLumpCommands.FindLump(const AName: string): Integer;
begin
  Result := TConsoleNumbers.ParseInteger(AName, NOT_FOUND);
  if Result = NOT_FOUND then
    Result := FLumps.CheckNumForName(AName);
end;

procedure TConsoleLumpCommands.LumpLength(const AName: string);
var
  LLump: Integer;
  LLength: Integer;
begin
  if AName = '' then
  begin
    WriteLine(SPECIFY_LUMP);
    Exit;
  end;

  LLump := FindLump(AName);
  if LLump = NOT_FOUND then
    WriteLine(Format(SLumpDoesNotExist, [AName]))
  else
  begin
    LLength := FLumps.LengthOf(LLump);
    WriteLine(Format(SLumpSize, [AName, LLength div 1024, LLength]));
  end;
end;

procedure TConsoleLumpCommands.CheckNumForName(const AName: string);
var
  LLump: Integer;
begin
  if AName = '' then
  begin
    WriteLine(SPECIFY_LUMP);
    Exit;
  end;

  LLump := FLumps.CheckNumForName(AName);
  if LLump = NOT_FOUND then
    WriteLine(Format(SLumpDoesNotExist, [AName]))
  else
    WriteLine(Format(SLumpNumber, [AName, LLump]));
end;

procedure TConsoleLumpCommands.NumLumps;
begin
  WriteLine(Format(STotalLumps, [FLumps.Count]));
end;

procedure TConsoleLumpCommands.SaveLumpToDisk(const ALumpName, AFileName: string);
var
  LFileName: string;
  LLump: Integer;
  LData: TBytes;
begin
  if (ALumpName = '') or (AFileName = '') then
  begin
    WriteLine(USAGE_FIRST);
    WriteLine(USAGE_SECOND);
    Exit;
  end;

  if Pos('.', AFileName) = 0 then
    LFileName := AFileName + DEFAULT_EXTENSION
  else
    LFileName := AFileName;
  LFileName := FFiles.SaveFileName(LFileName);

  LLump := FLumps.CheckNumForName(ALumpName);
  if LLump = NOT_FOUND then
  begin
    WriteLine(Format(SLumpNotFound, [ALumpName]));
    Exit;
  end;

  LData := FLumps.ReadBytes(LLump);
  if FFiles.WriteFile(LFileName, LData) then
    WriteLine(Format(SLumpSaved, [ALumpName, LFileName, Length(LData)]))
  else
    FLog.Warning(Format(SCanNotSave, [ALumpName, LFileName]));
end;

procedure TConsoleLumpCommands.Register;
begin
  FRegistry.Add('lumpsize, lumplength, lumplen',
    procedure(const AParam1, AParam2: string)
    begin
      LumpLength(AParam1);
    end);
  FRegistry.Add('lumpnum, checknumforname',
    procedure(const AParam1, AParam2: string)
    begin
      CheckNumForName(AParam1);
    end);
  FRegistry.Add('numlumps',
    procedure(const AParam1, AParam2: string)
    begin
      NumLumps;
    end);
  FRegistry.Add('savelumptodisk',
    procedure(const AParam1, AParam2: string)
    begin
      SaveLumpToDisk(AParam1, AParam2);
    end);
end;

end.
