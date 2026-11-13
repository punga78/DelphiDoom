{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the scanner library - fakes of the idLib services      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Scanner.IdFakes;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.IdLib.Core.Intf;

type
  /// <summary>Writes what idLib prints as lines: "P: text" and "W: text" (escaped as the golden files do)</summary>
  TFakeIdLibLog = class(TInterfacedObject, IIdLibLog)
  strict private
    FLines: TStrings;
    FOwnsLines: Boolean;
  public
    constructor Create(const ALines: TStrings = nil);
    destructor Destroy; override;
    procedure Printf(const AMessage: string);
    procedure Warning(const AMessage: string);
    property Lines: TStrings read FLines;
    /// <summary>Text as the golden files print it: backslash, \n, \r, \t and \xHH for the others outside 32..126</summary>
    class function Escape(const AText: AnsiString): string; static;
  end;

  TIdFileWrittenEvent = reference to procedure(const AName: AnsiString; const AData: TBytes);

  /// <summary>Files in memory by name; a write is stored and reported</summary>
  TFakeIdLibFileSystem = class(TInterfacedObject, IIdLibFileSystem)
  strict private
    FFiles: TDictionary<AnsiString, AnsiString>;
    FOnWritten: TIdFileWrittenEvent;
  public
    constructor Create;
    destructor Destroy; override;
    function TryReadFile(const AName: AnsiString; const AIsOsPath: Boolean; out AFile: TIdLibFileData): Boolean;
    function WriteFile(const AName: AnsiString; const AData: TBytes): Boolean;
    procedure Add(const AName, AContent: AnsiString);
    procedure Clear;
    function Content(const AName: AnsiString): AnsiString;
    property OnWritten: TIdFileWrittenEvent read FOnWritten write FOnWritten;
  end;

implementation

{ TFakeIdLibLog }

constructor TFakeIdLibLog.Create(const ALines: TStrings);
begin
  inherited Create;
  if Assigned(ALines) then
    FLines := ALines
  else
  begin
    FLines := TStringList.Create;
    FOwnsLines := True;
  end;
end;

destructor TFakeIdLibLog.Destroy;
begin
  if FOwnsLines then
    FLines.Free;
  inherited Destroy;
end;

class function TFakeIdLibLog.Escape(const AText: AnsiString): string;
var
  LIndex: Integer;
  LCode: Byte;
begin
  Result := '';
  for LIndex := 1 to Length(AText) do
  begin
    LCode := Byte(AText[LIndex]);
    case LCode of
      Ord('\'): Result := Result + '\\';
      10: Result := Result + '\n';
      13: Result := Result + '\r';
      9: Result := Result + '\t';
    else
      if (LCode < 32) or (LCode > 126) then
        Result := Result + '\x' + IntToHex(LCode, 2)
      else
        Result := Result + Char(LCode);
    end;
  end;
end;

procedure TFakeIdLibLog.Printf(const AMessage: string);
begin
  FLines.Add('P: ' + Escape(AnsiString(AMessage)));
end;

procedure TFakeIdLibLog.Warning(const AMessage: string);
begin
  FLines.Add('W: ' + Escape(AnsiString(AMessage)));
end;

{ TFakeIdLibFileSystem }

constructor TFakeIdLibFileSystem.Create;
begin
  inherited Create;
  FFiles := TDictionary<AnsiString, AnsiString>.Create;
end;

destructor TFakeIdLibFileSystem.Destroy;
begin
  FFiles.Free;
  inherited Destroy;
end;

procedure TFakeIdLibFileSystem.Add(const AName, AContent: AnsiString);
begin
  FFiles.AddOrSetValue(AName, AContent);
end;

procedure TFakeIdLibFileSystem.Clear;
begin
  FFiles.Clear;
end;

function TFakeIdLibFileSystem.Content(const AName: AnsiString): AnsiString;
begin
  if not FFiles.TryGetValue(AName, Result) then
    Result := '';
end;

function TFakeIdLibFileSystem.TryReadFile(const AName: AnsiString; const AIsOsPath: Boolean;
  out AFile: TIdLibFileData): Boolean;
var
  LContent: AnsiString;
begin
  Result := FFiles.TryGetValue(AName, LContent);
  if not Result then
    Exit;
  SetLength(AFile.Data, Length(LContent));
  if Length(LContent) > 0 then
    Move(LContent[1], AFile.Data[0], Length(LContent));
  AFile.FullPath := AName;
  AFile.Timestamp := 0;
end;

function TFakeIdLibFileSystem.WriteFile(const AName: AnsiString; const AData: TBytes): Boolean;
var
  LContent: AnsiString;
begin
  if Length(AData) = 0 then
    LContent := ''
  else
    SetString(LContent, PAnsiChar(@AData[0]), Length(AData));
  FFiles.AddOrSetValue(AName, LContent);
  if Assigned(FOnWritten) then
    FOnWritten(AName, AData);
  Result := True;
end;

end.
