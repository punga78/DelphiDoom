{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the texture definitions library - the fakes            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.TextureDefs.Fakes;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Logging.Intf, DelphiDoom.TextureDefs.Intf,
  DelphiDoom.Tests.TextureDefs.Corpus;

type
  /// <summary>The lumps of a game kept in a dictionary; it counts the reads</summary>
  TFakeLumpSource = class(TInterfacedObject, ITextureDefsLumpSource)
  private
    FLumps: TDictionary<string, TBytes>;
    FReads: TList<string>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure SetLump(const AName: string; const ABytes: TBytes);
    function TryReadLump(const AName: string; out ABytes: TBytes): Boolean;
    /// <summary>The names asked for, in order</summary>
    property Reads: TList<string> read FReads;
  end;

  /// <summary>A WAD of the corpus as a source of lumps</summary>
  TWadSourceAdapter = class(TInterfacedObject, ITextureDefsLumpSource)
  private
    FWad: TCorpusWad;
  public
    constructor Create(AWad: TCorpusWad);
    function TryReadLump(const AName: string; out ABytes: TBytes): Boolean;
  end;

  /// <summary>The flats of the engine: a list of names; the last one with the name wins</summary>
  TFakeFlatCatalog = class(TInterfacedObject, ITextureDefsFlatCatalog)
  private
    FNames: TArray<string>;
  public
    constructor Create(const ANames: TArray<string>);
    function LastIndexOf(const AUpperName: string): Integer;
  end;

  /// <summary>The warnings, one string each, as written</summary>
  TFakeLog = class(TInterfacedObject, ILog)
  private
    FWarnings: TList<string>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Info(const AText: string);
    procedure Warning(const AText: string);
    procedure DevWarning(const AText: string);
    procedure Error(const AText: string);
    property Warnings: TList<string> read FWarnings;
  end;

implementation

{ TFakeLumpSource }

constructor TFakeLumpSource.Create;
begin
  inherited Create;
  FLumps := TDictionary<string, TBytes>.Create;
  FReads := TList<string>.Create;
end;

destructor TFakeLumpSource.Destroy;
begin
  FLumps.Free;
  FReads.Free;
  inherited Destroy;
end;

procedure TFakeLumpSource.SetLump(const AName: string; const ABytes: TBytes);
begin
  FLumps.AddOrSetValue(AName, ABytes);
end;

function TFakeLumpSource.TryReadLump(const AName: string; out ABytes: TBytes): Boolean;
begin
  FReads.Add(AName);
  Result := FLumps.TryGetValue(AName, ABytes);
end;

{ TWadSourceAdapter }

constructor TWadSourceAdapter.Create(AWad: TCorpusWad);
begin
  inherited Create;
  FWad := AWad;
end;

function TWadSourceAdapter.TryReadLump(const AName: string; out ABytes: TBytes): Boolean;
begin
  Result := FWad.TryReadLump(AName, ABytes);
end;

{ TFakeFlatCatalog }

constructor TFakeFlatCatalog.Create(const ANames: TArray<string>);
begin
  inherited Create;
  FNames := ANames;
end;

function TFakeFlatCatalog.LastIndexOf(const AUpperName: string): Integer;
var
  LIndex: Integer;
begin
  for LIndex := High(FNames) downto 0 do
    if FNames[LIndex] = AUpperName then
      Exit(LIndex);
  Result := -1;
end;

{ TFakeLog }

constructor TFakeLog.Create;
begin
  inherited Create;
  FWarnings := TList<string>.Create;
end;

destructor TFakeLog.Destroy;
begin
  FWarnings.Free;
  inherited Destroy;
end;

procedure TFakeLog.Info(const AText: string);
begin
end;

procedure TFakeLog.Warning(const AText: string);
begin
  FWarnings.Add(AText);
end;

procedure TFakeLog.DevWarning(const AText: string);
begin
end;

procedure TFakeLog.Error(const AText: string);
begin
end;

end.
