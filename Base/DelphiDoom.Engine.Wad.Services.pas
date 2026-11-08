{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - WAD services made of the classes of Libs\Wad           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Wad.Services;

interface

uses
  d_delphi, DelphiDoom.Wad.Types, DelphiDoom.Wad.Intf, DelphiDoom.Wad.Pak.Intf, DelphiDoom.Engine.Wad.Intf;

type
  /// <summary>IEngineWadServices on top of TWadFactory and the sources of the library</summary>
  TEngineWadServices = class(TInterfacedObject, IEngineWadServices)
  public
    function OpenPath(const APath: string): IWadSource;
    function OpenStream(const AName: string; AStream: TDStream; ASingleLump: Boolean): IWadSource;
    function MakeReloadable(const APath: string; const ADirectory: IWadSource): IWadSource;
    function CreateDirectory: IWadDirectory;
    function CreateFinder(const ADirectory: IWadDirectory): IWadFinder;
    function CreateReader(const ADirectory: IWadDirectory): ILumpReader;
    function CreateBuilder(AKind: TWadKind): IWadBuilder;
    function CreatePakIndex: IPakIndex;
    function CreatePakResolver(const AIndex: IPakIndex): IPakPathResolver;
  end;

implementation

uses
  DelphiDoom.Wad.Factory,
  DelphiDoom.Wad.Source.Wad,
  DelphiDoom.Wad.Source.SingleFile,
  DelphiDoom.Wad.DStreamAdapter,
  DelphiDoom.Wad.ReloadableSource;

{ TEngineWadServices }

function TEngineWadServices.OpenPath(const APath: string): IWadSource;
begin
  Result := TWadFactory.OpenPath(APath);
end;

function TEngineWadServices.OpenStream(const AName: string; AStream: TDStream;
  ASingleLump: Boolean): IWadSource;
var
  LAdapter: TDStreamAdapter;
begin
  // the source owns the adapter (and frees it if its constructor fails), not the stream
  LAdapter := TDStreamAdapter.Create(AStream);
  if ASingleLump then
    Result := TSingleFileSource.Create(AName, LAdapter, True)
  else
    Result := TWadFileSource.Create(AName, LAdapter, True);
end;

function TEngineWadServices.MakeReloadable(const APath: string;
  const ADirectory: IWadSource): IWadSource;
begin
  Result := TReloadableWadSource.Create(APath, ADirectory);
end;

function TEngineWadServices.CreateDirectory: IWadDirectory;
begin
  Result := TWadFactory.CreateDirectory;
end;

function TEngineWadServices.CreateFinder(const ADirectory: IWadDirectory): IWadFinder;
begin
  Result := TWadFactory.CreateFinder(ADirectory);
end;

function TEngineWadServices.CreateReader(const ADirectory: IWadDirectory): ILumpReader;
begin
  Result := TWadFactory.CreateReader(ADirectory);
end;

function TEngineWadServices.CreateBuilder(AKind: TWadKind): IWadBuilder;
begin
  Result := TWadFactory.CreateBuilder(AKind);
end;

function TEngineWadServices.CreatePakIndex: IPakIndex;
begin
  Result := TWadFactory.CreatePakIndex;
end;

function TEngineWadServices.CreatePakResolver(const AIndex: IPakIndex): IPakPathResolver;
begin
  Result := TWadFactory.CreatePakResolver(AIndex);
end;

end.
