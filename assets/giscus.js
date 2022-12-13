const initAll = () => {
    const path = window.location.pathname
    if (path.endsWith("/print.html")) {
        return
    }

    document
        .getElementById("theme-list")
        .addEventListener("click", function (e) {
            const iframe = document.querySelector(".giscus-frame")

            if (!iframe) return

            let theme
            if (e.target.className === "theme") {
                theme = e.target.id
            } else {
                return
            }
            // const availableThemes = [
            //   "light",
            //   "light_high_contrast",
            //   "light_protanopia",
            //   "dark",
            //   "dark_high_contrast",
            //   "dark_protanopia",
            //   "dark_dimmed",
            //   "transparent_dark",
            //   "preferred_color_scheme",
            //   "custom",
            // ];

            //// mdbook-theme != light|rust { giscus-theme = transparent_dark}
            let giscusTheme

            switch (theme) {
                case "light":
                case "rust":
                    giscusTheme = "light"
                    break
                default:
                    giscusTheme = "transparent_dark"
                    break
            }

            const msg = {
                setConfig: {
                    theme: giscusTheme,
                },
            }
            iframe.contentWindow.postMessage(
                { giscus: msg },
                "https://giscus.app",
            )
        })

    // add vistors count
    const ele = document.createElement("div")
    ele.setAttribute("align", "center")

    const count = document.createElement("img")
    count.setAttribute(
        "src",
        `https://visitor-badge.glitch.me/badge?page_id=${path}`,
    )
    ele.appendChild(count)

    const divider = document.createElement("hr")

    document.getElementById("giscus-container").appendChild(ele)
    document.getElementById("giscus-container").appendChild(divider)

    // set giscus dark-theme
    let theme = "transparent_dark"

    const themeClass = document.getElementsByTagName("html")[0].className
    if (
        themeClass.indexOf("light") !== -1 ||
        themeClass.indexOf("rust") !== -1
    ) {
        theme = "light"
    }

    const script = document.createElement("script")
    script.type = "text/javascript"

    /* 
  https://github.com/giscus/giscus/blob/main/LICENSE
  License: MIT
  Copyright (c) 2021 Sage M. Abdullah
  Copyright (c) 2018 Jeremy Danyow
  Copyright (c) 2018 Chris Veness
*/
    script.src = "https://giscus.app/client.js"
    script.async = true
    script.crossOrigin = "anonymous"
    script.setAttribute("data-repo", "2moe/tmoe")
    script.setAttribute("data-repo-id", "MDEwOlJlcG9zaXRvcnkyNTQxOTAxMzU=")
    script.setAttribute("data-category", "Doc")
    script.setAttribute("data-category-id", "DIC_kwDODyaiN84CPBPv")
    script.setAttribute("data-mapping", "pathname")
    script.setAttribute("data-reactions-enabled", "1")
    script.setAttribute("data-emit-metadata", "0")
    script.setAttribute("data-input-position", "bottom")
    script.setAttribute("data-theme", theme)

    const language = navigator.language || navigator.languages[0]
    const lang_slice = language.slice(0, 2).toLowerCase()

    // availableLanguages： https://github.com/giscus/giscus/blob/main/lib/i18n.tsx
    // ar: 'العربية',
    // de: 'Deutsch',
    // en: 'English',
    // es: 'Español',
    // fr: 'Français',
    // id: 'Indonesia',
    // it: 'Italiano',
    // ja: '日本語',
    // ko: '한국어',
    // nl: 'Nederlands',
    // pl: 'Polski',
    // pt: 'Português',
    // ro: 'Română',
    // ru: 'Русский',
    // th: 'ภาษาไทย',
    // tr: 'Türkçe',
    // vi: 'Việt Nam',
    // 'zh-CN': '简体中文',
    // 'zh-TW': '繁體中文',

    const get_region = () => language.slice(-2).toUpperCase()

    let lang

    const match_zh = (slice) => {
        const region = get_region()
        switch (region) {
            case "HK":
            case "TW":
                return `${slice}-${region}`
            default:
                return slice
        }
    }

    // const match_de = () => {
    //     if (get_region() === "CH") {
    //         return "gsw"
    //     } else {
    //         return "de"
    //     }
    // }

    switch (lang_slice) {
        case "zh":
            lang = match_zh(lang_slice)
            break
        case "de":
        case "gsw":
            // lang = match_de()
            lang = "de"
            break
        case "ar":
        case "es":
        case "fr":
        case "id":
        case "it":
        case "ja":
        case "ko":
        case "pl":
        case "pt":
        case "ro":
        case "ru":
        case "th":
        case "tr":
        case "vi":
            lang = lang_slice
            break
        default:
            lang = "en"
            break
    }

    script.setAttribute("data-lang", lang)
    // script.setAttribute("crossorigin", "anonymous")
    script.setAttribute("data-loading", "lazy")
    document.getElementById("giscus-container").appendChild(script)
}

self.addEventListener("load", initAll)
