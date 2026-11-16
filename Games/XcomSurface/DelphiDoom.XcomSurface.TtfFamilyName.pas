{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom surface library - reads the family name written in a        }
{  TrueType or OpenType font file                                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSurface.TtfFamilyName;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   A font registered from a file is then asked for by its family name, which is in the "name" table of the
  ///   file (name id 1). Single fonts (.ttf, .otf) and collections (.ttc: Windows registers every font of the file
  ///   and the family tells which one is used; without a name the family of font Index is read)
  /// </summary>
  TXcomTtfFamilyName = class sealed
  strict private
    const
      NAME_ID_FAMILY = 1;
      PLATFORM_UNICODE = 0;
      PLATFORM_MACINTOSH = 1;
      PLATFORM_WINDOWS = 3;
      LANGUAGE_ENGLISH_US = $409;
    class function WordAt(const AData: TBytes; AOffset: Integer; out AValue: Integer): Boolean; static;
    class function LongAt(const AData: TBytes; AOffset: Integer; out AValue: Int64): Boolean; static;
  public
    /// <summary>The bytes are a collection of fonts (.ttc: they start with "ttcf")</summary>
    class function IsCollection(const AData: TBytes): Boolean; static;
    /// <summary>How many fonts the file has: the count of a collection, 1 for a single font</summary>
    class function FaceCount(const AData: TBytes): Integer; static;
    /// <summary>
    ///   False when the bytes are not a font or have no family name. The Windows name in English is preferred,
    ///   then any Windows or Unicode name (UTF-16 big endian), then a Macintosh one (one byte per character).
    ///   The first font of a collection
    /// </summary>
    class function TryRead(const AData: TBytes; out AName: string): Boolean; overload; static;
    /// <summary>The family of font AIndex of a collection (0 for a single font); false for an index the file does not have</summary>
    class function TryRead(const AData: TBytes; AIndex: Integer; out AName: string): Boolean; overload; static;
  end;

implementation

class function TXcomTtfFamilyName.WordAt(const AData: TBytes; AOffset: Integer; out AValue: Integer): Boolean;
begin
  AValue := 0;
  Result := (AOffset >= 0) and (AOffset + 2 <= Length(AData));
  if Result then
    AValue := AData[AOffset] shl 8 or AData[AOffset + 1];
end;

class function TXcomTtfFamilyName.LongAt(const AData: TBytes; AOffset: Integer; out AValue: Int64): Boolean;
begin
  AValue := 0;
  Result := (AOffset >= 0) and (AOffset + 4 <= Length(AData));
  if Result then
    AValue := Int64(AData[AOffset]) shl 24 or AData[AOffset + 1] shl 16 or AData[AOffset + 2] shl 8 or
      AData[AOffset + 3];
end;

class function TXcomTtfFamilyName.FaceCount(const AData: TBytes): Integer;
var
  LCount: Int64;
begin
  Result := 1;
  if IsCollection(AData) and LongAt(AData, 8, LCount) and (LCount > 0) and (LCount < 1024) then
    Result := Integer(LCount);
end;

class function TXcomTtfFamilyName.IsCollection(const AData: TBytes): Boolean;
begin
  Result := (Length(AData) >= 16) and (AData[0] = Ord('t')) and (AData[1] = Ord('t')) and (AData[2] = Ord('c')) and
    (AData[3] = Ord('f'));
end;

class function TXcomTtfFamilyName.TryRead(const AData: TBytes; out AName: string): Boolean;
begin
  Result := TryRead(AData, 0, AName);
end;

class function TXcomTtfFamilyName.TryRead(const AData: TBytes; AIndex: Integer; out AName: string): Boolean;
var
  LBase: Integer;
  LOffset32: Int64;
  LTableCount: Integer;
  LTable: Integer;
  LRecord: Integer;
  LTableOffset: Int64;
  LCount: Integer;
  LStrings: Integer;
  LIndex: Integer;
  LPlatform: Integer;
  LLanguage: Integer;
  LNameId: Integer;
  LLength: Integer;
  LOffset: Integer;
  LStart: Integer;
  LNameTable: Integer;
  LRank: Integer;
  LBest: Integer;
  LText: string;
  LChar: Integer;
begin
  AName := '';
  LBase := 0;
  if IsCollection(AData) then
  begin
    // a collection: the offsets of the fonts follow the count; the tables of each are addressed from the file start
    if (AIndex < 0) or (AIndex >= FaceCount(AData)) or not LongAt(AData, 12 + AIndex * 4, LOffset32) or
      (LOffset32 > Length(AData)) then
      Exit(False);
    LBase := Integer(LOffset32);
  end
  else if AIndex <> 0 then
    Exit(False);
  if not WordAt(AData, LBase + 4, LTableCount) then
    Exit(False);
  LTableOffset := -1;
  for LTable := 0 to LTableCount - 1 do
  begin
    LRecord := LBase + 12 + LTable * 16;
    if LRecord + 16 > Length(AData) then
      Exit(False);
    if (AData[LRecord] = Ord('n')) and (AData[LRecord + 1] = Ord('a')) and (AData[LRecord + 2] = Ord('m')) and
      (AData[LRecord + 3] = Ord('e')) then
      LongAt(AData, LRecord + 8, LTableOffset);
  end;
  if (LTableOffset < 0) or (LTableOffset > Length(AData)) then
    Exit(False);
  LNameTable := Integer(LTableOffset);
  if not WordAt(AData, LNameTable + 2, LCount) or
    not WordAt(AData, LNameTable + 4, LStrings) then
    Exit(False);
  LBest := 0;
  for LIndex := 0 to LCount - 1 do
  begin
    LRecord := LNameTable + 6 + LIndex * 12;
    if not WordAt(AData, LRecord + 10, LOffset) then
      Break;
    WordAt(AData, LRecord, LPlatform);
    WordAt(AData, LRecord + 4, LLanguage);
    WordAt(AData, LRecord + 6, LNameId);
    WordAt(AData, LRecord + 8, LLength);
    if LNameId <> NAME_ID_FAMILY then
      Continue;
    if (LPlatform = PLATFORM_WINDOWS) and (LLanguage = LANGUAGE_ENGLISH_US) then
      LRank := 4
    else if LPlatform = PLATFORM_WINDOWS then
      LRank := 3
    else if LPlatform = PLATFORM_UNICODE then
      LRank := 2
    else if LPlatform = PLATFORM_MACINTOSH then
      LRank := 1
    else
      LRank := 0;
    LStart := LNameTable + LStrings + LOffset;
    if (LRank <= LBest) or (LLength = 0) or (LStart + LLength > Length(AData)) then
      Continue;
    LText := '';
    if LPlatform = PLATFORM_MACINTOSH then
      for LChar := 0 to LLength - 1 do
        LText := LText + Char(AData[LStart + LChar])
    else
      for LChar := 0 to LLength div 2 - 1 do
        LText := LText + Char(AData[LStart + LChar * 2] shl 8 or AData[LStart + LChar * 2 + 1]);
    AName := LText;
    LBest := LRank;
  end;
  Result := AName <> '';
end;

end.
