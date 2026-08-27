return {
  {
    'stevearc/conform.nvim',

    opts = function(_, opts)
      -- ======================================================================
      -- C / C++ FORMATTER
      -- ======================================================================
      --
      -- clangd  -> language server
      -- clang-format -> formatter
      -- conform.nvim -> runs the formatter
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
      -- Available built-in presets include:
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

      opts.formatters.clang_format = {
        prepend_args = {
          [[--style={

            # ==================================================================
            # BASE STYLE
            # ==================================================================

            BasedOnStyle: LLVM,


            # ==================================================================
            # INDENTATION
            # ==================================================================

            # Number of spaces per indentation level.
            #
            # Common choices:
            #
            #   2
            #   4
            #   8
            #
            # 4 is a common C++ choice.
            #
            IndentWidth: 4,

            # Number of spaces represented by a tab.
            #
            TabWidth: 4,

            # Whether clang-format should use actual tab characters.
            #
            # Never:
            #   Always use spaces.
            #
            # ForIndentation:
            #   Tabs may be used for indentation.
            #
            # Always:
            #   Prefer tabs.
            #
            UseTab: Never,

            # Indent the contents of switch cases.
            #
            # true:
            #
            #   switch (x)
            #   {
            #       case 1:
            #           foo();
            #           break;
            #   }
            #
            # false:
            #
            #   switch (x)
            #   {
            #   case 1:
            #       foo();
            #       break;
            #   }
            #
            IndentCaseLabels: true,

            # Indent access modifiers relative to the class.
            #
            # With -4:
            #
            #   class Foo
            #   {
            #   private:
            #       int x;
            #
            #   public:
            #       void foo();
            #   };
            #
            AccessModifierOffset: -4,


            # ==================================================================
            # BRACES
            # ==================================================================

            # Where opening braces are placed.
            #
            # Allman:
            #
            #   if (condition)
            #   {
            #       foo();
            #   }
            #
            # Attach:
            #
            #   if (condition) {
            #       foo();
            #   }
            #
            # Other major styles:
            #
            #   Stroustrup
            #   GNU
            #
            BreakBeforeBraces: Attach,

            # Allow empty functions on one line.
            #
            #   Foo() {}
            #
            # Options include:
            #
            #   None
            #   Empty
            #   Inline
            #   InlineOnly
            #
            AllowShortFunctionsOnASingleLine: Empty,

            # Don't put short if statements on one line.
            #
            # false would allow things like:
            #
            #   if (x) foo();
            #
            AllowShortIfStatementsOnASingleLine: Never,

            # Don't collapse short loops.
            #
            # false keeps:
            #
            #   while (x)
            #   {
            #       foo();
            #   }
            #
            # rather than:
            #
            #   while (x) foo();
            #
            AllowShortLoopsOnASingleLine: true,

            # Don't collapse arbitrary short blocks.
            #
            AllowShortBlocksOnASingleLine: true,


            # ==================================================================
            # LINE LENGTH
            # ==================================================================

            # Preferred maximum line length.
            #
            # Common choices:
            #
            #   80
            #   100
            #   120
            #
            # 0 means no column limit.
            #
            ColumnLimit: 0,


            # ==================================================================
            # SPACING
            # ==================================================================

            # Spaces before parentheses.
            #
            # Control:
            #
            #   if (condition)
            #   while (condition)
            #   for (condition)
            #
            # Function calls remain:
            #
            #   foo();
            #
            SpaceBeforeParens: Control,

            # Spaces inside parentheses.
            #
            # false:
            #
            #   foo(x, y);
            #
            # true:
            #
            #   foo( x, y );
            #
            SpacesInParentheses: false,

            # Spaces inside square brackets.
            #
            # false:
            #
            #   array[index]
            #
            SpacesInSquareBrackets: false,

            # Spaces inside empty parentheses.
            #
            #   foo()
            #
            SpacesInEmptyParentheses: false,

            # Spaces around assignment operators.
            #
            #   x = 10;
            #
            SpaceBeforeAssignmentOperators: true,


            # ==================================================================
            # POINTERS
            # ==================================================================

            # Where * is placed.
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
            PointerAlignment: Left,


            # ==================================================================
            # REFERENCES
            # ==================================================================

            # Where & is placed.
            #
            # Left:
            #
            #   int& value;
            #
            # Right:
            #
            #   int &value;
            #
            ReferenceAlignment: Left,


            # ==================================================================
            # FUNCTION PARAMETERS / ARGUMENTS
            # ==================================================================

            # Keep function arguments on the same line when possible.
            #
            # true:
            #
            #   foo(first, second, third);
            #
            # false tends toward:
            #
            #   foo(
            #       first,
            #       second,
            #       third);
            #
            BinPackArguments: true,

            # Keep function parameters on the same line when possible.
            #
            #   void foo(int a, int b, int c);
            #
            BinPackParameters: true,


            # ==================================================================
            # CONSTRUCTORS
            # ==================================================================

            # Indentation of constructor initializer lists.
            #
            # Example:
            #
            #   Rectangle(int length, int width)
            #       : length(length),
            #         width(width)
            #   {
            #   }
            #
            ConstructorInitializerIndentWidth: 4,

            # How constructor initializers are packed.
            #
            # BinPack:
            #
            #   Foo()
            #       : a(1), b(2), c(3)
            #
            PackConstructorInitializers: BinPack,


            # ==================================================================
            # CLASSES
            # ==================================================================

            # Namespace indentation.
            #
            # None:
            #
            #   namespace foo
            #   {
            #   class Bar
            #   {
            #   };
            #   }
            #
            # All:
            #
            #   namespace foo
            #   {
            #       class Bar
            #       {
            #       };
            #   }
            #
            NamespaceIndentation: None,

            # Where a class inheritance list breaks.
            #
            # Example:
            #
            #   class Square
            #       : public Shape
            #   {
            #   };
            #
            BreakInheritanceList: BeforeColon,


            # ==================================================================
            # TEMPLATES
            # ==================================================================

            # Always put template declarations on their own line.
            #
            #   template <typename T>
            #   class Foo
            #   {
            #   };
            #
            AlwaysBreakTemplateDeclarations: Yes,


            # ==================================================================
            # INCLUDES
            # ==================================================================

            # Automatically sort includes.
            #
            # Options:
            #
            #   Never
            #   CaseSensitive
            #   CaseInsensitive
            #
            SortIncludes: CaseSensitive,

            # Regroup include blocks.
            #
            # Useful when you want system/project includes separated.
            #
            IncludeBlocks: Regroup,


            # ==================================================================
            # COMMENTS
            # ==================================================================

            # Allow clang-format to reflow comments.
            #
            # true:
            #   Long comments may be wrapped.
            #
            # false:
            #   Leave comment wrapping alone.
            #
            ReflowComments: true,

            # Align trailing comments.
            #
            # Example:
            #
            #   int x = 1;          // value
            #   int longVariable;   // another value
            #
            AlignTrailingComments: true,


            # ==================================================================
            # EMPTY LINES
            # ==================================================================

            # Maximum consecutive blank lines.
            #
            # 0 = no blank lines
            # 1 = one blank line
            # 2 = two blank lines
            #
            MaxEmptyLinesToKeep: 1,


            # ==================================================================
            # OPERATORS
            # ==================================================================

            # Where binary operators go when lines wrap.
            #
            # None:
            #
            #   auto result = first + second +
            #                 third;
            #
            # Beginning:
            #
            #   auto result = first + second
            #                 + third;
            #
            BreakBeforeBinaryOperators: None,

            # Formatting of ternary operators.
            #
            BreakBeforeTernaryOperators: false,


            # ==================================================================
            # STRING LITERALS
            # ==================================================================

            # Allow clang-format to break long string literals.
            #
            # false:
            #   Don't split them.
            #
            BreakStringLiterals: false,


            # ==================================================================
            # C++ STANDARD
            # ==================================================================

            # Formatting language standard.
            #
            # Options include:
            #
            #   Cpp03
            #   Cpp11
            #   Cpp14
            #   Cpp17
            #   Cpp20
            #   Cpp23
            #   Latest
            #
            Standard: Latest,

            # C++11 braced initializer formatting.
            #
            Cpp11BracedListStyle: true,


            # ==================================================================
            # ALIGNMENT
            # ==================================================================

            # Align consecutive assignments?
            #
            # false:
            #
            #   int x = 1;
            #   int longerName = 2;
            #
            # true:
            #
            #   int x          = 1;
            #   int longerName = 2;
            #
            AlignConsecutiveAssignments: None,

            # Align consecutive declarations?
            #
            AlignConsecutiveDeclarations: None,

            # Align consecutive macros?
            #
            AlignConsecutiveMacros: None,


            # ==================================================================
            # ACCESS MODIFIERS
            # ==================================================================

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
            EmptyLineBeforeAccessModifier: LogicalBlock,


            # ==================================================================
            # NAMESPACES
            # ==================================================================

            # Add comments to namespace closing braces.
            #
            #   } // namespace foo
            #
            FixNamespaceComments: true,

          }]],
        },
      }
    end,
  },
}

