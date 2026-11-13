{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the factory of the levels                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Level.Factory;

interface

uses
  DelphiDoom.War.Intf, DelphiDoom.War.Level.Intf, DelphiDoom.War.Campaign.Intf;

type
  /// <summary>The place that knows the concrete classes of levels, campaigns and objectives</summary>
  TWarLevelFactory = class
  public
    /// <summary>The reader of the levels of an archive</summary>
    class function CreateLevelLoader(const AArchive: IWarArchive; const ACatalog: IWarCatalog): IWarLevelLoader; static;
    /// <summary>The table of the 24 campaign maps and the custom map</summary>
    class function CreateCampaigns: IWarCampaigns; static;
    /// <summary>The victory and defeat conditions</summary>
    class function CreateObjectives: IWarObjectives; static;
  end;

implementation

uses
  DelphiDoom.War.Level.Loader, DelphiDoom.War.Campaign.Catalog, DelphiDoom.War.Campaign.Objectives;

{ TWarLevelFactory }

class function TWarLevelFactory.CreateLevelLoader(const AArchive: IWarArchive;
  const ACatalog: IWarCatalog): IWarLevelLoader;
begin
  Result := TWarLevelLoader.Create(AArchive, ACatalog);
end;

class function TWarLevelFactory.CreateCampaigns: IWarCampaigns;
begin
  Result := TWarCampaigns.Create;
end;

class function TWarLevelFactory.CreateObjectives: IWarObjectives;
begin
  Result := TWarObjectives.Create;
end;

end.
