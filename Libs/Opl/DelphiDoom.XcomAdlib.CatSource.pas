{******************************************************************************}
{                                                                              }
{  DelphiDoom: X-COM Adlib player - the songs of an ADLIB.CAT or GM.CAT         }
{                                                                              }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\Opl\README.md for the license                                           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomAdlib.CatSource;

interface

uses
  System.SysUtils, DelphiDoom.Xcom.Intf, DelphiDoom.XcomAdlib.Intf;

type
  /// <summary>The songs of an Adlib container: the entries of a CAT file, each with the name skipped</summary>
  TXcomCatAdlibSource = class(TInterfacedObject, IXcomAdlibMusicSource)
  strict private
    FArchive: IXcomCatArchive;
  public
    constructor Create(const AArchive: IXcomCatArchive);
    function TrackCount: Integer;
    function LoadTrack(AIndex: Integer): TBytes;
    function LoadTrackWithName(AIndex: Integer): TBytes;
  end;

implementation

{ TXcomCatAdlibSource }

constructor TXcomCatAdlibSource.Create(const AArchive: IXcomCatArchive);
begin
  inherited Create;
  FArchive := AArchive;
end;

function TXcomCatAdlibSource.TrackCount: Integer;
begin
  Result := FArchive.GetCount;
end;

function TXcomCatAdlibSource.LoadTrack(AIndex: Integer): TBytes;
begin
  Result := FArchive.Load(AIndex, False);
end;

function TXcomCatAdlibSource.LoadTrackWithName(AIndex: Integer): TBytes;
begin
  Result := FArchive.Load(AIndex, True);
end;

end.
