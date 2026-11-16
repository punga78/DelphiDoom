{******************************************************************************}
{                                                                              }
{  DelphiDoom: UDMF library - the things of Hexen                             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Udmf.ThingFormat.Hexen;

interface

uses
  System.SysUtils, DelphiDoom.Udmf.Types, DelphiDoom.Udmf.Intf, DelphiDoom.Udmf.BinaryWriter,
  DelphiDoom.Udmf.ThingFormat.Base;

type
  /// <summary>
  ///   The things of Hexen: the record has the id, the height, the special and the 5 arguments, and
  ///   the options have the bits for the game type, the classes and dormant
  /// </summary>
  TUdmfHexenThingFormat = class(TUdmfThingFormatBase)
  private
    FHexen: TUdmfHexenThingFlags;
  public
    constructor Create(const AFlags: TUdmfCommonThingFlags; const AHexen: TUdmfHexenThingFlags);
    function Apply(const AKey: string; const AReader: IUdmfValueReader;
      var AThing: TUdmfThing): Boolean; override;
    function GetBaseSize: Integer; override;
    function GetExtraSize: Integer; override;
    procedure WriteBase(const AThing: TUdmfThing; const AWriter: TUdmfBinaryWriter); override;
    procedure WriteExtra(const AThing: TUdmfThing; const AWriter: TUdmfBinaryWriter); override;
  end;

implementation

{ TUdmfHexenThingFormat }

constructor TUdmfHexenThingFormat.Create(const AFlags: TUdmfCommonThingFlags;
  const AHexen: TUdmfHexenThingFlags);
begin
  inherited Create(AFlags);
  FHexen := AHexen;
end;

function TUdmfHexenThingFormat.Apply(const AKey: string; const AReader: IUdmfValueReader;
  var AThing: TUdmfThing): Boolean;
begin
  Result := ApplyCommon(AKey, AReader, AThing);
  if Result then
    Exit;

  Result := True;
  if AKey = 'SINGLE' then
  begin
    if AReader.ReadIsTrue then
    begin
      AThing.Options := AThing.Options or FHexen.GameSingle;
      AThing.ExtraFlags := AThing.ExtraFlags or UDMF_TF_SINGLE;
    end;
  end
  else if AKey = 'COOP' then
  begin
    if AReader.ReadIsTrue then
    begin
      AThing.Options := AThing.Options or FHexen.GameCoop;
      AThing.ExtraFlags := AThing.ExtraFlags or UDMF_TF_COOP;
    end;
  end
  else if AKey = 'DM' then
  begin
    if AReader.ReadIsTrue then
    begin
      AThing.Options := AThing.Options or FHexen.GameDeathmatch;
      AThing.ExtraFlags := AThing.ExtraFlags or UDMF_TF_DM;
    end;
  end
  else if AKey = 'DORMANT' then
  begin
    if AReader.ReadIsTrue then
      AThing.Options := AThing.Options or FHexen.Dormant;
  end
  else if AKey = 'CLASS1' then
  begin
    if AReader.ReadIsTrue then
      AThing.Options := AThing.Options or FHexen.Fighter;
  end
  else if AKey = 'CLASS2' then
  begin
    if AReader.ReadIsTrue then
      AThing.Options := AThing.Options or FHexen.Cleric;
  end
  else if AKey = 'CLASS3' then
  begin
    if AReader.ReadIsTrue then
      AThing.Options := AThing.Options or FHexen.Mage;
  end
  else if AKey = 'SPECIAL' then
    AThing.Special := AReader.ReadInteger
  else if AKey = 'ARG0' then
    AThing.Args[0] := AReader.ReadInteger
  else if AKey = 'ARG1' then
    AThing.Args[1] := AReader.ReadInteger
  else if AKey = 'ARG2' then
    AThing.Args[2] := AReader.ReadInteger
  else if AKey = 'ARG3' then
    AThing.Args[3] := AReader.ReadInteger
  else if AKey = 'ARG4' then
    AThing.Args[4] := AReader.ReadInteger
  else
    Result := False;
end;

function TUdmfHexenThingFormat.GetBaseSize: Integer;
begin
  Result := 20;
end;

function TUdmfHexenThingFormat.GetExtraSize: Integer;
begin
  Result := 28;
end;

procedure TUdmfHexenThingFormat.WriteBase(const AThing: TUdmfThing;
  const AWriter: TUdmfBinaryWriter);
var
  LIndex: Integer;
begin
  AWriter.WriteInt16(AThing.Tid);
  AWriter.WriteInt16(AThing.X);
  AWriter.WriteInt16(AThing.Y);
  AWriter.WriteInt16(AThing.Height);
  AWriter.WriteInt16(AThing.Angle);
  AWriter.WriteInt16(AThing.ThingType);
  AWriter.WriteInt16(AThing.Options);
  AWriter.WriteByte(AThing.Special);
  for LIndex := 0 to 4 do
    AWriter.WriteByte(AThing.Args[LIndex]);
end;

procedure TUdmfHexenThingFormat.WriteExtra(const AThing: TUdmfThing;
  const AWriter: TUdmfBinaryWriter);
begin
  AWriter.WriteInt32(AThing.ExtraFlags);
  AWriter.WriteInt32(AThing.ExtraX);
  AWriter.WriteInt32(AThing.ExtraY);
  AWriter.WriteInt32(AThing.ExtraZ);
  AWriter.WriteInt32(AThing.ExtraId);
  AWriter.WriteSingle(AThing.Gravity);
  AWriter.WriteSingle(AThing.Health);
end;

end.