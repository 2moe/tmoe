let initAll = function () {
  let path = window.location.pathname;
  if (path.endsWith("/print.html")) {
    return;
  }

  document.getElementById("theme-list").addEventListener("click", function (e) {
    let iframe = document.querySelector(".giscus-frame");
    if (!iframe) return;
    let theme;
    if (e.target.className === "theme") {
      theme = e.target.id;
    } else {
      return;
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
    /// mdbook-theme != light|rust { giscus-theme = transparent_dark}
    switch (theme) {
      case "light":
      case "rust":
        var giscusTheme = "light";
        break;
      default:
        var giscusTheme = "transparent_dark";
        break;
    }

    let msg = {
      setConfig: {
        theme: giscusTheme,
      },
    };
    iframe.contentWindow.postMessage({ giscus: msg }, "https://giscus.app");
  });

  // add vistors count
  let ele = document.createElement("div");
  ele.setAttribute("align", "center");
  let count = document.createElement("img");
  count.setAttribute(
    "src",
    "https://visitor-badge.glitch.me/badge?page_id=" + path
  );
  ele.appendChild(count);
  let divider = document.createElement("hr");

  document.getElementById("giscus-container").appendChild(ele);
  document.getElementById("giscus-container").appendChild(divider);

  // language
  const lang = navigator.language || navigator.languages[0];
  // set giscus dark-theme
  let theme = "transparent_dark";
  const themeClass = document.getElementsByTagName("html")[0].className;
  if (themeClass.indexOf("light") != -1 || themeClass.indexOf("rust") != -1) {
    let theme = "light";
  }

  let script = document.createElement("script");
  script.type = "text/javascript";
  /* 
  https://github.com/giscus/giscus/blob/main/LICENSE
  License: MIT
  Copyright (c) 2021 Sage M. Abdullah
  Copyright (c) 2018 Jeremy Danyow
  Copyright (c) 2018 Chris Veness
  */
  script.src = "https://giscus.app/client.js";
  script.async = true;
  script.crossOrigin = "anonymous";
  script.setAttribute("data-repo", "2moe/tmoe");
  script.setAttribute("data-repo-id", "MDEwOlJlcG9zaXRvcnkyNTQxOTAxMzU=");
  script.setAttribute("data-category", "Doc");
  script.setAttribute("data-category-id", "DIC_kwDODyaiN84CPBPv");
  script.setAttribute("data-mapping", "pathname");
  script.setAttribute("data-reactions-enabled", "1");
  script.setAttribute("data-emit-metadata", "0");
  script.setAttribute("data-input-position", "bottom");
  script.setAttribute("data-theme", theme);
  //   const availableLanguages = {
  //       de: 'Deutsch',
  //       gsw: 'Deutsch (Schweiz)',
  //       en: 'English',
  //       es: 'Español',
  //       fr: 'Français',
  //       id: 'Indonesia',
  //       it: 'Italiano',
  //       ja: '日本語',
  //       ko: '한국어',
  //       pl: 'Polski',
  //       ro: 'Română',
  //       ru: 'Русский',
  //       tr: 'Türkçe',
  //       vi: 'Việt Nam',
  //       'zh-CN': '简体中文',
  //       'zh-TW': '繁體中文',
  //     }
  switch (lang) {
    case "zh-HK":
    case "zh-TW":
      var language = "zh-TW";
      break;
    case (lang.match(/^zh/) || {}).input:
      var language = "zh-CN";
      break;
    case "de-CH":
      var language = "gsw";
      break;
    case (lang.match(/^de/) || {}).input:
      var language = "de";
      break;
    case "ja":
    case "ja-JP":
      var language = "ja";
      break;
    case (lang.match(/^es/) || {}).input:
      var language = "es";
      break;
    case (lang.match(/^fr/) || {}).input:
      var language = "fr";
      break;
    case (lang.match(/^ko/) || {}).input:
      var language = "ko";
      break;
    case (lang.match(/^id/) || {}).input:
      var language = "id";
      break;
    case (lang.match(/^it/) || {}).input:
      var language = "it";
      break;
    case (lang.match(/^pl/) || {}).input:
      var language = "pl";
      break;
    case (lang.match(/^ro/) || {}).input:
      var language = "ro";
      break;
    case (lang.match(/^ru/) || {}).input:
      var language = "ru";
      break;
    case (lang.match(/^tr/) || {}).input:
      var language = "tr";
      break;
    case (lang.match(/^vi/) || {}).input:
      var language = "vi";
      break;
    default:
      var language = "en";
      break;
  }
  script.setAttribute("data-lang", language);
  //   script.setAttribute("crossorigin", "anonymous");
  script.setAttribute("data-loading", "lazy");
  document.getElementById("giscus-container").appendChild(script);
};

window.addEventListener("load", initAll);
