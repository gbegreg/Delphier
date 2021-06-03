{ Développé par Grégory Bersegeay 2021 }
unit uMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, System.StrUtils,
  FMX.Objects, FMX.Layouts, FMX.Ani, FMX.Controls.Presentation, system.Math,
  FMX.StdCtrls, RegularExpressions, System.JSON, System.IOUtils, system.Generics.Collections,
  FMX.Effects, FMX.Filter.Effects, FMX.Utils, uGame, uUtils, FMX.Gestures;

type
  TFormMain = class(TForm)
    layNiveau: TLayout;
    recPlateforme: TRectangle;
    aniPlayer: TBitmapListAnimation;
    GameLoop: TFloatAnimation;
    layInfos: TLayout;
    lblNbPierre: TLabel;
    recDecor: TRectangle;
    recBonus: TRectangle;
    recEnnemi: TRectangle;
    Image2: TImage;
    layVie: TLayout;
    layPierre: TLayout;
    Image3: TImage;
    lblNbVie: TLabel;
    layZoneJeu: TLayout;
    recMessage: TRectangle;
    lblMessage: TLabel;
    btnMessage: TButton;
    joueur: TImage;
    layIHMMobile: TLayout;
    LeftBTN: TRectangle;
    RightBTN: TRectangle;
    JumpBTN: TRectangle;
    back: TRectangle;
    procedure FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure GameLoopProcess(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnMessageClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure RightBTNMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure RightBTNMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure LeftBTNMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure LeftBTNMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure FormTouch(Sender: TObject; const Touches: TTouches;
      const Action: TTouchAction);
  private
    procedure avancer;
    procedure reculer;
    procedure sauter;
    procedure bornerAGauche;
    procedure bornerADroite;
    procedure genererPlateformes(plateforme: string);
    procedure setAnimationPrecedente;
    procedure deplacerScrollings(vitesse: single);
    procedure toucher;
    procedure creerNouvellePartie;
    procedure afficherMessage(msg : string);
    procedure chargerNiveau(nomFichier: string);
    function getPositionJoueur: TPoint;
    procedure initialiserNiveau;
    procedure testerCollisions;
    procedure CreerAnimation(animation: string; parent: TImage; ennemi: boolean = false);
    procedure DeplacerEnnemiFinish(Sender: TObject);
    procedure genererBonus(bonus: string);
    procedure genererDecor(decor: string);
    procedure genererEnnemis(ennemi: string);
    procedure testerFinDeJeu;
    procedure gererTouches;
    procedure orienterSaut;
    procedure initialiserTouches;
    procedure stopperMouvement(droite: boolean);
  public
    vitesseX, vitesseY, gravite, oldPlateformePosX, milieuForm, scale : single;
    direction : TDirection;
    nbBonus, nbVie, nbBonusMax, nbLine, TileSize, nbTilePerLine, playerStartPosX, formHauteur : integer;
    toucheAvancer, toucheReculer, toucheSauter, sautEnCours, enCollisionAvecPlateforme : boolean;
    playerIdle, playerIdleGauche, playerRun, playerRunGauche, playerSauter, playerSauterGauche, tileSet : TBitmap;
    tailleNiveau : extended;
    oldAnimation : TAnimationJoueur;
    listeDecor : TList<TBitmap>;
    listeBonus : TList<TBonus>;
    listeEnnemis : TList<TEnnemi>;
    listePlateforme : TList<TPlateformeInfos>;
    listeScrollings : TList<TScrolling>;
  end;

var
  FormMain: TFormMain;

implementation
{$R *.fmx}

procedure TFormMain.GameLoopProcess(Sender: TObject); // Boucle principale du jeu
begin
  lblNbVie.text := 'x ' + nbVie.ToString;
  lblNbPierre.Text := nbBonus.ToString + '/' + nbBonusMax.ToString ;

  vitesseY := vitesseY + gravite; // on ajoute la gravité à la vitesse verticale
  joueur.Position.Y := joueur.Position.Y + vitesseY; // nouvelle position du joueur sur axe Y

  gererTouches; // gestion des touches
  testerFinDeJeu;   // Test si situation de fin de jeu (perdu ou gagné)
  testerCollisions; // Gestion des collisions

  if layNiveau.Position.X >= 0 then begin // Si on est au début du niveau
    bornerAGauche;                        // borner le joueur de la gauche au centre de la fenêtre
    exit;
  end;

  if layNiveau.Position.X <= -(tailleNiveau) then begin // Si on est à la fin du niveau
    bornerADroite;                        // borner le joueur du centre à la droite de la fenêtre
    exit;
  end;

  deplacerScrollings(vitesseX); // gestion défilement des plans de scrolling
end;

procedure TFormMain.gererTouches;
begin
  if toucheAvancer then avancer;
  if toucheReculer then reculer;
  if toucheSauter then sauter;
end;

procedure TFormMain.testerFinDeJeu;
begin
  if nbVie = 0 then begin   // Si plus de vie, on perd...
    afficherMessage('Vous avez perdu...');
    GameLoop.StopAtCurrent;
  end;
  if nbBonus = nbBonusMax then begin // Si le joueur a récupéré tous les bonus, on gagne...
    afficherMessage('Félicitations !!! ' + sLineBreak+ 'Vous avez trouvé tous les diamants !');
    GameLoop.StopAtCurrent;
  end;
  if joueur.Position.Y > formMain.ClientHeight then toucher; // Si le joueur tombe et sort de l'écran, on considère qu'il est touché
end;

procedure TFormMain.testerCollisions;
begin
  var position := getPositionJoueur; // Récupération de la position du joueur (sa position en X par rapport à la fenêtre mais aussi par rapport à la position du niveau)
  if joueur.Position.Y <= (joueur.Position.Y + vitesseY) then begin // on ne teste les collisions avec les plateformes que lorsque la joueur est en train de descendre sur l'axe Y
    var resultat := gererCollisionsPlateformes(position, joueur, recPlateforme);
    enCollisionAvecPlateforme := resultat.enCollision;
    if enCollisionAvecPlateforme then begin // En cas de collision avec une plateforme
      setAnimationPrecedente; // Permet de stopper l'éventuel saut et de remettre l'animation du joueur à sa valeur d'avant saut
      sautEnCours := false;
      joueur.Position.Y := resultat.objet.Position.Y - joueur.Height; // On place le joueur sur la plateforme
      if resultat.objet.ChildrenCount = 1 then begin // Si la plateforme possède un enfant, il s'agit de son animation
         if (resultat.objet.Children[0] as TFloatAnimation).PropertyName.ToLower = 'position.x'  then begin // si la plateforme est animée sur l'axe X, il faut déplacer le joueur du déplacement de la plateforme
           if oldPlateformePosX = 0 then oldPlateformePosX := resultat.objet.Position.X;
           deplacerScrollings(oldPlateformePosX - resultat.objet.Position.X);
           oldPlateformePosX := resultat.objet.Position.X;
         end;
      end;
      vitesseY := 0; // On bloque la vitesse sur l'axe Y en cas de collision avec une plateforme
    end;
  end else enCollisionAvecPlateforme := false;
  if not(enCollisionAvecPlateforme) then oldPlateformePosX := 0;

  if gererCollisions(position, joueur, recBonus, true).enCollision then inc(nbBonus); // test collision du joueur avec un bonus
  if gererCollisions(position, joueur, recEnnemi, false).enCollision then toucher; // test collision du joueur avec un ennemi
end;

procedure TFormMain.deplacerScrollings(vitesse: single);
begin
  for var scrolling in listeScrollings do begin // Pour chaque plan de scrolling
    scrolling.position.X := scrolling.position.X + (vitesse * scrolling.vitesse); // On le déplace en fonction de sa vitesse
    if direction = TDirection.droite then begin
      if scrolling.position.X <= - scrolling.Rectangle.Fill.Bitmap.Bitmap.Width then scrolling.position.X := 0;
    end else begin
      if scrolling.position.X >= 0 then scrolling.position.X := - scrolling.Rectangle.Fill.Bitmap.Bitmap.Width;
    end;
  end;
  layNiveau.Position.X := layNiveau.Position.X + vitesse; // déplacement du niveau
end;

procedure TFormMain.FormCreate(Sender: TObject); // Toutes les initialisations au démarrage de l'appli
begin
  listeDecor := TList<TBitmap>.create;
  listeBonus := TList<TBonus>.create;
  listeEnnemis := TList<TEnnemi>.create;
  listePlateforme := TList<TPlateformeInfos>.create;
  listeScrollings := TList<TScrolling>.create;
  vitesseY := 0;
  vitesseX := 0;
  layIHMMobile.Visible := false;
  scale := 2; // Zoom de la zone de jeu
  {$IFDEF ANDROID}
    layIHMMobile.Visible := true;
    FullScreen := true;
    scale := 1.2;
  {$ENDIF ANDROID}
  layZoneJeu.Scale.X := scale;
  layZoneJeu.Scale.Y := scale;
  formMain.ClientWidth := round(formWidth * scale);
  formMain.ClientHeight := round(formHeight * scale);
  formHauteur := formMain.ClientHeight;
  milieuForm := (formMain.ClientWidth * 0.5 / scale) - joueur.width;
  playerIdle := TBitmap.Create;
  playerIdleGauche := TBitmap.Create;
  playerRun := TBitmap.Create;
  playerRunGauche := TBitmap.Create;
  playerSauter := TBitmap.Create;
  playerSauterGauche := TBitmap.Create;
  tileSet := TBitmap.Create;
  creerNouvellePartie;
end;

procedure TFormMain.creerNouvellePartie; // Lancement d'une nouvelle partie
begin
  chargerNiveau(TPath.Combine(GetAppResourcesPath, 'niveau1.json')); // Lecture du fichier json et génération du niveau
  nbBonus := 0;
  nbVie := 3;
  initialiserTouches;
  layZoneJeu.Visible := true;
  recMessage.Visible := false;
  joueur.Visible := true;
  aniPlayer.AnimationBitmap := playerIdle;
  aniPlayer.AnimationCount := 9;
  aniPlayer.Start;
  oldAnimation := TAnimationJoueur.idleDroite;
  GameLoop.Start;
end;

procedure TFormMain.FormDestroy(Sender: TObject); // Fermeture de l'appli, on libère les ressources
begin
  listeDecor.Free;
  listeBonus.Free;
  listeEnnemis.Free;
  listePlateforme.Free;
  listeScrollings.Free;
  playerIdle.Free;
  playerIdleGauche.Free;
  playerRun.Free;
  playerRunGauche.Free;
  playerSauter.Free;
  playerSauterGauche.Free;
  tileSet.Free;
end;

procedure TFormMain.FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState); // Se déclenche lors de l'appui sur une touche du clavier
begin
  if (keyChar = 'D') or (keyChar = 'd') or (key = 39) then begin
    toucheAvancer := true;
    toucheReculer := false;
  end;
  if (keyChar = 'Q') or (keyChar = 'q') or (keyChar = 'A') or (keyChar = 'a') or (key = 37) then begin
    toucheAvancer := false;
    toucheReculer := true; // Q pour clavier AZERTY, A pour clavier QWERTY
  end;
  if (keyChar = ' ') or (key = 38) or (KeyChar = 'Z') or (KeyChar = 'z') or (KeyChar = 'W') or (KeyChar = 'w') then toucheSauter := true; // W pour les claviers QWERTY
