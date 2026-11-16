{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the renderer library - the profiles of the games       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Renderer.Profiles;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Renderer.Types;

type
  [TestFixture]
  [Category('renderer')]
  TTestRendererProfiles = class(TObject)
  public
    [Test]
    procedure DovrebbeDareLAltezzaDelCieloDiOgniGioco;
    [Test]
    procedure DovrebbeDareLaTexturePerAssenteDiOgniGioco;
    [Test]
    procedure DovrebbeRiconoscereINomiDeiGiochi;
    [Test]
    procedure DovrebbeNonRiconoscereUnNomeSconosciuto;
    /// <summary>
    ///   Parity: the rule of the old R_NameForSideTexture and R_SafeTextureNumForName, that had
    ///   the {$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}, for every game and number
    /// </summary>
    [Test]
    procedure DovrebbeFareComeIlVecchioTestoDelleTextureDeiLati;
  end;

implementation

uses
  DelphiDoom.Renderer.Profiles;

const
  FRACUNIT = 65536;

{ TTestRendererProfiles }

procedure TTestRendererProfiles.DovrebbeDareLAltezzaDelCieloDiOgniGioco;
begin
  Assert.AreEqual(100 * FRACUNIT, TRendererProfiles.ForGame(TRendererGame.Doom).SkyTextureMid);
  Assert.AreEqual(100 * FRACUNIT, TRendererProfiles.ForGame(TRendererGame.Heretic).SkyTextureMid);
  Assert.AreEqual(200 * FRACUNIT, TRendererProfiles.ForGame(TRendererGame.Hexen).SkyTextureMid);
  Assert.AreEqual(199 * FRACUNIT, TRendererProfiles.ForGame(TRendererGame.Strife).SkyTextureMid);
end;

procedure TTestRendererProfiles.DovrebbeDareLaTexturePerAssenteDiOgniGioco;
begin
  Assert.AreEqual(0, TRendererProfiles.ForGame(TRendererGame.Doom).MissingTexture);
  Assert.AreEqual(-1, TRendererProfiles.ForGame(TRendererGame.Heretic).MissingTexture);
  Assert.AreEqual(-1, TRendererProfiles.ForGame(TRendererGame.Hexen).MissingTexture);
  Assert.AreEqual(0, TRendererProfiles.ForGame(TRendererGame.Strife).MissingTexture);
  Assert.IsTrue(TRendererProfiles.ForGame(TRendererGame.Doom).DoomLightLevelColumns);
  Assert.IsFalse(TRendererProfiles.ForGame(TRendererGame.Strife).DoomLightLevelColumns);
end;

procedure TTestRendererProfiles.DovrebbeRiconoscereINomiDeiGiochi;
var
  LGame: TRendererGame;
begin
  Assert.IsTrue(TRendererProfiles.TryFromName('hexen', LGame));
  Assert.AreEqual(Ord(TRendererGame.Hexen), Ord(LGame));
  Assert.IsTrue(TRendererProfiles.TryFromName('Doom', LGame));
  Assert.AreEqual('STRIFE', TRendererProfiles.NameOf(TRendererGame.Strife));
end;

procedure TTestRendererProfiles.DovrebbeNonRiconoscereUnNomeSconosciuto;
var
  LGame: TRendererGame;
begin
  Assert.IsFalse(TRendererProfiles.TryFromName('Quake', LGame));
  Assert.IsFalse(TRendererProfiles.TryFromName('', LGame));
end;

procedure TTestRendererProfiles.DovrebbeFareComeIlVecchioTestoDelleTextureDeiLati;
var
  LGame: TRendererGame;
  LProfile: TRendererProfile;
  LNumber: Integer;
  LOldNone: Boolean;
  LOldHeretic: Boolean;
begin
  for LGame := Low(TRendererGame) to High(TRendererGame) do
  begin
    LProfile := TRendererProfiles.ForGame(LGame);
    LOldHeretic := LGame in [TRendererGame.Heretic, TRendererGame.Hexen];
    for LNumber := -5 to 5 do
    begin
      // old: {$IF HERETIC OR HEXEN} if sn < 0 {$ELSE} if sn = 0 {$ENDIF} exit
      if LOldHeretic then
        LOldNone := LNumber < 0
      else
        LOldNone := LNumber = 0;
      Assert.AreEqual(LOldNone, TRendererProfiles.IsNoSideTexture(LProfile, LNumber));
    end;
    // old: custom colormaps only in the games that are not Heretic or Hexen
    Assert.AreEqual(not LOldHeretic, LProfile.CustomColormapsOnSides);
    // old: R_SafeTextureNumForName gave -1 in Heretic and Hexen, 0 otherwise
    if LOldHeretic then
      Assert.AreEqual(-1, LProfile.MissingTexture)
    else
      Assert.AreEqual(0, LProfile.MissingTexture);
  end;
end;

end.
