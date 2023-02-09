(hs.ipc.cliInstall)
(require-macros :lib.macros)

(local lg-tv "LG TV SSCR2")
(local mini-screen :HS156KC)

(local bottom-right (hs.geometry.rect 0.4 0.3 0.6 1))
(local bottom-left (hs.geometry.rect 0 0.3 0.4 1))
(local lg-layout [[:Safari nil mini-screen hs.layout.maximized nil nil]
                  [:Emacs nil lg-tv bottom-right nil nil]])

(local default-layout [[:Safari nil (hs.screen.primaryScreen) hs.layout.left50 nil nil]
                       [:Emacs nil (hs.screen.primaryScreen) hs.layout.right50 nil nil]])

(hs.grid.setGrid :5x5)
(local expose (hs.expose.new nil {:showThumbnails false}))

(fn get-layout [screen]
  (let [screen-name (: screen :name)]
    (match screen-name
      lg-tv lg-layout
      _ default-layout)))

(fn fuzzy [choices func]
  (doto (hs.chooser.new func)
    (: :searchSubText true)
    (: :fgColor {:hex "#bbf"})
    (: :subTextColor {:hex "#aaa"})
    (: :width 25)
    (: :show)
    (: :choices choices)))

(fn select-window [window]
  (when window (window.window:focus)))

(fn show-window-fuzzy [app]
  (let [app-images {}
        focused-id (: (hs.window.focusedWindow) :id)
        windows (if (= app nil) (hs.window.visibleWindows)
                  (= app true) (: (hs.application.frontmostApplication) :allWindows)
                  (= (type app) "string") (: (hs.application.open app) :allWindows)
                  (app:allWindows))
        choices #(icollect [_ window (ipairs windows)]
                  (let [win-app (window:application)]
                    (if (= (. app-images win-app) nil) ; cache the app image per app
                      (tset app-images win-app (hs.image.imageFromAppBundle (win-app:bundleID))))
                    (let [text (window:title)
                          id (window:id)
                          active (= id focused-id)
                          subText (.. (win-app:title) (if active " (active)" ""))
                          image (. app-images win-app)
                          valid (= id focused-id)]
                      {: text : subText : image : valid : window})))]
    (fuzzy choices select-window)))

(hs.hotkey.bind hyper :D #(hs.alert.show (: (hs.screen.primaryScreen) :name)))
(hs.hotkey.bind hyper :G hs.grid.show)
(hs.hotkey.bind hyper :e #(expose:toggleShow))
(hs.hotkey.bind hyper hs.keycodes.map.space #(show-window-fuzzy))

(hs.hotkey.bind hyper :l
                #(hs.layout.apply (get-layout (hs.screen.primaryScreen))))

(hs.hotkey.bind [:ctrl :cmd] "`" nil
                (fn []
                  (if-let [console (hs.console.hswindow)]
                          (when (= console (hs.console.hswindow))
                            (hs.closeConsole))
                          (hs.openConsole))))
