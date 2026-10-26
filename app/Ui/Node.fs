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
