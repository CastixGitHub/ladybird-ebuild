# Ladybird Browser Ebuilds

This Repository contains Gentoo ebuilds for:

- Ladybird

- Skia

- simdutf (you can use GURU too)


## Scope

If you want to contribute to Ladybird development

This might help you doing so (set:)
```
 *   EGIT_OVERRIDE_REPO_LADYBIRDBROWSER_LADYBIRD
 *   EGIT_OVERRIDE_BRANCH_LADYBIRDBROWSER_LADYBIRD
 *   EGIT_OVERRIDE_COMMIT_LADYBIRDBROWSER_LADYBIRD
```

##### Disclaimers

- Skia and Ladybird have been patched to ensure skia libraries have a prefix

- Skia's skcms have been stripped away of some optimizations for >2013 amd64.

  You should USE="-no-avx512" on newer cpus (should be reamed into a meaningful name)

- ANGLE have been chopped off, so WebGL may not work on every website (or not work at all), see PR#12 for more info or alternatives

  DANGEROUS: That's unsafe! See https://github.com/LadybirdBrowser/ladybird/issues/5785#issuecomment-3182078580
