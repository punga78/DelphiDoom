{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - source: folder of files                           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Source.Folder;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections,
  System.Generics.Defaults, DelphiDoom.Wad.Types, DelphiDoom.Wad.Intf;

type
  /// <summary>
  ///   A folder: every file below it is a lump named by its path relative to
  ///   the folder, upper case with '/' as separator, sorted by name
  /// </summary>
  TFolderSource = class(TInterfacedObject, IWadSource)
  private
    FPath: string;
    FEntries: TArray<TWadEntry>;
    FFiles: TArray<string>;
  public
    /// <summary>Raises EWadException when the folder does not exist</summary>
    constructor Create(const APath: string);
    function GetName: string;
    function GetKind: TWadSourceKind;
    function GetCount: Integer;
    function GetEntry(AIndex: Integer): TWadEntry;
    function ReadEntry(AIndex: Integer): TBytes;
    procedure ReadEntryInto(AIndex: Integer; ADestination: Pointer);
  end;

implementation

uses
  DelphiDoom.Wad.Name;

type
  TFolderFile = record
    Lump: string;
    Path: string;
  end;

const
  SNoFolder = 'The folder %s does not exist';
  SBadFolderIndex = 'Lump %d does not exist in %s (it has %d)';

{ TFolderSource }

constructor TFolderSource.Create(const APath: string);
var
  LRoot, LFile: string;
  LFiles: TArray<string>;
  LList: TList<TFolderFile>;
  LItem: TFolderFile;
  LIndex: Integer;
begin
  inherited Create;
  if not TDirectory.Exists(APath) then
    raise EWadException.CreateFmt(SNoFolder, [APath]);
  FPath := APath;
  LRoot := IncludeTrailingPathDelimiter(TPath.GetFullPath(APath));
  LFiles := TDirectory.GetFiles(LRoot, '*', TSearchOption.soAllDirectories);
  LList := TList<TFolderFile>.Create;
  try
    for LFile in LFiles do
    begin
      LItem.Path := LFile;
      LItem.Lump := TWadLumpName.UpperCase(
        StringReplace(Copy(LFile, Length(LRoot) + 1, MaxInt), '\', '/', [rfReplaceAll]));
      LList.Add(LItem);
    end;
    LList.Sort(TComparer<TFolderFile>.Construct(
      function(const ALeft, ARight: TFolderFile): Integer
      begin
        Result := CompareStr(ALeft.Lump, ARight.Lump);
      end));
    SetLength(FEntries, LList.Count);
    SetLength(FFiles, LList.Count);
    for LIndex := 0 to LList.Count - 1 do
    begin
      FEntries[LIndex].Name := LList[LIndex].Lump;
      FEntries[LIndex].Offset := 0;
      FEntries[LIndex].Size := Integer(TFile.GetSize(LList[LIndex].Path));
      FFiles[LIndex] := LList[LIndex].Path;
    end;
  finally
    LList.Free;
  end;
end;

function TFolderSource.GetName: string;
begin
  Result := FPath;
end;

function TFolderSource.GetKind: TWadSourceKind;
begin
  Result := TWadSourceKind.Folder;
end;

function TFolderSource.GetCount: Integer;
begin
  Result := Length(FEntries);
end;

function TFolderSource.GetEntry(AIndex: Integer): TWadEntry;
begin
  if (AIndex < 0) or (AIndex >= Length(FEntries)) then
    raise EWadException.CreateFmt(SBadFolderIndex, [AIndex, FPath, Length(FEntries)]);
  Result := FEntries[AIndex];
end;

function TFolderSource.ReadEntry(AIndex: Integer): TBytes;
begin
  GetEntry(AIndex);
  Result := TFile.ReadAllBytes(FFiles[AIndex]);
end;

procedure TFolderSource.ReadEntryInto(AIndex: Integer; ADestination: Pointer);
var
  LBytes: TBytes;
begin
  LBytes := ReadEntry(AIndex);
  if Length(LBytes) > 0 then
    Move(LBytes[0], ADestination^, Length(LBytes));
end;

end.
