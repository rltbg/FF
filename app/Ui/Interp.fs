namespace Ui

open Avalonia
open Avalonia.Controls
open Avalonia.Layout
open Avalonia.Media

/// État porté par un TextBox (dans Control.Tag) : le tag F* courant et le dernier texte connu.
type internal InputState = { mutable InputTag: obj; mutable Last: string }

/// Interpréteur Node -> contrôles Avalonia avec réconciliation : à chaque rendu, l'arbre précédent est
/// comparé au nouveau position par position ; un contrôle du même genre est réutilisé et seules ses
/// propriétés changent. Les contrôles restent donc les mêmes objets entre deux rendus : un clic commencé
/// avant un rendu n'est pas perdu et le focus/curseur des TextBox est conservé.
/// Les msg/tags sont lus dans Control.Tag au moment de l'événement (jamais capturés dans une fermeture).
type Interp(dispatch: obj -> unit, onInput: obj -> string -> unit) =
  /// vrai pendant que l'interpréteur modifie lui-même des propriétés : on ignore alors les événements
  let mutable patching = false
  let mutable current : (Node * Control) option = None

  let kind (n: Node) =
    match n with
    | Column _ -> 0 | Row _ -> 1 | Heading _ -> 2 | Text _ -> 3
    | Button _ -> 4 | Input _ -> 5 | Check _ -> 6

  let textOf (tb: TextBox) = if isNull tb.Text then "" else tb.Text

  let rec build (n: Node) : Control =
    match n with
    | Column xs | Row xs ->
      let p = StackPanel(Spacing = 8.0)
      p.Orientation <- (match n with Row _ -> Orientation.Horizontal | _ -> Orientation.Vertical)
      for x in xs do p.Children.Add(build x)
      p :> Control
    | Heading s -> TextBlock(Text = s, FontSize = 22.0, FontWeight = FontWeight.Bold) :> Control
    | Text s -> TextBlock(Text = s, TextWrapping = TextWrapping.Wrap) :> Control
    | Button (label, msg) ->
      let b = Button(Content = label, Tag = msg)
      b.Click.Add(fun _ -> dispatch b.Tag)
      b :> Control
    | Check (label, isChecked, msg) ->
      let c = CheckBox(Content = label, IsChecked = System.Nullable isChecked, Tag = msg)
      c.IsCheckedChanged.Add(fun _ -> if not patching then dispatch c.Tag)
      c :> Control
    | Input (tag, value, hint) ->
      let st = { InputTag = tag; Last = value }
      let tb = TextBox(Width = 220.0, Text = value, PlaceholderText = hint, Tag = st)
      // Notification synchrone de la propriété Text (TextChanged est asynchrone d'après la doc Avalonia,
      // ce qui laissait un rendu s'intercaler entre la frappe et l'événement).
      tb.PropertyChanged.Add(fun e ->
        if e.Property = TextBox.TextProperty && not patching then
          let t = textOf tb
          if t <> st.Last then
            st.Last <- t
            onInput st.InputTag t)
      tb :> Control

  let rec patch (old: Node) (c: Control) (n: Node) : Control =
    if kind old <> kind n then build n
    else
      match old, n, c with
      | (Column olds | Row olds), (Column xs | Row xs), (:? Panel as p) ->
        let olds = Array.ofList olds
        let xs = Array.ofList xs
        let kids = p.Children
        for i in 0 .. xs.Length - 1 do
          if i < kids.Count && i < olds.Length then
            let c' = patch olds.[i] kids.[i] xs.[i]
            if not (obj.ReferenceEquals(c', kids.[i])) then kids.[i] <- c'
          else kids.Add(build xs.[i])
        while kids.Count > xs.Length do kids.RemoveAt(kids.Count - 1)
        p :> Control
      | _, (Heading s | Text s), (:? TextBlock as t) ->
        if t.Text <> s then t.Text <- s
        t :> Control
      | _, Button (label, msg), (:? Button as b) ->
        if not (obj.Equals(b.Content, label)) then b.Content <- label
        b.Tag <- msg
        b :> Control
      | _, Check (label, isChecked, msg), (:? CheckBox as cb) ->
        if not (obj.Equals(cb.Content, label)) then cb.Content <- label
        cb.Tag <- msg
        if cb.IsChecked <> System.Nullable isChecked then cb.IsChecked <- System.Nullable isChecked
        cb :> Control
      | _, Input (tag, value, hint), (:? TextBox as tb) ->
        let st = tb.Tag :?> InputState
        st.InputTag <- tag
        if tb.PlaceholderText <> hint then tb.PlaceholderText <- hint
        if textOf tb <> value then
          st.Last <- value
          tb.Text <- value
        tb :> Control
      | _ -> build n

  /// Construit ou met à jour l'arbre ; renvoie la racine (même objet tant que la racine garde son genre).
  member _.Render(n: Node) : Control =
    let prev = patching
    patching <- true
    try
      let root =
        match current with
        | Some (old, c) -> patch old c n
        | None -> build n
      current <- Some (n, root)
      root
    finally
      patching <- prev

  /// Oublie l'arbre courant : le prochain rendu reconstruit tout (après remplacement du cœur,
  /// pour ne garder aucune référence vers les types de l'ancien assembly).
  member _.Reset() = current <- None
