{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the renderer library - the fakes                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Renderer.Fakes;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Renderer.Intf,
  DelphiDoom.Logging.Intf;

type
  /// <summary>A log that keeps what it is told, apart: the developer warnings and the rest</summary>
  TFakeLog = class(TInterfacedObject, ILog)
  strict private
    FDevWarnings: TList<string>;
    FOthers: TList<string>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Info(const AText: string);
    procedure Warning(const AText: string);
    procedure DevWarning(const AText: string);
    procedure Error(const AText: string);
    property DevWarnings: TList<string> read FDevWarnings;
    property Others: TList<string> read FOthers;
  end;

  /// <summary>The bytes of a patch lump, as the WAD has them, and how to read them</summary>
  TFakePatchBytes = class
  public
    /// <summary>
    ///   A patch of AWidth columns, with the number of posts of every column: header of eight
    ///   bytes, the table of the offsets of the columns, then every column as a list of
    ///   posts (topdelta, length, a pad byte, the pixels, a pad byte) ended by $FF
    /// </summary>
    class function Build(AWidth: Integer; const APostCounts: TArray<Integer>): TBytes; static;
    class function ReadSmall(const ABytes: TBytes; AOffset: Integer): Integer; static;
    class function ReadInt(const ABytes: TBytes; AOffset: Integer): Integer; static;
    /// <summary>Walks the posts from AOffset to the $FF as R_GenerateLookup did</summary>
    class function CountPosts(const ABytes: TBytes; AOffset: Integer): Integer; static;
  end;

  TFakePatchSource = class;

  /// <summary>An open patch over bytes: it tells the source when it is released</summary>
  TFakePatchColumns = class(TInterfacedObject, IRendererPatchColumns)
  strict private
    FSource: TFakePatchSource;
    FBytes: TBytes;
  public
    constructor Create(ASource: TFakePatchSource; const ABytes: TBytes);
    destructor Destroy; override;
    function Width: Integer;
    procedure Column(AColumn: Integer; out AOffset, APostCount: Integer);
  end;

  /// <summary>
  ///   The patches by lump number: a lump out of range, or without bytes, is not a patch
  ///   (nil), as the Doom check of the engine does
  /// </summary>
  TFakePatchSource = class(TInterfacedObject, IRendererPatchSource)
  strict private
    FOpenNow: Integer;
    FMaxOpen: Integer;
    FOpenCount: Integer;
  public
    Patches: TArray<TBytes>;
    function Open(ALump: Integer): IRendererPatchColumns;
    procedure Released;
    /// <summary>How many patches were open at the same time, at most</summary>
    property MaxOpen: Integer read FMaxOpen;
    /// <summary>How many times a patch was opened</summary>
    property OpenCount: Integer read FOpenCount;
    property OpenNow: Integer read FOpenNow;
  end;

implementation

{ TFakeLog }

constructor TFakeLog.Create;
begin
  inherited Create;
  FDevWarnings := TList<string>.Create;
  FOthers := TList<string>.Create;
end;

destructor TFakeLog.Destroy;
begin
  FOthers.Free;
  FDevWarnings.Free;
  inherited Destroy;
end;

procedure TFakeLog.Info(const AText: string);
begin
  FOthers.Add(AText);
end;

procedure TFakeLog.Warning(const AText: string);
begin
  FOthers.Add(AText);
end;

procedure TFakeLog.DevWarning(const AText: string);
begin
  FDevWarnings.Add(AText);
end;

procedure TFakeLog.Error(const AText: string);
begin
  FOthers.Add(AText);
end;

{ TFakePatchBytes }

class function TFakePatchBytes.ReadSmall(const ABytes: TBytes; AOffset: Integer): Integer;
begin
  Result := SmallInt(Integer(ABytes[AOffset]) or (Integer(ABytes[AOffset + 1]) shl 8));
end;

class function TFakePatchBytes.ReadInt(const ABytes: TBytes; AOffset: Integer): Integer;
begin
  Result := Integer(Cardinal(ABytes[AOffset]) or (Cardinal(ABytes[AOffset + 1]) shl 8) or
    (Cardinal(ABytes[AOffset + 2]) shl 16) or (Cardinal(ABytes[AOffset + 3]) shl 24));
end;

class function TFakePatchBytes.CountPosts(const ABytes: TBytes; AOffset: Integer): Integer;
begin
  Result := 0;
  while ABytes[AOffset] <> $FF do
  begin
    Inc(Result);
    AOffset := AOffset + ABytes[AOffset + 1] + 4;
  end;
end;

class function TFakePatchBytes.Build(AWidth: Integer;
  const APostCounts: TArray<Integer>): TBytes;
var
  LColumn: Integer;
  LPost: Integer;
  LPixel: Integer;
  LPostLength: Integer;
  LLength: Integer;
  LOffsets: TArray<Integer>;
begin
  SetLength(LOffsets, AWidth);
  SetLength(Result, 8 + 4 * AWidth);
  Result[0] := AWidth and $FF;
  Result[1] := (AWidth shr 8) and $FF;
  Result[2] := 64;  // height
  Result[3] := 0;
  // left and top offsets stay zero
  for LColumn := 0 to AWidth - 1 do
  begin
    LOffsets[LColumn] := Length(Result);
    for LPost := 0 to APostCounts[LColumn] - 1 do
    begin
      LPostLength := (LPost mod 3) + 1;
      LLength := Length(Result);
      SetLength(Result, LLength + LPostLength + 4);
      Result[LLength] := LPost * 4;
      Result[LLength + 1] := LPostLength;
      Result[LLength + 2] := 0;
      for LPixel := 0 to LPostLength - 1 do
        Result[LLength + 3 + LPixel] := (LColumn + LPost + LPixel) and $FF;
      Result[LLength + 3 + LPostLength] := 0;
    end;
    LLength := Length(Result);
    SetLength(Result, LLength + 1);
    Result[LLength] := $FF;
  end;
  for LColumn := 0 to AWidth - 1 do
  begin
    Result[8 + 4 * LColumn] := LOffsets[LColumn] and $FF;
    Result[8 + 4 * LColumn + 1] := (LOffsets[LColumn] shr 8) and $FF;
    Result[8 + 4 * LColumn + 2] := (LOffsets[LColumn] shr 16) and $FF;
    Result[8 + 4 * LColumn + 3] := (LOffsets[LColumn] shr 24) and $FF;
  end;
end;

{ TFakePatchColumns }

constructor TFakePatchColumns.Create(ASource: TFakePatchSource; const ABytes: TBytes);
begin
  inherited Create;
  FSource := ASource;
  FBytes := ABytes;
end;

destructor TFakePatchColumns.Destroy;
begin
  FSource.Released;
  inherited Destroy;
end;

function TFakePatchColumns.Width: Integer;
begin
  Result := TFakePatchBytes.ReadSmall(FBytes, 0);
end;

procedure TFakePatchColumns.Column(AColumn: Integer; out AOffset, APostCount: Integer);
begin
  AOffset := TFakePatchBytes.ReadInt(FBytes, 8 + 4 * AColumn);
  APostCount := TFakePatchBytes.CountPosts(FBytes, AOffset);
end;

{ TFakePatchSource }

function TFakePatchSource.Open(ALump: Integer): IRendererPatchColumns;
begin
  if (ALump < 0) or (ALump > High(Patches)) or (Length(Patches[ALump]) = 0) then
  begin
    Result := nil;
    Exit;
  end;
  Inc(FOpenCount);
  Inc(FOpenNow);
  if FOpenNow > FMaxOpen then
    FMaxOpen := FOpenNow;
  Result := TFakePatchColumns.Create(Self, Patches[ALump]);
end;

procedure TFakePatchSource.Released;
begin
  Dec(FOpenNow);
end;

end.
