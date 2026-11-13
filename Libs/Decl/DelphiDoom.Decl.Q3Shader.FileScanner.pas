{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III shaders - finding the shaders of a .shader file       }
{                                                                              }
{  Port of the scan of ScanAndLoadShaderFiles and of FindShaderInShaderText    }
{  (renderer\tr_shader.c of Quake III Arena, id Software, GPL v2 or later):    }
{  a name, then SkipBracedSection. Based on the Quake III Arena GPL Source     }
{  Code (id Software).                                                         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Q3Shader.FileScanner;

interface

uses
  DelphiDoom.Decl.FileScanner.Intf;

type
  /// <summary>
  ///   The syntax of a <c>.shader</c> file: <c>name { ... }</c> with no type word, words split by
  ///   COM_ParseExt. A name is every word that is not inside a braced section; what follows it is skipped
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
  System.SysUtils, System.Generics.Collections, DelphiDoom.Decl.Q3Shader.Tokenizer;

{ TQ3ShaderFileScanner }

class function TQ3ShaderFileScanner.Scan(const AText: AnsiString; const ATypeId: Integer;
  out ANumLines: Integer): TArray<TDeclScannedBlock>;
var
  LTokenizer: TQ3ShaderTokenizer;
  LBlock: TDeclScannedBlock;
  LStart, LEnd, LCounted, LLine, LIndex: Integer;
  LName: AnsiString;
  LBlocks: TList<TDeclScannedBlock>;
begin
  LCounted := 1;
  LLine := 1;
  LTokenizer := TQ3ShaderTokenizer.Create(AText);
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
        LEnd := Length(AText) + 1
      else
        LEnd := LTokenizer.Position;
      for LIndex := LCounted to LStart - 1 do
        if AText[LIndex] = #10 then
          Inc(LLine);
      LCounted := LStart;
      LBlock.TypeId := ATypeId;
      LBlock.Name := LName;
      LBlock.Offset := LStart - 1;
      LBlock.Length := LEnd - LStart;
      LBlock.Line := LLine;
      LBlocks.Add(LBlock);
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
