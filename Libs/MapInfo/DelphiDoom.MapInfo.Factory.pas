{******************************************************************************}
{                                                                              }
{  DelphiDoom: UMAPINFO library - the factory: the composition root           }
{  Copyright (C) 2004-2023 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapInfo.Factory;

interface

uses
  DelphiDoom.Logging.Intf, DelphiDoom.MapInfo.Intf;

type
  /// <summary>The only place that knows the classes behind the UMAPINFO contracts</summary>
  TMapInfoFactory = class
  public
    class function CreateCatalog(const AMusic: IMapMusicResolver): IMapInfoCatalog; static;
    /// <param name="ALog">May be nil</param>
    class function CreateParser(const AServices: TMapInfoServices;
      const ALog: ILog): IMapInfoParser; static;
    /// <param name="AFilter">May be nil</param>
    class function CreateLoader(const ASource: IMapInfoTextSource;
      const AFilter: IMapInfoTextFilter; const AParser: IMapInfoParser;
      const ACatalog: IMapInfoCatalog): IMapInfoLoader; static;
    /// <summary>The rule of Doom and Heretic: a line needs a tag, unless its special ends the level</summary>
    class function CreateTaggedBossActionRule(const AExitSpecials: TArray<Integer>): IMapBossActionRule; static;
    /// <summary>The rule of Strife: every line is taken</summary>
    class function CreateOpenBossActionRule: IMapBossActionRule; static;
  end;

implementation

uses
  DelphiDoom.MapInfo.Catalog, DelphiDoom.MapInfo.Parser, DelphiDoom.MapInfo.Loader,
  DelphiDoom.MapInfo.BossActionRule;

{ TMapInfoFactory }

class function TMapInfoFactory.CreateCatalog(const AMusic: IMapMusicResolver): IMapInfoCatalog;
begin
  Result := TMapInfoCatalog.Create(AMusic);
end;

class function TMapInfoFactory.CreateParser(const AServices: TMapInfoServices;
  const ALog: ILog): IMapInfoParser;
begin
  Result := TMapInfoParser.Create(AServices, ALog);
end;

class function TMapInfoFactory.CreateLoader(const ASource: IMapInfoTextSource;
  const AFilter: IMapInfoTextFilter; const AParser: IMapInfoParser;
  const ACatalog: IMapInfoCatalog): IMapInfoLoader;
begin
  Result := TMapInfoLoader.Create(ASource, AFilter, AParser, ACatalog);
end;

class function TMapInfoFactory.CreateTaggedBossActionRule(
  const AExitSpecials: TArray<Integer>): IMapBossActionRule;
begin
  Result := TMapInfoBossActionRule.Create(True, AExitSpecials);
end;

class function TMapInfoFactory.CreateOpenBossActionRule: IMapBossActionRule;
begin
  Result := TMapInfoBossActionRule.Create(False, nil);
end;

end.