end;

procedure TFormMain.FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState); // Se déclenche lorsque l'on relache une touche du clavier
begin
  if (keyChar = 'D') or (keyChar = 'd') or (key = 39) then stopperMouvement(true);
  if (keyChar = 'Q') or (keyChar = 'q') or (keyChar = 'A') or (keyChar = 'a') or (key = 37) then stopperMouvement(false);
  if (keyChar = ' ') or (key = 38) or (KeyChar = 'Z') or (KeyChar = 'z') or (KeyChar = 'W') or (KeyChar = 'w') then toucheSauter := false;
end;

procedure TFormMain.FormResize(Sender: TObject);
begin
  milieuForm := (formMain.ClientWidth * 0.5 / scale) - joueur.width;
  for var scrolling in listeScrollings do
    Scrolling.rectangle.Width := Scrolling.rectangle.Fill.Bitmap.Bitmap.width * ((formMain.ClientWidth / Scrolling.rectangle.Fill.Bitmap.Bitmap.width) + 1);
end;

procedure TFormMain.FormTouch(Sender: TObject; const Touches: TTouches; const Action: TTouchAction);
begin
  if layIHMMobile.Visible then begin // A faire que si l'IHM dédiée au mobile est visible
    for var iTouch : TTouch in Touches do begin
      if not(sautEnCours) then begin // On saute si on n'est pas déjà en saut
        if (iTouch.Location.X >= JumpBTN.Position.X) and   // Si l'utilisateur appuie sur le bouton de saut
           (iTouch.Location.X <= (JumpBTN.Position.X + JumpBTN.Width)) and
           (iTouch.Location.Y >= JumpBTN.Position.Y + layIHMMobile.Position.Y) and
           (iTouch.Location.Y <= (JumpBTN.Position.Y + JumpBTN.height) + layIHMMobile.Position.y + layIHMMobile.Height) then
           toucheSauter := true;
      end else toucheSauter := false;
    end;
  end;
