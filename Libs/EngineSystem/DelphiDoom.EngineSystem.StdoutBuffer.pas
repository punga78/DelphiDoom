{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine system library - the lines of the standard output        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.EngineSystem.StdoutBuffer;

// The buffer of I_IOprintf of i_io.pas (issue #185): everything the engine prints is also kept as
// lines, for the console of the game, the window of the start and the file that I_Error saves.

interface

uses
  System.SysUtils, System.Generics.Collections;

type
  /// <summary>
  ///   What the engine printed, as lines. The rule of the old code is kept: a text that ends with
  ///   a carriage return starts a new line, any other text goes on the last line (so a text that
  ///   ends with CR LF is followed by more text on the same line, a quirk of the old code). Another quirk is kept:
  ///   the first line never grows (the Put of TDStringList ignored the index 0)
  /// </summary>
  TStdoutBuffer = class
  strict private
    FLines: TList<string>;
    FLastNewLine: Boolean;
    function GetCount: Integer;
    function GetLine(AIndex: Integer): string;
    function GetText: string;
    class function SplitLines(const AText: string): TArray<string>; static;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>Adds what was printed. An empty text is nothing; a single carriage return is an empty line</summary>
    procedure Append(const AText: string);
    procedure Clear;
    /// <summary>Writes the text, 8 bit, to a file; false if the file cannot be written. It never raises</summary>
    function SaveToFile(const AFileName: string): Boolean;
    property Count: Integer read GetCount;
    property Lines[AIndex: Integer]: string read GetLine; default;
    /// <summary>The lines, each one with CR LF at the end</summary>
    property Text: string read GetText;
  end;

implementation

uses
  System.Classes;

{ TStdoutBuffer }

constructor TStdoutBuffer.Create;
begin
  inherited Create;
  FLines := TList<string>.Create;
  FLastNewLine := True;
end;

destructor TStdoutBuffer.Destroy;
begin
  FLines.Free;
  inherited Destroy;
end;

function TStdoutBuffer.GetCount: Integer;
begin
  Result := FLines.Count;
end;

function TStdoutBuffer.GetLine(AIndex: Integer): string;
begin
  Result := FLines[AIndex];
end;

function TStdoutBuffer.GetText: string;
var
  LLine: string;
  LBuilder: TStringBuilder;
begin
  LBuilder := TStringBuilder.Create;
  try
    for LLine in FLines do
    begin
      LBuilder.Append(LLine);
      LBuilder.Append(#13#10);
    end;
    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
end;

// The rule of the old SetTextStr: a line ends at CR, LF or CR LF, and at the terminator of the text
class function TStdoutBuffer.SplitLines(const AText: string): TArray<string>;
var
  LResult: TList<string>;
  LIndex: Integer;
  LStart: Integer;
  LLength: Integer;
begin
  LResult := TList<string>.Create;
  try
    LLength := Length(AText);
    LIndex := 1;
    while (LIndex <= LLength) and (AText[LIndex] <> #0) do
    begin
      LStart := LIndex;
      while (LIndex <= LLength) and not CharInSet(AText[LIndex], [#0, #10, #13]) do
        Inc(LIndex);
      LResult.Add(Copy(AText, LStart, LIndex - LStart));
      if (LIndex <= LLength) and (AText[LIndex] = #13) then
        Inc(LIndex);
      if (LIndex <= LLength) and (AText[LIndex] = #10) then
        Inc(LIndex);
    end;
    Result := LResult.ToArray;
  finally
    LResult.Free;
  end;
end;

procedure TStdoutBuffer.Append(const AText: string);
var
  LParts: TArray<string>;
  LPart: Integer;
  LLength: Integer;
begin
  LLength := Length(AText);
  if LLength = 0 then
    Exit;

  if (LLength = 1) and (AText[1] = #13) then
  begin
    FLines.Add('');
    FLastNewLine := True;
  end
  else
  begin
    LParts := SplitLines(AText);
    if FLastNewLine or (FLines.Count = 0) then
      FLines.AddRange(LParts)
    else if Length(LParts) > 0 then
    begin
      // Defect kept: TDStringList.Put of d_delphi ignores the index 0 (Index > 0), so the first line never grew
      if FLines.Count > 1 then
        FLines[FLines.Count - 1] := FLines[FLines.Count - 1] + LParts[0];
      for LPart := 1 to Length(LParts) - 1 do
        FLines.Add(LParts[LPart]);
    end;
    FLastNewLine := AText[LLength] = #13;
  end;
end;

procedure TStdoutBuffer.Clear;
begin
  FLines.Clear;
  FLastNewLine := True;
end;

function TStdoutBuffer.SaveToFile(const AFileName: string): Boolean;
var
  LStream: TFileStream;
  LBytes: AnsiString;
begin
  // files are written as 8 bit text
  LBytes := AnsiString(GetText);
  Result := True;
  try
    LStream := TFileStream.Create(AFileName, fmCreate);
    try
      if Length(LBytes) > 0 then
        LStream.WriteBuffer(Pointer(LBytes)^, Length(LBytes));
    finally
      LStream.Free;
    end;
  except
    on EStreamError do
      Result := False;
    on EInOutError do
      Result := False;
  end;
end;

end.
