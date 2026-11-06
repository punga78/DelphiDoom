{******************************************************************************}
{                                                                              }
{  DelphiDoom: UDMF library - the lines of Doom, Heretic and Strife           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Udmf.LineFormat.Vanilla;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Udmf.Types, DelphiDoom.Udmf.Intf,
  DelphiDoom.Udmf.BinaryWriter, DelphiDoom.Udmf.LineFormat.Base;

type
  /// <summary>
  ///   The lines of a game that has the record of Doom: special and tag of 16 bits. The
  ///   arguments and what activates the line are in the extra record. The tag starts as -1
  /// </summary>
  TUdmfVanillaLineFormat = class(TUdmfLineFormatBase)
  private
    FActivators: TDictionary<string, Integer>;
  protected
    procedure ApplyId(AId: Integer; var ALine: TUdmfLine); override;
    procedure ApplyArgument(AIndex, AValue: Integer; var ALine: TUdmfLine); override;
    function ApplyGameKey(const AKey: string; const AReader: IUdmfValueReader;
      var ALine: TUdmfLine): Boolean; override;
  public
    constructor Create(const AFlags: TUdmfLineFlags);
    destructor Destroy; override;
    procedure Reset(var ALine: TUdmfLine); override;
    function GetBaseSize: Integer; override;
    function GetExtraSize: Integer; override;
    procedure WriteBase(const ALine: TUdmfLine; const AWriter: TUdmfBinaryWriter); override;
    procedure WriteExtra(const ALine: TUdmfLine; const AWriter: TUdmfBinaryWriter); override;
  end;

implementation

{ TUdmfVanillaLineFormat }

constructor TUdmfVanillaLineFormat.Create(const AFlags: TUdmfLineFlags);
begin
  inherited Create(AFlags);
  FActivators := TDictionary<string, Integer>.Create;
  FActivators.Add('REPEATSPECIAL', ULAC_REPEAT);
  FActivators.Add('PLAYERCROSS', ULAC_CROSS);
  FActivators.Add('PLAYERUSE', ULAC_USE);
  FActivators.Add('MONSTERCROSS', ULAC_MCROSS);
  FActivators.Add('IMPACT', ULAC_IMPACT);
  FActivators.Add('PLAYERPUSH', ULAC_PUSH);
  FActivators.Add('MISSILECROSS', ULAC_PCROSS);
  FActivators.Add('MONSTERPUSH', ULAC_MPUSH);
  FActivators.Add('OLDSTYLE', ULAC_DEFAULT);
end;

destructor TUdmfVanillaLineFormat.Destroy;
begin
  FActivators.Free;
  inherited Destroy;
end;

procedure TUdmfVanillaLineFormat.Reset(var ALine: TUdmfLine);
begin
  inherited Reset(ALine);
  ALine.Tag := -1;
end;

procedure TUdmfVanillaLineFormat.ApplyId(AId: Integer; var ALine: TUdmfLine);
begin
  ALine.Tag := AId;
end;

procedure TUdmfVanillaLineFormat.ApplyArgument(AIndex, AValue: Integer; var ALine: TUdmfLine);
begin
  ALine.ExtraArgs[AIndex] := AValue;
end;

function TUdmfVanillaLineFormat.ApplyGameKey(const AKey: string; const AReader: IUdmfValueReader;
  var ALine: TUdmfLine): Boolean;
var
  LActivator: Integer;
begin
  Result := FActivators.TryGetValue(AKey, LActivator);
  if Result and AReader.ReadIsTrue then
    ALine.Activators := ALine.Activators or LActivator;
end;

function TUdmfVanillaLineFormat.GetBaseSize: Integer;
begin
  Result := 14;
end;

function TUdmfVanillaLineFormat.GetExtraSize: Integer;
begin
  Result := 56;
end;

procedure TUdmfVanillaLineFormat.WriteBase(const ALine: TUdmfLine;
  const AWriter: TUdmfBinaryWriter);
begin
  AWriter.WriteInt16(ALine.V1);
  AWriter.WriteInt16(ALine.V2);
  AWriter.WriteInt16(ALine.Flags);
  AWriter.WriteInt16(ALine.Special);
  AWriter.WriteInt16(ALine.Tag);
  AWriter.WriteInt16(ALine.SideFront);
  AWriter.WriteInt16(ALine.SideBack);
end;

procedure TUdmfVanillaLineFormat.WriteExtra(const ALine: TUdmfLine;
  const AWriter: TUdmfBinaryWriter);
var
  LIndex: Integer;
begin
  for LIndex := 0 to 4 do
    AWriter.WriteInt32(ALine.ExtraArgs[LIndex]);
  AWriter.WriteInt32(ALine.Activators);
  AWriter.WriteMoreIds(ALine.MoreIds);
end;

end.