end;

procedure TFormMain.bornerAGauche;
begin
  if (joueur.Position.X >= 0) then begin
    joueur.Position.X := joueur.Position.X - vitesseX;
    if joueur.Position.X >= milieuForm then layNiveau.Position.X := -1;
  end else joueur.Position.X := 0;
end;

procedure TFormMain.bornerADroite;
begin
  if joueur.Position.X <= (formMain.ClientWidth / scale) - joueur.Width then begin
    joueur.Position.X := joueur.Position.X - vitesseX;
    if joueur.Position.X <= milieuForm then layNiveau.Position.X := - (tailleNiveau) + 1;
  end else joueur.Position.X := (formMain.ClientWidth / scale) - joueur.Width;
end;

procedure TFormMain.setAnimationPrecedente;
begin
  case oldAnimation of
    TAnimationJoueur.courtDroite: begin
                                    aniPlayer.AnimationBitmap := playerRun;
                                    aniPlayer.AnimationCount := 8;
                                  end;
    TAnimationJoueur.courtGauche: begin
                                    aniPlayer.AnimationBitmap := playerRunGauche;
                                    aniPlayer.AnimationCount := 8;
                                  end;
    TAnimationJoueur.idleDroite: begin
                                   aniPlayer.AnimationBitmap := playerIdle;
                                   aniPlayer.AnimationCount := 9;
                                 end;
    TAnimationJoueur.idleGauche: begin
                                   aniPlayer.AnimationBitmap := playerIdleGauche;
                                   aniPlayer.AnimationCount := 9;
                                 end;
  end;
