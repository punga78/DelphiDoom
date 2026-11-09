{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - the death of a soldier (SoldierDeath) }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.SoldierDeath;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.NodeReader, DelphiDoom.XcomSave.NodeWriter,
  DelphiDoom.XcomSave.GameTime, DelphiDoom.XcomSave.BattleUnitKills;

type
  /// <summary>When a soldier died and, if known, the kill that ended his life. Owns both</summary>
  TXcomSoldierDeath = class
  strict private
    FTime: TXcomGameTime;
    FCause: TXcomBattleUnitKills;
  public
    /// <summary>A death at time zero without a cause (to load into)</summary>
    constructor Create; overload;
    /// <param name="ATime">Copied</param>
    /// <param name="ACause">Taken over by the death (freed with it); may be nil</param>
    constructor Create(const ATime: TXcomGameTime; ACause: TXcomBattleUnitKills); overload;
    destructor Destroy; override;
    /// <summary>Loads the death; a node without the time raises EYamlInvalidNode (as the C++ does)</summary>
    procedure Load(const ANode: IYamlNode);
    function Save: IYamlNode;
    /// <summary>getTime: owned by the death</summary>
    property Time: TXcomGameTime read FTime;
    /// <summary>getCause: owned by the death; nil if none</summary>
    property Cause: TXcomBattleUnitKills read FCause;
  end;

implementation

{ TXcomSoldierDeath }

constructor TXcomSoldierDeath.Create;
begin
  inherited Create;
  FTime := TXcomGameTime.Create(0, 0, 0, 0, 0, 0, 0);
end;

constructor TXcomSoldierDeath.Create(const ATime: TXcomGameTime; ACause: TXcomBattleUnitKills);
begin
  inherited Create;
  FTime := TXcomGameTime.Create(ATime.Weekday, ATime.Day, ATime.Month, ATime.Year, ATime.Hour, ATime.Minute,
    ATime.Second);
  FCause := ACause;
end;

destructor TXcomSoldierDeath.Destroy;
begin
  FCause.Free;
  FTime.Free;
  inherited Destroy;
end;

procedure TXcomSoldierDeath.Load(const ANode: IYamlNode);
var
  LField: IYamlNode;
  LCause: TXcomBattleUnitKills;
begin
  FTime.Load(TXcomNodeReader.Field(ANode, 'time'));
  LField := TXcomNodeReader.Field(ANode, 'cause');
  if LField.IsDefined then
  begin
    LCause := TXcomBattleUnitKills.Create;
    try
      LCause.Load(LField);
    except
      LCause.Free;
      raise;
    end;
    FCause.Free;
    FCause := LCause;
  end;
end;

function TXcomSoldierDeath.Save: IYamlNode;
begin
  Result := TXcomNodeWriter.NewMap;
  TXcomNodeWriter.SetNode(Result, 'time', FTime.Save);
  if Assigned(FCause) then
    TXcomNodeWriter.SetNode(Result, 'cause', FCause.Save);
end;

end.
