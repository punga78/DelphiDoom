{******************************************************************************}
{                                                                              }
{  DDGlbsp.dll: the glbsp node builder for DelphiDoom                          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
library DDGlbsp;

uses
  DelphiDoom.Zlib.Intf in '..\Zlib\DelphiDoom.Zlib.Intf.pas',
  DelphiDoom.Zlib.Inflater in '..\Zlib\DelphiDoom.Zlib.Inflater.pas',
  DelphiDoom.Zlib.Deflater in '..\Zlib\DelphiDoom.Zlib.Deflater.pas',
  DelphiDoom.Zlib.Engine in '..\Zlib\DelphiDoom.Zlib.Engine.pas',
  DelphiDoom.Zlib.Client in '..\Zlib\DelphiDoom.Zlib.Client.pas',
  DelphiDoom.Zlib.Provider in '..\Zlib\DelphiDoom.Zlib.Provider.pas',
  DelphiDoom.Glbsp.Intf in 'DelphiDoom.Glbsp.Intf.pas',
  DelphiDoom.Glbsp.Util in 'DelphiDoom.Glbsp.Util.pas',
  DelphiDoom.Glbsp.Options in 'DelphiDoom.Glbsp.Options.pas',
  DelphiDoom.Glbsp.Wad.Types in 'DelphiDoom.Glbsp.Wad.Types.pas',
  DelphiDoom.Glbsp.Wad.Lump in 'DelphiDoom.Glbsp.Wad.Lump.pas',
  DelphiDoom.Glbsp.Wad.Document in 'DelphiDoom.Glbsp.Wad.Document.pas',
  DelphiDoom.Glbsp.Level.Raw in 'DelphiDoom.Glbsp.Level.Raw.pas',
  DelphiDoom.Glbsp.Level.Types in 'DelphiDoom.Glbsp.Level.Types.pas',
  DelphiDoom.Glbsp.Level.Data in 'DelphiDoom.Glbsp.Level.Data.pas',
  DelphiDoom.Glbsp.Level.Loader in 'DelphiDoom.Glbsp.Level.Loader.pas',
  DelphiDoom.Glbsp.Geometry in 'DelphiDoom.Glbsp.Geometry.pas',
  DelphiDoom.Glbsp.Level.Analyzer in 'DelphiDoom.Glbsp.Level.Analyzer.pas',
  DelphiDoom.Glbsp.Node.SuperBlocks in 'DelphiDoom.Glbsp.Node.SuperBlocks.pas',
  DelphiDoom.Glbsp.Node.Partitioner in 'DelphiDoom.Glbsp.Node.Partitioner.pas',
  DelphiDoom.Glbsp.Node.Builder in 'DelphiDoom.Glbsp.Node.Builder.pas',
  DelphiDoom.Glbsp.Blockmap.Builder in 'DelphiDoom.Glbsp.Blockmap.Builder.pas',
  DelphiDoom.Glbsp.Reject.Builder in 'DelphiDoom.Glbsp.Reject.Builder.pas',
  DelphiDoom.Glbsp.Level.Writer in 'DelphiDoom.Glbsp.Level.Writer.pas',
  DelphiDoom.Glbsp.Level.Processor in 'DelphiDoom.Glbsp.Level.Processor.pas',
  DelphiDoom.Glbsp.Wad.Builder in 'DelphiDoom.Glbsp.Wad.Builder.pas',
  DelphiDoom.Glbsp.Engine in 'DelphiDoom.Glbsp.Engine.pas';

function DDGlbspCreate(out AGlbsp: IGlbsp): Integer; stdcall;
begin
  AGlbsp := nil;
  try
    AGlbsp := TGlbspEngine.Create;
    Result := GLBSP_OK;
  except
    Result := GLBSP_ERR_INTERNAL;
  end;
end;

exports
  DDGlbspCreate;

begin
end.
