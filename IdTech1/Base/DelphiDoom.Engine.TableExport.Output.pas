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

unit DelphiDoom.Engine.TableExport.Output;

interface

uses
  DelphiDoom.TableExport.Saver.Intf;

type
  /// <summary>The console, the folder of the saved files and the disk, for the saving of the exports</summary>
  TEngineExportOutput = class(TInterfacedObject, ITableExportOutput)
  public
    procedure Print(const AText: string);
    function SaveFileName(const AName: string): string;
    procedure SaveLines(const AFileName: string; const ALines: TArray<string>);
  end;

implementation

uses
  d_delphi,
  m_argv;

{ TEngineExportOutput }

procedure TEngineExportOutput.Print(const AText: string);
begin
  printf('%s', [AText]);
end;

function TEngineExportOutput.SaveFileName(const AName: string): string;
begin
  Result := M_SaveFileName(AName);
end;

procedure TEngineExportOutput.SaveLines(const AFileName: string; const ALines: TArray<string>);
var
  LList: TDStringList;
  LIndex: Integer;
begin
  LList := TDStringList.Create;
  try
    for LIndex := 0 to Length(ALines) - 1 do
      LList.Add(ALines[LIndex]);
    LList.SaveToFile(AFileName);
  finally
    LList.Free;
  end;
end;

end.
