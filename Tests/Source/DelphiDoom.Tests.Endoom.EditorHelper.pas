{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the endoom library - what the editor tests share        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Endoom.EditorHelper;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections,
  DelphiDoom.Endoom.Intf,
  DelphiDoom.Tests.Endoom.EditorScenarios;

type
  TEditorHelper = class
  public
    /// <summary>The lines of a golden file of Tests\Data\Endoom (the editor's by default) that start with AKind, without it</summary>
    class function GoldenLines(const AKind: string; const AFile: string = 'editor.golden.txt'): TArray<string>; static;
    /// <summary>The changes of cells of the scenarios on the screen of the library</summary>
    class procedure ApplyOps(const AScreen: IEndoomScreen; const AOps: TArray<TEditorModelOp>); static;
    /// <summary>The 640x200 pixels without the alpha byte (the old bitmap had none), as a fingerprint</summary>
    class function PixelDigest(const APixels: TArray<Cardinal>): string; static;
  end;

implementation

uses
  DelphiDoom.Endoom.ColorQuantizer, DelphiDoom.Tests.Endoom.Digest;

{ TEditorHelper }

class function TEditorHelper.GoldenLines(const AKind, AFile: string): TArray<string>;
var
  LLines: TStringList;
  LResult: TList<string>;
  LLine: string;
  LPrefix: string;
begin
  LResult := TList<string>.Create;
  LLines := TStringList.Create;
  try
    LLines.LoadFromFile(TPath.GetFullPath(ExtractFilePath(ParamStr(0)) + '..\..\Tests\Data\Endoom\' + AFile));
    LPrefix := AKind + ' ';
    for LLine in LLines do
      if LLine.StartsWith(LPrefix) then
        LResult.Add(Copy(LLine, Length(LPrefix) + 1, MaxInt));
    Result := LResult.ToArray;
  finally
    LLines.Free;
    LResult.Free;
  end;
end;

class procedure TEditorHelper.ApplyOps(const AScreen: IEndoomScreen; const AOps: TArray<TEditorModelOp>);
var
  LOp: TEditorModelOp;
begin
  for LOp in AOps do
    case LOp.Kind of
      EDITOR_OP_CHARACTER:
        AScreen.SetCharacter(LOp.X, LOp.Y, Byte(LOp.Value));
      EDITOR_OP_FOREGROUND:
        AScreen.SetForeground(LOp.X, LOp.Y,
          TEndoomColorQuantizer.NearestForeground(TEditorScenarios.ToRgb(LOp.Color)));
      EDITOR_OP_BACKGROUND:
        AScreen.SetBackground(LOp.X, LOp.Y,
          TEndoomColorQuantizer.NearestBackground(TEditorScenarios.ToRgb(LOp.Color)));
      EDITOR_OP_BLINK:
        AScreen.SetBlink(LOp.X, LOp.Y, Odd(LOp.Value));
      EDITOR_OP_CLEAR:
        AScreen.Clear;
    end;
end;

class function TEditorHelper.PixelDigest(const APixels: TArray<Cardinal>): string;
var
  LMasked: TArray<Cardinal>;
  LIndex: Integer;
begin
  SetLength(LMasked, Length(APixels));
  for LIndex := 0 to High(APixels) do
    LMasked[LIndex] := APixels[LIndex] and $FFFFFF;
  Result := TEndoomDigest.OfCardinals(LMasked);
end;

end.
