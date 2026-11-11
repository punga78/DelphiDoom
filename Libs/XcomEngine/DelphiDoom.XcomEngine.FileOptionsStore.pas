{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - the options in options.cfg                 }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.FileOptionsStore;

interface

uses
  System.SysUtils, System.IOUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomEngine.Options,
  DelphiDoom.XcomEngine.OptionsStore.Intf;

type
  /// <summary>
  ///   IXcomOptionsStore on the file options.cfg of the user folder. Saving writes the options (the registered ones and
  ///   the unknown keys that were read) and keeps every other top-level section of the file as it is (mods, ...)
  /// </summary>
  TXcomFileOptionsStore = class(TInterfacedObject, IXcomOptionsStore)
  strict private
    FFiles: IXcomFileSystem;
    FParser: IYamlParser;
    FPath: string;
    /// <summary>The text of the top-level sections of the file other than "options", in their order, with the place of options</summary>
    function MergeOptions(const AExisting, AOptionsBlock: string): string;
  public
    constructor Create(const AFiles: IXcomFileSystem; const AParser: IYamlParser; const AUserFolder: string);
    procedure Load(AOptions: TXcomOptions);
    procedure Save(AOptions: TXcomOptions);
  end;

implementation

constructor TXcomFileOptionsStore.Create(const AFiles: IXcomFileSystem; const AParser: IYamlParser;
  const AUserFolder: string);
begin
  inherited Create;
  FFiles := AFiles;
  FParser := AParser;
  if AUserFolder <> '' then
    FPath := TPath.Combine(AUserFolder, 'options.cfg');
end;

procedure TXcomFileOptionsStore.Load(AOptions: TXcomOptions);
begin
  if (FPath <> '') and FFiles.FileExists(FPath) then
    AOptions.Load(FParser.Load(FFiles.ReadAll(FPath)));
end;

function TXcomFileOptionsStore.MergeOptions(const AExisting, AOptionsBlock: string): string;
var
  LLines: TArray<string>;
  LLine: string;
  LBuilder: TStringBuilder;
  LInOptions: Boolean;
  LWritten: Boolean;
  LTopLevel: Boolean;
begin
  LBuilder := TStringBuilder.Create;
  try
    LInOptions := False;
    LWritten := False;
    LLines := AExisting.Replace(#13#10, #10).Split([#10]);
    for LLine in LLines do
    begin
      // a top-level key starts at the first column with a letter (comments, sequences and blanks do not)
      LTopLevel := (LLine <> '') and (LLine[1] <> ' ') and (LLine[1] <> '#') and (LLine[1] <> '-') and
        (LLine[1] <> #9);
      if LTopLevel then
      begin
        LInOptions := LLine.StartsWith('options:');
        if LInOptions then
        begin
          LBuilder.Append(AOptionsBlock);
          LWritten := True;
          Continue;
        end;
      end;
      if LInOptions then
        Continue;
      if (LLine = '') and (LLine = LLines[High(LLines)]) then
        Continue;
      LBuilder.Append(LLine).Append(#10);
    end;
    if not LWritten then
      LBuilder.Append(AOptionsBlock);
    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
end;

procedure TXcomFileOptionsStore.Save(AOptions: TXcomOptions);
var
  LText: string;
begin
  if FPath = '' then
    Exit;
  LText := AOptions.Save;
  if FFiles.FileExists(FPath) then
    LText := MergeOptions(TEncoding.UTF8.GetString(FFiles.ReadAll(FPath)), LText);
  FFiles.WriteAll(FPath, TEncoding.UTF8.GetBytes(LText));
end;

end.