end;

procedure TFormMain.avancer;
begin
  vitesseX := -vitesseXMax;
  direction := TDirection.droite;
  if not(sautEnCours) then begin
    oldAnimation := TAnimationJoueur.courtDroite;
    aniPlayer.AnimationBitmap := playerRun;
    aniPlayer.AnimationCount := 8;
  end else orienterSaut;
end;

procedure TFormMain.btnMessageClick(Sender: TObject);
begin
  creerNouvellePartie;
end;

procedure TFormMain.reculer;
begin
  vitesseX := vitesseXMax;
  direction := TDirection.gauche;
  if not(sautEnCours) then begin
    oldAnimation := TAnimationJoueur.courtGauche;
    aniPlayer.AnimationBitmap := playerRunGauche;
    aniPlayer.AnimationCount := 8;
  end else orienterSaut;
end;

procedure TFormMain.RightBTNMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  toucheAvancer := true;
  toucheReculer := false;
end;

procedure TFormMain.RightBTNMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  stopperMouvement(true);
end;

procedure TFormMain.orienterSaut;
begin
  if sautEnCours then begin
    if direction = TDirection.droite then aniPlayer.AnimationBitmap := playerSauter
    else aniPlayer.AnimationBitmap := playerSauterGauche;
    aniPlayer.AnimationCount := 1;
  end;
