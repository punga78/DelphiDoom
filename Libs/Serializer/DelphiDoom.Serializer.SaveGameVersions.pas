{******************************************************************************}
{                                                                              }
{  DelphiDoom: serializer library - the versions of the saved games            }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Serializer.SaveGameVersions;

interface

type
  /// <summary>How the text of the version of a saved game compares with the ones the game reads</summary>
  TSaveGameVersionStatus = (
    /// <summary>The version of the engine</summary>
    sgvCurrent,
    /// <summary>An older version the game still reads</summary>
    sgvCompatible,
    /// <summary>The file is too short to have a version</summary>
    sgvTooShort,
    /// <summary>A version the game does not read</summary>
    sgvUnsupported
  );

  /// <summary>
  ///   The versions of the saved games a game can load: the current one and a table of the older
  ///   ones with the number the loader switches on (the chain of tests on the text of the version
  ///   of G_DoLoadGame)
  /// </summary>
  TSaveGameVersions = class sealed
  strict private
    type
      TEntry = record
        Text: string;
        Version: Integer;
        Hack: Integer;
      end;
  strict private
    FCurrent: Integer;
    FPrefix: string;
    FEntries: TArray<TEntry>;
  public
    /// <param name="ACurrent">The number of the version the engine writes</param>
    /// <param name="APrefix">The word before the number in the text of the current version ("version", "heretic")</param>
    constructor Create(const ACurrent: Integer; const APrefix: string = 'version');

    /// <summary>Accepts an older version</summary>
    /// <param name="AText">The text in the file, for example "version 206"</param>
    /// <param name="AVersion">The number the loader uses for the fields of that version</param>
    /// <param name="AHack">A number the game gives to a file of its own that has the version text of another (0 for none)</param>
    procedure AddCompatible(const AText: string; const AVersion: Integer; const AHack: Integer = 0);

    /// <summary>
    ///   Reads the text of the version of a file
    /// </summary>
    /// <param name="AHeader">The first byte of the field of the version</param>
    /// <param name="AFileLength">
    ///   The size of the whole file: it is compared with the length of the text of the current version, not with
    ///   what is left after the description (as before)
    /// </param>
    /// <param name="AVersion">The number to load with (the current one for sgvCurrent)</param>
    /// <param name="AHack">The hack of the entry, 0 for the others</param>
    /// <param name="ASavedText">The text found in the file when it is not the current one (for the warning)</param>
    function Resolve(const AHeader: PByte; const AFileLength: Integer; out AVersion: Integer;
      out AHack: Integer; out ASavedText: string): TSaveGameVersionStatus;
  end;

implementation

uses
  System.SysUtils;

{ TSaveGameVersions }

constructor TSaveGameVersions.Create(const ACurrent: Integer; const APrefix: string);
begin
  inherited Create;
  FCurrent := ACurrent;
  FPrefix := APrefix;
end;

procedure TSaveGameVersions.AddCompatible(const AText: string; const AVersion: Integer;
  const AHack: Integer);
var
  LCount: Integer;
begin
  LCount := Length(FEntries);
  SetLength(FEntries, LCount + 1);
  FEntries[LCount].Text := AText;
  FEntries[LCount].Version := AVersion;
  FEntries[LCount].Hack := AHack;
end;

function TSaveGameVersions.Resolve(const AHeader: PByte; const AFileLength: Integer;
  out AVersion: Integer; out AHack: Integer; out ASavedText: string): TSaveGameVersionStatus;
var
  LCurrentText: string;
  LIndex: Integer;
  LEntry: Integer;
  LMismatch: Boolean;
begin
  AVersion := FCurrent; // assume the current version
  AHack := 0;
  ASavedText := '';
  LCurrentText := FPrefix + ' ' + IntToStr(FCurrent);

  if AFileLength < Length(LCurrentText) then
  begin
    Result := sgvTooShort;
    Exit;
  end;

  LMismatch := False;
  for LIndex := 0 to Length(LCurrentText) - 1 do
    if AHeader[LIndex] <> Ord(LCurrentText[LIndex + 1]) then
    begin
      LMismatch := True;
      Break;
    end;

  if not LMismatch then
  begin
    Result := sgvCurrent;
    Exit;
  end;

  for LIndex := 0 to Length(LCurrentText) - 1 do
    ASavedText := ASavedText + Chr(AHeader[LIndex]);

  // the first entry with the text wins, as the chain of tests did
  for LEntry := 0 to High(FEntries) do
    if FEntries[LEntry].Text = ASavedText then
    begin
      AVersion := FEntries[LEntry].Version;
      AHack := FEntries[LEntry].Hack;
      Result := sgvCompatible;
      Exit;
    end;

  Result := sgvUnsupported;
end;

end.
