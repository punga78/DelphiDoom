{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III shaders - finding the shaders of a .shader file       }
{                                                                              }
{  Port of the scan of ScanAndLoadShaderFiles and of FindShaderInShaderText    }
{  (renderer\tr_shader.c of Quake III Arena, id Software, GPL v2 or later):    }
{  the file goes through COM_Compress, then a name and SkipBracedSection.      }
{  Based on the Quake III Arena GPL Source Code (id Software).                 }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Q3Shader.FileScanner;

interface

uses
  DelphiDoom.Decl.FileScanner.Intf;

type
  /// <summary>
  ///   The syntax of a <c>.shader</c> file: <c>name { ... }</c> with no type word, words split by
  ///   COM_ParseExt. The file is compressed first (<c>TQ3ShaderCompressor</c>), as the original does, and what the
  ///   declarations hold is the compressed text; <c>Offset</c>, <c>Length</c> and <c>Line</c> of a block are
  ///   those of the file. A name is every word that is not inside a braced section; what follows it is skipped
  ///   with SkipBracedSection (if it is not a brace, only that word is skipped, as in the original).
  ///   Unlike the original, which joins all the files in a text, each file stands alone.
  /// </summary>
  TQ3ShaderFileScanner = class sealed
  public
    class function Scan(const AText: AnsiString; const ATypeId: Integer;
      out ANumLines: Integer): TArray<TDeclScannedBlock>; static;
  end;

implementation

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Decl.Q3Shader.Tokenizer,
  DelphiDoom.Decl.Q3Shader.Compressor;

{ TQ3ShaderFileScanner }

class function TQ3ShaderFileScanner.Scan(const AText: AnsiString; const ATypeId: Integer;
  out ANumLines: Integer): TArray<TDeclScannedBlock>;
var
  LTokenizer: TQ3ShaderTokenizer;
  LBlock: TDeclScannedBlock;
  LCompressed: AnsiString;
  LMap: TArray<Integer>;
  LStart, LEnd, LCounted, LLine, LIndex, LOriginalStart, LOriginalEnd: Integer;
  LName: AnsiString;
  LBlocks: TList<TDeclScannedBlock>;
begin
  LCompressed := TQ3ShaderCompressor.Compress(AText, LMap);
  LCounted := 1;
  LLine := 1;
  // the text of a declaration starts where the one before ended: the comments above it belong to it
  LOriginalStart := 1;
  LTokenizer := TQ3ShaderTokenizer.Create(LCompressed);
  LBlocks := TList<TDeclScannedBlock>.Create;
  try
    while True do
    begin
      LStart := LTokenizer.Position;
      LName := LTokenizer.ParseExt(True);
      // an empty word (also an empty "") is the end for the original
      if LName = '' then
        Break;
      LTokenizer.SkipBracedSection;
      if LTokenizer.Ended then
      begin
        LEnd := Length(LCompressed) + 1;
        LOriginalEnd := Length(AText) + 1;
      end
      else
      begin
        LEnd := LTokenizer.Position;
        // the character after the last one of the block, in the file
        LOriginalEnd := LMap[LEnd - 2] + 1;
      end;
      for LIndex := LCounted to LOriginalStart - 1 do
        if AText[LIndex] = #10 then
          Inc(LLine);
      LCounted := LOriginalStart;
      LBlock.TypeId := ATypeId;
      LBlock.Name := LName;
      LBlock.Offset := LOriginalStart - 1;
      LBlock.Length := LOriginalEnd - LOriginalStart;
      LBlock.Line := LLine;
      LBlock.Text := Copy(LCompressed, LStart, LEnd - LStart);
      LBlocks.Add(LBlock);
      LOriginalStart := LOriginalEnd;
    end;
    Result := LBlocks.ToArray;
  finally
    LBlocks.Free;
    LTokenizer.Free;
  end;
  ANumLines := 1;
  for LIndex := 1 to Length(AText) do
    if AText[LIndex] = #10 then
      Inc(ANumLines);
end;

end.
