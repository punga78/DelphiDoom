{******************************************************************************}
{                                                                              }
{  DelphiDoom: UDMF library - the sides                                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Udmf.SideFormat;

interface

uses
  System.SysUtils, DelphiDoom.Udmf.Types, DelphiDoom.Udmf.Intf, DelphiDoom.Udmf.BinaryWriter;

type
  /// <summary>The sides: the same in all the games</summary>
  TUdmfSideFormat = class(TInterfacedObject, IUdmfSideFormat)
  private
    function ReadName(const AReader: IUdmfValueReader): TUdmfName8;
  public
    procedure Reset(var ASide: TUdmfSide);
    function Apply(const AKey: string; const AReader: IUdmfValueReader;
      var ASide: TUdmfSide): Boolean;
    function GetBaseSize: Integer;
    function GetExtraSize: Integer;
    procedure WriteBase(const ASide: TUdmfSide; const AWriter: TUdmfBinaryWriter);
    procedure WriteExtra(const ASide: TUdmfSide; const AWriter: TUdmfBinaryWriter);
  end;

implementation

uses
  DelphiDoom.Udmf.Text;

{ TUdmfSideFormat }

procedure TUdmfSideFormat.Reset(var ASide: TUdmfSide);
begin
  ASide := Default(TUdmfSide);
  ASide.TopTexture[0] := '-';
  ASide.BottomTexture[0] := '-';
  ASide.MidTexture[0] := '-';
end;

function TUdmfSideFormat.ReadName(const AReader: IUdmfValueReader): TUdmfName8;
var
  LToken: string;
begin
  LToken := AReader.ReadToken;
  if Length(LToken) > 8 then
    AReader.Warn(Format('TUdmfSideFormat: the name "%s" is longer than 8 characters and is cut'#13#10,
      [LToken]));
  Result := TUdmfText.ToName8(LToken);
end;

function TUdmfSideFormat.Apply(const AKey: string; const AReader: IUdmfValueReader;
  var ASide: TUdmfSide): Boolean;
var
  LFloat: Single;
begin
  Result := True;
  if AKey = 'OFFSETX' then
  begin
    LFloat := AReader.ReadFloat;
    ASide.TextureOffset := Round(LFloat);
    ASide.ExtraTextureOffset := Round(LFloat * FRACUNIT);
  end
  else if AKey = 'OFFSETX_BOTTOM' then
    ASide.ExtraBottomTextureOffset := Round(AReader.ReadFloat * FRACUNIT)
  else if AKey = 'OFFSETX_TOP' then
    ASide.ExtraTopTextureOffset := Round(AReader.ReadFloat * FRACUNIT)
  else if AKey = 'OFFSETX_MID' then
    ASide.ExtraMidTextureOffset := Round(AReader.ReadFloat * FRACUNIT)
  else if AKey = 'OFFSETY' then
  begin
    LFloat := AReader.ReadFloat;
    ASide.RowOffset := Round(LFloat);
    ASide.ExtraRowOffset := Round(LFloat * FRACUNIT);
  end
  else if AKey = 'OFFSETY_BOTTOM' then
    ASide.ExtraBottomRowOffset := Round(AReader.ReadFloat * FRACUNIT)
  else if AKey = 'OFFSETY_TOP' then
    ASide.ExtraTopRowOffset := Round(AReader.ReadFloat * FRACUNIT)
  else if AKey = 'OFFSETY_MID' then
    ASide.ExtraMidRowOffset := Round(AReader.ReadFloat * FRACUNIT)
  else if AKey = 'TEXTURETOP' then
    ASide.TopTexture := ReadName(AReader)
  else if AKey = 'TEXTUREBOTTOM' then
    ASide.BottomTexture := ReadName(AReader)
  else if AKey = 'TEXTUREMIDDLE' then
    ASide.MidTexture := ReadName(AReader)
  else if AKey = 'SECTOR' then
    ASide.Sector := AReader.ReadInteger
  else if AKey = 'NOFAKECONTRAST' then
  begin
    if AReader.ReadIsTrue then
      ASide.ExtraFlags := ASide.ExtraFlags or SDF_NOFAKECONTRAST;
  end
  else if AKey = 'COMMENT' then
    AReader.ReadToken
  else
    Result := False;
end;

function TUdmfSideFormat.GetBaseSize: Integer;
begin
  Result := 30;
end;

function TUdmfSideFormat.GetExtraSize: Integer;
begin
  Result := 36;
end;

procedure TUdmfSideFormat.WriteBase(const ASide: TUdmfSide; const AWriter: TUdmfBinaryWriter);
begin
  AWriter.WriteInt16(ASide.TextureOffset);
  AWriter.WriteInt16(ASide.RowOffset);
  AWriter.WriteName8(ASide.TopTexture);
  AWriter.WriteName8(ASide.BottomTexture);
  AWriter.WriteName8(ASide.MidTexture);
  AWriter.WriteInt16(ASide.Sector);
end;

procedure TUdmfSideFormat.WriteExtra(const ASide: TUdmfSide; const AWriter: TUdmfBinaryWriter);
begin
  AWriter.WriteInt32(ASide.ExtraTextureOffset);
  AWriter.WriteInt32(ASide.ExtraTopTextureOffset);
  AWriter.WriteInt32(ASide.ExtraBottomTextureOffset);
  AWriter.WriteInt32(ASide.ExtraMidTextureOffset);
  AWriter.WriteInt32(ASide.ExtraRowOffset);
  AWriter.WriteInt32(ASide.ExtraTopRowOffset);
  AWriter.WriteInt32(ASide.ExtraBottomRowOffset);
  AWriter.WriteInt32(ASide.ExtraMidRowOffset);
  AWriter.WriteInt32(ASide.ExtraFlags);
end;

end.