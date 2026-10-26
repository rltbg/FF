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

/// Les seules fonctions que l'hôte connaît du cœur F*.
type CoreApi =
  { Init: obj
    Update: obj -> obj -> obj
    View: obj -> Node
    MsgOfInput: obj -> string -> obj }
