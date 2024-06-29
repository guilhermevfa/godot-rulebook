class_name Resolution
extends Script

var rulebook: Rulebook
# Set by Rulebook before calling this resolution
var _match: Dictionary

# ABSTRACT FUNCTION
func _resolve():
  push_error("NOT IMPLEMENTED ERROR: Resolution._resolve()")
