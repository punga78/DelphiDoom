{******************************************************************************}
{                                                                              }
{  DDWad.dll: WAD, PAK, ZIP and folder reader and WAD writer for DelphiDoom    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
library DDWad;

uses
  DelphiDoom.Wad.Types in 'DelphiDoom.Wad.Types.pas',
  DelphiDoom.Wad.Name in 'DelphiDoom.Wad.Name.pas',
  DelphiDoom.Wad.Intf in 'DelphiDoom.Wad.Intf.pas',
  DelphiDoom.Wad.Indicators in 'DelphiDoom.Wad.Indicators.pas',
  DelphiDoom.Wad.Source.Base in 'DelphiDoom.Wad.Source.Base.pas',
  DelphiDoom.Wad.Source.Wad in 'DelphiDoom.Wad.Source.Wad.pas',
  DelphiDoom.Wad.Source.Wad2 in 'DelphiDoom.Wad.Source.Wad2.pas',
  DelphiDoom.Wad.Source.Pak in 'DelphiDoom.Wad.Source.Pak.pas',
  DelphiDoom.Wad.Source.Zip in 'DelphiDoom.Wad.Source.Zip.pas',
  DelphiDoom.Wad.Source.Folder in 'DelphiDoom.Wad.Source.Folder.pas',
  DelphiDoom.Wad.Source.SingleFile in 'DelphiDoom.Wad.Source.SingleFile.pas',
  DelphiDoom.Wad.Directory in 'DelphiDoom.Wad.Directory.pas',
  DelphiDoom.Wad.Builder in 'DelphiDoom.Wad.Builder.pas',
  DelphiDoom.Wad.LumpCache in 'DelphiDoom.Wad.LumpCache.pas',
  DelphiDoom.Wad.Pak.Types in 'DelphiDoom.Wad.Pak.Types.pas',
  DelphiDoom.Wad.Pak.Intf in 'DelphiDoom.Wad.Pak.Intf.pas',
  DelphiDoom.Wad.Pak.Names in 'DelphiDoom.Wad.Pak.Names.pas',
  DelphiDoom.Wad.Pak.Index in 'DelphiDoom.Wad.Pak.Index.pas',
  DelphiDoom.Wad.Pak.PathResolver in 'DelphiDoom.Wad.Pak.PathResolver.pas',
  DelphiDoom.Wad.Factory in 'DelphiDoom.Wad.Factory.pas',
  DelphiDoom.Wad.Dll.Intf in 'DelphiDoom.Wad.Dll.Intf.pas',
  DelphiDoom.Wad.Dll.Text in 'DelphiDoom.Wad.Dll.Text.pas',
  DelphiDoom.Wad.Dll.ErrorSink in 'DelphiDoom.Wad.Dll.ErrorSink.pas',
  DelphiDoom.Wad.Dll.SourceAdapter in 'DelphiDoom.Wad.Dll.SourceAdapter.pas',
  DelphiDoom.Wad.Dll.DirectoryAdapter in 'DelphiDoom.Wad.Dll.DirectoryAdapter.pas',
  DelphiDoom.Wad.Dll.BuilderAdapter in 'DelphiDoom.Wad.Dll.BuilderAdapter.pas',
  DelphiDoom.Wad.Dll.Engine in 'DelphiDoom.Wad.Dll.Engine.pas';

function DDWadCreate(out AWad: IWadDll): Integer; stdcall;
begin
  AWad := nil;
  try
    AWad := TWadDllEngine.Create;
    Result := WADDLL_OK;
  except
    Result := WADDLL_ERR_OUT_OF_MEMORY;
  end;
end;

exports
  DDWadCreate;

begin
end.