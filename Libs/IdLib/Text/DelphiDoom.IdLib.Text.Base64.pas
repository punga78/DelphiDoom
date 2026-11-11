{******************************************************************************}
{                                                                              }
{  DelphiDoom: idLib text - TIdBase64, the base64 coder of idLib               }
{                                                                              }
{  Port of idLib (id Software, Doom 3, GPL v3): idlib\Base64.h, Base64.cpp     }
{  (the sixtets of Lib.cpp). Copyright (C) 1999-2011 id Software LLC, a        }
{  ZeniMax Media company; the algorithm is derived from the base64 code of     }
{  Daniel Vik (BSD style license, kept in Base64.cpp of the original).         }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.IdLib.Text.Base64;

{$Q-}
{$R-}

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   idBase64: encodes bytes to the base64 alphabet (padded with '=') and decodes them back. The
  ///   decoder ignores spaces and line feeds, stops at the first '=' or end, and treats a character
  ///   that is not in the alphabet as the sixtet 0, exactly like the original. The text is an
  ///   AnsiString; no line wrapping is added.
  /// </summary>
  TIdBase64 = class
  private
    FText: AnsiString;
  public
    constructor Create; overload;
    /// <summary>idBase64(idStr): the text to decode</summary>
    constructor Create(const AText: AnsiString); overload;
    procedure Encode(const AData: TBytes); overload;
    procedure Encode(const AText: AnsiString); overload;
    /// <summary>The minimum size in bytes of the buffer for decoding: 3 * length / 4</summary>
    function DecodeLength: Integer;
    function Decode: TBytes; overload;
    /// <summary>Decodes to a string (the content can hold #0 and other non ASCII bytes)</summary>
    function DecodeToString: AnsiString;
    property Text: AnsiString read FText write FText;
  end;

implementation

const
  SIXTET_TO_BASE64: AnsiString = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

{ TIdBase64 }

constructor TIdBase64.Create;
begin
  inherited Create;
  FText := '';
end;

constructor TIdBase64.Create(const AText: AnsiString);
begin
  inherited Create;
  FText := AText;
end;

procedure TIdBase64.Encode(const AData: TBytes);
var
  LIndex, LCount, LJ, LWord: Integer;
  LSixtets: array[0..3] of Byte;
  LRemaining: Integer;
begin
  FText := '';
  LRemaining := Length(AData);
  LIndex := 0;
  LCount := 0;
  LWord := 0;
  while LRemaining > 0 do
  begin
    LWord := LWord or (Integer(AData[LIndex]) shl (LCount * 8));
    Inc(LIndex);
    Dec(LRemaining);
    Inc(LCount);
    if (LRemaining = 0) or (LCount = 3) then
    begin
      // SixtetsForIntLittle
      LSixtets[0] := (LWord and $FC) shr 2;
      LSixtets[1] := ((LWord and $3) shl 4) + (((LWord shr 8) and $F0) shr 4);
      LSixtets[2] := (((LWord shr 8) and $F) shl 2) + (((LWord shr 16) and $C0) shr 6);
      LSixtets[3] := (LWord shr 16) and $3F;
      LJ := 0;
      while LJ * 6 < LCount * 8 do
      begin
        FText := FText + SIXTET_TO_BASE64[LSixtets[LJ] + 1];
        Inc(LJ);
      end;
      if LRemaining = 0 then
        for LJ := LCount to 2 do
          FText := FText + '=';
      LWord := 0;
      LCount := 0;
    end;
  end;
end;

procedure TIdBase64.Encode(const AText: AnsiString);
var
  LData: TBytes;
begin
  SetLength(LData, Length(AText));
  if Length(AText) > 0 then
    Move(AText[1], LData[0], Length(AText));
  Encode(LData);
end;

function TIdBase64.DecodeLength: Integer;
begin
  Result := 3 * Length(FText) div 4;
end;

function TIdBase64.Decode: TBytes;
var
  LTable: array[0..255] of Byte;
  LIndex, LI, LJ, LWord, LOut: Integer;
  LIn: array[0..3] of Byte;
  LChar: Byte;
begin
  FillChar(LTable, SizeOf(LTable), 0);
  for LIndex := 1 to Length(SIXTET_TO_BASE64) do
    LTable[Byte(SIXTET_TO_BASE64[LIndex])] := LIndex - 1;
  SetLength(Result, DecodeLength + 1);
  FillChar(LIn, SizeOf(LIn), 0);
  LOut := 0;
  LI := 0;
  LIndex := 1;
  while (LIndex <= Length(FText)) and (FText[LIndex] <> '=') do
  begin
    LChar := Byte(FText[LIndex]);
    if (LChar = Ord(' ')) or (LChar = 10) then
    begin
      Inc(LIndex);
      Continue;
    end;
    LIn[LI] := LTable[LChar];
    Inc(LI);
    Inc(LIndex);
    if (LIndex > Length(FText)) or (FText[LIndex] = '=') or (LI = 4) then
    begin
      // IntForSixtetsLittle
      LWord := (LIn[0] shl 2) or ((LIn[1] and $30) shr 4);
      LWord := LWord or (((LIn[1] and $F) shl 4) or ((LIn[2] and $3C) shr 2)) shl 8;
      LWord := LWord or (((LIn[2] and $3) shl 6) or LIn[3]) shl 16;
      LJ := 0;
      while LJ * 8 < LI * 6 do
      begin
        if LOut >= Length(Result) then
          SetLength(Result, LOut + 4);
        Result[LOut] := LWord and $FF;
        Inc(LOut);
        LWord := LWord shr 8;
        Inc(LJ);
      end;
      LI := 0;
    end;
  end;
  SetLength(Result, LOut);
end;

function TIdBase64.DecodeToString: AnsiString;
var
  LBytes: TBytes;
  LLength: Integer;
begin
  LBytes := Decode;
  // the original assigns the buffer to an idStr as a C string: it ends at the first #0
  // (decoding a partial group also gives a trailing zero byte)
  LLength := 0;
  while (LLength < Length(LBytes)) and (LBytes[LLength] <> 0) do
    Inc(LLength);
  SetLength(Result, LLength);
  if LLength > 0 then
    Move(LBytes[0], Result[1], LLength);
end;

end.
