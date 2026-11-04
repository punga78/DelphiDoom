{******************************************************************************}
{                                                                              }
{  DelphiDoom: XMI/CMF/SOP - recognizes the format of a song                   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xmi.FormatDetector;

interface

uses
  System.SysUtils, DelphiDoom.Xmi.Intf;

type
  /// <summary>
  ///   Looks at the first bytes of a song to say which format it is
  /// </summary>
  TXmiFormatDetector = class
  public
    /// <summary>
    ///   Standard MIDI, XMIDI, CMF or Sopepos; Unknown for anything else
    /// </summary>
    class function Detect(const AData: TBytes): TXmiFormat; static;

    class function IsMidi(const AData: TBytes): Boolean; static;
    class function IsXmi(const AData: TBytes): Boolean; static;
    class function IsCmf(const AData: TBytes): Boolean; static;
    class function IsSop(const AData: TBytes): Boolean; static;
  end;

implementation

uses
  DelphiDoom.Xmi.Iff;

const
  // 'MThd', the length 6 and the three fields of the header
  MIDI_MINIMUM_SIZE = 14;
  // The header of a CMF file
  CMF_MINIMUM_SIZE = 36;
  // The header of a Sopepos file
  SOP_MINIMUM_SIZE = $4C;

  MIDI_TAG: array[0..3] of Byte = ($4D, $54, $68, $64); // MThd
  CMF_TAG: array[0..3] of Byte = ($43, $54, $4D, $46);  // CTMF
  // 'sopepos', a zero, then the version 1.0
  SOP_SIGNATURE: array[0..9] of Byte = ($73, $6F, $70, $65, $70, $6F, $73,
    0, 1, 0);

function StartsWith(const AData: TBytes; const ATag: array of Byte): Boolean;
var
  LIndex: Integer;
begin
  Result := Length(AData) >= Length(ATag);
  if not Result then
    Exit;

  for LIndex := 0 to High(ATag) do
    if AData[LIndex] <> ATag[LIndex] then
      Exit(False);
end;

{ TXmiFormatDetector }

class function TXmiFormatDetector.IsMidi(const AData: TBytes): Boolean;
begin
  Result := (Length(AData) >= MIDI_MINIMUM_SIZE) and StartsWith(AData, MIDI_TAG);
end;

class function TXmiFormatDetector.IsXmi(const AData: TBytes): Boolean;
var
  LNodes: TXmiIffNodes;
begin
  LNodes := TXmiIff.GetNodes(AData, 0, Length(AData));
  Result := (TXmiIff.Count(LNodes, 'CAT ', 'XMID') > 0) or
    (TXmiIff.Count(LNodes, 'FORM', 'XMID') > 0);
end;

class function TXmiFormatDetector.IsCmf(const AData: TBytes): Boolean;
begin
  Result := (Length(AData) >= CMF_MINIMUM_SIZE) and StartsWith(AData, CMF_TAG);
end;

class function TXmiFormatDetector.IsSop(const AData: TBytes): Boolean;
begin
  Result := (Length(AData) >= SOP_MINIMUM_SIZE) and StartsWith(AData, SOP_SIGNATURE);
end;

class function TXmiFormatDetector.Detect(const AData: TBytes): TXmiFormat;
begin
  if Length(AData) = 0 then
    Exit(TXmiFormat.Unknown);

  if IsMidi(AData) then
    Result := TXmiFormat.Midi
  else if IsXmi(AData) then
    Result := TXmiFormat.Xmi
  else if IsCmf(AData) then
    Result := TXmiFormat.Cmf
  else if IsSop(AData) then
    Result := TXmiFormat.Sop
  else
    Result := TXmiFormat.Unknown;
end;

end.
