{******************************************************************************}
{                                                                              }
{  DelphiDoom: UDMF library - the converter                                   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Udmf.Converter;

interface

uses
  System.SysUtils, DelphiDoom.Udmf.Intf, DelphiDoom.Logging.Intf;

type
  /// <summary>
  ///   Reads the text of a map and writes its records, the ones that a vanilla map has and the
  ///   extra ones, as the profile of the game says. Nothing is kept from a map to the next
  /// </summary>
  TUdmfConverter = class(TInterfacedObject, IUdmfConverter)
  private
    FProfile: IUdmfProfile;
    FLog: ILog;
  public
    /// <param name="ALog">May be nil</param>
    constructor Create(const AProfile: IUdmfProfile; const ALog: ILog);
    function GetProfile: IUdmfProfile;
    function Convert(const AText: string): IUdmfConvertedMap;
  end;

implementation

uses
  DelphiDoom.Udmf.Map, DelphiDoom.Udmf.Parser, DelphiDoom.Udmf.BinaryWriter,
  DelphiDoom.Udmf.ConvertedMap;

{ TUdmfConverter }

constructor TUdmfConverter.Create(const AProfile: IUdmfProfile; const ALog: ILog);
begin
  inherited Create;
  FProfile := AProfile;
  FLog := ALog;
end;

function TUdmfConverter.GetProfile: IUdmfProfile;
begin
  Result := FProfile;
end;

function TUdmfConverter.Convert(const AText: string): IUdmfConvertedMap;
var
  LParser: TUdmfParser;
  LMap: TUdmfMap;
  LBase: TUdmfBinaryWriter;
  LExtra: TUdmfBinaryWriter;
  LThings, LLines, LSides, LVertexes, LSectors: TBytes;
  LExtraThings, LExtraLines, LExtraSides, LExtraVertexes, LExtraSectors: TBytes;
  LIndex: Integer;
begin
  LParser := TUdmfParser.Create(FProfile, FLog);
  try
    LMap := LParser.Parse(AText);
  finally
    LParser.Free;
  end;
  try
    LBase := TUdmfBinaryWriter.Create;
    LExtra := TUdmfBinaryWriter.Create;
    try
      for LIndex := 0 to LMap.Things.Count - 1 do
      begin
        FProfile.Things.WriteBase(LMap.Things[LIndex], LBase);
        FProfile.Things.WriteExtra(LMap.Things[LIndex], LExtra);
      end;
      LThings := LBase.ToBytes;
      LExtraThings := LExtra.ToBytes;
    finally
      LBase.Free;
      LExtra.Free;
    end;

    LBase := TUdmfBinaryWriter.Create;
    LExtra := TUdmfBinaryWriter.Create;
    try
      for LIndex := 0 to LMap.Lines.Count - 1 do
      begin
        FProfile.Lines.WriteBase(LMap.Lines[LIndex], LBase);
        FProfile.Lines.WriteExtra(LMap.Lines[LIndex], LExtra);
      end;
      LLines := LBase.ToBytes;
      LExtraLines := LExtra.ToBytes;
    finally
      LBase.Free;
      LExtra.Free;
    end;

    LBase := TUdmfBinaryWriter.Create;
    LExtra := TUdmfBinaryWriter.Create;
    try
      for LIndex := 0 to LMap.Sides.Count - 1 do
      begin
        FProfile.Sides.WriteBase(LMap.Sides[LIndex], LBase);
        FProfile.Sides.WriteExtra(LMap.Sides[LIndex], LExtra);
      end;
      LSides := LBase.ToBytes;
      LExtraSides := LExtra.ToBytes;
    finally
      LBase.Free;
      LExtra.Free;
    end;

    LBase := TUdmfBinaryWriter.Create;
    LExtra := TUdmfBinaryWriter.Create;
    try
      for LIndex := 0 to LMap.Vertexes.Count - 1 do
      begin
        FProfile.Vertexes.WriteBase(LMap.Vertexes[LIndex], LBase);
        FProfile.Vertexes.WriteExtra(LMap.Vertexes[LIndex], LExtra);
      end;
      LVertexes := LBase.ToBytes;
      LExtraVertexes := LExtra.ToBytes;
    finally
      LBase.Free;
      LExtra.Free;
    end;

    LBase := TUdmfBinaryWriter.Create;
    LExtra := TUdmfBinaryWriter.Create;
    try
      for LIndex := 0 to LMap.Sectors.Count - 1 do
      begin
        FProfile.Sectors.WriteBase(LMap.Sectors[LIndex], LBase);
        FProfile.Sectors.WriteExtra(LMap.Sectors[LIndex], LExtra);
      end;
      LSectors := LBase.ToBytes;
      LExtraSectors := LExtra.ToBytes;
    finally
      LBase.Free;
      LExtra.Free;
    end;

    Result := TUdmfConvertedMap.Create(LMap.Namespace, LMap.LineTranslate, LMap.Things.Count,
      LMap.Lines.Count, LMap.Sides.Count, LMap.Vertexes.Count, LMap.Sectors.Count, LThings,
      LLines, LSides, LVertexes, LSectors, LExtraThings, LExtraLines, LExtraSides, LExtraVertexes,
      LExtraSectors);
  finally
    LMap.Free;
  end;
end;

end.