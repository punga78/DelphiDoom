{******************************************************************************}
{                                                                              }
{  DelphiDoom: UDMF library - a game as the sum of its formats                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Udmf.Profile;

interface

uses
  DelphiDoom.Udmf.Intf;

type
  /// <summary>The name of a game and the format that it has for each kind of thing of the map</summary>
  TUdmfProfile = class(TInterfacedObject, IUdmfProfile)
  private
    FGameName: string;
    FThings: IUdmfThingFormat;
    FLines: IUdmfLineFormat;
    FSides: IUdmfSideFormat;
    FVertexes: IUdmfVertexFormat;
    FSectors: IUdmfSectorFormat;
  public
    constructor Create(const AGameName: string; const AThings: IUdmfThingFormat;
      const ALines: IUdmfLineFormat; const ASides: IUdmfSideFormat;
      const AVertexes: IUdmfVertexFormat; const ASectors: IUdmfSectorFormat);
    function GetGameName: string;
    function GetThings: IUdmfThingFormat;
    function GetLines: IUdmfLineFormat;
    function GetSides: IUdmfSideFormat;
    function GetVertexes: IUdmfVertexFormat;
    function GetSectors: IUdmfSectorFormat;
  end;

implementation

{ TUdmfProfile }

constructor TUdmfProfile.Create(const AGameName: string; const AThings: IUdmfThingFormat;
  const ALines: IUdmfLineFormat; const ASides: IUdmfSideFormat;
  const AVertexes: IUdmfVertexFormat; const ASectors: IUdmfSectorFormat);
begin
  inherited Create;
  FGameName := AGameName;
  FThings := AThings;
  FLines := ALines;
  FSides := ASides;
  FVertexes := AVertexes;
  FSectors := ASectors;
end;

function TUdmfProfile.GetGameName: string;
begin
  Result := FGameName;
end;

function TUdmfProfile.GetThings: IUdmfThingFormat;
begin
  Result := FThings;
end;

function TUdmfProfile.GetLines: IUdmfLineFormat;
begin
  Result := FLines;
end;

function TUdmfProfile.GetSides: IUdmfSideFormat;
begin
  Result := FSides;
end;

function TUdmfProfile.GetVertexes: IUdmfVertexFormat;
begin
  Result := FVertexes;
end;

function TUdmfProfile.GetSectors: IUdmfSectorFormat;
begin
  Result := FSectors;
end;

end.