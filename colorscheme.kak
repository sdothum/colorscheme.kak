# sdothum - 2016 (c) wtfpl

# Kakoune
# ══════════════════════════════════════════════════════════════════════════════

# Modal UI
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# SEE: bundle duochrome.kak.git
#      bundle lambda.kak.git

declare-option str theme 'duochrome'  # default

# ............................................................. Term colorscheme

if-else %{ [ -n "$DISPLAY" ] } %{
	declare-option str mode    ''  # initial state
	declare-option str color   ''  # force colorscheme initialization

	# dynamically match alacritty terminal background (edges) to theme SEE: duochrome

	define-command -hidden sync-terminal-bg %{
	   nop %sh{
			colors="colors.primary.background='#${kak_opt_current_background#*:}'"

			# NOTE: read current alacritty indentifiers from attached tmux session SEE: $HOME/.tmux.conf
			if [ -n "$TMUX" ]; then
				socket=$(tmux show-environment ALACRITTY_SOCKET 2>/dev/null)
				case "$socket" in
					-* | '' ) socket='' ;;
					*=*     ) socket=${socket#*=} ;;
				esac

				window=$(tmux show-environment ALACRITTY_WINDOW_ID 2>/dev/null)
				case "$window" in
					-* | '' ) window='' ;;
					*=*     ) window=${window#*=} ;;
				esac
			else
				socket=$kak_client_env_ALACRITTY_SOCKET
				window=$kak_client_env_ALACRITTY_WINDOW_ID
			fi

	      [ -n "$socket" ] &&
	      [ -n "$window" ] &&
	      alacritty msg  --socket "${socket}" config "$colors" --window-id "${window}"
	   }
	}

	define-command -hidden restore-terminal-bg %{
		set-option window current_background %sh{ echo ${TERMBG:-263238} }
		sync-terminal-bg
	}

	hook global ClientCreate .* sync-terminal-bg
	hook global ClientClose  .* restore-terminal-bg


	# NOTE: "echo" to clear statusline filename from caplock switching

	define-command -hidden normal-mode-colorscheme %{
		set-option window mode "normal"
		if %{ [ "$kak_opt_color" != "normal" ] } %{
			trace %{ normal-mode-colorscheme }
			set-option window color "normal"
			colorscheme %opt{theme}
			echo
		}
	}

	define-command -hidden insert-mode-colorscheme %{
		set-option window mode "insert"
		if %{ [ "$kak_opt_color" != "insert" ] } %{
			trace %{ insert-mode-colorscheme }
			set-option window color "insert"
			colorscheme %opt{theme}
			echo
		}
	}

	define-command -hidden capslock-colorscheme %{
		if %{ [ "$kak_opt_color" != "capslock" ] } %{
			trace %{ capslock-colorscheme }
			set-option window color "capslock"
			colorscheme %opt{theme}
			echo
		}
	}

# ............................................................... Capslock event

	# (??) capslock colorscheme switching defers until the next keystroke HACK: see sxhkdrc for Caps_Lock trigger

	define-command -hidden capslock-check %{
		trace %{ capslock-check }
		if-else %{ capslock } %{
			capslock-colorscheme
		} %{
			if-else %{ [ "$kak_opt_mode" = "insert" ] } %{
				insert-mode-colorscheme
			} %{
				normal-mode-colorscheme
			}
		}
	}

	# window modal/capslock "duo"chrome
	hook global WinCreate .* %{ normal-mode-colorscheme }

	hook global WinCreate ^[^*].* %{
		hook window ModeChange (push|pop):.*:insert insert-mode-colorscheme
		hook window ModeChange (push|pop):insert:.* normal-mode-colorscheme
		hook window InsertIdle .*                   capslock-check
		hook window NormalIdle .*                   capslock-check
		hook window PromptIdle .*                   capslock-check
	}
} %{

# .......................................................... Console colorscheme

	declare-option str theme %sh{ echo "${COLORSCHEME:-default}" }
	colorscheme %opt{theme}
}

# kak: filetype=kak
