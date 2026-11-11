{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom ruleset library - the rules of the real TFTD   }
{  mods against what the real OpenXcom (Mod::loadAll) holds                     }
{                                                                              }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomMod.RealMod;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Tests.Xcom.Skip;

type
  [TestFixture]
  [Category('xcom-mod')]
  [Category('xcom-mod-real')]
  TTestXcomModReal = class(TObject)
  public
    /// <summary>
    ///   The rules that the library loads from the mods of OpenXcom (data of the TFTD nightly, not in the
    ///   repository) must be the lines that the real Mod printed (the golden); skipped without the data
    /// </summary>
    [Test]
    [TestCase('xcom2', 'tftd.xcom2.golden.txt')]
    [TestCase('xcom2 con i mod TFTD', 'tftd.mods.golden.txt')]
    [TestCase('xcom1 (UFO)', 'ufo.xcom1.golden.txt')]
    [TestCase('xcom1 con i mod di UFO', 'ufo.mods.golden.txt')]
    procedure DovrebbeDareLeStesseRegoleDelModVero(const AGolden: string);
  end;

implementation

uses
  DelphiDoom.XcomMod.Ruleset, DelphiDoom.Tests.XcomMod.RealData, DelphiDoom.Tests.XcomMod.ModDump;

{ TTestXcomModReal }

procedure TTestXcomModReal.DovrebbeDareLeStesseRegoleDelModVero(const AGolden: string);
var
  LData: TXcomRealData;
  LMod: TXcomRuleset;
  LDump: TXcomModDump;
  LActual, LExpected: TStringList;
  LIndex, LDifferences: Integer;
  LFirst: string;
begin
  LData := TXcomRealData.Create(AGolden);
  try
    if LData.DataFolder = '' then
    begin
      TXcomTestSkip.Ignore('dati del nightly TFTD/UFO non trovati (Reference\_dati\xcom_tftd\openxcom, xcom_ufo\openxcom)');
      Exit;
    end;
    LMod := LData.Load;
    try
      LDump := TXcomModDump.Create(LMod);
      try
        LActual := LDump.Dump;
        LExpected := LData.RuleLines(TXcomModDump.Sections);
        try
          LDifferences := 0;
          LFirst := '';
          for LIndex := 0 to LExpected.Count - 1 do
            if (LIndex >= LActual.Count) or (LExpected[LIndex] <> LActual[LIndex]) then
            begin
              if LFirst = '' then
              begin
                LFirst := Format('riga %d: atteso "%s"', [LIndex + 1, LExpected[LIndex]]);
                if LIndex < LActual.Count then
                  LFirst := LFirst + Format(' ottenuto "%s"', [LActual[LIndex]]);
              end;
              Inc(LDifferences);
            end;
          Assert.AreEqual(0, LDifferences, LFirst);
          Assert.AreEqual(LExpected.Count, LActual.Count, 'numero di righe');
        finally
          LExpected.Free;
        end;
      finally
        LDump.Free;
      end;
    finally
      LMod.Free;
    end;
  finally
    LData.Free;
  end;
end;

end.
