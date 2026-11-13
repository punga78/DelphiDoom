{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the table of the campaign maps                    }
{                                                                              }
{  Port of war1 (acoto87/war1), wcamp_getCampaignData and                      }
{  wcamp_tryGetMapType of war_campaigns.c, (c) 2019 Alejandro Coto Gutierrez,  }
{  zlib License (see Libs\War\LICENSE-war1.txt). This is an altered version.   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Campaign.Catalog;

interface

uses
  DelphiDoom.War.Level.Types, DelphiDoom.War.Campaign.Types, DelphiDoom.War.Campaign.Intf;

type
  /// <summary>The 25 entries of the table of the campaigns; the table is given to the constructor</summary>
  TWarCampaigns = class(TInterfacedObject, IWarCampaigns)
  strict private
    FData: TArray<TWarCampaignMapData>;
  public
    /// <summary>With the table of the original (DelphiDoom.War.Campaign.Data)</summary>
    constructor Create; overload;
    constructor Create(const AData: TArray<TWarCampaignMapData>); overload;
    function GetData(AMapType: Integer): TWarCampaignMapData;
    function TryGetMapType(ARace: TWarRace; AMission: Integer; out AMapType: Integer): Boolean;
    function MapTypeOfLevel(AIndex: Integer): Integer;
    function IsDemoLastLevel(AIndex: Integer): Boolean;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.War.Types, DelphiDoom.War.Campaign.Data;

{ TWarCampaigns }

constructor TWarCampaigns.Create;
begin
  Create(WarDefaultCampaignData);
end;

constructor TWarCampaigns.Create(const AData: TArray<TWarCampaignMapData>);
begin
  inherited Create;
  if Length(AData) <> WAR_CAMPAIGN_COUNT then
    raise EWarException.CreateFmt(SWarIndexOutOfRange, [Length(AData), WAR_CAMPAIGN_COUNT]);
  FData := Copy(AData);
end;

function TWarCampaigns.GetData(AMapType: Integer): TWarCampaignMapData;
var
  LPosition: Integer;
begin
  for LPosition := 0 to High(FData) do
    if FData[LPosition].MapType = AMapType then
      Exit(FData[LPosition]);
  // the original logged a warning and indexed the table with WAR_CAMPAIGN_CUSTOM (141): past its end
  Result := FData[High(FData)];
end;

function TWarCampaigns.TryGetMapType(ARace: TWarRace; AMission: Integer; out AMapType: Integer): Boolean;
begin
  Result := (AMission >= 1) and (AMission <= WAR_CAMPAIGN_MISSIONS) and (ARace in [wraHumans, wraOrcs]);
  if not Result then
  begin
    AMapType := 0;
    Exit;
  end;
  if ARace = wraHumans then
    AMapType := WAR_CAMPAIGN_HUMANS_01 + 2 * (AMission - 1)
  else
    AMapType := WAR_CAMPAIGN_ORCS_01 + 2 * (AMission - 1);
end;

function TWarCampaigns.MapTypeOfLevel(AIndex: Integer): Integer;
begin
  if (AIndex >= WAR_CAMPAIGN_HUMANS_01) and (AIndex <= WAR_CAMPAIGN_ORCS_12) then
    Result := AIndex
  else
    Result := WAR_CAMPAIGN_CUSTOM;
end;

function TWarCampaigns.IsDemoLastLevel(AIndex: Integer): Boolean;
begin
  Result := (AIndex = WAR_CAMPAIGN_HUMANS_02) or (AIndex = WAR_CAMPAIGN_ORCS_02);
end;

end.
