{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom game - the setting of the composition in true color         }
{  (issue 183) as a row of the advanced options: "trueColor" of options.cfg     }
{                                                                              }
{  Licensed under the GNU General Public License, version 3 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.TrueColorOption;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Options, DelphiDoom.XcomEngine.ExtraOptions.Intf;

type
  /// <summary>
  ///   IXcomExtraOptions with the one setting OpenXcom does not have: the frame composed in true color. It is the
  ///   key "trueColor" of the section "options" of options.cfg, that OpenXcom does not know: the options keep it
  ///   among the unknown ones and write it back. The options are not owned
  /// </summary>
  TXcomTrueColorOption = class(TInterfacedObject, IXcomExtraOptions)
  public
    const
      OPTION_ID = 'trueColor';
  strict private
    FOptions: TXcomOptions;
  public
    constructor Create(AOptions: TXcomOptions);
    function Heading: string;
    function Count: Integer;
    function Title(AIndex: Integer): string;
    function Description(AIndex: Integer): string;
    function IsOn(AIndex: Integer): Boolean;
    procedure SetOn(AIndex: Integer; AValue: Boolean);
    /// <summary>What the options file says</summary>
    class function Wanted(AOptions: TXcomOptions): Boolean; static;
  end;

implementation

const
  SHeading = 'DELPHIDOOM';
  STitle = '32-bit drawing';
  SDescription = 'True color picture: at 2x or more the globe, the graphs and the radars are drawn at the ' +
    'resolution of the window, smoke and fire are blended.';

constructor TXcomTrueColorOption.Create(AOptions: TXcomOptions);
begin
  inherited Create;
  if not Assigned(AOptions) then
    raise EArgumentNilException.Create('AOptions');
  FOptions := AOptions;
end;

class function TXcomTrueColorOption.Wanted(AOptions: TXcomOptions): Boolean;
var
  LValue: string;
begin
  Result := AOptions.UnknownOptions.TryGetValue(OPTION_ID, LValue) and SameText(LValue, 'true');
end;

function TXcomTrueColorOption.Heading: string;
begin
  Result := SHeading;
end;

function TXcomTrueColorOption.Count: Integer;
begin
  Result := 1;
end;

function TXcomTrueColorOption.Title(AIndex: Integer): string;
begin
  Result := STitle;
end;

function TXcomTrueColorOption.Description(AIndex: Integer): string;
begin
  Result := SDescription;
end;

function TXcomTrueColorOption.IsOn(AIndex: Integer): Boolean;
begin
  Result := Wanted(FOptions);
end;

procedure TXcomTrueColorOption.SetOn(AIndex: Integer; AValue: Boolean);
begin
  if AValue then
    FOptions.UnknownOptions.AddOrSetValue(OPTION_ID, 'true')
  else
    FOptions.UnknownOptions.AddOrSetValue(OPTION_ID, 'false');
end;

end.
