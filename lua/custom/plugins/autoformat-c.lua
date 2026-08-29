return {
  {
    'stevearc/conform.nvim',

    opts = function(_, opts)
      -- ======================================================================
      -- C FORMATTER
      -- ======================================================================
      --
      -- clangd        -> language server
      -- clang-format  -> code formatter
      -- conform.nvim  -> runs clang-format
      --
      -- This file contains the C formatting configuration.
      --
      -- C++ projects should use autoformat-cpp.lua instead.
      --
      -- ======================================================================

      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters = opts.formatters or {}

      -- ----------------------------------------------------------------------
      -- Filetypes
      -- ----------------------------------------------------------------------

      opts.formatters_by_ft.c = { 'clang_format_c' }

      -- ======================================================================
      -- clang-format (C style)
      -- ======================================================================
      --
      -- We start with the LLVM preset and override individual options.
      --
      -- Built-in presets include:
      --
      --   LLVM
      --   Google
      --   Chromium
      --   Mozilla
      --   WebKit
      --   Microsoft
      --   GNU
      --
      -- ======================================================================

      local clang_format_style = [[
# ======================================================================
# BASE STYLE
# ======================================================================

# Start with the LLVM formatting style.
#
# Other presets:
#
#   LLVM
#   Google
#   Chromium
#   Mozilla
#   WebKit
#   Microsoft
#   GNU
#
BasedOnStyle: LLVM


# ======================================================================
# LANGUAGE
# ======================================================================

# Explicitly target C.
#
# Options:
#
#   Cpp
#   C
#   Java
#   JavaScript
#   ObjC
#   Proto
#   CSharp
#
Language: C


# ======================================================================
# INDENTATION
# ======================================================================

# Number of spaces per indentation level.
#
# Common choices:
#
#   2
#   4
#   8
#
# We are using 4 spaces.
#
IndentWidth: 4

# Number of spaces represented by a tab.
#
TabWidth: 4

# Never use actual tab characters for indentation.
#
# Never:
#   Use spaces.
#
# ForIndentation:
#   Tabs may be used for indentation.
#
# Always:
#   Prefer tabs.
#
UseTab: Never

# Indent the contents of switch cases.
#
# true:
#
#   switch (value)
#   {
#       case 1:
#           foo();
#           break;
#   }
#
# false:
#
#   switch (value)
#   {
#   case 1:
#       foo();
#       break;
#   }
#
IndentCaseLabels: true


# ======================================================================
# BRACES
# ======================================================================

# Keep the opening brace on the same line.
#
# Attach:
#
#   if (condition) {
#       foo();
#   }
#
# Allman would produce:
#
#   if (condition)
#   {
#       foo();
#   }
#
# GNU would produce:
#
#   if (condition)
#     {
#       foo();
#     }
#
BreakBeforeBraces: Attach

# Allow completely empty functions to stay on one line.
#
#   void noop(void) {}
#
# Other common values:
#
#   None
#   Empty
#   Inline
#   InlineOnly
#
AllowShortFunctionsOnASingleLine: Empty

# Don't put short if statements on one line.
#
# Keeps:
#
#   if (x) {
#       foo();
#   }
#
# instead of:
#
#   if (x) foo();
#
AllowShortIfStatementsOnASingleLine: Never

# Don't collapse short loops onto one line.
#
AllowShortLoopsOnASingleLine: false

# Don't collapse short blocks onto one line.
#
AllowShortBlocksOnASingleLine: false


# ======================================================================
# LINE LENGTH
# ======================================================================

# Maximum preferred line length.
#
# Common choices:
#
#   80
#   100
#   120
#
# 0 means no column limit.
#
ColumnLimit: 0


# ======================================================================
# SPACING
# ======================================================================

# Add spaces around assignment operators.
#
#   int size = 10;
#   size += 5;
#
# instead of:
#
#   int size=10;
#   size+=5;
#
SpaceBeforeAssignmentOperators: true

# Don't put spaces immediately inside parentheses.
#
#   foo(x, y);
#
# instead of:
#
#   foo( x, y );
#
SpacesInParentheses: false

# Don't put spaces inside square brackets.
#
#   array[index]
#
# instead of:
#
#   array[ index ]
#
SpacesInSquareBrackets: false


# ======================================================================
# POINTERS
# ======================================================================

# Put * next to the type.
#
# Left:
#
#   int* ptr;
#
# Right:
#
#   int *ptr;
#
# Middle:
#
#   int * ptr;
#
# NOTE:
#   In C, "Right" is more traditional.  K&R and the
#   Linux kernel style both use "int *ptr".
#
#   "Left" keeps consistency with the C++ config.
#   Change to "Right" for a more C-idiomatic style.
#
PointerAlignment: Left


# ======================================================================
# FUNCTION PARAMETERS / ARGUMENTS
# ======================================================================

# Keep function arguments together on one line when possible.
#
# true:
#
#   foo(first, second, third);
#
# false may produce:
#
#   foo(
#       first,
#       second,
#       third);
#
BinPackArguments: true

# Keep function parameters together on one line when possible.
#
#   void foo(int first, int second, int third);
#
BinPackParameters: true


# ======================================================================
# STRUCTS / ENUMS
# ======================================================================

# Allow short enums on a single line.
#
# true:
#
#   enum Color { RED, GREEN, BLUE };
#
# false:
#
#   enum Color {
#       RED,
#       GREEN,
#       BLUE
#   };
#
AllowShortEnumsOnASingleLine: false


# ======================================================================
# INCLUDES
# ======================================================================

# Sort #include directives.
#
# Options:
#
#   Never
#   CaseSensitive
#   CaseInsensitive
#
SortIncludes: CaseSensitive

# Regroup include blocks when sorting.
#
IncludeBlocks: Regroup


# ======================================================================
# COMMENTS
# ======================================================================

# Allow clang-format to reflow long comments.
#
# true:
#   Long comments may be wrapped.
#
# false:
#   Leave comment wrapping alone.
#
ReflowComments: true

# Align trailing comments.
#
#   int x = 1;          // value
#   int longer_name = 2; // another value
#
AlignTrailingComments: true


# ======================================================================
# EMPTY LINES
# ======================================================================

# Maximum number of consecutive blank lines.
#
# 0 = no blank lines
# 1 = one blank line
# 2 = two blank lines
#
MaxEmptyLinesToKeep: 1


# ======================================================================
# OPERATORS
# ======================================================================

# Keep binary operators at the end of wrapped lines.
#
#   int result = first + second +
#                third;
#
# Beginning would produce:
#
#   int result = first + second
#                + third;
#
BreakBeforeBinaryOperators: None

# Keep ternary operators in the conventional position.
#
#   int result = condition ? first : second;
#
BreakBeforeTernaryOperators: false


# ======================================================================
# STRING LITERALS
# ======================================================================

# Don't automatically split long string literals.
#
BreakStringLiterals: false


# ======================================================================
# ALIGNMENT
# ======================================================================

# Don't align consecutive assignments.
#
#   int x = 1;
#   int longer_name = 2;
#
# instead of:
#
#   int x           = 1;
#   int longer_name = 2;
#
AlignConsecutiveAssignments: None

# Don't align consecutive declarations.
#
AlignConsecutiveDeclarations: None

# Don't align consecutive macros.
#
#   #define SHORT 1
#   #define LONGER_NAME 2
#
# instead of:
#
#   #define SHORT       1
#   #define LONGER_NAME 2
#
AlignConsecutiveMacros: None
]]

      -- ======================================================================
      -- PLATFORM-SPECIFIC clang-format CONFIGURATION
      -- ======================================================================
      --
      -- Windows:
      --
      --   The complete --style={...} configuration can exceed the Windows
      --   command-line length limit.
      --
      --   Therefore, write the YAML to a temporary file and use:
      --
      --       --style=file:<path>
      --
      -- Linux/macOS:
      --
      --   Pass the configuration directly using the clang-format inline
      --   style syntax.
      --
      -- ======================================================================

      if is_os_windows() then
        local cache_dir = vim.fn.stdpath('cache')
        local clang_format_file = cache_dir .. '/clang-format-c.nvim.yaml'

        -- Make sure the cache directory exists.
        vim.fn.mkdir(cache_dir, 'p')

        -- Write valid YAML to the configuration file.
        vim.fn.writefile(
          vim.split(clang_format_style, '\n', { plain = true }),
          clang_format_file
        )

        opts.formatters.clang_format_c = {
          command = 'clang-format',
          prepend_args = {
            '--style=file:' .. clang_format_file,
          },
        }
      else
        opts.formatters.clang_format_c = {
          command = 'clang-format',
          prepend_args = {
            '--style={' .. clang_format_style .. '}',
          },
        }
      end
    end,
  },
}
