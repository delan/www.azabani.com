#!/bin/sh
set -eu

O="$(pwd)"
D="$O/asset"
S=' ¡¢£¤¥¦§¨©ª«¬­®¯°±²³´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿſƒȀȁȂȃȄȅȆȇȈȉȊȋȌȍȎȏȐȑȒȓȔȕȖȗȘșȚțȜȝȞȟȠȡȢȣȤȥȦȧȨȩȪȫȬȭȮȯȰȱȲȳȴȵȶȷȸȹȺȻȼȽȾȿɀɁɂɃɄɅɆɇɈɉɊɋɌɍɎɏɐɑɒɓɔɕɖɗɘəɚɛɜɝɞɟɠɡɢɣɤɥɦɧɨɩɪɫɬɭɮɯɰɱɲɳɴɵɶɷɸɹɺɻɼɽɾɿʀʁʂʃʄʅʆʇʈʉʊʋʌʍʎʏʐʑʒʓʔʕʖʗʘʙʚʛʜʝʞʟʠʡʢʣʤʥʦʧʨʩʪʫʬʭʮʯʰʱʲʳʴʵʶʷʸʹʺʻʼʽʾʿˀˁ˂˃˄˅ˆˇˈˉˊˋˌˍˎˏːˑ˒˓˔˕˖˗˘˙˚˛˜˝˞˟ˠˡˢˣˤ˥˦˧˨˩˪˫ˬ˭ˮ˯˰˱˲˳˴˵˶˷˸˹˺˻˼˽˾˿ΓΘΣΦΩαδεπστφادلنی‐‑‒–—―‖‗‘’‚‛“”„‟•′″‴‼ⁿ₧™←↑→↓↔↕↨∙√∞∟∩≈≡≤≥⌂⌐⌠⌡␀␁␂␃␄␅␆␇␈␉␊␋␌␍␎␏␐␑␒␓␔␕␖␗␘␙␚␛␜␝␞␟␠␡␢␣␤␥␦─│┌┐└┘├┤┬┴┼═║╒╓╔╕╖╗╘╙╚╛╜╝╞╟╠╡╢╣╤╥╦╧╨╩╪╫╬▀▄█▌▐░▒▓■▬▲►▼◄○◘◙☺☻☼♀♂♠♣♥♦♪♫📖'

cd helper

path="$D/$1"; shift
family="$1"; shift
weight="$1"; shift
style="$1"; shift
base="$(basename -- "$path")"
result="-${base%.*}.woff"

. .venv/bin/activate

(
    set -x

    >&2 npx glyphhanger --formats=woff2 --subset="$path"
    mv -- "$D/${base%.*}-subset.woff2" "$D/${base%.*}.woff2"

    >&2 npx glyphhanger --formats=woff2 --subset="$path" --US_ASCII --whitelist="$S"
    mv -- "$D/${base%.*}-subset.woff2" "$D/-${base%.*}.woff2"
)

printf '@include font("%s", "%s", %s, %s, %s);\n' \
    "${base%.*}.woff2" "$family" "$weight" "$style" \
    'U+0-10FFFF'

printf '@include font("%s", "%s", %s, %s, %s);\n' \
    "-${base%.*}.woff2" "$family" "$weight" "$style" \
    "$(npx glyphhanger --US_ASCII --whitelist="$S")"
