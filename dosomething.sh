cd src
for f in *.mli; do
  # echo ${f:4};
  echo $f;
  # git checkout $f
  # ocamlfind ocamlc -package sexplib,ppx_sexp_conv,ppx_compare,ppx_bin_prot,ppx_typerep_conv,ppx_enumerate,ppx_fields_conv,ppx_variants_conv -dsource -c $f &> tmp_$f;
  # sed -i.bak '1d' tmp_$f
  # sed -i.bak '/^File \"/d' tmp_$f
  # sed -i.bak '/^Error\: /d' tmp_$f
  # sed -i.bak -e 's/Sexplib/OcamlSexplib/g' tmp_$f
  # sed -i.bak -e 's/Bin_prot/OcamlBin_prot/g' tmp_$f
  # sed -i.bak -e 's/Typerep_lib/OcamlTyperep/g' tmp_$f
  # sed -i.bak -e 's/OcamlOcaml/Ocaml/g' tmp_$f
  # sed -i.bak -e 's/Variantslib/OcamlVariantslib/g' tmp_$f
  # sed -i.bak -e 's/Typerep_lib/Typerep/g' $f
  # sed -i.bak -e 's/ OcamlResult\.Result\.Export/ Core_result\.Export/g' $f
  # sed -i.bak -e 's/ OcamlResult\.Result\.bind/ Core_result\.bind/g' $f
  sed -i.bak -e 's/Ppx_assert\./Ppx_assert_lib\./g' $f
  # sed -i.bak -e 's/Ppx_assert_lib/Ppx_assert/g' $f
  # sed -i.bak -e 's/\[@@nonrec \]//g' tmp_$f
  # mv $f ${f:4}
done
