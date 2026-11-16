{******************************************************************************}
{                                                                              }
{  DelphiDoom: ide library - a file of a project                               }
{  Copyright (C) 2016-2022 by Jim Valavanis (original DD_IDE)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ide.ProjectItem;

interface

uses
  DelphiDoom.Ide.Types,
  DelphiDoom.Ide.Intf,
  DelphiDoom.Ide.Document;

type
  /// <summary>A script, a compiled script or an actor list of a project</summary>
  TIdeProjectItem = class(TIdeDocument)
  strict private
    FKind: TIdeItemKind;
    // the project is not reference counted (see TIdeUncountedObject), so this does not keep it alive
    FProject: IIdeProjectContext;
  public
    constructor Create(const AProject: IIdeProjectContext; const AFileSystem: IIdeFileSystem;
      const ALog: IIdeLog; const AClock: IIdeClock; const AFileName: string;
      const AKind: TIdeItemKind);
    /// <summary>The path relative to the file of the project</summary>
    function RelativePath: string;
    property Kind: TIdeItemKind read FKind;
    /// <summary>The project that holds the item (its game says how to compile the item)</summary>
    property Project: IIdeProjectContext read FProject;
  end;

implementation

uses
  System.SysUtils;

{ TIdeProjectItem }

constructor TIdeProjectItem.Create(const AProject: IIdeProjectContext;
  const AFileSystem: IIdeFileSystem; const ALog: IIdeLog; const AClock: IIdeClock;
  const AFileName: string; const AKind: TIdeItemKind);
begin
  if not Assigned(AProject) then
    raise EArgumentNilException.Create('AProject');
  FProject := AProject;
  FKind := AKind;
  inherited Create(AFileSystem, ALog, AClock, AFileName);
end;

function TIdeProjectItem.RelativePath: string;
begin
  Result := ExtractRelativePath(FProject.FileName, FileName);
end;

end.
