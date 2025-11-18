pyftsubset DejaVuSansMono.ttf \
  --text=" \"#'()+,.0123456789:<>?@CDIPRS^_adeimnprtv-–" \
  --output-file=DejaVuSansMono-subset.woff2

base64 -i DejaVuSansMono-subset.woff2 > DejaVuSansMono.base64