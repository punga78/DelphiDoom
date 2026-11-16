{******************************************************************************}
{                                                                              }
{  DelphiDoom: UDMF library - the lines of Hexen                              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Udmf.LineFormat.Hexen;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Udmf.Types, DelphiDoom.Udmf.Intf,
  DelphiDoom.Udmf.BinaryWriter, DelphiDoom.Udmf.LineFormat.Base;

type
  /// <summary>
  ///   The lines of Hexen: the special is a byte and there are 5 arguments in the record. The id
  ///   is the first argument of the special 121 (set line identification), and what activates the
  ///   line is a number in 3 bits of the flags
  /// </summary>
  TUdmfHexenLineFormat = class(TUdmfLineFormatBase)
  private
    FRepeatSpecial: Integer;
    FActivationShift: Integer;
    FActivations: TDictionary<string, Integer>;
  protected
    procedure ApplyId(AId: Integer; var ALine: TUdmfLine); override;
    procedure ApplyArgument(AIndex, AValue: Integer; var ALine: TUdmfLine); override;
    function ApplyGameKey(const AKey: string; const AReader: IUdmfValueReader;
      var ALine: TUdmfLine): Boolean; override;
  public
    const
      SET_LINE_IDENTIFICATION = 121;
    /// <param name="ARepeatSpecial">The flag of repeat special</param>
    /// <param name="AActivationShift">The first bit of the number that says what activates the line</param>
    constructor Create(const AFlags: TUdmfLineFlags; ARepeatSpecial, AActivationShift: Integer);
    destructor Destroy; override;
    function GetBaseSize: Integer; override;
    function GetExtraSize: Integer; override;
    procedure WriteBase(const ALine: TUdmfLine; const AWriter: TUdmfBinaryWriter); override;
    procedure WriteExtra(const ALine: TUdmfLine; const AWriter: TUdmfBinaryWriter); override;
  end;

implementation

{ TUdmfHexenLineFormat }

constructor TUdmfHexenLineFormat.Create(const AFlags: TUdmfLineFlags; ARepeatSpecial,
  AActivationShift: Integer);
begin
  inherited Create(AFlags);
  FRepeatSpecial := ARepeatSpecial;
  FActivationShift := AActivationShift;
  FActivations := TDictionary<string, Integer>.Create;
  FActivations.Add('PLAYERCROSS', SPAC_CROSS);
  FActivations.Add('PLAYERUSE', SPAC_USE);
  FActivations.Add('MONSTERCROSS', SPAC_MCROSS);
  FActivations.Add('IMPACT', SPAC_IMPACT);
  FActivations.Add('PLAYERPUSH', SPAC_PUSH);
  FActivations.Add('MISSILECROSS', SPAC_PCROSS);
  // the old code uses the push of the player for the push of a monster, too
  FActivations.Add('MONSTERPUSH', SPAC_PUSH);
end;

destructor TUdmfHexenLineFormat.Destroy;
begin
  FActivations.Free;
  inherited Destroy;
end;

procedure TUdmfHexenLineFormat.ApplyId(AId: Integer; var ALine: TUdmfLine);
begin
  ALine.Special := SET_LINE_IDENTIFICATION;
  ALine.Args[0] := AId;
end;

procedure TUdmfHexenLineFormat.ApplyArgument(AIndex, AValue: Integer; var ALine: TUdmfLine);
begin
  ALine.Args[AIndex] := AValue;
end;

function TUdmfHexenLineFormat.ApplyGameKey(const AKey: string; const AReader: IUdmfValueReader;
  var ALine: TUdmfLine): Boolean;
var
  LActivation: Integer;
begin
  Result := True;
  if AKey = 'REPEATSPECIAL' then
  begin
    if AReader.ReadIsTrue then
      ALine.Flags := ALine.Flags or FRepeatSpecial;
  end
  else if FActivations.TryGetValue(AKey, LActivation) then
  begin
    if AReader.ReadIsTrue then
      ALine.Flags := ALine.Flags or (LActivation shl FActivationShift);
  end
  else
    Result := False;
end;

function TUdmfHexenLineFormat.GetBaseSize: Integer;
begin
  Result := 16;
end;

function TUdmfHexenLineFormat.GetExtraSize: Integer;
begin
  Result := 32;
end;

procedure TUdmfHexenLineFormat.WriteBase(const ALine: TUdmfLine; const AWriter: TUdmfBinaryWriter);
var
  LIndex: Integer;
begin
  AWriter.WriteInt16(ALine.V1);
  AWriter.WriteInt16(ALine.V2);
  AWriter.WriteInt16(ALine.Flags);
  AWriter.WriteByte(ALine.Special);
  for LIndex := 0 to 4 do
    AWriter.WriteByte(ALine.Args[LIndex]);
  AWriter.WriteInt16(ALine.SideFront);
  AWriter.WriteInt16(ALine.SideBack);
end;

procedure TUdmfHexenLineFormat.WriteExtra(const ALine: TUdmfLine; const AWriter: TUdmfBinaryWriter);
begin
  AWriter.WriteMoreIds(ALine.MoreIds);
end;

end.