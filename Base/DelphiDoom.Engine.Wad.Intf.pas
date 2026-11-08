{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - what the WAD units of the engine ask for               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Wad.Intf;

interface

uses
  d_delphi, DelphiDoom.Wad.Types, DelphiDoom.Wad.Intf, DelphiDoom.Wad.Pak.Intf;

type
  /// <summary>
  ///   The services of the WAD library as the engine needs them: w_wad, w_wadreader,
  ///   w_wadwriter and the PAK file system (TPakFileSystem) receive one from the composition root and do not know the
  ///   classes behind it
  /// </summary>
  IEngineWadServices = interface
    ['{4D2B7C31-8E5A-4F06-9B13-6A0D1E7C2F85}']
    /// <summary>A file or a folder, by what it holds (WAD, PAK, ZIP, WAD2/3, folder, one lump)</summary>
    function OpenPath(const APath: string): IWadSource;
    /// <summary>
    ///   The lumps of a stream of the engine. The stream stays of the caller; the source
    ///   reads the directory now and the lumps when they are asked for. With ASingleLump the
    ///   whole stream is one lump named after AName
    /// </summary>
    function OpenStream(const AName: string; AStream: TDStream; ASingleLump: Boolean): IWadSource;
    /// <summary>
    ///   Wraps ADirectory (a source already read) so that the file APath is opened
    ///   again at every read
    /// </summary>
    function MakeReloadable(const APath: string; const ADirectory: IWadSource): IWadSource;
    function CreateDirectory: IWadDirectory;
    function CreateFinder(const ADirectory: IWadDirectory): IWadFinder;
    function CreateReader(const ADirectory: IWadDirectory): ILumpReader;
    function CreateBuilder(AKind: TWadKind): IWadBuilder;
    /// <summary>An empty index of the PAK file system</summary>
    function CreatePakIndex: IPakIndex;
    /// <summary>The rules of the engine to open a name of the PAK file system, on AIndex</summary>
    function CreatePakResolver(const AIndex: IPakIndex): IPakPathResolver;
  end;

implementation

end.
