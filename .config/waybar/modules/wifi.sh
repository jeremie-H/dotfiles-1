#!/bin/bash
if [[ $(nmcli -f wifi -t g s) == 'disabled' ]]; then
    jq -nc '{ "text": "", "class": "disabled" }'
    exit 0
fi

iface="$1"

network_name=$(
    nmcli -t -f name,device c s -a \
        | grep ":${iface}$" \
        | cut -d':' -f1
)

if [[ -z $network_name ]]; then
    jq -nc '{ "text": " disconnected", "class": "disconnected" }'
else
    freq=$(iwconfig "$iface" | grep -q 'Frequency:2' && printf '2.4' || printf '5')

    link_quality=$(
        iwconfig "$iface" \
            | grep 'Link Quality' \
            | sed 's/\s\+Link Quality=\([0-9]\+\/[0-9]\+\).*/\1/'
    )

    if [[ $(bc <<< "scale=2; $link_quality < 0.6") == 1 ]]; then
        class='bad-link-q'
    else
        class='good-link-q'
    fi

    text=$(printf '<span color="#888"></span> %s (%s\u2009GHz)' "$network_name" "$freq")
    jq -nc '{ "text": $ARGS.named.text, "class": $ARGS.named.class }' --arg text "$text" --arg class "$class"
fi
