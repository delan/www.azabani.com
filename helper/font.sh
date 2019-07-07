#!/bin/sh
set -eu

O="$(pwd)"
D="$O/asset"
S=' !"#$%&'\''()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~ ¡¢£¤¥¦§¨©ª«¬­®¯°±²³´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿȀȁȂȃȄȅȆȇȈȉȊȋȌȍȎȏȐȑȒȓȔȕȖȗȘșȚțȜȝȞȟȠȡȢȣȤȥȦȧȨȩȪȫȬȭȮȯȰȱȲȳȴȵȶȷȸȹȺȻȼȽȾȿɀɁɂɃɄɅɆɇɈɉɊɋɌɍɎɏɐɑɒɓɔɕɖɗɘəɚɛɜɝɞɟɠɡɢɣɤɥɦɧɨɩɪɫɬɭɮɯɰɱɲɳɴɵɶɷɸɹɺɻɼɽɾɿʀʁʂʃʄʅʆʇʈʉʊʋʌʍʎʏʐʑʒʓʔʕʖʗʘʙʚʛʜʝʞʟʠʡʢʣʤʥʦʧʨʩʪʫʬʭʮʯʰʱʲʳʴʵʶʷʸʹʺʻʼʽʾʿˀˁ˂˃˄˅ˆˇˈˉˊˋˌˍˎˏːˑ˒˓˔˕˖˗˘˙˚˛˜˝˞˟ˠˡˢˣˤ˥˦˧˨˩˪˫ˬ˭ˮ˯˰˱˲˳˴˵˶˷˸˹˺˻˼˽˾˿‐‑‒–—―‖‗‘’‚‛“”„‟™📖'

cd -- "$D"

fontinfo="$O/helper/sfntly/fontinfo.jar"
sfnttool="$O/helper/sfntly/sfnttool.jar"
woff2sfnt="$O/helper/sfnt2woff/woff2sfnt"

unwoff() {
    result="$(mktemp)"

    case "$1" in
    (*.woff) "$woff2sfnt" "$1" > "$result" ;;
    (*) cp -- "$1" "$result" ;;
    esac

    printf '%s' "$result"
}

path="$1"; shift
family="$1"; shift
weight="$1"; shift
style="$1"; shift

if [ $# -gt 0 ]; then
    S="$1"; shift
fi

base="$(basename -- "$path")"
result="-${base%.*}.woff"

if ! [ "./$result" -nt "$path" ] || ! [ "./$result" -nt "$O/helper/font.sh" ]; then
    java -jar "$sfnttool" -s "$S" -w "$(unwoff "$path")" "./$result"
fi

for font in "$path" "$result"; do
    dump="$(mktemp)"
    range="$(mktemp)"

    > "$dump" java -jar "$fontinfo" -r "$(unwoff "./$font")"

    < "$dump" sed -En '/ *U\+([0-9A-F]+).*/{s//0x\1/;p;}' \
        | tr \\n , \
        | sed 's/^/[/;s/,$/]/' \
        | python3 "$O/helper/test.py" \
        > "$range"

    printf '@include font("%s", "%s", %s, %s, %s);\n' "$font" "$family" "$weight" "$style" "$(cat "$range")"
done
