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
// DESCRIPTION:
//  WAD Writer
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

unit w_wadwriter;

interface

uses
  d_delphi,
  DelphiDoom.Wad.Intf;

type
  /// <summary>
  ///   Makes a PWAD in memory and writes it to a stream or a file. It is the
  ///   API the engine had, kept on top of the WAD library (Libs\Wad): the
  ///   lumps are in an IWadBuilder. The WAD has the layout of the library (data
  ///   aligned to 4 bytes, directory at the end)
  /// </summary>
  TWadWriter = class(TObject)
  private
    FBuilder: IWadBuilder;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure Clear; virtual;
    /// <summary>Appends a lump of size bytes; the name is cut to upper case, 1 to 8 characters</summary>
    procedure AddData(const lumpname: string; const data: pointer; const size: integer);
    /// <summary>Appends a lump with the characters of the string, one byte each</summary>
    procedure AddString(const lumpname: string; const data: string);
    /// <summary>Appends an empty lump (S_START, F_END ...)</summary>
    procedure AddSeparator(const lumpname: string);
    procedure SaveToStream(const strm: TDStream);
    procedure SaveToFile(const fname: string);
    function NumEntries: integer;
  end;

// AddDataToWAD
function AddDataToWAD(const wad: TWADWriter; const lumpname, data: string): boolean;

implementation

uses
  System.SysUtils,
  DelphiDoom.Wad.Types,
  DelphiDoom.Wad.Factory,
  i_system;

//==============================================================================
//
// TWadWriter.Create
//
//==============================================================================
constructor TWadWriter.Create;
begin
  inherited Create;
  FBuilder := TWadFactory.CreateBuilder(TWadKind.PWad);
end;

//==============================================================================
//
// TWadWriter.Destroy
//
//==============================================================================
destructor TWadWriter.Destroy;
begin
  FBuilder := nil;
  inherited Destroy;
end;

//==============================================================================
//
// TWadWriter.Clear
//
//==============================================================================
procedure TWadWriter.Clear;
begin
  FBuilder.Clear;
end;

//==============================================================================
//
// TWadWriter.AddData
//
//==============================================================================
procedure TWadWriter.AddData(const lumpname: string; const data: pointer; const size: integer);
var
  bytes: TBytes;
begin
  SetLength(bytes, size);
  if size > 0 then
    Move(data^, bytes[0], size);
  try
    FBuilder.AddLump(lumpname, bytes);
  except
    on E: EWadException do
      I_Error('TWadWriter.AddData(): %s'#13#10, [E.Message]);
  end;
end;

//==============================================================================
//
// TWadWriter.AddString
//
//==============================================================================
procedure TWadWriter.AddString(const lumpname: string; const data: string);
var
  bytes: TBytes;
  i: integer;
begin
  SetLength(bytes, Length(data));
  for i := 1 to Length(data) do
    bytes[i - 1] := Byte(Ord(data[i]));
  try
    FBuilder.AddLump(lumpname, bytes);
  except
    on E: EWadException do
      I_Error('TWadWriter.AddString(): %s'#13#10, [E.Message]);
  end;
end;

//==============================================================================
//
// TWadWriter.AddSeparator
//
//==============================================================================
procedure TWadWriter.AddSeparator(const lumpname: string);
begin
  AddData(lumpname, nil, 0);
end;

//==============================================================================
//
// TWadWriter.SaveToStream
//
//==============================================================================
procedure TWadWriter.SaveToStream(const strm: TDStream);
var
  bytes: TBytes;
begin
  bytes := FBuilder.ToBytes;
  strm.Write(bytes[0], Length(bytes));
end;

//==============================================================================
//
// TWadWriter.SaveToFile
//
//==============================================================================
procedure TWadWriter.SaveToFile(const fname: string);
begin
  FBuilder.SaveToFile(fname);
end;

//==============================================================================
//
// TWadWriter.NumEntries
//
//==============================================================================
function TWadWriter.NumEntries: integer;
begin
  Result := FBuilder.Count;
end;

//==============================================================================
//
// AddDataToWAD
//
//==============================================================================
function AddDataToWAD(const wad: TWADWriter; const lumpname, data: string): boolean;
begin
  if wad <> nil then
  begin
    wad.AddString(lumpname, data);
    Result := True;
  end
  else
    Result := False;
end;

end.
