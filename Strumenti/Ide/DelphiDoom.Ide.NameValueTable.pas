{******************************************************************************}
{                                                                              }
{  DelphiDoom: ide library - constants, variables and types of the library     }
{  Copyright (C) 2016-2022 by Jim Valavanis (original DD_IDE)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ide.NameValueTable;

interface

uses
  DelphiDoom.Ide.Types,
  DelphiDoom.Ide.Intf,
  DelphiDoom.Ide.LibraryTable;

type
  /// <summary>Which of the three lists a name and value table is</summary>
  TIdeNameValueKind = (nvConstants, nvVariables, nvTypes);

  /// <summary>
  ///   The lines "name=value" of the constants, the variables (value is the type) or the types
  ///   (value is the base type) of a game. Only the constants sort their value column as numbers
  /// </summary>
  TIdeNameValueTable = class(TIdeLibraryTable)
  strict private
    FKind: TIdeNameValueKind;
  public
    constructor Create(const AKind: TIdeNameValueKind);
    function Load(const ALibrary: IIdeGameLibrary; const AGame: string): Boolean; override;
  end;

implementation

uses
  DelphiDoom.Ide.Text,
  DelphiDoom.Ide.RowSorter;

{ TIdeNameValueTable }

constructor TIdeNameValueTable.Create(const AKind: TIdeNameValueKind);
begin
  if AKind = nvConstants then
    inherited Create(ccNumbers)
  else
    inherited Create(ccText);
  FKind := AKind;
end;

function TIdeNameValueTable.Load(const ALibrary: IIdeGameLibrary; const AGame: string): Boolean;
const
  LIBRARY_DATA: array[TIdeNameValueKind] of TIdeLibraryData = (ldConstants, ldVariables, ldTypes);
var
  LLines: TArray<string>;
  LLine, LName, LValue, LDeclaration: string;
begin
  Result := ALibrary.TryGetLines(LIBRARY_DATA[FKind], AGame, LLines);
  if not Result then
    Exit;
  Clear;
  for LLine in LLines do
  begin
    TIdeText.SplitPair(LLine, '=', LName, LValue);
    case FKind of
      nvConstants:
        LDeclaration := LName + ' = ' + LValue + ';';
      nvVariables:
        LDeclaration := LName + ': ' + LValue + ';';
    else
      LDeclaration := LName + ' (' + LValue + ')';
    end;
    Add(LName, TArray<string>.Create(LValue), LDeclaration);
  end;
end;

end.