end;

procedure TFormMain.toucher;
begin
  initialiserNiveau;
  dec(nbVie);
end;

procedure TFormMain.sauter;
begin
  if enCollisionAvecPlateforme then begin
    sautEnCours := true;
    orienterSaut;
    vitesseY := - puissanceSaut;
  end;
end;

function TFormMain.getPositionJoueur:TPoint;
begin
  result.X := Round(joueur.Position.X + abs(layNiveau.Position.X));
  result.Y := Round(joueur.Position.Y);
end;

procedure TFormMain.afficherMessage(msg: string);
begin
  joueur.Visible := false;
  lblMessage.Text := msg;
  recMessage.Visible := true;
end;

procedure TFormMain.chargerNiveau(nomFichier: string);
begin
  if fileexists(nomfichier) then begin
    // Initialisation des "conteneurs"
    recBonus.DeleteChildren;
    recEnnemi.DeleteChildren;
    recPlateforme.DeleteChildren;
    listeBonus.Clear;
    listeEnnemis.Clear;
    listePlateforme.Clear;
    listeScrollings.Clear;
    listeDecor.Clear;

    // Lecture du fichier JSON de description du niveau
    var JSONValue := TJSONObject.ParseJSONValue(TFile.ReadAllText(nomFichier));
    try
      if JsonValue <> nil then begin
        if JSONVAlue is TJSONObject then begin
          var nbCol := JSONValue.GetValue<integer>('width'); // Lecture des infos générales du niveau
          TileSize := JSONValue.GetValue<integer>('tileSize');
          tailleNiveau := TileSize * nbCol;
          chargerImage(tileSet, TPath.Combine(GetAppResourcesPath, JSONValue.GetValue<string>('tileImage')));
          nbTilePerLine := Round(tileSet.width / tileSize);
          gravite := JSONValue.GetValue<single>('gravity');
          playerStartPosX := JSONValue.GetValue<integer>('playerStartPosX');
          var decor := JSONValue.GetValue<string>('niveau.decor');
          var plateformes := JSONValue.GetValue<string>('niveau.plateformes');
          var bonus := JSONValue.GetValue<string>('niveau.bonus');
          var ennemis := JSONValue.GetValue<string>('niveau.ennemis');
          chargerImage(playerIdle, TPath.Combine(GetAppResourcesPath, JSONValue.GetValue<string>('player-idle')));
          chargerImage(playerIdleGauche, TPath.Combine(GetAppResourcesPath, JSONValue.GetValue<string>('player-idle-left')));
          chargerImage(playerRun, TPath.Combine(GetAppResourcesPath, JSONValue.GetValue<string>('player-run')));
          chargerImage(playerRunGauche, TPath.Combine(GetAppResourcesPath, JSONValue.GetValue<string>('player-run-left')));
          chargerImage(playerSauter, TPath.Combine(GetAppResourcesPath, JSONValue.GetValue<string>('player-jump')));
          chargerImage(playerSauterGauche, TPath.Combine(GetAppResourcesPath, JSONValue.GetValue<string>('player-jump-left')));

          var scrollingArr := JSONValue.GetValue<TJSONArray>('scrollings');
          for var I := 0 to scrollingArr.Count-1 do begin  // Lecture des scrollings
             var unScrolling := TScrolling.Create(nil);
             unScrolling.Parent := layZoneJeu;
             unScrolling.Position.Y := scrollingArr[i].GetValue<integer>('posY');
             chargerImage(unScrolling.rectangle.Fill.Bitmap.Bitmap, TPath.Combine(GetAppResourcesPath, scrollingArr[i].GetValue<string>('image')));
             unScrolling.rectangle.Width := unScrolling.rectangle.Fill.Bitmap.Bitmap.width * ((formMain.ClientWidth / unScrolling.rectangle.Fill.Bitmap.Bitmap.width) + 1);
             unScrolling.rectangle.Height := unScrolling.rectangle.Fill.Bitmap.Bitmap.Height;
             unScrolling.Height := unScrolling.rectangle.Fill.Bitmap.Bitmap.Height;
             unScrolling.vitesse := scrollingArr[i].GetValue<single>('vitesse');
             listeScrollings.Add(unScrolling);
          end;

          layNiveau.BringToFront; // On replace le conteneur du niveau, le joueur et le conteneur des infos au premier plan
          joueur.BringToFront;
          layInfos.BringToFront;

          var decorArr := JSONValue.GetValue<TJSONArray>('decorElement');
          for var I := 0 to decorArr.Count-1 do begin // Lecture des éléments de décor
             listeDecor.Add(TBitmap.CreateFromFile(TPath.Combine(GetAppResourcesPath, decorArr[i].GetValue<string>('image'))));
          end;

          var plateformesArr := JSONValue.GetValue<TJSONArray>('plateformElement');
          for var i := 0 to plateformesArr.Count-1 do begin // Lecture des éléments de plateforme
            var unePlateforme: TPlateformeInfos;
            unePlateforme.image := plateformesArr.Items[i].GetValue<string>('image');
            unePlateforme.animation := plateformesArr.Items[i].GetValue<string>('animation').ToLower;
            listePlateforme.Add(unePlateforme);
          end;

          var bonusArr := JSONValue.GetValue<TJSONArray>('bonusElement');
          for var I := 0 to bonusArr.Count-1 do begin // Lecture des éléments bonus
            var unBonus : TBonus;
            unBonus.image := TPath.Combine(GetAppResourcesPath, bonusArr[i].GetValue<string>('image'));
            unBonus.count := bonusArr[i].GetValue<integer>('count');
            unBonus.duration := bonusArr[i].GetValue<single>('duration');
            listeBonus.Add(unBonus);
          end;

          var ennemiArr := JSONValue.GetValue<TJSONArray>('ennemiElement');
          for var I := 0 to ennemiArr.Count-1 do begin // Lecture des éléments ennemis
            var unEnnemi : TEnnemi;
            unEnnemi.image1 := TPath.Combine(GetAppResourcesPath, ennemiArr[i].GetValue<string>('image1'));
            unEnnemi.image2 := TPath.Combine(GetAppResourcesPath, ennemiArr[i].GetValue<string>('image2'));
            unEnnemi.count := ennemiArr[i].GetValue<integer>('count');
            unEnnemi.duration := ennemiArr[i].GetValue<single>('duration');
            unEnnemi.deplacement := ennemiArr[i].GetValue<string>('deplacement');
            listeEnnemis.Add(unEnnemi);
          end;

          // Génération du niveau
          genererDecor(decor);
          genererPlateformes(plateformes);
          genererBonus(bonus);
          genererEnnemis(ennemis);
          initialiserNiveau;
        end;
      end;
    finally
      JSONValue.Free;
    end;
  end else begin
    showmessage('Erreur au chargement du fichier "'+nomFichier+'".');
    halt;
  end;
