#! /usr/bin/env janet
(import sh)

(defn- get-focus-pid
  []
  (string (sh/$$_ ["xdotool" "getwindowfocus" "getwindowpid"])))

(defn- get-focus-prog
  []
  (->> 
    (sh/$$_ ["ps" "-o" "comm,args" "-p" (get-focus-pid)])
    (string/split "\n" )
    (last)))

(defn get-focus-wintitle
  []
  (string (sh/$$_ ["xdotool" "getactivewindow" "getwindowname"])))

(defn get-selection
  []
  (-> 
    (sh/$$ ["xclip" "-o"])
    (string)))

(defn main [& args]
  (def logfile (os/getenv "PLUMBTOOL_LOG"))
  (def runscript (or (os/getenv "PLUMBTOOL_RUNSCRIPT")
                      (string (os/getenv "HOME") "/.plumbtool.janet")))
  
  (when logfile
    (def o (file/open logfile :w))
    (setdyn :out o)
    (setdyn :err o))

  (try
    (do 
      (setdyn :plumbtool/invocation (array/slice args 1))
      (setdyn :plumbtool/winprog (get-focus-prog))
      (setdyn :plumbtool/wintitle (get-focus-wintitle))
      (setdyn :plumbtool/selection (get-selection))
      (eval-string (slurp runscript)))
    ([err f] (debug/stacktrace f err))))
