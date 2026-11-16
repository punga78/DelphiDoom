{******************************************************************************}
{                                                                              }
{  DelphiDoom: ide library - the functions of the units of the library         }
{  Copyright (C) 2016-2022 by Jim Valavanis (original DD_IDE)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ide.UnitFunctionTable;

interface

uses
  DelphiDoom.Ide.Intf,
  DelphiDoom.Ide.LibraryTable;

type
  /// <summary>
  ///   The procedures and functions of the units a script can use, for the "Functions" panel:
  ///   the name, "function" or "procedure", and the unit
  /// </summary>
  TIdeUnitFunctionTable = class(TIdeLibraryTable)
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

{ TIdeUnitFunctionTable }

constructor TIdeUnitFunctionTable.Create;
begin
  inherited Create(ccText);
end;

function TIdeUnitFunctionTable.Load(const ALibrary: IIdeGameLibrary; const AGame: string): Boolean;
var
  LUnits: TArray<TIdeUnitDeclarations>;
  LUnit: TIdeUnitDeclarations;
  LDeclaration, LText: string;
  LIndex: Integer;
begin
  Result := ALibrary.TryGetUnitFunctions(AGame, LUnits);
  if not Result then
    Exit;
  Clear;
  for LUnit in LUnits do
    for LDeclaration in LUnit.Declarations do
    begin
      LText := LDeclaration;
      for LIndex := 1 to Length(LText) do
        if CharInSet(LText[LIndex], ['(', ';', ':']) then
          LText[LIndex] := ' ';
      Add(TIdeText.FirstWord(TIdeText.SecondWord(LText, ' '), ' '),
        TArray<string>.Create(LowerCase(TIdeText.FirstWord(LText, ' ')), LUnit.UnitName),
        LDeclaration);
    end;
end;

end.
