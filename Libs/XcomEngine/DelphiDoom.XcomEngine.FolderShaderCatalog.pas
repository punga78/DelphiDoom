{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - the shaders of common\Shaders              }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.FolderShaderCatalog;

interface

uses
  System.SysUtils, System.Generics.Collections, System.Generics.Defaults, System.IOUtils,
  DelphiDoom.XcomEngine.Intf;

type
  /// <summary>
  ///   IXcomShaderCatalog on the data folder: the shaders are the *.OpenGL.shader files of common\Shaders. The
  ///   names are given as the FileMap of OpenXcom gives them (lower case, in the order of their characters); a
  ///   shader is read by the path that the option keeps ("Shaders/..." in any case), and only from that folder.
  ///   The Shaders folders of the mods are not searched
  /// </summary>
  TXcomFolderShaderCatalog = class(TInterfacedObject, IXcomShaderCatalog)
  strict private
    const
      SHADER_FOLDER = 'Shaders';
      FILE_EXTENSION = 'shader';
      // OptionsVideoState::GL_EXT, in lower case
      SHADER_SUFFIX = 'opengl.shader';
    var
      FCommonFolder: string;
      FFiles: IXcomFileSystem;
    function Folder: string;
  public
    /// <param name="ACommonFolder">The common folder of the data (it has Shaders, Language...)</param>
    constructor Create(const ACommonFolder: string; const AFiles: IXcomFileSystem);
    function Files: TArray<string>;
    function TryRead(const APath: string; out ABytes: TBytes): Boolean;
  end;

implementation

constructor TXcomFolderShaderCatalog.Create(const ACommonFolder: string; const AFiles: IXcomFileSystem);
begin
  inherited Create;
  if not Assigned(AFiles) then
    raise EArgumentNilException.Create('AFiles');
  FCommonFolder := ACommonFolder;
  FFiles := AFiles;
end;

function TXcomFolderShaderCatalog.Folder: string;
begin
  Result := TPath.Combine(FCommonFolder, SHADER_FOLDER);
end;

function TXcomFolderShaderCatalog.Files: TArray<string>;
var
  LList: TList<string>;
  LName: string;
  LFile: string;
begin
  LList := TList<string>.Create;
  try
    for LName in FFiles.FolderContents(Folder, FILE_EXTENSION) do
    begin
      LFile := LowerCase(LName) + '.' + FILE_EXTENSION;
      // FileMap::_filterFiles: the name ends with the extension and has at least one character before its dot
      if (Length(LFile) > Length(SHADER_SUFFIX) + 1) and LFile.EndsWith(SHADER_SUFFIX) then
        LList.Add(LFile);
    end;
    // std::set<std::string>: by the codes of the characters
    LList.Sort(TComparer<string>.Construct(
      function(const ALeft, ARight: string): Integer
      begin
        Result := CompareStr(ALeft, ARight);
      end));
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

function TXcomFolderShaderCatalog.TryRead(const APath: string; out ABytes: TBytes): Boolean;
var
  LPrefix: string;
  LName: string;
  LFile: string;
begin
  ABytes := nil;
  Result := False;
  LPrefix := SHADER_FOLDER + '/';
  if not APath.StartsWith(LPrefix, True) then
    Exit;
  // a file of the folder itself: the option is text that the player can write
  LName := Copy(APath, Length(LPrefix) + 1, MaxInt);
  if (LName = '') or (LName.IndexOfAny(['/', '\', ':']) >= 0) then
    Exit;
  LFile := TPath.Combine(Folder, LName);
  if not FFiles.FileExists(LFile) then
    Exit;
  ABytes := FFiles.ReadAll(LFile);
  Result := True;
end;

end.