end;

procedure TFormMain.genererDecor(decor : string); // Création du décor en fonction des infos lues dans le fichier json
begin
  var tabDecor := TRegEx.Split(decor, ';');

  for var I := 0 to length(tabDecor) -1 do begin
    var infoDecor := TRegEx.Split(tabDecor[i], ':');
    var rec := TImage.Create(nil);
    rec.Name := 'decor' + i.ToString;
    rec.Parent := recDecor;
    rec.Bitmap := listeDecor[StrToIntDef(infoDecor[0],0)];
    rec.Width := rec.Bitmap.Width;
    rec.Height := rec.Bitmap.Height;
    rec.Position.X := StrToIntDef(infoDecor[2],0) * TileSize ;
    rec.Position.Y := StrToIntDef(infoDecor[1],0) * TileSize  - rec.Height;
  end;
end;

procedure TFormMain.genererPlateformes(plateforme : string);
begin
  var tabPlateforme := TRegEx.Split(plateforme, ';');

  for var I := 0 to length(tabPlateforme) -1 do begin
    var infoPlateforme := TRegEx.Split(tabPlateforme[i], ':');
    var rec := TImage.Create(nil);
    rec.Name := 'plateforme' + i.ToString;
    rec.Parent := recPlateforme;
    var unePlateforme : TPlateformeInfos := listePlateforme[strtointdef(infoPlateforme[0],0)];
    var image := unePlateforme.image;
    var tabImage := TregEx.Split(image, ':');
    var bmp := TBitmap.Create;
    bmp.Width := length(tabImage) * TileSize;
    bmp.Height := TileSize;

    for var j := 0 to Length(tabImage) -1 do begin
      bmp.CopyFromBitmap(getTileImage(strtointdef(tabImage[j],0),tileSize, nbTilePerLine, tileSet), Rect(0,0, TileSize, tileSize), tilesize * j, 0);
    end;

    rec.Bitmap := bmp;
    rec.Width := rec.Bitmap.Width;
    rec.Height := rec.Bitmap.Height;
    rec.Position.X := StrToIntDef(infoPlateforme[2],0) * TileSize;
    rec.Position.Y := StrToIntDef(infoPlateforme[1],0) * TileSize - rec.Height;
    var deplacement := listePlateforme[ strtointdef(infoPlateforme[0],0) ].animation;
    CreerAnimation(deplacement, rec);
  end;
