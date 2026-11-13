{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - the utility commands (dir, cd, cat, web pages) }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.UtilityCommands;

interface

uses
  DelphiDoom.Console.Intf;

type
  /// <summary>
  ///   Port of c_utils.pas: "dir, ls", "cd, pwd", "type, cat", "gotowebpage", "homepage",
  ///   "help, documentation", "getlatestversion, downloadlatestversion" and "forum, forums".
  ///   The files and the browser are given, so the tests need neither the disk nor a window.
  /// </summary>
  TConsoleUtilityCommands = class(TInterfacedObject, IConsoleCommandGroup)
  strict private
    FRegistry: ICommandRegistry;
    FOutput: IConsoleOutput;
    FFiles: IConsoleFileLister;
    FBrowser: IConsoleBrowser;
    FInterpreter: IConsoleInterpreter;
  public
    /// <summary>EArgumentNilException if a parameter is nil</summary>
    constructor Create(const ARegistry: ICommandRegistry; const AOutput: IConsoleOutput;
      const AFiles: IConsoleFileLister; const ABrowser: IConsoleBrowser;
      const AInterpreter: IConsoleInterpreter);
    /// <summary>
    ///   The names of the files that match AParam1, then the ones that match each mask of
    ///   AParam2 (the masks are separated by spaces); no mask means "*.*" for the first
    /// </summary>
    procedure Directory(const AParam1, AParam2: string);
    /// <summary>The current directory</summary>
    procedure CurrentDirectory;
    /// <summary>
    ///   The lines of the files that match each mask; a missing mask says "Please specify the
    ///   files to display."
    /// </summary>
    procedure Concatenate(const AParam1, AParam2: string);
    procedure GoToWebPage(const AAddress: string);
    procedure Homepage;
    procedure Help;
    procedure Forums;
    /// <summary>Runs "ver" and opens the download page</summary>
    procedure GetLatestVersion;
    procedure Register;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Console.Text;

const
  LINE_BREAK = #13#10;
  WORD_SEPARATOR = ' ';
  DEFAULT_MASK = '*.*';
  SPECIFY_FILES = 'Please specify the files to display.';
  ADDRESS_HOMEPAGE = 'http://sourceforge.net/projects/delphidoom/';
  ADDRESS_DOWNLOADS = 'http://sourceforge.net/projects/delphidoom/files/';
  ADDRESS_FORUMS = 'http://delphidoom.forumotion.com/index.htm';

{ TConsoleUtilityCommands }

constructor TConsoleUtilityCommands.Create(const ARegistry: ICommandRegistry;
  const AOutput: IConsoleOutput; const AFiles: IConsoleFileLister; const ABrowser: IConsoleBrowser;
  const AInterpreter: IConsoleInterpreter);
begin
  inherited Create;
  if not Assigned(ARegistry) then
    raise EArgumentNilException.Create('ARegistry');
  if not Assigned(AOutput) then
    raise EArgumentNilException.Create('AOutput');
  if not Assigned(AFiles) then
    raise EArgumentNilException.Create('AFiles');
  if not Assigned(ABrowser) then
    raise EArgumentNilException.Create('ABrowser');
  if not Assigned(AInterpreter) then
    raise EArgumentNilException.Create('AInterpreter');
  FRegistry := ARegistry;
  FOutput := AOutput;
  FFiles := AFiles;
  FBrowser := ABrowser;
  FInterpreter := AInterpreter;
end;

procedure TConsoleUtilityCommands.Directory(const AParam1, AParam2: string);
var
  LMask: string;
  LRest: string;
  LNext: string;
  LName: string;
begin
  LMask := AParam1;
  LRest := AParam2;
  while True do
  begin
    if LMask = '' then
      LMask := DEFAULT_MASK;
    for LName in FFiles.FindFiles(LMask) do
      FOutput.Write(LName + LINE_BREAK);
    if LRest = '' then
      Break;
    TConsoleText.Split(LRest, WORD_SEPARATOR, LMask, LNext);
    LRest := LNext;
  end;
end;

procedure TConsoleUtilityCommands.CurrentDirectory;
begin
  FOutput.Write(FFiles.CurrentDirectory + LINE_BREAK);
end;

procedure TConsoleUtilityCommands.Concatenate(const AParam1, AParam2: string);
var
  LMask: string;
  LRest: string;
  LNext: string;
  LName: string;
  LLine: string;
begin
  LMask := AParam1;
  LRest := AParam2;
  while True do
  begin
    if LMask = '' then
    begin
      // an empty mask stops the whole command, as it always did
      FOutput.Write(SPECIFY_FILES + LINE_BREAK);
      Break;
    end;
    for LName in FFiles.FindFiles(LMask) do
      for LLine in FFiles.ReadTextLines(LName) do
        FOutput.Write(LLine + LINE_BREAK);
    if LRest = '' then
      Break;
    TConsoleText.Split(LRest, WORD_SEPARATOR, LMask, LNext);
    LRest := LNext;
  end;
end;

procedure TConsoleUtilityCommands.GoToWebPage(const AAddress: string);
begin
  FBrowser.OpenWebPage(AAddress);
end;

procedure TConsoleUtilityCommands.Homepage;
begin
  GoToWebPage(ADDRESS_HOMEPAGE);
end;

procedure TConsoleUtilityCommands.Help;
begin
  GoToWebPage(ADDRESS_HOMEPAGE);
end;

procedure TConsoleUtilityCommands.Forums;
begin
  GoToWebPage(ADDRESS_FORUMS);
end;

procedure TConsoleUtilityCommands.GetLatestVersion;
begin
  FInterpreter.Execute('ver');
  GoToWebPage(ADDRESS_DOWNLOADS);
end;

procedure TConsoleUtilityCommands.Register;
begin
  FRegistry.Add('dir, ls',
    procedure(const AParam1, AParam2: string)
    begin
      Directory(AParam1, AParam2);
    end);
  FRegistry.Add('cd, pwd',
    procedure(const AParam1, AParam2: string)
    begin
      CurrentDirectory;
    end);
  FRegistry.Add('type, cat',
    procedure(const AParam1, AParam2: string)
    begin
      Concatenate(AParam1, AParam2);
    end);
  FRegistry.Add('gotowebpage',
    procedure(const AParam1, AParam2: string)
    begin
      GoToWebPage(AParam1);
    end);
  FRegistry.Add('homepage',
    procedure(const AParam1, AParam2: string)
    begin
      Homepage;
    end);
  FRegistry.Add('help, documentation',
    procedure(const AParam1, AParam2: string)
    begin
      Help;
    end);
  FRegistry.Add('getlatestversion, downloadlatestversion',
    procedure(const AParam1, AParam2: string)
    begin
      GetLatestVersion;
    end);
  FRegistry.Add('forum, forums',
    procedure(const AParam1, AParam2: string)
    begin
      Forums;
    end);
end;

end.
