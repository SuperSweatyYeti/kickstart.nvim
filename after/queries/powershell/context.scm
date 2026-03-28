; ; Functions
; (function_statement
;   (function_name) @context) @context.start
;
; ; If statements
; (if_statement
;   condition: (pipeline) @context) @context.start
;
; ; For loops
; (for_statement
;   for_initializer: (for_initializer) @context) @context.start
;
; ; Foreach loops
; (foreach_statement
;   (variable) @context) @context.start
;
; ; While loops
; (while_statement
;   condition: (while_condition) @context) @context.start
;
; ; Do-While / Do-Until
; (do_statement
;   condition: (while_condition) @context) @context.start
;
; ; Switch
; (switch_statement
;   (switch_condition) @context) @context.start
;
; ; Try/Catch/Finally
; (try_statement) @context.start
;
; ; Classes
; (class_statement
;   (simple_name) @context) @context.start
;
; ; Class methods

; (class_method_definition
;   (simple_name) @context) @context.start
;(function_statement) @context
