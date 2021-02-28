# Minecraft function file language support, brought to you by Lue and released
# under the 0BSD license! Reuse whatever you want; no attribution required!

# Set filetype based on file extension.
hook global BufCreate .*[.]mcfunction %{
    set-option buffer filetype mcfunction
}

# Initialize indentation hooks.
hook global WinSetOption filetype=mcfunction %{
    require-module mcfunction

    hook window ModeChange pop:insert:.* -group mcfunction-trim-indent mcfunction-trim-indent
    hook window InsertChar \n -group mcfunction-indent mcfunction-indent-on-new-line
    hook -once -always window WinSetOption filetype=.* %{ remove-hooks window mcfunction-.+ }
}

# Initialize mcfunction syntax highlighting.
hook -group mcfunction-highlight global WinSetOption filetype=mcfunction %{
    add-highlighter window/mcfunction ref mcfunction/main
    hook -once -always window WinSetOption filetype=.* %{ remove-highlighter window/mcfunction }
}

# Define syntax highlighters and provide indentation utilities.
provide-module mcfunction %❤
    add-highlighter shared/mcfunction       group
    add-highlighter shared/mcfunction/main  regions
    add-highlighter shared/mcfunction/main/ region '^[\t ]*\K(?=#).+$' '$' fill comment
    add-highlighter shared/mcfunction/main/ region '^[\t ]*\K(?!#).+$' '$' ref mcfunction/root

    add-highlighter shared/mcfunction/root  regions
    add-highlighter shared/mcfunction/root/ region '^[\t ]*\K(?!say[\t ])[^\t\n #]' '$|(?=[\t ])' regex '(?:[a-z0-9_.-]*:)?[a-z0-9_./-]*([^\t\n a-z0-9_.-][^\t\n ]*)?' 0:keyword 1:error
    add-highlighter shared/mcfunction/root/ region '^[\t ]*\Ksay[\t ]' '$' regex '(say)[\t ]*([^\t ].*)?' 1:keyword 2:string
    add-highlighter shared/mcfunction/root/ default-region ref mcfunction/params

    add-highlighter shared/mcfunction/params        regions
    add-highlighter shared/mcfunction/params/run    region '(?<=[\t ])run(?:$|[\t ]+)' '$' regions
    add-highlighter shared/mcfunction/params/run/   region 'run[\t ]*(?!say[\t ])[^\t ]' '$|(?=[\t ])' regex '(run)[\t ]*\K(?:[a-z0-9_.-]*:)?[a-z0-9_./-]*([^\t a-z0-9_.-][^\t ]*)?' 0:keyword 1:function 2:error
    add-highlighter shared/mcfunction/params/run/   region 'run[\t ]+say[\t ]' '$' regex '(run)[\t ]+(say)[\t ]*([^\t ].*)?' 1:function 2:keyword 3:string
    add-highlighter shared/mcfunction/params/run/   region '[\t ]' '$' ref mcfunction/params

    add-highlighter shared/mcfunction/params/subcmd     region '(?<=[\t ])[a-z]+(?:$|(?=[\t ]))' '\K' regex '(?<=[\t ])(?:(true|false)|([^\t ]+))(?:$|(?=[\t ]))' 1:value 2:function
    add-highlighter shared/mcfunction/params/string     region -match-capture -recurse '(?<!\\)(?:\\\\)*\\([''"])' '(?<=[\t .,;:=\[\{])([''"])' '$|([''"])' fill string
    add-highlighter shared/mcfunction/params/selector   region '(?<=[\t ])@[a-z](?:$|(?=[\t \[]))' '\K' fill value
    add-highlighter shared/mcfunction/params/variable   region '(?<=[\t ])(?:(?:[\^~]-?[0-9]*[.]?[0-9]*|[+-]?(?:[0-9]+(?:[.][0-9]*)?|[0-9]*[.][0-9]+)(?:[eE][+-]?[0-9]*)?[DdFfts]?|[+-]?[0-9]+[BbSLl]|-?[0-9]+[.]{2}(?:-[0-9]+)?|(?:-[0-9]+)?[.]{2}-?[0-9]+)(?:$|(?=[\t ]))\K)|(?<=[\t ,;\[])[a-z0-9]*[$#A-Z0-9_.+-][$#A-Za-z0-9_.+-]*(?:$|(?=[\t ,;]))|(?<=[.])[A-Za-z0-9_+-]+(?:$|(?=[\t .,;\[\{\}\]]))|(?<=[\t ,;:=\[])[A-Za-z0-9_+-]+(?=[\{\[.]))' '\K' fill variable
    add-highlighter shared/mcfunction/params/selkey     region '[\{\[,;][\t ]*(?:[A-Za-z0-9_.+-]+|(?:[a-z0-9_.-]*:)?[a-z0-9_./-]+)(?:$|(?==)|[\t ]*(?=[,\]]))' '\K' regex '(?<![A-Za-z0-9_.+-])(?:(?:(true|false|[0-9]+(?:[.][0-9]*)?(?:[eE][+-]?[0-9]*)?[DdFf]?|(?:[0-9]*[.])?[0-9]+(?:[eE][+-]?[0-9]*)?[DdFfts]?|[0-9]+[BbSLl]))[\t ]*(?![\t =A-Za-z0-9_.+-])|([A-Za-z0-9_.+-]+)[\t ]*(?![\t A-Za-z0-9_.+-]))' 1:value 2:variable
    add-highlighter shared/mcfunction/params/badkey     region '(?<=[^\t \{\[,])[\t ]*[^\t ":=,\[\{\}\]%<>/*+-]+(?==)' '\K' regex '[\t ]*(.+)' 1:error
    add-highlighter shared/mcfunction/params/nbtkey     region '[\{,][\t ]*[A-Za-z0-9_.+-]+(?:[^\t :,\[\{\}\]A-Za-z0-9_.+-][^\t :=,\[\{\}\]]*)?(?:$|(?=[\t :=,\[\{\}\]]))' '\K' regex '[\{,][\t ]*(?:([A-Za-z0-9_.+-]+)([^A-Za-z0-9:=_.+-].*)?(?:$|(?=[\t ,:=\]]))|([^\t ]+(?=[,\[\{\}])))' 1:variable 2:error 3:error
    add-highlighter shared/mcfunction/params/rawstr     region '=#?[a-z0-9_.-]*[:/]\K|[:=][\t ]*(?:[\^~]-?[0-9]*[.]?[0-9]*|!?[A-Za-z0-9_.+-]+)(?:[^\t :=,\[\{\}\]A-Za-z0-9_.+-][^\t :=,\[\{\}\]]*)?(?:$|(?=[\t :=,\[\{\}\]]))' '\K' regex '[:=][\t ]*(?:(?:(true|false|(?:[\^~]-?[0-9]*[.]?[0-9]*|[+-]?(?:[0-9]+(?:[.][0-9]*)?|[0-9]*[.][0-9]+)(?:[eE][+-]?[0-9]*)?[DdFfts]?|[+-]?[0-9]+[BbSLl]|-?[0-9]+[.]{2}(?:-[0-9]+)?)|(?:(?:-[0-9]+)?[.]{2}-?[0-9]+)))|!?([A-Za-z0-9_.+-]+)([^A-Za-z0-9:=_.+-].*)?)(?:$|(?=[\t ,\]\}]))|([^\t ]+(?=[:=\[\{])))' 1:value 2:function 3:error 4:error
    add-highlighter shared/mcfunction/params/namespaced region '(?<=[\t ])/=(?:(?=[\t ]|$)\K|(?:(?<==)[\t ]*#[a-z0-9_.-]|(?<![\t ,:\[\{\}\]"])[\t ]*#?[a-z0-9_.-]*[:/])[^,\[\{\}\]\t ]*(?:$|(?=[\t ,\[\{\}\]]))' '\K' regex '(?<![\t ,:\[\{])[\t ]*(#?(?:[a-z0-9_.-]*:)?[a-z0-9_./-]*)([^,\[\{\}\]\t a-z0-9_.-][^,\[\{\}\]\t ]*)?(?:$|(?=[\t ,\[\{\}\]]))' 1:type 2:error
    add-highlighter shared/mcfunction/params/numeric    region '(?<=[\t ])(?:[\^~]-?[0-9]*[.]?[0-9]*|[+-]?(?:[0-9]+(?:[.][0-9]*)?|[0-9]*[.][0-9]+)(?:[eE][+-]?[0-9]*)?[DdFfts]?|[+-]?[0-9]+[BbSLl]|-?[0-9]+[.]{2}(?:-[0-9]+)?|(?:(?:-[0-9]+)?[.]{2}-?[0-9]+))(?:$|(?=[\t ]))' '\K' fill value

    define-command -hidden mcfunction-trim-indent %{
        # Remove trailing whitespace.
        try %{ execute-keys -draft -itersel <a-x> s \h+$ <ret> d }
    }

    define-command -hidden mcfunction-indent-on-new-line %{
        evaluate-commands -draft -itersel %{
            # Copy '#' comment prefix and following white spaces.
            try %{ execute-keys -draft k <a-x> s ^\h*\K#\h* <ret> y gh j P }
            # Preserve previous line indent.
            try %{ execute-keys -draft <semicolon> K <a-&> }
            # Filter previous line.
            try %{ execute-keys -draft k : mcfunction-trim-indent <ret> }
        }
    }
❤
