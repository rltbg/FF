namespace Ui

open System.Collections.Generic
open Avalonia
open Avalonia.Controls
open Avalonia.Layout
open Avalonia.Media

/// Interpréteur Node -> contrôles Avalonia. Les TextBox sont conservés entre deux rendus (clé = tag).
type Interp(dispatch: obj -> unit, onInput: obj -> string -> unit) =
  let boxes = Dictionary<obj, TextBox>()
  let lastText = Dictionary<obj, string>()

  let detach (c: Control) =
    match c.Parent with
    | :? Panel as p -> p.Children.Remove c |> ignore
    | _ -> ()

  member this.Build(node: Node) : Control =
    match node with
    | Column xs ->
      let p = StackPanel(Spacing = 8.0)
      for x in xs do p.Children.Add(this.Build x)
      p :> Control
    | Row xs ->
      let p = StackPanel(Orientation = Orientation.Horizontal, Spacing = 8.0)
      for x in xs do p.Children.Add(this.Build x)
      p :> Control
    | Heading s -> TextBlock(Text = s, FontSize = 22.0, FontWeight = FontWeight.Bold) :> Control
    | Text s -> TextBlock(Text = s, TextWrapping = TextWrapping.Wrap) :> Control
    | Button (label, msg) ->
      let b = Button(Content = label)
      b.Click.Add(fun _ -> dispatch msg)
      b :> Control
    | Check (label, isChecked, msg) ->
      let c = CheckBox(Content = label, IsChecked = System.Nullable isChecked)
      c.IsCheckedChanged.Add(fun _ -> if c.IsChecked = System.Nullable(not isChecked) then dispatch msg)
      c :> Control
    | Input (tag, value, hint) ->
      let key = tag
      let tb =
        match boxes.TryGetValue key with
        | true, tb -> detach tb; tb
        | _ ->
          let tb = TextBox(Width = 220.0)
          boxes.[key] <- tb
          lastText.[key] <- ""
          tb.TextChanged.Add(fun _ ->
            let t = if isNull tb.Text then "" else tb.Text
            if t <> lastText.[key] then
              lastText.[key] <- t
              onInput (box tb.Tag) t)
          tb
      tb.Tag <- tag
      tb.PlaceholderText <- hint
      if (if isNull tb.Text then "" else tb.Text) <> value then
        lastText.[key] <- value
        tb.Text <- value
      tb :> Control
