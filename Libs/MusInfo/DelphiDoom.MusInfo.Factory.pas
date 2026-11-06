{******************************************************************************}
{                                                                              }
{  DelphiDoom: MUSINFO library - the factory: the composition root            }
{  Copyright (C) 2004-2023 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MusInfo.Factory;

interface

uses
  DelphiDoom.Logging.Intf, DelphiDoom.MusInfo.Intf;

type
  /// <summary>The only place that knows the classes behind the MUSINFO contracts</summary>
  TMusInfoFactory = class
  public
    /// <param name="ALog">May be nil</param>
    class function CreateParser(const ALog: ILog): IMusInfoParser; static;
    /// <param name="ALog">May be nil</param>
    class function CreateCatalog(const AMusic: IMusInfoMusicResolver;
      const ALog: ILog): IMusInfoCatalog; static;
    class function CreateLoader(const ASource: IMusInfoTextSource; const AParser: IMusInfoParser;
      const ACatalog: IMusInfoCatalog): IMusInfoLoader; static;
  end;

implementation

uses
  DelphiDoom.MusInfo.Parser, DelphiDoom.MusInfo.Catalog, DelphiDoom.MusInfo.Loader;

{ TMusInfoFactory }

class function TMusInfoFactory.CreateParser(const ALog: ILog): IMusInfoParser;
begin
  Result := TMusInfoParser.Create(ALog);
end;

class function TMusInfoFactory.CreateCatalog(const AMusic: IMusInfoMusicResolver;
  const ALog: ILog): IMusInfoCatalog;
begin
  Result := TMusInfoCatalog.Create(AMusic, ALog);
end;

class function TMusInfoFactory.CreateLoader(const ASource: IMusInfoTextSource;
  const AParser: IMusInfoParser; const ACatalog: IMusInfoCatalog): IMusInfoLoader;
begin
  Result := TMusInfoLoader.Create(ASource, AParser, ACatalog);
end;

end.
