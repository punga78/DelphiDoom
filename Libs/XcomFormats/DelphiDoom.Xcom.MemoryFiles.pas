{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom formats library - data files kept in memory                 }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.MemoryFiles;

interface

uses
  System.SysUtils, System.Generics.Collections, System.Generics.Defaults, DelphiDoom.Xcom.Types,
  DelphiDoom.Xcom.Intf;

type
  /// <summary>
  ///   The files of the game as arrays of bytes with a name. The names do not care about the case and the folders
  ///   can be separated by / or \ (the original names, GEODATA/PALETTES.DAT, have a /)
  /// </summary>
  TXcomMemoryFiles = class(TInterfacedObject, IXcomDataFiles)
  strict private
    FFiles: TDictionary<string, TBytes>;
    class function Normalize(const AName: string): string; static;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>Adds a file, or replaces the one with the same name</summary>
    procedure Add(const AName: string; const ABytes: TBytes);
    function Exists(const AName: string): Boolean;
    function ReadAll(const AName: string): TBytes;
  end;

implementation

{ TXcomMemoryFiles }

constructor TXcomMemoryFiles.Create;
begin
  inherited Create;
  FFiles := TDictionary<string, TBytes>.Create(TIStringComparer.Ordinal);
end;

destructor TXcomMemoryFiles.Destroy;
begin
  FFiles.Free;
  inherited Destroy;
end;

class function TXcomMemoryFiles.Normalize(const AName: string): string;
begin
  Result := AName.Replace('\', '/');
end;

procedure TXcomMemoryFiles.Add(const AName: string; const ABytes: TBytes);
begin
  FFiles.AddOrSetValue(Normalize(AName), ABytes);
end;

function TXcomMemoryFiles.Exists(const AName: string): Boolean;
begin
  Result := FFiles.ContainsKey(Normalize(AName));
end;

function TXcomMemoryFiles.ReadAll(const AName: string): TBytes;
begin
  if not FFiles.TryGetValue(Normalize(AName), Result) then
    raise EXcomFileNotFoundException.CreateFmt(SXcomFileMissing, [AName]);
end;

end.
