[![Actions Status](https://github.com/raku-community-modules/IDNA-Punycode/workflows/test/badge.svg)](https://github.com/raku-community-modules/IDNA-Punycode/actions)

NAME
====

IDNA::Punycode - Punycode implementation according to RFC3492

SYNOPSIS
========

```raku
use IDNA::Punycode;

say encode_punycode 'nice'  # nice
say encode_punycode 'schön' # xn--schn-7qa

say decode_punycode 'nice'         # nice
say decode_punycode 'xn--schn-7qa' # schön
```

DESCRIPTION
===========

The `IDNA::Punycode` provides an easy way to encode / decode strings according to [RFC3492](https://www.rfc-editor.org/info/rfc3492).

AUTHOR
======

Tobias Leich (FROGGS)

Source can be located at: https://github.com/raku-community-modules/IDNA-Punycode . Comments and Pull Requests are welcome.

COPYRIGHT AND LICENSE
=====================

Copyright 2015, 2016, 2017 Tobias Leich, 2023 Raku Community

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

