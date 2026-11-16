{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - data files kept in memory                         }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.MemoryFiles;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.Generics.Defaults,
  DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf;

type
  /// <summary>The files of the game as arrays of bytes with a name (the names do not care about the case)</summary>
  TKeenMemoryFiles = class(TInterfacedObject, IKeenDataFiles)
  strict private
    FFiles: TDictionary<string, TBytes>;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>Adds a file, or replaces the one with the same name</summary>
    procedure Add(const AName: string; const ABytes: TBytes);
    function Exists(const AName: string): Boolean;
    function OpenStream(const AName: string): TStream;
    function ReadAll(const AName: string): TBytes;
  end;

implementation

{ TKeenMemoryFiles }

constructor TKeenMemoryFiles.Create;
begin
  inherited Create;
  FFiles := TDictionary<string, TBytes>.Create(TIStringComparer.Ordinal);
end;

destructor TKeenMemoryFiles.Destroy;
begin
  FFiles.Free;
  inherited Destroy;
end;

procedure TKeenMemoryFiles.Add(const AName: string; const ABytes: TBytes);
begin
  FFiles.AddOrSetValue(AName, ABytes);
end;

function TKeenMemoryFiles.Exists(const AName: string): Boolean;
begin
  Result := FFiles.ContainsKey(AName);
end;

function TKeenMemoryFiles.ReadAll(const AName: string): TBytes;
begin
  if not FFiles.TryGetValue(AName, Result) then
    raise EKeenFileNotFoundException.CreateFmt(SKeenFileMissing, [AName]);
end;

function TKeenMemoryFiles.OpenStream(const AName: string): TStream;
begin
  Result := TBytesStream.Create(ReadAll(AName));
end;

end.
