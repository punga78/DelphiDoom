//------------------------------------------------------------------------------
//
//  DelphiDoom is a source port of the game Doom and it is
//  based on original Linux Doom as published by "id Software"
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2004-2022 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}


unit w_wadreader;

interface

uses
  d_delphi,
  DelphiDoom.Wad.Intf,
  DelphiDoom.Engine.Wad.Intf;

type
  /// <summary>
  ///   Reads the lumps of one WAD file, apart from the lumps the game has loaded.
  ///   It is the API the engine had, kept on top of the WAD library (Libs\Wad)
  /// </summary>
  TWadReader = class
  private
    FSource: IWadSource;
    FDirectory: IWadDirectory;
    FFinder: IWadFinder;
    ffilename: string;
    class var FServices: IEngineWadServices;
  public
    /// <summary>The services the readers work on; the composition root calls it once</summary>
    class procedure Configure(const AServices: IEngineWadServices); static;
    constructor Create; virtual;
    destructor Destroy; override;
    procedure Clear; virtual;
    /// <summary>Opens the file; a missing or damaged file leaves the reader empty and warns</summary>
    procedure OpenWadFile(const aname: string);
    function EntryAsString(const id: integer): string; overload;
    function EntryAsString(const aname: string): string; overload;
    /// <summary>Gives a buffer made with malloc: the caller frees it with memfree</summary>
    function ReadEntry(const id: integer; var buf: pointer; var bufsize: integer): boolean; overload;
    function ReadEntry(const aname: string; var buf: pointer; var bufsize: integer): boolean; overload;
    function EntryName(const id: integer): string;
    /// <summary>The last lump with that name (-1 when none)</summary>
    function EntryId(const aname: string): integer;
    function NumEntries: integer;
    property FileName: string read ffilename;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Wad.Types,
  i_system;

//==============================================================================
//
// TWadReader.Create
//
//==============================================================================
class procedure TWadReader.Configure(const AServices: IEngineWadServices);
begin
  FServices := AServices;
end;

//==============================================================================
//
// TWadReader.Create
//
//==============================================================================
constructor TWadReader.Create;
begin
  inherited Create;
  if FServices = nil then
    I_Error('TWadReader.Create(): the WAD services were not configured (TWadReader.Configure)');
  ffilename := '';
end;

//==============================================================================
//
// TWadReader.Destroy
//
//==============================================================================
destructor TWadReader.Destroy;
begin
  Clear;
  inherited Destroy;
end;

//==============================================================================
//
// TWadReader.Clear
//
//==============================================================================
procedure TWadReader.Clear;
begin
  FFinder := nil;
  FDirectory := nil;
  FSource := nil;
  ffilename := '';
end;

//==============================================================================
//
// TWadReader.OpenWadFile
//
//==============================================================================
procedure TWadReader.OpenWadFile(const aname: string);
var
  source: IWadSource;
begin
  if aname = '' then
    Exit;
  Clear;
  if not fexists(aname) then
  begin
    I_Warning('TWadReader.OpenWadFile(): Can not find WAD file ' + aname + #13#10);
    Exit;
  end;

  try
    source := FServices.OpenPath(aname);
  except
    on E: EWadException do
    begin
      I_Warning('TWadReader.OpenWadFile(): Invalid WAD file ' + aname + #13#10);
      Exit;
    end;
  end;
  if source.Kind <> TWadSourceKind.Wad then
  begin
    I_Warning('TWadReader.OpenWadFile(): Invalid WAD file ' + aname + #13#10);
    Exit;
  end;

  FSource := source;
  FDirectory := FServices.CreateDirectory;
  FDirectory.AddSource(source);
  FFinder := FServices.CreateFinder(FDirectory);
  ffilename := aname;
end;

//==============================================================================
//
// TWadReader.EntryAsString
//
//==============================================================================
function TWadReader.EntryAsString(const id: integer): string;
var
  a: AnsiString;
begin
  Result := '';
  if (FSource <> nil) and (id >= 0) and (id < FSource.Count) then
  begin
    SetLength(a, FSource.Entries[id].Size);
    if Length(a) > 0 then
      FSource.ReadEntryInto(id, @a[1]);
    Result := string(a);
  end;
end;

//==============================================================================
//
// TWadReader.EntryAsString
//
//==============================================================================
function TWadReader.EntryAsString(const aname: string): string;
var
  id: integer;
begin
  id := EntryId(aname);
  if id >= 0 then
    Result := EntryAsString(id)
  else
    Result := '';
end;

//==============================================================================
//
// TWadReader.ReadEntry
//
//==============================================================================
function TWadReader.ReadEntry(const id: integer; var buf: pointer; var bufsize: integer): boolean;
begin
  if (FSource <> nil) and (id >= 0) and (id < FSource.Count) then
  begin
    bufsize := FSource.Entries[id].Size;
    buf := malloc(bufsize);
    FSource.ReadEntryInto(id, buf);
    Result := true;
  end
  else
    Result := false;
end;

//==============================================================================
//
// TWadReader.ReadEntry
//
//==============================================================================
function TWadReader.ReadEntry(const aname: string; var buf: pointer; var bufsize: integer): boolean;
var
  id: integer;
begin
  id := EntryId(aname);
  if id >= 0 then
    Result := ReadEntry(id, buf, bufsize)
  else
    Result := false;
end;

//==============================================================================
//
// TWadReader.EntryName
//
//==============================================================================
function TWadReader.EntryName(const id: integer): string;
begin
  if (FSource <> nil) and (id >= 0) and (id < FSource.Count) then
    Result := FSource.Entries[id].Name
  else
    Result := '';
end;

//==============================================================================
//
// TWadReader.EntryId
//
//==============================================================================
function TWadReader.EntryId(const aname: string): integer;
begin
  if FFinder <> nil then
    Result := FFinder.CheckNumForName(aname)
  else
    Result := -1;
end;

//==============================================================================
//
// TWadReader.NumEntries
//
//==============================================================================
function TWadReader.NumEntries: integer;
begin
  if FSource <> nil then
    Result := FSource.Count
  else
    Result := 0;
end;

end.