end;

procedure TFormMain.genererBonus(bonus : string); // Création des bonus en fonction des infos lues dans le fichier json
begin
  var tabBonus := TRegEx.Split(bonus, ';');
  nbBonusMax := 0;

  for var I := 0 to length(tabBonus) -1 do begin
    var infoBonus := TRegEx.Split(tabBonus[i], ':');
    var rec := TImage.Create(nil);
    rec.Name := 'bonus' + i.ToString;
    rec.Parent := recBonus;
    var animation := TBitmapListAnimation.Create(nil);
    animation.AnimationType := TAnimationType.InOut;
    animation.Interpolation := TInterpolationType.Sinusoidal;
    animation.Parent := rec;
    inc(nbBonusMax);
    chargerImage(animation.AnimationBitmap, listeBonus[StrToIntDef(infoBonus[0],0)].image);
    animation.AnimationCount := listeBonus[StrToIntDef(infoBonus[0],0)].count;
    animation.Loop := true;
    animation.Duration := listeBonus[StrToIntDef(infoBonus[0],0)].duration;
    animation.AutoReverse := true;
    animation.PropertyName := 'bitmap';
    animation.Start;
    rec.Width := rec.Bitmap.Width;
    rec.Height := rec.Bitmap.Height;
    rec.Position.X := StrToIntDef(infoBonus[2],0) * TileSize;
    rec.Position.Y := StrToIntDef(infoBonus[1],0) * TileSize  - rec.Height;
    rec.Visible := true;
  end;
end;

procedure TFormMain.genererEnnemis(ennemi : string); // Création des ennemis en fonction des infos lues dans le fichier json
begin
  var tabEnnemi := TRegEx.Split(ennemi, ';');

  for var I := 0 to length(tabEnnemi) -1 do begin
    var infoEnnemi := TRegEx.Split(tabEnnemi[i], ':');
    var rec := TImage.Create(nil);
    rec.Name := 'ennemi' + i.ToString;
    rec.Parent := recEnnemi;
    var animation := TBitmapListAnimation.Create(nil); // Animation du sprite
    animation.Parent := rec;
    chargerImage(animation.AnimationBitmap, listeEnnemis[StrToIntDef(infoEnnemi[0],0)].image1);
    animation.AnimationCount := listeEnnemis[StrToIntDef(infoEnnemi[0],0)].count;
    animation.Loop := true;
    animation.Duration := listeEnnemis[StrToIntDef(infoEnnemi[0],0)].duration;
    animation.AutoReverse := false;
    animation.AnimationType := TAnimationType.InOut;
    animation.PropertyName := 'bitmap';
    animation.Interpolation := TInterpolationType.Linear;
    animation.Start;
    rec.tagString := listeEnnemis[StrToIntDef(infoEnnemi[0],0)].image1+';'+listeEnnemis[StrToIntDef(infoEnnemi[0],0)].image2;
    rec.Width := rec.Bitmap.Width;
    rec.Height := rec.Bitmap.Height;
    rec.Position.X := StrToIntDef(infoEnnemi[2],0) * TileSize;
    rec.Position.Y := StrToIntDef(infoEnnemi[1],0) * TileSize  - rec.Height;
    var deplacement := listeEnnemis[strtointdef(infoEnnemi[0],0)].deplacement;
    CreerAnimation(deplacement, rec, true); // création d'une éventuelle aniamtion pour gérer le déplacement de l'ennemi
  end;
