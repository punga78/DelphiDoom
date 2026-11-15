@{
  # Gli scenari di Confronta-Scenari-Virgola.ps1: la stessa mappa e lo stesso giro con chiavi del .ini diverse.
  #   Ini: righe chiave=valore in piu' (si aggiungono a quelle fisse di Parity-Common.ps1: finestra 640x480, niente
  #        fili, interpolazione spenta); Pk3: carica anche Tests\Data\Pk3\zpktest.pk3 (voxel di prova)
  # Le pendenze e il pavimento 3D sono nella mappa: ci sono in ogni scenario. zaxisshift=1 serve a guardare in su e in
  # giu' (look del copione); usefake3d=1 accende la correzione di prospettiva (r_fake3d) che lo sguardo richiede.
  Scenarios = @(
    @{ Name = 'base'; Ini = @('zaxisshift=0'); Pk3 = $false }
    @{ Name = 'zaxis'; Ini = @('zaxisshift=1'); Pk3 = $false }
    @{ Name = 'fake3d'; Ini = @('zaxisshift=1', 'usefake3d=1'); Pk3 = $false }
    @{ Name = 'voxels'; Ini = @('zaxisshift=1', 'r_drawvoxels=1'); Pk3 = $true }
    @{ Name = 'interpolate'; Ini = @('zaxisshift=1', 'interpolate=1'); Pk3 = $false }
    @{ Name = 'tutto'; Ini = @('zaxisshift=1', 'usefake3d=1', 'r_drawvoxels=1', 'interpolate=1'); Pk3 = $true }
  )
}
