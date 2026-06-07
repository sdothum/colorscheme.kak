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

	# match terminal background (edges) to theme SEE: duochrome
	define-command -hidden sync-terminal-bg %{
		if-else %{ [ "$kak_history_id" -eq 1 ] } %{
			# readonly (manpage) windows have no bg sync issues BECAUSE: mirrored clients to kak manpage session
			nop %sh{ pgrep -x gaps >/dev/null || alacritty msg config "colors.primary.background='#${kak_opt_current_background#*:}'" }
		} %{
			# socket/window_id for bg sync with multiple editing windows SEE: kakrc for tickling bg color syncing
			# NOTE: 2>/dev/null to ignore misleading alacritty toml messages to *debug*
			# VARIANT: alacritty msg -s $<socket> config -w $<window_id> -- "<setting>='$<value>'" (config -w with double dash '--' BEFORE settings)
			nop %sh{ pgrep -x gaps >/dev/null || alacritty msg -s $kak_client_env_ALACRITTY_SOCKET config "colors.primary.background='#${kak_opt_current_background#*:}'" -w $kak_client_env_ALACRITTY_WINDOW_ID 2>/dev/null }
		}
	}

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
