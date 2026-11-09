{******************************************************************************}
{                                                                              }
{  DelphiDoom: yaml library - the text the emitter writes (ostream_wrapper)    }
{  Port of yaml-cpp 0.7.0 (MIT, Jesse Beder): see Libs\Yaml\README.md          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Yaml.OutputWriter;

interface

uses
  System.SysUtils,
  DelphiDoom.Yaml.Types;

type
  /// <summary>ostream_wrapper (the memory buffer form): the bytes written and the row, column and comment state</summary>
  TYamlOutputWriter = class
  strict private
    FBuffer: TBytes;
    FPos: Integer;
    FRow: Integer;
    FCol: Integer;
    FComment: Boolean;
    procedure UpdatePos(AChar: Byte);
  public
    procedure Write(const AText: TYamlText); overload;
    procedure Write(AChar: Byte); overload;
    /// <summary>The "indentation" of the emitter: ACount spaces</summary>
    procedure WriteSpaces(ACount: Integer);
    /// <summary>IndentTo: spaces until the column is ACol (nothing if it is already there or past)</summary>
    procedure IndentTo(ACol: Integer);
    procedure SetComment;
    /// <summary>Everything written</summary>
    function Text: TYamlText;
    property Row: Integer read FRow;
    property Col: Integer read FCol;
    property Pos: Integer read FPos;
    property Comment: Boolean read FComment;
  end;

implementation

procedure TYamlOutputWriter.UpdatePos(AChar: Byte);
begin
  Inc(FPos);
  Inc(FCol);
  if AChar = 10 then
  begin
    Inc(FRow);
    FCol := 0;
    FComment := False;
  end;
end;

procedure TYamlOutputWriter.Write(const AText: TYamlText);
var
  I: Integer;
begin
  if Length(AText) = 0 then
    Exit;
  if FPos + Length(AText) > Length(FBuffer) then
    SetLength(FBuffer, (FPos + Length(AText)) * 2);
  Move(AText[1], FBuffer[FPos], Length(AText));
  for I := 1 to Length(AText) do
    UpdatePos(Byte(AText[I]));
end;

procedure TYamlOutputWriter.Write(AChar: Byte);
begin
  if FPos + 1 > Length(FBuffer) then
    SetLength(FBuffer, (FPos + 1) * 2 + 16);
  FBuffer[FPos] := AChar;
  UpdatePos(AChar);
end;

procedure TYamlOutputWriter.WriteSpaces(ACount: Integer);
var
  I: Integer;
begin
  for I := 1 to ACount do
    Write(32);
end;

procedure TYamlOutputWriter.IndentTo(ACol: Integer);
begin
  while FCol < ACol do
    Write(32);
end;

procedure TYamlOutputWriter.SetComment;
begin
  FComment := True;
end;

function TYamlOutputWriter.Text: TYamlText;
begin
  SetLength(Result, FPos);
  if FPos > 0 then
    Move(FBuffer[0], Result[1], FPos);
end;

end.
