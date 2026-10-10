#!/usr/bin/env bash
set -euo pipefail

# The generator accepts one optional title. With no title, using today's date
# keeps the command useful for dated notes while still producing a valid slug.
if (( $# > 1 )); then
  printf 'Usage: %s [page title]\n' "$0" >&2
  exit 2
fi

title="${1:-$(date +%F)}"
if [[ -z "$title" || "$title" == *$'\n'* || "$title" == *$'\r'* ]]; then
  printf 'Page title must be a non-empty single line.\n' >&2
  exit 2
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Resolve paths relative to this script so it works regardless of the caller's
# current working directory.
site_root="$(cd "$script_dir/.." && pwd)"
template_file="$script_dir/templates/org-page.org"

# Keep the display title intact in the page, but derive a portable filename and
# URL slug from it. Transliteration preserves readable forms of accented text;
# the final substitutions lowercase the slug and replace punctuation/spacing
# with single hyphens.
slug="$(printf '%s' "$title" \
  | iconv -f UTF-8 -t ASCII//TRANSLIT \
  | tr '[:upper:]' '[:lower:]' \
  | sed -E 's/[^a-z0-9]+/-/g; s/^-//; s/-$//')"
if [[ -z "$slug" ]]; then
  printf 'Page title must contain letters or numbers.\n' >&2
  exit 2
fi

output_file="$site_root/$slug.org"
# Fail early for the common duplicate case. The later hard-link operation also
# checks atomically, so a file created after this test cannot be overwritten.
if [[ -e "$output_file" ]]; then
  printf 'File already exists: %s\n' "$output_file" >&2
  exit 1
fi

escape_sed_replacement() {
  printf '%s' "$1" | sed 's/[\\&|]/\\&/g'
}

# In sed replacement text, backslash, ampersand, and the chosen delimiter have
# special meanings. Escape them so titles containing those characters are
# copied literally into the Org template.
escaped_title="$(escape_sed_replacement "$title")"
# Build a temporary file in the destination directory: keeping it on the same
# filesystem lets ln create the final name atomically without replacing an
# existing page. The trap removes the temporary file if substitution or linking
# fails partway through.
temp_file="$(mktemp "$site_root/.${slug}.org.XXXXXX")"
trap 'rm -f "$temp_file"' EXIT
sed \
  -e "s|@@TITLE@@|$escaped_title|g" \
  -e "s|@@SLUG@@|$slug|g" \
  "$template_file" > "$temp_file"
chmod 644 "$temp_file"

if ! ln "$temp_file" "$output_file"; then
  printf 'File already exists: %s\n' "$output_file" >&2
  exit 1
fi

rm -f "$temp_file"
trap - EXIT
printf 'Created %s\n' "$output_file"