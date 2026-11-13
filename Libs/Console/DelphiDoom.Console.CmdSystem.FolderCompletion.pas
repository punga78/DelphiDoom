{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - idTech 4 completion of file names             }
{                                                                              }
{  Port of Doom 3 (id Software, GPL v3): framework\CmdSystem.cpp               }
{  (idCmdSystemLocal::ArgCompletion_FolderExtension).                          }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.CmdSystem.FolderCompletion;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.IdLib.Text.CmdArgs,
  DelphiDoom.Console.CmdSystem.Types, DelphiDoom.Console.CmdSystem.Intf;

type
  /// <summary>
  ///   The base of the completions of a path or a file (ArgCompletion_FileName, _MapName, ...):
  ///   the folders and the files with one of the extensions found where the user is typing. As the
  ///   original, it remembers the last text it listed (case insensitive) and does not list again
  ///   while the text is the same.
  /// </summary>
  TCmdFolderCompletion = class
  strict private
    FFiles: ICmdFileLister;
    FCompletionString: AnsiString;
    FCompletionParms: TList<AnsiString>;
  public
    constructor Create(const AFiles: ICmdFileLister);
    destructor Destroy; override;
    /// <summary>
    ///   Gives the callback the folders of the place and its files with one of the extensions,
    ///   each as "command name". AStripFolder removes AFolder from the names (it is the base the
    ///   typed path is relative to)
    /// </summary>
    procedure Complete(const AArgs: TIdCmdArgs; const ACallback: TCmdCompletionCallback; const AFolder: AnsiString;
      const AStripFolder: Boolean; const AExtensions: array of AnsiString);
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Str, DelphiDoom.IdLib.Text.Strings;

{ TCmdFolderCompletion }

constructor TCmdFolderCompletion.Create(const AFiles: ICmdFileLister);
begin
  inherited Create;
  FFiles := AFiles;
  FCompletionString := '*';
  FCompletionParms := TList<AnsiString>.Create;
end;

destructor TCmdFolderCompletion.Destroy;
begin
  FCompletionParms.Free;
  inherited Destroy;
end;

procedure TCmdFolderCompletion.Complete(const AArgs: TIdCmdArgs; const ACallback: TCmdCompletionCallback;
  const AFolder: AnsiString; const AStripFolder: Boolean; const AExtensions: array of AnsiString);
var
  LText, LParm, LPath, LName: TIdStr;
  LNames: TArray<AnsiString>;
  LExtension: AnsiString;
  LIndex: Integer;

  function Cleaned(const AFileName: AnsiString): TIdStr;
  begin
    Result := TIdStr.Create(AFileName);
    if AStripFolder then
      Result.Strip(AFolder)
    else
      Result.Strip('/');
  end;

begin
  LText := TIdStr.Create(AArgs.Argv(0) + ' ' + AArgs.Argv(1));

  if LText.Icmp(FCompletionString) <> 0 then
  begin
    FCompletionString := LText;
    FCompletionParms.Clear;

    LParm := TIdStr.Create(AArgs.Argv(1));
    LPath := LParm.ExtractFilePath;
    if AStripFolder or (LPath.Length = 0) then
      LPath := TIdStr.Create(AFolder + AnsiString(LPath));
    LPath.StripTrailing('/');

    // list folders
    LNames := FFiles.ListFiles(LPath, '/', True, True);
    for LIndex := 0 to High(LNames) do
    begin
      LName := Cleaned(LNames[LIndex]);
      FCompletionParms.Add(AArgs.Argv(0) + ' ' + AnsiString(LName) + '/');
    end;

    // list files
    for LExtension in AExtensions do
    begin
      LNames := FFiles.ListFiles(LPath, LExtension, True, True);
      for LIndex := 0 to High(LNames) do
      begin
        LName := Cleaned(LNames[LIndex]);
        FCompletionParms.Add(AArgs.Argv(0) + ' ' + AnsiString(LName));
      end;
    end;
  end;

  for LIndex := 0 to FCompletionParms.Count - 1 do
    ACallback(FCompletionParms[LIndex]);
end;

end.
