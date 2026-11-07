{******************************************************************************}
{                                                                              }
{  DelphiDoom: ide library - the tree of the project manager                   }
{  Copyright (C) 2016-2022 by Jim Valavanis (original DD_IDE)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ide.ProjectOutline;

interface

uses
  DelphiDoom.Ide.Outline,
  DelphiDoom.Ide.Project;

type
  /// <summary>
  ///   The tree of the project manager: three branches (Actors, Scripts, Compiled Scripts), each
  ///   with the files of that kind, by the path relative to the project. Other kinds of item are
  ///   in the project but not in the tree
  /// </summary>
  TIdeProjectOutline = class
  public
    class function Build(const AProject: TIdeProject): TIdeOutline; static;
  end;

implementation

uses
  DelphiDoom.Ide.Types,
  DelphiDoom.Ide.ProjectItem;

{ TIdeProjectOutline }

class function TIdeProjectOutline.Build(const AProject: TIdeProject): TIdeOutline;
var
  LActors, LScripts, LCompiled: TIdeOutlineNode;
  LIndex: Integer;
  LItem: TIdeProjectItem;
begin
  Result := TIdeOutline.Create;
  LActors := Result.AddRoot('Actors');
  LScripts := Result.AddRoot('Scripts');
  LCompiled := Result.AddRoot('Compiled Scripts');
  if AProject = nil then
    Exit;
  for LIndex := 0 to AProject.Count - 1 do
  begin
    LItem := AProject.Items[LIndex];
    case LItem.Kind of
      ikActor:
        LActors.AddChild(LItem.RelativePath);
      ikScript:
        LScripts.AddChild(LItem.RelativePath);
      ikCompiledScript:
        LCompiled.AddChild(LItem.RelativePath);
    end;
  end;
end;

end.
