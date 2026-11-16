{******************************************************************************}
{                                                                              }
{  DelphiDoom: UDMF library - the things of Doom, Heretic and Strife          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Udmf.ThingFormat.Vanilla;

interface

uses
  System.SysUtils, DelphiDoom.Udmf.Types, DelphiDoom.Udmf.Intf, DelphiDoom.Udmf.BinaryWriter,
  DelphiDoom.Udmf.ThingFormat.Base;

type
  /// <summary>
  ///   The things of a game that has the record of Doom: 5 numbers of 16 bits. What is not in it
  ///   (special and arguments) goes in the extra record. The options start as 16 (not in single
  ///   player): the key single takes it away
  /// </summary>
  TUdmfVanillaThingFormat = class(TUdmfThingFormatBase)
  private
    FAlly: Integer;
    FTranslation: TUdmfSpecialTranslation;
  public
    /// <param name="AAlly">The bit of the keys strifeally; 0 if the game has none</param>
    constructor Create(const AFlags: TUdmfCommonThingFlags; AAlly: Integer;
      const ATranslation: TUdmfSpecialTranslation);
    procedure Reset(var AThing: TUdmfThing); override;
    function Apply(const AKey: string; const AReader: IUdmfValueReader;
      var AThing: TUdmfThing): Boolean; override;
    function GetBaseSize: Integer; override;
    function GetExtraSize: Integer; override;
    procedure WriteBase(const AThing: TUdmfThing; const AWriter: TUdmfBinaryWriter); override;
    procedure WriteExtra(const AThing: TUdmfThing; const AWriter: TUdmfBinaryWriter); override;
  end;

implementation

{ TUdmfVanillaThingFormat }

constructor TUdmfVanillaThingFormat.Create(const AFlags: TUdmfCommonThingFlags; AAlly: Integer;
  const ATranslation: TUdmfSpecialTranslation);
begin
  inherited Create(AFlags);
  FAlly := AAlly;
  FTranslation := ATranslation;
end;

procedure TUdmfVanillaThingFormat.Reset(var AThing: TUdmfThing);
begin
  inherited Reset(AThing);
  AThing.Options := 16;
end;

function TUdmfVanillaThingFormat.Apply(const AKey: string; const AReader: IUdmfValueReader;
  var AThing: TUdmfThing): Boolean;
var
  LSpecial: Integer;
begin
  Result := ApplyCommon(AKey, AReader, AThing);
  if Result then
    Exit;

  Result := True;
  if AKey = 'SINGLE' then
  begin
    if AReader.ReadIsTrue then
    begin
      AThing.Options := AThing.Options and not 16;
      AThing.ExtraFlags := AThing.ExtraFlags or UDMF_TF_SINGLE;
    end;
  end
  else if AKey = 'COOP' then
  begin
    if AReader.ReadIsTrue then
    begin
      AThing.Options := AThing.Options or 32;
      AThing.ExtraFlags := AThing.ExtraFlags or UDMF_TF_COOP;
    end;
  end
  else if AKey = 'DM' then
  begin
    if AReader.ReadIsTrue then
    begin
      AThing.Options := AThing.Options or 64;
      AThing.ExtraFlags := AThing.ExtraFlags or UDMF_TF_DM;
    end;
  end
  else if AKey = 'SPECIAL' then
  begin
    LSpecial := AReader.ReadInteger;
    if AReader.LineTranslate then
    begin
      // the specials of the format of the map are moved to the ones of the game, and back
      if ((LSpecial and 1023) >= 1) and ((LSpecial and 1023) <= FTranslation.NormalAdd) then
        LSpecial := ((LSpecial and 1023) + FTranslation.SpecialStart) or (LSpecial and not 1023)
      else if ((LSpecial and 1023) >= FTranslation.NormalAdd) and
        ((LSpecial and 1023) <= FTranslation.SpecialStart + FTranslation.NormalAdd) then
        LSpecial := ((LSpecial and 1023) - FTranslation.NormalAdd) or (LSpecial and not 1023);
    end;
    AThing.ExtraSpecial := LSpecial;
  end
  else if AKey = 'ARG0' then
    AThing.ExtraArgs[0] := AReader.ReadInteger
  else if AKey = 'ARG1' then
    AThing.ExtraArgs[1] := AReader.ReadInteger
  else if AKey = 'ARG2' then
    AThing.ExtraArgs[2] := AReader.ReadInteger
  else if AKey = 'ARG3' then
    AThing.ExtraArgs[3] := AReader.ReadInteger
  else if AKey = 'ARG4' then
    AThing.ExtraArgs[4] := AReader.ReadInteger
  else if (AKey = 'STRIFEALLY') and (FAlly <> 0) then
  begin
    if AReader.ReadIsTrue then
      AThing.Options := AThing.Options or FAlly;
  end
  else
    Result := False;
end;

function TUdmfVanillaThingFormat.GetBaseSize: Integer;
begin
  Result := 10;
end;

function TUdmfVanillaThingFormat.GetExtraSize: Integer;
begin
  Result := 52;
end;

procedure TUdmfVanillaThingFormat.WriteBase(const AThing: TUdmfThing;
  const AWriter: TUdmfBinaryWriter);
begin
  AWriter.WriteInt16(AThing.X);
  AWriter.WriteInt16(AThing.Y);
  AWriter.WriteInt16(AThing.Angle);
  AWriter.WriteInt16(AThing.ThingType);
  AWriter.WriteInt16(AThing.Options);
end;

procedure TUdmfVanillaThingFormat.WriteExtra(const AThing: TUdmfThing;
  const AWriter: TUdmfBinaryWriter);
var
  LIndex: Integer;
begin
  AWriter.WriteInt32(AThing.ExtraFlags);
  AWriter.WriteInt32(AThing.ExtraX);
  AWriter.WriteInt32(AThing.ExtraY);
  AWriter.WriteInt32(AThing.ExtraZ);
  AWriter.WriteInt32(AThing.ExtraId);
  AWriter.WriteSingle(AThing.Gravity);
  AWriter.WriteSingle(AThing.Health);
  AWriter.WriteInt32(AThing.ExtraSpecial);
  for LIndex := 0 to 4 do
    AWriter.WriteInt32(AThing.ExtraArgs[LIndex]);
end;

end.