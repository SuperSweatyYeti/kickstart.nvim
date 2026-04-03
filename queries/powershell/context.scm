; Functions
(function_statement) @context

; Conditionals
(if_statement) @context
(elseif_clause) @context
(else_clause) @context

; Loops
(foreach_statement) @context
(for_statement) @context
(while_statement) @context
(do_statement) @context

; Error handling
(try_statement) @context
(catch_clause) @context
(finally_clause) @context

; Classes
(class_statement) @context
(class_method_definition) @context

; Script blocks (ForEach-Object {}, Where-Object {}, etc.)
(script_block_expression) @context


; (function_statement
;   (script_block) @context.end) @context
;
; (if_statement
;   (statement_block) @context.end) @context
;
; (elseif_clause
;   (statement_block) @context.end) @context
;
; (else_clause
;   (statement_block) @context.end) @context
;
; (foreach_statement
;   (statement_block) @context.end) @context
;
; (for_statement
;   (statement_block) @context.end) @context
;
; (while_statement
;   (statement_block) @context.end) @context
;
; (do_statement) @context
;
; (try_statement
;   (statement_block) @context.end) @context
;
; (catch_clause
;   (statement_block) @context.end) @context
;
; (finally_clause
;   (statement_block) @context.end) @context
;
; (class_statement
;   (simple_name) @context.final) @context
;
; (class_method_definition
;   (script_block) @context.end) @context
