{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - the reader of I3D corrections               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  The old TI3DModelLoader.LoadCorrectionsFromStream without the script        }
{  engine: the text is cut in words at the spaces and the comments are //.     }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.I3d.CorrectionReader;

interface

uses
  System.SysUtils,
  DelphiDoom.Models.Types,
  DelphiDoom.Models.I3d.Types,
  DelphiDoom.Models.I3d.Intf;

type
  /// <summary>
  ///   Reads "face 3 vertex 1 visible 1 x 10 y 20 z 30 tx 0 ty 0 color 7" lines (the keys are not
  ///   case sensitive and the numbers are decimal, or with $ or 0x). It does not need the model:
  ///   the numbers that point outside the model are ignored when the corrections are applied.
  /// </summary>
  TI3dCorrectionReader = class(TInterfacedObject, II3dCorrectionReader)
  strict private
    class function CutWords(const AText: string): TArray<string>; static;
    class function Expect(const AWords: TArray<string>; var APosition: Integer;
      const AKey: string): Integer; static;
  public
    function Parse(const AText: string): TArray<TI3dCorrection>;
  end;

implementation

uses
  System.Classes;

{ TI3dCorrectionReader }

class function TI3dCorrectionReader.CutWords(const AText: string): TArray<string>;
var
  LList: TStringList;
  LLines: TStringList;
  LLine, LWord: string;
  LComment: Integer;
  LCharacter: Char;
  LIndex: Integer;
  LCurrent: string;
begin
  LList := TStringList.Create;
  LLines := TStringList.Create;
  try
    LLines.Text := AText;
    for LLine in LLines do
    begin
      LComment := Pos('//', LLine);
      if LComment > 0 then
        LWord := Copy(LLine, 1, LComment - 1)
      else
        LWord := LLine;
      LCurrent := '';
      for LIndex := 1 to Length(LWord) do
      begin
        LCharacter := LWord[LIndex];
        if (LCharacter <= ' ') then
        begin
          if LCurrent <> '' then
            LList.Add(LCurrent);
          LCurrent := '';
        end
        else
          LCurrent := LCurrent + LCharacter;
      end;
      if LCurrent <> '' then
        LList.Add(LCurrent);
    end;
    Result := LList.ToStringArray;
  finally
    LLines.Free;
    LList.Free;
  end;
end;

class function TI3dCorrectionReader.Expect(const AWords: TArray<string>; var APosition: Integer;
  const AKey: string): Integer;
var
  LNumber: Int64;
  LText: string;
begin
  // the key (when there is one) and then the number
  if AKey <> '' then
  begin
    if (APosition >= Length(AWords)) or not SameText(AWords[APosition], AKey) then
    begin
      if APosition < Length(AWords) then
        LText := AWords[APosition]
      else
        LText := '';
      raise EModelsException.CreateFmt(SModelsI3dCorrectionText, [AKey, LText]);
    end;
    Inc(APosition);
  end;
  if (APosition >= Length(AWords)) or not TryStrToInt64(AWords[APosition], LNumber) then
  begin
    if APosition < Length(AWords) then
      LText := AWords[APosition]
    else
      LText := '';
    raise EModelsException.CreateFmt(SModelsI3dCorrectionText, ['a number', LText]);
  end;
  Inc(APosition);
  Result := Integer(LNumber);
end;

function TI3dCorrectionReader.Parse(const AText: string): TArray<TI3dCorrection>;
var
  LWords: TArray<string>;
  LPosition: Integer;
  LCorrection: TI3dCorrection;
  LCount: Integer;
begin
  LWords := CutWords(AText);
  SetLength(Result, 0);
  LCount := 0;
  LPosition := 0;
  while LPosition < Length(LWords) do
  begin
    if not SameText(LWords[LPosition], 'face') then
    begin
      // the old loader skipped every word that is not "face"
      Inc(LPosition);
      Continue;
    end;
    LCorrection.Face := Expect(LWords, LPosition, 'face');
    LCorrection.Vertex := Expect(LWords, LPosition, 'vertex');
    LCorrection.Visible := Expect(LWords, LPosition, 'visible') <> 0;
    LCorrection.X := Expect(LWords, LPosition, 'x');
    LCorrection.Y := Expect(LWords, LPosition, 'y');
    LCorrection.Z := Expect(LWords, LPosition, 'z');
    LCorrection.TextureX := Expect(LWords, LPosition, 'tx');
    LCorrection.TextureY := Expect(LWords, LPosition, 'ty');
    // the color is a byte (the old code truncated the number)
    LCorrection.Color := Byte(Expect(LWords, LPosition, 'color'));
    SetLength(Result, LCount + 1);
    Result[LCount] := LCorrection;
    Inc(LCount);
  end;
end;

end.

