#!/bin/bash
# This rewrites the grok patterns file
# in case of changes to the existing patterns
# this file can be regenerated

(
echo "class GrokPatterns"
echo ""
echo "  @@global_patterns = {"

# ensure we parse the common grok patterns first
GLOBIGNORE="*grok-patterns"
for i in src/patterns/grok-patterns src/patterns/* ; do
#for i in src/patterns/grok-patterns ; do
  echo "    # ${i/*\/}"
  cat $i | grep '^[A-Z]' | grep -vE '(RAILS3PROFILE|RAILS3)' | sed -e 's/^\([A-Z0-9_]*\) \(.*\)/    "\1" => %q(\2),/g'
  echo ""
done

echo "  }"
echo
echo "  def self.patterns"
echo "    @@global_patterns"
echo "  end"
echo
echo "end"
) > src/patterns.cr
