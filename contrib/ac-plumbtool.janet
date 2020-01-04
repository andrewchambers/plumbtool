(import sh)

# Arguments passed to plumbtool,
# use this in your window manager to distinguish between hotkeys.
(def invocation (dyn :plumbtool/invocation))

# The program + args of the focused window.
(def winprog (dyn :plumbtool/winprog))

# The focused window title.
(def wintitle (dyn :plumbtool/wintitle))

# The current window selection.
(def selection (dyn :plumbtool/selection))

(var cwd (os/getenv "HOME"))

(defn expand-path
  [p &opt rel-to]
  (default rel-to cwd)
  (string 
    (case (get p 0)
      ("/" 0)
        (sh/$$ ["readlink" "-n" "-m" p])
      ("~" 0)
        (sh/$$ ["readlink" "-n" "-m" (string (os/getenv "HOME") "/" (string/slice p 1))])
      (sh/$$ ["readlink" "-n" "-m" (string rel-to "/" p)]))))

(defn extract-cwd
  [p]
  (when-let
    [p (expand-path p)
     st (os/stat p)]
    (if (= (get st :mode) :directory)
      p
      (string (sh/$$_ ["dirname" p])))))

(def cwd-peg ~{
  :main
    (choice
      (sequence "ac@black: " (cmt (capture (any 1)) ,extract-cwd))
      (sequence 
        (cmt (capture (some (sequence (not " - Sublime Text") 1))) ,extract-cwd) " - Sublime Text"))
  })

(defn guess-cwd
  []
  (when-let [t (peg/match cwd-peg wintitle)]
    (first t)))

(when-let [focus-cwd (guess-cwd)]
  (set cwd focus-cwd))

(defn match-local-file
  [s]

  (defn is-local-file
    [p]
    (def absp (expand-path p))
    (when (os/stat absp)
      absp))
  
  (def fmatch-peg ~{
    :pos 
      (choice
        (sequence ":" (capture :d+) ":" (capture :d+))
        (sequence ":" (capture :d+) ":")
        (sequence ":" (capture :d+))
        (sequence "] on line " (capture :d+) ", column " (capture :d+)))

    :fname 
        (cmt (capture (some (sequence (not :pos) 1))) ,is-local-file)

    :main
      (choice
        (sequence :fname :pos)
        (sequence "[" :fname :pos)
        :fname)
    })
  
  (peg/match fmatch-peg s))

(when (= (get invocation 0) "repl")
  (sh/$ ["tmux" "send" "-t" "repl.0" "-l" selection])
  (sh/$ ["tmux" "send" "-t" "repl.0" "Enter"])
  (os/exit 0))

(when (= (get invocation 0) "go")
  (when-let [f (match-local-file selection)]
    (sh/$ ["subl" "-b" (string/join f ":")])
    (os/exit 0))
  (when (or (string/has-prefix? "http://" selection)
            (string/has-prefix? "https://" selection))
    (sh/$ ["xdg-open" selection])
    (os/exit 0))
  (os/exit 0))

