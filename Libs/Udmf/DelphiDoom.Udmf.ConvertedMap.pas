{******************************************************************************}
{                                                                              }
{  DelphiDoom: UDMF library - the map as lumps                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Udmf.ConvertedMap;

interface

uses
  System.SysUtils, DelphiDoom.Udmf.Types, DelphiDoom.Udmf.Intf;

type
  /// <summary>The records of a converted map, one lump each, and what is needed to say them in order</summary>
  TUdmfConvertedMap = class(TInterfacedObject, IUdmfConvertedMap)
  private
    FNamespace: string;
    FLineTranslate: Boolean;
    FThingCount: Integer;
    FLineCount: Integer;
    FSideCount: Integer;
    FVertexCount: Integer;
    FSectorCount: Integer;
    FThings: TBytes;
    FLines: TBytes;
    FSides: TBytes;
    FVertexes: TBytes;
    FSectors: TBytes;
    FExtraThings: TBytes;
    FExtraLines: TBytes;
    FExtraSides: TBytes;
    FExtraVertexes: TBytes;
    FExtraSectors: TBytes;
  public
    constructor Create(const ANamespace: string; ALineTranslate: Boolean;
      AThingCount, ALineCount, ASideCount, AVertexCount, ASectorCount: Integer;
      const AThings, ALines, ASides, AVertexes, ASectors: TBytes;
      const AExtraThings, AExtraLines, AExtraSides, AExtraVertexes, AExtraSectors: TBytes);
    function GetNamespace: string;
    function GetLineTranslate: Boolean;
    function GetThingCount: Integer;
    function GetLineCount: Integer;
    function GetSideCount: Integer;
    function GetVertexCount: Integer;
    function GetSectorCount: Integer;
    function GetExtraThings: TBytes;
    function GetExtraLines: TBytes;
    function GetExtraSides: TBytes;
    function GetExtraVertexes: TBytes;
    function GetExtraSectors: TBytes;
    function GetLumps(const AMapName: string; const ABehavior, AScripts: TBytes): TArray<TUdmfLump>;
  end;

implementation

uses
  DelphiDoom.Udmf.Text;

{ TUdmfConvertedMap }

constructor TUdmfConvertedMap.Create(const ANamespace: string; ALineTranslate: Boolean;
  AThingCount, ALineCount, ASideCount, AVertexCount, ASectorCount: Integer;
  const AThings, ALines, ASides, AVertexes, ASectors: TBytes;
  const AExtraThings, AExtraLines, AExtraSides, AExtraVertexes, AExtraSectors: TBytes);
begin
  inherited Create;
  FNamespace := ANamespace;
  FLineTranslate := ALineTranslate;
  FThingCount := AThingCount;
  FLineCount := ALineCount;
  FSideCount := ASideCount;
  FVertexCount := AVertexCount;
  FSectorCount := ASectorCount;
  FThings := AThings;
  FLines := ALines;
  FSides := ASides;
  FVertexes := AVertexes;
  FSectors := ASectors;
  FExtraThings := AExtraThings;
  FExtraLines := AExtraLines;
  FExtraSides := AExtraSides;
  FExtraVertexes := AExtraVertexes;
  FExtraSectors := AExtraSectors;
end;

function TUdmfConvertedMap.GetNamespace: string;
begin
  Result := FNamespace;
end;

function TUdmfConvertedMap.GetLineTranslate: Boolean;
begin
  Result := FLineTranslate;
end;

function TUdmfConvertedMap.GetThingCount: Integer;
begin
  Result := FThingCount;
end;

function TUdmfConvertedMap.GetLineCount: Integer;
begin
  Result := FLineCount;
end;

function TUdmfConvertedMap.GetSideCount: Integer;
begin
  Result := FSideCount;
end;

function TUdmfConvertedMap.GetVertexCount: Integer;
begin
  Result := FVertexCount;
end;

function TUdmfConvertedMap.GetSectorCount: Integer;
begin
  Result := FSectorCount;
end;

function TUdmfConvertedMap.GetExtraThings: TBytes;
begin
  Result := FExtraThings;
end;

function TUdmfConvertedMap.GetExtraLines: TBytes;
begin
  Result := FExtraLines;
end;

function TUdmfConvertedMap.GetExtraSides: TBytes;
begin
  Result := FExtraSides;
end;

function TUdmfConvertedMap.GetExtraVertexes: TBytes;
begin
  Result := FExtraVertexes;
end;

function TUdmfConvertedMap.GetExtraSectors: TBytes;
begin
  Result := FExtraSectors;
end;

function TUdmfConvertedMap.GetLumps(const AMapName: string;
  const ABehavior, AScripts: TBytes): TArray<TUdmfLump>;
var
  LNamespaceBytes: TBytes;
  LIndex: Integer;

  procedure Put(const AName: string; const AData: TBytes);
  begin
    Result[LIndex].Name := AName;
    Result[LIndex].Data := AData;
    Inc(LIndex);
  end;

begin
  // the namespace as the one byte characters that it has (the old code wrote two bytes for each)
  SetLength(LNamespaceBytes, Length(FNamespace));
  for LIndex := 1 to Length(FNamespace) do
    LNamespaceBytes[LIndex - 1] := Byte(Ord(FNamespace[LIndex]));

  SetLength(Result, 19);
  LIndex := 0;
  Put(TUdmfText.ToUpper(AMapName), nil);
  Put('THINGS', FThings);
  Put('LINEDEFS', FLines);
  Put('SIDEDEFS', FSides);
  Put('VERTEXES', FVertexes);
  Put('SEGS', nil);
  Put('SSECTORS', nil);
  Put('NODES', nil);
  Put('SECTORS', FSectors);
  Put('REJECT', nil);
  Put('BLOCKMAP', nil);
  Put('BEHAVIOR', ABehavior);
  Put('SCRIPTS', AScripts);
  Put(MLN_THINGS2, FExtraThings);
  Put(MLN_SECTORS2, FExtraSectors);
  Put(MLN_VERTEX2, FExtraVertexes);
  Put(MLN_LINEDEF2, FExtraLines);
  Put(MLN_SIDEDEF2, FExtraSides);
  Put(MLN_NSPACE, LNamespaceBytes);
end;

end.