{******************************************************************************}
{                                                                              }
{  DelphiDoom: UDMF library - what the things of all the games have           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Udmf.ThingFormat.Base;

interface

uses
  System.SysUtils, DelphiDoom.Udmf.Types, DelphiDoom.Udmf.Intf, DelphiDoom.Udmf.BinaryWriter;

type
  /// <summary>
  ///   The keys of a thing that are in every game: the position, the id, the angle, the type, the
  ///   skills, the ambush, the 3D floors, the script events, the friend, the gravity and the
  ///   health. The games add their own
  /// </summary>
  TUdmfThingFormatBase = class(TInterfacedObject, IUdmfThingFormat)
  private
    FFlags: TUdmfCommonThingFlags;
  protected
    /// <summary>False if the key is not one of the common ones</summary>
    function ApplyCommon(const AKey: string; const AReader: IUdmfValueReader;
      var AThing: TUdmfThing): Boolean;
    property Flags: TUdmfCommonThingFlags read FFlags;
  public
    constructor Create(const AFlags: TUdmfCommonThingFlags);
    procedure Reset(var AThing: TUdmfThing); virtual;
    function Apply(const AKey: string; const AReader: IUdmfValueReader;
      var AThing: TUdmfThing): Boolean; virtual; abstract;
    function GetBaseSize: Integer; virtual; abstract;
    function GetExtraSize: Integer; virtual; abstract;
    procedure WriteBase(const AThing: TUdmfThing; const AWriter: TUdmfBinaryWriter); virtual; abstract;
    procedure WriteExtra(const AThing: TUdmfThing; const AWriter: TUdmfBinaryWriter); virtual; abstract;
  end;

implementation

{ TUdmfThingFormatBase }

constructor TUdmfThingFormatBase.Create(const AFlags: TUdmfCommonThingFlags);
begin
  inherited Create;
  FFlags := AFlags;
end;

procedure TUdmfThingFormatBase.Reset(var AThing: TUdmfThing);
begin
  AThing := Default(TUdmfThing);
end;

function TUdmfThingFormatBase.ApplyCommon(const AKey: string; const AReader: IUdmfValueReader;
  var AThing: TUdmfThing): Boolean;
var
  LFloat: Single;
begin
  Result := True;
  if AKey = 'X' then
  begin
    LFloat := AReader.ReadFloat;
    AThing.X := Round(LFloat);
    AThing.ExtraX := Round(LFloat * FRACUNIT);
  end
  else if AKey = 'Y' then
  begin
    LFloat := AReader.ReadFloat;
    AThing.Y := Round(LFloat);
    AThing.ExtraY := Round(LFloat * FRACUNIT);
  end
  else if AKey = 'Z' then
  begin
    LFloat := AReader.ReadFloat;
    AThing.ExtraZ := Round(LFloat * FRACUNIT);
    AThing.ExtraFlags := AThing.ExtraFlags or UDMF_TF_HASZ;
  end
  else if AKey = 'ID' then
    AThing.ExtraId := AReader.ReadInteger
  else if AKey = 'ANGLE' then
    AThing.Angle := Round(AReader.ReadFloat)
  else if AKey = 'TYPE' then
    AThing.ThingType := AReader.ReadInteger
  else if (AKey = 'SKILL1') or (AKey = 'SKILL2') then
  begin
    if AReader.ReadIsTrue then
    begin
      AThing.Options := AThing.Options or 1;
      if AKey = 'SKILL1' then
        AThing.ExtraFlags := AThing.ExtraFlags or UDMF_TF_SKILL1
      else
        AThing.ExtraFlags := AThing.ExtraFlags or UDMF_TF_SKILL2;
    end;
  end
  else if AKey = 'SKILL3' then
  begin
    if AReader.ReadIsTrue then
    begin
      AThing.Options := AThing.Options or 2;
      AThing.ExtraFlags := AThing.ExtraFlags or UDMF_TF_SKILL3;
    end;
  end
  else if (AKey = 'SKILL4') or (AKey = 'SKILL5') then
  begin
    if AReader.ReadIsTrue then
    begin
      AThing.Options := AThing.Options or 4;
      if AKey = 'SKILL4' then
        AThing.ExtraFlags := AThing.ExtraFlags or UDMF_TF_SKILL4
      else
        AThing.ExtraFlags := AThing.ExtraFlags or UDMF_TF_SKILL5;
    end;
  end
  else if AKey = 'AMBUSH' then
  begin
    if AReader.ReadIsTrue then
      AThing.Options := AThing.Options or 8;
  end
  else if AKey = 'ONMIDDLEFLOOR' then
  begin
    if AReader.ReadIsTrue then
      AThing.Options := AThing.Options or FFlags.OnMidSector;
  end
  else if AKey = 'NOTRIGGERSCRIPTS' then
  begin
    if AReader.ReadIsTrue then
      AThing.Options := AThing.Options or FFlags.DoNotTriggerScripts;
  end
  else if AKey = 'FRIEND' then
  begin
    if AReader.ReadIsTrue then
      AThing.Options := AThing.Options or FFlags.Friend;
  end
  else if AKey = 'GRAVITY' then
  begin
    AThing.Gravity := AReader.ReadFloat;
    AThing.ExtraFlags := AThing.ExtraFlags or UDMF_TF_HASGRAVITY;
  end
  else if AKey = 'HEALTH' then
  begin
    AThing.Health := AReader.ReadFloat;
    AThing.ExtraFlags := AThing.ExtraFlags or UDMF_TF_HASHEALTH;
  end
  else if AKey = 'COMMENT' then
    AReader.ReadToken
  else
    Result := False;
end;

end.