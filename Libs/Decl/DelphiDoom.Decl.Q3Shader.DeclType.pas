{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III shaders - the registered type "shader"                }
{                                                                              }
{  Written from the description of the contract of Libs\Decl (issue #119).     }
{  Licensed under the GNU General Public License, version 2 or later.          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Q3Shader.DeclType;

interface

uses
  DelphiDoom.IdLib.Core.Intf, DelphiDoom.Decl.Intf, DelphiDoom.Decl.TypeInfo, DelphiDoom.Decl.FileScanner.Intf,
  DelphiDoom.Decl.Q3Shader.Types;

type
  /// <summary>
  ///   The type "shader": the usual <c>TDeclTypeInfo</c> that also is the scanner of its files (<c>IDeclFileScanner</c>),
  ///   which is how the type has a syntax of its own
  /// </summary>
  TQ3ShaderDeclType = class(TDeclTypeInfo, IDeclFileScanner)
  public
    constructor Create(const AOptions: TQ3ShaderOptions);
    function ScanFile(const AText, AFileName: AnsiString; const ADefaultType: Integer; const ALog: IIdLibLog;
      out ANumLines: Integer): TArray<TDeclScannedBlock>;
  end;

implementation

uses
  DelphiDoom.Decl.Q3Shader, DelphiDoom.Decl.Q3Shader.FileScanner;

{ TQ3ShaderDeclType }

constructor TQ3ShaderDeclType.Create(const AOptions: TQ3ShaderOptions);
var
  LOptions: TQ3ShaderOptions;
begin
  LOptions := AOptions;
  inherited Create('shader', DECL_Q3SHADER,
    function: IDecl
    begin
      Result := TDeclQ3Shader.Create(LOptions);
    end);
end;

function TQ3ShaderDeclType.ScanFile(const AText, AFileName: AnsiString; const ADefaultType: Integer;
  const ALog: IIdLibLog; out ANumLines: Integer): TArray<TDeclScannedBlock>;
begin
  Result := TQ3ShaderFileScanner.Scan(AText, ADefaultType, ANumLines);
end;

end.
