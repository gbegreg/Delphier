unit uGame;

interface

uses System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
     FMX.Objects, FMX.Layouts, FMX.Graphics;

type
  TDirection = (droite, gauche);
  TAnimationJoueur = (idleDroite, idleGauche, courtDroite, courtGauche);

  TScrolling = class(TLayout)
  private
    fRectangle: TRectangle;
    fVitesse: single;
  public
    constructor Create(AOwner: TComponent); override;
    property Rectangle: TRectangle read fRectangle write fRectangle;
    property Vitesse: single read fVitesse write fVitesse;
  end;

  TPlateformeInfos = record
  public
    animation, image: string;
  end;

  TEnnemi = record
  public
    image1, image2, deplacement: string;
    count: integer;
    duration: single;
  end;

  TBonus = record
  public
    image: string;
    count: integer;
    duration: single;
  end;

  TCollision = record
  public
    enCollision : boolean;
    objet : TImage;
  end;

  function gererCollisions(position : TPoint; joueur : TImage; unRectangle : TRectangle; detruireObjetTouche: boolean): TCollision;
  function gererCollisionsPlateformes(positionJoueur : TPoint; joueur : TImage; unRectangle : TRectangle): TCollision;
  function gererCollisionsJoueurAvecUnePlateforme(positionJoueur : TPoint; joueur, plateforme : TImage): boolean;

const
  vitesseXMax = 3; // Vitesse de déplacement du joueur
  puissanceSaut = 10; // Force du saut
  formWidth = 480;  // 30 tiles de 16 pixels
  formHeight = 272; // 17 tiles de 16 pixles

implementation

constructor TScrolling.create(AOwner: TComponent);
begin
  inherited;
  fRectangle := TRectangle.create(nil);
  fRectangle.Parent := self;
  fRectangle.HitTest := false;
  fRectangle.Fill.Kind := TBrushKind.Bitmap;
  fRectangle.Fill.Bitmap.WrapMode := TWrapMode.Tile;
  fRectangle.stroke.Dash := TStrokeDash.Solid;
  fRectangle.stroke.Color := TAlphaColorRec.Null;
  fRectangle.stroke.Kind := TBrushKind.Solid;
  fRectangle.stroke.Thickness := 1;
  fVitesse := 0;
end;

function gererCollisions(position : TPoint; joueur : TImage; unRectangle : TRectangle; detruireObjetTouche: boolean):TCollision;
begin
  var enCollision := false;
  for var recChild in unRectangle.Children do begin
    var unEnfant : TImage := recChild as TImage;
    if (position.X > unEnfant.Position.X) and (position.X < unEnfant.Position.X + unEnfant.Width) and
       (position.y + joueur.Height > unEnfant.Position.Y) and (position.y < unEnfant.Position.Y + unEnfant.Height) then begin
         enCollision := true;
         result.objet := unEnfant;
         if detruireObjetTouche then unEnfant.free;
         break;
    end;
  end;
  result.enCollision := enCollision;
end;

function gererCollisionsPlateformes(positionJoueur : TPoint; joueur: TImage; unRectangle : TRectangle):TCollision;
begin
  result.enCollision := false;
  for var recChild in unRectangle.Children do begin
    var unEnfant : TImage := recChild as TImage;
    if gererCollisionsJoueurAvecUnePlateforme(positionJoueur, joueur, unEnfant) then begin
       result.enCollision := true;
       result.objet := unEnfant;
       break;
    end;
  end;
end;

function gererCollisionsJoueurAvecUnePlateforme(positionJoueur : TPoint; joueur, plateforme : TImage): boolean;
begin
  Result := ((positionJoueur.X + joueur.Width * 0.75) > plateforme.Position.x) and
            ((positionJoueur.X + joueur.Width * 0.25)< plateforme.Position.X + plateforme.width) and
            (positionJoueur.Y + joueur.Height > plateforme.Position.Y) and
            (positionJoueur.Y < plateforme.Position.Y) and
            (plateforme.Opacity > 0.3);
end;

end.
