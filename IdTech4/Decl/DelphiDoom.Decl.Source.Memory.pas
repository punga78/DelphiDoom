{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - TDeclMemorySource, decl files in memory   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Source.Memory;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Decl.Source.Intf;

type
  /// <summary>
  ///   An <c>IDeclSource</c> over files held in memory: the harness of the parity tests, the unit tests and
  ///   tools that build declarations on the fly. Every <c>Add</c> and <c>WriteFile</c> gives the file a new
  ///   time (a counter), so a reload sees the change.
  /// </summary>
  TDeclMemorySource = class(TInterfacedObject, IDeclSource)
  strict private
    type
      TEntry = record
        Name: AnsiString;
        Text: AnsiString;
        Timestamp: Int64;
      end;
    var
      FFiles: TList<TEntry>;
      FClock: Int64;
      FReads: Integer;
    function IndexOf(const AName: AnsiString): Integer;
    class function Normalize(const AName: AnsiString): AnsiString; static;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>Adds or replaces a file</summary>
    procedure Add(const AName, AText: AnsiString);
    procedure Remove(const AName: AnsiString);
    function ListFiles(const AFolder, AExtension: AnsiString): TArray<AnsiString>;
    function TryReadFile(const AName: AnsiString; out AText: AnsiString; out ATimestamp: Int64): Boolean;
    function TryGetFileInfo(const AName: AnsiString; out ALength: Integer; out ATimestamp: Int64): Boolean;
    function WriteFile(const AName, AText: AnsiString): Boolean;
    /// <summary>How many times <c>TryReadFile</c> was called (a read on demand must not read a file twice)</summary>
    property ReadCount: Integer read FReads;
  end;

implementation

uses
  System.Generics.Defaults, DelphiDoom.IdLib.Text.Strings;

{ TDeclMemorySource }

constructor TDeclMemorySource.Create;
begin
  inherited Create;
  FFiles := TList<TEntry>.Create;
  FClock := 1000;
end;

destructor TDeclMemorySource.Destroy;
begin
  FFiles.Free;
  inherited Destroy;
end;

class function TDeclMemorySource.Normalize(const AName: AnsiString): AnsiString;
begin
  Result := AnsiString(StringReplace(string(AName), '\', '/', [rfReplaceAll]));
end;

function TDeclMemorySource.IndexOf(const AName: AnsiString): Integer;
var
  LIndex: Integer;
  LName: AnsiString;
begin
  LName := Normalize(AName);
  for LIndex := 0 to FFiles.Count - 1 do
    if TIdStrings.Icmp(FFiles[LIndex].Name, LName) = 0 then
      Exit(LIndex);
  Result := -1;
end;

procedure TDeclMemorySource.Add(const AName, AText: AnsiString);
begin
  WriteFile(AName, AText);
end;

procedure TDeclMemorySource.Remove(const AName: AnsiString);
var
  LIndex: Integer;
begin
  LIndex := IndexOf(AName);
  if LIndex >= 0 then
    FFiles.Delete(LIndex);
end;

function TDeclMemorySource.WriteFile(const AName, AText: AnsiString): Boolean;
var
  LIndex: Integer;
  LEntry: TEntry;
begin
  Inc(FClock);
  LEntry.Name := Normalize(AName);
  LEntry.Text := AText;
  LEntry.Timestamp := FClock;
  LIndex := IndexOf(AName);
  if LIndex >= 0 then
    FFiles[LIndex] := LEntry
  else
    FFiles.Add(LEntry);
  Result := True;
end;

function TDeclMemorySource.ListFiles(const AFolder, AExtension: AnsiString): TArray<AnsiString>;
var
  LResult: TList<AnsiString>;
  LEntry: TEntry;
  LPrefix: AnsiString;
begin
  LPrefix := Normalize(AFolder) + '/';
  LResult := TList<AnsiString>.Create;
  try
    for LEntry in FFiles do
      if (TIdStrings.Icmpn(LEntry.Name, LPrefix, Length(LPrefix)) = 0) and
        (Length(LEntry.Name) >= Length(LPrefix) + Length(AExtension)) and
        (TIdStrings.Icmp(Copy(LEntry.Name, Length(LEntry.Name) - Length(AExtension) + 1, Length(AExtension)),
          AExtension) = 0) then
        LResult.Add(Copy(LEntry.Name, Length(LPrefix) + 1, MaxInt));
    LResult.Sort(TComparer<AnsiString>.Construct(
      function(const ALeft, ARight: AnsiString): Integer
      begin
        Result := TIdStrings.Icmp(ALeft, ARight);
      end));
    Result := LResult.ToArray;
  finally
    LResult.Free;
  end;
end;

function TDeclMemorySource.TryReadFile(const AName: AnsiString; out AText: AnsiString; out ATimestamp: Int64): Boolean;
var
  LIndex: Integer;
begin
  LIndex := IndexOf(AName);
  Result := LIndex >= 0;
  if Result then
  begin
    Inc(FReads);
    AText := FFiles[LIndex].Text;
    ATimestamp := FFiles[LIndex].Timestamp;
  end
  else
  begin
    AText := '';
    ATimestamp := 0;
  end;
end;

function TDeclMemorySource.TryGetFileInfo(const AName: AnsiString; out ALength: Integer; out ATimestamp: Int64): Boolean;
var
  LIndex: Integer;
begin
  LIndex := IndexOf(AName);
  Result := LIndex >= 0;
  if Result then
  begin
    ALength := Length(FFiles[LIndex].Text);
    ATimestamp := FFiles[LIndex].Timestamp;
  end
  else
  begin
    ALength := -1;
    ATimestamp := 0;
  end;
end;

end.
