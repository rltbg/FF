namespace Ui

/// Description d'interface indépendante de F* et d'Avalonia. Les msg et tags sont opaques (obj).
type Node =
  | Column of Node list
  | Row of Node list
  | Heading of string
  | Text of string
  | Button of label: string * msg: obj
  | Input of tag: obj * value: string * hint: string
  | Check of label: string * isChecked: bool * msg: obj
  /// Grande liste dont les lignes vivent côté hôte (générées à la demande) ; F* ne connaît que le nombre de
  /// lignes et la sélection (-1 = aucune).
  | BigList of rows: uint32 * selected: int64
  /// Texte volumineux côté hôte, identifié par un entier ; l'hôte fournit son contenu à F* sur demande.
  | BigText of id: uint32

/// Les seules fonctions que l'hôte connaît du cœur F*.
type CoreApi =
  { Init: obj
    Update: obj -> obj -> obj
    View: obj -> Node
    MsgOfInput: obj -> string -> obj
    /// ligne choisie dans une BigList
    MsgOfSelect: uint32 -> obj
    /// contenu d'un BigText (fourni par l'hôte)
    MsgOfText: uint32 -> string -> obj }

/// Données volumineuses, côté hôte uniquement (jamais dans le modèle F*).
module BigData =
  /// Ligne i de la grande liste, calculée à la demande (rien n'est stocké pour les 100 000 lignes).
  let row (i: int) : string = "Ligne " + i.ToString("D6") + " — donnée côté hôte"

  /// Texte d'environ 1 Mo (1 022 080 octets UTF-8, 832 080 unités UTF-16), déterministe : 38 000 lignes.
  let textLines = 38000
  /// Ligne i du texte, calculée à la demande (le visualiseur n'a besoin que des lignes affichées).
  let line (i: int) : string = "Texte " + i.ToString("D6") + " — éàü " + string (i % 97)
  /// Le texte complet n'est construit que si F* doit le hacher.
  let text : Lazy<string> =
    lazy (
      let sb = System.Text.StringBuilder(textLines * 28)
      for i in 0 .. textLines - 1 do sb.Append(line i).Append('\n') |> ignore
      sb.ToString())
