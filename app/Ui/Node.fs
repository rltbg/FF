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
  /// Grande liste : les lignes sont demandées une à une à F* (source `src`, voir CoreApi.BigItem) ;
  /// le modèle F* ne connaît que le nombre de lignes et la sélection (-1 = aucune).
  | BigList of src: uint32 * rows: uint32 * selected: int64
  /// Texte volumineux affiché en lignes virtualisées (source `src`) avec un bouton qui demande à F* de le hacher.
  | BigText of src: uint32 * lines: uint32

/// Les seules fonctions que l'hôte connaît du cœur F*.
type CoreApi =
  { Init: obj
    Update: obj -> obj -> obj
    View: obj -> Node
    MsgOfInput: obj -> string -> obj
    /// ligne choisie dans une BigList
    MsgOfSelect: uint32 -> obj
    /// demande de hachage du texte d'une source (F* génère lui-même ce texte)
    MsgOfHash: uint32 -> obj
    /// ligne i de la source (Big.item) et indice d'une ligne (Big.index_of, -1 si inconnue) : calculées par F*
    BigItem: uint32 -> int -> string
    BigIndex: uint32 -> string -> int }
