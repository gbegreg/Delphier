unit uUtils;

interface
uses FMX.Graphics, System.UITypes, System.SysUtils, System.types, FMX.types, System.IOUtils;

  function getTileImage(indiceTile, tilesize, nbTilePerLine : integer; tileset : TBitmap):TBitmap;
  function cropImage(originBitmap : TBitmap; Xpos, Ypos, width, height: integer): TBitmap;
  function getInterpolation(nomInterpollation: string) : TInterpolationType;
  function getAnimationType(typeAnimation: string): TAnimationType;
  procedure chargerImage(uneImage : TBitmap; fichier : string);
  function GetAppResourcesPath:string;

implementation

function getTileImage(indiceTile, tilesize, nbTilePerLine : integer; tileset : TBitmap):TBitmap;
begin
  var imgTile := TBitmap.Create;
  imgTile.Width := TileSize;
  imgTile.Height := TileSize;
  var lg := indiceTile div nbTilePerLine;
  var col := indiceTile mod nbTilePerLine -1;
  imgTile := cropImage(tileset,col * tileSize, lg * tilesize, tilesize, tilesize);
  result := imgTile;
end;

function cropImage(originBitmap : TBitmap; Xpos, Ypos, width, height: integer): TBitmap;
begin
  result := TBitmap.Create;
  result.Width := Width;
  result.Height := Height;
  result.CopyFromBitmap(originBitmap, TRect.Create(Xpos, Ypos, Xpos + Width, Ypos + Height), 0, 0);
end;

procedure chargerImage(uneImage : TBitmap; fichier : string);
begin
  if fileExists(fichier) then uneImage.LoadFromFile(fichier);
end;

function getInterpolation(nomInterpollation: string): TInterpolationType;
begin
  result := TInterpolationType.Linear;
  if nomInterpollation = 'sinusoidal' then result := TInterpolationType.Sinusoidal;
  if nomInterpollation = 'quadratic' then result := TInterpolationType.Quadratic;
  if nomInterpollation = 'cubic' then result := TInterpolationType.Cubic;
  if nomInterpollation = 'quartic' then result := TInterpolationType.Quartic;
  if nomInterpollation = 'quintic' then result := TInterpolationType.Quintic;
  if nomInterpollation = 'exponential' then result := TInterpolationType.Exponential;
  if nomInterpollation = 'circular' then result := TInterpolationType.Circular;
  if nomInterpollation = 'elastic' then result := TInterpolationType.Elastic;
  if nomInterpollation = 'back' then result := TInterpolationType.Back;
  if nomInterpollation = 'bounce' then result := TInterpolationType.Bounce;
end;

function getAnimationType(typeAnimation: string): TAnimationType;
begin
  result := TAnimationType.In;
  if typeAnimation = 'out' then result := TAnimationType.Out;
  if typeAnimation = 'inout' then result := TAnimationType.InOut;
end;

function GetAppResourcesPath:string;
{$IFDEF MSWINDOWS}
  begin
    result := TPath.GetDirectoryName(ParamStr(0));
  end;
{$ENDIF MSWINDOWS}
{$IFDEF MACOS}
  begin
    result := TPath.GetHomePath;
  end;
{$ENDIF MACOS}
{$IFDEF LINUX}
  begin
    result := TPath.GetDirectoryName(ParamStr(0));
  end;
{$ENDIF LINUX}
{$IFDEF ANDROID}
  begin
    result := TPath.GetDocumentsPath;
  end;
{$ENDIF ANDROID}

end.
