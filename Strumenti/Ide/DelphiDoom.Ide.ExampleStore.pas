{******************************************************************************}
{                                                                              }
{  DelphiDoom: ide library - the example scripts of the library panels         }
{  Copyright (C) 2016-2022 by Jim Valavanis (original DD_IDE)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ide.ExampleStore;

interface

uses
  DelphiDoom.Ide.Intf;

type
  /// <summary>
  ///   Every item of a library panel (a constant, a function, a class...) can have a short example
  ///   script, kept in a text file in a folder next to the program ("consts", "classes"...), one
  ///   file for each item. The panel edits the example of the selected item; the examples can be
  ///   changed only if the ide was started with -devparm
  /// </summary>
  TIdeExampleStore = class
  strict private
    FFileSystem: IIdeFileSystem;
    FFolderName: string;
    FExtension: string;
    FReadOnly: Boolean;
    FCurrentName: string;
    function PathOf(const AName: string): string;
    procedure WriteText(const AName, AText: string);
  public
    constructor Create(const AFileSystem: IIdeFileSystem; const AFolderName, AExtension: string;
      const AReadOnly: Boolean);
    /// <summary>
    ///   Moves to the example of another item: the text of the item that was current is saved (unless
    ///   the store is read only) and the text of the new one is given back; an item with no file has
    ///   an empty text. Moving to the item that is already current changes nothing and gives false
    /// </summary>
    function Select(const AName, ACurrentText: string; out ANewText: string): Boolean;
    /// <summary>Saves the text of the current item (unless the store is read only or there is no item)</summary>
    procedure Save(const ACurrentText: string);
    property CurrentName: string read FCurrentName;
    property ReadOnly: Boolean read FReadOnly;
  end;

implementation

uses
  System.SysUtils;

{ TIdeExampleStore }

constructor TIdeExampleStore.Create(const AFileSystem: IIdeFileSystem; const AFolderName,
  AExtension: string; const AReadOnly: Boolean);
begin
  inherited Create;
  if not Assigned(AFileSystem) then
    raise EArgumentNilException.Create('AFileSystem');
  FFileSystem := AFileSystem;
  FFolderName := AFolderName;
  FExtension := AExtension;
  FReadOnly := AReadOnly;
  FCurrentName := '';
end;

function TIdeExampleStore.PathOf(const AName: string): string;
var
  LFolder: string;
begin
  LFolder := FFileSystem.ProgramFolder + FFolderName + '\';
  if not FFileSystem.DirectoryExists(LFolder) then
    FFileSystem.TryCreateDirectory(LFolder);
  Result := LFolder + AName + FExtension;
end;

procedure TIdeExampleStore.WriteText(const AName, AText: string);
begin
  FFileSystem.TrySaveTextFile(PathOf(AName), AText);
end;

function TIdeExampleStore.Select(const AName, ACurrentText: string; out ANewText: string): Boolean;
var
  LPath: string;
begin
  ANewText := ACurrentText;
  Result := FCurrentName <> AName;
  if not Result then
    Exit;
  if not FReadOnly then
    if FCurrentName <> '' then
      WriteText(FCurrentName, ACurrentText);
  LPath := PathOf(AName);
  if not (FFileSystem.FileExists(LPath) and FFileSystem.TryLoadTextFile(LPath, ANewText)) then
    ANewText := '';
  FCurrentName := AName;
end;

procedure TIdeExampleStore.Save(const ACurrentText: string);
begin
  if not FReadOnly then
    if FCurrentName <> '' then
      WriteText(FCurrentName, ACurrentText);
end;

end.
