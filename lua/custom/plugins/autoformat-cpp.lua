return {
  {
    'stevearc/conform.nvim',

    opts = function(_, opts)
      -- ======================================================================
      -- C / C++ FORMATTER
      -- ======================================================================
      --
      -- clangd        -> language server
      -- clang-format  -> code formatter
      -- conform.nvim  -> runs clang-format
      --
      -- This file contains the C/C++ formatting configuration.
      --
      -- ======================================================================

      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters = opts.formatters or {}

      -- ----------------------------------------------------------------------
      -- Filetypes
      -- ----------------------------------------------------------------------

      opts.formatters_by_ft.cpp = { 'clang_format' }
      opts.formatters_by_ft.c = { 'clang_format' }
      opts.formatters_by_ft.objc = { 'clang_format' }
      opts.formatters_by_ft.objcpp = { 'clang_format' }

      -- ======================================================================
      -- clang-format
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

# Move access modifiers relative to normal class indentation.
#
# With -4:
#
#   class Foo
#   {
#   private:
#       int value;
#
#   public:
#       void foo();
#   };
#
AccessModifierOffset: -4


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
BreakBeforeBraces: Attach

# Allow completely empty functions to stay on one line.
#
#   Foo() {}
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
#   if (x)
#   {
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
PointerAlignment: Left


# ======================================================================
# REFERENCES
# ======================================================================

# Put & next to the type.
#
# Left:
#
#   int& value;
#
# Right:
#
#   int &value;
#
ReferenceAlignment: Left


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
# CONSTRUCTORS
# ======================================================================

# Number of spaces used to indent constructor initializers.
#
# Example:
#
#   Rectangle(int length, int width)
#       : length(length),
#         width(width)
#   {
#   }
#
ConstructorInitializerIndentWidth: 4

# How constructor initializers are packed.
#
# BinPack:
#
#   Foo()
#       : a(1), b(2), c(3)
#
#
# Example:
#
#   Rectangle(int length, int width)
#       : length(length),
#         width(width)
#   {
#   }
#
# instead of packing them like:
#
#   Rectangle(int length, int width) : length(length),
#                                      width(width) {}
#
# PackConstructorInitializers: BinPack
# PackConstructorInitializers: CurrentLine

# Always break constructor initializer lists onto their own lines.
#
#   Rectangle(int length, int width)
#       : length(length),
#         width(width)
#   {
#   }
#
PackConstructorInitializers: Never


# ======================================================================
# CLASSES
# ======================================================================

# Don't add indentation inside namespaces.
#
# namespace foo
# {
# class Foo
# {
# };
# }
#
NamespaceIndentation: None

# How inheritance lists are broken.
#
# Example:
#
#   class Square
#       : public Shape
#   {
#   };
#
BreakInheritanceList: BeforeColon


# ======================================================================
# TEMPLATES
# ======================================================================

# Put template declarations on their own line.
#
#   template <typename T>
#   class Foo
#   {
#   };
#
AlwaysBreakTemplateDeclarations: Yes


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
#   int longerName = 2; // another value
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
#   auto result = first + second +
#                 third;
#
# Beginning would produce:
#
#   auto result = first + second
#                 + third;
#
BreakBeforeBinaryOperators: None

# Keep ternary operators in the conventional position.
#
#   auto result = condition ? first : second;
#
BreakBeforeTernaryOperators: false


# ======================================================================
# STRING LITERALS
# ======================================================================

# Don't automatically split long string literals.
#
BreakStringLiterals: false


# ======================================================================
# C++ STANDARD
# ======================================================================

# Formatting language standard.
#
# Options:
#
#   Cpp03
#   Cpp11
#   Cpp14
#   Cpp17
#   Cpp20
#   Cpp23
#   Latest
#
Standard: Latest

# Use C++11-style braced initializer formatting.
#
Cpp11BracedListStyle: true


# ======================================================================
# ALIGNMENT
# ======================================================================

# Don't align consecutive assignments.
#
#   int x = 1;
#   int longerName = 2;
#
# instead of:
#
#   int x          = 1;
#   int longerName = 2;
#
AlignConsecutiveAssignments: None

# Don't align consecutive declarations.
#
AlignConsecutiveDeclarations: None

# Don't align consecutive macros.
#
AlignConsecutiveMacros: None


# ======================================================================
# ACCESS MODIFIERS
# ======================================================================

# Add a blank line before logical access-modifier sections.
#
#   class Foo
#   {
#   private:
#       int value;
#
#   public:
#       void foo();
#   };
#
EmptyLineBeforeAccessModifier: LogicalBlock


# ======================================================================
# NAMESPACES
# ======================================================================

# Add a comment when closing a namespace.
#
#   } // namespace foo
#
FixNamespaceComments: true
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
        local clang_format_file = cache_dir .. '/clang-format.nvim.yaml'

        -- Make sure the cache directory exists.
        vim.fn.mkdir(cache_dir, 'p')

        -- Write valid YAML to the configuration file.
        vim.fn.writefile(
          vim.split(clang_format_style, '\n', { plain = true }),
          clang_format_file
        )

        opts.formatters.clang_format = {
          prepend_args = {
            '--style=file:' .. clang_format_file,
          },
        }
      else
        -- clang-format's inline style syntax uses a flow mapping.
        --
        -- The YAML file above intentionally has NO trailing commas.
        -- For the inline form, clang-format accepts commas between entries.
        --
        -- Convert the YAML key/value lines into the flow-mapping form by
        -- simply passing the YAML document inside braces.
        --
        -- clang-format accepts the multi-line mapping on Linux/macOS.

        opts.formatters.clang_format = {
          prepend_args = {
            '--style={' .. clang_format_style .. '}',
          },
        }
      end
    end,
  },
}
