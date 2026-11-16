{******************************************************************************}
{                                                                              }
{  DelphiDoom: ide library - the names of the kinds of project items           }
{  Copyright (C) 2016-2022 by Jim Valavanis (original DD_IDE)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ide.ItemKinds;

interface

uses
  DelphiDoom.Ide.Types;

type
  /// <summary>The words of the project file for each kind of item</summary>
  TIdeItemKinds = class
  public
    /// <summary>"script", "compiledscript", "actor", "project" or "none"</summary>
    class function ToText(const AKind: TIdeItemKind): string; static;
    /// <summary>The kind of a word; an unknown word is ikNone. The comparison is case sensitive</summary>
    class function FromText(const AText: string): TIdeItemKind; static;
  end;

implementation

{ TIdeItemKinds }

class function TIdeItemKinds.ToText(const AKind: TIdeItemKind): string;
begin
  case AKind of
    ikScript:
      Result := 'script';
    ikCompiledScript:
      Result := 'compiledscript';
    ikActor:
      Result := 'actor';
    ikProject:
      Result := 'project';
  else
    Result := 'none';
  end;
end;

class function TIdeItemKinds.FromText(const AText: string): TIdeItemKind;
begin
  if AText = 'script' then
    Result := ikScript
  else if AText = 'compiledscript' then
    Result := ikCompiledScript
  else if AText = 'actor' then
    Result := ikActor
  else if AText = 'project' then
    Result := ikProject
  else
    Result := ikNone;
end;

end.
