{******************************************************************************}
{                                                                              }
{  DelphiDoom: ide library - the functions of the actor definitions            }
{  Copyright (C) 2016-2022 by Jim Valavanis (original DD_IDE)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ide.ActorDefFunctionTable;

interface

uses
  DelphiDoom.Ide.Intf,
  DelphiDoom.Ide.LibraryTable;

type
  /// <summary>
  ///   The functions an ACTORDEF can call, for the "Actordef" panel. The name is the text before
  ///   the first bracket, without the "A_" at the start
  /// </summary>
  TIdeActorDefFunctionTable = class(TIdeLibraryTable)
  public
    constructor Create;
    function Load(const ALibrary: IIdeGameLibrary; const AGame: string): Boolean; override;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Ide.Types,
  DelphiDoom.Ide.Text,
  DelphiDoom.Ide.RowSorter;

{ TIdeActorDefFunctionTable }

constructor TIdeActorDefFunctionTable.Create;
begin
  inherited Create(ccText);
end;

function TIdeActorDefFunctionTable.Load(const ALibrary: IIdeGameLibrary; const AGame: string): Boolean;
var
  LLines: TArray<string>;
  LLine, LName, LRest: string;
begin
  Result := ALibrary.TryGetLines(ldActorDefFunctions, AGame, LLines);
  if not Result then
    Exit;
  Clear;
  for LLine in LLines do
  begin
    TIdeText.SplitPair(LLine, '(', LName, LRest);
    if Pos('A_', UpperCase(LName)) = 1 then
    begin
      LName[1] := ' ';
      LName[2] := ' ';
    end;
    LName := Trim(LName);
    if LName <> '' then
      Add(LName, TArray<string>.Create(LLine), LLine);
  end;
end;

end.
