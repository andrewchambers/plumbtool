# plumbtool
A window manager command runner and plumbing tool.

With plumbtool you can connect window manager hotkeys to a programmable janet script.

With plumbtool you can do things like:

- Open a browser for url any text on screen.
- Open a a text editor for compiler errors anywhere on screen.
- Anything you can program.

See below for examples...

# Install

Install:

- https://github.com/janet-lang/janet
- https://github.com/andrewchambers/janet-process
- https://github.com/andrewchambers/janet-sh
- xclip, coreutils and xdotool

Can be done with something like this after setting up your JANET_PATH:

```
git clone https://github.com/andrewchambers/plumbtool
cd plumbtool
jpm update-pkgs
jpm install process
jpm install sh
jpm install 
```

Currently, the only supported platform is linux with x11, but patches are welcome.

# Usage

```
plumbtool $ARGS
```

See the contrib directory, or below for examples.

## Example

### A universal repl and url opener

```
# ~/.plumbtool.janet:

(import sh)

# Arguments passed to plumbtool,
# Use this in your window manager to distinguish between hotkeys.
(def invocation (dyn :plumbtool/invocation))

# The program + args of the focused window.
# Use this to change action based on which program is open.
(def winprog (dyn :plumbtool/winprog))

# The focused window title.
# One use of this is to guess the working directory for your text editor.
(def wintitle (dyn :plumbtool/wintitle))

# The current window selection.
# Lets you send the selection to other programs, like the tmux repl below.
(def selection (dyn :plumbtool/selection))

(when (= (get invocation 0) "repl")
  (sh/$ ["tmux" "send" "-t" "repl.0" "-l" selection])
  (sh/$ ["tmux" "send" "-t" "repl.0" "Enter"])
  (os/exit 0))

(when (= (get invocation 0) "go")
  (when (or (string/has-prefix? "http://" selection)
            (string/has-prefix? "https://" selection))
    (sh/$ ["xdg-open" selection]))
  (os/exit 0))
```

Then from your window manager, bind the following hotkeys:

```
ctrl+r -> plumbtool repl
ctrl+g -> plumbtool go
```

Start a repl terminal session with:
```
tmux new -s repl
```

When you type ctrl+r the selected text will be sent to a tmux session named repl.
When you type ctrl+g when a url is selected, your browser will open.

## Env vars

### PLUMBTOOL_LOG

If set, the output of your plumbtool script is written here
after a hotkey is pressed for debug purposes.


### PLUMBTOOL_RUNSCRIPT

The path to the janet script to run when executed.

defaults to ```(string (os/getenv "HOME") "/.plumbtool.janet")```.