end;

procedure TFormMain.initialiserNiveau;
begin
  joueur.Position.X := playerStartPosX;
  joueur.Position.Y := 0;
  vitesseX := 0;
  initialiserTouches;
  oldAnimation := TAnimationJoueur.idleDroite;
  layNiveau.Position.X := 0;
  for var scrolling in listeScrollings do scrolling.position.X := 0;
  direction := TDirection.droite;
end;

procedure TFormMain.CreerAnimation(animation : string; parent : TImage; ennemi : boolean = false);
begin
  var tabAnimation := TRegEx.Split(animation, ':');
  if tabAnimation[0].ToLower <> 'none' then begin // Création de l'animation si elle est définie dans le fichier json
    var floatAni : TFloatAnimation := TFloatAnimation.Create(nil);
    floatAni.Parent := parent;
    floatAni.Loop := tabAnimation[5].toLower = 'loop';
    floatAni.AutoReverse := tabAnimation[6].toLower = 'autoreverse';
    floatAni.Interpolation := getInterpolation(tabAnimation[3].ToLower);
    floatAni.AnimationType := getAnimationType(tabAnimation[4].ToLower);
    floatAni.Duration := strtointdef(tabAnimation[1],5);

    if tabAnimation[0].ToLower = 'x' then begin
      floatAni.PropertyName := 'position.X';
      floatAni.StartValue := parent.Position.X;
      floatAni.StopValue := parent.Position.X + strtointdef(tabAnimation[2],0) * TileSize;
    end;
    if tabAnimation[0].ToLower = 'y' then begin
      floatAni.PropertyName := 'position.Y';
      floatAni.StartValue := parent.Position.Y;
      floatAni.StopValue := parent.Position.Y + strtointdef(tabAnimation[2],0) * TileSize;
    end;
    if tabAnimation[0].ToLower = 'o' then begin
      floatAni.PropertyName := 'opacity';
      floatAni.StartValue := 0;
      floatAni.StopValue := strtointdef(tabAnimation[2],0);
    end;

    if ennemi then floatAni.OnFinish := DeplacerEnnemiFinish; // Si l'animation concerne un ennemi
    floatAni.Start;
  end;
end;

procedure TFormMain.DeplacerEnnemiFinish(Sender: TObject); // A la fin de l'animation d'un ennemi,
begin
  with ((sender as TFloatAnimation).Parent as TImage) do begin
    var indice := ifthen(tag = 0, 1, 0);
    chargerImage((Children[0] as TBitmapListAnimation).AnimationBitmap, tagString.split([';'])[indice]); // On charge l'autre image de l'ennemi
    tag := indice;
  end;
  (sender as TFloatAnimation).Inverse := not((sender as TFloatAnimation).Inverse); // on inverse l'animation
  (sender as TFloatAnimation).Start;  // et on relance l'animation
end;

procedure TFormMain.initialiserTouches;
begin
  toucheAvancer := false;
  toucheReculer := false;
  toucheSauter := false;
  sautEnCours := false;
end;

procedure TFormMain.LeftBTNMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  toucheAvancer := false;
  toucheReculer := true;
end;

procedure TFormMain.LeftBTNMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  stopperMouvement(false);
end;

procedure TFormMain.stopperMouvement(droite: boolean);
begin
  vitesseX := 0;
  if droite then begin
    oldAnimation := TAnimationJoueur.idleDroite;
    toucheAvancer := false;
  end else begin
    oldAnimation := TAnimationJoueur.idleGauche;
    toucheReculer := false;
  end;
end;

end.
