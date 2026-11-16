{******************************************************************************}
{                                                                              }
{  DelphiDoom: UDMF library - the vertexes                                    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Udmf.VertexFormat;

interface

uses
  System.SysUtils, DelphiDoom.Udmf.Types, DelphiDoom.Udmf.Intf, DelphiDoom.Udmf.BinaryWriter;

type
  /// <summary>The vertexes: the same in all the games</summary>
  TUdmfVertexFormat = class(TInterfacedObject, IUdmfVertexFormat)
  public
    procedure Reset(var AVertex: TUdmfVertex);
    function Apply(const AKey: string; const AReader: IUdmfValueReader;
      var AVertex: TUdmfVertex): Boolean;
    function GetBaseSize: Integer;
    function GetExtraSize: Integer;
    procedure WriteBase(const AVertex: TUdmfVertex; const AWriter: TUdmfBinaryWriter);
    procedure WriteExtra(const AVertex: TUdmfVertex; const AWriter: TUdmfBinaryWriter);
  end;

implementation

{ TUdmfVertexFormat }

procedure TUdmfVertexFormat.Reset(var AVertex: TUdmfVertex);
begin
  AVertex := Default(TUdmfVertex);
end;

function TUdmfVertexFormat.Apply(const AKey: string; const AReader: IUdmfValueReader;
  var AVertex: TUdmfVertex): Boolean;
var
  LFloat: Single;
begin
  Result := True;
  if AKey = 'X' then
  begin
    LFloat := AReader.ReadFloat;
    AVertex.X := Round(LFloat);
    AVertex.ExtraX := Round(LFloat * FRACUNIT);
  end
  else if AKey = 'Y' then
  begin
    LFloat := AReader.ReadFloat;
    AVertex.Y := Round(LFloat);
    AVertex.ExtraY := Round(LFloat * FRACUNIT);
  end
  else if AKey = 'ZFLOOR' then
  begin
    AVertex.ZFloor := Round(AReader.ReadFloat * FRACUNIT);
    AVertex.ExtraFlags := AVertex.ExtraFlags or UDMF_VF_ZFLOOR;
  end
  else if AKey = 'ZCEILING' then
  begin
    AVertex.ZCeiling := Round(AReader.ReadFloat * FRACUNIT);
    AVertex.ExtraFlags := AVertex.ExtraFlags or UDMF_VF_ZCEILING;
  end
  else if AKey = 'COMMENT' then
    AReader.ReadToken
  else
    Result := False;
end;

function TUdmfVertexFormat.GetBaseSize: Integer;
begin
  Result := 4;
end;

function TUdmfVertexFormat.GetExtraSize: Integer;
begin
  Result := 20;
end;

procedure TUdmfVertexFormat.WriteBase(const AVertex: TUdmfVertex; const AWriter: TUdmfBinaryWriter);
begin
  AWriter.WriteInt16(AVertex.X);
  AWriter.WriteInt16(AVertex.Y);
end;

procedure TUdmfVertexFormat.WriteExtra(const AVertex: TUdmfVertex; const AWriter: TUdmfBinaryWriter);
begin
  AWriter.WriteInt32(AVertex.ExtraFlags);
  AWriter.WriteInt32(AVertex.ExtraX);
  AWriter.WriteInt32(AVertex.ExtraY);
  AWriter.WriteInt32(AVertex.ZFloor);
  AWriter.WriteInt32(AVertex.ZCeiling);
end;

end.