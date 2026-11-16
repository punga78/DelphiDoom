{******************************************************************************}
{                                                                              }
{  DelphiDoom: voxel editor - the DDVOX file (the file of the editor)           }
{  Copyright (C) 2013-2025 by Jim Valavanis (original DD_VOXEL)                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.VoxelEditor.Format.Ddvox;

interface

uses
  System.SysUtils,
  DelphiDoom.VoxelEditor.Model;

type
  /// <summary>
  ///   The DDVOX file, a text: the size of the cube on the first line, then a line for each (x, y) with the colors of
  ///   its z cells as decimal numbers, "skip N" standing for N empty cells, separated by commas
  ///   (DoSaveVoxel and DoLoadVoxel of the main window of DD_VOXEL)
  /// </summary>
  TVoxelEditorDdvoxFormat = class sealed
  public
    /// <summary>The text of the file, one byte for each character, lines ended by CR LF</summary>
    class function Write(const AModel: TVoxelEditorModel): TBytes; static;
    /// <summary>
    ///   Reads the file into the model (its size becomes the one of the file). Numbers are decimal, or $hex or 0xhex;
    ///   words are separated by spaces, tabs, line ends and commas. A "skip" that goes beyond the row, and
    ///   anything that is not a number, is an EVoxelEditorException (the old loader wrote outside the cube)
    /// </summary>
    class procedure Read(const ABytes: TBytes; const AModel: TVoxelEditorModel); static;
  end;

implementation

uses
  System.Classes, System.Generics.Collections,
  DelphiDoom.VoxelEditor.Types;

resourcestring
  SDdvoxNotNumber = 'a number was expected, not "%s"';
  SDdvoxNoSize = 'the size of the voxel is missing';
  SDdvoxTooMuch = 'a row of the voxel is longer than its size';

function ParseNumber(const AWord: string): Cardinal;
var
  LValue: Int64;
begin
  if (Length(AWord) > 2) and (AWord[1] = '0') and ((AWord[2] = 'x') or (AWord[2] = 'X')) then
  begin
    if not TryStrToInt64('$' + Copy(AWord, 3, MaxInt), LValue) then
      raise EVoxelEditorException.CreateFmt(SVoxelEditorBadFile, [Format(SDdvoxNotNumber, [AWord])]);
  end
  else if not TryStrToInt64(AWord, LValue) then
    raise EVoxelEditorException.CreateFmt(SVoxelEditorBadFile, [Format(SDdvoxNotNumber, [AWord])]);
  Result := Cardinal(LValue);
end;

function Split(const AText: string): TList<string>;
var
  LIndex, LStart: Integer;
begin
  Result := TList<string>.Create;
  LStart := 0;
  for LIndex := 1 to Length(AText) + 1 do
    if (LIndex > Length(AText)) or CharInSet(AText[LIndex], [#0..' ', ',']) then
    begin
      if LIndex - 1 > LStart then
        Result.Add(Copy(AText, LStart + 1, LIndex - 1 - LStart));
      LStart := LIndex;
    end;
end;

{ TVoxelEditorDdvoxFormat }

class function TVoxelEditorDdvoxFormat.Write(const AModel: TVoxelEditorModel): TBytes;
var
  LBuilder: TStringBuilder;
  LSize, LX, LY, LZ, LSkip: Integer;
  LColor: Cardinal;
begin
  LSize := AModel.Size;
  LBuilder := TStringBuilder.Create;
  try
    LBuilder.Append(LSize).Append(#13#10);
    for LX := 0 to LSize - 1 do
      for LY := 0 to LSize - 1 do
      begin
        LSkip := 0;
        for LZ := 0 to LSize - 1 do
        begin
          LColor := AModel.Get(LX, LY, LZ);
          if LColor = 0 then
          begin
            Inc(LSkip);
            if LZ = LSize - 1 then
              LBuilder.Append('skip ').Append(LSkip).Append(#13#10);
          end
          else
          begin
            if LSkip > 0 then
            begin
              LBuilder.Append('skip ').Append(LSkip).Append(', ');
              LSkip := 0;
            end;
            LBuilder.Append(LColor);
            if LZ = LSize - 1 then
              LBuilder.Append(#13#10)
            else
              LBuilder.Append(', ');
          end;
        end;
      end;
    Result := TEncoding.ANSI.GetBytes(LBuilder.ToString);
  finally
    LBuilder.Free;
  end;
end;

class procedure TVoxelEditorDdvoxFormat.Read(const ABytes: TBytes; const AModel: TVoxelEditorModel);
var
  LWords: TList<string>;
  LIndex, LSize, LX, LY, LZ: Integer;
begin
  LWords := Split(TEncoding.ANSI.GetString(ABytes));
  try
    if LWords.Count = 0 then
      raise EVoxelEditorException.CreateFmt(SVoxelEditorBadFile, [SDdvoxNoSize]);
    LSize := Integer(ParseNumber(LWords[0]));
    AModel.Reset(LSize);
    LX := 0;
    LY := 0;
    LZ := 0;
    LIndex := 1;
    while LIndex < LWords.Count do
    begin
      if SameText(LWords[LIndex], 'skip') then
      begin
        Inc(LIndex);
        if LIndex >= LWords.Count then
          raise EVoxelEditorException.CreateFmt(SVoxelEditorBadFile, [SDdvoxNoSize]);
        Inc(LZ, Integer(ParseNumber(LWords[LIndex])));
      end
      else
      begin
        if LZ >= LSize then
          raise EVoxelEditorException.CreateFmt(SVoxelEditorBadFile, [SDdvoxTooMuch]);
        AModel.Put(LX, LY, LZ, ParseNumber(LWords[LIndex]));
        Inc(LZ);
      end;
      Inc(LIndex);
      if LZ > LSize then
        raise EVoxelEditorException.CreateFmt(SVoxelEditorBadFile, [SDdvoxTooMuch]);
      if LZ = LSize then
      begin
        LZ := 0;
        Inc(LY);
        if LY = LSize then
        begin
          LY := 0;
          Inc(LX);
          if LX = LSize then
            Break;
        end;
      end;
    end;
  finally
    LWords.Free;
  end;
end;

end.
