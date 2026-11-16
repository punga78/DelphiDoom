{******************************************************************************}
{                                                                              }
{  DelphiDoom: DEHACKED library - the names a patch file is looked for under   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Dehacked.FileNames;

interface

uses
  System.SysUtils;

type
  /// <summary>The names under which DEH_ParseFile looks for a patch</summary>
  TDehackedFileNames = class sealed
  public
    /// <summary>
    ///   The names to try, in order: the name as given, or with .deh and then .bex if it has no
    ///   point; then, for every one of those from the last to the first, the name in the folder of
    ///   the saved files (AInSaveFolder) if it is another one
    /// </summary>
    class function Candidates(const AFileName: string;
      const AInSaveFolder: TFunc<string, string>): TArray<string>; static;
  end;

implementation

uses
  System.Generics.Collections;

{ TDehackedFileNames }

class function TDehackedFileNames.Candidates(const AFileName: string;
  const AInSaveFolder: TFunc<string, string>): TArray<string>;
var
  LNames: TList<string>;
  LIndex: Integer;
  LMapped: string;
begin
  LNames := TList<string>.Create;
  try
    if Pos('.', AFileName) = 0 then
    begin
      LNames.Add(AFileName + '.deh');
      LNames.Add(AFileName + '.bex');
    end
    else
      LNames.Add(AFileName);

    for LIndex := LNames.Count - 1 downto 0 do
    begin
      LMapped := AInSaveFolder(LNames[LIndex]);
      if LMapped <> LNames[LIndex] then
        LNames.Add(LMapped);
    end;
    Result := LNames.ToArray;
  finally
    LNames.Free;
  end;
end;

end.
