# Couverture des réalisations Custard par la suite F*

187 réalisations déclarées ; 171 exercées par la suite ; 16 bloquées ou éliminées (raison dans le tableau) ; 0 non exercées.

| Nom F* | Réalisation F# | État |
|---|---|---|
| `Prims.op_Plus` | `Prims.op_Plus` | natif (TString.test_prims) |
| `Prims.op_Minus` | `Prims.op_Minus` | natif (TString.test_prims) |
| `Prims.op_Star` | `Prims.op_Star` | natif (TString.test_prims) |
| `Prims.op_Slash` | `Prims.op_Slash` | natif (TString.test_prims) |
| `Prims.op_Percent` | `Prims.op_Percent` | natif (TString.test_prims) |
| `Prims.op_Minus_Minus` | `Prims.op_Minus_Minus` | bloqué : négation unaire : non atteignable depuis F* (op_Tilde_Minus non réalisé, Mx26) |
| `Prims.op_Less` | `Prims.op_Less` | natif (TString.test_prims) |
| `Prims.op_Less_Equals` | `Prims.op_Less_Equals` | natif (TString.test_prims) |
| `Prims.op_Greater` | `Prims.op_Greater` | natif (TString.test_prims) |
| `Prims.op_Greater_Equals` | `Prims.op_Greater_Equals` | natif (TString.test_prims) |
| `Prims.abs` | `Prims.abs` | bloqué : Error 395 op_Tilde_Minus dans la définition F* (Mx27) |
| `Prims.pow2` | `Prims.pow2` | exercé, compilé depuis sa définition F* (prims_pow2) : la réalisation F# n'est pas utilisée |
| `Prims.strcat` | `Prims.strcat` | exercé (alias de Prims.op_Hat) |
| `Prims.op_Hat` | `Prims.strcat` | exercé (alias de Prims.strcat) |
| `Prims.string_of_bool` | `Prims.string_of_bool` | exercé |
| `Prims.string_of_int` | `Prims.string_of_int` | exercé |
| `FStar.List.Tot.Base.isEmpty` | `FStar_List_Tot_Base.isEmpty` | exercé (alias de FStar.List.isEmpty) |
| `FStar.List.Tot.Base.hd` | `FStar_List_Tot_Base.hd` | exercé (alias de FStar.List.hd) |
| `FStar.List.Tot.Base.tail` | `FStar_List_Tot_Base.tail` | exercé |
| `FStar.List.Tot.Base.tl` | `FStar_List_Tot_Base.tl` | exercé (alias de FStar.List.tl, FStar.List.tail) |
| `FStar.List.Tot.Base.last` | `FStar_List_Tot_Base.last` | exercé (alias de FStar.List.last) |
| `FStar.List.Tot.Base.init` | `FStar_List_Tot_Base.init` | exercé (alias de FStar.List.init) |
| `FStar.List.Tot.Base.length` | `FStar_List_Tot_Base.length` | exercé (alias de FStar.List.length) |
| `FStar.List.Tot.Base.nth` | `FStar_List_Tot_Base.nth` | exercé |
| `FStar.List.Tot.Base.index` | `FStar_List_Tot_Base.index` | exercé |
| `FStar.List.Tot.Base.count` | `FStar_List_Tot_Base.count` | exercé |
| `FStar.List.Tot.Base.rev_acc` | `FStar_List_Tot_Base.rev_acc` | exercé |
| `FStar.List.Tot.Base.rev` | `FStar_List_Tot_Base.rev` | exercé (alias de FStar.List.rev) |
| `FStar.List.Tot.Base.append` | `FStar_List_Tot_Base.append` | exercé (alias de FStar.List.Tot.Base.op_At, FStar.List.append, FStar.List.op_At) |
| `FStar.List.Tot.Base.snoc` | `FStar_List_Tot_Base.snoc` | exercé |
| `FStar.List.Tot.Base.flatten` | `FStar_List_Tot_Base.flatten` | exercé (alias de FStar.List.flatten) |
| `FStar.List.Tot.Base.map` | `FStar_List_Tot_Base.map` | exercé (alias de FStar.List.map) |
| `FStar.List.Tot.Base.mapi` | `FStar_List_Tot_Base.mapi` | exercé (alias de FStar.List.mapi) |
| `FStar.List.Tot.Base.concatMap` | `FStar_List_Tot_Base.concatMap` | exercé (alias de FStar.List.concatMap) |
| `FStar.List.Tot.Base.fold_left` | `FStar_List_Tot_Base.fold_left` | exercé (alias de FStar.List.fold_left) |
| `FStar.List.Tot.Base.fold_right` | `FStar_List_Tot_Base.fold_right` | exercé (alias de FStar.List.fold_right) |
| `FStar.List.Tot.Base.fold_left2` | `FStar_List_Tot_Base.fold_left2` | exercé (alias de FStar.List.fold_left2) |
| `FStar.List.Tot.Base.mem` | `FStar_List_Tot_Base.mem` | exercé (alias de FStar.List.mem) |
| `FStar.List.Tot.Base.contains` | `FStar_List_Tot_Base.contains` | exercé (alias de FStar.List.contains) |
| `FStar.List.Tot.Base.existsb` | `FStar_List_Tot_Base.existsb` | exercé (alias de FStar.List.existsb) |
| `FStar.List.Tot.Base.find` | `FStar_List_Tot_Base.find` | exercé (alias de FStar.List.find) |
| `FStar.List.Tot.Base.filter` | `FStar_List_Tot_Base.filter` | exercé (alias de FStar.List.filter) |
| `FStar.List.Tot.Base.for_all` | `FStar_List_Tot_Base.for_all` | exercé (alias de FStar.List.for_all) |
| `FStar.List.Tot.Base.collect` | `FStar_List_Tot_Base.collect` | exercé (alias de FStar.List.collect) |
| `FStar.List.Tot.Base.tryFind` | `FStar_List_Tot_Base.tryFind` | exercé (alias de FStar.List.tryFind) |
| `FStar.List.Tot.Base.tryPick` | `FStar_List_Tot_Base.tryPick` | exercé (alias de FStar.List.tryPick) |
| `FStar.List.Tot.Base.choose` | `FStar_List_Tot_Base.choose` | exercé (alias de FStar.List.choose) |
| `FStar.List.Tot.Base.partition` | `FStar_List_Tot_Base.partition` | exercé (alias de FStar.List.partition) |
| `FStar.List.Tot.Base.noRepeats` | `FStar_List_Tot_Base.noRepeats` | exercé |
| `FStar.List.Tot.Base.assoc` | `FStar_List_Tot_Base.assoc` | exercé (alias de FStar.List.assoc) |
| `FStar.List.Tot.Base.split` | `FStar_List_Tot_Base.split` | exercé (alias de FStar.List.split) |
| `FStar.List.Tot.Base.unzip` | `FStar_List_Tot_Base.unzip` | exercé (alias de FStar.List.unzip) |
| `FStar.List.Tot.Base.unzip3` | `FStar_List_Tot_Base.unzip3` | exercé (alias de FStar.List.unzip3) |
| `FStar.List.Tot.Base.splitAt` | `FStar_List_Tot_Base.splitAt` | exercé (alias de FStar.List.splitAt) |
| `FStar.List.Tot.Base.unsnoc` | `FStar_List_Tot_Base.unsnoc` | exercé |
| `FStar.List.Tot.Base.split3` | `FStar_List_Tot_Base.split3` | exercé |
| `FStar.List.Tot.Base.bool_of_compare` | `FStar_List_Tot_Base.bool_of_compare` | bloqué : signe inversé dans la réalisation (Mx31) : exercée par la matrice, pas par la suite |
| `FStar.List.Tot.Base.compare_of_bool` | `FStar_List_Tot_Base.compare_of_bool` | bloqué : signes inversés dans la réalisation (Mx32) : exercée par la matrice, pas par la suite |
| `FStar.List.Tot.Base.sortWith` | `FStar_List_Tot_Base.sortWith` | exercé (alias de FStar.List.sortWith) |
| `FStar.List.Tot.Base.subset` | `FStar_List_Tot_Base.subset` | exercé |
| `FStar.List.Tot.Base.list_unref` | `FStar_List_Tot_Base.list_unref` | éliminé : identité : l'appel disparaît du F# généré (le test ne peut pas distinguer) |
| `FStar.List.Tot.Base.list_ref` | `FStar_List_Tot_Base.list_ref` | éliminé : identité : l'appel disparaît du F# généré |
| `FStar.List.Tot.Base.list_refb` | `FStar_List_Tot_Base.list_refb` | bloqué : le F# généré ne compile pas (Mx29) |
| `FStar.List.Tot.Base.op_At` | `FStar_List_Tot_Base.append` | exercé (alias de FStar.List.Tot.Base.append, FStar.List.append, FStar.List.op_At) |
| `FStar.UInt8.to_string` | `Prims.string_of_int8` | exercé |
| `FStar.UInt16.to_string` | `Prims.string_of_int16` | exercé |
| `FStar.UInt32.to_string` | `Prims.string_of_int32` | exercé |
| `FStar.UInt64.to_string` | `Prims.string_of_int64` | exercé |
| `FStar.Int8.to_string` | `Prims.string_of_sint8` | exercé |
| `FStar.Int16.to_string` | `Prims.string_of_sint16` | exercé |
| `FStar.Int32.to_string` | `Prims.string_of_sint32` | exercé |
| `FStar.Int64.to_string` | `Prims.string_of_sint64` | exercé |
| `FStar.IO.print_newline` | `FStar_IO.print_newline` | exercé |
| `FStar.IO.print_string` | `FStar_IO.print_string` | exercé |
| `FStar.IO.print_uint8` | `FStar_IO.print_uint8` | exercé |
| `FStar.IO.print_uint16` | `FStar_IO.print_uint16` | exercé |
| `FStar.IO.print_uint32` | `FStar_IO.print_uint32` | exercé |
| `FStar.IO.print_uint64` | `FStar_IO.print_uint64` | exercé |
| `FStar.IO.print_uint8_dec` | `FStar_IO.print_uint8_dec` | exercé |
| `FStar.IO.print_uint16_dec` | `FStar_IO.print_uint16_dec` | exercé |
| `FStar.IO.print_uint32_dec` | `FStar_IO.print_uint32_dec` | exercé |
| `FStar.IO.print_uint64_dec` | `FStar_IO.print_uint64_dec` | exercé |
| `FStar.IO.print_uint8_hex_pad` | `FStar_IO.print_uint8_hex_pad` | bloqué : divergence : préfixe 0x (Mx34), comportement observé mais pas conforme |
| `FStar.IO.print_uint16_hex_pad` | `FStar_IO.print_uint16_hex_pad` | bloqué : idem (Mx34) |
| `FStar.IO.print_uint32_hex_pad` | `FStar_IO.print_uint32_hex_pad` | bloqué : idem (Mx34) |
| `FStar.IO.print_uint64_hex_pad` | `FStar_IO.print_uint64_hex_pad` | bloqué : idem (Mx34) |
| `FStar.IO.print_uint8_dec_pad` | `FStar_IO.print_uint8_dec_pad` | exercé |
| `FStar.IO.print_uint16_dec_pad` | `FStar_IO.print_uint16_dec_pad` | exercé |
| `FStar.IO.print_uint32_dec_pad` | `FStar_IO.print_uint32_dec_pad` | exercé |
| `FStar.IO.print_uint64_dec_pad` | `FStar_IO.print_uint64_dec_pad` | exercé |
| `FStar.IO.debug_print_string` | `FStar_IO.debug_print_string` | bloqué : pas de contrat (« toujours false », impression de débogage) |
| `FStar.Char.lowercase` | `FStar_Char.lowercase` | exercé |
| `FStar.Char.uppercase` | `FStar_Char.uppercase` | exercé |
| `FStar.Char.int_of_char` | `FStar_Char.int_of_char` | exercé |
| `FStar.Char.char_of_int` | `FStar_Char.char_of_int` | exercé |
| `FStar.Char.u32_of_char` | `FStar_Char.u32_of_char` | bloqué : Error 395 char_code (docs/FSTAR-char_code.md) |
| `FStar.Char.char_of_u32` | `FStar_Char.char_of_u32` | bloqué : Error 395 char_code |
| `FStar.String.make` | `FStar_String.make` | exercé |
| `FStar.String.strcat` | `FStar_String.strcat` | bloqué : non déclaré dans FStar.String.fsti (inaccessible) |
| `FStar.String.op_Hat` | `FStar_String.strcat` | bloqué : non déclaré dans FStar.String.fsti (inaccessible) |
| `FStar.String.split` | `FStar_String.split` | exercé |
| `FStar.String.compare` | `FStar_String.compare` | exercé |
| `FStar.String.concat` | `FStar_String.concat` | exercé |
| `FStar.String.length` | `FStar_String.length` | exercé (alias de FStar.String.strlen) |
| `FStar.String.strlen` | `FStar_String.length` | exercé (alias de FStar.String.length) |
| `FStar.String.substring` | `FStar_String.substring` | exercé (alias de FStar.String.sub) |
| `FStar.String.sub` | `FStar_String.substring` | exercé (alias de FStar.String.substring) |
| `FStar.String.get` | `FStar_String.get` | exercé (alias de FStar.String.index) |
| `FStar.String.index` | `FStar_String.get` | exercé (alias de FStar.String.get) |
| `FStar.String.collect` | `FStar_String.collect` | exercé |
| `FStar.String.lowercase` | `FStar_String.lowercase` | exercé |
| `FStar.String.uppercase` | `FStar_String.uppercase` | exercé |
| `FStar.String.index_of` | `FStar_String.index_of` | exercé |
| `FStar.String.list_of_string` | `FStar_String.list_of_string` | exercé |
| `FStar.String.string_of_list` | `FStar_String.string_of_list` | exercé |
| `FStar.String.string_of_char` | `FStar_String.string_of_char` | exercé |
| `FStar.All.failwith` | `FStar_All.failwith` | exercé |
| `FStar.All.exit` | `FStar_All.exit` | exercé |
| `FStar.All.try_with` | `FStar_All.try_with` | exercé, compilé en try..with natif |
| `FStar.All.pipe_right` | `FStar_All.pipe_right` | exercé, compilé en application directe |
| `FStar.All.pipe_left` | `FStar_All.pipe_left` | exercé, compilé en application directe |
| `FStar.List.hd` | `FStar_List_Tot_Base.hd` | exercé (alias de FStar.List.Tot.Base.hd) |
| `FStar.List.tl` | `FStar_List_Tot_Base.tl` | exercé (alias de FStar.List.Tot.Base.tl, FStar.List.tail) |
| `FStar.List.tail` | `FStar_List_Tot_Base.tl` | exercé (alias de FStar.List.Tot.Base.tl, FStar.List.tl) |
| `FStar.List.last` | `FStar_List_Tot_Base.last` | exercé (alias de FStar.List.Tot.Base.last) |
| `FStar.List.init` | `FStar_List_Tot_Base.init` | exercé (alias de FStar.List.Tot.Base.init) |
| `FStar.List.length` | `FStar_List_Tot_Base.length` | exercé (alias de FStar.List.Tot.Base.length) |
| `FStar.List.rev` | `FStar_List_Tot_Base.rev` | exercé (alias de FStar.List.Tot.Base.rev) |
| `FStar.List.append` | `FStar_List_Tot_Base.append` | exercé (alias de FStar.List.Tot.Base.append, FStar.List.Tot.Base.op_At, FStar.List.op_At) |
| `FStar.List.op_At` | `FStar_List_Tot_Base.append` | exercé (alias de FStar.List.Tot.Base.append, FStar.List.Tot.Base.op_At, FStar.List.append) |
| `FStar.List.flatten` | `FStar_List_Tot_Base.flatten` | exercé (alias de FStar.List.Tot.Base.flatten) |
| `FStar.List.mem` | `FStar_List_Tot_Base.mem` | exercé (alias de FStar.List.Tot.Base.mem) |
| `FStar.List.contains` | `FStar_List_Tot_Base.contains` | exercé (alias de FStar.List.Tot.Base.contains) |
| `FStar.List.isEmpty` | `FStar_List_Tot_Base.isEmpty` | exercé (alias de FStar.List.Tot.Base.isEmpty) |
| `FStar.List.split` | `FStar_List_Tot_Base.split` | exercé (alias de FStar.List.Tot.Base.split) |
| `FStar.List.unzip` | `FStar_List_Tot_Base.unzip` | exercé (alias de FStar.List.Tot.Base.unzip) |
| `FStar.List.unzip3` | `FStar_List_Tot_Base.unzip3` | exercé (alias de FStar.List.Tot.Base.unzip3) |
| `FStar.List.splitAt` | `FStar_List_Tot_Base.splitAt` | exercé (alias de FStar.List.Tot.Base.splitAt) |
| `FStar.List.nth` | `FStar_List.nth` | exercé |
| `FStar.List.iter` | `FStar_List.iter` | exercé |
| `FStar.List.iteri` | `FStar_List.iteri` | exercé |
| `FStar.List.map` | `FStar_List_Tot_Base.map` | exercé (alias de FStar.List.Tot.Base.map) |
| `FStar.List.mapi` | `FStar_List_Tot_Base.mapi` | exercé (alias de FStar.List.Tot.Base.mapi) |
| `FStar.List.collect` | `FStar_List_Tot_Base.collect` | exercé (alias de FStar.List.Tot.Base.collect) |
| `FStar.List.concatMap` | `FStar_List_Tot_Base.concatMap` | exercé (alias de FStar.List.Tot.Base.concatMap) |
| `FStar.List.fold_left` | `FStar_List_Tot_Base.fold_left` | exercé (alias de FStar.List.Tot.Base.fold_left) |
| `FStar.List.fold_right` | `FStar_List_Tot_Base.fold_right` | exercé (alias de FStar.List.Tot.Base.fold_right) |
| `FStar.List.fold_left2` | `FStar_List_Tot_Base.fold_left2` | exercé (alias de FStar.List.Tot.Base.fold_left2) |
| `FStar.List.filter` | `FStar_List_Tot_Base.filter` | exercé (alias de FStar.List.Tot.Base.filter) |
| `FStar.List.for_all` | `FStar_List_Tot_Base.for_all` | exercé (alias de FStar.List.Tot.Base.for_all) |
| `FStar.List.existsb` | `FStar_List_Tot_Base.existsb` | exercé (alias de FStar.List.Tot.Base.existsb) |
| `FStar.List.find` | `FStar_List_Tot_Base.find` | exercé (alias de FStar.List.Tot.Base.find) |
| `FStar.List.tryFind` | `FStar_List_Tot_Base.tryFind` | exercé (alias de FStar.List.Tot.Base.tryFind) |
| `FStar.List.tryPick` | `FStar_List_Tot_Base.tryPick` | exercé (alias de FStar.List.Tot.Base.tryPick) |
| `FStar.List.choose` | `FStar_List_Tot_Base.choose` | exercé (alias de FStar.List.Tot.Base.choose) |
| `FStar.List.partition` | `FStar_List_Tot_Base.partition` | exercé (alias de FStar.List.Tot.Base.partition) |
| `FStar.List.assoc` | `FStar_List_Tot_Base.assoc` | exercé (alias de FStar.List.Tot.Base.assoc) |
| `FStar.List.sortWith` | `FStar_List_Tot_Base.sortWith` | exercé (alias de FStar.List.Tot.Base.sortWith) |
| `FStar.Bytes.len` | `FStar_Bytes.len` | exercé |
| `FStar.Bytes.empty_bytes` | `FStar_Bytes.empty_bytes` | exercé |
| `FStar.Bytes.get` | `FStar_Bytes.get` | exercé |
| `FStar.Bytes.create` | `FStar_Bytes.create` | exercé |
| `FStar.Bytes.init` | `FStar_Bytes.init` | exercé |
| `FStar.Bytes.abyte` | `FStar_Bytes.abyte` | exercé |
| `FStar.Bytes.twobytes` | `FStar_Bytes.twobytes` | exercé |
| `FStar.Bytes.append` | `FStar_Bytes.append` | exercé |
| `FStar.Bytes.slice` | `FStar_Bytes.slice` | exercé |
| `FStar.Bytes.sub` | `FStar_Bytes.sub` | exercé |
| `FStar.Bytes.split` | `FStar_Bytes.split` | exercé |
| `FStar.Bytes.repr_bytes` | `FStar_Bytes.repr_bytes` | exercé |
| `FStar.Bytes.int_of_bytes` | `FStar_Bytes.int_of_bytes` | exercé |
| `FStar.Bytes.bytes_of_int` | `FStar_Bytes.bytes_of_int` | exercé |
| `FStar.Bytes.int32_of_bytes` | `FStar_Bytes.int32_of_bytes` | exercé |
| `FStar.Bytes.int16_of_bytes` | `FStar_Bytes.int16_of_bytes` | exercé |
| `FStar.Bytes.int8_of_bytes` | `FStar_Bytes.int8_of_bytes` | exercé |
| `FStar.Bytes.bytes_of_int32` | `FStar_Bytes.bytes_of_int32` | exercé |
| `FStar.Bytes.bytes_of_int16` | `FStar_Bytes.bytes_of_int16` | exercé |
| `FStar.Bytes.bytes_of_int8` | `FStar_Bytes.bytes_of_int8` | exercé |
| `FStar.Bytes.xor` | `FStar_Bytes.xor` | exercé |
| `FStar.Bytes.utf8_encode` | `FStar_Bytes.utf8_encode` | exercé |
| `FStar.Bytes.iutf8_opt` | `FStar_Bytes.iutf8_opt` | exercé |
| `FStar.Bytes.string_of_hex` | `FStar_Bytes.string_of_hex` | exercé |
| `FStar.Bytes.bytes_of_hex` | `FStar_Bytes.bytes_of_hex` | exercé |
| `FStar.Bytes.hex_of_string` | `FStar_Bytes.hex_of_string` | exercé |
| `FStar.Bytes.hex_of_bytes` | `FStar_Bytes.hex_of_bytes` | exercé |
| `FStar.Bytes.print_bytes` | `FStar_Bytes.print_bytes` | exercé |
| `FStar.Bytes.bytes_of_string` | `FStar_Bytes.bytes_of_string` | exercé |
