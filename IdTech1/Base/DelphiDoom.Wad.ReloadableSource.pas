{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD - a WAD file that is opened again at every read             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.ReloadableSource;

interface

uses
  System.SysUtils, DelphiDoom.Wad.Types, DelphiDoom.Wad.Intf;

type
  /// <summary>
  ///   The lumps of a file that an editor can write while the game runs (a file
  ///   added with a tilde): the directory is the one already read, the file is
  ///   not kept open and is opened for each lump that is read
  /// </summary>
  TReloadableWadSource = class(TInterfacedObject, IWadSource)
  private
    FPath: string;
    FDirectory: IWadSource;
  public
    /// <summary>ADirectory gives the names, positions and sizes; it is never used to read</summary>
    constructor Create(const APath: string; const ADirectory: IWadSource);
    function GetName: string;
    function GetKind: TWadSourceKind;
    function GetCount: Integer;
    function GetEntry(AIndex: Integer): TWadEntry;
    function ReadEntry(AIndex: Integer): TBytes;
    procedure ReadEntryInto(AIndex: Integer; ADestination: Pointer);
  end;

implementation

uses
  d_delphi, i_system;

const
  SCannotOpen = 'Couldn''t open %s';
  SShortRead = 'Only read %d of %d bytes of lump %s of %s';

{ TReloadableWadSource }

constructor TReloadableWadSource.Create(const APath: string; const ADirectory: IWadSource);
begin
  inherited Create;
  FPath := APath;
  FDirectory := ADirectory;
end;

function TReloadableWadSource.GetName: string;
begin
  Result := FPath;
end;

function TReloadableWadSource.GetKind: TWadSourceKind;
begin
  Result := TWadSourceKind.Wad;
end;

function TReloadableWadSource.GetCount: Integer;
begin
  Result := FDirectory.Count;
end;

function TReloadableWadSource.GetEntry(AIndex: Integer): TWadEntry;
begin
  Result := FDirectory.Entries[AIndex];
end;

function TReloadableWadSource.ReadEntry(AIndex: Integer): TBytes;
begin
  SetLength(Result, GetEntry(AIndex).Size);
  if Length(Result) > 0 then
    ReadEntryInto(AIndex, @Result[0]);
end;

procedure TReloadableWadSource.ReadEntryInto(AIndex: Integer; ADestination: Pointer);
var
  LEntry: TWadEntry;
  LHandle: TDStream;
  LRead: Integer;
begin
  LEntry := GetEntry(AIndex);
  if LEntry.Size = 0 then
    Exit;
  if not fexists(FPath) then
    raise EWadException.CreateFmt(SCannotOpen, [FPath]);
  try
    LHandle := TCachedFile.Create(FPath, fOpenReadOnly);
  except
    raise EWadException.CreateFmt(SCannotOpen, [FPath]);
  end;
  try
    LHandle.OnBeginBusy := I_BeginDiskBusy;
    LHandle.Seek(LEntry.Offset, sFromBeginning);
    LRead := LHandle.Read(ADestination^, LEntry.Size);
  finally
    LHandle.Free;
  end;
  if LRead < LEntry.Size then
    raise EWadException.CreateFmt(SShortRead, [LRead, LEntry.Size, LEntry.Name, FPath]);
end;

end.
